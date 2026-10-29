<div align="center">

# 🏠 dotfiles

**My PikaOS + Hyprland + Noctalia desktop, managed with [chezmoi](https://www.chezmoi.io/), plus a modular post-install setup script.**

![PikaOS](https://img.shields.io/badge/PikaOS-Hyprland-1793d1?style=flat-square)
![Noctalia](https://img.shields.io/badge/shell-Noctalia-a6e3a1?style=flat-square)
![chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-4b8bbe?style=flat-square)
![Bash](https://img.shields.io/badge/setup-bash-4eaa25?style=flat-square&logo=gnubash&logoColor=white)

</div>

> [!NOTE]
> These are my personal dotfiles, built for **my own machines and my own taste**. You're
> free to use, fork, or borrow anything from here, but nothing is guaranteed to work outside
> my setup. Read before you run.

> [!IMPORTANT]
> **About the setup script:** `setup/` is vibe coded, written with AI coding agents. It is
> *not* a one-shot dump, though: it has been built up incrementally, painstakingly
> reviewed and maintained over many iterations, and mixed with plenty of manual touch-ups.

## Contents

- [What's inside](#whats-inside)
- [Quick start (fresh install)](#quick-start-fresh-install)
- [Dotfiles only](#dotfiles-only)
- [The setup script](#the-setup-script)
- [Modules](#modules)
- [Configuration](#configuration)
- [Per-machine templates](#per-machine-templates)
- [Theming](#theming)
- [Repository layout](#repository-layout)
- [Roadmap](#roadmap)

## What's inside

| Area | What |
| --- | --- |
| Desktop | [Hyprland](https://hyprland.org/) (Lua config) with the [Noctalia](https://docs.noctalia.dev/) shell, bar, dock and greeter |
| Terminal | Ghostty, tmux, zsh / bash, Starship |
| Editors | Neovim, Zed |
| CLI tools | bat, btop, yazi, fastfetch |
| Apps | Zathura, Vesktop, Spicetify (Spotify) |
| Theming | GTK 3/4, Qt6 (qt6ct), all coloured from Noctalia's palette |
| AI agents | Claude Code and Oh My Pi settings, shared agent skills in `~/.agents/skills` |
| Wallpapers | `~/wallpapers` (Noctalia's wallpaper folder) |
| Setup | `setup/`: modular post-install script for PikaOS |

## Quick start (fresh install)

Target: a fresh **PikaOS (Hyprland edition)** install.

```bash
# 1. Update the system first
pikman upgrade

# 2. Clone straight into chezmoi's source directory
git clone https://github.com/NicholasSebastian/dotfiles.git ~/.local/share/chezmoi

# 3. Run the setup script as your normal user (not root; it uses sudo where needed)
bash ~/.local/share/chezmoi/setup/executable_setup.sh
```

A checklist opens with the default modules ticked. The `dotfiles` module installs chezmoi
and applies this repo. Files it would overwrite are backed up first as
`FILE.setup-bak.<timestamp>`. A summary at the end lists anything that still needs a reboot
or a manual step.

> [!TIP]
> Try `--dry-run` first: it shows what would happen with no sudo, no network and no changes.

## Dotfiles only

Don't want the setup script? Use chezmoi on its own:

```bash
chezmoi init --apply NicholasSebastian/dotfiles
```

Day to day:

```bash
chezmoi edit ~/.config/hypr/keybinds.lua   # edit the source copy
chezmoi diff                               # preview changes
chezmoi apply                              # write them to $HOME
chezmoi update                             # pull + apply
```

## The setup script

Once the dotfiles are applied, the script also lives at `~/setup/setup.sh`.

```text
setup.sh [options] [module...]

  (no options)      choose modules from a checklist (defaults pre-ticked)
  --all             run every module
  --only a,b        run only these modules (plus what they depend on)
  --skip a,b        leave these out (modules that need them are skipped too)
  --yes, -y         no menu: run the default modules (or --only/--all ones)
  --force           don't ask before risky modules
  --dry-run         show what would happen; no sudo, no network, no changes
  --list            list modules with defaults and dependencies
  -h, --help        help
```

Examples:

```bash
./setup.sh --list                 # see every module
./setup.sh --only dev,ai          # just these (plus dependencies)
./setup.sh noctalia_greeter       # bare names work like --only
./setup.sh -y --skip games        # defaults, no menu, without games
```

- Modules are idempotent: re-running one is the usual way to update or finish it.
- Risky modules (⚠️ below) ask for confirmation unless `--force` is given. `cleanup` always asks.
- Logs go to `~/.local/state/setup/`.

## Modules

Each module is a file in `setup/modules/NN-<id>.sh`. Package lists live inside the
modules: comment out a line to drop an item.

| Module | Default | Description |
| --- | :---: | --- |
| `base` | ✅ | Core packages, Flatpak + Flathub, archive formats, firmware updates, rclone |
| `clock` ⚠️ | | Hardware clock in local time (dual-boot with Windows) |
| `snapshots` | ✅ | Timeshift snapshots + ufw firewall |
| `secure_boot` ⚠️ | | Sign kernel + rEFInd with your own keys (sbctl), per the PikaOS wiki |
| `runtimes` | ✅ | C/C++, mise (Node, Go, Bun, Python, uv), Java (Temurin), Rust, .NET |
| `shell` | ✅ | zsh + plugins, Starship, modern CLI tools, fastfetch, lazygit, lazydocker |
| `hyprland` | ✅ | What Otter/PikaOS don't ship: image viewer, audio mixer, media keys, clipboard CLI |
| `noctalia` ⚠️ | ✅ | Switch the desktop shell to Noctalia + GTK/Qt theming |
| `noctalia_greeter` ⚠️ | ✅ | Noctalia Greeter (greetd) login screen, synced to Noctalia's look · needs `noctalia` |
| `laptop` | | ASUS ROG tools (asusctl, ROG Control Center, supergfxctl), OpenLogi |
| `fonts` | ✅ | JetBrains Mono + Iosevka Nerd Fonts, Noto, emoji, CJK, Microsoft core fonts |
| `input_method` | | Fcitx5 for typing Chinese/Japanese |
| `dev` | ✅ | Docker, GitHub CLI, Bruno, Beekeeper, pnpm + Oxc, Zed, Neovim, JetBrains IDEs, etc. · needs `runtimes` |
| `ai` | ✅ | Claude Code, Oh My Pi, Hermes Agent, Ollama (+ optional Open WebUI), LM Studio Bionic, ComfyUI (CLI + Desktop), Upscayl · needs `runtimes` |
| `apps` | ✅ | Brave + Chrome, Bitwarden, Obsidian, LocalSend, Discord, Telegram, Spotify, Affinity, etc. |
| `photogimp` | ✅ | PhotoGIMP patch for GIMP (open and close GIMP once first) · needs `apps` |
| `games` | ✅ | Minecraft (official, CurseForge, Modrinth) + emulators |
| `gamedev` | ✅ | Godot (C#/.NET), Blender, Tiled, Audacity, Aseprite (built from source) |
| `kvm` ⚠️ | ✅ | KVM/QEMU + libvirt + virt-manager, UEFI + TPM for Windows 11, virtio drivers |
| `looking_glass` | | Build the Looking Glass client (needs a second GPU + passthrough) · needs `kvm` |
| `dotfiles` | ✅ | Apply these dotfiles with chezmoi, then hook Noctalia's colours into apps · needs `noctalia` |
| `personal` | | My taste: default apps, zsh as login shell, git and keyring settings, reminders |
| `drives` ⚠️ | ✅ | Choose drives to mount at boot (`/etc/fstab`, `/mnt/<label>`) |
| `plymouth` | | Boot splash: adi1090x "splash" Plymouth theme |
| `refind` ⚠️ | | rEFInd boot menu: config, kernel options and rEFInd-lite theme |
| `cleanup` ⚠️ | ✅ | Offer to remove duplicates: Otter leftovers, extra file managers, Chromium, GNOME leftovers |

## Configuration

Defaults live in [`setup/config.sh`](setup/config.sh). Any of them can be overridden for a
single run from the environment:

```bash
OPEN_WEBUI=1 ./setup.sh --only ai
```

| Variable | Default | Meaning |
| --- | --- | --- |
| `JAVA_VERSION` | `27` | Temurin major version (falls back to OpenJDK) |
| `SET_ZSH_DEFAULT` | `1` | `personal`: make zsh the login shell |
| `SHELL_GREETING` | `1` | `personal`: run fastfetch when a terminal opens |
| `OPEN_WEBUI` | `0` | `ai`: run Open WebUI in Docker for Ollama |
| `DOTFILES_REPO` | this repo | Repo `dotfiles` clones on a new machine |
| `AI_DIR` | `~/AI` | ComfyUI workspace |
| `APPS_DIR` | `~/Applications` | AppImages |
| `SRC_DIR` | `~/src` | Source builds (Aseprite) |
| `VM_DIR` | `~/VMs` | virtio driver ISO |
| `LOG_DIR` | `~/.local/state/setup` | Run logs |

## Per-machine templates

Monitor layout, Noctalia bar and dock differ per machine. chezmoi picks the file named after
the machine's hostname and falls back to `default`:

```text
.chezmoitemplates/
├── hypr-monitors/   default.lua   nicholas-pc.lua
├── noctalia-bar/    default.toml  nicholas-pc.toml
└── noctalia-dock/   default.toml  nicholas-pc.toml
```

New machine: copy `default.*` to `<hostname>.*` in each folder and adjust it.

## Theming

Colours come from Noctalia's palette (generated from the wallpaper). Noctalia renders theme
files for Ghostty, tmux, Neovim, Zed, bat, btop, yazi, Zathura, GTK, Qt, Vesktop, Spicetify,
fastfetch, Claude Code and Oh My Pi on every palette change. Those generated files are listed
in [`.chezmoiignore`](.chezmoiignore) so chezmoi never fights over them. The `dotfiles`
module also selects the Noctalia theme in apps that need a setting for it.

## Repository layout

```text
.
├── dot_config/          → ~/.config (hypr, noctalia, ghostty, nvim, zed, tmux, …)
├── dot_zshrc, dot_bashrc
├── dot_claude/          → ~/.claude (Claude Code settings)
├── dot_omp/             → ~/.omp (Oh My Pi config)
├── dot_agents/skills/   → ~/.agents/skills (agent skills)
├── wallpapers/          → ~/wallpapers
├── .chezmoitemplates/   per-machine templates
└── setup/
    ├── executable_setup.sh   entry point
    ├── config.sh             settings
    ├── lib/                  shared helpers (packages, GitHub releases, env)
    ├── modules/              one file per module
    └── files/                assets (Plymouth theme, rEFInd theme, greeter)
```

## Roadmap

- [ ] Add `dot_agents/agents`, then symlink `dot_claude/agents` to it.
- [ ] Define agents for `dot_omp/agent/agents` (written slightly differently from Claude's).
