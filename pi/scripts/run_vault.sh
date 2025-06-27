#!/bin/bash

# Find the full path to docker to make the script more robust
DOCKER_PATH=$(which docker)

# First, try to start the container if it already exists but is stopped
$DOCKER_PATH start vaultwarden || \
# If that fails (e.g., container doesn't exist), then run it for the first time
$DOCKER_PATH run \
  --name vaultwarden \
  -v /srv/vaultwarden/data:/data \
  -p 127.0.0.1:8081:80 \
  --restart unless-stopped \
  vaultwarden/server:latest

