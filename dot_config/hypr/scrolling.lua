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

-- Index of w's column and of the workspace's last column, or nil if w is not
-- a tiled scrolling window.
local function column_position(w)
    local col = w and w.layout and w.layout.column
    if not col or not w.workspace then return nil end

    local last = 0
    for _, o in ipairs(hl.get_workspace_windows(w.workspace.id)) do
        local oc = o.layout and o.layout.column
        if oc and oc.index > last then last = oc.index end
    end
    return col.index, last
end

local function center_column(w)
    local index, last = column_position(w)
    if not index or index == 0 or index == last then return end

    hl.config({ scrolling = { focus_fit_method = 0 } })
    hl.dispatch(hl.dsp.layout("fit_into_view"))
    hl.config({ scrolling = { focus_fit_method = 1 } })
end

-- True while pin_last_column() juggles focus; the window.active hook ignores it.
local pinning = false

-- Scroll the last column flush against the far screen edge (right on landscape,
-- bottom on portrait). Fit leaves it wherever it already fits, which can be the
-- near edge with empty space after it.
local function pin_last_column(w)
    local index, last = column_position(w)
    if not index or index == 0 or index ~= last then return end

    local m = w.monitor
    local mw, mh = m.size.width / m.scale, m.size.height / m.scale
    if m.transform % 2 == 1 then mw, mh = mh, mw end
    local gaps, border = hl.get_config("general.gaps_out"), hl.get_config("general.border_size")

    local delta
    if mh > mw then
        delta = (m.position.y + mh - m.reserved.bottom - gaps.bottom - border) - (w.at.y + w.size.y)
    else
        delta = (m.position.x + mw - m.reserved.right - gaps.right - border) - (w.at.x + w.size.x)
    end
    delta = math.floor(delta)
    if delta <= 0 then return end

    -- A pixel move focuses whichever column then covers the screen center, so a
    -- narrow last column loses focus; give it back (already in view: no scroll).
    pinning = true
    hl.dispatch(hl.dsp.layout("move +" .. delta))
    local now = hl.get_active_window()
    if not now or now.address ~= w.address then
        hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
    end
    pinning = false
end

-- After a width or fullscreen change: center middle columns, pin the last one.
-- The pin is deferred by 1 ms (0 never fires) so it reads the settled geometry;
-- right after the change the window can still have its old size or, leaving
-- fullscreen, its borderless geometry.
local function recenter(w)
    center_column(w)
    hl.timer(function() pin_last_column(hl.get_active_window()) end, { timeout = 1, type = "oneshot" })
end

-- Leaving fullscreen/maximize, whether from a bind or the app itself (F11,
-- Esc in a video): the layout restores the column with a plain fit.
hl.on("window.fullscreen", function(w)
    if w and w.active and w.fullscreen == 0 then recenter(w) end
end)

-- Keyboard and other focus changes. Mouse focus is skipped here: hovering
-- (focus-follows-mouse) must not move the view, and clicks are handled below.
local FOCUS_REASON_FFM, FOCUS_REASON_CLICK = 1, 16

hl.on("window.active", function(w, reason)
    if pinning or reason == FOCUS_REASON_FFM or reason & FOCUS_REASON_CLICK ~= 0 then return end
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

return { recenter = recenter }
