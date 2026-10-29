# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=apps
MODULE_DESC="Brave + Chrome, Bitwarden, Obsidian, LocalSend, Discord, Telegram, Spotify, Affinity, ArtCraft, Cloudflare WARP, etc."
MODULE_DEFAULT=1
}

# --- Browsers ----------------------------------------------------------------

_apps_browsers() {
  # Brave's script adds its signed apt repo and installs brave-browser
  if have brave-browser; then info "Brave already installed"; else install_script https://dl.brave.com/install.sh sh || soft_fail "Brave's install script failed; see https://brave.com/linux"; fi

  # Chrome's .deb adds Google's apt repo for updates. Google publishes no
  # checksum for the 'current' .deb; it's fetched over TLS.
  if have google-chrome-stable; then
    info "Google Chrome already installed"
  else
    local deb="$MODULE_TMP/google-chrome-stable_current_amd64.deb"
    if download https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb "$deb"; then
      apt_install "$deb"
    else
      soft_fail "Google Chrome download failed; get it from https://www.google.com/chrome"
    fi
  fi
}

# --- Desktop apps ------------------------------------------------------------

# Comfy, the Spicetify theme Noctalia's spicetify template colours: the
# template writes Themes/Comfy/color.ini, and config-xpui.ini (dotfiles)
# selects Comfy. Comfy's own color.ini is skipped so it never replaces
# Noctalia's.
_apps_spicetify_comfy() {
  local themes="${XDG_CONFIG_HOME:-$HOME/.config}/spicetify/Themes" repo="$MODULE_TMP/comfy"
  if [[ -f "$themes/Comfy/user.css" ]]; then
    info "Spicetify Comfy theme already installed"
    return 0
  fi
  if ! run git clone --depth 1 https://github.com/Comfy-Themes/Spicetify.git "$repo"; then
    soft_fail "Spicetify: couldn't clone the Comfy theme (Noctalia's Spotify colours need it); re-run './setup.sh --only apps'"
    return 0
  fi
  run mkdir -p "$themes/Comfy"
  run cp -rn "$repo/Comfy/." "$themes/Comfy/"
}

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
  _apps_spicetify_comfy
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

# Vesktop reads its config from ~/.config/vesktop (where dotfiles can manage
# it) instead of the Flatpak's own ~/.var/app/dev.vencord.Vesktop/config/
# vesktop: the xdg-config/vesktop permission mounts the host folder over
# that path inside the sandbox. The first time, the existing Flatpak config
# (settings, themes, login session) moves to ~/.config/vesktop; if that
# already exists it wins, and the Flatpak copy is renamed aside.
_apps_vesktop_config() {
  local app=dev.vencord.Vesktop host="${XDG_CONFIG_HOME:-$HOME/.config}/vesktop"
  local old="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop" fs
  if ! is_dry && ! flatpak_installed "$app"; then return 0; fi
  fs="$(flatpak_overrides filesystems "$app")"
  if [[ "$fs" == *";xdg-config/vesktop;"* || "$fs" == *";xdg-config/vesktop:"* ]]; then
    info "Vesktop already reads its config from $host"
    return 0
  fi

  if [[ -d "$old" && -n "$(ls -A "$old" 2>/dev/null)" ]]; then
    # Moving it under a running Vesktop would break its open session files
    if ! is_dry && flatpak_running "$app"; then
      soft_fail "Vesktop is running: quit it (also from the tray), then re-run './setup.sh --only apps' to move its config to $host"
      return 0
    fi
    if [[ -e "$host" ]]; then
      run mv "$old" "$old.setup-bak.$TS"
    else
      run mkdir -p "${host%/*}"
      run mv "$old" "$host"
    fi
  fi
  run mkdir -p "$host"
  run flatpak override --user --filesystem=xdg-config/vesktop:create "$app"
}

# Run Vesktop natively on Wayland: as a Flatpak it falls back to X11
# (XWayland) whenever it's allowed to, so take its X11 access away, as
# https://vesktop.dev/wiki/linux/tips/#wayland-support says (Flatseal's
# "X11 windowing system" switch does the same). Per-user override, so it
# survives Flatpak updates.
_apps_vesktop_wayland() {
  if ! is_dry && ! flatpak_installed dev.vencord.Vesktop; then return 0; fi
  local sockets
  sockets="$(flatpak_overrides sockets dev.vencord.Vesktop)"
  if [[ "$sockets" == *";!x11;"* && "$sockets" == *";!fallback-x11;"* ]]; then
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
  if flatpak_installed com.discordapp.Discord || have discord; then has_discord=1; fi

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
    if ! have_icon discord; then
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

# Qalculate replaces Otter's calculator once otter-calc is gone (the cleanup
# module offers to remove it, and installs Qalculate itself when it does).
_apps_calculator() {
  if pkg_installed otter-calc; then
    info "Otter's calculator (otter-calc) is installed; Qalculate not added"
    return 0
  fi
  flatpak_install io.github.Qalculate
}

_apps_desktop() {
  # (No video player: PikaOS ships mpv. Calculator: see _apps_calculator.)
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

    # Video
    fr.handbrake.ghb                       # video transcoding

    # System
    com.usebottles.bottles                 # Windows apps, each in its own Wine "bottle"
    com.github.tchx84.Flatseal             # manage Flatpak permissions
    it.mijorus.gearlever                   # manage AppImages (Affinity etc.)
  )
  flatpak_install "${apps[@]}"
  _apps_calculator
  # LocalSend receives on port 53317 (TCP + UDP). With ufw on "deny incoming"
  # it can send but never receive. ufw stores rules even while disabled, and
  # adding an existing rule is a no-op.
  if is_dry || have ufw || [[ -x /usr/sbin/ufw ]]; then
    run sudo ufw allow 53317 comment 'LocalSend'
  fi
  _apps_spicetify
  _apps_vesktop_as_discord
  _apps_vesktop_config
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
    com.obsproject.Studio                  # screen recording and streaming
    org.gimp.GIMP
    org.kde.krita
    org.inkscape.Inkscape
    org.darktable.Darktable                # RAW photo editing (product shots)
    org.kde.kdenlive
  )
  flatpak_install "${apps[@]}"

  # ArtCraft's Crafting Apps (open source, pure Rust, early alpha): the
  # ArtCraft Launcher installs them and keeps them updated. It isn't on
  # Flathub or in apt, so its .deb comes from the latest GitHub release.
  # https://getartcraft.com/apps
  if pkg_installed artcraft-launcher; then
    info "ArtCraft Launcher already installed"
  else
    local acl="$MODULE_TMP/artcraft-launcher.deb"
    if gh_download_latest storytold/craft-launcher '-linux-x86_64\.deb$' "$acl"; then
      apt_install "$acl"
      followup manual "ArtCraft Launcher: open it and install PhotoCraft, VectorCraft, FilmCraft and LightCraft (it keeps them updated)."
    else
      soft_fail "ArtCraft Launcher: couldn't download the .deb from the latest storytold/craft-launcher release"
    fi
  fi

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

# --- Network -----------------------------------------------------------------

# Cloudflare WARP (1.1.1.1 VPN / DNS client) from Cloudflare's apt repo.
# PikaOS is Debian sid (codename 'nest'), which that repo doesn't publish, so
# Cloudflare's own instructions ($(lsb_release -cs)) break 'apt update'; this
# uses Debian 13 'trixie', the newest Debian suite it has. The key and list go
# where those instructions put them (so a hand-added 'nest' list is replaced):
# the package's postinst nags about the key if that keyring is missing or old.
_APPS_WARP_KEY_FPR="C068A2B5771775193CBE1F2F6E2DD2174FA1C3BA"   # RPM's gpg-pubkey(4fa1c3ba-61abda35)
_APPS_WARP_KEYRING=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
_apps_warp() {
  local key="$MODULE_TMP/cloudflare-warp.asc" changed=0
  if is_dry; then
    cmd "download https://pkg.cloudflareclient.com/pubkey.gpg, check key fingerprint $_APPS_WARP_KEY_FPR -> $_APPS_WARP_KEYRING"
  elif download https://pkg.cloudflareclient.com/pubkey.gpg "$key"; then
    install_keyring cloudflare-warp "$key" "$_APPS_WARP_KEY_FPR" "$_APPS_WARP_KEYRING"
    if write_changed; then changed=1; fi
  else
    soft_fail "Cloudflare WARP: couldn't download Cloudflare's repo key; see https://pkg.cloudflareclient.com"
    return 0
  fi
  printf 'deb [signed-by=%s] https://pkg.cloudflareclient.com/ trixie main\n' "$_APPS_WARP_KEYRING" \
    | write_file /etc/apt/sources.list.d/cloudflare-client.list
  if write_changed; then changed=1; fi
  if (( changed )); then apt_update; fi

  if pkg_installed cloudflare-warp; then
    info "Cloudflare WARP already installed"
    return 0
  fi
  if is_dry && ! apt_available cloudflare-warp; then
    cmd "apt-get install cloudflare-warp (from Cloudflare's repo)"
  else
    apt_install cloudflare-warp
  fi
  followup manual "Cloudflare WARP: run 'warp-cli registration new', then 'warp-cli connect'."
}

# --- Web apps ----------------------------------------------------------------

# Icon for a web app: ICON is either a name from the icon themes (Papirus,
# from the noctalia module, has many brands) or the https URL of a PNG, which
# is downloaded once to $_APPS_WEBAPP_ICONS/SLUG-<url hash>.png (a new URL means a new file). Prints the Icon= value
# (everything else goes to stderr); the generic browser icon if neither works out.
_APPS_WEBAPP_ICONS="${XDG_DATA_HOME:-$HOME/.local/share}/webapp-icons"
_apps_webapp_icon() {
  local slug="$1" icon="$2" dest
  if [[ "$icon" != https://* ]]; then
    if is_dry || have_icon "$icon"; then
      printf '%s\n' "$icon"
    else
      soft_fail "Web app icon '$icon' isn't in your icon themes (Papirus has it; the noctalia module installs it)" >&2
      printf 'web-browser\n'
    fi
    return 0
  fi
  dest="$_APPS_WEBAPP_ICONS/$slug-$(printf '%s' "$icon" | sha256sum | cut -c1-12).png"
  if [[ -s "$dest" ]] || download "$icon" "$dest" >&2; then
    printf '%s\n' "$dest"
  else
    soft_fail "Web app icon for $slug couldn't be downloaded from $icon" >&2
    printf 'web-browser\n'
  fi
}

# Launcher entry that opens a site as a Brave (or Chrome) app window.
_apps_webapp() {
  local name="$1" url="$2" icon="$3"
  local slug file browser="brave-browser" prefix="brave"
  slug="$(tr '[:upper:] ' '[:lower:]-' <<<"$name")"
  file="$HOME/.local/share/applications/webapp-$slug.desktop"
  if ! have brave-browser && have google-chrome-stable; then
    browser="google-chrome-stable"; prefix="chrome"
  fi
  icon="$(_apps_webapp_icon "$slug" "$icon")"

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
Icon=$icon
Terminal=false
Categories=Network;WebApp;
EOF
}

_apps_webapps() {
  # Name|URL|icon: a Papirus icon name where Papirus has the brand, else the
  # site's own app icon (or dashboard-icons' copy of it) as a PNG URL.
  local dash=https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png
  local webapps=(
    "WhatsApp|https://web.whatsapp.com|whatsapp"
    "Gmail|https://mail.google.com|gmail"
    "Google Calendar|https://calendar.google.com|$dash/google-calendar.png"
    "Claude|https://claude.ai|$dash/claude-ai.png"
    "ChatGPT|https://chatgpt.com|$dash/chatgpt.png"
    "Perplexity|https://www.perplexity.ai|https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/perplexity.png"
    "Excalidraw|https://excalidraw.com|excalidraw"
    "Figma|https://www.figma.com/files|figma"
    "Canva|https://www.canva.com|https://static.canva.com/static/images/apple-touch-180x180-1.png"
    "CapCut|https://www.capcut.com/editor|https://sf16-web-tos-buz.capcutcdn-us.com/obj/capcut-web-buz-tx/pwa/512.png"
    "Day One|https://dayone.me|https://dayone.me/favicons/android-icon-192x192.png"
    "Sonos|https://play.sonos.com|https://play.sonos.com/assets/logo512x512.png"
  )
  local entry name url icon changed=0
  for entry in "${webapps[@]}"; do
    IFS='|' read -r name url icon <<<"$entry"
    _apps_webapp "$name" "$url" "$icon"
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
  _apps_warp                             # last: a key fingerprint mismatch stops the module
}
