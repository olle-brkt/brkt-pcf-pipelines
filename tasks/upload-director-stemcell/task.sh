#!/bin/bash

set -eu

echo "Uploading wrapped stemcell to director..."

echo "$PEM" > ssh-key
chmod 700 ssh-key

mv brktized-stemcell/*.tgz ./

sc_file_path=$(find ./ -name *.tgz)

if [ ! -f "$sc_file_path" ]; then
  echo "Stemcell file not found!"
  exit 1
fi

ssh -i ssh-key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error ubuntu@$OPSMAN_DOMAIN_OR_IP_ADDRESS 'mkdir -p /tmp/brktized_stemcells/'
echo "scp:ing the brktized stemcell to $OPSMAN_DOMAIN_OR_IP_ADDRESS"
scp -i ssh-key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error $sc_file_path ubuntu@$OPSMAN_DOMAIN_OR_IP_ADDRESS:/tmp/brktized_stemcells/

echo "moving the stock stemcell.tgz from /var/tempest/stemcells to /tmp/brktized_stemcells/..."
ssh -i ssh-key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=error ubuntu@$OPSMAN_DOMAIN_OR_IP_ADDRESS 'sudo mv /tmp/brktized_stemcells/*.tgz /var/tempest/stemcells/'
