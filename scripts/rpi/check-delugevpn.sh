#!/usr/bin/env bash
# check-vpn.sh - Show DelugeVPN public IP and PIA port forward status

set -euo pipefail

CONTAINER="delugevpn"

# Check if container is running
if ! docker ps | grep -q "$CONTAINER"; then
    echo "ERROR: Container '$CONTAINER' is not running."
    echo "Start it with: docker compose -f ~/docker-compose-delugevpn.yaml up -d"
    exit 1
fi

echo "=== DELUGEVPN STATUS ==="
echo

# 1. Public IP (via VPN)
echo "Public IP (through PIA VPN):"
VPN_IP=$(docker exec "$CONTAINER" curl -s --fail https://ipinfo.io/ip || echo "Failed")
if [[ "$VPN_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "   $VPN_IP"
else
    echo "   Could not detect IP. Is VPN connected?"
fi
echo

# 2. Full IP info (optional, pretty)
echo "IP Location Details:"
docker exec "$CONTAINER" curl -s https://ipinfo.io/json | jq -r '
    "   City: \(.city), \(.region)",
    "   Country: \(.country)",
    "   ISP: \(.org)"
' 2>/dev/null || echo "   (Install 'jq' for pretty output: sudo apt install jq)"
echo

# 3. PIA Port Forwarding
echo "PIA Port Forwarding:"
docker logs "$CONTAINER" 2>/dev/null | grep -i "assigned.*port" | tail -1 || \
    echo "   No port forward detected yet. Wait 1-2 mins after VPN connects."

echo
echo "Tip: Set Deluge → Preferences → Connection → Incoming Port to the number above."
