local mainMod = "SUPER"

-- Run a dispatcher, then re-apply the scrolling layout's centering rule
-- (scrolling.lua), which the layout's own resize/maximize handling skips.
local function and_center(dispatcher)
    return function()
        hl.dispatch(dispatcher)
        require("scrolling").center_column(hl.get_active_window())
    end
end

-- Mouse Binds
hl.bind(mainMod .. " + " .. "mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + " .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

-- App Shortcuts
hl.bind(mainMod .. " + " .. "SHIFT + B", hl.dsp.exec_cmd("brave-browser"), { description = "Brave" })
hl.bind(mainMod .. " + " .. "Return", hl.dsp.exec_cmd("ghostty"), { description = "Terminal" })
hl.bind(mainMod .. " + " .. "SHIFT + V", hl.dsp.exec_cmd("pwvucontrol"), { description = "Audio Volume Control" })
hl.bind(mainMod .. " + " .. "SHIFT + Q", hl.dsp.exec_cmd("noctalia msg panel-toggle session"), { description = "Logout Menu" })
hl.bind(mainMod .. " + " .. "SHIFT + F", hl.dsp.exec_cmd("nemo"), { description = "File Manager" })
hl.bind(mainMod .. " + " .. "Escape", hl.dsp.exec_cmd("hyprctl reload"), { description = "Reload Hyprland" })

-- Window Controls
hl.bind(mainMod .. " + " .. "S", hl.dsp.window.float(), { description = "Toggle Window Float" })
hl.bind(mainMod .. " + " .. "A", hl.dsp.window.pin(), { description = "Toggle Window Pin" })
hl.bind(mainMod .. " + " .. "Q", hl.dsp.window.close(), { description = "Close Window" })
hl.bind(mainMod .. " + " .. "CONTROL + Q", hl.dsp.exec_cmd("hyprctl kill"), { description = "Kill Window/App" })
hl.bind(mainMod .. " + " .. "F", and_center(hl.dsp.window.fullscreen()), { description = "Toggle Fullscreen" })

-- Audio Controls
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/Pause" })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true, description = "Stop" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous Track" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next Track" })

-- Window Navigation
hl.bind(mainMod .. " + " .. "left", hl.dsp.focus({ direction = "left" }), { description = "Focus Left" })
hl.bind(mainMod .. " + " .. "right", hl.dsp.focus({ direction = "right" }), { description = "Focus Right" })
hl.bind(mainMod .. " + " .. "up", hl.dsp.focus({ direction = "up" }), { description = "Focus Up" })
hl.bind(mainMod .. " + " .. "down", hl.dsp.focus({ direction = "down" }), { description = "Focus Down" })

-- Window Movement
hl.bind(mainMod .. " + " .. "CONTROL + SHIFT + left", hl.dsp.window.move({ workspace = "-1" }), { description = "Move Window to Previous Workspace" })
hl.bind(mainMod .. " + " .. "CONTROL + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }), { description = "Move Window to Next Workspace" })
hl.bind(mainMod .. " + " .. "SHIFT + up", hl.dsp.window.move({ direction = "up" }), { description = "Move Window Up" })
hl.bind(mainMod .. " + " .. "SHIFT + down", hl.dsp.window.move({ direction = "down" }), { description = "Move Window Down" })

-- Workspace Navigation
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

-- Monitor Navigation
hl.bind(mainMod .. " + " .. "CONTROL + up", hl.dsp.focus({ monitor = "l" }), { description = "Focus Monitor Left" })
hl.bind(mainMod .. " + " .. "CONTROL + down", hl.dsp.focus({ monitor = "r" }), { description = "Focus Monitor Right" })

-- Window Resize
hl.bind(mainMod .. " + " .. "ALT + left", and_center(hl.dsp.window.resize({ x = -20, y = 0, relative = true })), { description = "Resize Window Left" })
hl.bind(mainMod .. " + " .. "ALT + right", and_center(hl.dsp.window.resize({ x = 20, y = 0, relative = true })), { description = "Resize Window Right" })
hl.bind(mainMod .. " + " .. "ALT + up", and_center(hl.dsp.window.resize({ x = 0, y = -20, relative = true })), { description = "Resize Window Up" })
hl.bind(mainMod .. " + " .. "ALT + down", and_center(hl.dsp.window.resize({ x = 0, y = 20, relative = true })), { description = "Resize Window Down" })

-- Scrolling layout
hl.bind(mainMod .. " + " .. "SHIFT + left", and_center(hl.dsp.layout("swapcol l")), { description = "Swap Column Left" })
hl.bind(mainMod .. " + " .. "SHIFT + right", and_center(hl.dsp.layout("swapcol r")), { description = "Swap Column Right" })
hl.bind(mainMod .. " + " .. "equal", and_center(hl.dsp.layout("colresize +conf")), { description = "Next Column Width Preset" })
hl.bind(mainMod .. " + " .. "minus", and_center(hl.dsp.layout("colresize -conf")), { description = "Previous Column Width Preset" })
hl.bind(mainMod .. " + " .. "bracketleft", and_center(hl.dsp.layout("consume_or_expel prev")), { description = "Stack Window into Previous Column" })
hl.bind(mainMod .. " + " .. "bracketright", and_center(hl.dsp.layout("promote")), { description = "Move Window to Own Column" })
hl.bind(mainMod .. " + " .. "mouse_down", hl.dsp.layout("move +col"), { description = "Scroll Columns Forward" })
hl.bind(mainMod .. " + " .. "mouse_up", hl.dsp.layout("move -col"), { description = "Scroll Columns Back" })
hl.bind(mainMod .. " + " .. "SHIFT + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Next Workspace on Monitor" })
hl.bind(mainMod .. " + " .. "SHIFT + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous Workspace on Monitor" })

local function focus_edge_column(want_last)
    local active = hl.get_active_window()
    if not active or not active.workspace then return end
    local target, target_idx
    for _, w in ipairs(hl.get_workspace_windows(active.workspace.id)) do
        local layout = w.layout
        if layout and layout.column and layout.index_in_column == 0 then
            local col = layout.column
            if not target_idx or (want_last and col.index > target_idx) or (not want_last and col.index < target_idx) then
                target, target_idx = w, col.index
            end
        end
    end
    if target then hl.dispatch(hl.dsp.focus({ window = "address:" .. target.address })) end
end

-- Focus the first or last column of the focused window's workspace.
hl.bind(mainMod .. " + " .. "Home", function() focus_edge_column(false) end, { description = "Focus First Column" })
hl.bind(mainMod .. " + " .. "End", function() focus_edge_column(true) end, { description = "Focus Last Column" })

-- Windows
hl.bind(mainMod .. " + " .. "M", and_center(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })), { description = "Toggle Maximize" })
hl.bind(mainMod .. " + " .. "CONTROL + SHIFT + up", hl.dsp.window.move({ monitor = "l" }), { description = "Move Window to Left Monitor" })
hl.bind(mainMod .. " + " .. "CONTROL + SHIFT + down", hl.dsp.window.move({ monitor = "r" }), { description = "Move Window to Right Monitor" })
hl.bind(mainMod .. " + " .. "grave", hl.dsp.workspace.toggle_special("scratchpad"), { description = "Toggle Scratchpad" })
hl.bind(mainMod .. " + " .. "SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }), { description = "Send Window to Scratchpad" })

-- Utilities
hl.bind(mainMod .. " + " .. "L", hl.dsp.exec_cmd("noctalia msg session lock"), { description = "Lock Screen" })
hl.bind(mainMod .. " + " .. "V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"), { description = "Clipboard History" })
hl.bind(mainMod .. " + " .. "period", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher '/emo '"), { description = "Emoji Picker" })
hl.bind(mainMod .. " + " .. "SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Color Picker" })
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"), { description = "Screenshot Monitor" })
hl.bind("CONTROL + PRINT", hl.dsp.exec_cmd("noctalia msg screenshot-annotate"), { description = "Annotate Screenshot" })

-- Noctalia keybinds (do...end keeps local variables scoped)
do
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
