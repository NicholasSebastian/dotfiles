hl.config({
    animations = {
        enabled = true,
    },

    decoration = {
        rounding = 16,
        rounding_power = 2,
        inactive_opacity = 0.92,
        blur = {
            enabled = true,
            xray = false,
            size = 2,
            passes = 3,
            new_optimizations = true,
            noise = 0.01,
            contrast = 1.5,
            brightness = 1.0,
        },
        shadow = {
            enabled = true,
            range = 20,
            render_power = 3,
            offset = "0 6",
            color_inactive = "rgba(1A1A1A99)",
            color = "rgba(1A1A1ACC)",
        },
    },
})

-- Border and group colors from Noctalia's palette. Noctalia's Hyprland template
-- generates noctalia.lua (machine-local, not in chezmoi); until it has, the
-- colors above apply. The template's hook looks for this exact require.
local has_noctalia, noctalia = pcall(function() return require("noctalia") end)
if has_noctalia then noctalia.apply_theme() end
