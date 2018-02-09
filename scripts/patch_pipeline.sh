#!/bin/bash

fly format-pipeline -c <(cat /pipeline.yml | yaml-patch -o /brktize.yml)
