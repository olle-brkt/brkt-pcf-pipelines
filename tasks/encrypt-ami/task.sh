#!/bin/bash
set -eu

source_ami=$(cat stock-ami/ami)
key="$METAVISOR_VERSION.$source_ami"
source_file=encrypted-amis/encrypted-amis-map.yml
output_file=results/encrypted-amis-map.yml

curl -L -s -k -o yaml "https://github.com/mikefarah/yaml/releases/download/1.13.1/yaml_linux_amd64"
chmod +x yaml

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
    cmd="brkt aws encrypt --service-domain $SERVICE_DOMAIN --region $REGION --metavisor-version ${METAVISOR_VERSION} --no-single-disk --brkt-tag app=pcf --brkt-tag role=opsmanager $source_ami"
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
