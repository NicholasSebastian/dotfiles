#!/usr/bin/bash

# Start the swww daemon.
swww-daemon &

# Wait for the daemon to finish initializing.
BACK_PID=$!
wait $BACK_PID

# Set the wallpaper for the monitors.
swww img -o eDP-1,HDMI-A-1 '/mnt/data/Pictures/Archcraft Wallpapers/archcraft-backgrounds/files/mocha.jpg'

