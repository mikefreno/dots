sudo systemctl start ssh
sudo systemctl enable ssh
sudo apt install vim git zsh docker pip nginx fastfetch
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
touch $HOME/.hushlogin

git clone git@github.com:mikefreno/dots.git
cp -r ~/dots/mac/nvim ~/.config/
