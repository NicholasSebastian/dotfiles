-- Apps can't maximize themselves; column width stays under keyboard control.
hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Empty, untitled XWayland popups (JetBrains menus/tooltips, Wine apps) must not steal focus.
hl.window_rule({
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Dialogs float centered instead of becoming a column.
hl.window_rule({
    match = { modal = true },
    float = true,
    center = true,
})

hl.window_rule({
    match = { class = "^(xdg-desktop-portal-gtk|org\\.freedesktop\\.impl\\.portal\\.desktop\\..+)$" },
    float = true,
    center = true,
})

hl.window_rule({
    match = {
        title =
        "^(Open|Open File|Open Files|Open Folder|Select Folder|Select a File|Choose Files?|File Upload|Save|Save File|Save As|Save Image|Open With|Choose Application)$"
    },
    float = true,
    center = true,
})

-- Picture-in-Picture: small, pinned to all workspaces, bottom-right corner.
hl.window_rule({
    match = { title = "^(Picture[- ]in[- ][Pp]icture)$" },
    float = true,
    pin = true,
    keep_aspect_ratio = true,
    opaque = true,
    -- Position from the monitor size: window_w/h are still the app's own size when this is evaluated.
    size = { "(monitor_w*0.3)", "(monitor_w*0.16875)" },
    move = { "(monitor_w*0.7-24)", "(monitor_h-monitor_w*0.16875-24)" },
})

hl.window_rule({
    match = { title = "^(Sharing)$" },
    float = true
})

hl.window_rule({
    match = { class = "^([Ss]tream|steamwebhelper)$" },
    float = true,
    border_size = 0,
    no_shadow = true,
    no_blur = true
})

hl.window_rule({
    match = { class = "^(gamescope)$" },
    idle_inhibit = "always"
})

hl.window_rule({
    match = { class = "^(steam_app_.*)$" },
    fullscreen = true,
    immediate = true,
    idle_inhibit = "always",
    allows_input = true,
    render_unfocused = true
})

hl.window_rule({
    match = { fullscreen = true },
    immediate = true,
    idle_inhibit = "always",
    opaque = true
})

hl.window_rule({
    match = {
        class = "^(com\\.github\\.pikaos-linux\\.pikmanupdatemanager|com\\.saivert\\.pwvucontrol)$"
    },
    float = true
})

-- Work apps that open as a full-width column in the scrolling layout.
-- Entries are regexes matched case-insensitively against the whole window class;
-- apps with both an X11 class and a Wayland/Flatpak app ID list both.

local full_width_apps = {
    -- Editors and IDEs
    "dev\\.zed\\.zed",
    "codium", "vscodium",
    "jetbrains-.+", -- every JetBrains IDE, incl. Android Studio

    -- Game dev
    "blender",
    "godot", "org\\.godotengine\\.godot(sharp)?",
    "unity", -- the editor, not Unity Hub
    "tiled", "org\\.mapeditor\\.tiled",
    "audacity", "org\\.audacityteam\\.audacity",
    "aseprite",
    "pixelorama", "com\\.orama_interactive\\.pixelorama",

    -- Creative
    "gimp(-[0-9.]+)?", "org\\.gimp\\.gimp",
    "krita", "org\\.kde\\.krita",
    "inkscape", "org\\.inkscape\\.inkscape",
    "darktable", "org\\.darktable\\.darktable",
    "kdenlive", "org\\.kde\\.kdenlive",
    "resolve",                              -- DaVinci Resolve
    "affinity\\.exe",
    "(photo|vector|film|light)craft",       -- ArtCraft apps
    "(brave|chrome)-www\\.figma\\.com__.*", -- web apps
    "(brave|chrome)-www\\.canva\\.com__.*",
    "(brave|chrome)-excalidraw\\.com__.*",
}

hl.window_rule({
    match = { class = "(?i)^(" .. table.concat(full_width_apps, "|") .. ")$" },
    scrolling_width = 1.0,
})

-- Noctalia blur
hl.layer_rule({
    name = "noctalia",
    match = {
        namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
    },
    no_anim = true,
    ignore_alpha = 0.5,
    blur = true,
    blur_popups = true,
})

-- Noctalia Settings
hl.window_rule({
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    size = { 1080, 920 },
})
