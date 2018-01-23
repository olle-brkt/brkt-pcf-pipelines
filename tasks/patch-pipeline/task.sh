#!/bin/bash
set -eu

echo "getting fly-cli from ${ATC_EXTERNAL_URL}/api/v1/cli?arch=amd64&platform=linux..."

curl -L -k -o fly "${ATC_EXTERNAL_URL}/api/v1/cli?arch=amd64&platform=linux"
chmod +x fly

echo "patching pipeline..."

cat pcf-pipelines/install-pcf/aws/pipeline.yml | yaml-patch \
    -o brkt-pcf-pipelines/operations/brktize-pipeline.yml \
    > messy_pipeline.yml

echo "formatting pipeline..."

./fly format-pipeline -c messy_pipeline.yml > generated-pipeline/pipeline.yml
