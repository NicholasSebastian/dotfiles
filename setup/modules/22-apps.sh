# shellcheck shell=bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] || { echo "Modules are sourced by setup.sh, not run directly." >&2; exit 1; }

# shellcheck disable=SC2034  # header variables are read by setup.sh after sourcing
{
MODULE_ID=apps
MODULE_DESC="Bitwarden, Obsidian, Vesktop, Telegram, EasyEffects, Anki, Bottles, Spotify..."
MODULE_DEFAULT=1
}

apps_run() {
  # (No calculator or video player: Otter ships otter-calc, PikaOS ships mpv.)
  apt_install qbittorrent

  local apps=(
    # Productivity
    com.bitwarden.desktop
    md.obsidian.Obsidian
    net.ankiweb.Anki                       # flashcards
    org.onlyoffice.desktopeditors
    org.localsend.localsend_app

    # Chat
    org.telegram.desktop
    dev.vencord.Vesktop                    # Discord with Vencord + working Wayland screen share
    # com.discordapp.Discord               # official client
    # com.slack.Slack

    # Audio
    com.spotify.Client
    com.github.wwmm.easyeffects            # mic noise suppression + EQ (replaces rnnoise/JamesDSP)

    # System
    com.usebottles.bottles                 # Windows apps, each in its own Wine "bottle"
    com.github.tchx84.Flatseal             # manage Flatpak permissions
    it.mijorus.gearlever                   # manage AppImages (Affinity etc.)
    # org.filezillaproject.Filezilla
    # org.libreoffice.LibreOffice
  )
  flatpak_install "${apps[@]}"

  followup manual "EasyEffects: add the 'Noise Reduction' (RNNoise/DeepFilterNet) effect on your mic input for the old noise-cancelling setup."
}
