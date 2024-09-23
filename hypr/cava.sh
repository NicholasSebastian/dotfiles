#!/bin/sh

# Launches cava overlaying the wallpaper with hyprwinwrap.

hyprpm reload
kitty --class="kitty-bg" --override="background_opacity=0.0" --hold cava
