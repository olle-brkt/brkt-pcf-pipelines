#!/bin/bash

set -eu

echo "brktizing ami..."

source_ami=$(cat stock-ami/ami)

curl -L -s -k -o /bin/metavisor "https://github.com/immutable/metavisor-cli/releases/download/v1.0.1/metavisor-linux"
chmod +x /bin/metavisor

if [[ $METAVISOR_AMI == "automatic" ]]
then
    cmd="metavisor aws wrap-ami --metavisor-version $METAVISOR_VERSION $source_ami"
else
    cmd="metavisor aws wrap-ami --metavisor-image $METAVISOR_AMI $source_ami"
fi

echo "Running: \"$cmd\""
set -o pipefail
$cmd | tee ami/ami
