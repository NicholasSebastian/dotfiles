# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=cleanup
MODULE_DESC="Offer to remove duplicates: Otter leftovers, extra file managers, Chromium, GNOME leftovers"
MODULE_DEFAULT=1
MODULE_RISKY=1
}

# Goes through packages that other modules made redundant and asks, group by
# group, which to remove. Nothing is removed without an answer: --yes and
# --force don't skip these questions. Every package is checked with an apt
# simulation first, and one that would take anything else along (e.g. a
# PikaOS meta package, or something another kept package needs) is kept and
# not offered. All picks go into one 'apt-get remove' (configs are kept, not
# purged); configs that pointed at removed apps are fixed afterwards.

_CLEANUP_NO_TTY="needs your answers but there is no terminal"
_CLEANUP_REMOVE=()                       # packages picked for removal
_CLEANUP_ALLOW=(pika-shell-profile-common)  # may go along with them (only holds Otter apps)
_CLEANUP_FM_KEEP=""
_CLEANUP_BROWSER_BIN="" _CLEANUP_BROWSER_NAME=""   # replaces chromium in keybinds

# GNOME desktop pieces left over from an earlier GNOME install. gnome-keyring,
# gnome-disk-utility, ibus and im-config are left alone on purpose.
_CLEANUP_GNOME=(
  gnome-shell gnome-shell-common gnome-control-center gnome-control-center-data
  gnome-session-bin gnome-session-common gnome-session-canberra
  gnome-settings-daemon gnome-settings-daemon-common mutter-common mutter-common-bin
  gnome-remote-desktop gnome-user-share gnome-online-accounts gnome-browser-connector
  gnome-bluetooth-sendto gnome-menus gnome-user-docs
  rygel evolution-ews-core realmd tecla apache2-bin libapache2-mod-dnssd
)

# --- Helpers -----------------------------------------------------------------

# Packages 'apt-get -s ARGS...' would remove (simulation, no root needed).
_cleanup_apt_removes() { apt-get -s "$@" 2>/dev/null | awk '$1 == "Remv" { print $2 }' || true; }

# Packages apt would remove along with PKG... (simulation, no root needed).
_cleanup_sim() {
  (( $# )) || return 0
  _cleanup_apt_removes remove "$@"
}

# _cleanup_outside LIST OK: lines of LIST that aren't in OK.
_cleanup_outside() {
  local p
  while IFS= read -r p; do
    if [[ -n "$p" ]] && ! in_lines "$p" "$2"; then printf '%s\n' "$p"; fi
  done <<<"$1"
}

_cleanup_picked() { in_lines "$1" "$(printf '%s\n' "${_CLEANUP_REMOVE[@]}")"; }

# The given packages that are installed, in the given order.
_cleanup_installed() {
  (( $# )) || return 0
  local p inst
  inst="$(pkgs_installed "$@")"
  for p in "$@"; do
    if in_lines "$p" "$inst"; then printf '%s\n' "$p"; fi
  done
}

# _cleanup_sim_each DIR PKG...: simulate removing each PKG on its own (plus the
# picks so far), several at a time; DIR/PKG lists what would go.
_cleanup_sim_each() {
  local dir="$1"; shift
  rm -rf "$dir"; mkdir -p "$dir"
  # shellcheck disable=SC2016  # $0/$1/$@ belong to the inner bash
  printf '%s\n' "$@" | xargs -r -P 8 -I{} bash -c \
    'apt-get -s remove "$@" 2>/dev/null | sed -n "s/^Remv \([^ ]*\).*/\1/p" >"$0/$1" || true' \
    "$dir" {} "${_CLEANUP_REMOVE[@]}"
}

# The first 8 lines of LIST on one line, plus how many more there are.
_cleanup_brief() {
  local -a w=()
  mapfile -t w <<<"$1"
  printf '%s' "${w[*]:0:8}"
  if (( ${#w[@]} > 8 )); then printf ' (and %d more)' $(( ${#w[@]} - 8 )); fi
}

# _cleanup_filter EXTRA_ALLOW_CSV PKG...
# Print the PKGs that can be removed (with everything picked so far) without
# taking anything else along, apart from the PKGs themselves, _CLEANUP_ALLOW
# and EXTRA_ALLOW_CSV. Usually one simulation; if that fails, each PKG is
# checked on its own and the ones that would take more along are kept (which
# can make others fail in turn, so it repeats until nothing changes).
# Messages go to stderr because callers capture stdout.
_cleanup_filter() {
  local extra="$1" base ok out p dir="$MODULE_TMP/sim"; shift
  local -a keep=("$@") next=()
  base="$(printf '%s\n' "${_CLEANUP_REMOVE[@]}" "${_CLEANUP_ALLOW[@]}" "${extra//,/$'\n'}")"
  ok="$base"$'\n'"$(printf '%s\n' "$@")"
  out="$(_cleanup_outside "$(_cleanup_sim "${_CLEANUP_REMOVE[@]}" "$@")" "$ok")"
  if [[ -z "$out" ]]; then printf '%s\n' "$@"; return 0; fi

  info "Checking each package separately (apt simulation)..." >&2
  _cleanup_sim_each "$dir" "$@"
  while (( ${#keep[@]} )); do
    ok="$base"$'\n'"$(printf '%s\n' "${keep[@]}")"
    next=()
    for p in "${keep[@]}"; do
      out="$(_cleanup_outside "$(<"$dir/$p")" "$ok")"
      if [[ -z "$out" ]]; then next+=("$p"); else info "Keeping $p: removing it would also remove $(_cleanup_brief "$out")" >&2; fi
    done
    (( ${#next[@]} < ${#keep[@]} )) || break
    keep=("${next[@]}")
  done

  # Each passes alone; make sure they also pass together
  if (( ${#keep[@]} )); then
    ok="$base"$'\n'"$(printf '%s\n' "${keep[@]}")"
    out="$(_cleanup_outside "$(_cleanup_sim "${_CLEANUP_REMOVE[@]}" "${keep[@]}")" "$ok")"
    if [[ -n "$out" ]]; then
      info "Keeping ${keep[*]}: removing them together would also remove $(_cleanup_brief "$out")" >&2
      keep=()
    fi
  fi
  if (( ${#keep[@]} )); then printf '%s\n' "${keep[@]}"; fi
}

# _cleanup_candidates EXTRA_ALLOW_CSV PKG...: the installed PKGs that pass _cleanup_filter.
_cleanup_candidates() {
  local extra="$1"; shift
  local -a inst=()
  mapfile -t inst < <(_cleanup_installed "$@")
  if (( ${#inst[@]} )); then _cleanup_filter "$extra" "${inst[@]}"; fi
}

# List PKG... and whatever else apt would remove with them (beyond what the
# earlier picks already take along).
_cleanup_show() {
  local also
  printf '       - %s\n' "$@"
  also="$(_cleanup_outside "$(_cleanup_sim "${_CLEANUP_REMOVE[@]}" "$@")" \
    "$(_cleanup_sim "${_CLEANUP_REMOVE[@]}"; printf '%s\n' "$@")")"
  if [[ -n "$also" ]]; then printf '       (also removes: %s)\n' "${also//$'\n'/ }"; fi
}

# _cleanup_ask_one QUESTION PKG...: y/N for the whole set. Does nothing without PKGs.
_cleanup_ask_one() {
  (( $# > 1 )) || return 0
  local question="$1"; shift
  _cleanup_show "$@"
  if is_dry; then info "(dry run: would ask) $question"; _CLEANUP_REMOVE+=("$@"); return 0; fi
  if ask_yes_no "$question"; then _CLEANUP_REMOVE+=("$@"); fi
}

# _cleanup_ask_all QUESTION PKG...: keep all, remove all, or pick one by one.
# Does nothing without PKGs.
_cleanup_ask_all() {
  (( $# > 1 )) || return 0
  local question="$1" p; shift
  _cleanup_show "$@"
  if is_dry; then info "(dry run: would ask) $question"; _CLEANUP_REMOVE+=("$@"); return 0; fi
  ask_choice "$question" "Keep them" "Remove all of them" "Choose one by one" || module_skip "$_CLEANUP_NO_TTY"
  case "$CHOICE" in
    2) _CLEANUP_REMOVE+=("$@") ;;
    3) for p in "$@"; do
         if ask_yes_no "Remove $p?"; then _CLEANUP_REMOVE+=("$p"); fi
       done ;;
  esac
}

# --- Groups ------------------------------------------------------------------

_cleanup_greeter() {
  local -a c=()
  if [[ "$(dm_unit)" != greetd.service ]] || ! pkg_installed noctalia-greeter; then return 0; fi
  mapfile -t c < <(_cleanup_candidates "" otter-greeter)
  _cleanup_ask_one "Remove otter-greeter? Noctalia Greeter is your login screen now." "${c[@]}"
}

_cleanup_terminal() {
  local -a c=()
  pkg_installed ghostty || return 0
  mapfile -t c < <(_cleanup_candidates otter-shell-plugins,otter-bluetooth-plugin otter-term)
  _cleanup_ask_one "Remove Otter Terminal (otter-term)? Ghostty is your terminal." "${c[@]}"
  if _cleanup_picked otter-term; then _CLEANUP_ALLOW+=(otter-shell-plugins otter-bluetooth-plugin); fi
}

# PikaOS ships Nemo and Otter Files (an older setup also added Nautilus): keep one.
_cleanup_file_manager() {
  local -A name=([nemo]=Nemo [otter-files]="Otter Files" [nautilus]=Nautilus)
  local -A extra=([nemo]="" [otter-files]="xdg-desktop-portal-otter" [nautilus]="gnome-sushi,xdg-desktop-portal-gnome")
  local -a inst=() opts=("Keep all of them") keeps=("") drop=() ok=() more=()
  local keep p allow
  mapfile -t inst < <(_cleanup_installed nemo otter-files nautilus)
  (( ${#inst[@]} >= 2 )) || return 0

  for keep in "${inst[@]}"; do
    drop=() allow=""
    for p in "${inst[@]}"; do
      if [[ "$p" != "$keep" ]]; then drop+=("$p"); allow+="${extra[$p]},"; fi
    done
    mapfile -t ok < <(_cleanup_filter "$allow" "${drop[@]}")
    if (( ${#ok[@]} == ${#drop[@]} )); then
      opts+=("Keep only ${name[$keep]} (removes ${drop[*]})")
      keeps+=("$keep")
    fi
  done
  (( ${#opts[@]} > 1 )) || return 0

  if in_lines otter-files "$(printf '%s\n' "${inst[@]}")"; then
    info "Removing Otter Files also removes Otter's desktop portal; apps then use the Hyprland/GTK portals (file pickers, screen sharing)."
  fi
  local question="You have ${#inst[@]} file managers. Which should stay?"
  if is_dry; then
    info "(dry run: would ask) $question"
    printf '       - %s\n' "${opts[@]}"
    return 0
  fi
  ask_choice "$question" "${opts[@]}" || module_skip "$_CLEANUP_NO_TTY"
  keep="${keeps[CHOICE - 1]}"
  [[ -n "$keep" ]] || return 0

  _CLEANUP_FM_KEEP="$keep"
  for p in "${inst[@]}"; do
    [[ "$p" != "$keep" ]] || continue
    _CLEANUP_REMOVE+=("$p")
    IFS=, read -ra more <<<"${extra[$p]}"
    _CLEANUP_ALLOW+=("${more[@]}")
  done
}

# Otter's shell pieces, once Noctalia is what starts at login. The greeter,
# terminal and file manager have their own questions; packages that the kept
# ones still need (wallpaper, portal helpers, fonts) are kept automatically.
_cleanup_otter_shell() {
  local -a all=() c=()
  pkg_installed noctalia || return 0
  grep -qsE '^[[:space:]]*hl[.]exec_cmd[(]"noctalia"[)]' "$HOME/.config/hypr/exec.lua" || return 0
  mapfile -t all < <(dpkg-query -W -f='${db:Status-Status} ${Package}\n' 'otter-*' 2>/dev/null \
    | awk '$1 == "installed" && $2 !~ /^otter-(files|term|greeter)$/ { print $2 }' || true)
  (( ${#all[@]} )) || return 0
  mapfile -t c < <(_cleanup_filter "" "${all[@]}")
  _cleanup_ask_all "Noctalia replaces the Otter shell (bar, dock, launcher, notifications, lock, OSD...). Remove these Otter packages?" "${c[@]}"
}

_cleanup_browser() {
  local -a c=() browsers=()
  if pkg_installed brave-browser; then browsers+=(Brave); _CLEANUP_BROWSER_BIN=brave-browser; fi
  if pkg_installed google-chrome-stable; then
    browsers+=("Google Chrome")
    if [[ -z "$_CLEANUP_BROWSER_BIN" ]]; then _CLEANUP_BROWSER_BIN=google-chrome-stable; fi
  fi
  _CLEANUP_BROWSER_NAME="${browsers[0]:-}"
  (( ${#browsers[@]} )) || return 0
  mapfile -t c < <(_cleanup_candidates "" chromium)
  local names="${browsers[0]}"
  if (( ${#browsers[@]} > 1 )); then names+=" and ${browsers[1]}"; fi
  _cleanup_ask_one "Remove Chromium? You use $names." "${c[@]}"
}

_cleanup_gnome() {
  local -a mutter=() c=()
  pkg_installed gnome-shell || return 0
  if pkg_installed gdm3; then return 0; fi           # a GNOME session is still set up
  mapfile -t mutter < <(dpkg-query -W -f='${db:Status-Status} ${Package}\n' 'libmutter-*' 'gir1.2-mutter-*' 2>/dev/null \
    | awk '$1 == "installed" && $2 ~ /^(libmutter-[0-9]+-0|gir1\.2-mutter-[0-9]+)$/ { print $2 }' || true)
  mapfile -t c < <(_cleanup_candidates "" "${_CLEANUP_GNOME[@]}" "${mutter[@]}")
  _cleanup_ask_all "These GNOME desktop pieces are left over from an earlier GNOME install and aren't used by Hyprland. Remove them?" "${c[@]}"
}

# --- Removal -----------------------------------------------------------------

_cleanup_remove() {
  local all outside
  local -a list=()
  if (( ${#_CLEANUP_REMOVE[@]} == 0 )); then info "No duplicates to remove"; return 0; fi
  all="$(_cleanup_sim "${_CLEANUP_REMOVE[@]}" | sort)"
  [[ -n "$all" ]] || die "apt couldn't work out the removal; nothing was removed"
  outside="$(_cleanup_outside "$all" "$(printf '%s\n' "${_CLEANUP_REMOVE[@]}" "${_CLEANUP_ALLOW[@]}")")"
  [[ -z "$outside" ]] || die "apt would also remove: ${outside//$'\n'/ }; nothing was removed"

  mapfile -t list <<<"$all"
  warn "Removing ${#list[@]} packages:"
  printf '       - %s\n' "${list[@]}"
  if ! is_dry; then ask_yes_no "Remove these packages now?" || module_skip "removal not confirmed"; fi

  # Otter's portal goes with Otter Files; make sure a replacement is there
  if _cleanup_picked otter-files; then apt_install xdg-desktop-portal-hyprland xdg-desktop-portal-gtk; fi
  run "${APT_GET[@]}" remove "${_CLEANUP_REMOVE[@]}"
}

# Picked now, or already removed (e.g. by an earlier run).
_cleanup_gone() { _cleanup_picked "$1" || ! pkg_installed "$1"; }

# Fill gaps the removal left, and add what the kept apps are missing.
# Checks what's gone rather than only this run's picks, like _cleanup_fix_configs.
_cleanup_fill_gaps() {
  # Qalculate replaces Otter's calculator (the apps module does the same on later runs)
  if _cleanup_gone otter-calc; then flatpak_install io.github.Qalculate; fi
  # Nemo's "Extract here"/"Compress..." context menu entries (File Roller)
  if ! _cleanup_gone nemo; then apt_install nemo-fileroller; fi
}

# Point configs that used removed apps at what's left. Checks what's gone
# rather than only this run's picks, so a re-run also fixes configs left
# behind by an earlier removal. Every edit is a no-op once it's done.
_cleanup_fix_configs() {
  local keys="$HOME/.config/hypr/keybinds.lua" fm="$_CLEANUP_FM_KEEP" p
  local -A desktop=([nemo]=nemo.desktop [otter-files]=org.otter_shell.OtterFiles.desktop [nautilus]=org.gnome.Nautilus.desktop)
  local -a sed_args=()

  if _cleanup_gone otter-greeter && pkg_installed noctalia-greeter; then
    # Removing a display manager can relink the login screen; pin greetd again
    _noctalia_greeter_make_default
    if grep -qs otter-greeter "$HOME/restore-login-screen.sh"; then
      followup manual "$HOME/restore-login-screen.sh switches back to otter-greeter, which was removed: run 'sudo apt install otter-greeter' before using it."
    fi
  fi
  if _cleanup_gone otter-term && { is_dry || have ghostty; }; then _personal_use_ghostty; fi

  # File manager: default app and the SUPER+SHIFT+F bind (package name = command)
  if [[ -z "$fm" ]]; then
    for p in nemo otter-files nautilus; do
      if ! _cleanup_gone "$p"; then fm="$p"; break; fi
    done
  fi
  if [[ -n "$fm" ]]; then
    for p in nemo otter-files nautilus; do
      if [[ "$p" != "$fm" ]] && _cleanup_gone "$p"; then
        sed_args+=(-e "s/hl\.dsp\.exec_cmd(\"$p\")/hl.dsp.exec_cmd(\"$fm\")/")
      fi
    done
    if (( ${#sed_args[@]} )); then xdg_default "${desktop[$fm]}" inode/directory inode/mount-point; fi
  fi
  if [[ -n "$_CLEANUP_BROWSER_BIN" ]] && _cleanup_gone chromium; then
    sed_args+=(-e "s/hl\.dsp\.exec_cmd(\"chromium\")/hl.dsp.exec_cmd(\"$_CLEANUP_BROWSER_BIN\")/"
               -e "s/description = \"Chromium\"/description = \"$_CLEANUP_BROWSER_NAME\"/")
  fi
  if _cleanup_gone otter-logout; then
    sed_args+=(-e 's/hl\.dsp\.exec_cmd("otter-logout")/hl.dsp.exec_cmd("noctalia msg panel-toggle session")/')
  fi
  if (( ${#sed_args[@]} )) && [[ -f "$keys" ]]; then
    sed "${sed_args[@]}" "$keys" | write_file "$keys" 0644
  fi

  # PikaOS's portals.conf for Hyprland names Otter's portal (and stays behind,
  # since removal keeps config files); override it per user
  if _cleanup_gone otter-files && grep -qs '^default=otter' /etc/xdg/xdg-desktop-portal/hyprland-portals.conf; then
    write_file "$HOME/.config/xdg-desktop-portal/hyprland-portals.conf" 0644 < <(printf '[preferred]\ndefault=hyprland;gtk\n')
    if write_changed; then
      followup relogin "Log out and back in so apps use the Hyprland/GTK desktop portal (file pickers, screen sharing) instead of Otter's."
    fi
  fi
}

# Offer 'apt autoremove' for what the removal (or earlier ones) left unneeded.
_cleanup_autoremove() {
  local orphans
  local -a list=()
  if is_dry && (( ${#_CLEANUP_REMOVE[@]} )); then
    # Nothing was really removed, so simulate removal + autoremove together
    orphans="$(_cleanup_outside "$(_cleanup_apt_removes remove --autoremove "${_CLEANUP_REMOVE[@]}")" \
      "$(_cleanup_sim "${_CLEANUP_REMOVE[@]}")")"
  else
    orphans="$(_cleanup_apt_removes autoremove)"
  fi
  if [[ -z "$orphans" ]]; then info "Nothing left over for autoremove"; return 0; fi

  mapfile -t list < <(sort <<<"$orphans")
  warn "${#list[@]} packages aren't needed by anything any more:"
  printf '       - %s\n' "${list[@]}"
  if is_dry; then
    info "(dry run: would ask) Also remove these ${#list[@]} packages (apt autoremove)?"
    cmd "${APT_GET[*]} autoremove"
    return 0
  fi
  if ask_yes_no "Also remove these ${#list[@]} packages nothing needs any more (apt autoremove)?"; then
    run "${APT_GET[@]}" autoremove
  fi
}

cleanup_run() {
  if ! is_dry && ! has_tty; then module_skip "$_CLEANUP_NO_TTY"; fi
  info "Checking what each removal would take with it (apt simulation)..."
  _cleanup_greeter
  _cleanup_terminal
  _cleanup_file_manager
  _cleanup_otter_shell
  _cleanup_browser
  _cleanup_gnome
  _cleanup_remove
  _cleanup_fill_gaps
  _cleanup_fix_configs
  _cleanup_autoremove
}
