#!/usr/bin/env bash
# Cross-distro compatibility prolog (auto-inserted)
# Works on Arch Linux (pacman) and Debian-based (apt) like Raspberry Pi OS.
set -euo pipefail
IFS=$'\n\t'

detect_pkg_mgr() {
    if command -v pacman >/dev/null 2>&1; then
        PKG_MGR="pacman"
    elif command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
        PKG_MGR="apt"
    elif command -v apk >/dev/null 2>&1; then
        PKG_MGR="apk"
    else
        PKG_MGR="unknown"
    fi
}

pkg_install() {
    detect_pkg_mgr
    case "$PKG_MGR" in
        pacman) pkg_install "$@" ;;
        apt) pkg_install && -y "$@" ;;
        apk) sudo apk add "$@" ;;
        *) echo "No known package manager found; please install: $*" >&2; return 1 ;;
    esac
}

# wrapper for systemctl where not available
maybe_systemctl() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl "$@"
    else
        echo "systemctl not available on this system. $*" >&2
        return 1
    fi
}

# wrapper for architecture
ARCH=$(uname -m)
# normalize common architecture names
case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7*|armv6*) ARCH="armv7" ;;
esac

# End of prolog

# Script to install Docker, , and docker.io-compose on Arch Linux,
# then run Deluge in a Docker container using docker.io-compose.NO VPN will be installed.
# Downloads will be saved to ~/adata on the host

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create ~/adata if it doesn't exist
if [ ! -d "$HOME/adata" ]; then
    mkdir -p "$HOME/adata"
    echo "Created directory: $HOME/adata"
fi

# Check if Docker is installed
if ! command_exists docker.io; then
    echo "Docker is not installed. Installing Docker..."
    pkg_install 
    pkg_install docker.io
    sudo systemctl start docker.io
    sudo systemctl enable docker.io
    sudo usermod -aG docker.io $USER
    echo "Docker installed. You may need to log out and back in for group changes to take effect."
else
    echo "Docker is already installed."
fi

# Check if  is installed
if ! command_exists ; then
    echo " is not installed. Installing ..."
    pkg_install 
    echo " installed."
else
    echo " is already installed."
fi

# Check if docker.io-compose is installed
if ! command_exists docker.io-compose; then
    echo "docker.io-compose is not installed. Installing docker.io-compose..."
    pkg_install docker.io-compose
    echo "docker.io-compose installed."
else
    echo "docker.io-compose is already installed."
fi

# Create docker.io-compose.yaml for Deluge
COMPOSE_FILE="$HOME/docker.io-compose.yaml"
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Creating docker.io-compose.yaml for Deluge..."
    cat > "$COMPOSE_FILE" <<EOL
version: '3.8'
services:
  deluge:
    image: linuxserver/deluge:latest
    container_name: deluge
    environment:
      - PUID=$(id -u)
      - PGID=$(id -g)
      - TZ=Etc/UTC
    ports:
      - 8112:8112
      - 6881:6881
      - 6881:6881/udp
    volumes:
      - $HOME/adata:/downloads
    restart: unless-stopped
EOL
    echo "docker.io-compose.yaml created at $COMPOSE_FILE"
else
    echo "docker.io-compose.yaml already exists at $COMPOSE_FILE"
fi

# Start Deluge using docker.io-compose
echo "Starting Deluge container with docker.io-compose..."
docker.io-compose -f "$COMPOSE_FILE" up -d

echo "Deluge is running. Access the web UI at http://localhost:8112"
echo "Default web UI password: deluge"
echo "Downloads will be saved to $HOME/adata"
echo "You can manage the container with  or docker.io-compose commands."
