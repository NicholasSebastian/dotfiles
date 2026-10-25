# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=snapshots
MODULE_DESC="Timeshift snapshots + ufw firewall"
MODULE_DEFAULT=1
}

snapshots_run() {
  apt_install timeshift ufw

  # ufw.conf is world-readable, so this works without sudo (and in dry-run).
  # An already-enabled firewall keeps your own defaults.
  if grep -qs '^ENABLED=yes' /etc/ufw/ufw.conf; then
    info "ufw is already enabled"
  else
    run sudo ufw default deny incoming
    run sudo ufw default allow outgoing
    run sudo ufw --force enable
  fi

  if [[ ! -f /etc/timeshift/timeshift.json ]]; then
    followup manual "Open Timeshift once and choose BTRFS (if root is btrfs) or RSYNC, plus a schedule."
  fi
}
