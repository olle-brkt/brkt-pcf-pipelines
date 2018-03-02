#!/bin/bash

set -eu

echo "uploading product"
# Should the slug contain more than one product, pick only the first.
file_path=$(find ./pivnet-product -name "*.pivotal" | sort | head -1)
om-linux -t "https://$OPSMAN_DOMAIN_OR_IP_ADDRESS" \
  -u "$OPSMAN_USR" \
  -p "$OPSMAN_PWD" \
  -k \
  --request-timeout 3600 \
  upload-product \
  -p "$file_path"
