# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=kvm
MODULE_DESC="KVM/QEMU + libvirt + virt-manager, UEFI + TPM for Windows 11, virtio drivers"
MODULE_DEFAULT=1
MODULE_RISKY=1
}

_KVM_PKGS=(
  qemu-system-x86 qemu-utils
  qemu-system-modules-spice              # SPICE display for VMs
  libvirt-daemon-system libvirt-clients
  libvirt-daemon-config-network dnsmasq-base   # the 'default' NAT network
  virt-manager
  gir1.2-spiceclientgtk-3.0              # virt-manager's VM console viewer
  ovmf swtpm swtpm-tools                 # UEFI + TPM 2.0 for Windows 11
  # quickemu                             # quick alternative: quickget windows 11
)

kvm_run() {
  if ! grep -Eq 'vmx|svm' /proc/cpuinfo; then
    warn "CPU virtualization not detected: enable VT-x (Intel) or SVM (AMD) in the BIOS"
  fi
  local kvm_mod="kvm_amd"
  if grep -q vmx /proc/cpuinfo; then kvm_mod="kvm_intel"; fi
  local modules_conf="/etc/modules-load.d/kvm.conf" modules_want=$'kvm\n'"$kvm_mod"

  # Work out what's still to do, so a finished setup doesn't ask again
  local -a missing_pkgs=() plan=()
  local p installed
  installed="$(pkgs_installed "${_KVM_PKGS[@]}")"
  for p in "${_KVM_PKGS[@]}"; do in_lines "$p" "$installed" || missing_pkgs+=("$p"); done

  local libvirt_unit=libvirtd.service
  if ! systemctl cat libvirtd.service >/dev/null 2>&1 && systemctl cat virtqemud.socket >/dev/null 2>&1; then
    libvirt_unit=virtqemud.socket
  fi

  if (( ${#missing_pkgs[@]} )); then plan+=("install ${missing_pkgs[*]}"); fi
  if [[ "$(cat "$modules_conf" 2>/dev/null || true)" != "$modules_want" ]]; then
    plan+=("load kvm + $kvm_mod now and at boot ($modules_conf)")
  fi
  if ! systemctl is-enabled -q "$libvirt_unit" 2>/dev/null; then plan+=("enable and start $libvirt_unit"); fi
  if ! in_group libvirt || ! in_group kvm; then plan+=("add $USER_NAME to the libvirt and kvm groups"); fi
  if [[ ! -e /etc/libvirt/qemu/networks/autostart/default.xml ]]; then plan+=("autostart libvirt's 'default' NAT network"); fi

  if (( ${#plan[@]} )); then
    local has_ufw=0
    if is_dry || have ufw || [[ -x /usr/sbin/ufw ]]; then has_ufw=1; fi
    if (( has_ufw )); then
      plan+=("allow DHCP/DNS and routing for VMs on virbr0 in ufw")
    fi
    confirm_risky "${plan[@]}"

    apt_install "${_KVM_PKGS[@]}"

    run sudo modprobe kvm
    run sudo modprobe "$kvm_mod"
    printf '%s\n' "$modules_want" | write_file "$modules_conf"

    if systemctl cat libvirtd.service >/dev/null 2>&1; then libvirt_unit=libvirtd.service; fi
    enable_now "$libvirt_unit"
    add_user_to_group libvirt
    add_user_to_group kvm
    run sudo virsh net-autostart default
    if is_dry || ! sudo virsh net-info default 2>/dev/null | grep -q '^Active:.*yes'; then
      run sudo virsh net-start default
    fi

    # ufw's "deny incoming" also blocks VMs asking the host for an IP address
    # (DHCP) and DNS on libvirt's bridge, so they'd boot with no network.
    # Adding an existing ufw rule is a no-op.
    if (( has_ufw )); then
      run sudo ufw allow in on virbr0 comment 'libvirt VMs: DHCP/DNS'
      run sudo ufw route allow in on virbr0 comment 'libvirt VMs: internet'
      run sudo ufw route allow out on virbr0 comment 'libvirt VMs: internet'
    fi
  else
    info "KVM/libvirt is already set up"
  fi

  # virtio drivers for Windows guests (not risky; just a download). Fedora
  # publishes no checksum next to the 'stable' link.
  if [[ -f "$VM_DIR/virtio-win.iso" ]]; then
    info "virtio-win.iso already in $VM_DIR"
  else
    info "virtio-win.iso is ~700 MB, this can take a while"
    download https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso \
      "$VM_DIR/virtio-win.iso"
  fi

  followup manual "If VMs lose internet after Docker is installed, Docker's firewall rules are the usual cause (it sets the FORWARD policy to DROP)."
  followup manual "Windows 11 VM: get the ISO from microsoft.com, create it in virt-manager (Q35, UEFI, TPM 2.0, VirtIO disk + network) and attach $VM_DIR/virtio-win.iso for drivers."
}
