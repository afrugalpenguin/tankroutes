-- Tank Routes: the map window. Draws a dungeon's rooms, with zoom, pan and Fit.
local _, TR = ...
TR = TR or TankRoutes

local G = TR.Geometry
local W = {}
TR.MapWindow = W

local DEFAULT_W, DEFAULT_H = 300, 220
local MIN_W, MIN_H = 200, 150
local MIN_ZOOM, MAX_ZOOM = 1, 8
local ZOOM_STEP = 1.25
local MARGIN = 0.06

local frame, viewport, canvas, title, emptyText
local roomTextures = {}
local roomTurns = {}   -- quarter turns per room, or false when drawn with SetRotation

-- texture coordinates (upper-left, lower-left, upper-right, lower-right) for each quarter turn
local TURNS = {
    [0] = { 0, 0, 0, 1, 1, 0, 1, 1 },
    [1] = { 1, 0, 0, 0, 1, 1, 0, 1 },
    [2] = { 1, 1, 1, 0, 0, 1, 0, 0 },
    [3] = { 0, 1, 1, 1, 0, 0, 1, 0 },
}
local view       -- { k, cu, cv, w, h, fitK }
local current    -- { id, map, bounds }
local dragging   -- { x, y } last cursor position while panning

local function setColor(tex, r, g, b, a)
    if tex.SetColorTexture then
        tex:SetColorTexture(r, g, b, a)
    else
        tex:SetTexture(r, g, b, a)
    end
end

local function saveGeometry()
    if not TankRoutesDB or not frame then
        return
    end
    local point, _, relPoint, x, y = frame:GetPoint(1)
    TankRoutesDB.window = {
        point = point, relPoint = relPoint, x = x, y = y,
        w = frame:GetWidth(), h = frame:GetHeight(),
    }
end

local function restoreGeometry()
    local saved = TankRoutesDB and TankRoutesDB.window
    frame:ClearAllPoints()
    if saved and saved.point then
        frame:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
        frame:SetSize(saved.w or DEFAULT_W, saved.h or DEFAULT_H)
    else
        frame:SetPoint("CENTER")
        frame:SetSize(DEFAULT_W, DEFAULT_H)
    end
end

function W.GetCanvas()
    return canvas
end

-- Position every room for the current view, then redraw the route on top.
function W.Layout()
    if not current or not view then
        return
    end
    view.w, view.h = viewport:GetWidth(), viewport:GetHeight()
    for i, r in ipairs(current.map.rooms) do
        local tex = roomTextures[i]
        local x, y = G.ToScreen(r[2], r[3], view)
        tex:ClearAllPoints()
        local turn = roomTurns[i]
        if turn and turn % 2 == 1 then
            tex:SetSize(r[5] * view.k, r[4] * view.k)
        else
            tex:SetSize(r[4] * view.k, r[5] * view.k)
        end
        tex:SetPoint("CENTER", canvas, "TOPLEFT", x, -y)
    end
    if TR.RouteLayer then
        TR.RouteLayer.Draw(view)
    end
end

function W.Fit()
    if not current then
        return
    end
    if viewport:GetWidth() <= 0 or viewport:GetHeight() <= 0 then
        -- not laid out yet (first show): try again on the next frame
        C_Timer.After(0, W.Fit)
        return
    end
    local b = current.bounds
    local k = G.FitScale(b, viewport:GetWidth(), viewport:GetHeight(), MARGIN)
    view = { k = k, fitK = k, cu = (b[1] + b[3]) / 2, cv = (b[2] + b[4]) / 2 }
    W.Layout()
end

local function onWheel(_, delta)
    if not view then
        return
    end
    G.Zoom(view, delta > 0 and ZOOM_STEP or 1 / ZOOM_STEP, view.fitK * MIN_ZOOM, view.fitK * MAX_ZOOM)
    W.Layout()
end

local function cursor()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    return x / scale, y / scale
end

local function onUpdate()
    if not dragging or not view then
        return
    end
    local x, y = cursor()
    -- cursor y grows upward; Pan takes y growing downward
    G.Pan(view, x - dragging.x, dragging.y - y)
    dragging.x, dragging.y = x, y
    W.Layout()
end

local function create()
    frame = CreateFrame("Frame", "TankRoutesWindow", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_W, MIN_H)
    elseif frame.SetMinResize then
        frame:SetMinResize(MIN_W, MIN_H)
    end
    restoreGeometry()

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    setColor(bg, 0.02, 0.02, 0.03, 0.92)

    -- title bar: drag here to move the window
    local bar = CreateFrame("Frame", nil, frame)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(20)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() frame:StartMoving() end)
    bar:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); saveGeometry() end)

    title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("LEFT", 6, 0)
    title:SetPoint("RIGHT", -60, 0)
    title:SetJustifyH("LEFT")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 4, 4)
    close:SetSize(24, 24)

    local fit = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    fit:SetSize(36, 16)
    fit:SetPoint("RIGHT", close, "LEFT", 0, 0)
    fit:SetText("Fit")
    fit:SetScript("OnClick", W.Fit)

    viewport = CreateFrame("Frame", nil, frame)
    viewport:SetPoint("TOPLEFT", 4, -22)
    viewport:SetPoint("BOTTOMRIGHT", -4, 4)
    viewport:SetClipsChildren(true)
    viewport:EnableMouse(true)
    viewport:EnableMouseWheel(true)
    viewport:SetScript("OnMouseWheel", onWheel)
    viewport:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            local x, y = cursor()
            dragging = { x = x, y = y }
        end
    end)
    viewport:SetScript("OnMouseUp", function() dragging = nil end)
    viewport:SetScript("OnUpdate", onUpdate)

    canvas = CreateFrame("Frame", nil, viewport)
    canvas:SetAllPoints()

    emptyText = viewport:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("CENTER")

    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(14, 14)
    grip:SetPoint("BOTTOMRIGHT")
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); saveGeometry() end)

    frame:SetScript("OnSizeChanged", W.Layout)
end

-- Show the map for an instance ID. Prints and shows a message when there is none.
function W.ShowMap(id, displayName)
    if not frame then
        create()
    end
    for _, tex in ipairs(roomTextures) do
        tex:Hide()
    end
    current, view = nil, nil

    local map = TR.Maps and TR.Maps[id]
    if not map then
        local name = displayName or ("instance " .. tostring(id))
        title:SetText("Tank Routes")
        emptyText:SetText("No map for " .. name .. " yet")
        emptyText:Show()
        if TR.RouteLayer then TR.RouteLayer.SetRoute(nil) end
        frame:Show()
        TR:Print("No map for " .. name .. " (instance " .. tostring(id) .. ") yet.")
        return
    end

    emptyText:Hide()
    title:SetText(map.name)
    local failed = 0
    for i, r in ipairs(map.rooms) do
        local tex = roomTextures[i]
        if not tex then
            tex = canvas:CreateTexture(nil, "ARTWORK")
            roomTextures[i] = tex
        end
        tex:SetDrawLayer("ARTWORK", math.max(-8, math.min(7, r[7] or 0)))
        tex:SetVertexColor(1, 1, 1, 1)
        if tex:SetTexture(r[1]) == false then
            -- the image did not load: show the room as a grey box so the layout still reads
            failed = failed + 1
            setColor(tex, 0.4, 0.4, 0.4, 0.5)
        end
        local turn = G.QuarterTurn(r[6] or 0)
        roomTurns[i] = turn or false
        if turn then
            tex:SetTexCoord(unpack(TURNS[turn]))
            if tex.SetRotation then
                tex:SetRotation(0)
            end
        else
            tex:SetTexCoord(0, 1, 0, 1)
            if tex.SetRotation then
                tex:SetRotation(r[6])
            end
        end
        tex:Show()
    end
    if failed > 0 then
        TR:Print(failed .. " of " .. #map.rooms .. " room images did not load for " .. map.name .. ".")
    end

    current = { id = id, map = map, bounds = G.Bounds(map.rooms) }
    if TR.RouteLayer then
        TR.RouteLayer.SetRoute(TR.Routes and TR.Routes[id])
    end
    frame:Show()
    W.Fit()
end

function W.IsShown()
    return frame and frame:IsShown()
end

function W.Hide()
    if frame then
        frame:Hide()
    end
end
