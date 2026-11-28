-- Tank Routes: draws a route on the map window as lines and numbered stops.
-- In edit mode every point takes the mouse (bends get small handles) and presses go to TR.Editor.
local _, TR = ...
TR = TR or TankRoutes

local G = TR.Geometry
local L = {}
TR.RouteLayer = L

local LINE_THICKNESS = 3
local STOP_SIZE = 18
local BEND_SIZE = 10

local route
local editing = false
local lines, stops, bends = {}, {}, {}
local screen = {}   -- last drawn position of each point, or false when it is not on this floor

-- Hide a stop or bend handle, and the tooltip if it owns it.
local function hideButton(b)
    b:Hide()
    if GameTooltip.IsOwned and GameTooltip:IsOwned(b) then
        GameTooltip:Hide()
    end
end

-- Hide pool entries from the given indexes onward.
local function hideFrom(firstLine, firstStop, firstBend)
    for i = firstLine, #lines do lines[i]:Hide() end
    for i = firstStop, #stops do hideButton(stops[i]) end
    for i = firstBend, #bends do hideButton(bends[i]) end
end

local function hideAll()
    hideFrom(1, 1, 1)
    screen = {}
end

-- Clears the old drawing too: the no-map path sets nil without a Draw.
function L.SetRoute(r)
    hideAll()
    route = r
    if r then
        local ok, err = TR.Route.Validate(r)
        if not ok then
            TR:Print("Route for instance " .. tostring(r.instanceID) .. " is invalid: " .. err)
            route = nil
        end
    end
end

function L.GetRoute()
    return route
end

function L.SetEditing(on)
    editing = on and true or false
end

-- Screen positions from the last Draw, for hit tests: { x, y } or false per point.
function L.ScreenPoints()
    return screen
end

local function line(i, canvas)
    local l = lines[i]
    if not l then
        l = canvas:CreateLine(nil, "OVERLAY")
        l:SetThickness(LINE_THICKNESS)
        l:SetColorTexture(1, 0.25, 0.2, 0.9)
        lines[i] = l
    end
    return l
end

local function onEnter(self)
    if not self.note and not editing then
        return
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(self.number and ("Stop " .. self.number) or "Bend", 1, 0.82, 0)
    if self.note then
        GameTooltip:AddLine(self.note, 1, 1, 1, true)
    end
    if editing then
        GameTooltip:AddLine(self.number and "Click: note. Drag: move. Right-click: delete."
            or "Drag: move. Right-click: delete.", 0.6, 0.6, 0.6, true)
    end
    GameTooltip:Show()
end

-- Presses go to the editor in edit mode, otherwise to the viewport so a drag pans.
local function onMouseDown(self, button)
    if editing and TR.Editor then
        TR.Editor.OnPointDown(self.index, button)
        return
    end
    local vp = self:GetParent():GetParent()
    local f = vp:GetScript("OnMouseDown")
    if f then f(vp, button) end
end

local function newButton(canvas, size)
    local b = CreateFrame("Button", nil, canvas)
    b:SetSize(size, size)
    b:SetFrameLevel(canvas:GetFrameLevel() + 5)
    b:SetScript("OnEnter", onEnter)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnMouseDown", onMouseDown)
    return b
end

local function stop(i, canvas)
    local b = stops[i]
    if not b then
        b = newButton(canvas, STOP_SIZE)
        local disc = b:CreateTexture(nil, "BACKGROUND")
        disc:SetAllPoints()
        disc:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
        disc:SetVertexColor(1, 0.82, 0.1, 1)
        b.num = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        b.num:SetPoint("CENTER")
        b.num:SetTextColor(0, 0, 0, 1)
        stops[i] = b
    end
    return b
end

local function bend(i, canvas)
    local b = bends[i]
    if not b then
        b = newButton(canvas, BEND_SIZE)
        local dot = b:CreateTexture(nil, "BACKGROUND")
        dot:SetAllPoints()
        dot:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
        dot:SetVertexColor(0.9, 0.9, 0.9, 0.9)
        bends[i] = b
    end
    return b
end

local function place(b, canvas, x, y)
    b:ClearAllPoints()
    b:SetPoint("CENTER", canvas, "TOPLEFT", x, -y)
    b:Show()
end

function L.Draw(view)
    if not route then
        hideAll()
        return
    end
    local canvas = TR.MapWindow.GetCanvas()
    local floor = TR.MapWindow.CurrentFloor()
    local pts = route.points
    screen = {}
    for i, p in ipairs(pts) do
        if (p.floor or 1) == floor then
            local u, v = TR.MapWindow.ToMapSpace(p)
            local x, y = G.ToScreen(u, v, view)
            screen[i] = { x, y }
        else
            screen[i] = false
        end
    end
    for i = 1, #pts - 1 do
        local a, b = screen[i], screen[i + 1]
        if a and b then
            local l = line(i, canvas)
            l:SetStartPoint("TOPLEFT", canvas, a[1], -a[2])
            l:SetEndPoint("TOPLEFT", canvas, b[1], -b[2])
            l:Show()
        elseif lines[i] then
            lines[i]:Hide()
        end
    end
    -- Stops are pooled by stop number, so a hovered button keeps its stop.
    -- Numbers are global across floors.
    local nums, n = TR.Route.StopNumbers(pts)
    local m = STOP_SIZE / 2
    local nb = 0
    for i, p in ipairs(pts) do
        local s = screen[i]
        local inView = s and s[1] >= -m and s[1] <= view.w + m and s[2] >= -m and s[2] <= view.h + m
        if nums[i] then
            if not inView then
                if stops[nums[i]] then hideButton(stops[nums[i]]) end
            else
                local b = stop(nums[i], canvas)
                b.index, b.number, b.note = i, nums[i], p.note
                b.num:SetText(tostring(nums[i]))
                b:EnableMouse(editing or p.note ~= nil)
                place(b, canvas, s[1], s[2])
            end
        elseif editing and inView then
            nb = nb + 1
            local b = bend(nb, canvas)
            b.index, b.number, b.note = i, nil, nil
            place(b, canvas, s[1], s[2])
        end
    end
    hideFrom(math.max(#pts, 1), n + 1, nb + 1)
end
