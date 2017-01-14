#!/bin/bash

# generate the Gemfile.lock
rm -f Gemfile.lock
docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app ruby:2.4 bundle install
