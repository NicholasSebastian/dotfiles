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
        -- kb_layout = "gb"
        repeat_rate = 50,
        repeat_delay = 300,
        numlock_by_default = true,
        left_handed = false,
        follow_mouse = 1,
        accel_profile = "flat",
    },

    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = true,
    },

    scrolling = {
        column_width = 0.667,
        fullscreen_on_one_column = true,
        direction = "right",
        focus_fit_method = 1, -- fit; scrolling.lua centers non-edge columns
    },

    render = {
        -- should apply as window rule to window instead of general rule
        direct_scanout = false,
    },

    opengl = {
        -- nvidia_anti_flicker = 0,
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
        swallow_regex = "^(Alacritty|kitty|foot|wezterm)$",
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
