#!/bin/bash
# Script to set up automatic USB drive mounting in user's home directory and create 'adata' folder with full permissions on Raspberry Pi

# Step 1: Identify the USB drive
echo "Listing available disks..."
lsblk

# Prompt user for the device name (e.g., /dev/sda1)
echo "Enter the device name of your USB drive (e.g., /dev/sda1):"
read usb_device

# Step 2: Create a mount point in the user's home directory
mount_point="/home/$USER/usb_drive"
sudo mkdir -p "$mount_point"

# Step 3: Get the UUID of the USB drive
uuid=$(sudo blkid -o value -s UUID "$usb_device")
if [ -z "$uuid" ]; then
    echo "Error: Could not find UUID for $usb_device. Please check the device name."
    exit 1
fi
echo "USB Drive UUID: $uuid"

# Step 4: Determine the filesystem type
fs_type=$(sudo blkid -o value -s TYPE "$usb_device")
if [ -z "$fs_type" ]; then
    echo "Error: Could not determine filesystem type for $usb_device."
    exit 1
fi
echo "Filesystem type: $fs_type"

# Step 5: Backup existing fstab
sudo cp /etc/fstab /etc/fstab.bak
echo "Backed up /etc/fstab to /etc/fstab.bak"

# Step 6: Add entry to fstab
fstab_entry="UUID=$uuid $mount_point $fs_type defaults,auto,users,rw,nofail 0 0"
echo "Adding fstab entry: $fstab_entry"
sudo sh -c "echo '$fstab_entry' >> /etc/fstab"

# Step 7: Test the mount
echo "Testing mount..."
sudo mount -a
if [ $? -eq 0 ]; then
    echo "Mount successful."
else
    echo "Error: Mount failed. Please check /etc/fstab and device details."
    exit 1
fi

# Step 8: Create the 'adata' folder
folder_name="adata"
folder_path="$mount_point/$folder_name"

# Check if the mount point is mounted
if ! mountpoint -q "$mount_point"; then
    echo "Error: $mount_point is not a mounted filesystem. Please mount the USB drive."
    exit 1
fi

echo "Creating folder $folder_path..."
sudo mkdir -p "$folder_path"

# Step 9: Set full permissions (read, write, execute) for all users
echo "Setting full permissions (777) for $folder_path..."
sudo chmod 777 "$folder_path"

# Step 10: Verify permissions
echo "Verifying permissions for $folder_path:"
ls -ld "$folder_path"

# Step 11: Display contents of fstab
echo "Current /etc/fstab contents:"
cat /etc/fstab

echo "Setup complete! USB drive will mount automatically at boot in $mount_point, and 'adata' folder created with full permissions."
echo "Reboot your Raspberry Pi to verify automatic mounting."