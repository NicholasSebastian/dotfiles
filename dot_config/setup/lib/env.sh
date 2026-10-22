# shellcheck shell=bash
# Environment for this run, and the tool-path block in ~/.bashrc and ~/.zshrc.

# Put every user-level tool dir on PATH before anything runs. Directories
# that don't exist yet are harmless and start working as soon as a module
# creates them (setup.sh runs `hash -r` after each module), so e.g. tools
# from mise in `runtimes` are usable by `dev` in the same run.
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

RC_START='# >>> pikaos-setup >>>'
RC_END='# <<< pikaos-setup <<<'

# The tool-path block for SHELL (bash|zsh): what the runtimes and shell
# modules need in every new terminal, whatever your shell.
env_block() {
  cat <<'EOF'
# --- Tool paths ---
export PNPM_HOME="$HOME/.local/share/pnpm"                     # pnpm add -g
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$PNPM_HOME:$HOME/.dotnet:$HOME/.dotnet/tools:$HOME/.bun/bin:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"
export LIBVIRT_DEFAULT_URI="qemu:///system"                     # virsh sees virt-manager's VMs
EOF
  # shellcheck disable=SC2016  # expanded by the shell that reads the rc file
  printf 'command -v mise >/dev/null && eval "$(mise activate %s)"\n' "$1"
}

# Write the tool-path block into ~/.bashrc and ~/.zshrc (created if missing).
write_shell_env() {
  rc_block "$HOME/.bashrc" "$RC_START" "$RC_END" "$(env_block bash)"
  rc_block "$HOME/.zshrc"  "$RC_START" "$RC_END" "$(env_block zsh)"
}
