# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=noctalia_greeter
MODULE_DESC="Replace the otter-greeter login screen with Noctalia Greeter (greetd), synced to Noctalia's look"
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
_NG_TOML="/var/lib/noctalia-greeter/greeter.toml"
_NG_COMPOSITOR=/usr/bin/noctalia-greeter-compositor
_NG_PATCH="$SETUP_DIR/files/noctalia-greeter/keep-unused-outputs-black.patch"

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

# PikaOS enables eCryptfs's PAM profile (pam_ecryptfs.so in common-auth, as
# 'required') though nothing uses an encrypted home. It once crashed greetd's
# auth worker (SIGSEGV in pam_ecryptfs), which leaves the greeter waiting with
# no error, so the login silently does nothing. Turned off when no eCryptfs
# home exists; undo: sudo pam-auth-update --enable ecryptfs-utils
_noctalia_greeter_no_ecryptfs() {
  grep -qs 'pam_ecryptfs' /etc/pam.d/common-auth || return 0
  if [[ -d /home/.ecryptfs || -d "$HOME/.ecryptfs" ]]; then
    info "eCryptfs home found; its PAM module stays on"
    return 0
  fi
  confirm_step "Turn off the unused eCryptfs PAM module (pam-auth-update --disable ecryptfs-utils): it can crash greetd's login check, and nothing here uses an encrypted home" \
    || { info "eCryptfs PAM module left on"; return 0; }
  run sudo env DEBIAN_FRONTEND=noninteractive pam-auth-update --disable ecryptfs-utils
  if ! is_dry && grep -qs 'pam_ecryptfs' /etc/pam.d/common-auth; then
    soft_fail "pam-auth-update didn't remove pam_ecryptfs from /etc/pam.d/common-auth; run 'sudo pam-auth-update' and untick eCryptfs"
  fi
}

# _noctalia_greeter_set_output FILE NAME RATES: print FILE with [output] name
# and refresh_rate set to NAME and RATES, right under the [output] header.
# An empty NAME removes name (= all monitors); RATES "-" leaves refresh_rate
# as it is, empty removes it. Adds an [output] section at the end if needed.
# Other keys and sections are kept.
_noctalia_greeter_set_output() {
  local n="${2//\\/\\\\}" r="${3//\\/\\\\}"
  n="${n//\"/\\\"}"; r="${r//\"/\\\"}"
  NAME="$n" RATES="$r" awk '
    function emit() {
      if (ENVIRON["NAME"] != "") print "name = \"" ENVIRON["NAME"] "\"  # chosen by ~/.config/setup"
      if (ENVIRON["RATES"] != "" && ENVIRON["RATES"] != "-") print "refresh_rate = \"" ENVIRON["RATES"] "\"  # max per monitor, by ~/.config/setup"
      done = 1
    }
    /^[[:space:]]*\[/ {
      in_out = ($0 ~ /^[[:space:]]*\[output\][[:space:]]*(#.*)?$/)
      print
      if (in_out && !done) emit()
      next
    }
    in_out && /^[[:space:]]*name[[:space:]]*=/ { next }
    in_out && ENVIRON["RATES"] != "-" && /^[[:space:]]*refresh_rate[[:space:]]*=/ { next }
    { print }
    END {
      if (!done && (ENVIRON["NAME"] != "" || (ENVIRON["RATES"] != "" && ENVIRON["RATES"] != "-"))) {
        if (NR) print ""
        print "[output]"; emit()
      }
    }' "$1"
}

# CONNECTOR<TAB>HZ per monitor: the highest refresh rate at the monitor's
# preferred resolution (the greeter uses that resolution, and applies
# refresh_rate at it). Hyprland lists the preferred mode first, like DRM.
# Without a running Hyprland (e.g. a Niri session) this prints nothing.
_noctalia_greeter_max_rates() {
  have hyprctl || return 0
  hyprctl monitors all -j 2>/dev/null | jq -r '
    .[] | select(.availableModes | length > 0)
    | (.availableModes[0] | split("@")[0]) as $res
    | ([.availableModes[] | select(startswith($res + "@")) | sub(".*@"; "") | sub("Hz$"; "") | tonumber] | max) as $hz
    | "\(.name)\t\($hz | round)"' 2>/dev/null || true
}

# Upstream turns every monitor except the pinned one off while the greeter
# runs (choose_outputs() in src/compositor/noctalia_compositor.c), so they
# lose signal. This builds the compositor from the installed version's
# source with files/noctalia-greeter/keep-unused-outputs-black.patch, which
# keeps them on and black instead, and installs it over the packaged binary.
# A noctalia-greeter upgrade puts the stock binary back (monitors switch off
# again, nothing breaks); the next run notices via the stamp and rebuilds.
# Back to stock: sudo apt install --reinstall noctalia-greeter
_noctalia_greeter_patch_compositor() {
  local ver stamp="$LOG_DIR/noctalia-greeter-compositor.stamp" want=""
  local src="$MODULE_TMP/noctalia-greeter-src"
  [[ -f "$_NG_PATCH" ]] || die "Patch missing: $_NG_PATCH (run chezmoi apply)"
  ver="$(dpkg-query -W -f='${Version}' noctalia-greeter 2>/dev/null || true)"
  ver="${ver#*:}"; ver="${ver%-*}"           # 1.7.0-2 -> 1.7.0
  [[ -n "$ver" ]] || { info "noctalia-greeter isn't installed; the compositor patch waits for the next run"; return 0; }

  # "<version> <patch sha256> <installed binary sha256>" of the last install
  if [[ -f "$stamp" && -f "$_NG_COMPOSITOR" ]]; then
    want="$ver $(sha256sum "$_NG_PATCH" | cut -d' ' -f1) $(sha256sum "$_NG_COMPOSITOR" | cut -d' ' -f1)"
    if [[ "$(cat "$stamp")" == "$want" ]]; then
      info "Patched Noctalia Greeter compositor $ver is installed (other monitors stay on, black)"
      return 0
    fi
  fi

  confirm_step "Build noctalia-greeter-compositor $ver from source with the keep-monitors-on patch and install it over $_NG_COMPOSITOR (installs ~20 -dev build packages; undo: sudo apt install --reinstall noctalia-greeter)" \
    || { info "Compositor left as packaged: the other monitors switch off at the login screen"; return 0; }

  apt_install meson ninja-build pkgconf g++ git patch libwayland-dev wayland-protocols \
    libxkbcommon-dev libfreetype-dev libfontconfig-dev libcairo2-dev libpango1.0-dev \
    librsvg2-dev libxml2-dev libglib2.0-dev libtomlplusplus-dev nlohmann-json3-dev \
    libwlroots-0.20-dev libinput-dev libegl-dev libgles-dev libwebp-dev libjxl-dev libstb-dev

  run git clone -q --depth 1 --branch "v$ver" https://github.com/noctalia-dev/noctalia-greeter "$src" \
    || { soft_fail "Noctalia Greeter: couldn't fetch source tag v$ver; compositor left as packaged"; return 0; }
  run_in "$src" patch -p1 --forward --quiet -i "$_NG_PATCH" \
    || { soft_fail "Noctalia Greeter: the patch doesn't apply to v$ver (upstream changed); compositor left as packaged. Update files/noctalia-greeter/keep-unused-outputs-black.patch"; return 0; }
  if ! run_in "$src" meson setup build --prefix=/usr --buildtype=release \
    || ! run_in "$src" meson compile -C build noctalia-greeter-compositor; then
    soft_fail "Noctalia Greeter: compositor build failed (see the log); compositor left as packaged"
    return 0
  fi

  run sudo mkdir -p "/var/backups/setup${_NG_COMPOSITOR%/*}"
  run sudo cp -a "$_NG_COMPOSITOR" "/var/backups/setup$_NG_COMPOSITOR.$TS"
  run sudo install -m 0755 "$src/build/noctalia-greeter-compositor" "$_NG_COMPOSITOR"
  if ! is_dry; then
    mkdir -p "$LOG_DIR"
    printf '%s %s %s\n' "$ver" "$(sha256sum "$_NG_PATCH" | cut -d' ' -f1)" "$(sha256sum "$_NG_COMPOSITOR" | cut -d' ' -f1)" >"$stamp"
  fi
  followup reboot "Noctalia Greeter: patched compositor installed; at the next login screen the other monitors stay on and black."
  followup manual "Noctalia Greeter: after a noctalia-greeter update, re-run './setup.sh --only noctalia_greeter' to rebuild the patched compositor (until then the other monitors switch off again). Back to stock: sudo apt install --reinstall noctalia-greeter"
}

# Which monitor shows the login screen. Noctalia Greeter shows it on every
# monitor, or on one pinned with [output] name in greeter.toml; it can't do a
# subset (https://docs.noctalia.dev/greeter/displays/). The directory is
# _greetd's (mode 750), so the file is read and written with sudo.
_noctalia_greeter_displays() {
  local conn id key cur="" known=1 exists=0 i c=0 hz rates="" rate_info=""
  local -A max_hz=()
  local old="$MODULE_TMP/greeter.toml" new="$MODULE_TMP/greeter.toml.new"
  local -a conns=() ids=() vals=("") labs=("All monitors")

  if ! have noctalia-greeter; then
    info "Noctalia Greeter isn't installed yet; its monitor is asked about on the next run"
    return 0
  fi
  while IFS=$'\t' read -r conn id; do
    if [[ -n "$conn" ]]; then conns+=("$conn"); ids+=("$id"); fi
  done < <(noctalia-greeter outputs --details 2>/dev/null || true)
  if (( ${#conns[@]} == 0 )); then
    info "Login screen monitor: no monitors found from this session, nothing to set"
    return 0
  fi
  while IFS=$'\t' read -r conn hz; do
    if [[ -n "$conn" && "$hz" =~ ^[0-9]+$ ]]; then max_hz[$conn]=$hz; fi
  done < <(_noctalia_greeter_max_rates)

  # Current setting (dry run: only if sudo needs no password). The copy in
  # $MODULE_TMP is meant to be ours, so sudo not covering '>' is intended.
  : >"$old"
  # shellcheck disable=SC2024
  if is_dry; then
    if sudo -n test -f "$_NG_TOML" 2>/dev/null; then exists=1; sudo -n cat "$_NG_TOML" >"$old"
    elif ! sudo -n true 2>/dev/null; then known=0; fi
  elif sudo test -f "$_NG_TOML"; then
    exists=1; sudo cat "$_NG_TOML" >"$old"
  fi
  cur="$(awk '
    /^[[:space:]]*\[/ { in_out = ($0 ~ /^[[:space:]]*\[output\][[:space:]]*(#.*)?$/); next }
    in_out && /^[[:space:]]*name[[:space:]]*=/ {
      v = $0; sub(/^[^=]*=[[:space:]]*"/, "", v); sub(/".*$/, "", v); print v; exit
    }' "$old")"

  # One entry per monitor. Pin the stable id (connector numbers can change
  # between boots) unless it's empty or shared by two identical monitors.
  for i in "${!conns[@]}"; do
    key="${conns[i]}"
    if [[ -n "${ids[i]}" ]] && (( $(printf '%s\n' "${ids[@]}" | grep -cxF -- "${ids[i]}") == 1 )); then key="${ids[i]}"; fi
    vals+=("$key"); labs+=("Only ${conns[i]}${ids[i]:+ (${ids[i]})}")
    hz="${max_hz[${conns[i]}]:-}"
    if [[ -n "$hz" ]]; then rates+="${rates:+; }$key:$hz"; rate_info+="${rate_info:+, }${conns[i]} $hz Hz"; fi
    if [[ -n "$cur" && ( "$cur" == "${conns[i]}" || "$cur" == "${ids[i]}" ) ]]; then c=$(( i + 1 )); fi
  done
  # The current choice goes first, so Enter keeps it. A pin to a monitor
  # that isn't connected counts as "All monitors": that's what the greeter does.
  if (( known )); then
    labs[c]+=" (current)"
    if (( c > 0 )); then
      key="${vals[0]}"; vals[0]="${vals[c]}"; vals[c]="$key"
      key="${labs[0]}"; labs[0]="${labs[c]}"; labs[c]="$key"
    fi
  fi

  if (( ${#conns[@]} < 2 )); then
    key="$cur"                              # one monitor: nothing to choose
  elif ask_choice "Which monitor should show the login screen? (Noctalia Greeter can use all of them or just one)" "${labs[@]}"; then
    key="${vals[CHOICE - 1]}"
    if [[ -n "$key" ]]; then _noctalia_greeter_patch_compositor; fi
  else
    info "No terminal: login screen monitor left as it is"
    key="$cur"
    if [[ -n "$key" ]]; then _noctalia_greeter_patch_compositor; fi
  fi
  # Every monitor at its highest refresh rate (the greeter otherwise uses
  # the EDID-preferred mode, often 60 Hz); "-" keeps any existing setting
  # when the rates can't be read from this session.
  if [[ -n "$rates" ]]; then info "Login screen refresh rates: $rate_info"; else rates="-"; info "Couldn't read the monitors' refresh rates (needs a running Hyprland); refresh rate left as it is"; fi
  _noctalia_greeter_set_output "$old" "$key" "$rates" >"$new"
  if (( known )) && cmp -s "$old" "$new"; then
    info "Login screen monitor and refresh rates unchanged"
    return 0
  fi

  if is_dry && (( ! known )); then
    info "Would update $_NG_TOML if it differs (reading it needs sudo; run 'sudo -v' first to see the diff)"
    return 0
  fi
  info "Writing $_NG_TOML"
  if is_dry; then
    show_diff "$old" "$new"
    return 0
  fi
  local owner mode=0644
  owner="$(sudo stat -c '%U:%G' "${_NG_TOML%/*}")"
  if (( exists )); then
    owner="$(sudo stat -c '%U:%G' "$_NG_TOML")"; mode="$(sudo stat -c '%a' "$_NG_TOML")"
    run sudo mkdir -p "/var/backups/setup${_NG_TOML%/*}"
    run sudo cp -a "$_NG_TOML" "/var/backups/setup$_NG_TOML.$TS"
  fi
  run sudo install -m "$mode" -o "${owner%%:*}" -g "${owner#*:}" "$new" "$_NG_TOML"
  followup reboot "Noctalia Greeter: from the next boot the login screen shows on ${key:-all monitors}${rate_info:+, at $rate_info}."
}

# Copy Noctalia's look (wallpaper, colours, font, monitor layout) to the
# login screen now; [shell.greeter_sync] auto_sync in the dotfiles keeps it
# in sync afterwards. Sync runs a root helper through pkexec; the package's
# passwordless-sync rule lets only this user, in an active local session,
# run only that helper with --sync, so it never prompts (there's no polkit
# agent to show a prompt). https://docs.noctalia.dev/greeter/sync/
# Undo: sudo noctalia-greeter passwordless-sync disable $USER
_noctalia_greeter_sync() {
  local out
  if ! run sudo noctalia-greeter passwordless-sync enable "$USER_NAME"; then
    soft_fail "Noctalia Greeter: couldn't allow passwordless sync for $USER_NAME; syncs will ask for an admin password"
  fi
  if is_dry; then cmd "noctalia msg greeter-sync"; return 0; fi
  if ! pgrep -x noctalia >/dev/null; then
    followup manual "Noctalia Greeter: log in to Noctalia and run 'noctalia msg greeter-sync' to copy its look to the login screen."
    return 0
  fi
  cmd "noctalia msg greeter-sync"
  out="$(noctalia msg greeter-sync 2>&1 || true)"
  if [[ "$out" == ok ]]; then
    info "Copying Noctalia's look to the login screen (finishes in the background)"
  else
    # Noctalia only offers greeter-sync if the greeter was installed when it started
    followup manual "Noctalia Greeter: run 'noctalia msg greeter-sync' after you next log in to copy Noctalia's look to the login screen (now: ${out:-no answer})."
  fi
}

noctalia_greeter_run() {
  local restore="$HOME/restore-login-screen.sh" old_unit
  old_unit="$(dm_unit)"

  if [[ "$old_unit" == greetd.service ]] && pkg_installed noctalia-greeter; then
    info "Noctalia Greeter is already your login screen"
    _noctalia_greeter_make_default
    _noctalia_greeter_no_ecryptfs
    _noctalia_greeter_displays
    _noctalia_greeter_sync
    return 0
  fi

  confirm_risky \
    "add Noctalia's Debian sid APT repo if PikaOS doesn't package noctalia-greeter (key pinned by fingerprint, repo pinned low)" \
    "install greetd and noctalia-greeter" \
    "ask to turn off the unused eCryptfs PAM module if it's enabled (it can make greetd logins silently fail)" \
    "ask which monitor shows the login screen (all, or one) and set it in $_NG_TOML; with one, build a patched greeter compositor so the other monitors stay on and black" \
    "disable ${old_unit:-the current login screen} and enable greetd for the NEXT boot (this session keeps running)" \
    "write an undo script to $restore" \
    "allow passwordless login-screen sync for $USER_NAME (only the greeter's sync helper) and copy Noctalia's look to the login screen now"

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
  _noctalia_greeter_displays
  _noctalia_greeter_no_ecryptfs

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
  _noctalia_greeter_sync

  followup reboot "Noctalia Greeter takes over at the next reboot. Black screen? Press Ctrl+Alt+F3, log in, run 'bash ~/restore-login-screen.sh', then 'sudo reboot'."
  followup manual "Noctalia Greeter: fonts must be installed system-wide to show on the login screen; install accountsservice for user avatars."
}
