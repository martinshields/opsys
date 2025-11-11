 #!/usr/bin/env bash
# ==============================================================
# Deluge + PIA VPN on Raspberry Pi (Docker + docker-compose)
# Works on Raspberry Pi OS (Debian) – aarch64 or armv7
# ==============================================================

set -euo pipefail
IFS=$'\n\t'

# ---------------------  USER SETTINGS  ------------------------
VPN_USER="p123456789"          # <-- YOUR PIA USERNAME
VPN_PASS="your_pia_password"   # <-- YOUR PIA PASSWORD
# --------------------------------------------------------------

# ----------  Helper: package manager (apt only on RPi) ----------
install_pkg() {
    sudo apt-get update
    sudo apt-get install -y "$@"
}

# ----------  Detect architecture ----------
ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64)  ARCH="arm64" ;;
    armv7*|armv6*)  ARCH="armv7" ;;
    *)              echo "Unsupported arch: $ARCH"; exit 1 ;;
esac
echo "Detected architecture: $ARCH"

# ----------  Create host directories ----------
DATA_DIR="$HOME/usb_drive/adata"
CONFIG_DIR="$HOME/delugevpn/config/openvpn"

mkdir -p "$DATA_DIR" "$CONFIG_DIR"
chmod 775 "$DATA_DIR"
chown "$USER:$USER" "$DATA_DIR"
echo "Host folders ready:"
echo "  Downloads → $DATA_DIR"
echo "  OpenVPN config → $CONFIG_DIR  (drop your .ovpn + ca.crt here if you have them)"

# ----------  Install Docker Engine ----------
if ! command -v docker >/dev/null 2>&1; then
    echo "Installing Docker Engine..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    echo "Docker installed. Log out/in or run 'newgrp docker' to apply group."
else
    echo "Docker already installed."
fi

# ----------  Install docker-compose (v2 plugin) ----------
if ! docker compose version >/dev/null 2>&1; then
    echo "Installing docker-compose plugin..."
    COMPOSE_VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-linux-$(uname -m)" \
         -o /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi
COMPOSE_CMD="docker compose"

# ----------  Install lazydocker (optional UI) ----------
if ! command -v lazydocker >/dev/null 2>&1; then
    echo "Installing lazydocker..."
    LAZY_VER=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')
    curl -L https://github.com/jesseduffield/lazydocker/releases/download/v${LAZY_VER}/lazydocker_${LAZY_VER}_Linux_arm64.tar.gz \
         | tar xz -C /tmp lazydocker
    sudo mv /tmp/lazydocker /usr/local/bin/
    echo "lazydocker installed."
else
    echo "lazydocker already present."
fi

# ----------  Port conflict check ----------
for port in 8112 58846 8118; do
    if ss -tuln | grep -q ":$port "; then
        echo "ERROR: Port $port already in use."
        exit 1
    fi
done

# ----------  Choose ARM-compatible image ----------
DELUGE_IMAGE="linuxserver/deluge:latest"
echo "Using ARM-compatible image: $DELUGE_IMAGE"

# ----------  Write docker-compose.yaml ----------
COMPOSE_FILE="$HOME/docker-compose-delugevpn.yaml"
TZ=$(cat /etc/timezone 2>/dev/null || echo "Etc/UTC")

cat > "$COMPOSE_FILE" <<EOF
version: "3.8"
services:
  delugevpn:
    image: ${DELUGE_IMAGE}
    container_name: delugevpn
    cap_add:
      - NET_ADMIN
    environment:
      - PUID=$(id -u)
      - PGID=$(id -g)
      - TZ=${TZ}
      - VPN_ENABLED=yes
      - VPN_USER=${VPN_USER}
      - VPN_PASS=${VPN_PASS}
      - VPN_PROV=pia
      - VPN_CLIENT=openvpn
      - STRICT_PORT_FORWARD=yes
      - ENABLE_PRIVOXY=yes
      - LAN_NETWORK=192.168.1.0/24   # <<< CHANGE IF YOUR LAN IS DIFFERENT THEN 192.168.1.0/24 You can run getip.sh to find out.
      - NAME_SERVERS=1.1.1.1,8.8.4.4
      - UMASK=000
    ports:
      - 8112:8112      # Web UI
      - 58846:58846    # Daemon
      - 58846:58846/udp
      - 8118:8118      # Privoxy
    volumes:
      - ${HOME}/delugevpn/config:/config
      - ${DATA_DIR}:/data
    restart: unless-stopped
EOF
echo "docker-compose file created: $COMPOSE_FILE"

# ----------  Start container ----------
echo "Starting Deluge + PIA VPN (may take 30-60 s for VPN handshake)..."
$COMPOSE_CMD -f "$COMPOSE_FILE" up -d

# ----------  Final instructions ----------
sleep 12
echo "=== CONTAINER LOGS (last VPN lines) ==="
docker logs delugevpn 2>&1 | grep -E "(VPN|openvpn|port forward|pia)" | tail -5 || true

cat <<EOS

================================================================
DelugeVPN is now running!

  Web UI      → http://$(hostname -I | awk '{print $1}'):8112
  Default pwd → deluge   (CHANGE IT IMMEDIATELY!)
  Downloads   → $DATA_DIR
  Privoxy     → localhost:8118 (user: admin, pass: socks)

Commands:
  Stop   → $COMPOSE_CMD -f $COMPOSE_FILE down
  Logs   → docker logs -f delugevpn
  UI     → lazydocker
================================================================
EOS



