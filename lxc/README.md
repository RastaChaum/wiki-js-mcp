# Wiki.js MCP Server — Guide de déploiement LXC Proxmox

## Architecture

Le serveur MCP tourne dans un conteneur LXC Debian 12 sur Proxmox et expose son API via le transport **SSE (Server-Sent Events)** sur le port `8000`, accessible à tous les clients du réseau local.

```
[IDE/Cursor/Copilot]  ──HTTP SSE──►  [LXC wiki-mcp :8000]  ──GraphQL──►  [Wiki.js]
```

## Prérequis

- Proxmox VE 7.x ou 8.x
- Shell sur l'hôte Proxmox (root)
- Accès internet depuis l'hôte (pour télécharger le template Debian 12)
- Un Wiki.js accessible depuis le réseau du LXC

## Déploiement rapide

### 1. Sur l'hôte Proxmox

```bash
# Cloner le dépôt sur l'hôte ou copier le répertoire lxc/
git clone https://github.com/RastaChaum/wiki-js-mcp.git /tmp/wiki-js-mcp
cd /tmp/wiki-js-mcp/lxc

# Variables optionnelles (valeurs par défaut entre parenthèses)
export VMID=200          # ID du conteneur Proxmox (200)
export HOSTNAME=wiki-mcp # Nom du conteneur (wiki-mcp)
export STORAGE=local-lvm # Stockage Proxmox pour le disque (local-lvm)
export MEMORY=512        # RAM en Mo (512)
export IP=dhcp           # "dhcp" ou "192.168.1.50/24" pour IP fixe
# export GW=192.168.1.1 # Passerelle (requis si IP fixe)

bash create-lxc.sh
```

### 2. Configurer le serveur

```bash
# Éditer la configuration dans le conteneur
pct exec 200 -- nano /opt/wiki-js-mcp/.env
```

Champs obligatoires dans `.env` :

```env
WIKIJS_API_URL=http://192.168.1.x:3000
WIKIJS_TOKEN=votre-jwt-token

# Déjà configurés par le script d'installation :
MCP_TRANSPORT=sse
MCP_HOST=0.0.0.0
MCP_PORT=8000
```

### 3. Démarrer le service

```bash
pct exec 200 -- systemctl start wiki-js-mcp
pct exec 200 -- systemctl status wiki-js-mcp
```

### 4. Configurer votre IDE

Ajoutez dans votre configuration MCP (ex: `~/.config/mcp.json` ou VS Code settings) :

```json
{
  "mcpServers": {
    "wikijs": {
      "url": "http://192.168.1.50:8000/sse"
    }
  }
}
```

## Commandes utiles

```bash
# Voir les logs en temps réel
pct exec 200 -- journalctl -u wiki-js-mcp -f

# Redémarrer après changement de config
pct exec 200 -- systemctl restart wiki-js-mcp

# Mise à jour du code
pct exec 200 -- bash /opt/wiki-js-mcp/lxc/install.sh

# Vérifier le port
pct exec 200 -- ss -tlnp | grep 8000
```

## Structure du répertoire lxc/

```
lxc/
├── create-lxc.sh        # Script Proxmox pour créer le conteneur
├── install.sh           # Script d'installation dans le conteneur
├── wiki-js-mcp.service  # Unit systemd
└── README.md            # Ce fichier
```

## Sécurité

- Le service tourne sous l'utilisateur `wikimcp` (non-root)
- `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem` activés
- Exposez le port 8000 uniquement sur votre réseau interne (pas sur Internet)
- Pour HTTPS, placez un reverse proxy Nginx/Traefik devant le LXC
