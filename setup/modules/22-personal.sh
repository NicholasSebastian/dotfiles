# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=personal
MODULE_DESC="Personal taste: Brave/imv/Ghostty as defaults, zsh setup, git settings, keyring settings, reminders"
MODULE_DEFAULT=0
}

# Everything opinionated lives here; the other modules only install things
# and configure them neutrally. Each part checks for the tool it configures,
# so this runs fine on its own (tools that aren't there are skipped).

# --- Default apps ------------------------------------------------------------

# Point PikaOS's Hyprland config ($TERM/$TERMINAL, Nemo's "Open in Terminal")
# at Ghostty instead of otter-term. The cleanup module calls this too, after
# removing otter-term. Files that don't exist are skipped.
_personal_use_ghostty() {
  local hypr="$HOME/.config/hypr" key=org.cinnamon.desktop.default-applications.terminal cur
  if [[ -f "$hypr/env.lua" ]]; then
    sed -e 's/^\([[:space:]]*hl\.env("TERM", \)"otter-term")/\1"xterm-ghostty")/' \
        -e 's/^\([[:space:]]*hl\.env("TERMINAL", \)"otter-term")/\1"ghostty")/' "$hypr/env.lua" \
      | write_file "$hypr/env.lua" 0644
  fi
  if [[ -f "$hypr/exec.lua" ]]; then
    sed 's/\(default-applications\.terminal exec \)otter-term"/\1ghostty"/' "$hypr/exec.lua" \
      | write_file "$hypr/exec.lua" 0644
  fi
  # The live setting too, so it applies before the next login
  if have gsettings && cur="$(gsettings get "$key" exec 2>/dev/null)" && [[ "$cur" != "'ghostty'" ]]; then
    run gsettings set "$key" exec ghostty
  fi
}

_personal_default_apps() {
  # xdg-mime writes ~/.config/mimeapps.list directly. (xdg-settings needs a
  # recognised desktop environment and often fails under Hyprland.)
  if is_dry || have brave-browser; then
    xdg_default brave-browser.desktop \
      x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml
  fi
  # imv for images (otherwise ImageMagick's 'display' opens them)
  if is_dry || [[ -f /usr/share/applications/imv.desktop ]]; then
    xdg_default imv.desktop image/png image/jpeg image/gif image/webp image/bmp image/tiff
  fi
  if is_dry || have ghostty; then _personal_use_ghostty; fi
}

# --- Shell -------------------------------------------------------------------

_PERSONAL_START='# >>> pikaos-setup: personal >>>'
_PERSONAL_END='# <<< pikaos-setup: personal <<<'

# The zsh config that goes below the tool-path block in ~/.zshrc.
_personal_zshrc() {
  cat <<'EOF'
# --- Environment ---
export EDITOR=nvim VISUAL=zed
if command -v bat >/dev/null; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'" MANROFFOPT="-c"
fi

# --- History (shared between terminals, like fish) ---
HISTFILE="$HOME/.zsh_history"; HISTSIZE=50000; SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt AUTO_CD INTERACTIVE_COMMENTS

# --- Completion ---
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'    # case-insensitive
zstyle ':completion:*' menu select

# --- Tools ---
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide   >/dev/null && eval "$(zoxide init zsh --cmd cd)"   # smarter cd
command -v fzf      >/dev/null && source <(fzf --zsh)                  # Ctrl+R, Ctrl+T, Alt+C
[[ -r ~/.config/fzf/themes/noctalia.sh ]] && source ~/.config/fzf/themes/noctalia.sh   # Noctalia colors

# --- Aliases ---
if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -la --icons --git --group-directories-first'
  alias lt='eza -aT --icons --git-ignore --group-directories-first'
fi
command -v bat  >/dev/null && alias cat='bat --paging=never'
command -v btop >/dev/null && alias top='btop'
alias vi='nvim' vim='nvim'
alias lg='lazygit' ld='lazydocker'
alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
alias jctl='journalctl -p 3 -xb'                                # errors from this boot

# --- Fish-style plugins (syntax highlighting must load last) ---
for plugin in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -r "$plugin" ]] && source "$plugin"
done
unset plugin
EOF
  if (( SHELL_GREETING )); then
    printf '\n# --- Greeting ---\n'
    printf '[[ -o interactive ]] && command -v fastfetch >/dev/null && fastfetch\n'
  fi
}

# zsh as login shell, read from the user database ($SHELL only changes after re-login)
_personal_login_shell() {
  local zsh_bin login_shell
  if ! is_dry && ! have zsh; then
    soft_fail "zsh isn't installed (it comes from the shell module); login shell unchanged"
    return 0
  fi
  zsh_bin="$(command -v zsh || echo /usr/bin/zsh)"
  login_shell="$(getent passwd "$USER_NAME" | cut -d: -f7)"
  if [[ "${login_shell##*/}" == zsh ]]; then info "zsh is already your login shell"; return 0; fi
  run sudo chsh -s "$zsh_bin" "$USER_NAME"
  followup relogin "Log out and back in to start using zsh."
}

_personal_shell() {
  if (( SET_ZSH_DEFAULT )); then _personal_login_shell; fi

  # Tool paths first (setup.sh writes them again at the end; then unchanged),
  # so on a fresh ~/.zshrc they come before the personal block
  write_shell_env
  rc_block "$HOME/.zshrc" "$_PERSONAL_START" "$_PERSONAL_END" "$(_personal_zshrc)"
}

# --- Git ---------------------------------------------------------------------

# git's libsecret credential helper: keeps HTTPS passwords/tokens (e.g. your
# GitHub token) in GNOME Keyring. Debian ships only its source, in the git
# package, so it's built here. Absolute path in the git config, so apps
# started without ~/.local/bin on PATH find it too.
_PERSONAL_CRED_HELPER="$HOME/.local/bin/git-credential-libsecret"
_personal_credential_helper() {
  local src=/usr/share/doc/git/contrib/credential/libsecret build="$MODULE_TMP/libsecret"
  if [[ -x "$_PERSONAL_CRED_HELPER" ]]; then info "git libsecret credential helper already built"; return 0; fi
  if [[ ! -f "$src/git-credential-libsecret.c" ]]; then
    soft_fail "git's libsecret helper source isn't in $src; git won't remember your token"
    return 0
  fi
  apt_install libsecret-1-dev gcc make pkg-config
  run cp -r "$src" "$build"                # the source folder is root-owned
  if run_in "$build" make; then
    run install -D -m 0755 "$build/git-credential-libsecret" "$_PERSONAL_CRED_HELPER"
  else
    soft_fail "Building git's libsecret credential helper failed; git won't remember your token"
  fi
}

_personal_git() {
  _personal_credential_helper
  # Git defaults (kept from your old .gitconfig, with modern tweaks).
  # Format: "key value"; everything after the first space is the value.
  local git_settings=(
    "merge.conflictStyle zdiff3"           # diff3, minus the duplicated lines
    "diff.colorMoved default"
    "init.defaultBranch main"
    "pull.rebase true"
    "push.autoSetupRemote true"
    "rerere.enabled true"                  # remember conflict resolutions
  )
  # Only point git at delta if it's actually there, or git log/diff break
  if is_dry || have delta; then
    git_settings+=(
      "core.pager delta"
      "interactive.diffFilter delta --color-only"
      "delta.navigate true"
      "delta.side-by-side true"
    )
  fi
  # Remember HTTPS credentials (e.g. your GitHub token) in GNOME Keyring
  if is_dry || [[ -x "$_PERSONAL_CRED_HELPER" ]]; then
    git_settings+=("credential.helper $_PERSONAL_CRED_HELPER")
  fi
  # Only fills in keys you haven't set, so re-runs never undo your own changes
  local setting key
  for setting in "${git_settings[@]}"; do
    key="${setting%% *}"
    if git config --global --get "$key" >/dev/null; then continue; fi
    run git config --global "$key" "${setting#* }"
  done

  if ! git config --global user.name >/dev/null; then
    followup manual "Set your git identity: git config --global user.name '...' && git config --global user.email '...'"
  fi
  # No GitHub credential saved yet (fill fails instead of prompting)
  if [[ "$(git config --global --get credential.helper || true)" == "$_PERSONAL_CRED_HELPER" ]] || is_dry; then
    if ! printf 'protocol=https\nhost=github.com\n\n' | GIT_TERMINAL_PROMPT=0 git credential fill >/dev/null 2>&1; then
      followup manual "Git saves HTTPS credentials in GNOME Keyring: the next push to GitHub asks for your username and a personal access token (github.com/settings/tokens) once, then never again."
    fi
  fi
  if have gh && ! gh auth token >/dev/null 2>&1; then  # local check, no network
    followup manual "Run 'gh auth login' to use the GitHub CLI (choose HTTPS, and answer No to 'Authenticate Git with your GitHub credentials' so git keeps using the keyring)."
  fi
}

# --- Keyring -----------------------------------------------------------------

# GNOME Keyring unlocked by your login password (PAM), so apps stop asking for
# a separate keyring password. PAM only unlocks the keyring named "login".
_PERSONAL_KEYRING_CHANGED=0

# Each login service gets pam_gnome_keyring in its auth stack (grabs the
# password) and session stack (starts the daemon and unlocks). Appended lines
# run after common-auth/common-session, which is the order it needs. They're
# 'optional', so they can never make a login fail, and '-' skips them quietly
# if the module is missing. Services whose package already has the lines
# (greetd, otter-greeter) are left alone.
_personal_keyring_pam() {
  apt_install gnome-keyring libpam-gnome-keyring

  # password stack: keeps the keyring password in step when you change yours
  if ! grep -qE '^[[:space:]]*-?password[[:space:]].*pam_gnome_keyring\.so' /etc/pam.d/common-password; then
    if is_dry || [[ -f /usr/share/pam-configs/gnome-keyring ]]; then
      run sudo pam-auth-update --enable gnome-keyring
      _PERSONAL_KEYRING_CHANGED=1
    else
      soft_fail "pam-auth-update has no gnome-keyring profile; the keyring password won't follow password changes"
    fi
  fi

  local svc f rest body
  for svc in greetd login otter-greeter; do
    f="/etc/pam.d/$svc"
    [[ -f "$f" ]] || continue
    rest="$(strip_block "$f" "$_PERSONAL_START" "$_PERSONAL_END")"
    body=""
    if ! grep -qE '^[[:space:]]*-?auth[[:space:]].*pam_gnome_keyring\.so' <<<"$rest"; then
      body+="-auth     optional  pam_gnome_keyring.so"$'\n'
    fi
    if ! grep -qE '^[[:space:]]*-?session[[:space:]].*pam_gnome_keyring\.so' <<<"$rest"; then
      body+="-session  optional  pam_gnome_keyring.so auto_start"$'\n'
    fi
    body="${body%$'\n'}"
    if [[ -n "$body" ]]; then
      if [[ "$(block_body "$f" "$_PERSONAL_START" "$_PERSONAL_END")" == "$body" ]]; then
        info "$f already unlocks the keyring at login"
      else
        rc_block "$f" "$_PERSONAL_START" "$_PERSONAL_END" "$body"
        _PERSONAL_KEYRING_CHANGED=1
      fi
    elif grep -qxF "$_PERSONAL_START" "$f"; then
      # The package added its own lines; ours are redundant now
      strip_block "$f" "$_PERSONAL_START" "$_PERSONAL_END" | write_file "$f" 0644
      _PERSONAL_KEYRING_CHANGED=1
    else
      info "$f already unlocks the keyring at login"
    fi
  done
}

# New secrets should go to "login" (the one PAM unlocks), not a second
# keyring with its own password. The old keyring is left as it is.
_personal_keyring_default() {
  local kr="$HOME/.local/share/keyrings"
  # No file: gnome-keyring uses "login" anyway
  if [[ -f "$kr/default" && "$(<"$kr/default")" != login ]]; then
    printf 'login' | write_file "$kr/default" 0600   # no newline, like gnome-keyring
    _PERSONAL_KEYRING_CHANGED=1
    if [[ -f "$kr/Default.keyring" ]]; then
      followup manual "Keyring: new secrets now go to the 'Login' keyring, which your login unlocks. Your old 'Default' keyring still has a separate password: next time it asks, tick 'Automatically unlock this keyring whenever I'm logged in' (it stores that password in Login), or re-save those passwords and delete 'Default' in Passwords and Keys (seahorse)."
    fi
  fi
}

_personal_keyring() {
  _personal_keyring_pam
  _personal_keyring_default
  if (( _PERSONAL_KEYRING_CHANGED )); then
    followup relogin "Keyring: log out and back in so it unlocks with your login password."
  fi
}

# --- Reminders ---------------------------------------------------------------

_personal_reminders() {
  if is_dry || compgen -G "$HOME/.local/share/fonts/JetBrainsMonoNerd/*.ttf" >/dev/null; then
    followup manual "Set 'JetBrainsMono Nerd Font' in your terminal and Zed."
  fi
  if is_dry || [[ -f "$HOME/.config/nvim/lazyvim.json" || -f "$HOME/.config/nvim/lua/config/lazy.lua" ]]; then
    followup manual "LazyVim extras you used before: run :LazyExtras and enable lang.typescript, go, rust, java, omnisharp, python, sql, tailwind, docker, astro, svelte. Skip the eslint/prettier extras since you use Oxc."
  fi
  if is_dry || flatpak_installed com.github.wwmm.easyeffects; then
    followup manual "EasyEffects: add the 'Noise Reduction' (RNNoise/DeepFilterNet) effect on your mic input for the old noise-cancelling setup."
  fi
}

personal_run() {
  _personal_default_apps
  _personal_shell
  _personal_git
  _personal_keyring
  _personal_reminders
}
