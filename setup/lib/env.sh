# shellcheck shell=bash
# Environment for this run, and the managed block in ~/.zshrc.

# Put every user-level tool dir on PATH before anything runs. Directories
# that don't exist yet are harmless and start working as soon as a module
# creates them (setup.sh runs `hash -r` after each module), so e.g. tools
# from mise in `runtimes` are usable by `js_tooling` in the same run.
setup_env() {
  export PNPM_HOME="$HOME/.local/share/pnpm"
  export DOTNET_ROOT="$HOME/.dotnet"
  export MISE_YES=1                        # no interactive mise prompts
  local d
  for d in "$HOME/.dotnet/tools" "$HOME/.dotnet" "$HOME/.bun/bin" "$PNPM_HOME" \
           "$HOME/go/bin" "$HOME/.cargo/bin" \
           "${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims" "$HOME/.local/bin"; do
    [[ ":$PATH:" == *":$d:"* ]] || PATH="$d:$PATH"
  done
  export PATH
}

ZSHRC_START='# >>> pikaos-setup >>>'
ZSHRC_END='# <<< pikaos-setup <<<'

zshrc_block() {
  printf '%s\n' "$ZSHRC_START"
  cat <<'EOF'
# --- Environment ---
export PNPM_HOME="$HOME/.local/share/pnpm"                     # pnpm add -g
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$PNPM_HOME:$HOME/.dotnet:$HOME/.dotnet/tools:$HOME/.bun/bin:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"
export EDITOR=nvim VISUAL=nvim
export LIBVIRT_DEFAULT_URI="qemu:///system"                     # virsh sees virt-manager's VMs
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
command -v mise     >/dev/null && eval "$(mise activate zsh)"
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
  printf '%s\n' "$ZSHRC_END"
}

# Replace the managed block in ~/.zshrc (or add it), keeping everything else.
write_zshrc() {
  local rc="$HOME/.zshrc"
  {
    if [[ -f "$rc" ]]; then strip_block "$rc" "$ZSHRC_START" "$ZSHRC_END" 1; fi
    zshrc_block
  } | write_file "$rc" 0644
}
