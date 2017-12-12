#!/bin/bash
set -eu

ami=$(cat stock_ami/ami)

echo "Installing brkt-cli"
pip install brkt-cli 1>/dev/null

echo "Getting token from https://$SERVICE_DOMAIN:443"
auth_cmd="brkt auth --email $EMAIL --password $PASSWORD --root-url https://$SERVICE_DOMAIN:443"
echo "Running command: brkt auth --email $EMAIL --password ***** --root-url https://$SERVICE_DOMAIN:443"
export BRKT_API_TOKEN=`$auth_cmd`

# echo "${CA_CERT}" > ${ROOT}/ca.crt
# cmd="brkt aws encrypt --service-domain $SERVICE_DOMAIN --region $region --metavisor-version ${METAVISOR_VERSION} --ca-cert ${ROOT}/ca.crt $ami"

echo "Encrypting stemcell image $ami"
cmd="brkt aws encrypt --service-domain $SERVICE_DOMAIN --region $REGION --metavisor-version ${METAVISOR_VERSION} --no-single-disk --brkt-tag 'app=pcf' --brkt-tag 'role=opsmanager' $ami"
echo "Running command: $cmd"
$cmd | tee encrypt.log &

# Wait for all background tasks to complete
wait

output_ami=`tail -1 encrypt.log | awk '{print $1}'`
if ! [[ $output_ami =~ ^ami- ]]; then
    echo "Encryption failed in region $REGION"
    exit 1
fi

echo "$output_ami" > ami/ami
