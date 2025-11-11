#!/usr/bin/env bash
# check-vpn.sh - Auto-install jq + show VPN IP + PIA port forward

set -euo pipefail

CONTAINER="delugevpn"

# --- Auto-install jq if missing ---
if ! command -v jq >/dev/null 2>&1; then
    echo "Installing 'jq' for nice formatting..."
    sudo apt-get update -qq
    sudo apt-get install -y jq > /dev/null
    echo "jq installed."
fi

# --- Check container ---
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}\$"; then
    echo "ERROR: Container '$CONTAINER' is not running."
    echo "Start it: docker compose -f ~/docker-compose-delugevpn.yaml up -d"
    exit 1
fi

echo "=== DELUGEVPN STATUS ==="
echo

# --- Public IP ---
echo "Public IP (via PIA VPN):"
VPN_IP=$(docker exec "$CONTAINER" curl -s --fail https://ipinfo.io/ip 2>/dev/null || echo "Unknown")
if [[ "$VPN_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    printf "   %s\n" "$VPN_IP"
else
    printf "   Failed to get IP (VPN down?)\n"
fi
echo

# --- Location Details ---
echo "Location & ISP:"
docker exec "$CONTAINER" curl -s https://ipinfo.io/json | jq -r '
    "   City: \(.city), \(.region)",
    "   Country: \(.country) – \(.hostname // "no hostname")",
    "   ISP: \(.org)"
' 2>/dev/null || echo "   (Failed to fetch geo data)"
echo

# --- Port Forwarding ---
echo "PIA Port Forward:"
PORT_LINE=$(docker logs "$CONTAINER" 2>/dev/null | grep -i "assigned.*port" | tail -1 || echo "")
if [[ -n "$PORT_LINE" ]]; then
    PORT=$(echo "$PORT_LINE" | grep -oE '[0-9]{4,5}' | tail -1)
    echo "   Active → Port $PORT"
    echo "   → Set in Deluge: Preferences → Connection → Incoming Ports: $PORT"
else
    echo "   Not active yet (wait 1-2 mins after VPN connects)"
fi

echo
echo "Done. Run this anytime: ~/check-vpn.sh"





