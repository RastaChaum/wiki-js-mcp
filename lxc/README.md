# Wiki.js MCP Server — Proxmox LXC Deployment Guide

## Architecture

The MCP server runs in a Debian 12 LXC container on Proxmox and exposes its API via the **SSE (Server-Sent Events)** transport on port `8000`, accessible to all clients on the local network.

```
[IDE/Cursor/Copilot]  ──HTTP SSE──►  [LXC wiki-mcp :8000]  ──GraphQL──►  [Wiki.js]
```

> **Tip:** For a fully interactive setup with the community-scripts/ProxmoxVE style installer,
> see [`community-scripts/README.md`](../community-scripts/README.md).

## Prerequisites

- Proxmox VE 7.x or 8.x
- Shell access on the Proxmox host (root)
- Internet access from the host (to download the Debian 12 template)
- A Wiki.js instance reachable from the LXC network

## Quick Deployment

### 1. On the Proxmox host

```bash
# Clone the repository on the host or copy the lxc/ directory
git clone https://github.com/RastaChaum/wiki-js-mcp.git /tmp/wiki-js-mcp
cd /tmp/wiki-js-mcp/lxc

# Optional overrides (defaults shown in parentheses)
export VMID=200          # Proxmox container ID (200)
export HOSTNAME=wiki-mcp # Container hostname (wiki-mcp)
export STORAGE=local-lvm # Proxmox storage pool for the disk (local-lvm)
export MEMORY=512        # RAM in MB (512)
export IP=dhcp           # "dhcp" or "192.168.1.50/24" for a static IP
# export GW=192.168.1.1 # Default gateway (required for static IP)

bash create-lxc.sh
```

### 2. Configure the server

```bash
# Edit the configuration inside the container
pct exec 200 -- nano /opt/wiki-js-mcp/.env
```

Mandatory `.env` fields:

```env
WIKIJS_API_URL=http://192.168.1.x:3000
WIKIJS_TOKEN=your-jwt-token
# OR
WIKIJS_USERNAME=admin@example.com
WIKIJS_PASSWORD=your-password

# Already set by the install script:
MCP_TRANSPORT=sse
MCP_HOST=0.0.0.0
MCP_PORT=8000
```

### 3. Start the service

```bash
pct exec 200 -- systemctl start wiki-js-mcp
pct exec 200 -- systemctl status wiki-js-mcp
```

### 4. Configure your IDE

Add to your MCP configuration (e.g. `~/.config/mcp.json` or VS Code settings):

```json
{
  "mcpServers": {
    "wikijs": {
      "url": "http://192.168.1.50:8000/sse"
    }
  }
}
```

## Useful Commands

```bash
# Follow logs in real time
pct exec 200 -- journalctl -u wiki-js-mcp -f

# Restart after a config change
pct exec 200 -- systemctl restart wiki-js-mcp

# Update the code to the latest commit
pct exec 200 -- bash /opt/wiki-js-mcp/lxc/install.sh

# Check the listening port
pct exec 200 -- ss -tlnp | grep 8000
```

## Directory Structure

```
lxc/
├── create-lxc.sh        # Proxmox host script — creates the LXC container
├── install.sh           # In-container installation script
├── wiki-js-mcp.service  # systemd unit file
└── README.md            # This file
```

## Security Notes

- The service runs as the `wikimcp` user (non-root)
- Systemd hardening: `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem=strict`
- Expose port 8000 on your internal network only (never directly to the internet)
- For HTTPS, place an Nginx or Traefik reverse proxy in front of the LXC
