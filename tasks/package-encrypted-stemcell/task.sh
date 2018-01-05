#!/bin/bash
set -eu

source_ami="$(cat stock-ami/ami)"
key="$METAVISOR_VERSION.$source_ami"
input_file=results/encrypted-amis-map.yml
output_file=encrypted-stemcell/encrypted_stemcell.tgz

curl -L -s -k -o yaml "https://github.com/mikefarah/yaml/releases/download/1.13.1/yaml_linux_amd64"
chmod +x yaml

pushd stemcell
sc_file_path=$(find ./ -name *.tgz)
cp $sc_file_path ../
popd

sc_file_path=$(find ./ -maxdepth 0 -name *.tgz)
echo "Extracting $sc_file_path"
tar xf $sc_file_path

encrypted_ami=$(./yaml read -- $input_file \"$key\")
echo "Repackaging stemcell - inserting new encrypted stemcell $encrypted_ami into stemcell.MF"
./yaml w -i -- stemcell.MF cloud_properties.ami.$REGION $encrypted_ami
echo "stemcell.MF:"
cat stemcell.MF

rm -f $sc_file_path
echo "Running: tar cfz $sc_file_path dev_tools_file_list.txt image stemcell.MF stemcell_dpkg_l.txt"
tar cfz $sc_file_path dev_tools_file_list.txt image stemcell.MF stemcell_dpkg_l.txt

# encrypted stemcell to encrypted-stemcell/$sc_file_path
cp $sc_file_path $output_file
