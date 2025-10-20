#!/bin/bash

# Script to set up Samba on Raspberry Pi and configure a shared folder

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

# Prompt for share name
echo "Enter a name for the Samba share (e.g., PiShare):"
read -r SHARE_NAME

# Prompt for permissions
echo "Choose permissions for the share:"
echo "1) Read-only for everyone"
echo "2) Read-write for everyone"
echo "3) Read-write for authenticated users only"
read -r PERM_CHOICE

# Set Samba configuration based on choice
case $PERM_CHOICE in
  1)
    PERM="read only = yes"
    GUEST="guest ok = yes"
    ;;
  2)
    PERM="read only = no"
    GUEST="guest ok = yes"
    ;;
  3)
    PERM="read only = no"
    GUEST="guest ok = no"
    ;;
  *)
    echo "Invalid choice. Defaulting to read-only for everyone."
    PERM="read only = yes"
    GUEST="guest ok = yes"
    ;;
esac

# Set folder permissions (ensure pi user and group can access)
chown -R pi:pi "$SHARE_PATH"
chmod -R 775 "$SHARE_PATH"

# Backup existing Samba configuration
if [ -f /etc/samba/smb.conf ]; then
  cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
  echo "Backed up existing Samba configuration to /etc/samba/smb.conf.bak"
fi

# Add share configuration to smb.conf
cat >> /etc/samba/smb.conf << EOF

[$SHARE_NAME]
   path = $SHARE_PATH
   $PERM
   $GUEST
   browsable = yes
   create mask = 0775
   directory mask = 0775
EOF

# If authenticated users are selected, prompt for Samba user setup
if [ "$PERM_CHOICE" = "3" ]; then
  echo "Setting up Samba user. Enter the username for Samba access (e.g., pi):"
  read -r SAMBA_USER
  echo "Enter the password for the Samba user:"
  smbpasswd -a "$SAMBA_USER"
  if [ $? -ne 0 ]; then
    echo "Failed to set Samba user password. Please set it manually using 'smbpasswd -a $SAMBA_USER'."
  else
    echo "Samba user $SAMBA_USER configured."
  fi
fi

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
if [ "$PERM_CHOICE" = "3" ]; then
  echo "Use the Samba username and password to access the share."
else
  echo "The share is accessible to guests."
fi

# Optional: Open firewall ports if ufw is enabled
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
  echo "Opening Samba ports in firewall..."
  ufw allow Samba
fi

echo "Setup complete. If you encounter issues, check /etc/samba/smb.conf or restart the Pi."
