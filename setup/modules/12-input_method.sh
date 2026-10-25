# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=input_method
MODULE_DESC="Fcitx5 for typing Chinese/Japanese (pick languages inside)"
MODULE_DEFAULT=0
}

input_method_run() {
  local pkgs=(
    fcitx5 fcitx5-config-qt
    fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5 fcitx5-frontend-qt6
    # fcitx5-chinese-addons                # Pinyin and other Chinese input
    # fcitx5-mozc                          # Japanese
    # fcitx5-hangul                        # Korean
  )
  apt_install "${pkgs[@]}"

  if ! grep -qs 'fcitx5' "$HOME/.config/hypr/exec.lua"; then
    followup manual "Fcitx5: add 'hl.exec_cmd(\"fcitx5 -d\")' inside the hl.on(\"hyprland.start\", ...) block of exec.lua in your dotfiles ('chezmoi edit ~/.config/hypr/exec.lua', then 'chezmoi apply'; direct edits are overwritten by the dotfiles module), then add your input methods in fcitx5-configtool."
  fi
}
