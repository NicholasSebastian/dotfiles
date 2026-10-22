# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=theming
MODULE_DESC="What Noctalia needs to theme GTK/Qt apps (nwg-look, qt6ct, adw-gtk3) + Papirus icons"
MODULE_DEFAULT=1
MODULE_DEPS=(noctalia)
}

# What Noctalia's "GTK and Qt Applications" template needs to colour your
# apps from its palette (no Kvantum: Noctalia generates the Qt colours).
# QT_QPA_PLATFORMTHEME=qt6ct is already set in PikaOS's hypr/env.lua.
theming_run() {
  local pkgs=(
    nwg-look                               # GTK settings: theme, icons, cursor, font
    papirus-icon-theme                     # icon theme
  )
  apt_install "${pkgs[@]}"

  # adw-gtk3: libadwaita look for GTK3 apps. From apt if packaged (Debian and
  # PikaOS call it adw-gtk3-theme), otherwise the official release (.tar.xz,
  # sha256-checked) into ~/.local/share/themes.
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

  # Qt settings. The KDE-patched qt6ct reads KDE colour schemes, so KDE apps
  # (Krita, Kdenlive) follow the colour scheme too. Plain qt6ct otherwise.
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
}
