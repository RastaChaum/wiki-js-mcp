# community-scripts/ProxmoxVE — Wiki.js MCP Deployment

These two files follow the [community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) format for deploying applications as Proxmox LXC containers.

## Files

| File | Purpose |
|------|---------|
| `ct/wiki-js-mcp.sh` | Run on the **Proxmox host** — creates and configures the LXC container |
| `install/wiki-js-mcp-install.sh` | Run **inside the container** — installs the Wiki.js MCP server |

## Deployment Options

### Option A — Personal Use (before official submission)

Run the ct script directly from this repository. By default it fetches the install script from the `feature/add-locale-parameter` branch of `RastaChaum/wiki-js-mcp`.

```bash
# On the Proxmox host shell:
bash -c "$(curl -fsSL https://raw.githubusercontent.com/RastaChaum/wiki-js-mcp/feature/add-locale-parameter/community-scripts/ct/wiki-js-mcp.sh)"
```

You can override the install script URL with the `INSTALL_SCRIPT_URL` environment variable:

```bash
export INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/YOUR_FORK/wiki-js-mcp/YOUR_BRANCH/community-scripts/install/wiki-js-mcp-install.sh"
bash -c "$(curl -fsSL ...ct/wiki-js-mcp.sh)"
```

### Option B — Via ProxmoxVED fork (recommended for testing before official PR)

Per the [CONTRIBUTING.md](https://github.com/community-scripts/ProxmoxVE/blob/main/CONTRIBUTING.md) guidelines, new scripts must be submitted to [community-scripts/ProxmoxVED](https://github.com/community-scripts/ProxmoxVED) first.

1. Fork `community-scripts/ProxmoxVED`
2. Copy `ct/wiki-js-mcp.sh` → `ct/` in your fork
3. Copy `install/wiki-js-mcp-install.sh` → `install/` in your fork
4. In `ct/wiki-js-mcp.sh`, remove the `INSTALL_SCRIPT_URL` variable and `build_container` override — the standard `build.func` flow will take over
5. Run the ct script from your fork URL

## Post-Deployment Configuration

After the container is created, configure the `.env` file before starting the service:

```bash
# Edit credentials
pct exec <CTID> -- nano /opt/wiki-js-mcp/.env
```

Mandatory `.env` fields:

```env
WIKIJS_API_URL=http://your-wikijs-host:3000
WIKIJS_TOKEN=your-jwt-token
# OR
WIKIJS_USERNAME=admin@example.com
WIKIJS_PASSWORD=your-password

# Already set by the installer:
MCP_TRANSPORT=sse
MCP_HOST=0.0.0.0
MCP_PORT=8000
```

Then start the service:

```bash
pct exec <CTID> -- systemctl start wiki-js-mcp
pct exec <CTID> -- systemctl status wiki-js-mcp
```

## Accessing the MCP Server

The server listens on port **8000** using the SSE transport. Configure your IDE:

```json
{
  "mcpServers": {
    "wikijs": {
      "url": "http://<container-ip>:8000/sse"
    }
  }
}
```

## Adapting for Official community-scripts Submission

When submitting to ProxmoxVED:

1. In `ct/wiki-js-mcp.sh`: remove the `INSTALL_SCRIPT_URL` variable and the custom `build_container` function between the `TEMPORARY` markers
2. Restore the standard three-line flow:
   ```bash
   start
   build_container
   description
   ```
3. Update the `Source:` URL comment to point to the upstream project
4. Submit a PR to [community-scripts/ProxmoxVED](https://github.com/community-scripts/ProxmoxVED)
