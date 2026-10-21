# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=clock
MODULE_DESC="Hardware clock in local time (dual-boot with Windows)"
MODULE_DEFAULT=1
MODULE_RISKY=1
}

# Windows keeps the hardware clock in local time, Linux in UTC. Matching
# Windows stops the clock jumping by your UTC offset whenever you switch OS.
clock_run() {
  local rtc ntp
  rtc="$(timedatectl show -p LocalRTC --value 2>/dev/null || echo unknown)"
  ntp="$(timedatectl show -p NTP --value 2>/dev/null || echo unknown)"
  if [[ "$rtc" == yes && "$ntp" == yes ]]; then
    info "Hardware clock is already in local time and NTP is on"
    return 0
  fi

  local -a plan=()
  if [[ "$rtc" != yes ]]; then
    plan+=("store the hardware clock (RTC) in local time, like Windows: timedatectl set-local-rtc 1 --adjust-system-clock")
  fi
  if [[ "$ntp" != yes ]]; then plan+=("turn on network time sync: timedatectl set-ntp true"); fi
  plan+=("undo later with: sudo timedatectl set-local-rtc 0")
  confirm_risky "${plan[@]}"

  if [[ "$rtc" != yes ]]; then run sudo timedatectl set-local-rtc 1 --adjust-system-clock; fi
  if [[ "$ntp" != yes ]]; then run sudo timedatectl set-ntp true; fi
}
