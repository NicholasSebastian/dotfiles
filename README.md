# Dotfiles

My personal dotfiles containing all my configurations for my Linux system, development apps, etc.

![Desktop](https://github.com/NicholasSebastian/dotfiles/blob/master/screenshots/screenshot_desktop.jpg)

<table width="100%">
    <tr>
        <td><img src="https://github.com/NicholasSebastian/dotfiles/blob/master/screenshots/screenshot_neovim.jpg"/></td>
        <td><img src="https://github.com/NicholasSebastian/dotfiles/blob/master/screenshots/screenshot_spotify.jpg"/></td>
    </tr>
    <tr>
        <td><img src="https://github.com/NicholasSebastian/dotfiles/blob/master/screenshots/screenshot_steam.jpg"/></td>
        <td><img src="https://github.com/NicholasSebastian/dotfiles/blob/master/screenshots/screenshot_photoshop.jpg"/></td>
    </tr>
</table>

## Prerequisites

Make sure you have the following packages installed for this to work:

```txt
stow
python
```

### Packages

A none exhaustive list of the packages you'll probably wanna have for all this to work the way its expected to:

```txt
hyprland
pyprland
swww
waypaper
waybar
hyprlock
hypridle
mako
rofi
noise-surpression-for-voice
polkit-kde-agent
nm-applet
grim
slurp
hyprpicker
spicetify   # check its website for installation instructions.
kitty
yazi
fish
fastfetch
bat
htop
catppuccin-gtk-theme-mocha   # its in the AUR
lightly-qt
numix-circle-icon-theme-git
```

### Extras

```txt
nwg-look
dconf-editor
qt5ct
qt6ct
kvantum
cava
jamesdsp
asusctltray
zathura
```

### Default Dock Apps

Here is a list of all the apps hardcoded onto the dock.
You don't have to install these but you'll probably want to edit the waybar dock config then.

```txt
pcmanfm
zen-browser
spotify
obs-studio
vesktop
telegram-desktop
whatsapp-web        # web app
adobe-photoshop     # wine
affinity-photo      # wine
affinity-designer   # wine
affinity-publisher  # wine
davinci-resolve
steam
lutris
heroic
neovim
vscodium
zed
docker
wireshark
beekeeper-studio
postman
figma-linux
excalidraw          # web app
qalculate-gtk
obsidian
```

### Installation

I do use GNU stow but in a rather unconventional way.\
Make sure to use the included install.py script because my setup involves mapping Stow to varying target directories.
Maybe I'll tidy it up again in the future. But probably uneccessary as it works the way its supposed to already.

```sh
chmod +x setup.py
./setup.py
```

### Notes to self

#### Pipewire Noise Suppression

The pipewire configuration includes noise suppression using the noise-suppression-for-voice package.\
The config needs the path to librnnoise\_ladspa.so to be specified, which can be found simply with "pacman -Ql noise-suppression-for-voice".

#### Installing the Affinity Suite

##### Manual Installation

Refer to https://codeberg.org/wanesty/affinity-wine-docs/src/branch/guide-wine9.13-part3

##### Automatic Installation

Refer to https://github.com/Twig6943/AffinityOnLinux

```sh
bash -c "$(curl -s https://raw.githubusercontent.com/Twig6943/AffinityOnLinux/main/AffinityScripts/AffinityPhoto.sh)"
bash -c "$(curl -s https://raw.githubusercontent.com/Twig6943/AffinityOnLinux/main/AffinityScripts/AffinityDesigner.sh)"
bash -c "$(curl -s https://raw.githubusercontent.com/Twig6943/AffinityOnLinux/main/AffinityScripts/AffinityPublisher.sh)"
```
