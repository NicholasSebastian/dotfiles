# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=secure_boot
MODULE_DESC="Sign kernel + rEFInd with your own keys (sbctl), per the PikaOS wiki"
MODULE_DEFAULT=0
MODULE_RISKY=1
}

# Follows https://wiki.pika-os.com/en/guides-wiki/secure-boot (option 2):
#   pikman install sbctl-booster-extra
#   sbctl create-keys   (the wiki's 'sbctl setup --setup' first would, since
#                        sbctl 0.18, enroll keys without Microsoft's or fail
#                        outside Setup Mode, so it's left out)
#   sbctl enroll-keys --microsoft
#   apt reinstall linux-image-$(uname -r)
#   sbctl sign rEFInd (EFI/refind or EFI/BOOT) + its ext4 driver; sbctl verify
# Keys are only enrolled when the firmware is in Setup Mode (which you switch
# on yourself in the BIOS) *and* you confirm the step.

_secure_boot_esp() {
  local esp
  esp="$(bootctl --print-esp-path 2>/dev/null || true)"
  [[ -n "$esp" ]] || esp="$(findmnt -no TARGET /boot/efi 2>/dev/null || true)"
  printf '%s' "${esp:-/boot/efi}"
}

_secure_boot_refind_files() {
  local esp="$1" dir f
  for dir in "$esp/EFI/refind" "$esp/EFI/BOOT"; do
    [[ -f "$dir/refind_x64.efi" ]] || continue
    printf '%s\n' "$dir/refind_x64.efi"
    for f in "$dir"/drivers_x64/*.efi; do
      if [[ -f "$f" ]]; then printf '%s\n' "$f"; fi
    done
  done
}

secure_boot_run() {
  # PikaOS's meta package, with recommends, as the wiki's 'pikman install'
  APT_RECOMMENDS=1 apt_install sbctl-booster-extra
  local sbctl
  sbctl="$(command -v sbctl || true)"
  if [[ -z "$sbctl" && -x /usr/sbin/sbctl ]]; then sbctl=/usr/sbin/sbctl; fi
  if [[ -z "$sbctl" ]]; then
    if is_dry; then info "sbctl isn't installed yet; the steps below depend on its status"; return 0; fi
    die "sbctl is missing after installing sbctl-booster-extra"
  fi

  # 1. Look before touching anything
  local status installed setup_mode sb vendors
  status="$("$sbctl" status --json 2>/dev/null || true)"
  if [[ -z "$status" ]] && can_sudo; then status="$(sudo "$sbctl" status --json)"; fi
  [[ -n "$status" ]] || die "Couldn't read 'sbctl status'"
  IFS=$'\t' read -r installed setup_mode sb vendors < <(jq -r '
    [.installed, .setup_mode, .secure_boot, ((.vendors // []) | join(","))] | map(tostring) | @tsv' <<<"$status")
  info "sbctl status: own keys created=$installed, setup mode=$setup_mode, secure boot=$sb, vendor keys=${vendors:-none}"

  if [[ "$sb" == true && "$installed" == true ]]; then
    info "Secure Boot is already on with sbctl keys; only verifying signatures"
    run sudo "$sbctl" verify
    return 0
  fi
  if [[ "$sb" == true ]]; then
    module_skip "Secure Boot is on but sbctl has no keys (another setup is in use); not touching it"
  fi

  local esp kernel_pkg
  local -a files=()
  esp="$(_secure_boot_esp)"
  kernel_pkg="linux-image-$(uname -r)"
  mapfile -t files < <(_secure_boot_refind_files "$esp")

  local -a plan=()
  if [[ "$installed" != true ]]; then plan+=("create your own Secure Boot signing keys (sbctl create-keys)"); fi
  if [[ "$setup_mode" == true ]]; then
    plan+=("enroll them into the firmware together with Microsoft's keys (sbctl enroll-keys --microsoft); asked again separately")
  else
    plan+=("NOT enroll keys: the firmware isn't in Setup Mode")
  fi
  plan+=("reinstall $kernel_pkg so its unified kernel image (UKI) is rebuilt and signed"
         "sign rEFInd under $esp: ${files[*]:-no rEFInd files found}"
         "run sbctl verify")
  confirm_risky "${plan[@]}"

  local keys_changed=0
  if [[ "$installed" != true ]]; then
    run sudo "$sbctl" create-keys
    keys_changed=1
  fi

  if [[ "$setup_mode" == true ]]; then
    if confirm_step "Enroll keys into the firmware now (sbctl enroll-keys --microsoft)? Microsoft's keys are kept so Windows and GPU option ROMs still boot."; then
      run sudo "$sbctl" enroll-keys --microsoft
      keys_changed=1
    else
      followup manual "Secure Boot: keys weren't enrolled (declined). Re-run './setup.sh --only secure_boot' when ready."
    fi
  else
    followup manual "Secure Boot: keys aren't enrolled because the firmware isn't in Setup Mode. In the BIOS, with Secure Boot off, clear/reset the Secure Boot keys (Setup Mode), then run './setup.sh --only secure_boot' again."
  fi

  # Only needed when keys changed; afterwards kernel updates are signed automatically
  if (( keys_changed )); then
    if is_dry || apt_available "$kernel_pkg"; then
      run "${APT_GET[@]}" install --reinstall "$kernel_pkg"
    else
      soft_fail "kernel package $kernel_pkg not found; reinstall your kernel by hand so the UKI gets signed"
    fi
  else
    info "Secure Boot keys unchanged, skipping kernel reinstall"
  fi

  # -s saves each file in sbctl's database so it's re-signed after updates;
  # signing an already-signed file is a no-op.
  if (( ${#files[@]} == 0 )); then
    soft_fail "no rEFInd files under $esp/EFI/{refind,BOOT}; sign your bootloader by hand"
  fi
  local f
  for f in "${files[@]}"; do run sudo "$sbctl" sign -s "$f"; done

  run sudo "$sbctl" verify

  followup reboot "Secure Boot: have your Windows BitLocker recovery key ready (new keys can trigger a BitLocker prompt). Then enable Secure Boot in the BIOS and pick the 'vmlinuz-...-pikaos-uki.efi' entry in rEFInd."
  followup manual "Secure Boot: once it's on, check the NVIDIA driver still loads with 'nvidia-smi'."
}
