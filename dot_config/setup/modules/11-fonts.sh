# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=fonts
MODULE_DESC="JetBrains Mono + Iosevka Nerd Fonts, Noto, emoji, CJK, Microsoft core fonts"
MODULE_DEFAULT=1
}

fonts_run() {
  apt_install fonts-noto-core fonts-noto-color-emoji fonts-noto-cjk

  # Microsoft core fonts (Arial, Times New Roman...). Needs the contrib repo.
  if pkg_installed ttf-mscorefonts-installer; then
    info "Microsoft core fonts already installed"
  elif apt_available ttf-mscorefonts-installer; then
    debconf_preseed 'ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true'
    apt_install ttf-mscorefonts-installer
  else
    warn "ttf-mscorefonts-installer not available (contrib repo off?), skipping"
  fi

  # Nerd Fonts, from the latest release with GitHub's sha256. Checks for font
  # files, not just the folder, so an interrupted install is retried.
  local nerd_fonts=(
    JetBrainsMono                          # code
    Iosevka                                # narrow alternative
  )
  local font dir changed=0
  for font in "${nerd_fonts[@]}"; do
    dir="$HOME/.local/share/fonts/${font}Nerd"
    if compgen -G "$dir/*.ttf" >/dev/null; then
      info "$font Nerd Font already installed"
      continue
    fi
    if gh_download_latest ryanoasis/nerd-fonts "^${font}\\.tar\\.xz\$" "$MODULE_TMP/$font.tar.xz"; then
      run mkdir -p "$dir"
      run tar -xJf "$MODULE_TMP/$font.tar.xz" -C "$dir"
      changed=1
    else
      soft_fail "Nerd Font $font couldn't be downloaded"
    fi
  done
  if (( changed )); then run fc-cache -f; fi
}
