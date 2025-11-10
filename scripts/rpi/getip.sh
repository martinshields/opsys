#!/bin/bash
# Script to show local IP, public IP, and LAN network (CIDR)
echo "Fetching IP addresses and network..."
echo "-----------------------------------"

# Local (private) IP - using ip command (preferred)
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1)
# Fallback using hostname
[ -z "$LOCAL_IP" ] && LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

echo "Local IP (inside network): $LOCAL_IP"

# Determine LAN network (CIDR) using 'ip route' - find the route to a public IP
LAN_NETWORK=$(ip route get 1.1.1.1 2>/dev/null | awk 'NR==1 {for(i=1;i<=NF;i++) if($i=="src") print $(i+1) "/" $(i+3)}' | head -1)
# Fallback: parse default route's network
[ -z "$LAN_NETWORK" ] && LAN_NETWORK=$(ip route show default 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1) "/" $(i+3)}' | head -1)
# Final fallback: try to infer from interface route
[ -z "$LAN_NETWORK" ] && LAN_NETWORK=$(ip route | grep -v default | grep -E '^[0-9]' | head -1 | awk '{print $1}')

if [ -n "$LAN_NETWORK" ]; then
    echo "LAN Network (CIDR)       : $LAN_NETWORK"
else
    echo "LAN Network (CIDR)       : Unable to determine"
fi

# Public (outside) IP - using external service
PUBLIC_IP=$(curl -s --connect-timeout 10 https://api.ipify.org)
if [ $? -eq 0 ] && [ -n "$PUBLIC_IP" ]; then
    echo "Public IP (outside world): $PUBLIC_IP"
else
    echo "Public IP                : Failed to retrieve (check internet connection)"
fi

echo "-----------------------------------"

