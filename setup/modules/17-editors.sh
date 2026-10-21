# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=editors
MODULE_DESC="Zed, Neovim + LazyVim"
MODULE_DEFAULT=1
}

editors_run() {
  # Zed (installs to ~/.local/bin)
  if have zed; then info "Zed already installed"; else install_script https://zed.dev/install.sh sh; fi

  # Neovim + LazyVim. An existing non-LazyVim config is backed up, not deleted.
  local nvim_dir="$HOME/.config/nvim"
  apt_install neovim
  apt_or_mise "tree-sitter-cli|tree-sitter"

  if [[ -f "$nvim_dir/lazyvim.json" || -f "$nvim_dir/lua/config/lazy.lua" ]]; then
    info "LazyVim config already in $nvim_dir"
  else
    if [[ -e "$nvim_dir" ]]; then run mv "$nvim_dir" "$nvim_dir.bak.$TS"; fi
    run git clone --depth 1 https://github.com/LazyVim/starter "$nvim_dir"
    run rm -rf "$nvim_dir/.git"
  fi

  # Optional editors from Flathub
  # flatpak_install com.vscodium.codium    # VS Code without Microsoft telemetry

  followup manual "LazyVim extras you used before: run :LazyExtras and enable lang.typescript, go, rust, java, omnisharp, python, sql, tailwind, docker, astro, svelte. Skip the eslint/prettier extras since you use Oxc."
}
