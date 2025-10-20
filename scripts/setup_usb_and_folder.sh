#!/bin/bash
# Script to format a USB drive to ext4, set up automatic mounting in user's home directory, and create 'adata' folder with full permissions for the user on Raspberry Pi

# Check for sudo privileges
if ! sudo -n true 2>/dev/null; then
    echo "Error: This script requires sudo privileges."
    exit 1
fi

# Step 1: Identify the USB drive
echo "Listing available disks..."
lsblk

# Prompt user for the device name (e.g., /dev/sda1)
echo "Enter the device name of your USB drive (e.g., /dev/sda1):"
read usb_device

# Validate device
if [ ! -b "$usb_device" ]; then
    echo "Error: $usb_device is not a valid block device."
    exit 1
fi

# Safety check: Prevent formatting system drives
if [[ "$usb_device" == /dev/mmcblk* ]] || [[ "$usb_device" == /dev/nvme* ]] || [[ "$usb_device" == /dev/sd*[a-z] ]]; then
    echo "Warning: $usb_device may be a system or critical drive."
    echo "Formatting will ERASE ALL DATA on $usb_device. Are you sure you want to proceed? (Type 'YES' to confirm)"
    read confirm_format
    if [ "$confirm_format" != "YES" ]; then
        echo "Aborting: User did not confirm formatting."
        exit 1
    fi
else
    echo "Formatting will ERASE ALL DATA on $usb_device. Are you sure you want to proceed? (Type 'YES' to confirm)"
    read confirm_format
    if [ "$confirm_format" != "YES" ]; then
        echo "Aborting: User did not confirm formatting."
        exit 1
    fi
fi

# Step 2: Format the USB drive to ext4
echo "Formatting $usb_device to ext4..."
sudo mkfs.ext4 -F "$usb_device"
if [ $? -ne 0 ]; then
    echo "Error: Failed to format $usb_device to ext4."
    exit 1
fi
echo "Format successful."

# Step 3: Create a mount point in the user's home directory
mount_point="/home/$USER/usb_drive"
if mountpoint -q "$mount_point"; then
    echo "Error: $mount_point is already a mount point. Please choose a different location."
    exit 1
fi
sudo mkdir -p "$mount_point"

# Step 4: Get the UUID of the USB drive
uuid=$(sudo blkid -o value -s UUID "$usb_device")
if [ -z "$uuid" ]; then
    echo "Error: Could not find UUID for $usb_device. Please check the device."
    exit 1
fi
echo "USB Drive UUID: $uuid"

# Step 5: Check for existing fstab entry
if grep -q "$uuid" /etc/fstab; then
    echo "Error: An entry for UUID $uuid already exists in /etc/fstab."
    exit 1
fi

# Step 6: Backup existing fstab
sudo cp /etc/fstab /etc/fstab.bak
echo "Backed up /etc/fstab to /etc/fstab.bak"

# Step 7: Add entry to fstab (ext4-specific)
fstab_entry="UUID=$uuid $mount_point ext4 defaults,auto,users,rw,nofail 0 0"
echo "Adding fstab entry: $fstab_entry"
sudo sh -c "echo '$fstab_entry' >> /etc/fstab"

# Step 8: Test the mount
echo "Testing mount..."
sudo mount -a
if [ $? -ne 0 ]; then
    echo "Error: Mount failed. Restoring original /etc/fstab..."
    sudo mv /etc/fstab.bak /etc/fstab
    exit 1
fi
echo "Mount successful."

# Step 9: Create the 'adata' folder
folder_name="adata"
folder_path="$mount_point/$folder_name"
if ! mountpoint -q "$mount_point"; then
    echo "Error: $mount_point is not a mounted filesystem. Please mount the USB drive."
    exit 1
fi
echo "Creating folder $folder_path..."
sudo mkdir -p "$folder_path"

# Step 10: Set ownership to the current user
echo "Setting ownership of $folder_path to $USER..."
sudo chown "$USER:$(id -gn)" "$folder_path"

# Step 11: Prompt for permission scope
echo "Choose permissions for $folder_path:"
echo "1) Full permissions for user only (700)"
echo "2) Full permissions for user and group (770)"
echo "3) Full permissions for all users (777)"
read -p "Enter choice (1, 2, or 3) [default: 1]: " perm_choice
case "$perm_choice" in
    2)
        perms="770"
        ;;
    3)
        perms="777"
        ;;
    *)
        perms="700"
        ;;
esac
echo "Setting permissions ($perms) for $folder_path..."
sudo chmod "$perms" "$folder_path"

# Step 12: Verify permissions
echo "Verifying permissions for $folder_path:"
ls -ld "$folder_path"

# Step 13: Display contents of fstab
echo "Current /etc/fstab contents:"
cat /etc/fstab

# Step 14: Offer reboot
echo "Setup complete! USB drive formatted to ext4, will mount automatically at boot in $mount_point, and 'adata' folder created with permissions $perms for $USER."
echo "Would you like to reboot now to verify automatic mounting? (y/n)"
read reboot_choice
if [ "$reboot_choice" = "y" ] || [ "$reboot_choice" = "Y" ]; then
    sudo reboot
fi
