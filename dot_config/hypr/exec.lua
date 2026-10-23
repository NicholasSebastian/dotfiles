-- Autostart
hl.on("hyprland.start", function()
    -- Session / dbus
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY")
    hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    hl.exec_cmd("noctalia")

    -- Desktop helpers
    hl.exec_cmd("xdg-user-dirs-update")
    hl.exec_cmd("pikman-update-manager-autostart")
    hl.exec_cmd("dconf write /org/gnome/desktop/interface/cursor-size 24")
    hl.exec_cmd("gsettings set org.cinnamon.desktop.default-applications.terminal exec ghostty")

    -- PikaOS welcome
    hl.exec_cmd("pika-welcome-autostart")
end)
