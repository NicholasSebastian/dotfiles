#!/usr/bin/python

header_width = 46
label_width = 24

keybind_colour = "#a6e3a1"
desc_colour = "#fab387"

keybinds = {
    "SHORTCUTS": {
        "SUPER + SPACE": "App Launcher",
        "SUPER + E": "File Explorer",
        "SUPER + B": "Zen Browser",
        "SUPER + Q": "Terminal",
        "SUPER + A": "Screenshot",
        "SUPER + L": "Lock Screen",
        "SUPER + DELETE": "Process Viewer",
    },
    "WINDOW CONTROLS": {
        "SUPER + C": "Close Window",
        "SUPER + F": "Fullscreen",
        "SUPER + V": "Toggle Floating",
        "SUPER + J": "Toggle Split",
        "SUPER + O": "Toggle Center",
        "SUPER + P": "Toggle Pseudo",
        "SUPER + ARROW": "Move Current Focus",
        "CTRL + SHIFT + ARROW": "Resize Window",
        "SUPER + SHIFT + NUMBER": "Move Window to Desktop",
        "SUPER + NUMBER": "Navigate to Desktop",
    },
}

stdout: list[str] = []
for header, mappings in keybinds.items():
    if stdout:
        stdout[-1] += "\r"
    indent = int((header_width - len(header)) / 2)
    stdout.append(" " * indent + header)
    for keybind, desc in mappings.items():
        gap = " " * (label_width - len(keybind))
        keybind = f"<span color='{keybind_colour}'>{keybind}</span>"
        desc = f"<span color='{desc_colour}'>{desc}</span>"
        stdout.append(f"{keybind}{gap}{desc}")

print("\r".join(stdout))
