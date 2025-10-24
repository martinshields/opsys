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

# Script to configure a static IP address on a Raspberry Pi

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (use sudo)."
  exit 1
fi

# Function to validate IP address format
validate_ip() {
  local ip=$1
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
    return 0
  else
    echo "Error: Invalid IP address format: $ip"
    exit 1
  fi
}

# Function to validate network interface
validate_interface() {
  local iface=$1
  if ip link show "$iface" >/dev/null 2>&1; then
    return 0
  else
    echo "Error: Network interface $iface does not exist."
    echo "Available interfaces:"
    ip link show | grep '^[0-9]' | cut -d: -f2 | awk '{print $1}'
    exit 1
  fi
}

# Prompt for network interface
echo "Enter the network interface (e.g., wlan0 for Wi-Fi, eth0 for Ethernet):"
read interface
validate_interface "$interface"

# Get current IP address and subnet mask
current_ip=$(ip addr show "$interface" | grep -w inet | awk '{print $2}' | head -n 1)
if [ -n "$current_ip" ]; then
  echo "Current IP address and subnet mask for $interface: $current_ip"
  echo "Would you like to use this IP and subnet mask for the static configuration? (y/n)"
  read use_current
  if [ "$use_current" = "y" ] || [ "$use_current" = "Y" ]; then
    ip_address="$current_ip"
  else
    echo "Enter the desired static IP address with subnet mask (e.g., 192.168.1.100/24):"
    read ip_address
    validate_ip "$ip_address"
  fi
else
  echo "Warning: Could not retrieve current IP address for $interface."
  echo "Enter the desired static IP address with subnet mask (e.g., 192.168.1.100/24):"
  read ip_address
  validate_ip "$ip_address"
fi

# Prompt for router/gateway IP
echo "Enter the router/gateway IP address (e.g., 192.168.1.1):"
read router_ip
validate_ip "$router_ip"

# Prompt for DNS servers
echo "Enter DNS server(s) (e.g., 192.168.1.1 8.8.8.8, separated by spaces):"
read dns_servers
for dns in $dns_servers; do
  validate_ip "$dns"
done

# Backup existing dhcpcd.conf with timestamp
backup_file="/etc/dhcpcd.conf.bak.$(date +%F_%H-%M-%S)"
echo "Backing up /etc/dhcpcd.conf to $backup_file"
cp /etc/dhcpcd.conf "$backup_file"

# Append static IP configuration to dhcpcd.conf
echo "Configuring static IP in /etc/dhcpcd.conf"
cat <<EOL >> /etc/dhcpcd.conf

# Static IP configuration for $interface
interface $interface
static ip_address=$ip_address
static routers=$router_ip
static domain_name_servers=$dns_servers
EOL

# Restart networking service
echo "Restarting dhcpcd service to apply changes"
if ! systemctl restart dhcpcd; then
  echo "Error: Failed to restart dhcpcd service. Please check the configuration."
  echo "Restore the backup with: sudo mv $backup_file /etc/dhcpcd.conf"
  exit 1
fi

# Verify the new IP address
echo "Verifying the IP address..."
sleep 5 # Increased delay for network stabilization
new_ip=$(ip addr show "$interface" | grep -w inet | awk '{print $2}' | cut -d'/' -f1 | head -n 1)
if [ -z "$new_ip" ]; then
  echo "Error: Could not retrieve IP address for $interface."
  echo "Restore the backup with: sudo mv $backup_file /etc/dhcpcd.conf"
  exit 1
fi
echo "Current IP address for $interface: $new_ip"

# Check if the assigned IP matches the requested IP
requested_ip=$(echo "$ip_address" | cut -d'/' -f1)
if [ "$new_ip" = "$requested_ip" ]; then
  echo "Static IP configuration applied successfully."
else
  echo "Warning: Configured IP ($new_ip) does not match requested IP ($requested_ip)."
fi

# Inform user to check connectivity
echo "Static IP configuration complete. Please test network connectivity (e.g., 'ping 8.8.8.8')."
echo "If there are issues, restore the backup with: sudo mv $backup_file /etc/dhcpcd.conf"
