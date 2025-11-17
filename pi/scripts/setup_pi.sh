sudo systemctl start ssh
sudo systemctl enable ssh
sudo apt install vim git zsh docker pip nginx fastfetch nodejs tmux clangd golang npm certbot python3-certbot-nginx docker-io ufw -y
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

curl https://repo.jellyfin.org/install-debuntu.sh | sudo bash

wget https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-linux-arm64.tar.gz

sudo mv nvim-linux-arm64 /opt/nvim
sudo ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim

touch $HOME/.hushlogin

git clone git@github.com:mikefreno/dots.git
cp -r ~/dots/mac/nvim ~/.config/

cd ~/dots/pi/nginx_auth_server/ && go build

sudo cp ~/dots/pi/service_files/* /etc/systemd/system/

cd
sudo tee /etc/nginx/sites-enabled/temp-certbot > /dev/null <<'EOF'
server {
    listen 80;
    server_name jellyfin.freno.me mikefreno.tplinkdns.com vw.freno.me ai.freno.me lm.freno.me files.freno.me infill.freno.me;
}
EOF

sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d jellyfin.freno.me
sudo certbot --nginx -d vw.freno.me
sudo certbot --nginx -d ai.freno.me
sudo certbot --nginx -d lm.freno.me
sudo certbot --nginx -d files.freno.me
sudo certbot --nginx -d infill.freno.me

sudo cp ~/dots/pi/nginx/sites-available/frenome /etc/nginx/sites-available/frenome
sudo ln -s /etc/nginx/sites-available/frenome /etc/nginx/sites-enabled/frenome

sudo nginx -t
sudo systemctl reload nginx

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow 22/tcp

sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

sudo ufw enable
