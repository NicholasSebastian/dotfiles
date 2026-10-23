# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=noctalia_greeter
MODULE_DESC="Replace the otter-greeter login screen with Noctalia Greeter (greetd)"
MODULE_DEFAULT=1
MODULE_DEPS=(noctalia)
MODULE_RISKY=1
}

# Upstream: https://docs.noctalia.dev/greeter/installation/ and
# https://docs.noctalia.dev/noctalia/getting-started/installation/#debian
#
# PikaOS is Debian sid, so this uses Noctalia's 'unstable/' suite. Its
# noctalia-greeter package (checked: 1.7.0-2) configures greetd itself: it
# ships /etc/greetd/noctalia-greeter.toml (greeter user _greetd) plus a
# greetd.service drop-in that points greetd at that file. So
# /etc/greetd/config.toml is left alone.
#
# Nothing changes until you reboot: the old login screen is disabled, not
# stopped, so your current session keeps running (upstream uses --now, which
# would end it on the spot). An undo script goes to ~/restore-login-screen.sh.

_NG_REPO_URI="https://pkg.noctalia.dev/deb/"
_NG_SUITE="unstable/"
_NG_KEYRING_DEB="https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb"
_NG_KEY_FPR="C2A7E07FB3D746BDF2A245CD683B67D7BC99A9B7"    # expires 2027-06-01; renewals keep this fingerprint
_NG_CFG="/etc/greetd/noctalia-greeter.toml"

# Add Noctalia's APT repo, pinned low so it only supplies packages PikaOS
# doesn't have and never replaces PikaOS's own (like the noctalia shell).
_noctalia_greeter_add_repo() {
  info "noctalia-greeter isn't in PikaOS's repos, adding Noctalia's Debian sid repo (pinned low)"
  if is_dry; then
    cmd "download $_NG_KEYRING_DEB, check key fingerprint $_NG_KEY_FPR -> /etc/apt/keyrings/noctalia.gpg"
  else
    download "$_NG_KEYRING_DEB" "$MODULE_TMP/keyring.deb"
    dpkg-deb -x "$MODULE_TMP/keyring.deb" "$MODULE_TMP/keyring"
    local key
    key="$(find "$MODULE_TMP/keyring" -name '*.gpg' -path '*keyrings*' -print -quit)"
    [[ -n "$key" ]] || die "No keyring file inside $_NG_KEYRING_DEB"
    install_keyring noctalia "$key" "$_NG_KEY_FPR"
  fi

  printf '%s\n' \
    "Types: deb" \
    "URIs: $_NG_REPO_URI" \
    "Suites: $_NG_SUITE" \
    "Signed-By: /etc/apt/keyrings/noctalia.gpg" \
    | write_file /etc/apt/sources.list.d/noctalia.sources
  printf '%s\n' \
    "# Written by ~/.config/setup: Noctalia's repo only fills gaps in PikaOS's." \
    "Package: *" \
    "Pin: origin pkg.noctalia.dev" \
    "Pin-Priority: 100" \
    | write_file /etc/apt/preferences.d/90-noctalia-low
  apt_update
  followup manual "Noctalia's repo key expires 2027-06-01. If 'apt update' then complains, re-run './setup.sh --only noctalia_greeter' to fetch the renewed key (same fingerprint). If the run instead stops on a fingerprint mismatch, Noctalia replaced the key: check the new fingerprint against Noctalia's docs before putting it in _NG_KEY_FPR in modules/09-noctalia_greeter.sh."
}

# Make greetd the login screen in both places Debian keeps it: the
# display-manager.service link and /etc/X11/default-display-manager. Display
# manager packages' maintainer scripts rebuild the link from that file when
# they're upgraded or removed, so a stale entry (PikaOS ships otter-greeterd)
# would switch the login screen back, or to nothing once otter-greeter is
# gone. The cleanup module calls this too, after removing otter-greeter.
_noctalia_greeter_make_default() {
  printf '/usr/sbin/greetd\n' | write_file /etc/X11/default-display-manager 0644
  if [[ "$(dm_unit)" != greetd.service ]]; then run sudo systemctl enable --force greetd.service; fi
  printf '%s\n' greetd.service >"$RUN_DIR/dm_expected"
}

noctalia_greeter_run() {
  local restore="$HOME/restore-login-screen.sh" old_unit
  old_unit="$(dm_unit)"

  if [[ "$old_unit" == greetd.service ]] && pkg_installed noctalia-greeter; then
    info "Noctalia Greeter is already your login screen"
    _noctalia_greeter_make_default
    return 0
  fi

  confirm_risky \
    "add Noctalia's Debian sid APT repo if PikaOS doesn't package noctalia-greeter (key pinned by fingerprint, repo pinned low)" \
    "install greetd and noctalia-greeter" \
    "disable ${old_unit:-the current login screen} and enable greetd for the NEXT boot (this session keeps running)" \
    "write an undo script to $restore"

  local repo_added=0
  if ! apt_available noctalia-greeter && [[ ! -f /etc/apt/sources.list.d/noctalia.sources ]]; then
    _noctalia_greeter_add_repo
    repo_added=1
  fi
  if is_dry && (( repo_added )); then
    apt_install greetd                     # noctalia-greeter only exists once the repo is really added
    cmd "apt-get install noctalia-greeter (from Noctalia's repo)"
  else
    apt_install greetd noctalia-greeter
  fi
  if is_dry; then
    info "Would check that greetd uses $_NG_CFG (via the package's systemd drop-in)"
  else
    have noctalia-greeter-session || die "Noctalia Greeter didn't install, so the login screen was left unchanged"
    systemctl cat greetd.service 2>/dev/null | grep -q "$_NG_CFG" \
      || die "greetd isn't set up to use $_NG_CFG (package layout changed?); login screen left unchanged"
  fi

  # Greeter account from the package's config (Debian's greetd uses _greetd)
  local greeter_user
  greeter_user="$(awk -F'=' '
    /^\[/ { sec = $0 }
    sec == "[default_session]" && $1 ~ /^[[:space:]]*user[[:space:]]*$/ {
      v = $2; gsub(/^[[:space:]"]+|[[:space:]"]+$/, "", v); print v; exit
    }' "$_NG_CFG" 2>/dev/null || true)"
  : "${greeter_user:=_greetd}"
  run sudo env GREETER_USER="$greeter_user" noctalia-greeter-apply-appearance --setup-system

  # An [initial_session] means automatic login: the greeter would only
  # appear after you log out, never at boot
  if grep -qs '^\[initial_session\]' "$_NG_CFG"; then
    followup manual "Noctalia Greeter: $_NG_CFG has an [initial_session] (automatic login), so you'll only see the greeter after logging out."
  fi

  # Undo script (first run only, so it always points back to the original setup)
  local old_x11 x11_line=""
  old_x11="$(cat /etc/X11/default-display-manager 2>/dev/null || true)"
  if [[ -n "$old_x11" ]]; then x11_line="echo '$old_x11' | sudo tee /etc/X11/default-display-manager >/dev/null"; fi
  if [[ ! -f "$restore" && -n "$old_unit" && "$old_unit" != greetd.service ]]; then
    write_file "$restore" 0755 <<EOF
#!/usr/bin/env bash
# Undo the Noctalia Greeter switch (written by ~/.config/setup).
# From a text console (Ctrl+Alt+F3, then log in): bash ~/restore-login-screen.sh
set -euo pipefail
sudo systemctl enable --force '$old_unit'
sudo systemctl disable greetd.service
$x11_line
echo "Login screen restored to $old_unit. Optional: sudo apt remove noctalia-greeter. Reboot with: sudo reboot"
EOF
  fi

  # Switch login screens for the next boot. No --now: stopping the current
  # one would end this session on the spot.
  if [[ -n "$old_unit" && "$old_unit" != greetd.service ]]; then run sudo systemctl disable "$old_unit"; fi
  _noctalia_greeter_make_default

  followup reboot "Noctalia Greeter takes over at the next reboot. Black screen? Press Ctrl+Alt+F3, log in, run 'bash ~/restore-login-screen.sh', then 'sudo reboot'."
  followup manual "To match the login screen to your desktop: Noctalia Settings -> Security -> Noctalia Greeter -> Sync Now (or Auto-Sync). Fonts must be installed system-wide to show there; install accountsservice for user avatars."
}
