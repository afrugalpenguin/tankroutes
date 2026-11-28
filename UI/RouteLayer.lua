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

-- Hide everything drawn, and the tooltip if a stop owns it.
local function hideAll()
    for _, l in ipairs(lines) do l:Hide() end
    for _, b in ipairs(stops) do
        b:Hide()
        if GameTooltip.IsOwned and GameTooltip:IsOwned(b) then
            GameTooltip:Hide()
        end
    end
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
        stops[i] = b
    end
    return b
end

function L.Draw(view)
    hideAll()
    if not route then
        return
    end
    local canvas = TR.MapWindow.GetCanvas()
    local pts = route.points
    local screen = {}
    for i, p in ipairs(pts) do
        local x, y = G.ToScreen(p[1], p[2], view)
        screen[i] = { x, y }
    end
    for i = 1, #pts - 1 do
        local l = line(i, canvas)
        l:SetStartPoint("TOPLEFT", canvas, screen[i][1], -screen[i][2])
        l:SetEndPoint("TOPLEFT", canvas, screen[i + 1][1], -screen[i + 1][2])
        l:Show()
    end
    local nums = TR.Route.StopNumbers(pts)
    local n = 0
    for i, p in ipairs(pts) do
        if nums[i] then
            n = n + 1
            local b = stop(n, canvas)
            b.number, b.note = nums[i], p.note
            b.num:SetText(tostring(nums[i]))
            b:ClearAllPoints()
            b:SetPoint("CENTER", canvas, "TOPLEFT", screen[i][1], -screen[i][2])
            b:Show()
        end
    end
end
