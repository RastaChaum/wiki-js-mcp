# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Model Context Protocol (MCP) server** that bridges Wiki.js (a documentation platform) with AI coding assistants (Cursor, Claude Code). The server exposes 22 MCP tools for creating, updating, searching, and organizing hierarchical documentation pages via the Wiki.js GraphQL API.

## Commands

```bash
# Setup
./setup.sh                          # Create venv, install deps, generate .env from example

# Run the MCP server
./start-server.sh                   # Activates venv and starts stdio MCP server

# Test interactively
./test-server.sh

# Deploy Wiki.js locally (PostgreSQL + Wiki.js)
docker-compose -f docker.yml up -d

# Code quality (installed via Poetry)
black src/                          # Format (line-length=88)
isort src/                          # Sort imports
mypy src/                           # Type-check (strict: disallow_untyped_defs)
pytest                              # Run tests
pytest tests/test_foo.py::test_bar  # Run single test
```

## Architecture

All logic lives in a single file: [src/wiki_mcp_server.py](src/wiki_mcp_server.py) (~2,200 lines).

**Startup sequence:**
1. Pydantic `Settings` loads config from `.env`
2. `WikiJSClient` is instantiated (async `httpx` client, HTTP/1.1 forced, SSL disabled for self-signed certs)
3. `FastMCP` server starts and listens on stdin/stdout for MCP protocol messages from the IDE

**Key classes/objects:**
- `WikiJSClient` — all GraphQL communication with Wiki.js; handles JWT auth with fallback to username/password login; wraps requests in tenacity retry (3 attempts, exponential backoff)
- `mcp = FastMCP(...)` — each `@mcp.tool()` decorated function is one of the 22 exposed tools
- SQLAlchemy (SQLite) — local DB with two tables: `FileMapping` (maps source files to page IDs, tracks hash for change detection) and `RepositoryContext` (maps git repos to Wiki.js spaces)

**Tool categories:**
- **Hierarchical**: `wikijs_create_repo_structure`, `wikijs_create_nested_page`, `wikijs_get_page_children`, `wikijs_create_documentation_hierarchy`
- **Core CRUD**: `wikijs_create_page`, `wikijs_update_page`, `wikijs_get_page`, `wikijs_move_page`
- **Search**: `wikijs_search_pages`
- **File sync**: `wikijs_link_file_to_page`, `wikijs_sync_file_docs`, `wikijs_generate_file_overview`
- **Deletion**: `wikijs_delete_page`, `wikijs_batch_delete_pages`, `wikijs_delete_hierarchy`, `wikijs_cleanup_orphaned_mappings`
- **Bulk/System**: `wikijs_bulk_update_project_docs`, `wikijs_connection_status`, `wikijs_repository_context`

All tools return JSON strings.

## Configuration

Copy `config/example.env` to `.env`. Key variables:

```bash
WIKIJS_API_URL=http://localhost:3000
WIKIJS_TOKEN=<jwt>          # preferred auth
# OR
WIKIJS_USERNAME=<user>
WIKIJS_PASSWORD=<pass>
WIKIJS_MCP_DB=./wikijs_mappings.db
LOG_LEVEL=INFO
```

## HomeLab Wiki Usage Rules

These rules come from `.github/copilot-instructions.md` and apply when operating this MCP server against the HomeLab Wiki.js instance:

- **Always use `locale: "fr"`** for all page operations (create, update, search) unless explicitly told otherwise.
- **Search before creating** (`wikijs_search_pages`) to avoid duplicates.
- **Link, don't duplicate**: reference existing pages rather than copying content.
- **Slug convention**: kebab-case — `quick-reference-<service>`, `<service>-troubleshooting`, `<service>-setup-homelab`; index pages end in `-index`.
- **Deletion safety**: `confirm_deletion` defaults to `False` (preview mode); set to `True` explicitly to execute.
- Page structure template for service pages: Quick Reference → Installation → Configuration → Démarrage/Arrêt → Stratégie de sauvegarde → Procédure de reprise → Problèmes courants.
