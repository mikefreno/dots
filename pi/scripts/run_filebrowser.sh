#!/bin/bash

# Find the full path to docker to make the script more robust
DOCKER_PATH=$(which docker)

$DOCKER_PATH run -d \
  --name filebrowser \
  -p 127.0.0.1:8083:80 \
  -v /srv/filebrowser/config:/config \
  -v /ServerStore/filebrowser/:/srv \
  -u 1000:1000 \
  --restart unless-stopped \
  filebrowser/filebrowser
