#!/bin/bash
DOCKER=$(which docker)

# Start Watchtower if it isn’t already running
if ! $DOCKER ps -q -f name=watchtower | grep -q .; then
  $DOCKER run -d \
    --name watchtower \
    --restart unless-stopped \
    -v /var/run/docker.sock:/var/run/docker.sock \
    containrrr/watchtower \
    --interval 300 \
    --cleanup
fi

# Start chat if it isn’t already running
if ! $DOCKER ps -q -f name=chat | grep -q .; then
  $DOCKER run -d \
    --name chat \
    --restart unless-stopped \
    -p 127.0.0.1:8082:8080 \
    -e OLLAMA_BASE_URL=http://atlas.local:11434 \
    -v open-webui:/app/backend/data \
    ghcr.io/open-webui/open-webui:main
fi
