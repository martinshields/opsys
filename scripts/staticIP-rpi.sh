#!/bin/bash

# Script to configure a static IP address on a Raspberry Pi

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (use sudo)."
  exit 1
fi

# Prompt for network interface
echo "Enter the network interface (e.g., wlan0 for Wi-Fi, eth0 for Ethernet):"
read interface

# Prompt for static IP address
echo "Enter the desired static IP address with subnet mask (e.g., 192.168.1.100/24):"
read ip_address

# Prompt for router/gateway IP
echo "Enter the router/gateway IP address (e.g., 192.168.1.1):"
read router_ip

# Prompt for DNS servers
echo "Enter DNS server(s) (e.g., 192.168.1.1 8.8.8.8, separated by spaces):"
read dns_servers

# Backup existing dhcpcd.conf
echo "Backing up /etc/dhcpcd.conf to /etc/dhcpcd.conf.bak"
cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak

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
systemctl restart dhcpcd

# Verify the new IP address
echo "Verifying the IP address..."
sleep 2 # Wait for network service to restart
new_ip=$(hostname -I | awk '{print $1}')
echo "Current IP address: $new_ip"

# Inform user to check connectivity
echo "Static IP configuration complete. Please test network connectivity (e.g., 'ping 8.8.8.8')."
echo "If there are issues, restore the backup with: sudo mv /etc/dhcpcd.conf.bak /etc/dhcpcd.conf"
