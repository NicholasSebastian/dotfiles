# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=drives
MODULE_DESC="Choose drives to mount at boot (/etc/fstab, /mnt/<label>)"
MODULE_DEFAULT=1
MODULE_RISKY=1
}

# Lists every filesystem on every drive, mounted or not, and asks which ones
# to mount at boot. The picks go in a managed block in /etc/fstab (by UUID,
# with nofail so a missing drive never blocks boot) and are mounted right away.
# The rest of /etc/fstab is left alone; entries there are never offered.

_DRIVES_FSTAB=/etc/fstab
_DRIVES_START='# >>> pikaos-setup: drives >>>'
_DRIVES_END='# <<< pikaos-setup: drives <<<'
_DRIVES_FS=" ntfs ext2 ext3 ext4 btrfs xfs exfat vfat f2fs "   # mountable data filesystems
# ESP, Microsoft reserved, Windows recovery (GPT); ESP, hidden recovery (MBR)
_DRIVES_HIDE_PARTTYPES=" c12a7328-f81f-11d2-ba4b-00a0c93ec93b e3c9e316-0b5c-4db8-817d-f92df00215ae de94bba4-07c3-4d4a-8a83-a8e0c1d1fa4c 0xef 0x27 "

# Candidates, in display order. -g: setup.sh sources modules inside a function.
declare -ga _DRIVES_DEV=() _DRIVES_FSTYPE=() _DRIVES_LABEL=() _DRIVES_UUID=() _DRIVES_SIZE=()
declare -ga _DRIVES_CUR=() _DRIVES_MP=() _DRIVES_ON=() _DRIVES_NOTE=()
# UUID -> mount point, from the managed block as it is now
declare -gA _DRIVES_MANAGED=()

# Lines of the managed block, or "UUID<TAB>mountpoint" pairs with 'pairs'
_drives_block() {
  [[ -f "$_DRIVES_FSTAB" ]] || return 0
  awk -v s="$_DRIVES_START" -v e="$_DRIVES_END" -v pairs="${1:-}" '
    $0 == s { f = 1; next }
    $0 == e { f = 0; next }
    f && pairs && /^UUID=/ { sub(/^UUID=/, "", $1); print $1 "\t" $2; next }
    f && !pairs' "$_DRIVES_FSTAB"
}

# _drives_is_windows DEV CUR: 0 if the NTFS volume holds a Windows install,
# 1 if not, 2 if it can't be checked (dry run: no sudo).
_drives_is_windows() {
  local dev="$1" cur="$2" out
  if [[ -n "$cur" ]]; then [[ -d "$cur/Windows/System32" ]]; return; fi
  if is_dry; then return 2; fi
  # Captured first: 'ntfsls | grep -q' would SIGPIPE ntfsls under pipefail.
  # -f reads hibernated (Fast Startup) volumes too.
  out="$(sudo ntfsls -f -p /Windows "$dev" 2>/dev/null || true)"
  grep -qix system32 <<<"$out"
}

_drives_scan() {
  local dev fs label uuid ptype size cur sys_sources rc uuid_mp mp
  while IFS=$'\t' read -r uuid mp; do
    if [[ -n "$uuid" ]]; then _DRIVES_MANAGED[$uuid]="$mp"; fi
  done < <(_drives_block pairs)
  sys_sources="$(strip_block "$_DRIVES_FSTAB" "$_DRIVES_START" "$_DRIVES_END" | awk '!/^[[:space:]]*(#|$)/ { print $1 }')"

  if in_lines ntfs "$(lsblk -nlo FSTYPE)"; then apt_install ntfs-3g; fi   # ntfsls

  while IFS=$'\t' read -r dev fs label uuid ptype size cur; do
    if [[ "$_DRIVES_FS" != *" $fs "* ]]; then
      info "Not offered: $dev ${label:-(no label)} ($fs) - not a data filesystem"; continue
    fi
    if [[ -n "$ptype" && "$_DRIVES_HIDE_PARTTYPES" == *" $ptype "* ]]; then
      info "Not offered: $dev ${label:-(no label)} ($fs) - boot/reserved/recovery partition"; continue
    fi
    if in_lines "UUID=$uuid" "$sys_sources" || in_lines "$dev" "$sys_sources" \
        || { [[ -n "$label" ]] && in_lines "LABEL=$label" "$sys_sources"; } \
        || [[ "$cur" == / || "$cur" == /boot || "$cur" == /boot/* ]]; then
      info "Not offered: $dev ${label:-(no label)} ($fs) - already in /etc/fstab (system entry)"; continue
    fi
    rc=1
    if [[ "$fs" == ntfs ]]; then _drives_is_windows "$dev" "$cur" && rc=0 || rc=$?; fi
    if (( rc == 0 )); then
      info "Not offered: $dev ${label:-(no label)} ($fs) - Windows system partition"; continue
    fi

    _DRIVES_DEV+=("$dev") _DRIVES_FSTYPE+=("$fs") _DRIVES_LABEL+=("$label")
    _DRIVES_UUID+=("$uuid") _DRIVES_SIZE+=("$size") _DRIVES_CUR+=("$cur")
    if [[ -n "${_DRIVES_MANAGED[$uuid]:-}" ]]; then _DRIVES_ON+=(1); else _DRIVES_ON+=(0); fi
    if (( rc == 2 )); then _DRIVES_NOTE+=(" (Windows check skipped in dry run)"); else _DRIVES_NOTE+=(""); fi
  done < <(lsblk -J -o PATH,FSTYPE,LABEL,UUID,PARTTYPE,SIZE,MOUNTPOINTS | jq -r '
    [.blockdevices[] | recurse(.children[]?)][]
    | select(.uuid != null and .fstype != null)
    | [.path, .fstype, (.label // ""), .uuid, ((.parttype // "") | ascii_downcase), .size,
       ((.mountpoints // []) | map(select(. != null)) | .[0] // "")] | @tsv')

  # Mount points: keep the managed one (stable if the label changes), else
  # /mnt/<label> with anything unusual turned into '_', made unique.
  local i name base n managed_mps
  local -A used=()
  managed_mps="$(printf '%s\n' "${_DRIVES_MANAGED[@]}")"
  for i in "${!_DRIVES_DEV[@]}"; do
    uuid_mp="${_DRIVES_MANAGED[${_DRIVES_UUID[i]}]:-}"
    if [[ -n "$uuid_mp" ]]; then _DRIVES_MP[i]="$uuid_mp"; used[$uuid_mp]=1; fi
  done
  for i in "${!_DRIVES_DEV[@]}"; do
    [[ -z "${_DRIVES_MP[i]:-}" ]] || continue
    name="${_DRIVES_LABEL[i]//[^A-Za-z0-9._-]/_}"
    [[ -n "$name" ]] || name="${_DRIVES_UUID[i]}"
    base="/mnt/$name" mp="$base" n=1
    while [[ -n "${used[$mp]:-}" ]] \
        || { [[ -n "$(ls -A "$mp" 2>/dev/null)" ]] && ! in_lines "$mp" "$managed_mps"; }; do
      n=$(( n + 1 )); mp="$base-$n"
    done
    _DRIVES_MP[i]="$mp"; used[$mp]=1
  done
}

_drives_show() {
  local i mark state
  for i in "${!_DRIVES_DEV[@]}"; do
    mark=" " state="not mounted"
    if (( _DRIVES_ON[i] )); then mark=x; fi
    if [[ -n "${_DRIVES_CUR[i]}" ]]; then state="mounted at ${_DRIVES_CUR[i]}"; fi
    printf '       %d) [%s] %-16s %-24s %-6s %6s  %s -> %s%s\n' "$(( i + 1 ))" "$mark" \
      "${_DRIVES_DEV[i]}" "${_DRIVES_LABEL[i]:-(no label)}" "${_DRIVES_FSTYPE[i]}" \
      "${_DRIVES_SIZE[i]}" "$state" "${_DRIVES_MP[i]}" "${_DRIVES_NOTE[i]}"
  done
}

_drives_pick() {
  local reply tok bad n="${#_DRIVES_DEV[@]}" i
  local -a toks=() picked=()
  _drives_show
  if is_dry; then
    info "(dry run: would ask) Mount which drives at boot? Previewing with all of them ticked."
    for i in "${!_DRIVES_ON[@]}"; do _DRIVES_ON[i]=1; done
    return 0
  fi
  while :; do
    printf '%s  ?? Mount which drives at boot? Numbers (space/comma separated); Enter keeps the [x] ones; "none" clears all.%s\n' "$C_YELLOW" "$C_RESET"
    IFS= read -r reply </dev/tty || module_skip "no terminal to choose drives"
    printf '  -> answer: %s\n' "${reply:-(keep)}"
    [[ -n "$reply" ]] || return 0
    if [[ "${reply,,}" == none ]]; then
      for i in "${!_DRIVES_ON[@]}"; do _DRIVES_ON[i]=0; done
      return 0
    fi
    IFS=', ' read -ra toks <<<"$reply"
    bad="" picked=()
    for tok in "${toks[@]}"; do
      [[ -n "$tok" ]] || continue
      if [[ "$tok" =~ ^[0-9]+$ ]] && (( 10#$tok >= 1 && 10#$tok <= n )); then
        picked+=("$(( 10#$tok - 1 ))")
      else
        bad="$tok"; break
      fi
    done
    if [[ -n "$bad" ]]; then warn "Not a drive number: $bad"; continue; fi
    for i in "${!_DRIVES_ON[@]}"; do _DRIVES_ON[i]=0; done
    for i in "${picked[@]}"; do _DRIVES_ON[i]=1; done
    return 0
  done
}

# _drives_entry I: the fstab type, options and pass number for candidate I
_drives_entry() {
  local uid gid common="nofail,x-systemd.device-timeout=10s,x-gvfs-show"
  uid="$(id -u "$USER_NAME")" gid="$(id -g "$USER_NAME")"
  case "${_DRIVES_FSTYPE[$1]}" in
    ntfs)           printf 'ntfs3\tuid=%s,gid=%s,umask=022,windows_names,%s\t0\n' "$uid" "$gid" "$common" ;;
    exfat)          printf 'exfat\tuid=%s,gid=%s,umask=022,%s\t0\n' "$uid" "$gid" "$common" ;;
    vfat)           printf 'vfat\tuid=%s,gid=%s,umask=022,utf8,%s\t0\n' "$uid" "$gid" "$common" ;;
    ext2|ext3|ext4) printf '%s\tdefaults,%s\t2\n' "${_DRIVES_FSTYPE[$1]}" "$common" ;;
    *)              printf '%s\tdefaults,%s\t0\n' "${_DRIVES_FSTYPE[$1]}" "$common" ;;
  esac
}

_drives_body() {
  local i type opts pass first=1
  for i in "${!_DRIVES_DEV[@]}"; do
    (( _DRIVES_ON[i] )) || continue
    IFS=$'\t' read -r type opts pass < <(_drives_entry "$i")
    (( first )) || printf '\n'
    first=0
    # Label only in the comment: device names change when drives are renumbered
    printf '# %s\nUUID=%s\t%s\t%s\t%s\t0\t%s' "${_DRIVES_LABEL[i]:-${_DRIVES_UUID[i]}}" \
      "${_DRIVES_UUID[i]}" "${_DRIVES_MP[i]}" "$type" "$opts" "$pass"
  done
}

drives_run() {
  if ! is_dry && ! has_tty; then module_skip "choosing drives needs a terminal"; fi
  _drives_scan
  if (( ${#_DRIVES_DEV[@]} == 0 )); then info "No drives to offer"; return 0; fi
  _drives_pick

  local new old i uuid label any_ntfs=0
  local -a changes=() removed=()
  local -A present=()
  new="$(_drives_body)"
  old="$(_drives_block)"
  for i in "${!_DRIVES_DEV[@]}"; do
    uuid="${_DRIVES_UUID[i]}" label="${_DRIVES_LABEL[i]:-$uuid}"
    present[$uuid]=1
    if (( _DRIVES_ON[i] )); then
      if [[ "${_DRIVES_FSTYPE[i]}" == ntfs ]]; then any_ntfs=1; fi
      if [[ -z "${_DRIVES_MANAGED[$uuid]:-}" ]]; then
        changes+=("add $label -> ${_DRIVES_MP[i]} ($(_drives_entry "$i" | cut -f1))")
      fi
    elif [[ -n "${_DRIVES_MANAGED[$uuid]:-}" ]]; then
      changes+=("remove $label (${_DRIVES_MANAGED[$uuid]})")
      removed+=("$label"$'\t'"${_DRIVES_MANAGED[$uuid]}")
    fi
  done
  for uuid in "${!_DRIVES_MANAGED[@]}"; do
    [[ -n "${present[$uuid]:-}" ]] || changes+=("remove UUID=$uuid (drive not present)")
  done

  if [[ "$new" != "$old" ]]; then
    (( ${#changes[@]} )) || changes+=("update the options of the managed entries")
    confirm_risky "${changes[@]}" \
      "back up /etc/fstab to /var/backups/setup/etc/fstab.$TS first" \
      "entries use nofail: a missing or unmountable drive never blocks boot"
    for i in "${!_DRIVES_DEV[@]}"; do
      if (( _DRIVES_ON[i] )); then run sudo mkdir -p "${_DRIVES_MP[i]}"; fi
    done
    if [[ -z "$new" ]]; then
      if grep -qxF "$_DRIVES_START" "$_DRIVES_FSTAB"; then
        strip_block "$_DRIVES_FSTAB" "$_DRIVES_START" "$_DRIVES_END" | write_file "$_DRIVES_FSTAB" 0644
      fi
    else
      rc_block "$_DRIVES_FSTAB" "$_DRIVES_START" "$_DRIVES_END" "$new"
    fi
    # The block differs, so the file was written. (write_changed can't be used
    # here: rc_block runs write_file at the end of a pipe, in a subshell.)
    if ! is_dry && ! findmnt --verify --tab-file "$_DRIVES_FSTAB" >/dev/null; then
      die "/etc/fstab doesn't verify (findmnt --verify). Restore it: sudo cp /var/backups/setup/etc/fstab.$TS /etc/fstab"
    fi
    run sudo systemctl daemon-reload
  else
    info "/etc/fstab already has these drives"
  fi

  # Mount now (also repairs a run where the mount failed earlier)
  local dev mp cur
  for i in "${!_DRIVES_DEV[@]}"; do
    (( _DRIVES_ON[i] )) || continue
    dev="${_DRIVES_DEV[i]}" mp="${_DRIVES_MP[i]}" cur="${_DRIVES_CUR[i]}" label="${_DRIVES_LABEL[i]:-$dev}"
    if [[ "$cur" == "$mp" ]]; then info "$label already mounted at $mp"; continue; fi
    if [[ -n "$cur" ]] && ! run sudo umount "$dev"; then
      soft_fail "$label is in use at $cur; it will mount at $mp after a reboot"
      continue
    fi
    if ! run sudo mount "$mp"; then
      soft_fail "$label: couldn't mount at $mp. If Windows was hibernated (Fast Startup), boot Windows and shut down fully; details: sudo dmesg | tail"
    fi
  done

  local entry
  for entry in "${removed[@]}"; do
    mp="${entry#*$'\t'}"
    if mountpoint -q "$mp" 2>/dev/null; then
      info "${entry%%$'\t'*} stays mounted at $mp until reboot (or: sudo umount $mp)"
    fi
  done

  if (( any_ntfs )); then
    followup manual "Windows: turn off Fast Startup (Control Panel > Power Options > Choose what the power buttons do) so the NTFS drives in /etc/fstab mount read-write after you've used Windows."
  fi
}
