#!/bin/bash
set -eu

curl -L -s -k -o jq "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64"
chmod +x jq

curl -L -s -k -o om "https://github.com/pivotal-cf/om/releases/download/0.28.0/om-linux"
chmod +x om

curl -L -s -k -o pivnet-cli "https://github.com/pivotal-cf/pivnet-cli/releases/download/v0.0.49/pivnet-linux-amd64-0.0.49"
chmod +x pivnet-cli

curl -L -s -k -o yaml "https://github.com/mikefarah/yaml/releases/download/1.13.1/yaml_linux_amd64"
chmod +x yaml


mkdir -p stock-ami


# Retrieving stock stemcell. Snippet taken from https://github.com/pivotal-cf/pcf-pipelines/blob/master/tasks/upload-product-and-stemcell/task.sh

if [[ -n "$NO_PROXY" ]]; then
  echo "$OM_IP $OPSMAN_DOMAIN_OR_IP_ADDRESS" >> /etc/hosts
fi

STEMCELL_VERSION=$(
  cat ./pivnet-product/metadata.json |
  ./jq --raw-output \
    '
    [
      .Dependencies[]
      | select(.Release.Product.Name | contains("Stemcells"))
      | .Release.Version
    ]
    | map(split(".") | map(tonumber))
    | transpose | transpose
    | max // empty
    | map(tostring)
    | join(".")
    '
)

if [ -n "$STEMCELL_VERSION" ]; then
  diagnostic_report=$(
    ./om \
      --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
      --client-id "${OPSMAN_CLIENT_ID}" \
      --client-secret "${OPSMAN_CLIENT_SECRET}" \
      --username "$OPS_MGR_USR" \
      --password "$OPS_MGR_PWD" \
      --skip-ssl-validation \
      curl --silent --path "/api/v0/diagnostic_report"
  )

  stemcell=$(
    echo "$diagnostic_report" |
    ./jq \
      --arg version "$STEMCELL_VERSION" \
      --arg glob "$IAAS" \
    '.stemcells[] | select(contains($version) and contains($glob))'
  )

  if [[ -z "$stemcell" ]]; then
    echo "Downloading stemcell $STEMCELL_VERSION"

    product_slug=$(
      ./jq --raw-output \
        '
        if any(.Dependencies[]; select(.Release.Product.Name | contains("Stemcells for PCF (Windows)"))) then
          "stemcells-windows-server"
        else
          "stemcells"
        end
        ' < pivnet-product/metadata.json
    )

    ./pivnet-cli login --api-token="$PIVNET_API_TOKEN"
    ./pivnet-cli download-product-files -p "$product_slug" -r "$STEMCELL_VERSION" -g "*${IAAS}*" --accept-eula

    SC_FILE_PATH=$(find ./ -name *.tgz)

    if [ ! -f "$SC_FILE_PATH" ]; then
      echo "Stemcell file not found!"
      exit 1
    fi

    tar xf *.tgz
    STEMCELL_AMI=$(grep "$REGION" stemcell.MF | awk '{print $2}')
    echo "$STEMCELL_AMI" > stock-ami/ami
  fi
fi


# Encrypting stemcell. Snippet taken from https://github.com/olle-brkt/brkt-pcf-pipelines/blob/master/tasks/encrypt-ami/task.sh

source_ami=$(cat stock-ami/ami)
key="$METAVISOR_VERSION.$source_ami"
source_file=encrypted-amis/encrypted-amis-map.yml
output_file=results/encrypted-amis-map.yml



echo "All encrypted AMI's in the format \"Metavisor_version.source_ami: encrypted_ami\""
./yaml read -- $source_file

echo "Searching for \"$key\":"
encrypted_ami=$(./yaml read -- $source_file \"$key\")

if ! [ "$encrypted_ami" == "null" ]; then
    # Reusing previous encryption results to save time
    echo "Source AMI $source_ami encrypted by $METAVISOR_VERSION found: $encrypted_ami"
    echo "Copying over \"$source_file\" to \"$output_file\""
    cp $source_file $output_file
else
    # Can't reuse previous encryption results, encrypting source_ami
    echo "Installing brkt-cli"
    pip install brkt-cli 1>/dev/null

    echo "Getting token from https://api.$SERVICE_DOMAIN:443"
    auth_cmd="brkt auth --email $EMAIL --password $PASSWORD --root-url https://api.$SERVICE_DOMAIN:443"
    echo "Running command: export BRKT_API_TOKEN=\$(brkt auth --email $EMAIL --password *** --root-url https://api.$SERVICE_DOMAIN:443)"
    BRKT_API_TOKEN=$($auth_cmd)
    export BRKT_API_TOKEN

    echo "Encrypting stemcell image $source_ami"
    cmd="brkt aws encrypt --service-domain $SERVICE_DOMAIN --region $REGION --metavisor-version ${METAVISOR_VERSION} --no-single-disk --brkt-tag app=pcf --brkt-tag role=stemcell $source_ami"
    echo "Running command: $cmd"
    $cmd | tee encrypt.log &

    # Wait for all background tasks to complete
    wait

    encrypted_ami=$(tail -1 encrypt.log | awk '{print $1}')
    if ! [[ $encrypted_ami =~ ^ami- ]]; then
        echo "Encryption failed in region $REGION"
        exit 1
    fi

    echo "Source AMI $source_ami encrypted by $METAVISOR_VERSION: $encrypted_ami"
    echo "Adding \"$key: $encrypted_ami\" to \"$source_file\""
    ./yaml write -i -- $source_file \"$key\" $encrypted_ami
    echo "Copying over \"$source_file\" to \"$output_file\""
    cp $source_file $output_file
fi

echo "Results in \"$output_file\":"
./yaml read -- $output_file


# Repackaging stemcell
echo "Repackaging stemcell"
encrypted_ami=$(./yaml read -- $output_file \"$key\")
sed -i "s/\b$REGION\b.*$/$REGION: $encrypted_ami/" stemcell.MF

TGZ_NAME=$(find ./ -name *.tgz)
rm -rf $TGZ_NAME
tar cvfz $TGZ_NAME $(ls)
cp $TGZ_NAME stemcell/stemcell.tgz
echo "ls stemcell:"
ls stemcell
