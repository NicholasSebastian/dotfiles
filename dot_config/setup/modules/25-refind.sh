# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=refind
MODULE_DESC="rEFInd boot menu: config, kernel options and rEFInd-lite theme (files in setup/files/refind)"
MODULE_DEFAULT=0
MODULE_RISKY=1
}

# Files in files/refind:
#   refind.conf        -> EFI/refind/refind.conf
#   refind_linux.conf  -> /boot and EFI/Linux (the kernel options rEFInd
#                         passes to PikaOS's UKIs; @ROOT_UUID@ is filled in
#                         from this system's / so it can't point at another disk)
#   themes/rEFInd-lite -> EFI/refind/themes/rEFInd-lite
#                         (Littlebanbrick/rEFInd-lite, MIT, commit e600b8c)
# PikaOS's kernel hook copies /boot/refind_linux.conf to EFI/Linux only when
# it's missing there, so both copies are written. Nothing signed is touched.

_REFIND_THEME=rEFInd-lite

# Same lookup as the secure_boot module
_refind_esp() {
  local esp
  esp="$(bootctl --print-esp-path 2>/dev/null || true)"
  [[ -n "$esp" ]] || esp="$(findmnt -no TARGET /boot/efi 2>/dev/null || true)"
  printf '%s' "${esp:-/boot/efi}"
}

refind_run() {
  local src="$SETUP_DIR/files/refind" esp dir uuid
  esp="$(_refind_esp)"
  dir="$esp/EFI/refind"
  [[ -f "$dir/refind.conf" ]] || module_skip "rEFInd isn't installed in $dir"
  [[ -d "$src/themes/$_REFIND_THEME" ]] || die "Theme files missing: $src/themes/$_REFIND_THEME (run chezmoi apply)"

  uuid="$(findmnt -no UUID /)"
  [[ -n "$uuid" ]] || die "Couldn't read the root filesystem's UUID"
  local linux_conf="$MODULE_TMP/refind_linux.conf"
  sed "s/@ROOT_UUID@/$uuid/g" "$src/refind_linux.conf" >"$linux_conf"

  # What's out of date
  local theme=0 conf=0 f
  local -a linux_targets=() plan=()
  if ! diff -rq "$src/themes/$_REFIND_THEME" "$dir/themes/$_REFIND_THEME" >/dev/null 2>&1; then
    theme=1; plan+=("install the $_REFIND_THEME theme to $dir/themes/$_REFIND_THEME")
  fi
  if ! cmp -s "$src/refind.conf" "$dir/refind.conf"; then
    conf=1; plan+=("replace $dir/refind.conf (shown below)")
  fi
  for f in /boot/refind_linux.conf "$esp/EFI/Linux/refind_linux.conf"; do
    [[ -d "${f%/*}" ]] || continue
    if ! cmp -s "$linux_conf" "$f"; then
      linux_targets+=("$f"); plan+=("update kernel options in $f")
    fi
  done
  if (( ${#plan[@]} == 0 )); then
    info "rEFInd config and theme are up to date"
    return 0
  fi

  confirm_risky "${plan[@]}" \
    "back up the replaced files to /var/backups/setup/... first" \
    "the old refind-dark theme folder stays on the ESP (unused)" \
    "takes effect at the next boot; if the menu looks wrong, restore $dir/refind.conf from the backup"

  if (( theme )); then
    run sudo mkdir -p "$dir/themes/$_REFIND_THEME"
    run sudo cp -rT --no-preserve=mode,ownership "$src/themes/$_REFIND_THEME" "$dir/themes/$_REFIND_THEME"
  fi
  if (( conf )); then write_file "$dir/refind.conf" 0644 <"$src/refind.conf"; fi
  for f in "${linux_targets[@]}"; do write_file "$f" 0644 <"$linux_conf"; done

  followup reboot "rEFInd: reboot to see the $_REFIND_THEME theme."
}
