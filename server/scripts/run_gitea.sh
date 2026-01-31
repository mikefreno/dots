# Basic setup with default configuration
docker run -d \
  --name=gitea \
  --hostname=gitea \
  --network=host \
  -v /home/git/gitea:/var/lib/gitea \
  -v /etc/timezone:/etc/timezone:ro \
  -v /etc/localtime:/etc/localtime:ro \
  gitea/gitea:latest
