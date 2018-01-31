#!/bin/bash

set -eu

echo "Finding stock director stemcell..."

echo "$PEM" > ssh-key
chmod 700 ssh-key

echo "Moving the stock stemcell.tgz from /var/tempest/stemcells to /tmp/stock_stemcells/..."
ssh -i ssh-key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error ubuntu@$OPSMAN_DOMAIN_OR_IP_ADDRESS 'mkdir -p /tmp/stock_stemcells/; sudo mv /var/tempest/stemcells/*.tgz /tmp/stock_stemcells/'

echo "scp:ing the stock stemcell from $OPSMAN_DOMAIN_OR_IP_ADDRESS"
scp -i ssh-key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error ubuntu@$OPSMAN_DOMAIN_OR_IP_ADDRESS:'/tmp/stock_stemcells/*.tgz' ./

sc_file_path=$(find ./ -name *.tgz)

if [ ! -f "$sc_file_path" ]; then
  echo "Stemcell file not found!"
  exit 1
fi

# stock stemcell to stemcell/$sc_file_path
cp $sc_file_path stemcell/$sc_file_path

tar xf $sc_file_path
source_ami=$(grep "$REGION" stemcell.MF | awk '{print $2}')
echo "Stock stemcell ami: $source_ami"

# stock stemcell ami to stock-ami/ami
echo "$source_ami" > stock-ami/ami
