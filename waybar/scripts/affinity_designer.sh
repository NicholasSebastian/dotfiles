#!/usr/bin/bash

notify-send "Affinity Designer 2" "Designer launched. Please wait." -i "/home/nicholas/.config/waybar/icons/affinity-designer.svg"

WINE_PREFIX=/home/nicholas/.AffinityLinux
WINE=/home/nicholas/.AffinityLinux/ElementalWarriorWine/bin/wine

export WINEPREFIX="$WINE_PREFIX" 

$WINE "/home/nicholas/.AffinityLinux/drive_c/Program Files/Affinity/Designer 2/Designer.exe"
