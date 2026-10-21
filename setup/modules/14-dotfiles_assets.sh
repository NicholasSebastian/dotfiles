# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=dotfiles_assets
MODULE_DESC="Wallpapers and custom fonts from your old dotfiles repo"
MODULE_DEFAULT=0
}

# Pulls only the wallpapers and custom fonts from $DOTFILES_REPO (config.sh).
# The two Nerd Fonts in there are skipped; the fonts module gets newer ones.
dotfiles_assets_run() {
  local font_dir="$HOME/.local/share/fonts/dotfiles"
  local fonts=(AlfaSlabOne-Regular GrapeNuts-Regular Icomoon-Feather)
  local font missing=0
  for font in "${fonts[@]}"; do
    [[ -f "$font_dir/$font.ttf" ]] || missing=1
  done
  if (( ! missing )) && compgen -G "$WALLPAPER_DIR/*" >/dev/null; then
    info "Wallpapers and fonts from your dotfiles are already in place"
    return 0
  fi

  local repo="$MODULE_TMP/old-dotfiles"
  run git clone --depth 1 --filter=blob:none --sparse "$DOTFILES_REPO" "$repo"
  run git -C "$repo" sparse-checkout set waypaper/wallpapers fonts

  # --update=none keeps files you already have (plain -n exits non-zero on
  # newer coreutils when it skips a file)
  run mkdir -p "$WALLPAPER_DIR" "$font_dir"
  run cp -r --update=none "$repo/waypaper/wallpapers/." "$WALLPAPER_DIR/"
  for font in "${fonts[@]}"; do
    run cp --update=none "$repo/fonts/$font.ttf" "$font_dir/"
  done
  run fc-cache -f

  followup manual "Your wallpapers are in $WALLPAPER_DIR. Point Noctalia's wallpaper folder there."
}
