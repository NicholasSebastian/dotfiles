# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=webapps
MODULE_DESC="WhatsApp, Sonos, Day One, Gmail, Calendar, Figma, Canva, Excalidraw, Claude"
MODULE_DEFAULT=1
MODULE_DEPS=(browsers)                   # Exec= uses whichever browser is installed
}

# Launcher entry that opens a site as a Brave (or Chrome) app window.
# Sets WEBAPP_CHANGED=1 if the .desktop file was written.
WEBAPP_CHANGED=0
_webapps_make() {
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
  if write_changed; then WEBAPP_CHANGED=1; fi
}

webapps_run() {
  local webapps=(
    "WhatsApp|https://web.whatsapp.com"
    "Sonos|https://play.sonos.com"
    "Day One|https://dayone.me"
    "Gmail|https://mail.google.com"
    "Google Calendar|https://calendar.google.com"
    "Figma|https://www.figma.com/files"
    "Canva|https://www.canva.com"
    "Excalidraw|https://excalidraw.com"
    "Claude|https://claude.ai"
    # "Notion|https://www.notion.so"
  )
  local entry
  for entry in "${webapps[@]}"; do
    _webapps_make "${entry%%|*}" "${entry#*|}"
  done

  if (( WEBAPP_CHANGED )) && have update-desktop-database; then
    run update-desktop-database "$HOME/.local/share/applications"
  fi
}
