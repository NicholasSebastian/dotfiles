#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
# =============================================================================
# setup.sh - post-install setup for PikaOS (Hyprland edition)
# =============================================================================
# Modules live in modules/NN-<id>.sh and are sourced, never executed. Each
# declares MODULE_ID/DESC/DEFAULT (and optionally DEPS/RISKY) and a <id>_run
# function; the menu, --list and dependency order are built from those headers.

set -Eeuo pipefail
shopt -s inherit_errexit

SETUP_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# shellcheck source=config.sh
source "$SETUP_DIR/config.sh"
# shellcheck source=lib/core.sh
source "$SETUP_DIR/lib/core.sh"
# shellcheck source=lib/pkg.sh
source "$SETUP_DIR/lib/pkg.sh"
# shellcheck source=lib/github.sh
source "$SETUP_DIR/lib/github.sh"
# shellcheck source=lib/env.sh
source "$SETUP_DIR/lib/env.sh"

usage() {
  cat <<EOF
Usage: ${0##*/} [options] [module...]

  (no options)      choose modules from a checklist (defaults pre-ticked)
  --all             run every module
  --only a,b        run only these modules (plus what they depend on)
  --skip a,b        leave these out (modules that need them are skipped too)
  --yes, -y         no menu: run the default modules (or --only/--all ones)
  --force           don't ask before risky modules (secure_boot, clock, kvm,
                    noctalia, noctalia_greeter, drives); --yes alone still asks
                    (cleanup always asks, even with --force)
  --dry-run         show what would happen; no sudo, no network, no changes
  --list            list modules with defaults and dependencies
  -h, --help        this help

Module names given without a flag work like --only; --pick is the old name
for the checklist. Run 'pikman upgrade' first. Logs: $LOG_DIR
EOF
}

# --- Registry ----------------------------------------------------------------

declare -a MOD_ORDER=()
declare -A MOD_DESC=() MOD_DEFAULT=() MOD_DEPS=() MOD_RISKY=() MOD_NUM=()

load_modules() {
  local f base num id d
  for f in "$SETUP_DIR"/modules/[0-9][0-9]-*.sh; do
    [[ -e "$f" ]] || die "No modules found in $SETUP_DIR/modules"
    base="${f##*/}"; base="${base%.sh}"
    num="${base%%-*}"; id="${base#*-}"

    unset MODULE_ID MODULE_DESC MODULE_DEFAULT MODULE_RISKY
    MODULE_DEPS=()
    # Modules are shellchecked on their own; following them here would only
    # repeat that, so the dynamic path isn't resolved.
    # shellcheck source=/dev/null
    source "$f"

    [[ "${MODULE_ID:-}" == "$id" ]] || die "$base: MODULE_ID '${MODULE_ID:-}' doesn't match the file name"
    declare -F "${id}_run" >/dev/null || die "$base: no ${id}_run function"
    [[ "${MODULE_DEFAULT:-}" == [01] ]] || die "$base: MODULE_DEFAULT must be 0 or 1"
    [[ -n "${MODULE_DESC:-}" ]] || die "$base: MODULE_DESC is empty"

    MOD_ORDER+=("$id")
    MOD_NUM[$id]="$num"
    MOD_DESC[$id]="$MODULE_DESC"
    MOD_DEFAULT[$id]="$MODULE_DEFAULT"
    MOD_RISKY[$id]="${MODULE_RISKY:-0}"
    MOD_DEPS[$id]="${MODULE_DEPS[*]}"
  done

  # Dependencies must exist and come earlier, so run order = file order
  for id in "${MOD_ORDER[@]}"; do
    for d in ${MOD_DEPS[$id]}; do
      [[ -n "${MOD_NUM[$d]:-}" ]] || die "$id depends on unknown module '$d'"
      (( 10#${MOD_NUM[$d]} < 10#${MOD_NUM[$id]} )) || die "$id depends on $d, which runs later"
    done
  done
}

list_modules() {
  local id state risky deps
  printf '  %-3s %-17s %-4s %-6s %-22s %s\n' "#" "module" "on" "risky" "needs" "description"
  for id in "${MOD_ORDER[@]}"; do
    if (( MOD_DEFAULT[$id] )); then state="${C_GREEN}on ${C_RESET}"; else state="${C_DIM}off${C_RESET}"; fi
    if (( MOD_RISKY[$id] )); then risky="${C_YELLOW}yes${C_RESET}"; else risky="   "; fi
    deps="${MOD_DEPS[$id]:-–}"
    printf '  %-3s %-17s %s  %s    %-22s %s\n' "${MOD_NUM[$id]}" "$id" "$state" "$risky" "$deps" "${MOD_DESC[$id]}"
  done
}

# --- Arguments ---------------------------------------------------------------

DRY_RUN=0 FORCE=0 ASSUME_YES=0 LIST=0 MODE=menu
declare -a ONLY=() SKIP=()

# add_ids ARRAY LIST: append the ids in a comma/space separated LIST to ARRAY.
add_ids() {
  local -n _arr="$1"; local IFS=', ' _id; local -a _ids
  read -ra _ids <<<"$2"
  for _id in "${_ids[@]}"; do if [[ -n "$_id" ]]; then _arr+=("$_id"); fi; done
}

parse_args() {
  while (( $# )); do
    case "$1" in
      --all)       MODE=all ;;
      --only)      (( $# > 1 )) || die "--only needs a list"; add_ids ONLY "$2"; MODE=only; shift ;;
      --only=*)    add_ids ONLY "${1#*=}"; MODE=only ;;
      --skip)      (( $# > 1 )) || die "--skip needs a list"; add_ids SKIP "$2"; shift ;;
      --skip=*)    add_ids SKIP "${1#*=}" ;;
      --yes|-y)    ASSUME_YES=1 ;;
      --force)     FORCE=1 ;;
      --dry-run)   DRY_RUN=1 ;;
      --list)      LIST=1 ;;
      --pick)      MODE=menu ;;
      -h|--help)   usage; exit 0 ;;
      -*)          die "Unknown option: $1 (see --help)" ;;
      *)           add_ids ONLY "$1"; MODE=only ;;
    esac
    shift
  done
}

check_ids() {
  local id
  for id in "$@"; do
    [[ -n "${MOD_NUM[$id]:-}" ]] || die "Unknown module: $id (see --list)"
  done
}

# --- Selection ---------------------------------------------------------------

declare -A WANT=() AUTO=() STATUS=() REASON=()
declare -a RUN_ORDER=()

want_defaults() {
  local id
  for id in "${MOD_ORDER[@]}"; do
    if (( MOD_DEFAULT[$id] )); then WANT[$id]=1; fi
  done
}

pick_menu() {
  local id desc on choice reply
  local -a args=() picked=()
  if have whiptail; then
    for id in "${MOD_ORDER[@]}"; do
      desc="${MOD_DESC[$id]}" on=OFF
      if (( MOD_RISKY[$id] )); then desc="[!] $desc"; fi
      if (( MOD_DEFAULT[$id] )); then on=ON; fi
      args+=("$id" "$desc" "$on")
    done
    choice="$(whiptail --title "PikaOS setup" \
      --checklist "Space toggles, Enter confirms. [!] asks again before changing boot/login state." \
      25 118 17 "${args[@]}" 3>&1 1>&2 2>&3)" || exit 0
    read -ra picked <<<"${choice//\"/}"
  else
    list_modules
    printf '\nModules to run (space/comma separated), Enter for the defaults: '
    IFS= read -r reply </dev/tty || exit 0
    if [[ -z "$reply" ]]; then want_defaults; return 0; fi
    add_ids picked "$reply"
  fi
  check_ids "${picked[@]}"
  for id in "${picked[@]}"; do WANT[$id]=1; done
}

choose_modules() {
  local id
  check_ids "${ONLY[@]}" "${SKIP[@]}"
  case "$MODE" in
    all)  for id in "${MOD_ORDER[@]}"; do WANT[$id]=1; done ;;
    only) for id in "${ONLY[@]}"; do WANT[$id]=1; done ;;
    menu)
      if (( ASSUME_YES )); then
        want_defaults
      else
        has_tty || die "No terminal for the menu: use --yes, --all or --only"
        pick_menu
      fi ;;
  esac

  local -A skipped=()
  for id in "${SKIP[@]}"; do
    skipped[$id]=1
    if [[ -n "${WANT[$id]:-}" ]]; then STATUS[$id]=skipped; REASON[$id]="--skip"; fi
    unset 'WANT[$id]'
  done

  # Pull in dependencies (unless explicitly skipped), until nothing changes
  local changed=1 d
  while (( changed )); do
    changed=0
    for id in "${!WANT[@]}"; do
      for d in ${MOD_DEPS[$id]}; do
        if [[ -z "${WANT[$d]:-}" && -z "${skipped[$d]:-}" ]]; then
          WANT[$d]=1; AUTO[$d]=1; changed=1
        fi
      done
    done
  done

  # Drop modules whose dependency was skipped. Deps always come earlier, so a
  # single pass in file order also catches chains.
  for id in "${MOD_ORDER[@]}"; do
    [[ -n "${WANT[$id]:-}" ]] || continue
    for d in ${MOD_DEPS[$id]}; do
      if [[ -z "${WANT[$d]:-}" ]]; then
        unset 'WANT[$id]'
        STATUS[$id]=skipped; REASON[$id]="needs $d, which was skipped"
        break
      fi
    done
  done

  for id in "${MOD_ORDER[@]}"; do
    if [[ -n "${WANT[$id]:-}" ]]; then RUN_ORDER+=("$id"); fi
  done
}

# --- Running -----------------------------------------------------------------

# Run a function in a strict, isolated subshell. The result goes in STEP_RC
# (0 ok, 3 skipped, else failed) instead of the return value: calling this
# from `if` or `||` would silently switch off errexit inside the module.
STEP_RC=0
run_step() {
  local id="$1" fn="$2"
  set +e
  (
    set -Eeuo pipefail
    trap 'on_err "$?" "${BASH_SOURCE[0]:-$0}" "$LINENO" "$BASH_COMMAND"' ERR
    MODULE="$id"
    MODULE_TMP="$SETUP_TMP/mod-$id"
    mkdir -p "$MODULE_TMP"
    cd "$HOME"
    "$fn"
  )
  STEP_RC=$?
  set -e
  hash -r
}

run_modules() {
  local id d i=0 n="${#RUN_ORDER[@]}" blocked
  for id in "${RUN_ORDER[@]}"; do
    i=$(( i + 1 ))
    blocked=""
    for d in ${MOD_DEPS[$id]}; do
      if [[ "${STATUS[$d]:-}" != ok ]]; then blocked="$d"; break; fi
    done
    if [[ -n "$blocked" ]]; then
      log "[$i/$n] $id - skipped"
      STATUS[$id]=skipped; REASON[$id]="dependency $blocked ${STATUS[$blocked]:-did not run}"
      warn "${REASON[$id]}"
      continue
    fi

    log "[$i/$n] $id - ${MOD_DESC[$id]}"
    run_step "$id" "${id}_run"
    case "$STEP_RC" in
      0) STATUS[$id]=ok ;;
      # 3 is module_skip only if it left its reason file; a command that
      # failed with exit 3 (unzip, curl, ...) is a real failure
      3) if [[ -f "$RUN_DIR/skip.$id" ]]; then
           STATUS[$id]=skipped; REASON[$id]="$(<"$RUN_DIR/skip.$id")"
         else
           STATUS[$id]=failed; err "$id failed (exit $STEP_RC); continuing with the next module"
         fi ;;
      *) STATUS[$id]=failed; err "$id failed (exit $STEP_RC); continuing with the next module" ;;
    esac
  done
}

# Stop apt from ever installing another display manager. You log in through
# otter-greeter or greetd; anything else (gdm3, sddm...) would compete. Display
# managers that are already installed are left out so their updates still work.
block_display_managers() {
  local dm
  local -a blocked=()
  for dm in gdm3 sddm lightdm lxdm xdm slim wdm nodm ly; do
    pkg_installed "$dm" || blocked+=("$dm")
  done
  (( ${#blocked[@]} )) || return 0
  printf '%s\n' \
    "# Written by ~/.config/setup: no extra display managers (you use otter-greeter or greetd)." \
    "Package: ${blocked[*]}" \
    "Pin: release *" \
    "Pin-Priority: -1" | write_file /etc/apt/preferences.d/99-no-display-managers
}

preflight() {
  apt_update                               # once for the whole run
  apt_install curl ca-certificates gnupg jq
  block_display_managers
}

# Safety net: if the login screen changed without a module meaning to
# (noctalia_greeter records its change), switch it back.
check_display_manager() {
  local before="$1" expected after
  expected="$(cat "$RUN_DIR/dm_expected" 2>/dev/null || printf '%s' "$before")"
  after="$(dm_unit)"
  if is_dry || [[ -z "$expected" || "$after" == "$expected" ]]; then return 0; fi
  warn "Login screen changed to '${after:-none}', restoring '$expected'"
  if ! sudo systemctl enable --force "$expected"; then
    followup manual "Couldn't restore the login screen: run 'sudo systemctl enable --force $expected'"
  fi
}

# --- Logging & cleanup -------------------------------------------------------

LOGGER_PID="" KEEPALIVE_PID="" OUT_FD="" ERR_FD=""

# Output goes to the terminal unchanged and as it comes (progress bars too),
# and to the log file with timestamps, without colours, and with only the
# final state of lines redrawn with \r. awk does the cleanup: a bash pattern
# substitution is so slow on long redrawn lines that the run looked hung.
log_writer() {
  tee >(awk '{ sub(/.*\r/, ""); gsub(/\033\[[0-9;?]*[A-Za-z]/, "")
               print strftime("%F %T"), $0; fflush() }' >>"$1")
  wait "$!"                              # until the log file is written
}

start_logging() {
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/setup-$TS.log"
  ln -sfn "${LOG_FILE##*/}" "$LOG_DIR/latest.log"
  exec {OUT_FD}>&1 {ERR_FD}>&2
  exec > >(log_writer "$LOG_FILE") 2>&1
  LOGGER_PID=$!
}

cleanup() {
  local rc=$? i
  if [[ -n "$KEEPALIVE_PID" ]]; then kill "$KEEPALIVE_PID" 2>/dev/null || true; fi
  if [[ -n "$LOGGER_PID" ]]; then
    exec 1>&"$OUT_FD" 2>&"$ERR_FD"      # close the pipe so the logger drains
    for (( i = 0; i < 10; i++ )); do
      kill -0 "$LOGGER_PID" 2>/dev/null || break
      sleep 0.2
    done
  fi
  if [[ -n "${SETUP_TMP:-}" && -d "$SETUP_TMP" ]]; then rm -rf "$SETUP_TMP"; fi
  exit "$rc"
}

start_sudo() {
  info "Asking for your password once; sudo is used only for commands that need it"
  sudo -v || die "sudo is required"
  # Keep the sudo timestamp fresh until we exit (killed in cleanup)
  ( while sleep 50; do sudo -n true 2>/dev/null || exit 0; done ) >/dev/null 2>&1 &
  KEEPALIVE_PID=$!
}

# --- Summary -----------------------------------------------------------------

print_summary() {
  local id kind text f
  local -a ok_ids=() skip_ids=() fail_ids=()
  for id in "${MOD_ORDER[@]}"; do
    case "${STATUS[$id]:-}" in
      ok)      ok_ids+=("$id") ;;
      skipped) skip_ids+=("$id") ;;
      failed)  fail_ids+=("$id") ;;
    esac
  done

  log "Summary$(is_dry && echo ' (dry run)')"
  printf '%sSucceeded (%d):%s %s\n' "$C_GREEN" "${#ok_ids[@]}" "$C_RESET" "${ok_ids[*]:-–}"
  if (( ${#skip_ids[@]} )); then
    printf '%sSkipped (%d):%s\n' "$C_YELLOW" "${#skip_ids[@]}" "$C_RESET"
    for id in "${skip_ids[@]}"; do printf '  - %s: %s\n' "$id" "${REASON[$id]:-}"; done
  fi
  if (( ${#fail_ids[@]} )); then
    printf '%sFailed (%d):%s\n' "$C_RED" "${#fail_ids[@]}" "$C_RESET"
    for id in "${fail_ids[@]}"; do printf '  - %s (see the log for the failing line)\n' "$id"; done
  fi

  local warned=0
  for f in "$RUN_DIR"/warn.*; do
    [[ -e "$f" ]] || continue
    (( warned )) || printf '%sWarnings:%s\n' "$C_YELLOW" "$C_RESET"
    warned=1
    while IFS= read -r text; do printf '  - %s: %s\n' "${f##*/warn.}" "$text"; done <"$f"
  done

  if [[ -s "$RUN_DIR/followups" ]]; then
    local -A seen=() title=([relogin]="Re-login needed" [reboot]="Reboot needed" [manual]="Manual steps")
    for kind in relogin reboot manual; do
      local -a items=()
      while IFS=$'\t' read -r f text; do
        [[ "$f" == "$kind" && -z "${seen[$text]:-}" ]] || continue
        seen[$text]=1; items+=("$text")
      done <"$RUN_DIR/followups"
      (( ${#items[@]} )) || continue
      printf '\n%s%s:%s\n' "$C_YELLOW" "${title[$kind]}" "$C_RESET"
      printf '  - %s\n' "${items[@]}"
    done
  fi
  printf '\nLog: %s\n' "$LOG_FILE"
  (( ${#fail_ids[@]} == 0 ))
}

# --- Main --------------------------------------------------------------------

main() {
  local id
  parse_args "$@"
  (( EUID != 0 )) || die "Run this as your normal user, not root: \$HOME, user-level installs and file ownership would all be wrong. sudo is used where needed."

  USER_NAME="$(id -un)"
  TS="$(date +%Y%m%d-%H%M%S)"
  load_modules
  if (( LIST )); then list_modules; exit 0; fi

  choose_modules
  if (( ${#RUN_ORDER[@]} == 0 )); then
    warn "Nothing to run"
    for id in "${MOD_ORDER[@]}"; do
      if [[ -n "${REASON[$id]:-}" ]]; then printf '  - %s: %s\n' "$id" "${REASON[$id]}"; fi
    done
    exit 0
  fi

  SETUP_TMP="$(mktemp -d -t setup.XXXXXXXX)"
  RUN_DIR="$SETUP_TMP/run"
  mkdir -p "$RUN_DIR"
  trap cleanup EXIT
  trap 'exit 130' INT TERM

  start_logging
  local -a shown=()
  for id in "${RUN_ORDER[@]}"; do
    if [[ -n "${AUTO[$id]:-}" ]]; then shown+=("$id(+dep)"); else shown+=("$id"); fi
  done
  echo "=== setup $(date '+%F %T')$(is_dry && echo ' (dry run)') ==="
  echo "Modules: ${shown[*]}"

  setup_env
  is_dry || start_sudo

  # From here on nothing reads stdin: a hidden prompt fails instead of
  # hanging. Confirmations and sudo use the terminal directly.
  exec </dev/null

  local dm_before
  dm_before="$(dm_unit)"

  log "preflight - apt update, prerequisites, display-manager pin"
  run_step preflight preflight
  (( STEP_RC == 0 )) || die "Preflight failed; nothing else was run"

  run_modules

  if [[ "${STATUS[shell]:-}" == ok || "${STATUS[runtimes]:-}" == ok ]]; then
    log "shell rc - tool paths in ~/.bashrc and ~/.zshrc"
    run_step shellrc write_shell_env
    (( STEP_RC == 0 )) || err "Updating ~/.bashrc / ~/.zshrc failed"
  fi

  check_display_manager "$dm_before"
  print_summary
}

main "$@"
