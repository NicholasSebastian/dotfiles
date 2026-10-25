-- Default monitor setup for machines without their own file in
-- .chezmoitemplates/hypr-monitors/: every monitor runs at its highest
-- resolution, at the highest refresh rate available for that resolution,
-- placed automatically left to right.

hl.monitor({ output = "", mode = "highres", position = "auto", scale = "auto" })

local function best_mode(m)
    local best
    for _, md in ipairs(m.available_modes or {}) do
        local px = md.width * md.height
        if not best or px > best.px or (px == best.px and md.refresh_rate > best.rr) then
            best = { px = px, w = md.width, h = md.height, rr = md.refresh_rate }
        end
    end
    return best
end

local configured = {}

local function configure_monitors()
    for _, m in ipairs(hl.get_monitors()) do
        if not configured[m.name] then
            local b = best_mode(m)
            if b then
                hl.monitor({
                    output = m.name,
                    mode = string.format("%dx%d@%.3f", b.w, b.h, b.rr),
                    position = "auto",
                    scale = "auto",
                })
            end
            configured[m.name] = true
        end
    end
end

configure_monitors()
hl.on("monitor.added", configure_monitors)
