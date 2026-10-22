# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=hyprland
MODULE_DESC="What Otter/PikaOS don't ship: image viewer, audio mixer, media keys, clipboard CLI"
MODULE_DEFAULT=1
}

# Only what PikaOS's Otter desktop doesn't already ship. Otter provides the
# file manager (otter-files), screenshots (otter-shot), colour picker
# (otter-pick), lock screen, idle, night light, notifications, OSD, polkit
# agent and calculator, and PikaOS ships Papers (PDFs), File Roller (archives)
# and mpv (video). Ghostty is the terminal.

hyprland_run() {
  local pkgs=(
    imv                                    # image viewer (PikaOS sets none)
    pavucontrol                            # full audio mixer (per-app devices)
    playerctl                              # media keys
    wl-clipboard                           # wl-copy/wl-paste for the terminal and Neovim
    ghostty                                # terminal (the personal module makes it the default)
  )
  apt_install "${pkgs[@]}"
}
