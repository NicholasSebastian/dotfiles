# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=dev
MODULE_DESC="Docker, GitHub CLI, Wireshark, Bruno, Beekeeper Studio, pnpm + Oxc, Zed, Neovim (LazyVim), JetBrains IDEs"
MODULE_DEFAULT=1
MODULE_DEPS=(runtimes)                   # bun and mise for the JS tools

# --- Docker ------------------------------------------------------------------

_dev_docker() {
  apt_install docker.io docker-cli docker-compose docker-buildx

  # Docker writes its own firewall rules and bypasses ufw, so '-p 3000:3000'
  # would be reachable from any network you join. Bind published ports to
  # localhost by default; use '-p 0.0.0.0:3000:3000' when you mean it.
  # An existing daemon.json is yours and left alone.
  if [[ ! -e /etc/docker/daemon.json ]]; then
    write_file /etc/docker/daemon.json <<'EOF'
{
  "log-opts": { "max-size": "10m" },
  "registry-mirror": ["https://us-east.dl.containerd.aliyun.com"],
  "default-uids-gids": true,
  "storage-driver": "overlay2",
  "runtimes": {"nvidia-container-toolkit": {"path": "/usr/bin/nvidia-container-toolkit"}}
}
EOF
  fi
  enable_now docker.service
  add_user_to_group docker
}

# --- Tools -------------------------------------------------------------------

_dev_tools() {
  apt_install gh git-delta sqlite3

  # Wireshark, with packet capture allowed for the wireshark group (no sudo)
  if ! pkg_installed wireshark; then
    apt_install wireshark wireshark-services
  fi
  add_user_to_group wireshark
}

# --- JavaScript tooling ------------------------------------------------------

_dev_js() { … }

# --- Editors -----------------------------------------------------------------

_dev_editors() { … }

dev_run() {
  _dev_docker
  _dev_tools
  _dev_js
  _dev_editors
}
