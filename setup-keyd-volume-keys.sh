#!/usr/bin/env bash
set -euo pipefail

config=/etc/keyd/default.conf

run_as_root() {
  if (( EUID == 0 )); then
    "$@"
  else
    sudo "$@"
  fi
}

if ! command -v pacman >/dev/null 2>&1; then
  echo "This installer requires pacman (Arch Linux or a derivative)." >&2
  exit 1
fi

if (( EUID != 0 )) && ! command -v sudo >/dev/null 2>&1; then
  echo "Please install sudo or run this script as root." >&2
  exit 1
fi

if ! pacman -Q keyd >/dev/null 2>&1; then
  run_as_root pacman -S --needed keyd
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
