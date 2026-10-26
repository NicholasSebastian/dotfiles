-- Autostart
hl.on("hyprland.start", function()
    -- Session / dbus
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")

    -- Noctalia shell
    hl.exec_cmd("noctalia")

    -- Desktop helpers
    hl.exec_cmd("xdg-user-dirs-update")
    hl.exec_cmd("pikman-update-manager-autostart")
    hl.exec_cmd("dconf write /org/gnome/desktop/interface/cursor-size 24")
    hl.exec_cmd("gsettings set org.cinnamon.desktop.default-applications.terminal exec ghostty")

    -- EasyEffects (mic noise suppression + EQ): background service, no window
    hl.exec_cmd("flatpak run com.github.wwmm.easyeffects --service-mode --hide-window")

    -- PikaOS welcome
    hl.exec_cmd("pika-welcome-autostart")
end)
