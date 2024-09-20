#!/usr/bin/env sh

# Terminate already running bar instances
killall -q waybar

# Wait until the processes have been shut down
while pgrep -x waybar >/dev/null; do sleep 1; done

# Update the waybar stylesheets
sass ~/.config/waybar/styles/index.scss ~/.config/waybar/style.css

# Launch main
waybar
