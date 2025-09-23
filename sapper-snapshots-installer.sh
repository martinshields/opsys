#!/bin/bash

# This script installs and configures Snapper with GRUB integration on Arch Linux.
# It checks for required packages and installs them if missing.
# Assumes you have sudo privileges and an AUR helper like 'yay' installed.
# If 'yay' is not installed, install it manually first: git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
# Run this script with: sudo bash this_script.sh

set -e  # Exit on error

echo "Starting installation and configuration for Snapper with GRUB..."

# Function to check if a package is installed
is_installed() {
    pacman -Qi "$1" &> /dev/null
}

# Install official packages if not installed
PACKAGES=("snapper" "grub-btrfs" "inotify-tools")
for pkg in "${PACKAGES[@]}"; do
    if ! is_installed "$pkg"; then
        echo "Installing $pkg..."
        pacman -S --noconfirm "$pkg"
    else
        echo "$pkg is already installed."
    fi
done

# Check for AUR helper 'yay'
if ! command -v yay &> /dev/null; then
    echo "Error: 'yay' AUR helper not found. Please install it manually and rerun."
    exit 1
fi

# Install optional AUR package snap-pac-grub if not installed
AUR_PKG="snap-pac-grub"
if ! is_installed "$AUR_PKG"; then
    echo "Installing $AUR_PKG from AUR..."
    yay -S --noconfirm "$AUR_PKG"
else
    echo "$AUR_PKG is already installed."
fi

# Configure Snapper if not already done
SNAPPER_CONFIG="/etc/snapper/configs/root"
if [ ! -f "$SNAPPER_CONFIG" ]; then
    echo "Creating Snapper root config..."
    snapper -c root create-config /
else
    echo "Snapper root config already exists."
fi

# Enable and start services
SERVICES=("snapper-timeline.timer" "snapper-cleanup.timer" "grub-btrfsd.service")
for svc in "${SERVICES[@]}"; do
    if ! systemctl is-enabled "$svc" &> /dev/null; then
        echo "Enabling and starting $svc..."
        systemctl enable --now "$svc"
    else
        echo "$svc is already enabled."
    fi
done

# Generate GRUB config
echo "Generating GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "Installation and configuration complete! Reboot to see snapshots in GRUB."
echo "To create snapshots, use 'snapper' commands or wait for the timeline timer."
