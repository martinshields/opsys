#!/bin/bash

# Script to set up Samba on Raspberry Pi and configure a shared folder with specific settings

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (use sudo)."
  exit 1
fi

# Update and install Samba
echo "Updating package list and installing Samba..."
apt update && apt install -y samba samba-common-bin

# Check if Samba installed successfully
if ! command -v smbd &> /dev/null; then
  echo "Samba installation failed. Please check your internet connection or package manager."
  exit 1
fi

# Prompt for the folder to share
echo "Please enter the full path of the folder you want to share (e.g., /home/pi/share):"
read -r SHARE_PATH

# Validate folder path
if [ ! -d "$SHARE_PATH" ]; then
  echo "Directory does not exist. Would you like to create it? (y/n)"
  read -r CREATE_DIR
  if [ "$CREATE_DIR" = "y" ] || [ "$CREATE_DIR" = "Y" ]; then
    mkdir -p "$SHARE_PATH"
    echo "Created directory $SHARE_PATH"
  else
    echo "Exiting: No valid directory provided."
    exit 1
  fi
fi

# Prompt for the system user (for context, but not used for ownership)
echo "Enter the system user for reference (e.g., pi):"
read -r SYSTEM_USER

# Validate that the user exists
if ! id "$SYSTEM_USER" &> /dev/null; then
  echo "Error: User '$SYSTEM_USER' does not exist. Please create the user or choose an existing one."
  exit 1
fi

# Prompt for share name
echo "Enter a name for the Samba share (e.g., PiShare):"
read -r SHARE_NAME

# Set folder permissions (align with Samba settings: nobody:nogroup, 777)
chown -R nobody:nogroup "$SHARE_PATH"
chmod -R 777 "$SHARE_PATH"

# Backup existing Samba configuration
if [ -f /etc/samba/smb.conf ]; then
  cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
  echo "Backed up existing Samba configuration to /etc/samba/smb.conf.bak"
fi

# Add share configuration to smb.conf with specified settings
cat >> /etc/samba/smb.conf << EOF

[$SHARE_NAME]
   path = $SHARE_PATH
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   create mask = 0777
   directory mask = 0777
   force user = nobody
   force group = nogroup
EOF

# Test Samba configuration
echo "Testing Samba configuration..."
testparm -s
if [ $? -ne 0 ]; then
  echo "Samba configuration test failed. Please check /etc/samba/smb.conf for errors."
  exit 1
fi

# Restart Samba services
echo "Restarting Samba services..."
systemctl restart smbd
systemctl restart nmbd

# Get Raspberry Pi's IP address
IP=$(hostname -I | awk '{print $1}')
echo "Samba setup complete!"
echo "Shared folder: $SHARE_PATH"
echo "Share name: $SHARE_NAME"
echo "Access it from another device using: \\\\$IP\\$SHARE_NAME"
echo "The share is accessible to guests (no authentication required)."

# Optional: Open firewall ports if ufw is enabled
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
  echo "Opening Samba ports in firewall..."
  ufw allow Samba
fi

echo "Setup complete. If you encounter issues, check /etc/samba/smb.conf or restart the Pi."
