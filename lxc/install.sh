#!/bin/bash
# ============================================================
# Installation script — Wiki.js MCP Server (inside the LXC)
# Executed automatically by create-lxc.sh
# Can also be run manually to update an existing installation
# ============================================================
set -euo pipefail

INSTALL_DIR="/opt/wiki-js-mcp"
SERVICE_USER="wikimcp"
REPO_URL="https://github.com/RastaChaum/wiki-js-mcp.git"
REPO_BRANCH="feature/add-locale-parameter"
MCP_PORT="${MCP_PORT:-8000}"

echo "=== Wiki.js MCP Server Installation ==="

# System update
echo ">>> Updating packages..."
apt-get update -qq
apt-get install -y -qq \
    python3 python3-pip python3-venv \
    git curl ca-certificates \
    2>/dev/null

# Python 3.12 minimum check
PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
PYTHON_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 12 ]); then
    echo ">>> Python 3.12+ required, installing from system packages..."
    apt-get install -y -qq software-properties-common
    # On Debian 12: Python 3.12 is available natively
    apt-get install -y -qq python3.12 python3.12-venv python3.12-pip 2>/dev/null || true
fi

# Create service user
if ! id "$SERVICE_USER" &>/dev/null; then
    echo ">>> Creating service user $SERVICE_USER..."
    useradd -r -s /bin/false -d "$INSTALL_DIR" "$SERVICE_USER"
fi

# Clone or update the repository
if [ -d "$INSTALL_DIR/.git" ]; then
    echo ">>> Updating existing repository..."
    git -C "$INSTALL_DIR" fetch origin
    git -C "$INSTALL_DIR" checkout "$REPO_BRANCH"
    git -C "$INSTALL_DIR" pull origin "$REPO_BRANCH"
else
    echo ">>> Cloning repository..."
    git clone --branch "$REPO_BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi

# Create Python virtual environment
echo ">>> Creating Python virtual environment..."
PYTHON_CMD="python3"
command -v python3.12 &>/dev/null && PYTHON_CMD="python3.12"

"$PYTHON_CMD" -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip -q
"$INSTALL_DIR/venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt" -q

# Create .env from example if it doesn't exist
if [ ! -f "$INSTALL_DIR/.env" ]; then
    echo ">>> Creating .env file from example..."
    cp "$INSTALL_DIR/config/example.env" "$INSTALL_DIR/.env"
    # Enable SSE transport by default for LXC deployment
    echo "" >> "$INSTALL_DIR/.env"
    echo "# Network transport (SSE for network-wide access)" >> "$INSTALL_DIR/.env"
    echo "MCP_TRANSPORT=sse" >> "$INSTALL_DIR/.env"
    echo "MCP_HOST=0.0.0.0" >> "$INSTALL_DIR/.env"
    echo "MCP_PORT=${MCP_PORT}" >> "$INSTALL_DIR/.env"
    echo ""
    echo "IMPORTANT: Configure /opt/wiki-js-mcp/.env before starting the service!"
    echo "  Required fields: WIKIJS_API_URL, WIKIJS_TOKEN (or WIKIJS_USERNAME + WIKIJS_PASSWORD)"
fi

# Create required directories
mkdir -p "$INSTALL_DIR/logs"

# Set ownership
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"

# Install systemd service
echo ">>> Installing systemd service..."
cp "$INSTALL_DIR/lxc/wiki-js-mcp.service" /etc/systemd/system/wiki-js-mcp.service
systemctl daemon-reload
systemctl enable wiki-js-mcp

# Start only if .env is configured
if grep -q "^WIKIJS_API_URL=http" "$INSTALL_DIR/.env" 2>/dev/null; then
    echo ">>> Starting service..."
    systemctl start wiki-js-mcp
    sleep 2
    systemctl is-active wiki-js-mcp && echo "Service started successfully" || echo "Service did not start — check your .env configuration"
else
    echo ""
    echo ">>> Service NOT started: configure $INSTALL_DIR/.env first"
    echo "    Then run: systemctl start wiki-js-mcp"
fi

echo ""
echo "=== Installation terminée ==="
echo "  Répertoire : $INSTALL_DIR"
echo "  Service    : systemctl {start|stop|status|restart} wiki-js-mcp"
echo "  Logs       : journalctl -u wiki-js-mcp -f"
echo "  Config     : $INSTALL_DIR/.env"
