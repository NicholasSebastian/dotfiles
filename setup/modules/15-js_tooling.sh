# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=js_tooling
MODULE_DESC="pnpm, Oxc (oxlint + oxfmt)"
MODULE_DEFAULT=1
MODULE_DEPS=(runtimes)                   # bun and mise
}

js_tooling_run() {
  mise_use pnpm@latest

  # Global installs are for quick use and editors. Projects should still add
  # them as dev dependencies, as the Oxc docs recommend: pnpm add -D oxlint oxfmt
  local globals=(
    oxlint
    oxfmt
    # @biomejs/biome                       # fallback if a project uses Biome
  )
  local pkg
  local -a todo=()
  for pkg in "${globals[@]}"; do
    if have "${pkg##*/}"; then info "$pkg already installed"; else todo+=("$pkg"); fi
  done
  if (( ${#todo[@]} )); then
    need bun runtimes
    run bun add -g "${todo[@]}"
  fi
}
