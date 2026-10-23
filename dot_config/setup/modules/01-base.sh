# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=base
MODULE_DESC="Core packages, Flatpak + Flathub, archive formats, firmware updates, rclone"
MODULE_DEFAULT=1
}

base_run() {
  local pkgs=(
    # essentials
    curl git ca-certificates gnupg jq fzf pciutils xdg-utils
    desktop-file-utils flatpak
    # archives (PikaOS ships File Roller; these are the formats it hands off to)
    7zip zip unzip unar zstd
    # system
    rsync plocate lm-sensors smartmontools gnome-disk-utility fwupd
    # cloud sync (Google Drive etc.); fuse3 is needed for 'rclone mount'
    rclone fuse3
    # media
    ffmpeg imagemagick
  )
  apt_install "${pkgs[@]}"
  flatpak_ensure_flathub
}
