-- Tank Routes: route editing rules, undo history and saved routes. Pure functions, no WoW calls.
-- Saved routes live in db.routes[instanceID] and replace the bundled route for that dungeon.
local _, TR = ...
TR = TR or TankRoutes

local E = {}
TR.Edit = E

E.UNDO_MAX = 20

function E.Copy(t)
    if type(t) ~= "table" then
        return t
    end
    local c = {}
    for k, v in pairs(t) do
        c[k] = E.Copy(v)
    end
    return c
end

-- A stop or a bend. floor is only stored when it is not 1.
function E.NewPoint(a, b, stop, floor)
    local p = { a, b }
    if stop then
        p.stop = true
    end
    if floor and floor ~= 1 then
        p.floor = floor
    end
    return p
end

function E.Append(points, p)
    points[#points + 1] = p
end

-- Insert p so it becomes points[i].
function E.Insert(points, i, p)
    table.insert(points, i, p)
end

function E.Move(points, i, a, b)
    points[i][1], points[i][2] = a, b
end

function E.Delete(points, i)
    table.remove(points, i)
end

-- Set a stop's note (trimmed; empty clears it). Returns false for a bend.
function E.SetNote(points, i, text)
    local p = points[i]
    if not p or not p.stop then
        return false
    end
    text = (text or ""):match("^%s*(.-)%s*$")
    p.note = text ~= "" and text or nil
    return true
end

function E.NewHistory()
    return {}
end

function E.Push(hist, value)
    hist[#hist + 1] = value
    while #hist > E.UNDO_MAX do
        table.remove(hist, 1)
    end
end

-- Returns true and the newest entry, or false when the history is empty.
function E.Pop(hist)
    if #hist == 0 then
        return false
    end
    return true, table.remove(hist)
end

-- The route to show: a valid saved route, else the bundled one.
-- Returns route, source ("saved" or "bundled"), and an error when a saved route is invalid.
function E.Active(db, bundled, id)
    local saved = db and db.routes and db.routes[id]
    local err
    if saved then
        local ok, msg = TR.Route.Validate(saved)
        if ok then
            return saved, "saved"
        end
        err = msg
    end
    local b = bundled and bundled[id]
    if b then
        return b, "bundled", err
    end
    return nil, nil, err
end

-- The saved route to change, created from the bundled route (or empty) on the first edit.
-- An invalid saved route is replaced.
function E.Editable(db, bundled, id, title)
    db.routes = db.routes or {}
    local saved = db.routes[id]
    if saved and TR.Route.Validate(saved) then
        return saved
    end
    local b = bundled and bundled[id]
    local r = b and E.Copy(b)
        or { instanceID = id, title = title, version = TR.Route.VERSION, points = {} }
    db.routes[id] = r
    return r
end

-- An undo entry: a copy of the saved route, or false when there is none.
function E.Saved(db, id)
    local saved = db and db.routes and db.routes[id]
    return saved and E.Copy(saved) or false
end

-- Put back an undo entry from Saved.
function E.Restore(db, id, value)
    db.routes = db.routes or {}
    db.routes[id] = value and E.Copy(value) or nil
end
