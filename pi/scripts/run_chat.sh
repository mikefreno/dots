#!/bin/bash
DOCKER_PATH=$(which docker)

$DOCKER_PATH start chat || \
$DOCKER_PATH run -d \
  -p 127.0.0.1:8082:8080 \
  -e OLLAMA_BASE_URL=http://atlas.local:11434 \
  -v open-webui:/app/backend/data \
  --name chat \
  --restart unless-stopped \
  ghcr.io/open-webui/open-webui:main

