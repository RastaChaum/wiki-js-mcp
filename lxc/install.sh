#!/bin/bash
# ============================================================
# Script d'installation — Wiki.js MCP Server (dans le LXC)
# Exécuté automatiquement par create-lxc.sh
# Peut aussi être relancé manuellement pour mise à jour
# ============================================================
set -euo pipefail

INSTALL_DIR="/opt/wiki-js-mcp"
SERVICE_USER="wikimcp"
REPO_URL="https://github.com/RastaChaum/wiki-js-mcp.git"
REPO_BRANCH="feature/add-locale-parameter"
MCP_PORT="${MCP_PORT:-8000}"

echo "=== Installation Wiki.js MCP Server ==="

# Mise à jour du système
echo ">>> Mise à jour des paquets..."
apt-get update -qq
apt-get install -y -qq \
    python3 python3-pip python3-venv \
    git curl ca-certificates \
    2>/dev/null

# Python 3.12 minimum check
PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
PYTHON_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 12 ]); then
    echo ">>> Python 3.12+ requis, installation depuis deadsnakes PPA..."
    apt-get install -y -qq software-properties-common
    # Pour Debian 12 : Python 3.12 est déjà disponible nativement
    apt-get install -y -qq python3.12 python3.12-venv python3.12-pip 2>/dev/null || true
fi

# Créer l'utilisateur de service
if ! id "$SERVICE_USER" &>/dev/null; then
    echo ">>> Création de l'utilisateur $SERVICE_USER..."
    useradd -r -s /bin/false -d "$INSTALL_DIR" "$SERVICE_USER"
fi

# Cloner ou mettre à jour le dépôt
if [ -d "$INSTALL_DIR/.git" ]; then
    echo ">>> Mise à jour du dépôt existant..."
    git -C "$INSTALL_DIR" fetch origin
    git -C "$INSTALL_DIR" checkout "$REPO_BRANCH"
    git -C "$INSTALL_DIR" pull origin "$REPO_BRANCH"
else
    echo ">>> Clonage du dépôt..."
    git clone --branch "$REPO_BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi

# Créer l'environnement virtuel Python
echo ">>> Création de l'environnement virtuel Python..."
PYTHON_CMD="python3"
command -v python3.12 &>/dev/null && PYTHON_CMD="python3.12"

"$PYTHON_CMD" -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip -q
"$INSTALL_DIR/venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt" -q

# Créer le .env depuis l'exemple si absent
if [ ! -f "$INSTALL_DIR/.env" ]; then
    echo ">>> Création du fichier .env depuis l'exemple..."
    cp "$INSTALL_DIR/config/example.env" "$INSTALL_DIR/.env"
    # Configurer le transport SSE par défaut pour le LXC
    echo "" >> "$INSTALL_DIR/.env"
    echo "# Transport réseau (SSE pour accès multi-clients sur le réseau)" >> "$INSTALL_DIR/.env"
    echo "MCP_TRANSPORT=sse" >> "$INSTALL_DIR/.env"
    echo "MCP_HOST=0.0.0.0" >> "$INSTALL_DIR/.env"
    echo "MCP_PORT=${MCP_PORT}" >> "$INSTALL_DIR/.env"
    echo ""
    echo "ATTENTION : Configurez /opt/wiki-js-mcp/.env avant de démarrer le service !"
    echo "  Champs requis : WIKIJS_API_URL, WIKIJS_TOKEN (ou WIKIJS_USERNAME + WIKIJS_PASSWORD)"
fi

# Créer les répertoires nécessaires
mkdir -p "$INSTALL_DIR/logs"

# Droits sur le répertoire
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"

# Installer le service systemd
echo ">>> Installation du service systemd..."
cp "$INSTALL_DIR/lxc/wiki-js-mcp.service" /etc/systemd/system/wiki-js-mcp.service
systemctl daemon-reload
systemctl enable wiki-js-mcp

# Démarrer uniquement si .env est configuré
if grep -q "^WIKIJS_API_URL=http" "$INSTALL_DIR/.env" 2>/dev/null; then
    echo ">>> Démarrage du service..."
    systemctl start wiki-js-mcp
    sleep 2
    systemctl is-active wiki-js-mcp && echo "Service démarré avec succès" || echo "Le service n'a pas démarré — vérifiez la configuration .env"
else
    echo ""
    echo ">>> Service NON démarré : configurez d'abord $INSTALL_DIR/.env"
    echo "    Puis : systemctl start wiki-js-mcp"
fi

echo ""
echo "=== Installation terminée ==="
echo "  Répertoire : $INSTALL_DIR"
echo "  Service    : systemctl {start|stop|status|restart} wiki-js-mcp"
echo "  Logs       : journalctl -u wiki-js-mcp -f"
echo "  Config     : $INSTALL_DIR/.env"
