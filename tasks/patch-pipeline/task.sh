#!/bin/bash
set -eu

echo "patching pipeline..."

curl -L -s -k -o fly "${ATC_EXTERNAL_URL}/api/v1/cli?arch=amd64&platform=linux"
chmod +x fly

cat pcf-pipelines/install-pcf/aws/pipeline.yml | yaml-patch \
    -o brkt-pcf-pipelines/operations/brktize-pipeline.yml \
    > messy_pipeline.yml

./fly format-pipeline -c messy_pipeline.yml > generated-pipeline/pipeline.yml
