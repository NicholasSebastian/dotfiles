# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=gamedev
MODULE_DESC="Godot (C#/.NET), Blender, Tiled, Audacity, Aseprite (built from source)"
MODULE_DEFAULT=1
# No deps: the GodotSharp Flatpak bundles its own .NET 8 SDK
}

_gamedev_apps() {
  apt_install blender                      # PikaOS build with GPU compute support

  local apps=(
    org.godotengine.GodotSharp             # Godot with C#/.NET
    # org.godotengine.Godot                # standard Godot (GDScript only)
    # com.unity.UnityHub                   # Unity
    org.mapeditor.Tiled                    # tilemap editor
    org.audacityteam.Audacity              # sound editing
    # com.orama_interactive.Pixelorama     # pixel art
  )
  flatpak_install "${apps[@]}"
}

# --- Aseprite ----------------------------------------------------------------

# Latest release, built with its own build script.
# Upstream: https://github.com/aseprite/aseprite/blob/main/INSTALL.md
_gamedev_aseprite() {
  local dir="$SRC_DIR/aseprite" bin="$SRC_DIR/aseprite/build/bin/aseprite"

  # Build dependencies from INSTALL.md (apt skips what runtimes already installed)
  local deps=(
    g++ clang cmake ninja-build unzip
    libx11-dev libxcursor-dev libxi-dev libxrandr-dev
    libgl1-mesa-dev libfontconfig1-dev
  )
  apt_install "${deps[@]}"

  local tag=""
  if is_dry; then
    if [[ -x "$bin" ]]; then
      info "Built: $(git -C "$dir" describe --tags --exact-match 2>/dev/null || echo 'unknown version'); rebuilds only if the latest release tag differs"
    fi
    cmd "look up the latest aseprite/aseprite release tag"
  else
    tag="$(gh_latest_tag aseprite/aseprite || true)"
    [[ -n "$tag" ]] || die "Couldn't find the latest Aseprite release tag"
    info "Latest Aseprite release: $tag"
    if [[ -x "$bin" ]] && [[ "$(git -C "$dir" describe --tags --exact-match 2>/dev/null || true)" == "$tag" ]]; then
      info "Aseprite $tag is already built"
      return 0
    fi
  fi

  # Source
  if [[ -d "$dir/.git" ]]; then
    run git -C "$dir" fetch --tags
    run git -C "$dir" checkout "${tag:-<latest tag>}"
    run git -C "$dir" submodule update --init --recursive
  else
    run mkdir -p "$SRC_DIR"
    run git clone --recursive --branch "${tag:-<latest tag>}" https://github.com/aseprite/aseprite.git "$dir"
  fi

  # Build with Aseprite's own helper in unattended mode (--auto: release
  # build of the default configuration, --norun: don't launch it). It
  # downloads the exact prebuilt Skia this version needs.
  run_in "$dir" ./build.sh --auto --norun

  # Command and launcher entry
  run mkdir -p "$HOME/.local/bin"
  run ln -sf "$bin" "$HOME/.local/bin/aseprite"
  write_file "$HOME/.local/share/applications/aseprite.desktop" 0644 <<EOF
[Desktop Entry]
Type=Application
Name=Aseprite
Comment=Animated sprite editor and pixel art tool
Exec=$bin %F
Icon=$dir/data/icons/ase256.png
Terminal=false
Categories=Graphics;2DGraphics;RasterGraphics;
MimeType=image/x-aseprite;
EOF

  followup manual "Aseprite's EULA allows building for personal use, not redistributing. Re-run './setup.sh --only gamedev' to update."
}

gamedev_run() {
  _gamedev_apps
  _gamedev_aseprite
}
