#!/bin/bash

# Written by Nicholas Sebastian on May 2024.

# Install Starhip (a lot better than Oh My Bash).
echo "Installing Starship..."
curl -sS https://starship.rs/install.sh | sh

# Update APT package registry.
echo "Updating registries..."
add-apt-repository ppa:zhangsongcui3371/fastfetch
apt update

# Install some packages.
echo "Installing some packages..."
apt install fastfetch
apt install btop
apt install ripgrep
apt install gh
apt install jq
apt install tree
apt install neovim

# Configure Bash autocomplete.
printf "\n# enable autocomplete\nbind 'set show-all-if-ambiguous on'\nbind 'TAB:menu-complete'\n" >> ~/.bashrc

# Configure Starship to run when Bash starts.
printf "\n# use starship\neval \"\$(starship init bash)\"\n" >> ~/.bashrc

# Configure fastfetch to run when Bash starts.
printf "\n# show system information\nfastfetch\n" >> ~/.bashrc

# Install Node Version Manager, Node and NPM.
echo "Installing Node..."
printf "\n# nvm" >> ~/.bashrc
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install node

# Install Bun.
echo "Installing Bun..."
curl -fsSL https://bun.sh/install | bash

# Install Golang.
echo "Installing Go..."
curl -OL https://golang.org/dl/go1.22.3.linux-amd64.tar.gz
tar -C /usr/local -xvf go1.22.3.linux-amd64.tar.gz
printf "\n# golang\nexport PATH=\$PATH:/usr/local/go/bin\n" >> ~/.profile

# Install Rust.
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
