# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=shell
MODULE_DESC="zsh + plugins, Starship, modern CLI tools, fastfetch, lazygit, lazydocker, stow"
MODULE_DEFAULT=1
}

# The ~/.zshrc block itself is written once by setup.sh at the end of the run
# (after shell and/or runtimes), see lib/env.sh.
shell_run() {
  local tools=(
    "zsh"
    "zsh-autosuggestions"                  # fish-style suggestions as you type
    "zsh-syntax-highlighting"              # fish-style command colouring
    "tmux"                                 # or swap for "|zellij"; one multiplexer is enough
    "starship|starship"
    "fastfetch|fastfetch"
    "ripgrep|ripgrep"
    "fd-find|fd"
    "bat|bat"
    "eza|eza"
    "fzf|fzf"
    "zoxide|zoxide"
    "yazi|yazi"                            # terminal file manager
    "btop|btop"
    "du-dust|dust"                         # disk usage
    "tealdeer"                             # tldr
    "lazygit|lazygit"
    "|lazydocker"
    "|gum"
    "stow"                                 # symlink your dotfiles into place
  )
  apt_or_mise "${tools[@]}"

  # Debian ships bat and fd as batcat and fdfind
  local pair real alias_name
  for pair in batcat:bat fdfind:fd; do
    real="${pair%%:*}"; alias_name="${pair#*:}"
    if have "$real" && ! have "$alias_name"; then
      run mkdir -p "$HOME/.local/bin"
      run ln -sf "$(command -v "$real")" "$HOME/.local/bin/$alias_name"
    fi
  done

  # tldr pages: download once; tealdeer keeps them fresh itself after that
  if have tldr && [[ ! -d "${XDG_CACHE_HOME:-$HOME/.cache}/tealdeer/tldr-pages" ]]; then
    run tldr --update || soft_fail "tldr --update failed"
  fi

  # Login shell, read from the user database ($SHELL only changes after re-login)
  if (( SET_ZSH_DEFAULT )); then
    local zsh_bin login_shell
    zsh_bin="$(command -v zsh || echo /usr/bin/zsh)"
    login_shell="$(getent passwd "$USER_NAME" | cut -d: -f7)"
    if [[ "${login_shell##*/}" != zsh ]]; then
      run sudo chsh -s "$zsh_bin" "$USER_NAME"
      followup relogin "Log out and back in to start using zsh."
    else
      info "zsh is already your login shell"
    fi
  fi
}
