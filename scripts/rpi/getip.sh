#!/bin/bash

# Script to show local and public IP addresses

echo "Fetching IP addresses..."
echo "-----------------------------"

# Local (private) IP - using ip command (preferred)
LOCAL_IP=$(ip route get 1.1.1.1 | awk '{print $7}' | head -1)

# Alternative using hostname (fallback)
[ -z "$LOCAL_IP" ] && LOCAL_IP=$(hostname -I | awk '{print $1}')

echo "Local IP (inside network): $LOCAL_IP"

# Public (outside) IP - using external service
PUBLIC_IP=$(curl -s --connect-timeout 10 https://api.ipify.org)

if [ $? -eq 0 ] && [ -n "$PUBLIC_IP" ]; then
    echo "Public IP (outside world): $PUBLIC_IP"
else
    echo "Public IP: Failed to retrieve (check internet connection)"
fi

echo "-----------------------------"
