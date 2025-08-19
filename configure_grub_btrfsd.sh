#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Check if grub-btrfs and inotify-tools are installed
if ! command -v grub-btrfsd &> /dev/null || ! command -v inotifywait &> /dev/null; then
    echo "Installing required packages: grub-btrfs and inotify-tools..."
    if command -v pacman &> /dev/null; then
        pacman -S --noconfirm grub-btrfs inotify-tools
    elif command -v apt &> /dev/null; then
        apt update && apt install -y grub-btrfs inotify-tools
    elif command -v dnf &> /dev/null; then
        dnf install -y grub-btrfs inotify-tools
    else
        echo "Unsupported package manager. Please install grub-btrfs and inotify-tools manually."
        exit 1
    fi
fi

# Backup the original grub-btrfsd service file
SERVICE_FILE="/usr/lib/systemd/system/grub-btrfsd.service"
BACKUP_FILE="/usr/lib/systemd/system/grub-btrfsd.service.bak"
if [ -f "$SERVICE_FILE" ]; then
    echo "Backing up original service file to $BACKUP_FILE"
    cp "$SERVICE_FILE" "$BACKUP_FILE"
fi

# Create or edit the grub-btrfsd service file to include --timeshift-auto
echo "Configuring grub-btrfsd service to use --timeshift-auto..."
cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Regenerate grub-btrfs.cfg
DefaultDependencies=no
After=local-fs.target

[Service]
Type=simple
LogLevelMax=notice
Environment="PATH=/sbin:/bin:/usr/sbin:/usr/bin"
EnvironmentFile=/etc/default/grub-btrfs/config
ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon to apply changes
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable and start the grub-btrfsd service
echo "Enabling and starting grub-btrfsd service..."
systemctl enable --now grub-btrfsd

# Verify the service status
echo "Checking grub-btrfsd service status..."
systemctl status grub-btrfsd --no-pager

# Update GRUB configuration
echo "Updating GRUB configuration..."
if command -v grub2-mkconfig &> /dev/null; then
    grub2-mkconfig -o /boot/grub2/grub.cfg
else
    grub-mkconfig -o /boot/grub/grub.cfg
fi

echo "Configuration complete. Reboot to verify that Timeshift snapshots appear in the GRUB menu."