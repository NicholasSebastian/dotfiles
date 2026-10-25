# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=laptop
MODULE_DESC="ASUS ROG tools (asusctl, ROG Control Center, supergfxctl)"
MODULE_DEFAULT=0
}

# ASUS ROG: fan/power profiles, keyboard backlight, and dGPU switching.
# Not in Debian; installed only if your PikaOS repos package them.
laptop_run() {
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
