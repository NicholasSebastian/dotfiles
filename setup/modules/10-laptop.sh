# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=laptop
MODULE_DESC="ASUS ROG tools (asusctl, ROG Control Center, supergfxctl), OpenLogi (Logitech mice/keyboards)"
MODULE_DEFAULT=0
}

# ASUS ROG: fan/power profiles, keyboard backlight, and dGPU switching.
# Not in Debian; installed only if PikaOS repos package them.
_laptop_rog() {
  local pkg
  local -a pkgs=()
  for pkg in asusctl rog-control-center supergfxctl; do
    if apt_available "$pkg"; then
      pkgs+=("$pkg")
    else
      followup manual "$pkg isn't in your apt repos. Build instructions: https://asus-linux.org"
    fi
  done
  apt_install "${pkgs[@]}"
  if have supergfxctl; then enable_now supergfxd.service; fi
}

# OpenLogi: Logitech Options+ replacement.
# Not in apt or on Flathub, so its .deb comes from the latest GitHub release.
# Its background agent is a user service that has to be enabled.
# https://github.com/AprilNEA/OpenLogi
_laptop_openlogi() {
  local deb="$MODULE_TMP/openlogi.deb" unit=openlogi-agent.service
  if pkg_installed openlogi; then
    info "OpenLogi already installed"
  elif gh_download_latest AprilNEA/OpenLogi '-linux-amd64\.deb$' "$deb"; then
    apt_install "$deb"
  else
    soft_fail "OpenLogi: couldn't download the .deb from the latest AprilNEA/OpenLogi release"
    return 0
  fi

  if ! is_dry && ! pkg_installed openlogi; then return 0; fi   # apt_install already reported it
  if ! is_dry && systemctl --user is-enabled -q "$unit" 2>/dev/null && systemctl --user is-active -q "$unit" 2>/dev/null; then
    info "OpenLogi agent already running"
  elif ! run systemctl --user enable --now "$unit"; then
    soft_fail "OpenLogi: couldn't start its agent; run 'systemctl --user enable --now $unit' in your desktop session"
  fi
  if pkg_installed solaar; then
    followup manual "OpenLogi and Solaar both want your Logitech receiver: quit Solaar (or remove it) before using OpenLogi."
  fi
}

laptop_run() {
  _laptop_rog
  _laptop_openlogi
}
