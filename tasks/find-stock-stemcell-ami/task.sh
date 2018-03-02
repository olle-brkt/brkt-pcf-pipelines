#!/bin/bash

set -eu

echo "Retrieving stock stemcell version packaged with product..."

curl -L -s -k -o jq "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64"
chmod +x jq

curl -L -s -k -o pivnet-cli "https://github.com/pivotal-cf/pivnet-cli/releases/download/v0.0.49/pivnet-linux-amd64-0.0.49"
chmod +x pivnet-cli


# Retrieving stock stemcell. Some snippets taken from https://github.com/pivotal-cf/pcf-pipelines/blob/master/tasks/upload-product-and-stemcell/task.sh
stemcell_version=$(
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
echo "Stock stemcell version: $stemcell_version"

if [ -z "$stemcell_version" ]; then
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
./pivnet-cli download-product-files -p "$product_slug" -r "$stemcell_version" -g "*$IAAS*" --accept-eula

sc_file_path=$(find ./ -name "*.tgz")

if [ ! -f "$sc_file_path" ]; then
  echo "Stemcell file not found!"
  exit 1
fi

# stock stemcell to stemcell/$sc_file_path
cp "$sc_file_path" "stemcell/$sc_file_path"

tar xf "$sc_file_path"
source_ami=$(grep "$REGION" stemcell.MF | awk '{print $2}')
echo "Stock stemcell ami: $source_ami"

# stock stemcell ami to stock-ami/ami
echo "$source_ami" > stock-ami/ami
