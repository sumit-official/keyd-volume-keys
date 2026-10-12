#!/usr/bin/env bash
set -euo pipefail

config=/etc/keyd/default.conf
copr_repo=alternateved/keyd

run_as_root() {
  if (( EUID == 0 )); then
    "$@"
  else
    sudo "$@"
  fi
}

if [[ ! -r /etc/fedora-release ]]; then
  echo "This installer is intended for Fedora Linux." >&2
  exit 1
fi

if (( EUID != 0 )) && ! command -v sudo >/dev/null 2>&1; then
  echo "Please install sudo or run this script as root." >&2
  exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
  echo "dnf was not found; this installer requires Fedora's DNF package manager." >&2
  exit 1
fi

if ! command -v keyd >/dev/null 2>&1; then
  # keyd is distributed for Fedora through this community COPR repository.
  dnf_cmd=dnf
  if command -v dnf5 >/dev/null 2>&1; then
    dnf_cmd=dnf5
  fi
  if ! "$dnf_cmd" copr --help >/dev/null 2>&1; then
    if [[ "$dnf_cmd" == dnf5 ]]; then
      run_as_root "$dnf_cmd" install -y dnf5-plugins
    else
      run_as_root "$dnf_cmd" install -y dnf-plugins-core
    fi
  fi
  run_as_root "$dnf_cmd" copr enable -y "$copr_repo"
  run_as_root "$dnf_cmd" install -y keyd
fi

tmp_config=$(mktemp --suffix=.conf)
trap 'rm -f "$tmp_config"' EXIT
cat >"$tmp_config" <<'EOF'
[ids]
*

[main]
volumeup = noop
volumedown = noop
EOF

keyd check "$tmp_config"

config_changed=0
if [[ ! -f "$config" ]] || ! cmp -s "$tmp_config" "$config"; then
  if [[ -f "$config" ]]; then
    backup="${config}.backup.$(date +%Y%m%d-%H%M%S)"
    run_as_root cp -a "$config" "$backup"
    echo "Backed up the previous configuration to $backup"
  fi

  run_as_root install -D -m 0644 "$tmp_config" "$config"
  config_changed=1
fi

keyd check "$config"
run_as_root systemctl enable keyd
if systemctl is-active --quiet keyd; then
  if (( config_changed )); then
    run_as_root systemctl restart keyd
  fi
else
  run_as_root systemctl start keyd
fi

if ! systemctl is-active --quiet keyd; then
  echo "keyd did not become active; check 'systemctl status keyd'." >&2
  exit 1
fi

echo "keyd is active; volume up and volume down are disabled."
