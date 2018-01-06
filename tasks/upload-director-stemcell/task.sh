#!/bin/bash
set -eu

echo "$PEM" > ssh-key
chmod 700 ssh-key

mv encrypted-stemcell/*.tgz ./

sc_file_path=$(find ./ -name *.tgz)

if [ ! -f "$sc_file_path" ]; then
  echo "Stemcell file not found!"
  exit 1
fi

ssh -i ssh-key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error ubuntu@$OPSMAN_DOMAIN_OR_IP_ADDRESS 'mkdir -p /tmp/encrypted_stemcells/'
echo "scp:ing the encrypted stemcell to $OPSMAN_DOMAIN_OR_IP_ADDRESS"
scp -i ssh-key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error $sc_file_path ubuntu@$OPSMAN_DOMAIN_OR_IP_ADDRESS:/tmp/encrypted_stemcells/

echo "moving the stock stemcell.tgz from /var/tempest/stemcells to /tmp/encrypted_stemcells/..."
ssh -i ssh-key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error ubuntu@$OPSMAN_DOMAIN_OR_IP_ADDRESS 'sudo mv /tmp/encrypted_stemcells/*.tgz /var/tempest/stemcells/'
