# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=creative
MODULE_DESC="GIMP, Krita, Inkscape, Darktable, Kdenlive, Affinity (AppImage)"
MODULE_DEFAULT=1
}

creative_run() {
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
  local appimage="$APPS_DIR/Affinity.AppImage"
  apt_install libfuse2t64
  if [[ -f "$appimage" ]]; then
    info "Affinity AppImage already at $appimage"
  elif gh_download_latest ryzendew/Linux-Affinity-Installer '\.AppImage$' "$appimage"; then
    run chmod +x "$appimage"
    followup manual "Open $appimage with Gear Lever to add it to your launcher, then sign in with your Canva account."
  else
    soft_fail "Affinity: couldn't get the AppImage from the latest ryzendew/Linux-Affinity-Installer release"
  fi

  followup manual "DaVinci Resolve needs a manual download from blackmagicdesign.com (Linux .run installer)."
}
