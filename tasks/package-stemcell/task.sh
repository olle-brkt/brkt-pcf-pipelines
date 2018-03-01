#!/bin/bash

set -eu

echo "Packaging stemcell..."

curl -L -s -k -o yaml "https://github.com/mikefarah/yaml/releases/download/1.13.1/yaml_linux_amd64"
chmod +x yaml

mv stemcell/*.tgz ./
sc_file_path=$(find ./ -name "*.tgz" | sed "s|^\./||")
echo "Extracting $sc_file_path"
tar xf "$sc_file_path"
rm -f "$sc_file_path"

brktized_ami=$(cat ami/ami)
echo "Repackaging stemcell - inserting new brktized stemcell $brktized_ami into stemcell.MF"
./yaml w -i -- stemcell.MF cloud_properties.ami."$REGION" "$brktized_ami"
echo -e "\nstemcell.MF:\n"
cat stemcell.MF
echo -e "\n"

echo "Running: tar cfz $sc_file_path dev_tools_file_list.txt image stemcell.MF packages.txt"
tar cfz "$sc_file_path" dev_tools_file_list.txt image stemcell.MF packages.txt

# brktized stemcell to brktized-stemcell/$sc_file_path
cp "$sc_file_path" "brktized-stemcell/$sc_file_path"
