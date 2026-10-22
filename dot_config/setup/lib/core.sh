# shellcheck shell=bash
# Core helpers: output, dry-run, prompts, follow-ups, backups, file writes.
#
# Globals set by setup.sh before any module runs:
#   DRY_RUN FORCE        0/1
#   SETUP_TMP            scratch dir for this run (removed on exit)
#   RUN_DIR              per-run state shared between module subshells
#   MODULE MODULE_TMP    current module id and its scratch dir
#   USER_NAME TS         login name, run timestamp

# --- Output ------------------------------------------------------------------

C_BLUE=$'\e[1;34m'; C_GREEN=$'\e[1;32m'; C_YELLOW=$'\e[1;33m'
C_RED=$'\e[1;31m';  C_DIM=$'\e[2m';      C_RESET=$'\e[0m'

log()  { printf '\n%s==> %s%s\n' "$C_BLUE"   "$*" "$C_RESET"; }
info() { printf '%s  -> %s%s\n'  "$C_GREEN"  "$*" "$C_RESET"; }
warn() { printf '%s  !! %s%s\n'  "$C_YELLOW" "$*" "$C_RESET"; }
err()  { printf '%s  xx %s%s\n'  "$C_RED"    "$*" "$C_RESET"; }
cmd()  { printf '%s  $ %s%s\n'   "$C_DIM"    "$*" "$C_RESET"; }

# Abort the current module (it runs in its own subshell).
die() { err "$*"; exit 1; }

have()   { command -v "$1" >/dev/null 2>&1; }
is_dry() { (( DRY_RUN )); }

# True if WORD is one of the newline-separated LINES.
in_lines() { [[ $'\n'"$2"$'\n' == *$'\n'"$1"$'\n'* ]]; }

# need TOOL MODULE: abort unless TOOL (installed by MODULE) is on PATH.
need() { is_dry || have "$1" || die "$1 isn't available (it comes from the $2 module)"; }

# ERR trap target: on_err RC FILE LINE COMMAND reports where a module failed.
on_err() { err "${2#"$SETUP_DIR/"}:$3: '$4' exited with $1"; }

# --- Running commands --------------------------------------------------------

# Print and run a command; in dry-run, only print it.
run() { cmd "$*"; is_dry || "$@"; }

# Run a command inside a directory without touching the caller's cwd.
run_in() {
  local dir="$1"; shift
  cmd "(cd $dir && $*)"
  is_dry || ( cd "$dir" && "$@" )
}

# Feed text to a command's stdin, e.g. debconf-set-selections.
run_with_input() {
  local input="$1"; shift
  cmd "$* <<< '$input'"
  is_dry || printf '%s\n' "$input" | "$@"
}

# Pipe an upstream install script into an interpreter:
#   install_script URL sh|bash [script args...]
# Upstream publishes no checksums for these scripts; TLS is enforced.
install_script() {
  local url="$1" interp="$2"; shift 2
  cmd "curl -fsSL $url | $interp -s -- $*"
  if is_dry; then return 0; fi
  curl -fsSL --proto '=https' --tlsv1.2 --retry 3 "$url" | "$interp" -s -- "$@"
  hash -r
}

# True when sudo can be used without prompting (never in dry-run).
can_sudo() { ! is_dry && sudo -n true 2>/dev/null; }

# Run as root unless the path is inside $HOME.
as_owner() { if [[ "$1" == "$HOME"/* ]]; then "${@:2}"; else sudo "${@:2}"; fi; }

# --- Module results ----------------------------------------------------------

# A step failed but the module can carry on; listed in the summary.
soft_fail() {
  warn "$*"
  printf '%s\n' "$*" >>"$RUN_DIR/warn.$MODULE"
}

# Stop the module and report it as skipped, not failed.
module_skip() {
  warn "Skipping $MODULE: $*"
  printf '%s\n' "$*" >"$RUN_DIR/skip.$MODULE"
  exit 3
}

# followup relogin|reboot|manual "text"
followup() { printf '%s\t%s\n' "$1" "${*:2}" >>"$RUN_DIR/followups"; }

# --- Prompts -----------------------------------------------------------------
# stdin is /dev/null while modules run, so prompts read the terminal directly.

has_tty() { { : </dev/tty; } 2>/dev/null; }

# The question goes through stdout like all other output, not straight to
# /dev/tty: stdout is piped through the logger, which can lag behind, so a
# direct write could land in the middle of earlier output (e.g. a long diff)
# and the run would look stuck. It ends in a newline so the log file gets it
# as its own line. Only the answer is read from the terminal.
ask_yes_no() {
  local reply
  has_tty || return 1
  printf '%s  ?? %s [y/N]%s\n' "$C_YELLOW" "$1" "$C_RESET"
  IFS= read -r reply </dev/tty || return 1
  printf '  -> answer: %s\n' "${reply:-(none)}"
  [[ "$reply" == [yY]* ]]
}

# ask_choice QUESTION OPTION...: numbered menu; sets CHOICE to the picked
# number. Enter or anything invalid picks 1, so put the safe option first.
# Returns 1 without a terminal.
CHOICE=1
ask_choice() {
  local question="$1" reply i; shift
  has_tty || return 1
  printf '%s  ?? %s%s\n' "$C_YELLOW" "$question" "$C_RESET"
  for (( i = 1; i <= $#; i++ )); do printf '       %d) %s\n' "$i" "${!i}"; done
  printf '%s  ?? choice [1-%d, Enter = 1]%s\n' "$C_YELLOW" "$#" "$C_RESET"
  IFS= read -r reply </dev/tty || return 1
  CHOICE=1
  if [[ "$reply" =~ ^[1-9][0-9]*$ ]] && (( reply <= $# )); then CHOICE=$reply; fi
  printf '  -> answer: %s\n' "${!CHOICE}"
}

# Risky modules call this before changing boot/login/system state. It asks
# even with --yes; only --force skips the question. Declining skips the module.
confirm_risky() {
  warn "$MODULE changes boot, login or system state. It will:"
  printf '       - %s\n' "$@"
  if is_dry; then info "(dry run: would ask for confirmation here)"; return 0; fi
  if (( FORCE )); then info "--force given, not asking"; return 0; fi
  has_tty || module_skip "needs confirmation but there is no terminal (use --force)"
  ask_yes_no "Go ahead with $MODULE?" || module_skip "not confirmed"
}

# A single extra-careful step inside a risky module. Returns 1 if declined.
confirm_step() {
  warn "$1"
  if is_dry || (( FORCE )); then return 0; fi
  ask_yes_no "Do this step?"
}

# --- Files -------------------------------------------------------------------

# Copy a file aside before changing it. Files in $HOME get FILE.setup-bak.TS
# next to them; system files go to /var/backups/setup/<path>.TS, because a
# stray copy inside /etc/apt/sources.list.d, preferences.d etc. makes apt
# complain on every run (and some .d directories would even load it).
backup_file() {
  local file="$1" bak="/var/backups/setup$1.$TS"
  [[ -e "$file" ]] || return 0
  if [[ "$file" == "$HOME"/* ]]; then bak="$file.setup-bak.$TS"; fi
  cmd "cp -a $file $bak"
  if is_dry; then return 0; fi
  as_owner "$file" mkdir -p "${bak%/*}"
  as_owner "$file" cp -a "$file" "$bak"
}

# write_file DEST [MODE] < content
# Writes only when the content differs, backs up the old file first, follows
# symlinks (so stow-managed files stay links), and uses sudo outside $HOME.
# Afterwards, write_changed is true if the file was (or in dry-run would be) written.
WRITE_CHANGED=0
write_changed() { (( WRITE_CHANGED )); }
write_file() {
  local dest="$1" mode="${2:-0644}" tmp
  WRITE_CHANGED=0
  if [[ -L "$dest" ]]; then dest="$(readlink -f "$dest")"; fi
  tmp="$(mktemp -p "$SETUP_TMP")"
  cat >"$tmp"
  if [[ -f "$dest" ]] && cmp -s "$tmp" "$dest"; then
    info "Unchanged: $dest"
    return 0
  fi
  WRITE_CHANGED=1
  info "Writing $dest"
  if is_dry; then
    if [[ -f "$dest" ]]; then
      diff -u "$dest" "$tmp" | sed 's/^/      | /' || true
    elif LC_ALL=C grep -qI '' "$tmp"; then
      sed 's/^/      | /' "$tmp"
    fi
    return 0
  fi
  backup_file "$dest"
  as_owner "$dest" install -D -m "$mode" "$tmp" "$dest"
}

# strip_block FILE START END
# Print FILE without its managed START...END block and trailing blank lines.
strip_block() {
  awk -v s="$2" -v e="$3" '
    $0 == s { skip = 1 }
    !skip   { line[++n] = $0 }
    $0 == e { skip = 0 }
    END {
      while (n > 0 && line[n] ~ /^[[:space:]]*$/) n--
      for (i = 1; i <= n; i++) print line[i]
    }' "$1"
}

# rc_block FILE START END BODY
# Put BODY between the START and END lines of FILE: replaces that block where
# it is (dropping any duplicates), or appends it after a blank line. The rest
# of FILE is kept. Written with write_file (backup, dry-run diff).
rc_block() {
  local file="$1" start="$2" end="$3" body="$4"
  {
    if [[ -f "$file" ]]; then
      # BODY via the environment: awk -v would interpret backslashes
      BODY="$body" awk -v s="$start" -v e="$end" '
        $0 == s { if (!done) { print s; print ENVIRON["BODY"]; print e; done = 1 }; skip = 1; next }
        skip    { if ($0 == e) skip = 0; next }
                { print; last = $0 }
        END {
          if (!done) {
            if (NR && last !~ /^[[:space:]]*$/) print ""
            print s; print ENVIRON["BODY"]; print e
          }
        }' "$file"
    else
      printf '%s\n%s\n%s\n' "$start" "$body" "$end"
    fi
  } | write_file "$file" 0644
}
