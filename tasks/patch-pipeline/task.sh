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

##### Operations performed ####################################################
    # [X] Add the brkt-pcf-pipelines git resource
    # [X] Add the encrypted-amis s3 resource
    # [X] Include the brkt-pcf-pipelines and the encrypted-amis resources in aggregate step
    # [X] Replace the bootstrap-terraform-state job with the encrypt-ops-manager job
    # [] Replace the find-ami task with custom find-ami task

cat pcf-pipelines/install-pcf/aws/pipeline.yml | ./yaml-patch \
    -o brkt-pcf-pipelines/operations/add-brkt-pcf-pipelines-resource.yml \
    -o brkt-pcf-pipelines/operations/add-encrypted-amis-resource.yml \
    -o brkt-pcf-pipelines/operations/include-brkt-pcf-pipelines-resource.yml \
    -o brkt-pcf-pipelines/operations/include-encrypted-amis-resource.yml \
    -o brkt-pcf-pipelines/operations/replace-bootstrap-terraform-state-with-encrypt-ops-manager.yml \
    -o brkt-pcf-pipelines/operations/replace-find-ami-with-find-encrypted-ami.yml \
    > messy_pipeline.yml

./fly format-pipeline -c messy_pipeline.yml > generated-pipeline/pipeline.yml
