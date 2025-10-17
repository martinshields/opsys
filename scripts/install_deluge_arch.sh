#!/bin/bash

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
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm docker
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
    sudo pacman -S --noconfirm lazydocker
    echo "lazydocker installed."
else
    echo "lazydocker is already installed."
fi

# Check if docker-compose is installed
if ! command_exists docker-compose; then
    echo "docker-compose is not installed. Installing docker-compose..."
    sudo pacman -S --noconfirm docker-compose
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
