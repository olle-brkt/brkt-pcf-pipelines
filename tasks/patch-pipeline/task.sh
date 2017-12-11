#!/bin/bash

set -eu

mkdir patched-pipeline
# Do ops here:
cat pcf-pipelines/install-pcf/aws/pipeline.yml > patched-pipeline/pipeline.yml
