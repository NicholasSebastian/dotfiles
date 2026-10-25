# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=runtimes
MODULE_DESC="C/C++, mise (Node, Go, Bun, Python, uv), Java (Temurin), Rust, .NET"
MODULE_DEFAULT=1
}

runtimes_run() {
  local build_pkgs=(
    build-essential                        # gcc, g++, make
    clang clangd lldb gdb
    cmake ninja-build meson autoconf pkg-config
    libssl-dev libicu-dev                  # libicu is needed by .NET
  )
  apt_install "${build_pkgs[@]}"

  local tools=(
    node@lts
    go@latest
    bun@latest
    python@latest                          # pin e.g. python@3.13 if needed
    uv@latest
    # java@temurin-25                      # older LTS, if a project needs it
    # deno@latest
    # zig@latest
  )
  mise_use "${tools[@]}"

  # Java: Temurin, or OpenJDK of the same version if mise doesn't have Temurin yet
  if have mise && mise ls --global --json 2>/dev/null \
      | jq -e --arg v "$JAVA_VERSION" '.java // [] | any(.installed and ((.requested_version // "") | test("-" + $v + "$")))' >/dev/null; then
    info "mise: Java $JAVA_VERSION already set"
  elif is_dry; then
    cmd "mise use -g java@temurin-$JAVA_VERSION (falls back to java@openjdk-$JAVA_VERSION)"
  elif mise use -g "java@temurin-$JAVA_VERSION"; then
    info "Java: Temurin $JAVA_VERSION"
  else
    warn "Temurin $JAVA_VERSION not available yet, installing OpenJDK $JAVA_VERSION"
    if mise use -g "java@openjdk-$JAVA_VERSION"; then
      followup manual "Switch to Temurin once it's out: mise use -g java@temurin-$JAVA_VERSION"
    else
      soft_fail "Java $JAVA_VERSION: neither Temurin nor OpenJDK found in mise"
    fi
  fi

  # Rust: rustup is the standard installer. --no-modify-path: the managed
  # ~/.zshrc block already puts ~/.cargo/bin on PATH.
  if have rustup; then
    info "rustup already installed (update with: rustup update)"
  else
    install_script https://sh.rustup.rs sh -y --no-modify-path
  fi

  # .NET: Microsoft's install script, user-local in ~/.dotnet
  if [[ -x "$HOME/.dotnet/dotnet" ]]; then
    info ".NET already installed in ~/.dotnet"
  else
    install_script https://dot.net/v1/dotnet-install.sh bash --channel LTS --install-dir "$HOME/.dotnet"
  fi
}
