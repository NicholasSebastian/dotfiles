# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=games
MODULE_DESC="Minecraft (official, CurseForge, Modrinth) + emulators"
MODULE_DEFAULT=1
}

games_run() {
  local apps=(
    # Minecraft (CurseForge isn't on Flathub, see below)
    com.mojang.Minecraft                   # official launcher (community-packaged Flatpak)
    com.modrinth.ModrinthApp               # Modrinth App

    # Multi-system: NES, SNES, GB/GBA via mGBA, DS via melonDS, PSP via PPSSPP, Genesis, PS1...)
    # Standalone emulators below are for newer consoles only.
    org.libretro.RetroArch

    # Sony
    net.pcsx2.PCSX2                        # PS2
    net.rpcs3.RPCS3                        # PS3
    # net.shadps4.shadPS4                  # PS4 (early, limited compatibility)

    # Nintendo
    org.DolphinEmu.dolphin-emu             # GameCube + Wii
    info.cemu.Cemu                         # Wii U
    io.github.ryubing.Ryujinx              # Switch (Ryubing, maintained Ryujinx fork)
    org.azahar_emu.Azahar                  # 3DS (Citra successor)

    # Microsoft / Sega
    app.xemu.xemu                          # original Xbox
    # org.flycast.Flycast                  # Dreamcast

    # PC launchers: Steam and Lutris come with PikaOS (Lutris handles Epic/GOG)
    # com.heroicgameslauncher.hgl          # nicer Epic/GOG launcher, if Lutris annoys you
  )
  flatpak_install "${apps[@]}"

  # CurseForge: official .deb (the AppImage can't handle curseforge:// links).
  # No checksum is published; it's fetched over TLS.
  if pkg_installed curseforge; then
    info "CurseForge already installed"
  else
    local deb="$MODULE_TMP/curseforge-latest-linux.deb"
    if download https://curseforge.overwolf.com/downloads/curseforge-latest-linux.deb "$deb"; then
      apt_install "$deb"
    else
      soft_fail "CurseForge download failed. Get it from https://www.curseforge.com/download/app"
    fi
  fi

  followup manual "Emulators need BIOS/firmware/keys from consoles you own (PS2 BIOS, PS3 firmware from Sony, Switch keys)."
  followup manual "PS1: use RetroArch's Beetle PSX or SwanStation core (DuckStation dropped its Flatpak)."
}
