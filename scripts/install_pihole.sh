#!/bin/bash

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
sudo apt install -y curl

# Step 3: Download and run the official Pi-hole installer
echo -e "${GREEN}Downloading and running Pi-hole installer...${NC}"
curl -sSL https://install.pi-hole.net | bash

# Step 4: Post-installation instructions
echo -e "${GREEN}Pi-hole installation completed!${NC}"
echo -e "Access the Pi-hole admin interface at: http://<your-pi-ip>/admin"
echo -e "Default login: Username: pihole, Password: (set during installation)"
echo -e "To change the Pi-hole admin password, run: ${GREEN}pihole -a -p${NC}"
echo -e "Ensure your router or devices are configured to use the Pi-hole DNS server at <your-pi-ip>"