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

-- Screen pixels back to map coordinates (the inverse of ToScreen).
function G.ToMap(x, y, view)
    return (x - view.w / 2) / view.k + view.cu, (y - view.h / 2) / view.k + view.cv
end

-- Distance from (x, y) to the segment a..b.
local function segmentDistance(x, y, a, b)
    local dx, dy = b[1] - a[1], b[2] - a[2]
    local len2 = dx * dx + dy * dy
    local t = 0
    if len2 > 0 then
        t = math.max(0, math.min(1, ((x - a[1]) * dx + (y - a[2]) * dy) / len2))
    end
    local px, py = a[1] + t * dx - x, a[2] + t * dy - y
    return math.sqrt(px * px + py * py)
end

-- The segment (pts[i] to pts[i + 1]) closest to (x, y), as i and its distance,
-- or nil when none is within maxDist. pts entries are { x, y }, or false when not drawn.
function G.NearestSegment(pts, x, y, maxDist)
    local best, bestD
    for i = 1, #pts - 1 do
        local a, b = pts[i], pts[i + 1]
        if a and b then
            local d = segmentDistance(x, y, a, b)
            if d <= maxDist and (not bestD or d < bestD) then
                best, bestD = i, d
            end
        end
    end
    return best, bestD
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

-- Painted dungeon art: 12 tiles of 256 px, 4 columns x 3 rows, visible area 1002 x 668.
G.ART_W, G.ART_H = 1002, 668
G.ART_BOUNDS = { 0, 0, G.ART_W, G.ART_H }

-- The 12 tiles of one painted floor as rooms { path, u, v, 256, 256, 0, 0 },
-- in art pixels, so the room drawing code can draw them.
function G.ArtRooms(prefix)
    local rooms = {}
    for i = 1, 12 do
        local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
        rooms[i] = { prefix .. i, 128 + col * 256, 128 + row * 256, 256, 256, 0, 0 }
    end
    return rooms
end

-- A 0 to 1 position on painted art (0, 0 top-left) in art pixels.
function G.ArtToMap(x, y)
    return x * G.ART_W, y * G.ART_H
end

-- Art pixels back to a 0 to 1 position (the inverse of ArtToMap).
function G.MapToArt(u, v)
    return u / G.ART_W, v / G.ART_H
end
