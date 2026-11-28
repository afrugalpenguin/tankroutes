-- Tank Routes: map and screen geometry. Pure functions, no WoW calls.
-- Map coordinates are world yards: u east, v south.
-- Screen coordinates are pixels from the view's top-left: x right, y down.
local _, TR = ...
TR = TR or TankRoutes

local G = {}
TR.Geometry = G

-- Half width and half height of a w x h rectangle rotated by angle (radians).
function G.HalfExtents(w, h, angle)
    local c = math.abs(math.cos(angle or 0))
    local s = math.abs(math.sin(angle or 0))
    return (w * c + h * s) / 2, (w * s + h * c) / 2
end

-- { u1, v1, u2, v2 } containing every room, or nil when there are none.
-- Rooms are { fileID, u, v, width, height, angle, sublevel }.
function G.Bounds(rooms)
    local u1, v1, u2, v2
    for _, r in ipairs(rooms) do
        local ex, ey = G.HalfExtents(r[4], r[5], r[6])
        local a, b, c, d = r[2] - ex, r[3] - ey, r[2] + ex, r[3] + ey
        u1 = u1 and math.min(u1, a) or a
        v1 = v1 and math.min(v1, b) or b
        u2 = u2 and math.max(u2, c) or c
        v2 = v2 and math.max(v2, d) or d
    end
    if not u1 then
        return nil
    end
    return { u1, v1, u2, v2 }
end

-- Pixels per yard that fit bounds into a w x h view, leaving a margin fraction.
function G.FitScale(bounds, w, h, margin)
    local bw, bh = bounds[3] - bounds[1], bounds[4] - bounds[2]
    if bw <= 0 or bh <= 0 or w <= 0 or h <= 0 then
        return 1
    end
    return math.min(w / bw, h / bh) * (1 - (margin or 0))
end

-- view = { k = pixels per yard, cu, cv = map point at the view centre, w, h = view size }
function G.ToScreen(u, v, view)
    return (u - view.cu) * view.k + view.w / 2, (v - view.cv) * view.k + view.h / 2
end

-- Move the view by a drag of dx, dy pixels (x right, y down).
function G.Pan(view, dx, dy)
    view.cu = view.cu - dx / view.k
    view.cv = view.cv - dy / view.k
end

-- Multiply the scale by factor, clamped to [minK, maxK].
function G.Zoom(view, factor, minK, maxK)
    view.k = math.max(minK, math.min(maxK, view.k * factor))
end

-- The number of quarter turns (0..3) when angle is within half a degree of one, else nil.
function G.QuarterTurn(angle)
    local q = angle / (math.pi / 2)
    local nearest = math.floor(q + 0.5)
    if math.abs(q - nearest) * 90 > 0.5 then
        return nil
    end
    return nearest % 4
end
