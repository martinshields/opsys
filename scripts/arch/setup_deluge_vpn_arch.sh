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

# Script to install Docker, lazydocker, and docker-compose on Arch Linux or Raspberry Pi OS,
# then run Deluge with PIA VPN in a Docker container using docker-compose
# Downloads will be saved to ~/usb_drive/adata on the host

# TODO: Edit these with your PIA credentials
VPN_USER="your_pia_username"
VPN_PASS="your_pia_password"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS and architecture
OS=""
ARCH=$(uname -m)
if [ -f /etc/arch-release ]; then
    OS="arch"
elif [ -f /etc/debian_version ]; then
    OS="debian"
else
    echo "Unsupported OS. This script supports Arch Linux or Debian-based systems (e.g., Raspberry Pi OS)."
    exit 1
fi
echo "Detected OS: $OS, Architecture: $ARCH"

# Create ~/usb_drive/adata if it doesn't exist
if [ ! -d "$HOME/usb_drive/adata" ]; then
    mkdir -p "$HOME/usb_drive/adata"
    chmod -R 775 "$HOME/usb_drive/adata"
    chown -R "$USER:$USER" "$HOME/usb_drive/adata"
    echo "Created directory: $HOME/usb_drive/adata"
fi

# Create ~/delugevpn/config for VPN and Deluge config
CONFIG_DIR="$HOME/delugevpn/config"
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR/openvpn"
    echo "Created directory: $CONFIG_DIR (place your PIA .ovpn file in $CONFIG_DIR/openvpn/ if needed)"
fi

# Install Docker based on OS
if ! command_exists docker; then
    echo "Docker is not installed. Installing Docker..."
    if [ "$OS" = "arch" ]; then
        pkg_install || { echo "Failed to system"; exit 1; }
        pkg_install docker || { echo "Failed to Docker"; exit 1; }
    elif [ "$OS" = "debian" ]; then
        sudo apt-get update || { echo "Failed to update system"; exit 1; }
        pkg_install -y docker || { echo "Failed to Docker"; exit 1; }
    fi
    sudo systemctl start docker || { echo "Failed to start Docker service"; exit 1; }
    sudo systemctl enable docker
    if ! groups | grep -q docker; then
        sudo usermod -aG docker "$USER"
        echo "Added $USER to docker group. Run 'newgrp docker' or log out and back in to apply changes."
        newgrp docker 2>/dev/null || echo "Run 'newgrp docker' to apply group changes without logging out."
    fi
    # Verify Docker is running
    if ! docker info >/dev/null 2>&1; then
        echo "Docker is not running or accessible. Try running 'newgrp docker' or log out and back in."
        exit 1
    fi
else
    echo "Docker is already installed."
fi

# Install lazydocker based on OS
if ! command_exists lazydocker; then
    echo "lazydocker is not installed. Installing lazydocker..."
    if [ "$OS" = "arch" ]; then
        pkg_install lazydocker || { echo "Failed to lazydocker"; exit 1; }
    elif [ "$OS" = "debian" ]; then
        pkg_install -y curl || { echo "Failed to curl"; exit 1; }
        curl -L https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_"$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep tag_name | cut -d '"' -f 4 | cut -c 2-)"_Linux_"$([ "$ARCH" = "aarch64" ] && echo "arm64" || echo "arm")".tar.gz | tar xz -C /tmp
        sudo mv /tmp/lazydocker /usr/local/bin/ || { echo "Failed to install lazydocker"; exit 1; }
    fi
    echo "lazydocker installed."
else
    echo "lazydocker is already installed."
fi

# Install docker-compose based on OS
if command_exists docker-compose; then
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    echo "docker-compose is not installed. Installing docker-compose..."
    if [ "$OS" = "arch" ]; then
        if command_exists yay || command_exists paru; then
            yay -S --noconfirm docker-compose || paru -S --noconfirm docker-compose || { echo "Failed to install docker-compose. Ensure 'yay' or 'paru' is installed."; exit 1; }
            COMPOSE_CMD="docker-compose"
        else
            echo "No AUR helper (yay/paru) found. Install docker-compose manually or use 'docker compose' (Docker CLI)."
            echo "To install yay: pkg_install yay"
            exit 1
        fi
    elif [ "$OS" = "debian" ]; then
        pkg_install -y docker-compose || { echo "Failed to docker-compose"; exit 1; }
        COMPOSE_CMD="docker-compose"
    fi
    echo "docker-compose installed."
fi

# Check for port conflicts (web UI, torrent, and Privoxy ports)
for port in 8112 58846 8118; do
    if ss -tuln | grep -q ":$port "; then
        echo "Port $port is already in use. Please free it or modify the docker-compose.yaml ports."
        exit 1
    fi
done

# Select Docker image based on architecture
DELUGE_IMAGE="binhex/arch-delugevpn:latest"
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "armv7l" ]; then
    echo "ARM architecture detected. Checking for ARM-compatible DelugeVPN image..."
    # binhex/arch-delugevpn does not officially support ARM; fallback to an alternative or warn
    DELUGE_IMAGE="ghcr.io/linuxserver/deluge:latest"
    echo "Using linuxserver/deluge as binhex/arch-delugevpn is not ARM-compatible. VPN setup may require manual configuration."
fi

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
    image: $DELUGE_IMAGE
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
      - $HOME/usb_drive/adata:/adata
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
echo "All traffic is routed through PIA VPN. Downloads will be saved to $HOME/usb_drive/adata"
echo "Proxy access (if needed): HTTP/SOCKS at localhost:8118 (user: admin, pass: socks)"
echo "You can manage the container with lazydocker or $COMPOSE_CMD commands."
echo "To stop: $COMPOSE_CMD -f $COMPOSE_FILE down"
echo "Verify VPN: Run 'docker logs delugevpn' and look for successful connection/port forwarding messages."
