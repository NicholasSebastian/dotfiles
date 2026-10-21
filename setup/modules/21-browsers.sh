# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=browsers
MODULE_DESC="Brave (default browser) + Google Chrome"
MODULE_DEFAULT=1
}

browsers_run() {
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

  # xdg-mime writes ~/.config/mimeapps.list directly. (xdg-settings needs a
  # recognised desktop environment and often fails under Hyprland.)
  xdg_default brave-browser.desktop \
    x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml
}
