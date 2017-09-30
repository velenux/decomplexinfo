#!/bin/bash

# kill all decomplexinfo containers
docker ps --all | grep decomplexinfo | awk {'print $1'} | xargs docker rm

# remove previous images
docker rmi decomplexinfo

# rebuild the image
docker build -t decomplexinfo .

