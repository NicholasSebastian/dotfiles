# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=gamedev
MODULE_DESC="Godot (C#/.NET), Blender, Tiled, Audacity"
MODULE_DEFAULT=1
MODULE_DEPS=()                           # the GodotSharp Flatpak bundles its own .NET 8 SDK
}

gamedev_run() {
  apt_install blender                      # PikaOS build with GPU compute support

  local apps=(
    org.godotengine.GodotSharp             # Godot with C#/.NET
    org.mapeditor.Tiled                    # tilemap editor
    org.audacityteam.Audacity              # sound editing
    # org.godotengine.Godot                # standard Godot (GDScript only)
    # com.orama_interactive.Pixelorama     # pixel art
    # com.unity.UnityHub                   # Unity
  )
  flatpak_install "${apps[@]}"
}
