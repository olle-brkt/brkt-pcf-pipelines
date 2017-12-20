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


# Retrieving stock stemcell. Some snippets taken from https://github.com/pivotal-cf/pcf-pipelines/blob/master/tasks/upload-product-and-stemcell/task.sh

if [[ -n "$NO_PROXY" ]]; then
  echo "$OM_IP $OPSMAN_DOMAIN_OR_IP_ADDRESS" >> /etc/hosts
fi

echo "Retrieving stock stemcell version packaged with product"
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
echo "Stock stemcell version: $STEMCELL_VERSION"

if [ -z "$STEMCELL_VERSION" ]; then
  echo "Error: No stemcell version found! Exiting..."
  exit 1
fi

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
source_ami=$(grep "$REGION" stemcell.MF | awk '{print $2}')


# Encrypting stemcell. Snippet taken from https://github.com/olle-brkt/brkt-pcf-pipelines/blob/master/tasks/encrypt-ami/task.sh

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
encrypted_ami=$(./yaml read -- $output_file \"$key\")
echo "Repackaging stemcell - inserting new encrypted stemcell $encrypted_ami into stemcell.MF"
sed -ri 's/'"$REGION"': [a-z]{3}-[a-z0-9]{8}/'"$REGION"': '"$encrypted_ami"'/' stemcell.MF
echo "stemcell.MF:"
cat stemcell.MF

TGZ_NAME=$(find ./ -name *.tgz)
rm -rf $TGZ_NAME
echo "Running: tar cvfz $TGZ_NAME dev_tools_file_list.txt image stemcell.MF stemcell_dpkg_l.txt"
tar cfz $TGZ_NAME dev_tools_file_list.txt image stemcell.MF stemcell_dpkg_l.txt
cp $TGZ_NAME stemcell/stemcell.tgz
