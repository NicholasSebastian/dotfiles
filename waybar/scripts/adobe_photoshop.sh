#!/usr/bin/env bash

notify-send "Adobe Photoshop CC" "Photoshop launched. Please wait." -i "/home/nicholas/.config/waybar/icons/adobe-photoshop.svg"

SCR_PATH="/home/nicholas/.photoshopCCV19"
CACHE_PATH="/home/nicholas/.cache/photoshopCCV19"
RESOURCES_PATH="$SCR_PATH/resources"
WINE_PREFIX="$SCR_PATH/prefix"
 
export WINEPREFIX="$WINE_PREFIX"

wine64 "$SCR_PATH/prefix/drive_c/users/$USER/PhotoshopSE/Photoshop.exe"
