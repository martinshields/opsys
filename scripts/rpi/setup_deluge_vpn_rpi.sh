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

# Script to install Docker, , and docker.io-compose on Arch Linux or Raspberry Pi OS,
# then run Deluge with PIA VPN in a Docker container using docker.io-compose
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
if ! command_exists docker.io; then
    echo "Docker is not installed. Installing Docker..."
    if [ "$OS" = "arch" ]; then
        pkg_install || { echo "Failed to system"; exit 1; }
        pkg_install docker.io || { echo "Failed to Docker"; exit 1; }
    elif [ "$OS" = "debian" ]; then
        sudo apt-get update || { echo "Failed to update system"; exit 1; }
        pkg_install -y docker.io.io || { echo "Failed to Docker"; exit 1; }
    fi
    sudo systemctl start docker.io || { echo "Failed to start Docker service"; exit 1; }
    sudo systemctl enable docker.io
    if ! groups | grep -q docker.io; then
        sudo usermod -aG docker.io "$USER"
        echo "Added $USER to docker.io group. Run 'newgrp docker.io' or log out and back in to apply changes."
        newgrp docker.io 2>/dev/null || echo "Run 'newgrp docker.io' to apply group changes without logging out."
    fi
    # Verify Docker is running
    if ! docker.io info >/dev/null 2>&1; then
        echo "Docker is not running or accessible. Try running 'newgrp docker.io' or log out and back in."
        exit 1
    fi
else
    echo "Docker is already installed."
fi

# Install  based on OS
if ! command_exists ; then
    echo " is not installed. Installing ..."
    if [ "$OS" = "arch" ]; then
        pkg_install  || { echo "Failed to "; exit 1; }
    elif [ "$OS" = "debian" ]; then
        pkg_install -y curl || { echo "Failed to curl"; exit 1; }
        curl -L https://github.com/jesseduffield//releases/latest/download/lazydocker_"$(curl -s https://api.github.com/repos/jesseduffield//releases/latest | grep tag_name | cut -d '"' -f 4 | cut -c 2-)"_Linux_"$([ "$ARCH" = "aarch64" ] && echo "arm64" || echo "arm")".tar.gz | tar xz -C /tmp
        sudo mv /tmp/ /usr/local/bin/ || { echo "Failed to install "; exit YY1; }
    fi
    echo " installed."
else
    echo " is already installed."
fi

# Install docker.io-compose based on OS
if command_exists docker.io-compose; then
    COMPOSE_CMD="docker.io-compose"
elif docker.io compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker.io compose"
else
    echo "docker.io-compose is not installed. Installing docker.io-compose..."
    if [ "$OS" = "arch" ]; then
        if command_exists yay || command_exists paru; then
            yay -S --noconfirm docker.io-compose || paru -S --noconfirm docker.io-compose || { echo "Failed to install docker.io-compose. Ensure 'yay' or 'paru' is installed."; exit 1; }
            COMPOSE_CMD="docker.io-compose"
        else
            echo "No AUR helper (yay/paru) found. Install docker.io-compose manually or use 'docker.io compose' (Docker CLI)."
            echo "To install yay: pkg_install yay"
            exit 1
        fi
    elif [ "$OS" = "debian" ]; then
        pkg_install -y docker.io-compose || { echo "Failed to docker.io-compose"; exit 1; }
        COMPOSE_CMD="docker.io-compose"
    fi
    echo "docker.io-compose installed."
fi

# Check for port conflicts (web UI, torrent, and Privoxy ports)
for port in 8112 58846 8118; do
    if ss -tuln | grep -q ":$port "; then
        echo "Port $port is already in use. Please free it or modify the docker.io-compose.yaml ports."
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

# Create docker.io-compose.yaml for DelugeVPN
COMPOSE_FILE="$HOME/docker.io-compose.yaml"
if [ -f "$COMPOSE_FILE" ]; then
    echo "docker.io-compose.yaml already exists. Backing up to $COMPOSE_FILE.bak"
    mv "$COMPOSE_FILE" "$COMPOSE_FILE.bak"
fi
echo "Creating docker.io-compose.yaml for Deluge with PIA VPN..."
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
echo "docker.io-compose.yaml created at $COMPOSE_FILE"
echo "Edit LAN_NETWORK in $COMPOSE_FILE to match your local subnet if needed."

# Start DelugeVPN using docker.io-compose
echo "Starting DelugeVPN container with $COMPOSE_CMD... (This may take 30-60 seconds for VPN setup)"
$COMPOSE_CMD -f "$COMPOSE_FILE" up -d || { echo "Failed to start DelugeVPN container. Check logs with 'docker.io logs delugevpn'"; exit 1; }

# Wait a bit and check logs for VPN status
sleep 10
echo "Checking initial logs for VPN status..."
docker.io logs delugevpn 2>&1 | grep -E "(VPN| pia |openvpn|port forward)" | tail -5 || echo "No VPN-related logs found yet. Wait longer and check manually."

echo "DelugeVPN is running. Access the web UI at http://localhost:8112"
echo "WARNING: The default Deluge password is 'deluge'. Change it in the web UI immediately for security."
echo "All traffic is routed through PIA VPN. Downloads will be saved to $HOME/usb_drive/adata"
echo "Proxy access (if needed): HTTP/SOCKS at localhost:8118 (user: admin, pass: socks)"
echo "You can manage the container with  or $COMPOSE_CMD commands."
echo "To stop: $COMPOSE_CMD -f $COMPOSE_FILE down"
echo "Verify VPN: Run 'docker.io logs delugevpn' and look for successful connection/port forwarding messages."
