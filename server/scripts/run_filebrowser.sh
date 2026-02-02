#!/bin/bash

DOCKER_PATH=$(which docker)

$DOCKER_PATH start filebrowser || \

$DOCKER_PATH run -d \
  --name filebrowser \
  -p 127.0.0.1:8083:80 \
  -v /srv/filebrowser/config:/config \
  -v /ServerStore/filebrowser/:/srv \
  --restart unless-stopped \
  filebrowser/filebrowser
