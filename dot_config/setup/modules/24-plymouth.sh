# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=plymouth
MODULE_DESC="Boot splash: adi1090x 'splash' Plymouth theme (files in setup/files/plymouth)"
MODULE_DEFAULT=0
}

# The theme is adi1090x/plymouth-themes pack_4/splash (GPL-3.0), kept in
# files/plymouth/splash at upstream commit 158ccfd. Its .plymouth file
# hard-codes /usr/share/plymouth/themes/splash, so it's installed there.
# PikaOS's booster initramfs has enable_plymouth: false, so Plymouth starts
# from the root filesystem and picks up the theme without an initramfs rebuild.

_PLY_THEME=splash
_PLY_DEST="/usr/share/plymouth/themes/$_PLY_THEME"

plymouth_run() {
  local src="$SETUP_DIR/files/plymouth"
  apt_install plymouth                   # includes the script plugin the theme uses
  [[ -d "$src/$_PLY_THEME" ]] || die "Theme files missing: $src/$_PLY_THEME (run chezmoi apply)"

  if same_tree "$src/$_PLY_THEME" "$_PLY_DEST"; then
    info "Plymouth theme '$_PLY_THEME' already installed"
  else
    copy_tree "$src/$_PLY_THEME" "$_PLY_DEST"
  fi
  write_file /etc/plymouth/plymouthd.conf 0644 <"$src/plymouthd.conf"

  if [[ " $(</proc/cmdline) " != *" splash "* ]]; then
    followup manual "Plymouth: add 'splash' (and 'quiet') to the kernel options in /boot/refind_linux.conf, or the boot splash won't show."
  fi
  if [[ -f /etc/booster.yaml ]] && grep -qE '^enable_plymouth:[[:space:]]*true' /etc/booster.yaml; then
    followup manual "Plymouth: booster includes Plymouth in the initramfs; rebuild it so the new theme is used early in boot."
  fi
  followup manual "Plymouth: preview the splash with: sudo plymouthd && sudo plymouth --show-splash; sleep 5; sudo plymouth quit"
}
