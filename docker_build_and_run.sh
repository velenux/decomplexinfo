#!/bin/bash

docker rmi decomplexinfo
docker build -t decomplexinfo . && ./docker_run.sh
