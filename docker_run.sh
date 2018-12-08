#!/bin/bash

docker run -it --rm --name decomplexinfo -e LANG=C.UTF-8 -v "$PWD":/usr/src/app -w /usr/src/app decomplexinfo
