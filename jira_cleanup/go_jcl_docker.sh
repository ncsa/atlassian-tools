#!/usr/bin/bash

DEBUG=1
REGISTRY=ghcr.io
REPO=ncsa/jiracmdline

[[ "$DEBUG" -eq 1 ]] && set -x

tag=production
tag=latest

docker run -it --pull always \
--mount type=bind,src=$HOME,dst=/home \
--entrypoint "/bin/bash" \
$REGISTRY/$REPO:$tag
