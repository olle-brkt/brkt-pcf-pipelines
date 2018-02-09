SHELL	:= /usr/bin/env bash -e -o pipefail

docker-build:
	docker build -q -t brkt-pcf-pipelines .

patch-pipeline: docker-build
	@ if [ ${PCF_PIPELINE_PATH} = "" ]; then echo "Environment variable 'PCF_PIPELINE_PATH' not set"; exit 1; fi
	@ docker run -w / \
		-v `pwd`/scripts/patch_pipeline.sh:/patch_pipeline.sh \
		-v `pwd`/operations/brktize.yml:/brktize.yml \
		-v ${PCF_PIPELINE_PATH}:/pipeline.yml \
		brkt-pcf-pipelines /patch_pipeline.sh
