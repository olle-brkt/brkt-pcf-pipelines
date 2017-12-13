#!/bin/bash
set -eu

#!/bin/bash
set -eu

source_ami=$(grep $REGION pivnet-opsmgr/*.yml | cut -d' ' -f2)
key="$METAVISOR_VERSION-$source_ami"
source_file=encrypted-amis/encrypted-amis-map.yml

curl -L -s -k -o yaml "https://github.com/mikefarah/yaml/releases/download/1.13.1/yaml_linux_amd64"
chmod +x yaml

echo "All encrypted AMI's in the format \"Metavisor_version.source_ami: encrypted_ami\""
./yaml read -- $source_file

echo "Searching for $key:"
encrypted_ami=`./yaml read -- $source_file \"$key\"`

if ! [ "$encrypted_ami" == "null" ]; then
    echo "Source AMI $source_ami encrypted by $METAVISOR_VERSION found: $encrypted_ami"
    echo "$encrypted_ami" > ami/ami
else
    echo "Error: Encrypted AMI is missing for some reason, trigger the encrypt job again"
    exit 1
