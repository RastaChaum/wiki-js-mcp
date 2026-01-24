# HomeLab Infrastructure Documentation Guidelines

This wiki is dedicated to documenting the manual setup and disaster recovery procedures for our HomeLab infrastructure.

## ⚠️ IMPORTANT: Locale Configuration

**TOUJOURS TRAVAILLER EN FRANÇAIS (locale: "fr")**

- Toutes les pages Wiki.js doivent être créées avec `locale: "fr"`
- Toutes les recherches doivent utiliser le locale français
- Ne JAMAIS utiliser locale "en" sauf si explicitement demandé
- Cette règle s'applique à TOUS les outils Wiki.js :
  - `wikijs_create_page` → `locale: "fr"`
  - `wikijs_create_nested_page` → `locale: "fr"`
  - `wikijs_search_pages` → spécifier locale "fr" si disponible
  - `wikijs_update_page` → vérifier que la page est en locale "fr"

## Documentation Objectives

Before creating or updating any documentation, always:

1. **Focus on Disaster Recovery** - Document every step needed to rebuild this infrastructure from scratch
2. **Document Manual Procedures** - Include all manual configuration steps, not just automation
3. **Capture Dependencies** - List services, versions, ports, and inter-service dependencies
4. **Preserve Knowledge** - Document why decisions were made, not just what was done
5. **Create Runbooks** - For common tasks: startup procedures, backups, troubleshooting, recovery steps
6. **Maintain Architecture Diagrams** - Keep visual representations of the infrastructure layout
7. **⚠️ ALWAYS Use French Locale** - All pages MUST be created with `locale: "fr"` unless explicitly requested otherwise

## Documentation Structure

All documentation MUST use consistent naming convention for Wiki.js pages.

**CRITICAL NAMING RULE**: Every page name (slug) in Wiki.js follows this format:
- Root page: `homelab-home`
- Section index pages: `<section>-index` (e.g., `quick-references-index`, `disaster-recovery-index`)
- Service/content pages: `<service>-<section>` or `<topic>-<section>` (e.g., `quick-reference-proxmox`, `proxmox-troubleshooting`)

**Note**: Wiki.js v2 uses flat page structure. Hierarchy is created through page links and indexes, not filesystem-like paths.

### Page Naming Examples:
```
homelab-home                              # Root Home page
quick-references-index                    # Quick References section index
quick-reference-proxmox                   # Proxmox quick reference  
disaster-recovery-index                   # DR section index
recovery-checklist-homelab                # Recovery checklist page
troubleshooting-index                     # Troubleshooting section index
proxmox-troubleshooting                   # Proxmox troubleshooting
health-checks-monitoring-index            # Monitoring section index
prometheus-setup-homelab                  # Prometheus setup page
```

### Logical Organization Structure:
```
🏠 HomeLab (homelab-home)                              
├── 📚 Quick References (quick-references-index)
│   ├── Proxmox (quick-reference-proxmox)
│   ├── Home Assistant (quick-reference-home-assistant)
│   ├── Traefik (quick-reference-traefik)
│   ├── AdGuard Home (quick-reference-adguard-home)
│   ├── Vaultwarden (quick-reference-vaultwarden)
│   ├── Kopia (quick-reference-kopia)
│   └── NAS (quick-reference-nas)
├── 🚨 Disaster Recovery (disaster-recovery-index)
│   ├── Recovery Checklist (recovery-checklist-homelab)
│   ├── Service Rebuild Order (service-rebuild-order-homelab)
│   ├── Data Restoration Steps (data-restoration-steps-homelab)
│   └── Testing Procedures (testing-procedures-homelab)
├── 🔧 Troubleshooting (troubleshooting-index)
│   ├── Proxmox (proxmox-troubleshooting)
│   ├── Home Assistant (home-assistant-troubleshooting)
│   ├── Traefik (traefik-troubleshooting)
│   ├── AdGuard DNS (adguard-dns-troubleshooting)
│   ├── Kopia (kopia-troubleshooting)
│   ├── NAS (nas-troubleshooting)
│   └── Vaultwarden (vaultwarden-troubleshooting)
└── 📊 Monitoring (health-checks-monitoring-index)
    ├── Prometheus Setup (prometheus-setup-homelab)
    ├── Grafana Setup (grafana-setup-homelab)
    ├── Alert Configuration (alert-configuration-homelab)
    ├── Health Check Procedures (health-check-procedures-homelab)
    └── Service Health Status (service-health-status-homelab)
```

### Naming Convention
- Use kebab-case for all slugs: `quick-references-index`, `prometheus-setup-homelab`
- Pattern for quick refs: `quick-reference-<service>` 
- Pattern for troubleshooting: `<service>-troubleshooting`
- Pattern for setup guides: `<service>-setup-homelab`
- Section indexes end with `-index`
- Critical pages use suffix `-homelab` for clarity

## Documentation Standards

### For Each Service Document:
```
# Service Name

## Quick Reference
- **Version**: X.Y.Z
- **Ports**: List all ports used
- **Dependencies**: Other services/systems required
- **Critical Data**: Locations to backup
- **Recovery Time**: Estimated rebuild time

## Installation
[Step-by-step manual installation process]

## Configuration
[All manual configuration steps]

## Startup/Shutdown Procedures
[Daily operational steps]

## Backup Strategy
[What to backup, where, when]

## Recovery Procedure
[Step-by-step recovery from backup]

## Common Issues & Solutions
[Troubleshooting guide]
```

### For Disaster Recovery:
```
# [Service] Recovery Runbook

## Prerequisites
- Hardware requirements
- Network access needed
- Required credentials/keys location

## Recovery Steps
1. [Detailed step 1]
2. [Detailed step 2]
...

## Validation
- How to verify service is working
- Health checks to run
- Performance baselines

## Rollback Procedure
- If recovery fails, how to revert
```

## Using MCP Tools

When documenting:

1. **Search First**: Use `wikijs_search_pages` to find existing documentation before creating new pages
2. **Create Hierarchically**: Use `wikijs_create_nested_page` to maintain structure
3. **⚠️ ALWAYS Set Locale to "fr"**: All `wikijs_create_*` tools must use `locale: "fr"` parameter unless explicitly requested otherwise
4. **Link Related Content**: Use `wikijs_link_file_to_page` for configuration files or scripts
5. **Bulk Updates**: Use `wikijs_bulk_update_project_docs` when infrastructure changes affect multiple services
6. **Maintain Current State**: After any infrastructure change, use `wikijs_sync_file_docs` to update relevant pages

## Priority Documentation Areas

Focus documentation on:
- ✅ **Critical Recovery Paths** - What MUST be restored first?
- ✅ **Single Points of Failure** - What could break everything?
- ✅ **Data Preservation** - Where are critical backups stored?
- ✅ **Access & Credentials** - How to access management interfaces safely?
- ✅ **Monitoring & Alerting** - How to know if something fails?
- ✅ **Testing Procedures** - How to validate recovery procedures work?

## Backup of Documentation Itself

This wiki IS critical infrastructure - ensure it can be recovered:
- Document the Wiki.js installation process
- Export documentation regularly
- Keep a local copy of important runbooks
