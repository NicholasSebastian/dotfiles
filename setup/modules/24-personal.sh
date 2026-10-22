# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=personal
MODULE_DESC="Personal taste: Brave/imv/Ghostty as defaults, zsh setup, git settings + keyring, reminders"
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

# --- Reminders ---------------------------------------------------------------

_personal_reminders() {
  if is_dry || compgen -G "$HOME/.local/share/fonts/JetBrainsMonoNerd/*.ttf" >/dev/null; then
    followup manual "Set 'JetBrainsMono Nerd Font' in your terminal and Zed."
  fi
  if is_dry || [[ -f "$HOME/.config/nvim/lazyvim.json" || -f "$HOME/.config/nvim/lua/config/lazy.lua" ]]; then
    followup manual "LazyVim extras you used before: run :LazyExtras and enable lang.typescript, go, rust, java, omnisharp, python, sql, tailwind, docker, astro, svelte. Skip the eslint/prettier extras since you use Oxc."
  fi
  if is_dry || flatpak info --system com.github.wwmm.easyeffects >/dev/null 2>&1; then
    followup manual "EasyEffects: add the 'Noise Reduction' (RNNoise/DeepFilterNet) effect on your mic input for the old noise-cancelling setup."
  fi
}

personal_run() {
  _personal_default_apps
  _personal_shell
  _personal_git
  _personal_reminders
}
