#!/bin/bash

docker rmi decomplexinfo
docker build -t decomplexinfo . && docker run -it --name decomplexinfo -e LANG=C.UTF-8 decomplexinfo
