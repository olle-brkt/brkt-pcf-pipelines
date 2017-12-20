#!/bin/bash
set -eu

curl -L -s -k -o yaml-patch "https://github.com/krishicks/yaml-patch/releases/download/v0.0.10/yaml_patch_linux"
chmod +x yaml-patch

curl -L -s -k -o fly "${ATC_EXTERNAL_URL}/api/v1/cli?arch=amd64&platform=linux"
chmod +x fly

##### Operations performed ####################################################
    # [X] Add the brkt-pcf-pipelines git resource
    # [X] Add the encrypted-amis s3 resource
    # [X] Include the brkt-pcf-pipelines and the encrypted-amis resources in aggregate step
    # [X] Replace the bootstrap-terraform-state job with the encrypt-ops-manager job
    # [X] Replace the find-ami task with custom find-ami task
    # [X] Update pivnet-opsmgr-resource to be passed resource from prev. job
    # [X] Replace the upload-ert job with the encrypt-stemcell-and-upload-ert job

cat pcf-pipelines/install-pcf/aws/pipeline.yml | ./yaml-patch \
    -o brkt-pcf-pipelines/operations/add-brkt-pcf-pipelines-resource.yml \
    -o brkt-pcf-pipelines/operations/add-encrypted-amis-resource.yml \
    -o brkt-pcf-pipelines/operations/include-brkt-pcf-pipelines-resource.yml \
    -o brkt-pcf-pipelines/operations/include-encrypted-amis-resource.yml \
    -o brkt-pcf-pipelines/operations/replace-bootstrap-terraform-state-with-encrypt-ops-manager.yml \
    -o brkt-pcf-pipelines/operations/replace-find-ami-with-find-encrypted-ami.yml \
    -o brkt-pcf-pipelines/operations/update-pivnet-opsmgr-resource.yml \
    -o brkt-pcf-pipelines/operations/replace-upload-ert-with-encrypt-stemcell-and-upload-ert.yml \
    > messy_pipeline.yml

./fly format-pipeline -c messy_pipeline.yml > generated-pipeline/pipeline.yml
