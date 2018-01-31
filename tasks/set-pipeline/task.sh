#!/bin/bash

set -eu

echo "Setting pipeline..."

echo "$pipeline_params" > params.yml

curl -L -s -k -o fly "${concourse_url}/api/v1/cli?arch=amd64&platform=linux"
chmod +x fly

./fly --target self login \
  --insecure \
  --concourse-url "${concourse_url}" \
  --username "${basic_auth_username}" \
  --password "${basic_auth_password}" \
  --team-name "${team_name}"

./fly --target self set-pipeline \
  --non-interactive \
  --pipeline "${pipeline_name}" \
  --config patched-pipeline/pipeline.yml \
  --load-vars-from params.yml \
  --var "PEM=${PEM}" \
  --var "git_private_key=${git_private_key}"
