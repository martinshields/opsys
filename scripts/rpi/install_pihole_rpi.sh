#!/bin/bash

# Pi-hole Installation Script for Raspberry Pi 4
# Run this on a fresh Raspberry Pi OS (Lite recommended) installation.
# Ensure your RPi is connected to the internet and updated first.

# Step 1: Update system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install curl if not present (required for installer)
echo "Installing curl..."
sudo apt install curl -y

# Step 3: Download and run the official Pi-hole automated installer
echo "Starting Pi-hole installation..."
curl -sSL https://install.pi-hole.net | bash

# Step 4: After installation completes (follow prompts in the installer):
# - Choose upstream DNS (e.g., Cloudflare, Google)
# - Select blocklists
# - Install web admin interface and web server (lighttpd)
# - Enable logging if desired

# Step 5: Secure your Pi-hole (recommended post-install)
echo "Installation complete! Now secure your setup:"
echo "1. Change the admin password:"
echo "   sudo pihole -a -p"
echo ""
echo "2. Access the web dashboard at: http://pi.hole/admin or http://<your-pi-ip>/admin"
echo "   Find your Pi's IP with: hostname -I"
echo ""
echo "3. Set a static IP on your router for this Pi (recommended)"
echo ""
echo "4. Optional: Update Pi-hole later with: pihole -up"

# End of script



