-- Tank Routes: edit mode for the map window.
-- Click empty map: add a stop at the end (Shift: a bend). Click a line: insert there.
-- Drag a point: move it. Right-click a point: delete it. Click a stop: edit its note.
-- Undo button or Ctrl-Z: undo the last change. Every change is saved at once.
local _, TR = ...
TR = TR or TankRoutes

local E, G = TR.Edit, TR.Geometry
local ED = {}
TR.Editor = ED

local LINE_HIT = 6     -- pixels from a line that still count as clicking it
local DRAG_SLOP = 4    -- pixels a point must move before a press becomes a drag
local NEW_TITLE = "Custom route"

local active = false
local history = E.NewHistory()
local drag       -- { index, x, y, moved, route } while a point is pressed
local noteBox
local driver = CreateFrame("Frame")
local keys = CreateFrame("Frame", nil, UIParent)
keys:Hide()

local function db()
    TankRoutesDB = TankRoutesDB or {}
    return TankRoutesDB
end

function ED.IsActive()
    return active
end

-- Keep an undo entry, then apply fn(points) to the saved route (created on the first edit).
-- Returns the saved route.
local function change(fn)
    local id = TR.MapWindow.CurrentID()
    if not id then
        return
    end
    local d = db()
    E.Push(history, E.Saved(d, id))
    local r = E.Editable(d, TR.Routes, id, NEW_TITLE)
    fn(r.points)
    TR.MapWindow.ReloadRoute()
    return r
end

-- The cursor in route coordinates.
local function cursorPoint()
    local view = TR.MapWindow.CurrentView()
    if not view then
        return
    end
    local x, y = TR.MapWindow.CursorInView()
    local u, v = G.ToMap(x, y, view)
    local a, b = TR.MapWindow.ToRouteSpace(u, v)
    return a, b, x, y
end

local function hideNote()
    if noteBox then
        noteBox.index = nil
        noteBox:Hide()
    end
end

local function saveNote()
    local i = noteBox.index
    hideNote()
    local r = TR.RouteLayer.GetRoute()
    local p = r and r.points[i]
    if not p then
        return
    end
    local text = (noteBox:GetText() or ""):match("^%s*(.-)%s*$")
    if text == (p.note or "") then
        return
    end
    change(function(points) E.SetNote(points, i, text) end)
end

local function openNote(i)
    local s = TR.RouteLayer.ScreenPoints()[i]
    local r = TR.RouteLayer.GetRoute()
    if not s or not r or not r.points[i] then
        return
    end
    if not noteBox then
        noteBox = CreateFrame("EditBox", nil, TR.MapWindow.GetFrame(), "InputBoxTemplate")
        noteBox:SetSize(170, 20)
        noteBox:SetAutoFocus(false)
        noteBox:SetMaxLetters(200)
        noteBox:SetFrameLevel(TR.MapWindow.GetCanvas():GetFrameLevel() + 20)
        noteBox:SetScript("OnEnterPressed", saveNote)
        noteBox:SetScript("OnEscapePressed", hideNote)
        noteBox:SetScript("OnEditFocusLost", hideNote)
    end
    noteBox.index = i
    noteBox:SetText(r.points[i].note or "")
    noteBox:ClearAllPoints()
    noteBox:SetPoint("TOP", TR.MapWindow.GetCanvas(), "TOPLEFT", s[1], -s[2] - 12)
    noteBox:Show()
    noteBox:SetFocus()
    noteBox:HighlightText()
end

local function endDrag()
    driver:SetScript("OnUpdate", nil)
    local d = drag
    drag = nil
    if d and not d.moved then
        local r = TR.RouteLayer.GetRoute()
        if r and r.points[d.index] and r.points[d.index].stop then
            openNote(d.index)
        end
    end
end

local function onDragUpdate()
    if not drag then
        driver:SetScript("OnUpdate", nil)
        return
    end
    if not IsMouseButtonDown("LeftButton") then
        endDrag()
        return
    end
    local a, b, x, y = cursorPoint()
    if not a then
        return
    end
    if not drag.moved then
        if math.abs(x - drag.x) + math.abs(y - drag.y) < DRAG_SLOP then
            return
        end
        -- one undo entry for the whole drag
        drag.moved = true
        local i = drag.index
        drag.route = change(function(points) E.Move(points, i, a, b) end)
        return
    end
    if drag.route and drag.route.points[drag.index] then
        E.Move(drag.route.points, drag.index, a, b)
        TR.MapWindow.Layout()
    end
end

-- A press on a stop or bend handle.
function ED.OnPointDown(index, button)
    if not active then
        return
    end
    hideNote()
    if button == "RightButton" then
        change(function(points) E.Delete(points, index) end)
    elseif button == "LeftButton" then
        local x, y = TR.MapWindow.CursorInView()
        drag = { index = index, x = x, y = y, moved = false }
        driver:SetScript("OnUpdate", onDragUpdate)
    end
end

-- A click on the map (not on a point): insert on a line under the cursor, else add at the end.
function ED.OnMapClick()
    if not active then
        return
    end
    if noteBox and noteBox:IsShown() then
        hideNote()
        return
    end
    local a, b, x, y = cursorPoint()
    if not a then
        return
    end
    local p = E.NewPoint(a, b, not IsShiftKeyDown(), TR.MapWindow.CurrentFloor())
    local seg = G.NearestSegment(TR.RouteLayer.ScreenPoints(), x, y, LINE_HIT)
    change(function(points)
        if seg then
            E.Insert(points, seg + 1, p)
        else
            E.Append(points, p)
        end
    end)
end

function ED.Undo()
    local id = TR.MapWindow.CurrentID()
    if not id then
        return
    end
    hideNote()
    local ok, value = E.Pop(history)
    if not ok then
        TR:Print("Nothing to undo.")
        return
    end
    E.Restore(db(), id, value)
    TR.MapWindow.ReloadRoute()
end

-- Drop the saved route so the bundled one shows again. Undo brings it back.
function ED.Reset()
    local id = TR.MapWindow.CurrentID()
    if not id then
        TR:Print("Open a map first (/tr or /tr show <instanceID>).")
        return
    end
    local d = db()
    if not (d.routes and d.routes[id]) then
        TR:Print("This dungeon already uses the bundled route.")
        return
    end
    hideNote()
    E.Push(history, E.Saved(d, id))
    E.Restore(d, id, false)
    TR.MapWindow.ReloadRoute()
    TR:Print("Route reset to the bundled route. Undo in edit mode brings your edits back.")
end

function ED.SetActive(on)
    on = on and true or false
    if on == active then
        return
    end
    if on and InCombatLockdown() then
        TR:Print("Editing is not available in combat.")
        return
    end
    if on and not TR.MapWindow.CurrentID() then
        TR:Print("No map to edit.")
        return
    end
    active = on
    hideNote()
    drag = nil
    driver:SetScript("OnUpdate", nil)
    -- Ctrl-Z: keys always pass on to the game, so nothing is ever swallowed.
    if keys.SetPropagateKeyboardInput then
        if on then keys:SetPropagateKeyboardInput(true) end
        keys:EnableKeyboard(on)
        if on then keys:Show() else keys:Hide() end
    end
    TR.MapWindow.SetEditing(on)
    TR.RouteLayer.SetEditing(on)
    TR.MapWindow.Layout()
end

function ED.Toggle()
    ED.SetActive(not active)
end

-- Another map is about to be shown: leave edit mode and forget the undo history.
function ED.OnMapChanged()
    ED.SetActive(false)
    history = E.NewHistory()
end

keys:SetScript("OnKeyDown", function(_, key)
    if active and key == "Z" and IsControlKeyDown() then
        ED.Undo()
    end
end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:SetScript("OnEvent", function()
    if active then
        ED.SetActive(false)
        TR:Print("Editing stopped for combat.")
    end
end)
