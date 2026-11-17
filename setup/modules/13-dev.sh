# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=dev
MODULE_DESC="Docker, GitHub CLI, Wireshark, Bruno, Beekeeper Studio, pnpm + Oxc, Zed, Neovim (LazyVim), JetBrains IDEs"
MODULE_DEFAULT=1
MODULE_DEPS=(runtimes)                   # bun and mise for the JS tools
}

# --- Docker ------------------------------------------------------------------

_dev_docker() {
  # docker-cli holds the 'docker' command; it's only a Recommends of docker.io
  apt_install docker.io docker-cli docker-compose docker-buildx

  # Docker bypasses ufw; published ports bind to 127.0.0.1 unless a daemon.json already exists.
  if [[ ! -e /etc/docker/daemon.json ]]; then
    printf '{ "ip": "127.0.0.1" }\n' | write_file /etc/docker/daemon.json
    if systemctl is-active -q docker.service 2>/dev/null; then
      run sudo systemctl restart docker.service   # only when the config is new
    fi
  fi
  enable_now docker.service
  add_user_to_group docker
}

# --- Tools -------------------------------------------------------------------

_dev_tools() {
  apt_install gh git-delta sqlite3

  # Wireshark, with packet capture allowed for the wireshark group (no sudo)
  if ! pkg_installed wireshark; then
    debconf_preseed 'wireshark-common wireshark-common/install-setuid boolean true'
    apt_install wireshark
  fi
  add_user_to_group wireshark

  local apps=(
    # com.getpostman.Postman
    com.usebruno.Bruno
    io.beekeeperstudio.Studio
    # io.dbeaver.DBeaverCommunity
  )
  flatpak_install "${apps[@]}"

  # Optional CLIs
  # have cf || pnpm add --global cf
  # have neon || pnpm add --global neon
  # have turso || install_script https://get.tur.so/install.sh bash
  # have supabase || brew install supabase/tap/supabase
}

# --- JavaScript tooling ------------------------------------------------------

_dev_js() {
  mise_use pnpm@latest

  # Global installs are for quick use; projects should still add them as dev deps (pnpm add -D).
  local globals=(
    oxlint
    oxfmt
    # @biomejs/biome                       # fallback if a project uses Biome
  )
  local pkg
  local -a todo=()
  for pkg in "${globals[@]}"; do
    if have "${pkg##*/}"; then info "$pkg already installed"; else todo+=("$pkg"); fi
  done
  if (( ${#todo[@]} )); then
    need bun runtimes
    run bun add -g "${todo[@]}"
  fi
}

# --- Editors -----------------------------------------------------------------

_dev_editors() {
  # Zed (installs to ~/.local/bin)
  if have zed; then info "Zed already installed"; else install_script https://zed.dev/install.sh sh; fi

  # Neovim + LazyVim. An existing non-LazyVim config is backed up, not deleted.
  local nvim_dir="$HOME/.config/nvim"
  apt_install neovim
  apt_or_mise "tree-sitter-cli|tree-sitter"

  if [[ -f "$nvim_dir/lazyvim.json" || -f "$nvim_dir/lua/config/lazy.lua" ]]; then
    info "LazyVim config already in $nvim_dir"
  else
    if [[ -e "$nvim_dir" ]]; then run mv "$nvim_dir" "$nvim_dir.bak.$TS"; fi
    run git clone --depth 1 https://github.com/LazyVim/starter "$nvim_dir"
    run rm -rf "$nvim_dir/.git"
  fi

  # JetBrains IDEs from Flathub; IDEA's core is free, Ultimate needs a subscription (30-day trial).
  local jetbrains=(
    com.jetbrains.IntelliJ-IDEA-Ultimate    # IntelliJ IDEA (free core)
    # com.jetbrains.IntelliJ-IDEA-Community # IntelliJ IDEA Open: open-source build, no Ultimate trial
    # com.jetbrains.PyCharm-Professional    # PyCharm (free core; Community edition is EOL)
    # com.jetbrains.WebStorm                # free for non-commercial use
    # com.jetbrains.RustRover               # free for non-commercial use
    # com.jetbrains.CLion                   # free for non-commercial use
    # com.jetbrains.Rider                   # free for non-commercial use
    # com.jetbrains.DataGrip                # free for non-commercial use
    # com.google.AndroidStudio              # Google's IntelliJ-based Android IDE
  )
  flatpak_install "${jetbrains[@]}"

  # Optional editors from Flathub
  # flatpak_install com.vscodium.codium    # VS Code without Microsoft telemetry
}

dev_run() {
  _dev_docker
  _dev_tools
  _dev_js
  _dev_editors
}
