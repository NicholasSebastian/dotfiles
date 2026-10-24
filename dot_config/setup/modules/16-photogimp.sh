# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=photogimp
MODULE_DESC="PhotoGIMP patch for GIMP (open and close GIMP once first)"
MODULE_DEFAULT=1
MODULE_DEPS=(apps)                       # GIMP comes from the apps module
}

# PhotoGIMP's zip ships its settings for GIMP 3.0 (.config/GIMP/3.0), but
# GIMP reads a folder per minor version (3.2 reads GIMP/3.2). So the files
# go into the newest version folder GIMP has created. Flathub's GIMP has
# the xdg-config/GIMP permission, so it keeps them in the normal
# ~/.config/GIMP, not inside ~/.var/app/org.gimp.GIMP (whose config/GIMP
# stays an empty mount point); older builds without that permission used
# the sandbox folder, so both are checked.
photogimp_run() {
  local cfg="" ver="" d v
  for d in "${XDG_CONFIG_HOME:-$HOME/.config}/GIMP" "$HOME/.var/app/org.gimp.GIMP/config/GIMP"; do
    v="$(find "$d" -mindepth 1 -maxdepth 1 -type d -name '[0-9]*.[0-9]*' -printf '%f\n' 2>/dev/null \
         | grep -E '^[0-9]+\.[0-9]+$' | sort -V | tail -n1 || true)"
    # Newest version wins; on a tie the first folder (the one GIMP uses now)
    if [[ -n "$v" && ( -z "$ver" || "$(printf '%s\n%s\n' "$ver" "$v" | sort -V | tail -n1)" != "$ver" ) ]]; then
      cfg="$d" ver="$v"
    fi
  done
  if [[ -z "$ver" ]]; then
    followup manual "PhotoGIMP: open GIMP once, close it, then run './setup.sh --only photogimp'."
    module_skip "GIMP hasn't created its settings folder yet"
  fi
  info "GIMP $ver settings: $cfg/$ver"
  local target="$cfg/$ver" marker="$cfg/$ver/.photogimp-applied"
  if [[ -f "$marker" ]]; then
    info "PhotoGIMP already applied to GIMP $ver (delete $marker to re-apply)"
    return 0
  fi

  local zip="$MODULE_TMP/photogimp.zip" out="$MODULE_TMP/photogimp"
  gh_download_latest Diolinux/PhotoGIMP '^PhotoGIMP-linux\.zip$' "$zip"
  run unzip -oq "$zip" -d "$out"
  if is_dry; then
    cmd "back up $target, copy PhotoGIMP's GIMP settings into it, add its launcher entry"
    return 0
  fi

  # The zip has <root>/.config/GIMP/<version>/ and <root>/.local/...
  local src root
  src="$(find "$out" -maxdepth 4 -type d -path '*/.config/GIMP/*' -name '[0-9]*' -print -quit)"
  [[ -n "$src" ]] || die "PhotoGIMP: unexpected zip layout (no .config/GIMP/<version>)"
  root="${src%/.config/GIMP/*}"
  if [[ "${src##*/}" != "$ver" ]]; then
    info "PhotoGIMP ships settings for GIMP ${src##*/}; applying them to your GIMP $ver"
  fi

  cp -a "$target" "$target.setup-bak.$TS"
  cp -rf "$src/." "$target/"
  if [[ -d "$root/.local" ]]; then cp -rf "$root/.local/." "$HOME/.local/"; fi
  touch "$marker"
  info "PhotoGIMP applied (old settings: $target.setup-bak.$TS)"
}
