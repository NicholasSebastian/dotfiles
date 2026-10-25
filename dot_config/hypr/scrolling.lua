-- Scrolling direction per monitor: right on landscape, down on portrait.
-- Windows slide in from the same side the layout grows towards.
-- width/height are the unrotated mode size, so odd transforms (90°/270°) swap them.

local scroll_dir_set = {}

local function set_scroll_directions()
    for _, m in ipairs(hl.get_monitors()) do
        if not scroll_dir_set[m.name] then
            local w, h = m.width, m.height
            if m.transform % 2 == 1 then w, h = h, w end
            local portrait = h > w
            local ws = "m[" .. m.name .. "]"
            hl.workspace_rule({
                workspace = ws,
                layout_opts = { direction = portrait and "down" or "right" },
            })
            hl.window_rule({
                match = { workspace = ws },
                animation = portrait and "slide bottom" or "slide right",
            })
            scroll_dir_set[m.name] = true
        end
    end
end

set_scroll_directions()
hl.on("monitor.added", set_scroll_directions)

-- Focused column: centered in the viewport, except the first and last columns,
-- which sit flush against the screen edge instead.
-- hyprland.lua sets focus_fit_method = 1 (fit), so the layout's own focus scroll
-- already pins edge columns; center_column() re-centers middle columns after it.
local function center_column(w)
    local col = w and w.layout and w.layout.column
    if not col or not w.workspace then return end

    local last = 0
    for _, o in ipairs(hl.get_workspace_windows(w.workspace.id)) do
        local oc = o.layout and o.layout.column
        if oc and oc.index > last then last = oc.index end
    end
    if col.index == 0 or col.index == last then return end

    hl.config({ scrolling = { focus_fit_method = 0 } })
    hl.dispatch(hl.dsp.layout("fit_into_view"))
    hl.config({ scrolling = { focus_fit_method = 1 } })
end

-- Keyboard and other focus changes. Mouse focus is skipped here: hovering
-- (focus-follows-mouse) must not move the view, and clicks are handled below.
local FOCUS_REASON_FFM, FOCUS_REASON_CLICK = 1, 16

hl.on("window.active", function(w, reason)
    if reason == FOCUS_REASON_FFM or reason & FOCUS_REASON_CLICK ~= 0 then return end
    center_column(w)
end)

-- Clicks. With focus-follows-mouse the window is usually focused before the
-- click, so no focus event fires; this left-click release bind passes the click
-- through to the app and centers the window if the click landed inside it.
hl.bind("mouse:272", function()
    local w, c = hl.get_active_window(), hl.get_cursor_pos()
    if not w or not c or w.floating then return end
    if c.x < w.at.x or c.x >= w.at.x + w.size.x or c.y < w.at.y or c.y >= w.at.y + w.size.y then return end
    center_column(w)
end, { release = true, non_consuming = true, description = "Center Clicked Column" })

return { center_column = center_column }
