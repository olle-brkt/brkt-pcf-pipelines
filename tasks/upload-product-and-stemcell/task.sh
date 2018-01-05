#!/bin/bash
set -eu

if [[ -n "$NO_PROXY" ]]; then
  echo "$OM_IP $OPSMAN_DOMAIN_OR_IP_ADDRESS" >> /etc/hosts
fi

# echo om version for debugging
echo "$(om-linux -v)"

mv encrypted-stemcell/* ./

encrypted_sc_path=$(find ./ -name *.tgz | sed "s|^\./||")
echo "Uploading $encrypted_sc_path"

om-linux -t https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
    --client-id "${OPSMAN_CLIENT_ID}" \
    --client-secret "${OPSMAN_CLIENT_SECRET}" \
    -u "$OPS_MGR_USR" \
    -p "$OPS_MGR_PWD" \
    -k \
    upload-stemcell --force \
    -s $encrypted_sc_path

# Should the slug contain more than one product, pick only the first.
FILE_PATH=$(find ./pivnet-product -name *.pivotal | sort | head -1)
om-linux -t https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --client-id "${OPSMAN_CLIENT_ID}" \
  --client-secret "${OPSMAN_CLIENT_SECRET}" \
  -u "$OPS_MGR_USR" \
  -p "$OPS_MGR_PWD" \
  -k \
  --request-timeout 3600 \
  upload-product \
  -p $FILE_PATH
