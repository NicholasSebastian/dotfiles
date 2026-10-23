# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=apps
MODULE_DESC="Brave + Chrome, Bitwarden, Obsidian, LocalSend, Discord, Telegram, Spotify, Affinity, etc."
MODULE_DEFAULT=1
}

# --- Browsers ----------------------------------------------------------------

_apps_browsers() {
  # Brave's script adds its signed apt repo and installs brave-browser
  if have brave-browser; then info "Brave already installed"; else install_script https://dl.brave.com/install.sh sh; fi

  # Chrome's .deb adds Google's apt repo for updates. Google publishes no
  # checksum for the 'current' .deb; it's fetched over TLS.
  if have google-chrome-stable; then
    info "Google Chrome already installed"
  else
    local deb="$MODULE_TMP/google-chrome-stable_current_amd64.deb"
    download https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb "$deb"
    apt_install "$deb"
  fi
}

# --- Desktop apps ------------------------------------------------------------

# Spicetify (themes/extensions for Spotify), patched into the Flatpak's files
# as its docs describe: that folder is root-owned, so it's made writable
# first. It needs Spotify's prefs file, which appears once you've opened
# Spotify and logged in. A Spotify update replaces the patched files, so
# re-run this module afterwards.
_apps_spicetify() {
  local spotify=/var/lib/flatpak/app/com.spotify.Client/current/active/files/extra/share/spotify
  local prefs="$HOME/.var/app/com.spotify.Client/config/spotify/prefs"
  if ! is_dry && [[ ! -d "$spotify" ]]; then
    soft_fail "Spotify's Flatpak files aren't in $spotify; Spicetify not installed"
    return 0
  fi
  mise_use github:spicetify/cli
  if [[ -d "$spotify/Apps/xpui" ]]; then
    info "Spicetify is already applied to Spotify"
    return 0
  fi
  if ! is_dry && [[ ! -f "$prefs" ]]; then
    followup manual "Spicetify: open Spotify once and log in, then run './setup.sh --only apps' to apply it."
    return 0
  fi
  run spicetify config spotify_path "$spotify" prefs_path "$prefs"
  run sudo chmod a+wr "$spotify"
  run sudo chmod -R a+wr "$spotify/Apps"
  run spicetify --no-restart backup apply
  followup manual "Spicetify: restart Spotify to see it. After a Spotify update, run 'spicetify backup apply' (or re-run './setup.sh --only apps')."
}

# Run Vesktop natively on Wayland: as a Flatpak it falls back to X11
# (XWayland) whenever it's allowed to, so take its X11 access away, as
# https://vesktop.dev/wiki/linux/tips/#wayland-support says (Flatseal's
# "X11 windowing system" switch does the same). Per-user override, so it
# survives Flatpak updates.
_apps_vesktop_wayland() {
  if ! is_dry && ! flatpak info dev.vencord.Vesktop >/dev/null 2>&1; then return 0; fi
  local sockets
  sockets="$(flatpak override --user --show dev.vencord.Vesktop 2>/dev/null | sed -n 's/^sockets=//p')"
  if [[ ";$sockets" == *";!x11;"* && ";$sockets" == *";!fallback-x11;"* ]]; then
    info "Vesktop already runs on Wayland only"
  else
    run flatpak override --user --nosocket=x11 --nosocket=fallback-x11 dev.vencord.Vesktop
  fi
}

# Show Vesktop as "Discord" (name + Discord's icon) when the real Discord
# isn't installed. The override goes in ~/.local/share/applications, which
# shadows the Flatpak's own entry and survives Flatpak updates; it's rebuilt
# from the Flatpak's entry each run so Exec= stays current, and removed again
# once Discord itself is installed.
_apps_vesktop_as_discord() {
  local src=/var/lib/flatpak/exports/share/applications/dev.vencord.Vesktop.desktop
  local dest="$HOME/.local/share/applications/dev.vencord.Vesktop.desktop"
  local marker="# pikaos-setup: Vesktop shown as Discord"
  local changed=0 icon=discord tmp="$MODULE_TMP/vesktop.desktop" has_discord=0
  if flatpak info --system com.discordapp.Discord >/dev/null 2>&1 || have discord; then has_discord=1; fi

  if (( has_discord )) || [[ ! -f "$src" ]]; then
    # Discord itself is installed, or Vesktop isn't (left out, or its install
    # failure was already reported): drop an override we made earlier
    if [[ -f "$dest" && "$(head -n1 "$dest")" == "$marker" ]]; then
      run rm -f "$dest"
      changed=1
    elif (( ! has_discord )); then
      info "Vesktop isn't installed; not showing it as Discord"
    fi
  else
    if [[ -z "$(find /usr/share/icons "$HOME/.local/share/icons" -path '*/apps/discord.*' -print -quit 2>/dev/null)" ]]; then
      icon=dev.vencord.Vesktop
      followup manual "Vesktop is shown as Discord but kept its own icon: no 'discord' icon in your icon themes (Papirus has one; the noctalia module installs it)."
    fi
    { printf '%s\n' "$marker"
      sed -e 's/^Name=.*/Name=Discord/' -e "s/^Icon=.*/Icon=$icon/" "$src"
    } >"$tmp"
    # Redirected, not piped: write_file must run in this shell for write_changed
    write_file "$dest" 0644 <"$tmp"
    if write_changed; then changed=1; fi
  fi

  if (( changed )) && have update-desktop-database; then
    run update-desktop-database "$HOME/.local/share/applications"
  fi
}

_apps_desktop() {
  # (No calculator or video player: Otter ships otter-calc, PikaOS ships mpv.)
  apt_install qbittorrent

  local apps=(
    # Productivity
    com.bitwarden.desktop
    md.obsidian.Obsidian
    net.ankiweb.Anki                       # flashcards
    org.onlyoffice.desktopeditors
    org.localsend.localsend_app

    # Chat
    org.telegram.desktop
    dev.vencord.Vesktop                    # Discord with Vencord + working Wayland screen share
    # com.discordapp.Discord               # official client

    # Audio
    com.spotify.Client
    com.github.wwmm.easyeffects            # mic noise suppression + EQ (replaces rnnoise/JamesDSP)

    # System
    com.usebottles.bottles                 # Windows apps, each in its own Wine "bottle"
    com.github.tchx84.Flatseal             # manage Flatpak permissions
    it.mijorus.gearlever                   # manage AppImages (Affinity etc.)
  )
  flatpak_install "${apps[@]}"
  # LocalSend receives on port 53317 (TCP + UDP). With ufw on "deny incoming"
  # it can send but never receive. ufw stores rules even while disabled, and
  # adding an existing rule is a no-op.
  if is_dry || have ufw || [[ -x /usr/sbin/ufw ]]; then
    run sudo ufw allow 53317 comment 'LocalSend'
  fi
  _apps_spicetify
  _apps_vesktop_as_discord
  _apps_vesktop_wayland
}

# --- Creative ----------------------------------------------------------------

# Path of an AppImage Gear Lever has integrated, by its X-AppImage-Name.
# Gear Lever moves the file into its own folder (~/AppImages by default,
# renamed) and writes a launcher entry whose TryExec points at it.
_apps_gearlever_appimage() {
  local name="$1" f exe
  for f in "$HOME"/.local/share/applications/*.desktop; do
    if [[ ! -f "$f" ]] || ! grep -qxF "X-AppImage-Name=$name" "$f"; then continue; fi
    exe="$(sed -n '/^TryExec=/{s///p;q}' "$f")"
    if [[ -n "$exe" && -f "$exe" ]]; then printf '%s\n' "$exe"; return 0; fi
  done
  return 1
}

_apps_creative() {
  local apps=(
    org.gimp.GIMP
    org.kde.krita
    org.inkscape.Inkscape
    org.darktable.Darktable                # RAW photo editing (product shots)
    org.kde.kdenlive
  )
  flatpak_install "${apps[@]}"

  # Affinity: community AppImage (AffinityOnLinux, not affiliated with Serif)
  # with its own Wine setup. AppImages need FUSE 2.
  local appimage="$APPS_DIR/Affinity.AppImage" integrated
  apt_install libfuse2t64
  if integrated="$(_apps_gearlever_appimage Affinity)"; then
    info "Affinity already installed with Gear Lever at $integrated"
  elif [[ -f "$appimage" ]]; then
    info "Affinity AppImage already at $appimage"
  elif gh_download_latest ryzendew/Linux-Affinity-Installer '\.AppImage$' "$appimage"; then
    run chmod +x "$appimage"
    followup manual "Open $appimage with Gear Lever to add it to your launcher, then sign in with your Canva account."
  else
    soft_fail "Affinity: couldn't get the AppImage from the latest ryzendew/Linux-Affinity-Installer release"
  fi

  followup manual "DaVinci Resolve needs a manual download from blackmagicdesign.com (Linux .run installer)."
}

# --- Web apps ----------------------------------------------------------------

# Launcher entry that opens a site as a Brave (or Chrome) app window.
_apps_webapp() {
  local name="$1" url="$2"
  local slug file browser="brave-browser" prefix="brave"
  slug="$(tr '[:upper:] ' '[:lower:]-' <<<"$name")"
  file="$HOME/.local/share/applications/webapp-$slug.desktop"
  if ! have brave-browser && have google-chrome-stable; then
    browser="google-chrome-stable"; prefix="chrome"
  fi

  # Chromium names --app windows "<browser>-<host>__<path>-Default". Matching
  # it lets the dock/taskbar group each web app separately instead of
  # lumping them all under the browser.
  local rest="${url#*://}" host path
  host="${rest%%/*}"
  path="${rest#"$host"}"; path="${path#/}"; path="${path//\//_}"

  write_file "$file" 0644 <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Comment=$name web app
Exec=$browser --app=$url
StartupWMClass=$prefix-${host}__${path}-Default
Icon=web-browser
Terminal=false
Categories=Network;WebApp;
EOF
}

_apps_webapps() {
  local webapps=(
    "WhatsApp|https://web.whatsapp.com"
    "Gmail|https://mail.google.com"
    "Google Calendar|https://calendar.google.com"
    "Claude|https://claude.ai"
    "Excalidraw|https://excalidraw.com"
    "Figma|https://www.figma.com/files"
    "Canva|https://www.canva.com"
    "Day One|https://dayone.me"
    "Sonos|https://play.sonos.com"
  )
  local entry changed=0
  for entry in "${webapps[@]}"; do
    _apps_webapp "${entry%%|*}" "${entry#*|}"
    if write_changed; then changed=1; fi
  done

  if (( changed )) && have update-desktop-database; then
    run update-desktop-database "$HOME/.local/share/applications"
  fi
}

apps_run() {
  _apps_browsers
  _apps_desktop
  _apps_creative
  _apps_webapps                          # Exec= uses whichever browser is installed
}
