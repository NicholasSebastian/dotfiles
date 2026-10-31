hl.config({
    general = {
        layout = "scrolling",
        allow_tearing = true,
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(0DB7D4FF)", "rgba(7AA2F7FF)", "rgba(9778D0FF)" }, angle = 45 },
            inactive_border = "rgba(04404aaa)",
        },
    },

    xwayland = {
        use_nearest_neighbor = false,
        force_zero_scaling = true,
        create_abstract_socket = true,
    },

    input = {
        repeat_rate = 50,
        repeat_delay = 300,
        numlock_by_default = true,
        left_handed = false,
        follow_mouse = 0,
        accel_profile = "flat",
    },

    scrolling = {
        column_width = 0.667,
        fullscreen_on_one_column = true,
        direction = "right",
        focus_fit_method = 1, -- fit; scrolling.lua centers non-edge columns
    },

    render = {
        direct_scanout = false,
    },

    cursor = {
        no_hardware_cursors = 0,
        enable_hyprcursor = true,
        use_cpu_buffer = 0,
        sync_gsettings_theme = true,
    },

    misc = {
        vrr = 2,
        disable_hyprland_guiutils_check = true,
        enable_swallow = false,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        focus_on_activate = true,
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        middle_click_paste = false,
    },

    ecosystem = {
        no_update_news = true,
    },
})

require("env")
require("exec")
require("decorations")
require("keybinds")
require("monitors")
require("scrolling")
require("windows")
require("animations")

-- Noctalia's Hyprland template generates noctalia.lua (machine-local, not in chezmoi);
-- until it has, the general.col colors above apply.
-- The template's hook only checks hyprland.lua for this exact require, so it must stay in this file.
local has_noctalia, noctalia = pcall(function() return require("noctalia") end)
if has_noctalia then noctalia.apply_theme() end
