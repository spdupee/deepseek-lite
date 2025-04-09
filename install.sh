#!/bin/bash
# DEEPSEEK-Lite Installer for Ubuntu 24.04+
set -e

# Config
SWAP_SIZE="64G"
INSTALL_DIR="/opt/deepseek-lite"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root!${NC}"
  exit 1
fi

echo -e "${GREEN}>>> Installing DEEPSEEK-Lite (Docker-CE)${NC}"

# Handle Ubuntu 25.04 codename
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$VERSION_CODENAME" = "plucky" ]; then
        echo -e "${GREEN}>>> Detected Ubuntu 25.04 'plucky', using Ubuntu 24.10 'oracular' for Docker repos${NC}"
        DOCKER_CODENAME="oracular"
    else
        DOCKER_CODENAME="$VERSION_CODENAME"
    fi
else
    echo -e "${RED}Cannot detect OS version!${NC}"
    exit 1
fi

# Install Docker-CE
echo -e "${GREEN}>>> Setting up Docker-CE...${NC}"
apt-get update
apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $DOCKER_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure Docker
usermod -aG docker $SUDO_USER
systemctl enable --now docker

# Setup swap
echo -e "${GREEN}>>> Creating ${SWAP_SIZE} swap...${NC}"
fallocate -l $SWAP_SIZE /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# Kernel tuning
echo "vm.swappiness=100" >> /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
sysctl -p

# Clone repo
echo -e "${GREEN}>>> Downloading DEEPSEEK-Lite...${NC}"
git clone https://github.com/spdupee/deepseek-lite.git $INSTALL_DIR || { echo -e "${RED}Git clone failed!${NC}"; exit 1; }
cd $INSTALL_DIR
mkdir -p models/{text,image}

# Download models
wget -O models/text/model.gguf \
  https://huggingface.co/TheBloke/deepseek-r1-1.5b-GGUF/resolve/main/deepseek-r1-1.5b.Q4_K_M.gguf || echo -e "${RED}Text model download failed!${NC}"

wget -O models/image/sdxl-turbo.safetensors \
  https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sdxl-turbo-4bit.safetensors || echo -e "${RED}Image model download failed!${NC}"

# Build and start
echo -e "${GREEN}>>> Launching services...${NC}"
docker compose up -d --build || { echo -e "${RED}Docker compose failed!${NC}"; exit 1; }

echo -e "${GREEN}>>> Installation complete!${NC}"
echo -e "Access WebUI at: http://localhost:7860"
echo -e "Manage with: cd $INSTALL_DIR && docker compose [stop|start|down]"