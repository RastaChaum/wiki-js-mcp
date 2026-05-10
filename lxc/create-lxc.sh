#!/bin/bash
# ============================================================
# Proxmox LXC Creator — Wiki.js MCP Server
# À exécuter sur l'hôte Proxmox (shell PVE)
# ============================================================
set -euo pipefail

# ─── Paramètres personnalisables ────────────────────────────
VMID="${VMID:-200}"
HOSTNAME="${HOSTNAME:-wiki-mcp}"
STORAGE="${STORAGE:-local-lvm}"    # stockage pour le disque rootfs
TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-local}"  # stockage des templates CT
DISK_SIZE="${DISK_SIZE:-4}"        # Go
MEMORY="${MEMORY:-512}"            # Mo
CORES="${CORES:-1}"
BRIDGE="${BRIDGE:-vmbr0}"
IP="${IP:-dhcp}"                   # ex: "192.168.1.50/24" pour IP fixe
GW="${GW:-}"                       # ex: "192.168.1.1" (requis si IP fixe)
DNS="${DNS:-8.8.8.8}"
MCP_PORT="${MCP_PORT:-8000}"
# ────────────────────────────────────────────────────────────

TEMPLATE="debian-12-standard_12.7-1_amd64.tar.zst"
TEMPLATE_PATH="$TEMPLATE_STORAGE:vztmpl/$TEMPLATE"

echo "=== Wiki.js MCP Server — Création LXC Proxmox ==="
echo "  VMID     : $VMID"
echo "  Hostname : $HOSTNAME"
echo "  Storage  : $STORAGE  (disk: ${DISK_SIZE}G)"
echo "  Memory   : ${MEMORY}Mo  CPU: ${CORES} core(s)"
echo "  Réseau   : bridge=$BRIDGE  IP=$IP"
echo ""

# Télécharger le template si absent
if ! pveam list "$TEMPLATE_STORAGE" 2>/dev/null | grep -q "$TEMPLATE"; then
    echo ">>> Téléchargement du template Debian 12..."
    pveam update
    pveam download "$TEMPLATE_STORAGE" "$TEMPLATE"
fi

# Construire la config réseau
if [ "$IP" = "dhcp" ]; then
    NET_CONFIG="name=eth0,bridge=${BRIDGE},ip=dhcp"
else
    NET_CONFIG="name=eth0,bridge=${BRIDGE},ip=${IP}"
    [ -n "$GW" ] && NET_CONFIG="${NET_CONFIG},gw=${GW}"
fi

echo ">>> Création du conteneur LXC $VMID..."
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

echo ">>> Démarrage du conteneur..."
pct start "$VMID"
sleep 5

echo ">>> Copie du script d'installation dans le conteneur..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pct push "$VMID" "$SCRIPT_DIR/install.sh" /root/install.sh --perms 755

echo ""
echo ">>> Installation en cours dans le conteneur (peut prendre 2-3 min)..."
pct exec "$VMID" -- bash /root/install.sh

echo ""
echo "=== INSTALLATION TERMINÉE ==="
CONTAINER_IP=$(pct exec "$VMID" -- hostname -I 2>/dev/null | awk '{print $1}')
echo ""
echo "Le serveur MCP tourne sur : http://${CONTAINER_IP}:${MCP_PORT}/sse"
echo ""
echo "Prochaines étapes :"
echo "  1. Configurer /opt/wiki-js-mcp/.env dans le conteneur :"
echo "       pct exec $VMID -- nano /opt/wiki-js-mcp/.env"
echo "  2. Redémarrer le service :"
echo "       pct exec $VMID -- systemctl restart wiki-js-mcp"
echo "  3. Ajouter dans votre config MCP (VS Code, Cursor, etc.) :"
echo '       { "mcpServers": { "wikijs": { "url": "http://'"${CONTAINER_IP}:${MCP_PORT}"'/sse" } } }'
