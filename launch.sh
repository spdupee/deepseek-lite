#!/bin/bash
# DEEPSEEK-Lite Auto-Installer Wrapper
set -e

# Check root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root!"
  exit 1
fi

# Install dos2unix if missing
if ! command -v dos2unix &> /dev/null; then
  echo "Installing dos2unix..."
  apt-get update
  apt-get install -y dos2unix
fi

# Convert line endings and set permissions
dos2unix --quiet install.sh
chmod +x install.sh

# Execute main installer
./install.sh