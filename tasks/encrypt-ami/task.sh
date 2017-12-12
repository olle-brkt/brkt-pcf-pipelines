#!/bin/bash
set -eu

pip install brkt-cli 1>/dev/null

ami=$(cat stock_ami/ami)

auth_cmd="brkt auth --email $EMAIL --password $PASSWORD --root-url https://$SERVICE_DOMAIN"
export BRKT_API_TOKEN=`$auth_cmd`

# echo "${CA_CERT}" > ${ROOT}/ca.crt
# cmd="brkt aws encrypt --service-domain $SERVICE_DOMAIN --region $region --metavisor-version ${METAVISOR_VERSION} --ca-cert ${ROOT}/ca.crt $ami"

echo "Encrypting stemcell image $ami"
cmd="brkt aws encrypt --service-domain $SERVICE_DOMAIN --region $REGION --metavisor-version ${METAVISOR_VERSION} --no-single-disk --brkt-tag 'app=pcf' --brkt-tag 'role=opsmanager' $ami"
$cmd | tee encrypt.log &

# Wait for all background tasks to complete
wait

output_ami=`tail -1 encrypt.log | awk '{print $1}'`
if ! [[ $output_ami =~ ^ami- ]]; then
    echo "Encryption failed in region $region"
    exit 1
fi

echo "$output_ami" > ami/ami
