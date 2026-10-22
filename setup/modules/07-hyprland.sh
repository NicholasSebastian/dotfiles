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

# Point PikaOS's Hyprland config ($TERM/$TERMINAL, Nemo's "Open in Terminal")
# at Ghostty instead of otter-term. The cleanup module calls this again after
# removing otter-term. Files that don't exist are skipped.
_hyprland_use_ghostty() {
  local hypr="$HOME/.config/hypr" key=org.cinnamon.desktop.default-applications.terminal cur
  if [[ -f "$hypr/env.lua" ]]; then
    sed -e 's/^\([[:space:]]*hl\.env("TERM", \)"otter-term")/\1"xterm-ghostty")/' \
        -e 's/^\([[:space:]]*hl\.env("TERMINAL", \)"otter-term")/\1"ghostty")/' "$hypr/env.lua" \
      | write_file "$hypr/env.lua" 0644
  fi
  if [[ -f "$hypr/exec.lua" ]]; then
    sed 's/\(default-applications\.terminal exec \)otter-term"/\1ghostty"/' "$hypr/exec.lua" \
      | write_file "$hypr/exec.lua" 0644
  fi
  # The live setting too, so it applies before the next login
  if have gsettings && cur="$(gsettings get "$key" exec 2>/dev/null)" && [[ "$cur" != "'ghostty'" ]]; then
    run gsettings set "$key" exec ghostty
  fi
}

hyprland_run() {
  local pkgs=(
    imv                                    # image viewer (PikaOS sets none)
    pavucontrol                            # full audio mixer (per-app devices)
    playerctl                              # media keys
    wl-clipboard                           # wl-copy/wl-paste for the terminal and Neovim
    ghostty                                # terminal (SUPER+Return); made the default below
  )
  apt_install "${pkgs[@]}"

  # Make imv the image viewer (otherwise ImageMagick's 'display' opens images)
  if is_dry || [[ -f /usr/share/applications/imv.desktop ]]; then
    xdg_default imv.desktop image/png image/jpeg image/gif image/webp image/bmp image/tiff
  fi

  if is_dry || have ghostty; then _hyprland_use_ghostty; fi
}
