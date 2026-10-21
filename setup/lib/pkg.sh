# shellcheck shell=bash
# Package helpers: apt, Flatpak, mise, plus users/groups and services.

# - sudo resets the environment, so DEBIAN_FRONTEND goes through `env`
#   (sudo-rs also ignores VAR=value written straight after sudo; without
#   this, debconf dialogs open invisibly and apt hangs).
# - The Dpkg options keep your config files when a package ships a newer one.
APT_GET=(
  sudo env DEBIAN_FRONTEND=noninteractive apt-get -y
  -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold
)

apt_update() { run "${APT_GET[@]}" update; }

# Print the names (of those given) that are installed, each once.
pkgs_installed() {
  dpkg-query -W -f='${Package} ${db:Status-Status}\n' "$@" 2>/dev/null \
    | awk '$2 == "installed" && !seen[$1]++ { print $1 }' || true
}

pkg_installed() { [[ -n "$(pkgs_installed "$1")" ]]; }

# Print the names (of those given) that apt can install.
pkgs_available() {
  apt-cache policy "$@" 2>/dev/null | awk '
    /^[^ ].*:$/          { name = substr($0, 1, length($0) - 1) }
    /^  Candidate: /     { if ($2 != "(none)") print name }' || true
}

apt_available() { [[ -n "$(pkgs_available "$1")" ]]; }

# apt_install PKG|./file.deb ...
# Skips what's installed, reports packages apt doesn't know, installs the
# rest in one batch and retries one by one if the batch fails, so one bad
# name doesn't block the others. Misses are soft failures.
# --no-install-recommends stops "recommended" extras snowballing (a GTK app
# pulling in GDM); set APT_RECOMMENDS=1 for PikaOS's own meta packages.
apt_install() {
  (( $# )) || return 0
  local -a names=() debs=() rest=() todo=() opts=()
  local p inst avail
  for p in "$@"; do
    if [[ "$p" == */* ]]; then debs+=("$p"); else names+=("$p"); fi
  done
  (( ${APT_RECOMMENDS:-0} )) || opts=(--no-install-recommends)

  if (( ${#names[@]} )); then
    inst="$(pkgs_installed "${names[@]}")"
    for p in "${names[@]}"; do in_lines "$p" "$inst" || rest+=("$p"); done
    if (( ${#rest[@]} )); then
      avail="$(pkgs_available "${rest[@]}")"
      for p in "${rest[@]}"; do
        if in_lines "$p" "$avail"; then todo+=("$p"); else soft_fail "apt: $p not available"; fi
      done
    fi
    if [[ -n "$inst" ]]; then info "Already installed: ${inst//$'\n'/ }"; fi
  fi
  todo+=("${debs[@]}")
  (( ${#todo[@]} )) || return 0

  if run "${APT_GET[@]}" install "${opts[@]}" "${todo[@]}"; then return 0; fi
  warn "Batch install failed, retrying one by one"
  for p in "${todo[@]}"; do
    "${APT_GET[@]}" install "${opts[@]}" "$p" || soft_fail "apt: $p failed to install"
  done
}

# Answer a debconf question before the package is installed.
debconf_preseed() { run_with_input "$1" sudo debconf-set-selections; }

# install_keyring NAME KEYFILE FINGERPRINT
# Checks the key's primary fingerprint, then stores it de-armored as
# /etc/apt/keyrings/NAME.gpg for use with Signed-By.
install_keyring() {
  local name="$1" keyfile="$2" want="${3// /}" got
  got="$(gpg --show-keys --with-colons "$keyfile" 2>/dev/null | awk -F: '$1 == "fpr" { print $10; exit }')"
  [[ "$got" == "$want" ]] || die "Key for $name has fingerprint '${got:-none}', expected $want"
  info "Key fingerprint OK: $want"
  gpg --dearmor <"$keyfile" 2>/dev/null >"$keyfile.gpg" || cp "$keyfile" "$keyfile.gpg"
  write_file "/etc/apt/keyrings/$name.gpg" 0644 <"$keyfile.gpg"
}

# --- Flatpak -----------------------------------------------------------------

flatpak_ensure_flathub() {
  have flatpak || apt_install flatpak
  if have flatpak && flatpak remotes --system --columns=name 2>/dev/null | grep -qx flathub; then
    return 0
  fi
  run sudo flatpak remote-add --if-not-exists --system flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
}

# flatpak_install APP_ID... (system-wide, from Flathub; skips installed ones)
flatpak_install() {
  (( $# )) || return 0
  flatpak_ensure_flathub
  local id installed=""
  local -a todo=()
  if have flatpak; then installed="$(flatpak list --system --columns=application 2>/dev/null || true)"; fi
  for id in "$@"; do in_lines "$id" "$installed" || todo+=("$id"); done
  if (( ${#todo[@]} == 0 )); then info "Flatpaks already installed: $*"; return 0; fi

  if run sudo flatpak install -y --noninteractive --system flathub "${todo[@]}"; then return 0; fi
  warn "Batch Flatpak install failed, retrying one by one"
  for id in "${todo[@]}"; do
    sudo flatpak install -y --noninteractive --system flathub "$id" || soft_fail "flatpak: $id failed to install"
  done
}

# --- mise --------------------------------------------------------------------

mise_ensure() {
  if have mise; then return 0; fi
  install_script https://mise.run sh
  is_dry || have mise || die "mise didn't install"
}

# mise_use TOOL[@VERSION]... (global). Skips tools already set globally to the
# same requested version and installed; the rest go in one call, retried one
# by one on failure.
mise_use() {
  (( $# )) || return 0
  mise_ensure
  local spec name req current=""
  local -a todo=()
  if have mise; then
    current="$(mise ls --global --json 2>/dev/null | jq -r '
      to_entries[] | .key as $k | .value[]
      | select(.installed) | "\($k)@\(.requested_version // "latest")"' 2>/dev/null || true)"
  fi
  for spec in "$@"; do
    name="${spec%@*}" req=latest
    if [[ "$spec" == *@* ]]; then req="${spec##*@}"; fi
    if in_lines "$name@$req" "$current"; then info "mise: $name@$req already set"; else todo+=("$spec"); fi
  done
  (( ${#todo[@]} )) || return 0

  if run mise use -g "${todo[@]}"; then hash -r; return 0; fi
  warn "Batch mise install failed, retrying one by one"
  for spec in "${todo[@]}"; do
    mise use -g "$spec" || soft_fail "mise: $spec failed to install"
  done
  hash -r
}

# Entries are "apt-package|mise-tool":
#   "zsh"           apt only
#   "fd-find|fd"    apt, or mise if apt doesn't have it
#   "|zellij"       mise only
# The mise tool can be any mise backend, e.g. "cargo:name" or "github:owner/repo".
apt_or_mise() {
  local entry apt_pkg mise_tool avail=""
  local -a names=() to_apt=() to_mise=()
  for entry in "$@"; do
    if [[ -n "${entry%%|*}" ]]; then names+=("${entry%%|*}"); fi
  done
  if (( ${#names[@]} )); then avail="$(pkgs_available "${names[@]}")"; fi

  for entry in "$@"; do
    apt_pkg="${entry%%|*}" mise_tool=""
    if [[ "$entry" == *"|"* ]]; then mise_tool="${entry#*|}"; fi
    if [[ -z "$mise_tool" ]] || { [[ -n "$apt_pkg" ]] && in_lines "$apt_pkg" "$avail"; }; then
      to_apt+=("$apt_pkg")                 # apt only; apt_install reports misses
    else
      to_mise+=("$mise_tool")
    fi
  done
  apt_install "${to_apt[@]}"
  mise_use "${to_mise[@]}"
}

# --- Users, groups, services -------------------------------------------------

in_group() { [[ " $(id -nG "$USER_NAME") " == *" $1 "* ]]; }

# Add the user to a group; asks for a re-login only if something changed.
add_user_to_group() {
  local group="$1"
  if ! getent group "$group" >/dev/null; then
    if is_dry; then cmd "usermod -aG $group $USER_NAME (group is created by its package)"; else soft_fail "group '$group' doesn't exist"; fi
    return 0
  fi
  if in_group "$group"; then return 0; fi
  run sudo usermod -aG "$group" "$USER_NAME"
  followup relogin "Log out and back in to use the '$group' group (or run: newgrp $group)"
}

# Enable and start units unless they already are.
enable_now() {
  local unit
  for unit in "$@"; do
    if systemctl is-enabled -q "$unit" 2>/dev/null && systemctl is-active -q "$unit" 2>/dev/null; then
      info "$unit already enabled and running"
    else
      run sudo systemctl enable --now "$unit"
    fi
  done
}

# The current display manager's unit name (empty if none is set).
dm_unit() {
  local link
  link="$(readlink /etc/systemd/system/display-manager.service 2>/dev/null || true)"
  printf '%s' "${link##*/}"
}

# Set an XDG default application only if it differs.
xdg_default() {
  local desktop="$1" mime; shift
  local -a todo=()
  for mime in "$@"; do
    [[ "$(xdg-mime query default "$mime" 2>/dev/null)" == "$desktop" ]] || todo+=("$mime")
  done
  (( ${#todo[@]} )) || { info "$desktop is already the default for $*"; return 0; }
  run xdg-mime default "$desktop" "${todo[@]}"
}
