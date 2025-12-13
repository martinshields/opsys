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

# Script to install Docker, lazydocker, and docker-compose on Arch Linux,
# then run Deluge in a Docker container using docker-compose.NO VPN will be installed.
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
if ! command_exists docker; then
    echo "Docker is not installed. Installing Docker..."
    pkg_install 
    pkg_install docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "Docker installed. You may need to log out and back in for group changes to take effect."
else
    echo "Docker is already installed."
fi

# Check if lazydocker is installed
if ! command_exists lazydocker; then
    echo "lazydocker is not installed. Installing lazydocker..."
    pkg_install lazydocker
    echo "lazydocker installed."
else
    echo "lazydocker is already installed."
fi

# Check if docker-compose is installed
if ! command_exists docker-compose; then
    echo "docker-compose is not installed. Installing docker-compose..."
    pkg_install docker-compose
    echo "docker-compose installed."
else
    echo "docker-compose is already installed."
fi

# Create docker-compose.yaml for Deluge
COMPOSE_FILE="$HOME/docker-compose.yaml"
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Creating docker-compose.yaml for Deluge..."
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
    echo "docker-compose.yaml created at $COMPOSE_FILE"
else
    echo "docker-compose.yaml already exists at $COMPOSE_FILE"
fi

# Start Deluge using docker-compose
echo "Starting Deluge container with docker-compose..."
docker-compose -f "$COMPOSE_FILE" up -d

echo "Deluge is running. Access the web UI at http://localhost:8112"
echo "Default web UI password: deluge"
echo "Downloads will be saved to $HOME/adata"
echo "You can manage the container with lazydocker or docker-compose commands."
