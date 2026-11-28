-- Tank Routes: draws a route on the map window as lines and numbered stops.
local _, TR = ...
TR = TR or TankRoutes

local G = TR.Geometry
local L = {}
TR.RouteLayer = L

local LINE_THICKNESS = 3
local STOP_SIZE = 18

local route
local lines, stops = {}, {}

-- Hide a stop, and the tooltip if the stop owns it.
local function hideStop(b)
    b:Hide()
    if GameTooltip.IsOwned and GameTooltip:IsOwned(b) then
        GameTooltip:Hide()
    end
end

-- Hide pool entries from the given indexes onward.
local function hideFrom(firstLine, firstStop)
    for i = firstLine, #lines do lines[i]:Hide() end
    for i = firstStop, #stops do hideStop(stops[i]) end
end

local function hideAll()
    hideFrom(1, 1)
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

local function stop(i, canvas)
    local b = stops[i]
    if not b then
        b = CreateFrame("Button", nil, canvas)
        b:SetSize(STOP_SIZE, STOP_SIZE)
        b:SetFrameLevel(canvas:GetFrameLevel() + 5)
        local disc = b:CreateTexture(nil, "BACKGROUND")
        disc:SetAllPoints()
        disc:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
        disc:SetVertexColor(1, 0.82, 0.1, 1)
        b.num = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        b.num:SetPoint("CENTER")
        b.num:SetTextColor(0, 0, 0, 1)
        b:SetScript("OnEnter", function(self)
            if self.note then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Stop " .. self.number, 1, 0.82, 0)
                GameTooltip:AddLine(self.note, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- Pass presses to the viewport so a drag that starts on a stop pans.
        b:SetScript("OnMouseDown", function(_, button)
            local vp = canvas:GetParent()
            local f = vp:GetScript("OnMouseDown")
            if f then f(vp, button) end
        end)
        stops[i] = b
    end
    return b
end

function L.Draw(view)
    if not route then
        hideAll()
        return
    end
    local canvas = TR.MapWindow.GetCanvas()
    local floor = TR.MapWindow.CurrentFloor()
    local pts = route.points
    local screen, here = {}, {}
    for i, p in ipairs(pts) do
        local u, v = TR.MapWindow.ToMapSpace(p)
        local x, y = G.ToScreen(u, v, view)
        screen[i] = { x, y }
        here[i] = (p.floor or 1) == floor
    end
    for i = 1, #pts - 1 do
        if here[i] and here[i + 1] then
            local l = line(i, canvas)
            l:SetStartPoint("TOPLEFT", canvas, screen[i][1], -screen[i][2])
            l:SetEndPoint("TOPLEFT", canvas, screen[i + 1][1], -screen[i + 1][2])
            l:Show()
        elseif lines[i] then
            lines[i]:Hide()
        end
    end
    -- Stops are pooled by stop number, so a hovered button keeps its stop.
    -- Numbers are global across floors.
    local nums, n = TR.Route.StopNumbers(pts)
    local m = STOP_SIZE / 2
    for i, p in ipairs(pts) do
        if nums[i] then
            local x, y = screen[i][1], screen[i][2]
            if not here[i] or x < -m or x > view.w + m or y < -m or y > view.h + m then
                if stops[nums[i]] then hideStop(stops[nums[i]]) end
            else
                local b = stop(nums[i], canvas)
                b.number, b.note = nums[i], p.note
                b.num:SetText(tostring(nums[i]))
                b:EnableMouse(p.note ~= nil)
                b:ClearAllPoints()
                b:SetPoint("CENTER", canvas, "TOPLEFT", x, -y)
                b:Show()
            end
        end
    end
    hideFrom(math.max(#pts, 1), n + 1)
end
