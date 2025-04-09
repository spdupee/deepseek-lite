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
# Model Download Function
download_model() {
  local url="$1"
  local output="$2"
  local description="$3"
  
  echo -e "${GREEN}>>> Downloading ${description}...${NC}"
  if ! wget -q --show-progress -O "$output" "$url"; then
    echo -e "${YELLOW}>>> Primary download failed, trying mirror...${NC}"
    wget -q --show-progress -O "$output" "https://cdn-lfs.huggingface.co/${url#https://huggingface.co/}" || {
      echo -e "${RED}>>> Failed to download ${description}${NC}"
      return 1
    }
  fi
}

# Download models with error handling
download_model \
  "https://huggingface.co/TheBloke/deepseek-llm-1.3b-GGUF/resolve/main/deepseek-llm-1.3b.Q4_K_M.gguf" \
  "models/text/model.gguf" \
  "Text Model (1.3B 4-bit)"

download_model \
  "https://huggingface.co/radames/SD-Turbo-4bit-CPU/resolve/main/sd-turbo-4bit-cpu.safetensors" \
  "models/image/sdxl-turbo.safetensors" \
  "Image Model (SD-Turbo 4-bit)"

# Optional upscaler (skip if fails)
download_model \
  "https://huggingface.co/IAHQ/RealESRGAN/resolve/main/RealESRGAN_x4plus_anime_6B-4bit.pth" \
  "models/image/upscaler.pth" \
  "Image Upscaler (4-bit)" || true
  
# Build and start
echo -e "${GREEN}>>> Launching services...${NC}"
docker compose up -d --build || { echo -e "${RED}Docker compose failed!${NC}"; exit 1; }

echo -e "${GREEN}>>> Installation complete!${NC}"
echo -e "Access WebUI at: http://localhost:7860"
echo -e "Manage with: cd $INSTALL_DIR && docker compose [stop|start|down]"