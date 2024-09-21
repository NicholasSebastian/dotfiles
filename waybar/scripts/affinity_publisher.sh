#!/usr/bin/bash

notify-send "Affinity Publisher 2" "Publisher launched. Please wait." -i "/home/nicholas/.config/waybar/icons/affinity-publisher.svg"

WINE_PREFIX=/home/nicholas/.AffinityLinux
WINE=/home/nicholas/.AffinityLinux/ElementalWarriorWine/bin/wine

export WINEPREFIX="$WINE_PREFIX" 

$WINE "/home/nicholas/.AffinityLinux/drive_c/Program Files/Affinity/Publisher 2/Publisher.exe"
