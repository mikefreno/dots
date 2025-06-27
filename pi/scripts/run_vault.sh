#!/bin/bash

DOCKER_PATH=$(which docker)

$DOCKER_PATH start vaultwarden || \
$DOCKER_PATH run \
  --name vaultwarden \
  -v /srv/vaultwarden/data:/data \
  -p 127.0.0.1:8081:80 \
  --restart unless-stopped \
  vaultwarden/server:latest
