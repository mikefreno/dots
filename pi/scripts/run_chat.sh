#!/bin/bash

# Find the full path to docker to make the script more robust
DOCKER_PATH=$(which docker)

$DOCKER_PATH run -d \
  -p 127.0.0.1:8082:8080 \
  -e OLLAMA_BASE_URL=http://192.168.1.100:11434 \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart unless-stopped \
  ghcr.io/open-webui/open-webui:main
