local mainMod = "SUPER"

-- Mouse Binds
hl.bind(mainMod .. " + " .. "mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + " .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + " .. "SHIFT + B", hl.dsp.exec_cmd("brave-browser"), { description = "Brave" })
hl.bind(mainMod .. " + " .. "Return", hl.dsp.exec_cmd("ghostty"), { description = "Terminal" })
hl.bind(mainMod .. " + " .. "SHIFT + V", hl.dsp.exec_cmd("pwvucontrol"), { description = "Audio Volume Control" })
hl.bind(mainMod .. " + " .. "SHIFT + Q", hl.dsp.exec_cmd("noctalia msg panel-toggle session"),
    { description = "Logout Menu" })
hl.bind(mainMod .. " + " .. "SHIFT + F", hl.dsp.exec_cmd("nemo"), { description = "File Manager" })
hl.bind(mainMod .. " + " .. "Escape", hl.dsp.exec_cmd("hyprctl reload"), { description = "Reload Hyprland" })

hl.bind(mainMod .. " + " .. "S", hl.dsp.window.float(), { description = "Toggle Window Float" })
hl.bind(mainMod .. " + " .. "A", hl.dsp.window.pin(), { description = "Toggle Window Pin" })
hl.bind(mainMod .. " + " .. "Q", hl.dsp.window.close(), { description = "Close Window" })
hl.bind(mainMod .. " + " .. "CONTROL + Q", hl.dsp.exec_cmd("hyprctl kill"), { description = "Kill Window/App" })
hl.bind(mainMod .. " + " .. "F", hl.dsp.window.fullscreen(), { description = "Toggle Fullscreen" })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/Pause" })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true, description = "Stop" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous Track" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next Track" })

hl.bind(mainMod .. " + " .. "left", hl.dsp.focus({ direction = "left" }), { description = "Focus Left" })
hl.bind(mainMod .. " + " .. "right", hl.dsp.focus({ direction = "right" }), { description = "Focus Right" })
hl.bind(mainMod .. " + " .. "up", hl.dsp.focus({ direction = "up" }), { description = "Focus Up" })
hl.bind(mainMod .. " + " .. "down", hl.dsp.focus({ direction = "down" }), { description = "Focus Down" })

hl.bind(mainMod .. " + " .. "SHIFT + left", hl.dsp.window.move({ workspace = "-1" }),
    { description = "Move Window to Previous Workspace" })
hl.bind(mainMod .. " + " .. "SHIFT + right", hl.dsp.window.move({ workspace = "+1" }),
    { description = "Move Window to Next Workspace" })
hl.bind(mainMod .. " + " .. "SHIFT + up", hl.dsp.window.move({ direction = "up" }), { description = "Move Window Up" })
hl.bind(mainMod .. " + " .. "SHIFT + down", hl.dsp.window.move({ direction = "down" }),
    { description = "Move Window Down" })
hl.bind(mainMod .. " + " .. "CONTROL + left", hl.dsp.focus({ workspace = "-1" }), { description = "Previous Workspace" })
hl.bind(mainMod .. " + " .. "CONTROL + right", hl.dsp.focus({ workspace = "+1" }), { description = "Next Workspace" })

-- Stock Hyprland workspace binds: SUPER+1..0 switch, SUPER+SHIFT+1..0 move
for i = 1, 10 do
    local n = tostring(i)
    if n == "10" then n = "0" end
    local ws = tostring(i)
    hl.bind(mainMod .. " + " .. n, hl.dsp.focus({ workspace = ws }),
        { description = "Workspace " .. i })
    hl.bind(mainMod .. " + " .. "SHIFT + " .. n, hl.dsp.window.move({ workspace = ws }),
        { description = "Move Window to Workspace " .. i })
end

hl.bind(mainMod .. " + " .. "CONTROL + up", hl.dsp.focus({ monitor = "l" }), { description = "Focus Monitor Left" })
hl.bind(mainMod .. " + " .. "CONTROL + down", hl.dsp.focus({ monitor = "r" }), { description = "Focus Monitor Right" })
hl.bind(mainMod .. " + " .. "ALT + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }),
    { description = "Resize Window Left" })
hl.bind(mainMod .. " + " .. "ALT + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }),
    { description = "Resize Window Right" })
hl.bind(mainMod .. " + " .. "ALT + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }),
    { description = "Resize Window Up" })
hl.bind(mainMod .. " + " .. "ALT + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }),
    { description = "Resize Window Down" })

-- >>> pikaos-setup: noctalia >>>
-- Noctalia keybinds (do...end keeps these locals from clashing with yours)
do
    local mainMod = "SUPER"
    local ipc = "noctalia msg "
    hl.bind(mainMod .. "+Space", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
    hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
    hl.bind(mainMod .. "+comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
    hl.bind("ALT + Tab", hl.dsp.exec_cmd(ipc .. "window-switcher"))
    hl.bind("PRINT", hl.dsp.exec_cmd(ipc .. "screenshot-region"))
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"))
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"))
    hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"))
    hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"))
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"))
end
-- <<< pikaos-setup: noctalia <<<
