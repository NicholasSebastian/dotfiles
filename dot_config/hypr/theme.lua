-- Theme colors; loaded last from hyprland.lua so these override its defaults.
local primary = "rgb(48D7B0)"
local surface = "rgb(0D0F12)"
local secondary = "rgb(7ABB8F)"
local error = "rgb(E56B72)"
local surface_lowest = "rgb(0D0F12)"

hl.config({
    general = {
        col = {
            active_border = primary,
            inactive_border = surface,
        },
    },
    group = {
        col = {
            border_active = secondary,
            border_inactive = surface,
            border_locked_active = error,
            border_locked_inactive = surface,
        },
        groupbar = {
            col = {
                active = secondary,
                inactive = surface_lowest,
                locked_active = error,
                locked_inactive = surface,
            },
        },
    },
})
