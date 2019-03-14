#!/bin/bash

# generate the Gemfile.lock
rm -f Gemfile.lock
docker run --rm -v "$PWD":/usr/src/app \
  -w /usr/src/app \
  ruby:2.6-stretch \
  bundle install
