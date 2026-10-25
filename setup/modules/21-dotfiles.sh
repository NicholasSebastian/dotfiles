# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=dotfiles
MODULE_DESC="Apply the chezmoi dotfiles, then finish Noctalia's colours in apps"
MODULE_DEFAULT=1
MODULE_DEPS=(noctalia)                   # the hypr config starts Noctalia instead of Otter's shell
}

# Applies the dotfiles from chezmoi's source directory (https://www.chezmoi.io/).
# On a new machine that directory is empty, so the repo ($DOTFILES_REPO in
# config.sh) is cloned into it first, like 'chezmoi init --apply' would.
# The repo always wins: every managed file that differs is overwritten, after
# a copy of it is kept as FILE.setup-bak.TS (like every other file setup changes).
#
# Then Noctalia's colour templates are made to reach every app. Most templates
# write a file the app (or the dotfiles) already loads; these apps also need a
# setting that picks the generated theme, set here when the app's settings
# file exists: Claude Code, Oh My Pi, Vesktop, darktable, OBS, Heroic.
# Templates for apps that haven't been opened yet stay unrendered until they
# have (Noctalia checks for their config folder), so the summary lists them.
# Runs after the app modules on purpose, so their settings files exist.

_DOTFILES_OPEN_ONCE=()                   # installed apps that need a first start

_dotfiles_flatpak() { flatpak info --system "$1" >/dev/null 2>&1; }
_dotfiles_flatpak_running() { flatpak ps --columns=application 2>/dev/null | grep -qx "$1"; }

# Write FILE's new content from stdin, keeping its permissions.
_dotfiles_rewrite() { write_file "$1" "$(stat -c %a "$1")"; }

# _dotfiles_json_ok FILE CHECK [jq args...]: CHECK (a jq filter) is true for FILE.
_dotfiles_json_ok() {
  local f="$1" check="$2"; shift 2
  jq -e "$@" "$check" "$f" >/dev/null 2>&1
}

# _dotfiles_json_write APP FILE FILTER [jq args...]: apply FILTER to FILE.
_dotfiles_json_write() {
  local app="$1" f="$2" filter="$3" out="$MODULE_TMP/settings.json"; shift 3
  # shellcheck disable=SC2034  # read by write_changed (core.sh)
  WRITE_CHANGED=0                        # write_changed is false if nothing gets written
  if ! jq "$@" "$filter" "$f" >"$out" 2>/dev/null; then
    soft_fail "$app: $f isn't valid JSON; Noctalia's theme not selected"
    return 0
  fi
  _dotfiles_rewrite "$f" <"$out"
}

# _dotfiles_ini_set FILE SECTION KEY VALUE [SEP]: print FILE with KEY SEP VALUE
# (SEP defaults to "=") in [SECTION]: replaced in place, or added as the last
# line of the section (before its trailing blank lines) or of the file. An
# existing "KEY = ..." line matches whatever its spacing.
_dotfiles_ini_set() {
  awk -v s="[$2]" -v k="$3" -v v="$4" -v sep="${5:-=}" '
    function emit() { print k sep v; done = 1 }
    function flush() { printf "%s", blank; blank = "" }
    { t = $0; sub(/^\357\273\277/, "", t) }          # OBS may start the file with a BOM
    t == s { insec = 1; print; next }
    insec && t ~ /^[ \t]*$/ { blank = blank $0 "\n"; next }
    t ~ /^\[/ { if (insec && !done) emit(); insec = 0 }
    { flush() }
    insec && substr(t, 1, length(k)) == k && substr(t, length(k) + 1) ~ /^[ \t]*=/ { if (!done) emit(); next }
    { print }
    END { if (!done) { if (!insec) { if (NR) print ""; print s }; emit() } flush() }' "$1"
}

_dotfiles_running_fail() {
  soft_fail "$1 is running: quit it, then re-run './setup.sh --only dotfiles' to select Noctalia's theme"
}

# --- chezmoi -----------------------------------------------------------------

_dotfiles_apply() {
  local src status line path modes=0
  apt_install chezmoi git
  if ! have chezmoi; then
    is_dry && module_skip "chezmoi isn't installed yet (dry run)"
    die "chezmoi didn't install"
  fi
  src="$(chezmoi source-path)"

  # Clone without --apply: the listing and backups below run first
  if [[ ! -d "$src" ]] || [[ -z "$(ls -A "$src")" ]]; then
    info "No dotfiles in $src yet; cloning $DOTFILES_REPO"
    run env GIT_TERMINAL_PROMPT=0 chezmoi init --no-tty "$DOTFILES_REPO" \
      || die "Couldn't clone $DOTFILES_REPO (check DOTFILES_REPO in config.sh and your network)"
    if is_dry; then info "(dry run: nothing to compare until the repo is cloned)"; return 0; fi
  fi
  info "Dotfiles source: $src"

  status="$(chezmoi status -p absolute)"
  if [[ -z "$status" ]]; then
    info "Dotfiles already applied"
    return 0
  fi

  # List what changes; files whose content gets replaced are backed up first.
  # Most entries usually differ only in permissions, so those are just counted.
  while IFS= read -r line; do
    path="${line:3}"
    if [[ "${line:1:1}" != M ]]; then
      printf '      %s\n' "$line"
    elif [[ -f "$path" && ! -L "$path" ]] && ! chezmoi cat "$path" | cmp -s - "$path"; then
      printf '      %s\n' "$line"
      backup_file "$path"
    else
      modes=$(( modes + 1 ))
    fi
  done <<<"$status"
  if (( modes )); then info "$modes more only get their permissions set"; fi

  run chezmoi apply --force --no-tty
}

# --- Noctalia colours in apps ------------------------------------------------

# Hook dependencies of the papirus-icons template (gawk's strtonum) and the
# brave one (Pillow for the system python3). PikaOS only has them today as
# dependencies of other packages.
_dotfiles_noctalia_deps() {
  apt_install gawk python3-pil
}

_dotfiles_claude() {
  local f="$HOME/.claude/settings.json"
  have claude || return 0
  if [[ ! -f "$f" ]]; then
    printf '{\n  "theme": "custom:noctalia"\n}\n' | write_file "$f" 0644
  elif _dotfiles_json_ok "$f" '.theme == "custom:noctalia"'; then
    info "Claude Code already uses Noctalia's theme"
  else
    _dotfiles_json_write "Claude Code" "$f" '.theme = "custom:noctalia"'
  fi
}

_dotfiles_omp() {
  local k
  have omp || return 0
  for k in theme.dark theme.light; do
    if [[ "$(omp config get "$k" 2>/dev/null || true)" == noctalia ]]; then
      info "Oh My Pi $k is already noctalia"
    else
      run omp config set "$k" noctalia || soft_fail "Oh My Pi: couldn't set $k to noctalia"
    fi
  done
}

# The apps module points Vesktop at ~/.config/vesktop; the sandbox folder is
# the fallback for when that move hasn't happened.
_dotfiles_vesktop() {
  local app=dev.vencord.Vesktop f="" c
  _dotfiles_flatpak "$app" || return 0
  for c in "$HOME/.config/vesktop/settings/settings.json" \
           "$HOME/.var/app/$app/config/vesktop/settings/settings.json"; do
    if [[ -f "$c" ]]; then f="$c"; break; fi
  done
  if [[ -z "$f" ]]; then _DOTFILES_OPEN_ONCE+=(Vesktop); return 0; fi
  if _dotfiles_json_ok "$f" '(.enabledThemes // []) | index("noctalia.theme.css") != null'; then
    info "Vesktop already uses Noctalia's theme"
  elif _dotfiles_flatpak_running "$app"; then
    _dotfiles_running_fail "Vesktop (also from the tray)"
  else
    _dotfiles_json_write Vesktop "$f" '.enabledThemes = ((.enabledThemes // []) + ["noctalia.theme.css"])'
  fi
}

_dotfiles_darktable() {
  local app=org.darktable.Darktable f
  f="$HOME/.var/app/$app/config/darktable/darktablerc"
  _dotfiles_flatpak "$app" || return 0
  if [[ ! -f "$f" ]]; then _DOTFILES_OPEN_ONCE+=(darktable); return 0; fi
  if grep -qx 'ui_last/theme=noctalia' "$f"; then
    info "darktable already uses Noctalia's theme"
  elif _dotfiles_flatpak_running "$app"; then
    _dotfiles_running_fail darktable
  else
    awk -v k=ui_last/theme -v v=noctalia '
      index($0, k "=") == 1 { if (!done) print k "=" v; done = 1; next }
      { print }
      END { if (!done) print k "=" v }' "$f" | _dotfiles_rewrite "$f"
  fi
}

# OBS 31+ keeps the theme in user.ini, older versions in global.ini.
_dotfiles_obs() {
  local app=com.obsproject.Studio d f theme=com.obsproject.matugen
  d="$HOME/.var/app/$app/config/obs-studio"
  _dotfiles_flatpak "$app" || return 0
  if [[ -f "$d/user.ini" ]]; then f="$d/user.ini"
  elif [[ -f "$d/global.ini" ]]; then f="$d/global.ini"
  else _DOTFILES_OPEN_ONCE+=(OBS); return 0
  fi
  if _dotfiles_ini_set "$f" Appearance Theme "$theme" | cmp -s - "$f"; then
    info "OBS already uses Noctalia's theme"
  elif _dotfiles_flatpak_running "$app"; then
    _dotfiles_running_fail OBS
  else
    _dotfiles_ini_set "$f" Appearance Theme "$theme" | _dotfiles_rewrite "$f"
  fi
}

# Heroic comes with PikaOS (pika-gameutils-meta). Its themes folder is a
# setting; the theme itself is picked in its UI (kept in its browser storage).
# shellcheck disable=SC2016  # $p is a jq variable
_dotfiles_heroic() {
  local f="$HOME/.config/heroic/config.json" p="$HOME/.config/heroic/themes"
  have heroic || return 0
  if [[ ! -f "$f" ]]; then _DOTFILES_OPEN_ONCE+=(Heroic); return 0; fi
  if _dotfiles_json_ok "$f" '.defaultSettings.customThemesPath == $p' --arg p "$p"; then
    info "Heroic already looks for themes in $p"
  elif pgrep -x heroic >/dev/null; then
    _dotfiles_running_fail Heroic
  elif ! _dotfiles_json_ok "$f" '.defaultSettings | type == "object"'; then
    soft_fail "Heroic: $f has no defaultSettings; set Settings -> Accessibility -> Custom Themes Path to $p by hand"
  else
    _dotfiles_json_write Heroic "$f" '.defaultSettings.customThemesPath = $p' --arg p "$p"
    if write_changed; then
      followup manual "Heroic: Settings -> Accessibility -> pick 'matugen.css' in the theme list (Noctalia's colours)."
    fi
  fi
}

# Brave's theme is an unpacked extension, which only Brave itself can load.
_dotfiles_brave() {
  local prof="$HOME/.config/BraveSoftware/Brave-Browser/Default" theme="$HOME/.local/share/noctalia/brave-theme"
  have brave-browser || return 0
  if [[ ! -f "$prof/Preferences" ]]; then _DOTFILES_OPEN_ONCE+=(Brave); return 0; fi
  if ! grep -qsF "$theme" "$prof/Preferences" "$prof/Secure Preferences"; then
    followup manual "Brave: brave://extensions -> Developer mode -> Load unpacked -> ~/.local/share/noctalia/brave-theme (Noctalia's colours; after palette changes press Update there)."
  fi
}

_dotfiles_noctalia_apps() {
  _dotfiles_claude
  _dotfiles_omp
  _dotfiles_vesktop
  _dotfiles_darktable
  _dotfiles_obs
  _dotfiles_heroic
  _dotfiles_brave

  # These templates need nothing selected, only the app's config folder
  if have blender && [[ ! -d "$HOME/.config/blender" ]]; then _DOTFILES_OPEN_ONCE+=(Blender); fi
  if _dotfiles_flatpak org.inkscape.Inkscape && [[ ! -d "$HOME/.var/app/org.inkscape.Inkscape" ]]; then
    _DOTFILES_OPEN_ONCE+=(Inkscape)
  fi
  if _dotfiles_flatpak org.gimp.GIMP && [[ ! -d "$HOME/.config/GIMP" ]]; then _DOTFILES_OPEN_ONCE+=(GIMP); fi

  if (( ${#_DOTFILES_OPEN_ONCE[@]} )); then
    followup manual "Noctalia colours: open ${_DOTFILES_OPEN_ONCE[*]} once and close them, then run './setup.sh --only dotfiles' to theme them."
  fi
}

_DOTFILES_SCHEME_DOTFILES_SCHEME=(wallpaper m3-tonal-spot)  # palette source and scheme: colours follow the wallpaper

# Noctalia keeps the palette choice in its state file (color-scheme-set writes
# it there, not to the dotfiles' settings.toml). With Noctalia running it's set
# through its IPC; otherwise the state file is edited, and read at next start.
_dotfiles_noctalia_scheme() {
  local state="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/settings.toml" cur
  if (( $1 )); then
    cur="$(noctalia msg color-scheme-get 2>/dev/null || true)"
    if [[ "$cur" == "${_DOTFILES_SCHEME_DOTFILES_SCHEME[*]}" ]]; then
      info "Noctalia already derives its colours from the wallpaper (${_DOTFILES_SCHEME_DOTFILES_SCHEME[1]})"
    else
      run noctalia msg color-scheme-set "${_DOTFILES_SCHEME_DOTFILES_SCHEME[@]}" \
        || soft_fail "Noctalia: couldn't switch to wallpaper colours; run 'noctalia msg color-scheme-set ${_DOTFILES_SCHEME_DOTFILES_SCHEME[*]}'"
    fi
    return 0
  fi
  if [[ ! -f "$state" ]]; then
    printf '[theme]\nsource = "%s"\nwallpaper_scheme = "%s"\n' "${_DOTFILES_SCHEME_DOTFILES_SCHEME[@]}" | write_file "$state" 0644
    return 0
  fi
  _dotfiles_ini_set "$state" theme source "\"${_DOTFILES_SCHEME_DOTFILES_SCHEME[0]}\"" ' = ' >"$MODULE_TMP/state.toml"
  _dotfiles_ini_set "$MODULE_TMP/state.toml" theme wallpaper_scheme "\"${_DOTFILES_SCHEME_DOTFILES_SCHEME[1]}\"" ' = ' \
    | _dotfiles_rewrite "$state"
}

# Render the templates now that settings.toml, the configs that load the
# generated files and the app settings above are all in place.
_dotfiles_noctalia_render() {
  local settings="$HOME/.config/noctalia/settings.toml" running=0
  need noctalia noctalia
  have noctalia || return 0               # dry run before the noctalia module installed it
  if is_dry; then settings="$(chezmoi source-path)/dot_config/noctalia/settings.toml"; fi
  if [[ -f "$settings" ]]; then             # missing only in a dry run before the clone
    noctalia config validate "$settings" \
      || soft_fail "Noctalia: $settings doesn't validate (see above); templates may not render"
  fi

  if noctalia msg theme-mode-get >/dev/null 2>&1; then running=1; fi
  _dotfiles_noctalia_scheme "$running"
  if (( ! running )); then
    followup relogin "Noctalia colours: after logging in, run 'noctalia msg templates-apply' once (Noctalia downloads its community templates on first start, so the first render misses them)."
    return 0
  fi
  if run noctalia msg config-reload && run noctalia msg templates-apply; then
    info "Noctalia re-rendered the colour templates"
  else
    soft_fail "Noctalia: re-rendering the colour templates failed; run 'noctalia msg templates-apply'"
  fi
}

dotfiles_run() {
  _dotfiles_apply
  _dotfiles_noctalia_deps
  _dotfiles_noctalia_apps
  _dotfiles_noctalia_render
}
