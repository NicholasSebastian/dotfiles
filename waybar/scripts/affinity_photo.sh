#!/usr/bin/bash

notify-send "Affinity Photo 2" "Photo launched. Please wait." -i "/home/nicholas/.config/waybar/icons/affinity-photo.svg"

WINE_PREFIX=/home/nicholas/.AffinityLinux
WINE=/home/nicholas/.AffinityLinux/ElementalWarriorWine/bin/wine

export WINEPREFIX="$WINE_PREFIX" 

$WINE "/home/nicholas/.AffinityLinux/drive_c/Program Files/Affinity/Photo 2/Photo.exe"
