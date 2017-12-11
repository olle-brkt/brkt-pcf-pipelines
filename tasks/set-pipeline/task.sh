#!/bin/bash

set -eu

echo "$PIPELINE_PARAMS" > params.yml

curl \
  --silent \
  --insecure \
  --output fly \
  "${ATC_EXTERNAL_URL}/api/v1/cli?arch=amd64&platform=linux"

chmod +x fly

./fly --target self login \
  --insecure \
  --concourse-url "${ATC_EXTERNAL_URL}" \
  --username "${ATC_BASIC_AUTH_USERNAME}" \
  --password "${ATC_BASIC_AUTH_PASSWORD}" \
  --team-name "${ATC_TEAM_NAME}"

cat params.yml

./fly --target self set-pipeline \
  --non-interactive \
  --pipeline "${PIPELINE_NAME}" \
  --config "${PIPELINE_PATH}" \
  --load-vars-from params.yml \
  --var "PEM=${PEM}" \
  --var "git_private_key=${GIT_PRIVATE_KEY}"
