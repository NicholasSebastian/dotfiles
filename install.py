#!/usr/bin/python

# Written by Nicholas Oliver Bahary
# on September 16, 2024.

import os

# Define all directories to stow here.
targets = [
    # "/etc/default/grub.d",
    "$HOME/.profile",
    "$HOME/.config/fastfetch",
    "$HOME/.config/hypr",
    "$HOME/.config/kitty",
    "$HOME/.config/nvim",
    "$HOME/.config/ranger",
    # "$HOME/.config/spicetify/config-xpui.ini",
    "$HOME/.config/waybar",
    "$HOME/.config/zed",
]

# Stow every given directory here.
for target in targets:
    name = os.path.basename(target)
    target = os.popen("echo " + target).read().rstrip()
    if not os.path.exists(name):
        os.system("mv " + target + " .")
    if os.path.isdir(target):
        os.system("mkdir -p " + target)
        os.system("stow " + name + " -t " + target)
    else:
        localfile = os.getcwd() + "/" + name
        os.system("ln -sf " + localfile + " " + target)

