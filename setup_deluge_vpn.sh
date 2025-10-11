#!/bin/bash

# Script to install Docker, lazydocker, and docker-compose on Arch Linux,
# then run Deluge with PIA VPN in a Docker container using docker-compose
# Downloads will be saved to ~/adata on the host

# TODO: Edit these with your PIA credentials
VPN_USER="your_pia_username"
VPN_PASS="your_pia_password"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create ~/adata if it doesn't exist
if [ ! -d "$HOME/adata" ]; then
    mkdir -p "$HOME/adata"
    chmod -R 775 "$HOME/adata"
    chown -R $USER:$USER "$HOME/adata"
    echo "Created directory: $HOME/adata"
fi

# Create ~/delugevpn/config for VPN and Deluge config
CONFIG_DIR="$HOME/delugevpn/config"
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR/openvpn"
    echo "Created directory: $CONFIG_DIR (place your PIA .ovpn file in $CONFIG_DIR/openvpn/ if needed)"
fi

# Check if Docker is installed
if ! command_exists docker; then
    echo "Docker is not installed. Installing Docker..."
    sudo pacman -Syu --noconfirm || { echo "Failed to update system"; exit 1; }
    sudo pacman -S --noconfirm docker || { echo "Failed to install Docker"; exit 1; }
    sudo systemctl start docker || { echo "Failed to start Docker service"; exit 1; }
    sudo systemctl enable docker
    if ! groups | grep -q docker; then
        sudo usermod -aG docker $USER
        echo "Added $USER to docker group. Run 'newgrp docker' or log out and back in to apply changes."
        newgrp docker 2>/dev/null || echo "Run 'newgrp docker' to apply group changes without logging out."
    fi
else
    echo "Docker is already installed."
fi

# Check if lazydocker is installed
if ! command_exists lazydocker; then
    echo "lazydocker is not installed. Installing lazydocker..."
    sudo pacman -S --noconfirm lazydocker || { echo "Failed to install lazydocker"; exit 1; }
    echo "lazydocker installed."
else
    echo "lazydocker is already installed."
fi

# Check if docker-compose or docker compose is installed
if command_exists docker-compose; then
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    echo "docker-compose is not installed. Installing docker-compose..."
    sudo pacman -S --noconfirm docker-compose || { echo "Failed to install docker-compose"; exit 1; }
    COMPOSE_CMD="docker-compose"
    echo "docker-compose installed."
fi

# Check for port conflicts (web UI and torrent ports)
for port in 8112 58846; do
    if ss -tuln | grep -q ":$port "; then
        echo "Port $port is already in use. Please free it or modify the docker-compose.yaml ports."
        exit 1
    fi
done

# Create docker-compose.yaml for DelugeVPN
COMPOSE_FILE="$HOME/docker-compose.yaml"
if [ -f "$COMPOSE_FILE" ]; then
    echo "docker-compose.yaml already exists. Backing up to $COMPOSE_FILE.bak"
    mv "$COMPOSE_FILE" "$COMPOSE_FILE.bak"
fi
echo "Creating docker-compose.yaml for Deluge with PIA VPN..."
TZ=$(cat /etc/timezone 2>/dev/null || echo "Etc/UTC")
cat > "$COMPOSE_FILE" <<EOL
version: '3.8'
services:
  delugevpn:
    image: binhex/arch-delugevpn:latest
    container_name: delugevpn
    cap_add:
      - NET_ADMIN
    environment:
      - PUID=$(id -u)
      - PGID=$(id -g)
      - TZ=$TZ
      - VPN_ENABLED=yes
      - VPN_USER=$VPN_USER
      - VPN_PASS=$VPN_PASS
      - VPN_PROV=pia
      - VPN_CLIENT=openvpn
      - STRICT_PORT_FORWARD=yes
      - ENABLE_PRIVOXY=yes
      - LAN_NETWORK=192.168.1.0/24  # Adjust to your local network (e.g., 192.168.0.0/24)
      - NAME_SERVERS=1.1.1.1,8.8.4.4
      - UMASK=000
      - ENABLE_SOCKS=yes
      - SOCKS_USER=admin
      - SOCKS_PASS=socks
    ports:
      - 8112:8112
      - 58846:58846
      - 58846:58846/udp
      - 8118:8118  # Privoxy proxy
    volumes:
      - $CONFIG_DIR:/config
      - $HOME/adata:/data
    restart: unless-stopped
EOL
echo "docker-compose.yaml created at $COMPOSE_FILE"
echo "Edit LAN_NETWORK in $COMPOSE_FILE to match your local subnet if needed."

# Start DelugeVPN using docker-compose
echo "Starting DelugeVPN container with $COMPOSE_CMD... (This may take 30-60 seconds for VPN setup)"
$COMPOSE_CMD -f "$COMPOSE_FILE" up -d || { echo "Failed to start DelugeVPN container. Check logs with 'docker logs delugevpn'"; exit 1; }

# Wait a bit and check logs for VPN status
sleep 10
echo "Checking initial logs for VPN status..."
docker logs delugevpn 2>&1 | grep -E "(VPN| pia |openvpn|port forward)" | tail -5 || echo "No VPN-related logs found yet. Wait longer and check manually."

echo "DelugeVPN is running. Access the web UI at http://localhost:8112"
echo "WARNING: The default Deluge password is 'deluge'. Change it in the web UI immediately for security."
echo "All traffic is routed through PIA VPN. Downloads will be saved to $HOME/adata"
echo "Proxy access (if needed): HTTP/SOCKS at localhost:8118 (user: admin, pass: socks)"
echo "You can manage the container with lazydocker or $COMPOSE_CMD commands."
echo "To stop: $COMPOSE_CMD -f $COMPOSE_FILE down"
echo "Verify VPN: Run 'docker logs delugevpn' and look for successful connection/port forwarding messages."
