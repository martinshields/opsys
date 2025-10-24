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

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Pi-hole installation on Raspberry Pi${NC}"

# Step 1: Update the system
echo -e "${GREEN}Updating package lists and upgrading system...${NC}"
sudo apt update && sudo apt upgrade -y

# Step 2: Install required dependencies
echo -e "${GREEN}Installing required dependencies...${NC}"
pkg_install -y curl

# Step 3: Download and run the official Pi-hole installer
echo -e "${GREEN}Downloading and running Pi-hole installer...${NC}"
curl -sSL https://install.pi-hole.net | bash

# Step 4: Post-installation instructions
echo -e "${GREEN}Pi-hole installation completed!${NC}"
echo -e "Access the Pi-hole admin interface at: http://<your-pi-ip>/admin"
echo -e "Default login: Username: pihole, Password: (set during installation)"
echo -e "To change the Pi-hole admin password, run: ${GREEN}pihole -a -p${NC}"
echo -e "Ensure your router or devices are configured to use the Pi-hole DNS server at <your-pi-ip>"
