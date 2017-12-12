#!/bin/bash
set -eu

curl \
  -L \
  --silent \
  --insecure \
  --output yaml-patch \
  "https://github.com/krishicks/yaml-patch/releases/download/v0.0.10/yaml_patch_linux"

chmod +x yaml-patch

curl \
  --silent \
  --insecure \
  --output fly \
  "${ATC_EXTERNAL_URL}/api/v1/cli?arch=amd64&platform=linux"

chmod +x fly

# Do ops here:
./fly format-pipeline -c <(
  cat pcf-pipelines/install-pcf/aws/pipeline.yml |
  ./yaml-patch \
    -o brkt-pcf-pipelines/operations/remove-bootstrap-tf-state.yml \
    -o brkt-pcf-pipelines/operations/add-brkt-pcf-pipelines-resource.yml \
    -o brkt-pcf-pipelines/operations/add-encrypt-opsman.yml \
    -o /Users/olle/work/brkt-pcf-pipelines/operations/update-resources-to-include-bpcfp-res.yml
) > generated-pipeline/pipeline.yml
