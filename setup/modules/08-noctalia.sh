# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=noctalia
MODULE_DESC="Switch the desktop shell to Noctalia + GTK/Qt theming"
MODULE_DEFAULT=1
MODULE_RISKY=1
}

# Switches Otter's shell to Noctalia; edits are diffed and luac-checked before writing.

_NOCTALIA_OTTER_EXEC='otter-(wallpaper|osd|notifications|polkit|idle|theme-gen|weather|search|clip|bar)'
_NOCTALIA_OTTER_KEYS='otter-(launcher|screenshot|shot|rec|transcribectl|overview|osd)'
_NOCTALIA_BLOCK_START='-- >>> pikaos-setup: noctalia >>>'
_NOCTALIA_BLOCK_END='-- <<< pikaos-setup: noctalia <<<'

# Comment out every statement starting with START (ERE) and containing TARGET; multi-line whole.
_noctalia_comment_out() {
  local start="$1" target="$2" file="$3"
  awk -v start="$start" -v target="$target" '
    function depth(s,    t, o) { t = s; o = gsub(/[(]/, "", t); return o - gsub(/[)]/, "", t) }
    function flush(comment,    k, i, parts) {
      k = split(buf, parts, "\n")
      for (i = 1; i <= k; i++) print ((comment && buf ~ target) ? "-- " parts[i] : parts[i])
      buf = ""
    }
    {
      if (buf == "") {
        if ($0 !~ start) { print; next }
        buf = $0; d = depth($0)
      } else {
        buf = buf "\n" $0; d += depth($0)
      }
      if (d <= 0) flush(1)
    }
    END { if (buf != "") flush(0) }
  ' "$file"
}

# Add hl.exec_cmd("noctalia") after the last Otter line in hyprland.start (runs once at login).
_noctalia_add_exec() {
  local file="$1"
  if grep -qE '^[[:space:]]*hl[.]exec_cmd[(]"noctalia"[)]' "$file"; then cat "$file"; return 0; fi
  awk '
    { line[NR] = $0 }
    END {
      s = 0; e = 0; last = 0
      for (i = 1; i <= NR; i++) if (line[i] ~ /^[[:space:]]*hl[.]on[(]"hyprland[.]start"/) { s = i; break }
      if (s) for (i = s + 1; i <= NR; i++) {
        if (line[i] ~ /^end[)]/) { e = i; break }
        if (line[i] ~ /^-- [[:space:]]*hl[.]exec_cmd[(]"otter-/) last = i
      }
      at = last ? last : (e ? e - 1 : 0)
      indent = ""
      if (at) { l = line[at]; sub(/^-- /, "", l); match(l, /^[[:space:]]*/); indent = substr(l, 1, RLENGTH) }
      for (i = 1; i <= NR; i++) {
        print line[i]
        if (i == at) print indent "hl.exec_cmd(\"noctalia\")    -- Noctalia shell (added by setup)"
      }
      if (!at) { print ""; print "-- Noctalia shell (added by setup)"; print "hl.exec_cmd(\"noctalia\")" }
    }' "$file"
}

# Replace (or add) the managed block at the end of a Lua file.
_noctalia_block() {
  strip_block "$1" "$_NOCTALIA_BLOCK_START" "$_NOCTALIA_BLOCK_END"
  printf '\n%s\n%s\n%s\n' "$_NOCTALIA_BLOCK_START" "$2" "$_NOCTALIA_BLOCK_END"
}

_NOCTALIA_KEYS_BODY='-- Noctalia keybinds (do...end keeps these locals from clashing with yours)
do
  local mainMod = "SUPER"
  local ipc = "noctalia msg "
  hl.bind(mainMod .. "+Space", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
  hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
  hl.bind(mainMod .. "+comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
  hl.bind("ALT + Tab", hl.dsp.exec_cmd(ipc .. "window-switcher"))
  hl.bind("PRINT", hl.dsp.exec_cmd(ipc .. "screenshot-region"))
  hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"), { locked = true, repeating = true })
  hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"), { locked = true, repeating = true })
  hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"), { locked = true })
  hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"), { locked = true, repeating = true })
  hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"), { locked = true, repeating = true })
end'

_NOCTALIA_WINDOWS_BODY='-- Noctalia blur
hl.layer_rule({
  name = "noctalia",
  match = {
    namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
  },
  no_anim = true,
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})
-- Noctalia Settings
hl.window_rule({
  match = { class = "dev.noctalia.Noctalia" },
  float = true,
  size = { 1080, 920 },
})'

_noctalia_switch() {
  local hypr="$HOME/.config/hypr"
  local exec_lua="$hypr/exec.lua" keys_lua="$hypr/keybinds.lua" win_lua="$hypr/windows.lua"
  local backup="$HOME/.config/hypr.otter-backup" f

  for f in "$exec_lua" "$keys_lua" "$win_lua"; do
    [[ -f "$f" ]] || module_skip "$f not found, so the config wasn't changed. Follow the wiki guide by hand."
  done

  # Config already starting Noctalia was switched before; only Otter leftovers get commented out.
  local switched=0
  if grep -qE '^[[:space:]]*hl[.]exec_cmd[(]"noctalia"[)]' "$exec_lua"; then switched=1; fi

  # Build the new versions
  local new="$MODULE_TMP/new"
  mkdir -p "$new"
  _noctalia_comment_out '^[[:space:]]*hl[.]exec_cmd[(]' "^[[:space:]]*hl[.]exec_cmd[(]\"${_NOCTALIA_OTTER_EXEC}[\" ]" "$exec_lua" >"$new/exec.tmp"
  _noctalia_add_exec "$new/exec.tmp" >"$new/exec.lua"
  _noctalia_comment_out '^[[:space:]]*hl[.]bind[(]' "exec_cmd[(]\"${_NOCTALIA_OTTER_KEYS}[\" ]" "$keys_lua" >"$new/keys.tmp"
  if (( switched )) && ! grep -qxF -e "$_NOCTALIA_BLOCK_START" "$keys_lua"; then
    cp "$new/keys.tmp" "$new/keybinds.lua"
  else
    _noctalia_block "$new/keys.tmp" "$_NOCTALIA_KEYS_BODY" >"$new/keybinds.lua"
  fi
  if (( switched )) && ! grep -qxF -e "$_NOCTALIA_BLOCK_START" "$win_lua"; then
    cp "$win_lua" "$new/windows.lua"
  else
    _noctalia_block "$win_lua" "$_NOCTALIA_WINDOWS_BODY" >"$new/windows.lua"
  fi

  local -a changed=()
  for f in exec.lua keybinds.lua windows.lua; do
    cmp -s "$new/$f" "$hypr/$f" || changed+=("$f")
  done
  if pkg_installed noctalia && (( ${#changed[@]} == 0 )); then
    info "Noctalia is installed and your Hyprland config is already switched"
    return 0
  fi

  for f in "${changed[@]}"; do
    printf '%s--- %s%s\n' "$C_DIM" "$f" "$C_RESET"
    show_diff "$hypr/$f" "$new/$f"
  done
  local relogin="Noctalia: log out and back in, then press Super+comma and turn on Security -> Authentication -> Polkit Agent and the idle/lock/suspend settings (Otter's were switched off). Control center is Super+Shift+S."
  local -a plan=(
    "install noctalia (and lua5.4, to syntax-check the edits)"
    "install the GTK/Qt theming Noctalia's templates need: nwg-look, qt6ct, adw-gtk3, Papirus icons"
  )
  if (( ${#changed[@]} )); then
    plan+=("edit ${changed[*]} in $hypr as shown above (Otter's shell stops starting at login)"
           "back up $hypr once to $backup, and each file to *.setup-bak.$TS")
  fi
  plan+=("take effect at your next login")
  confirm_risky "${plan[@]}"

  apt_install noctalia lua5.4               # the wiki's 'pikman install noctalia'
  is_dry || pkg_installed noctalia || die "noctalia didn't install, so your Hyprland config was left unchanged"
  if (( ${#changed[@]} == 0 )); then followup relogin "$relogin"; return 0; fi

  local luac
  luac="$(command -v luac5.4 || command -v luac || true)"
  if [[ -z "$luac" ]]; then
    if is_dry; then info "Would syntax-check the edited files with luac5.4"; else die "luac isn't available, so the edits can't be checked; nothing was changed"; fi
  else
    for f in "${changed[@]}"; do
      "$luac" -p "$new/$f" || die "$f would have a Lua syntax error after editing; nothing was changed"
    done
    info "Edited files pass luac -p"
  fi

  # One-time backup of the untouched Otter config (your undo); -L copies real files via symlinks.
  if [[ ! -e "$backup" ]]; then run cp -aL "$hypr" "$backup"; fi

  for f in "${changed[@]}"; do write_file "$hypr/$f" 0644 <"$new/$f"; done

  # Anything Otter-related still active that the edits couldn't match
  local leftovers
  leftovers="$(grep -nE "^[[:space:]]*hl[.](exec_cmd|bind).*\"(${_NOCTALIA_OTTER_EXEC}|${_NOCTALIA_OTTER_KEYS})[\" ]" \
               "$new/exec.lua" "$new/keybinds.lua" || true)"
  if [[ -n "$leftovers" ]]; then
    followup manual "Noctalia: these Otter lines are still active: ${leftovers//$'\n'/; }"
  fi
  if grep -qE '^[[:space:]]*hl[.]exec_cmd[(]"otter-(dock|taskbar)' "$new/exec.lua"; then
    followup manual "Noctalia: exec.lua still starts otter-dock/otter-taskbar (the wiki leaves them on). Comment them out if you see two docks."
  fi

  followup relogin "$relogin"
  followup manual "Noctalia undo: restore ~/.config/hypr/*.setup-bak.$TS, or: rm -rf ~/.config/hypr && cp -a $backup ~/.config/hypr"
}

# For Noctalia's "GTK and Qt Applications" template; Qt6 platform theme is qt6ct (PikaOS env.lua).
_noctalia_theming() {
  local pkgs=(
    nwg-look                               # GTK settings: theme, icons, cursor, font
    papirus-icon-theme                     # icon theme
  )
  apt_install "${pkgs[@]}"

  # adw-gtk3 (libadwaita look for GTK3): apt adw-gtk3-theme if packaged, else sha256-checked build.
  local themes="$HOME/.local/share/themes"
  if [[ -d /usr/share/themes/adw-gtk3 || -d "$themes/adw-gtk3" ]]; then
    info "adw-gtk3 theme already installed"
  elif apt_available adw-gtk3-theme; then
    apt_install adw-gtk3-theme
  else
    local tarball="$MODULE_TMP/adw-gtk3.tar.xz"
    if gh_download_latest lassekongo83/adw-gtk3 '\.tar\.xz$' "$tarball"; then
      run mkdir -p "$themes"
      run tar -xJf "$tarball" -C "$themes"
    else
      soft_fail "adw-gtk3: not in apt and the GitHub release couldn't be fetched"
    fi
  fi

  # Qt: prefer the KDE-patched qt6ct (reads KDE colour schemes; Krita/Kdenlive follow), else qt6ct.
  if apt_available qt6ct-kde; then
    apt_install qt6ct-kde
  elif pkg_installed qt6ct; then
    info "qt6ct already installed (qt6ct-kde isn't packaged)"
  else
    apt_install qt6ct
    followup manual "qt6ct-kde isn't in your apt repos, so plain qt6ct was installed. KDE apps like Krita and Kdenlive may not fully follow your colour scheme."
  fi

  # Same GTK theme for Flatpak apps
  flatpak_install org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark
  # Let Flatpak GTK apps read ~/.config/gtk-3.0 and gtk-4.0 so Noctalia's noctalia.css applies.
  local fs
  fs="$(flatpak_overrides filesystems)"
  if [[ "$fs" == *";xdg-config/gtk-3.0:ro;"* && "$fs" == *";xdg-config/gtk-4.0:ro;"* ]]; then
    info "Flatpak apps already read ~/.config/gtk-3.0 and gtk-4.0"
  else
    run flatpak override --user --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro
  fi
}

# Theming runs only after the switch went through; a skipped/declined switch exits the module.
noctalia_run() {
  _noctalia_switch
  _noctalia_theming
}
