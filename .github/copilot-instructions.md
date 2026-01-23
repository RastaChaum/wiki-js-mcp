# HomeLab Infrastructure Documentation Guidelines

This wiki is dedicated to documenting the manual setup and disaster recovery procedures for our HomeLab infrastructure.

## Documentation Objectives

Before creating or updating any documentation, always:

1. **Focus on Disaster Recovery** - Document every step needed to rebuild this infrastructure from scratch
2. **Document Manual Procedures** - Include all manual configuration steps, not just automation
3. **Capture Dependencies** - List services, versions, ports, and inter-service dependencies
4. **Preserve Knowledge** - Document why decisions were made, not just what was done
5. **Create Runbooks** - For common tasks: startup procedures, backups, troubleshooting, recovery steps
6. **Maintain Architecture Diagrams** - Keep visual representations of the infrastructure layout

## Documentation Structure

All documentation MUST be organized under the **`homelab`** virtual folder hierarchy.

Use nested page structure with consistent parent paths:

```
homelab/
├── Home (index page)
├── quick-references/
│   ├── index
│   ├── proxmox
│   ├── home-assistant
│   ├── traefik
│   ├── adguard-home
│   ├── vaultwarden
│   ├── kopia
│   └── nas
├── disaster-recovery/
│   ├── index
│   ├── recovery-checklist
│   ├── service-rebuild-order
│   ├── data-restoration-steps
│   └── testing-procedures
├── troubleshooting/
│   ├── index
│   ├── proxmox
│   ├── home-assistant
│   ├── traefik
│   ├── adguard-dns
│   ├── kopia
│   ├── nas
│   └── vaultwarden
└── health-checks-monitoring/
    ├── index
    ├── prometheus-setup
    ├── grafana-setup
    ├── alert-configuration
    ├── health-check-procedures
    └── service-health-status
```

### Naming Convention
- Use kebab-case for page slugs: `quick-references`, `disaster-recovery`
- Use parent_path format: `homelab/quick-references`, `homelab/disaster-recovery`
- Index pages use parent path: `parent_path="homelab/quick-references"` creates under `homelab/quick-references/index`

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
3. **Link Related Content**: Use `wikijs_link_file_to_page` for configuration files or scripts
4. **Bulk Updates**: Use `wikijs_bulk_update_project_docs` when infrastructure changes affect multiple services
5. **Maintain Current State**: After any infrastructure change, use `wikijs_sync_file_docs` to update relevant pages

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
