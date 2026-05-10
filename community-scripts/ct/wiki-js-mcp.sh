#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: RastaChaum
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/talosdeus/wiki-js-mcp

APP="Wiki.js MCP"
var_tags="${var_tags:-mcp;wikijs;ai}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

# ---------------------------------------------------------------------------
# TEMPORARY: Custom build_container override for pre-submission testing.
#
# When this script is hosted at the official community-scripts URL, the
# build_container function from build.func will automatically download the
# install script from:
#   https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/install/wiki-js-mcp-install.sh
#
# Until then, set INSTALL_SCRIPT_URL to point to the install script in your
# own fork/branch, e.g.:
#   export INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/RastaChaum/wiki-js-mcp/feature/add-locale-parameter/community-scripts/install/wiki-js-mcp-install.sh"
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/RastaChaum/wiki-js-mcp/feature/add-locale-parameter/community-scripts/ct/wiki-js-mcp.sh)"
#
# TO SUBMIT TO ProxmoxVED: delete everything between the TEMPORARY markers
# and the build_container function, then use the standard `start; build_container; description` flow.
# ---------------------------------------------------------------------------
INSTALL_SCRIPT_URL="${INSTALL_SCRIPT_URL:-https://raw.githubusercontent.com/RastaChaum/wiki-js-mcp/feature/add-locale-parameter/community-scripts/install/wiki-js-mcp-install.sh}"

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/wiki-js-mcp ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP} LXC"
  $STD git -C /opt/wiki-js-mcp pull
  $STD /opt/wiki-js-mcp/venv/bin/pip install -r /opt/wiki-js-mcp/requirements.txt
  $STD systemctl restart wiki-js-mcp
  msg_ok "Updated ${APP} LXC"
  exit
}

# Custom build_container: creates the container and runs our install script.
# Remove this function when submitting to community-scripts/ProxmoxVED and
# replace the call below with the standard `build_container` from build.func.
function build_container() {
  export CTID="${CT_ID}"
  local tmpl_store="${TEMPLATE_STORAGE:-local}"
  local ct_store="${CONTAINER_STORAGE:-local-lvm}"

  # Resolve Debian template (latest available)
  local template
  template=$(pveam available -section system 2>/dev/null \
    | awk '{print $2}' \
    | grep -E "^debian-${var_version:-12}-standard" \
    | sort -V | tail -1)
  if [[ -z "$template" ]]; then
    template="debian-12-standard_12.7-1_amd64.tar.zst"
  fi

  # Download template if not present locally
  if ! pveam list "$tmpl_store" 2>/dev/null | grep -q "$template"; then
    msg_info "Downloading ${var_os:-debian} ${var_version:-12} template"
    $STD pveam update
    $STD pveam download "$tmpl_store" "$template"
    msg_ok "Downloaded ${template}"
  fi

  # Network string
  local net_str="name=eth0,bridge=${BRG:-vmbr0},ip=${NET:-dhcp}"
  [[ "${GATE:-}" =~ ,gw=(.+) ]]    && net_str="${net_str},gw=${BASH_REMATCH[1]}"
  [[ "${VLAN:-}" =~ ,tag=(.+) ]]   && net_str="${net_str},tag=${BASH_REMATCH[1]}"
  [[ "${MTU:-}" =~ ,mtu=(.+) ]]    && net_str="${net_str},mtu=${BASH_REMATCH[1]}"
  [[ "${MAC:-}" =~ ,hwaddr=(.+) ]] && net_str="${net_str},hwaddr=${BASH_REMATCH[1]}"

  # Features
  local features="nesting=1,keyctl=1"
  [[ "${ENABLE_FUSE:-no}" == "yes" ]] && features="${features},fuse=1"

  msg_info "Creating LXC Container ${CTID}"
  pct create "$CTID" "${tmpl_store}:vztmpl/${template}" \
    -hostname "${HN:-wiki-js-mcp}" \
    -cores "${CORE_COUNT:-1}" \
    -memory "${RAM_SIZE:-512}" \
    -unprivileged "${CT_TYPE:-1}" \
    -features "$features" \
    -tags "${TAGS:-community-script}" \
    -net0 "$net_str" \
    -onboot 1 \
    -rootfs "${ct_store}:${DISK_SIZE:-4}" \
    >/dev/null 2>&1 || { msg_error "Failed to create LXC container ${CTID}"; exit 1; }
  msg_ok "LXC Container ${CTID} created"

  # Export variables expected by the install script
  export FUNCTIONS_FILE_PATH
  FUNCTIONS_FILE_PATH="$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)"
  export DIAGNOSTICS="${DIAGNOSTICS:-no}"
  export RANDOM_UUID="${RANDOM_UUID:-$(cat /proc/sys/kernel/random/uuid)}"
  export APPLICATION="$APP"
  export app="$NSAPP"
  export VERBOSE="${VERBOSE:-no}"
  export CTTYPE="${CT_TYPE:-1}"
  export PCT_OSTYPE="${var_os:-debian}"
  export PCT_OSVERSION="${var_version:-12}"
  export PCT_DISK_SIZE="${DISK_SIZE:-4}"
  export PASSWORD="${PW:-}"

  msg_info "Starting LXC Container"
  pct start "$CTID"

  msg_info "Waiting for network"
  local ip_addr=""
  for i in {1..30}; do
    ip_addr=$(pct exec "$CTID" -- ip -4 addr show eth0 2>/dev/null \
      | awk '/inet / {print $2}' | cut -d/ -f1)
    [[ -n "$ip_addr" ]] && break
    sleep 2
  done
  [[ -z "$ip_addr" ]] && { msg_error "Container ${CTID} did not receive an IP address"; exit 1; }
  msg_ok "Network ready (${ip_addr})"

  msg_info "Installing base packages"
  pct exec "$CTID" -- bash -c \
    "apt-get update -qq && apt-get install -y -qq curl sudo git ca-certificates 2>/dev/null"
  msg_ok "Base packages installed"

  msg_info "Running ${APP} install script"
  lxc-attach -n "$CTID" \
    -v FUNCTIONS_FILE_PATH="$FUNCTIONS_FILE_PATH" \
    -v DIAGNOSTICS="${DIAGNOSTICS:-no}" \
    -v VERBOSE="${VERBOSE:-no}" \
    -- bash -c "$(curl -fsSL "${INSTALL_SCRIPT_URL}")"
  msg_ok "${APP} installed"

  IP="$ip_addr"
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL (SSE transport):${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000/sse${CL}"
echo -e ""
echo -e "${INFO}${YW} Configure Wiki.js credentials before starting the service:${CL}"
echo -e "${TAB}${BGN}pct exec ${CTID} -- nano /opt/wiki-js-mcp/.env${CL}"
echo -e "${TAB}${BGN}pct exec ${CTID} -- systemctl start wiki-js-mcp${CL}"
