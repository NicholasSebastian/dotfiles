# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=looking_glass
MODULE_DESC="Build Looking Glass client (needs a second GPU + passthrough)"
MODULE_DEFAULT=0
MODULE_DEPS=(kvm)
}

# Upstream: https://looking-glass.io/docs/stable/build/
looking_glass_run() {
  local bin="$HOME/.local/bin/looking-glass-client"
  if [[ -x "$bin" ]]; then
    info "Looking Glass client already installed ($bin); delete it and re-run to rebuild"
    return 0
  fi

  # The docs' apt list plus libgmp-dev, libxfixes-dev and libwayland-bin,
  # which the docs list as required but leave out of the one-liner.
  # PikaOS uses PipeWire, so the PipeWire libraries are right here.
  local deps=(
    binutils-dev cmake fonts-dejavu-core libfontconfig-dev gcc g++ pkg-config make
    libegl-dev libgl-dev libgles-dev libgmp-dev libspice-protocol-dev nettle-dev
    libx11-dev libxcursor-dev libxfixes-dev libxi-dev libxinerama-dev libxpresent-dev
    libxss-dev libxkbcommon-dev libwayland-bin libwayland-dev wayland-protocols
    libpipewire-0.3-dev libpulse-dev libsamplerate0-dev
  )
  apt_install "${deps[@]}"

  local tarball="$MODULE_TMP/looking-glass.tar.gz" src
  download https://looking-glass.io/artifact/stable/source "$tarball"
  run tar -xzf "$tarball" -C "$MODULE_TMP"
  if is_dry; then
    src="$MODULE_TMP/looking-glass-<version>"
  else
    src="$(find "$MODULE_TMP" -mindepth 1 -maxdepth 1 -type d -name 'looking-glass*' -print -quit)"
    [[ -n "$src" ]] || die "Looking Glass: source folder not found in the tarball"
  fi

  run mkdir -p "$src/client/build"
  run_in "$src/client/build" cmake ..
  run_in "$src/client/build" make -j"$(nproc)"
  run install -D -m 0755 "$src/client/build/looking-glass-client" "$bin"

  followup manual "Looking Glass also needs IOMMU on, a second GPU passed to the VM via VFIO, KVMFR/IVSHMEM shared memory, and the matching host app version in Windows. Guide: https://looking-glass.io/docs"
}
