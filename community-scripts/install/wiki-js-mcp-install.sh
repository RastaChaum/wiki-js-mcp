#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: RastaChaum
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/talosdeus/wiki-js-mcp

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

INSTALL_DIR="/opt/wiki-js-mcp"
SERVICE_USER="wikimcp"
REPO_URL="${REPO_URL:-https://github.com/RastaChaum/wiki-js-mcp.git}"
REPO_BRANCH="${REPO_BRANCH:-feature/add-locale-parameter}"
MCP_PORT="${MCP_PORT:-8000}"

msg_info "Installing Python 3 and system dependencies"
$STD apt-get install -y \
  python3 \
  python3-pip \
  python3-venv \
  git \
  curl \
  ca-certificates
msg_ok "Installed dependencies"

msg_info "Creating service user"
useradd -r -s /bin/false -d "${INSTALL_DIR}" "${SERVICE_USER}" 2>/dev/null || true
msg_ok "Created service user ${SERVICE_USER}"

msg_info "Cloning Wiki.js MCP repository"
$STD git clone --branch "${REPO_BRANCH}" "${REPO_URL}" "${INSTALL_DIR}"
msg_ok "Cloned repository (branch: ${REPO_BRANCH})"

msg_info "Setting up Python virtual environment"
python3 -m venv "${INSTALL_DIR}/venv"
$STD "${INSTALL_DIR}/venv/bin/pip" install --upgrade pip
$STD "${INSTALL_DIR}/venv/bin/pip" install -r "${INSTALL_DIR}/requirements.txt"
msg_ok "Python virtual environment ready"

msg_info "Configuring Wiki.js MCP Server"
cp "${INSTALL_DIR}/config/example.env" "${INSTALL_DIR}/.env"
cat >> "${INSTALL_DIR}/.env" << 'ENVEOF'

# Network transport for LXC deployment (SSE = network-accessible)
MCP_TRANSPORT=sse
MCP_HOST=0.0.0.0
MCP_PORT=8000
ENVEOF
mkdir -p "${INSTALL_DIR}/logs"
chown -R "${SERVICE_USER}:${SERVICE_USER}" "${INSTALL_DIR}"
msg_ok "Configured Wiki.js MCP Server"

msg_info "Creating systemd service"
cat << 'SERVICEEOF' > /etc/systemd/system/wiki-js-mcp.service
[Unit]
Description=Wiki.js MCP Server (SSE transport)
Documentation=https://github.com/talosdeus/wiki-js-mcp
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=wikimcp
Group=wikimcp
WorkingDirectory=/opt/wiki-js-mcp
EnvironmentFile=/opt/wiki-js-mcp/.env
ExecStart=/opt/wiki-js-mcp/venv/bin/python src/wiki_mcp_server.py
Restart=on-failure
RestartSec=5s
StandardOutput=append:/opt/wiki-js-mcp/logs/mcp.log
StandardError=append:/opt/wiki-js-mcp/logs/mcp-error.log

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/opt/wiki-js-mcp/logs /opt/wiki-js-mcp/wikijs_mappings.db

[Install]
WantedBy=multi-user.target
SERVICEEOF
$STD systemctl daemon-reload
$STD systemctl enable wiki-js-mcp
msg_ok "Created systemd service (disabled until .env is configured)"

motd_ssh
customize
cleanup_lxc
