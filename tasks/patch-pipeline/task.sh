#!/bin/bash
set -eu

curl \
  --silent \
  --insecure \
  --output yaml-patch \
  "https://github.com/krishicks/yaml-patch/releases/download/v0.0.10/yaml_patch_linux"

chmod +x yaml-patch

# Do ops here:
cat pcf-pipelines/install-pcf/aws/pipeline.yml | \
  ./yaml-patch -o brkt-pcf-pipelines/operations/remove-bootstrap-tf-state.yml \
  > generated-pipeline/pipeline.yml
