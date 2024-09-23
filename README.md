# Dotfiles

My personal dotfiles containing all my configurations for my Linux system, development apps, etc.

### Prerequisites

Make sure you have the following packages installed for this to work:  
```
stow
python
```

#### Packages

A none exhaustive list of the packages you'll probably wanna have for all this to work the way its expected to:  

```
hyprpaper
hyprlock
hypridle
hyprpicker
swww
waypaper
waybar
mako
rofi
grim
slurp
...the list goes on...

```

### Installation

I do use GNU stow but not in a rather unconventional way.  
Make sure to use the included install.py script because my setup involves a weird mix of Stow and regular symbolic links.
Maybe I'll tidy it up again in the future. But probably uneccessary as it works the way its supposed to already.

```sh
chmod +x setup.py
./setup.py
```

### Notes to self

#### Pipewire Noise Suppression

The pipewire configuration includes noise suppression using the noise-suppression-for-voice package.  
The config needs the path to librnnoise_ladspa.so to be specified, which can be found simply with "pacman -Ql noise-suppression-for-voice".

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
