#!/bin/bash

docker run --init --sig-proxy=false \
--name nextcloud-aio-mastercontainer \
--restart unless-stopped \
# 1️⃣  Reverse‑proxy: host 8085 → container 11000
--publish 8085:11000 \
# 2️⃣  Optional AIO UI: host 8081 → container 8080
--publish 8086:8080 \
# 3️⃣  Tell the container to bind Apache on 11000
--env APACHE_PORT=11000 \
# 4️⃣  Skip domain validation because nginx does TLS
--env SKIP_DOMAIN_VALIDATION=true \
# 5️⃣  Persist data
--volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
# 6️⃣  Let the container manage the other containers
--volume /var/run/docker.sock:/var/run/docker.sock:ro \
ghcr.io/nextcloud-releases/all-in-one:latest
