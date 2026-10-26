hl.curve("fluent_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })

local anims = {
    { leaf = "windowsIn",   speed = 4, style = "slide" },
    { leaf = "windowsOut",  speed = 4, style = "slide" },
    { leaf = "windowsMove", speed = 4 },
    { leaf = "fade",        speed = 4 },
    { leaf = "workspaces",  speed = 8, style = "slidevert" },
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
