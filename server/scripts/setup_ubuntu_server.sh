#!/bin/bash
set -e

# Enable and start SSH
sudo systemctl enable ssh
sudo systemctl start ssh

# Configure firewall first (before exposing services)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install basic dependencies
sudo apt-get install -y ca-certificates curl gnupg vim git zsh nginx certbot python3-certbot-nginx ufw

# Add Docker's official GPG key and repository
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

# Install additional packages
sudo apt-get install -y fastfetch nodejs npm tmux clangd golang

# Install Jellyfin
curl https://repo.jellyfin.org/install-debuntu.sh | sudo bash

# Install Neovim (x64 version for Ubuntu Server)
wget https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-linux64.tar.gz
tar xzf nvim-linux64.tar.gz
sudo mv nvim-linux64 /opt/nvim
sudo ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim
rm nvim-linux64.tar.gz

# Install Oh My Zsh (will prompt for shell change)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Suppress login messages
touch $HOME/.hushlogin

# Clone dotfiles
git clone git@github.com:mikefreno/dots.git ~/dots
mkdir -p ~/.config
cp -r ~/dots/mac/nvim ~/.config/

# Build auth server
cd ~/dots/pi/nginx_auth_server/ && go build
cd ~

# Copy service files
sudo cp ~/dots/pi/service_files/* /etc/systemd/system/
sudo systemctl daemon-reload

# Setup temporary nginx config for certbot
sudo tee /etc/nginx/sites-enabled/temp-certbot > /dev/null <<'EOF'
server {
    listen 80;
    server_name jellyfin.freno.me mikefreno.tplinkdns.com vw.freno.me ai.freno.me lm.freno.me files.freno.me infill.freno.me;
}
EOF

# Test and reload nginx
sudo nginx -t
sudo systemctl reload nginx

# Get SSL certificates
sudo certbot --nginx -d jellyfin.freno.me --non-interactive --agree-tos -m admin@freno.me || true
sudo certbot --nginx -d vw.freno.me --non-interactive --agree-tos -m admin@freno.me || true
sudo certbot --nginx -d ai.freno.me --non-interactive --agree-tos -m admin@freno.me || true
sudo certbot --nginx -d lm.freno.me --non-interactive --agree-tos -m admin@freno.me || true
sudo certbot --nginx -d files.freno.me --non-interactive --agree-tos -m admin@freno.me || true
sudo certbot --nginx -d infill.freno.me --non-interactive --agree-tos -m admin@freno.me || true

# Remove temp config and add real config
sudo rm /etc/nginx/sites-enabled/temp-certbot
sudo cp ~/dots/pi/nginx/sites-available/frenome /etc/nginx/sites-available/frenome
sudo ln -s /etc/nginx/sites-available/frenome /etc/nginx/sites-enabled/frenome

# Final nginx test and reload
sudo nginx -t
sudo systemctl reload nginx

echo "Setup complete! You may need to log out and back in for group changes to take effect."
