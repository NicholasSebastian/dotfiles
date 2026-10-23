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
    idle_inhibit = "always"
})

hl.window_rule({
    match = {
        class = "^(com%.github%.pikaos%-linux%.pikmanupdatemanager|com%.saivert%.pwvucontrol)$"
    },
    float = true
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
