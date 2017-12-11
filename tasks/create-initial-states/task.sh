#!/bin/bash
set -eu

# initialize terraform state
files=$(aws --endpoint-url $S3_ENDPOINT --region $S3_REGION s3 ls "${S3_BUCKET_TERRAFORM}/")

set +e
echo $files | grep terraform.tfstate
if [ "$?" -gt "0" ]; then
  echo "{\"version\": 3}" > terraform.tfstate
  aws s3 --endpoint-url $S3_ENDPOINT --region $S3_REGION cp terraform.tfstate "s3://${S3_BUCKET_TERRAFORM}/terraform.tfstate"
  set +x
  if [ "$?" -gt "0" ]; then
    echo "Failed to upload empty tfstate file"
    exit 1
  fi
else
  echo "terraform.tfstate file found, skipping"
  exit 0
fi

# initialize patched-pipeline state
files=$(aws --endpoint-url $S3_ENDPOINT --region $S3_REGION s3 ls "${S3_PATCHED_PIPELINE}/")

set +e
echo $files | grep pipeline.yml
if [ "$?" -gt "0" ]; then
  echo "initial_state: true" > pipeline.yml
  aws s3 --endpoint-url $S3_ENDPOINT --region $S3_REGION cp pipeline.yml "s3://${S3_PATCHED_PIPELINE}/pipeline.yml"
  set +x
  if [ "$?" -gt "0" ]; then
    echo "Failed to upload empty pipeline.yml file"
    exit 1
  fi
else
  echo "pipeline.yml file found, skipping"
  exit 0
fi
