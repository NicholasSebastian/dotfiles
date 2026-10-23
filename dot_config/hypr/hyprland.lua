hl.config({
    general = {
        layout = "dwindle",
        allow_tearing = true,
        gaps_in = 2,
        gaps_out = 6,
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

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = true,
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

    decoration = {
        rounding = 16,
        rounding_power = 2,
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

hl.curve("fluent_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })

local anims = {
    { leaf = "windowsIn",   speed = 4, style = "slide" },
    { leaf = "windowsOut",  speed = 4, style = "slide" },
    { leaf = "windowsMove", speed = 4 },
    { leaf = "fade",        speed = 4 },
    { leaf = "workspaces",  speed = 8 },
    { leaf = "layers",      speed = 8, style = "slide" },
}

for _, a in ipairs(anims) do
    hl.animation({
        leaf = a.leaf,
        enabled = true,
        speed = a.speed,
        bezier = "fluent_decel",
        style = a.style,
    })
end

require("env")
require("exec")
require("keybinds")
require("monitors")
require("windows")
require("theme")
