#!/bin/bash
# ============================================================
# Proxmox LXC Creator — Wiki.js MCP Server
# Run on the Proxmox host shell (root)
# ============================================================
set -euo pipefail

# ─── Configurable parameters ────────────────────────────────
VMID="${VMID:-200}"
HOSTNAME="${HOSTNAME:-wiki-mcp}"
STORAGE="${STORAGE:-local-lvm}"    # Storage pool for the rootfs disk
TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-local}"  # Storage pool for CT templates
DISK_SIZE="${DISK_SIZE:-4}"        # GB
MEMORY="${MEMORY:-512}"            # MB
CORES="${CORES:-1}"
BRIDGE="${BRIDGE:-vmbr0}"
IP="${IP:-dhcp}"                   # e.g. "192.168.1.50/24" for a static IP
GW="${GW:-}"                       # e.g. "192.168.1.1" (required for static IP)
DNS="${DNS:-8.8.8.8}"
MCP_PORT="${MCP_PORT:-8000}"
# ────────────────────────────────────────────────────────────

TEMPLATE="debian-12-standard_12.7-1_amd64.tar.zst"
TEMPLATE_PATH="$TEMPLATE_STORAGE:vztmpl/$TEMPLATE"

echo "=== Wiki.js MCP Server — Proxmox LXC Creation ==="
echo "  VMID     : $VMID"
echo "  Hostname : $HOSTNAME"
echo "  Storage  : $STORAGE  (disk: ${DISK_SIZE}G)"
echo "  Memory   : ${MEMORY}MB  CPU: ${CORES} core(s)"
echo "  Network  : bridge=$BRIDGE  IP=$IP"
echo ""

# Download template if not already present
if ! pveam list "$TEMPLATE_STORAGE" 2>/dev/null | grep -q "$TEMPLATE"; then
    echo ">>> Downloading Debian 12 template..."
    pveam update
    pveam download "$TEMPLATE_STORAGE" "$TEMPLATE"
fi

# Build network configuration string
if [ "$IP" = "dhcp" ]; then
    NET_CONFIG="name=eth0,bridge=${BRIDGE},ip=dhcp"
else
    NET_CONFIG="name=eth0,bridge=${BRIDGE},ip=${IP}"
    [ -n "$GW" ] && NET_CONFIG="${NET_CONFIG},gw=${GW}"
fi

echo ">>> Creating LXC container $VMID..."
pct create "$VMID" "$TEMPLATE_PATH" \
    --hostname "$HOSTNAME" \
    --storage "$STORAGE" \
    --rootfs "${STORAGE}:${DISK_SIZE}" \
    --memory "$MEMORY" \
    --cores "$CORES" \
    --net0 "$NET_CONFIG" \
    --nameserver "$DNS" \
    --unprivileged 1 \
    --features nesting=1 \
    --onboot 1 \
    --start 0

echo ">>> Starting container..."
pct start "$VMID"
sleep 5

echo ">>> Copying install script into the container..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pct push "$VMID" "$SCRIPT_DIR/install.sh" /root/install.sh --perms 755

echo ""
echo ">>> Running installation inside the container (may take 2-3 min)..."
pct exec "$VMID" -- bash /root/install.sh

echo ""
echo "=== INSTALLATION COMPLETE ==="
CONTAINER_IP=$(pct exec "$VMID" -- hostname -I 2>/dev/null | awk '{print $1}')
echo ""
echo "MCP server endpoint: http://${CONTAINER_IP}:${MCP_PORT}/sse"
echo ""
echo "Prochaines étapes :"
echo "  1. Configurer /opt/wiki-js-mcp/.env dans le conteneur :"
echo "       pct exec $VMID -- nano /opt/wiki-js-mcp/.env"
echo "  2. Redémarrer le service :"
echo "       pct exec $VMID -- systemctl restart wiki-js-mcp"
echo "  3. Ajouter dans votre config MCP (VS Code, Cursor, etc.) :"
echo '       { "mcpServers": { "wikijs": { "url": "http://'"${CONTAINER_IP}:${MCP_PORT}"'/sse" } } }'
