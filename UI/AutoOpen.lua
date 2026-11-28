-- Tank Routes: open the map window on entering a dungeon that has a route, and close it on leaving
-- (only when it was opened here). /tr auto turns this off.
local _, TR = ...
TR = TR or TankRoutes

local A = TR.Auto

local prevID          -- dungeon the player was in at the last loading screen
local autoOpened = false

-- The instance ID and name when in a party or raid instance, else nil.
function TR.CurrentInstance()
    local name, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
    if issecretvalue and (issecretvalue(instanceID) or issecretvalue(instanceType)) then
        return nil
    end
    if (instanceType == "party" or instanceType == "raid") and type(instanceID) == "number" then
        return instanceID, name
    end
end

local function hasRoute(id)
    if not (TR.Art and TR.Art[id]) and not (TR.Maps and TR.Maps[id]) then
        return false
    end
    return TR.Edit.Active(TankRoutesDB, TR.Routes, id) ~= nil
end

local function onEnteringWorld()
    local id, name = TR.CurrentInstance()
    local action = A.Decide({
        prev = prevID, new = id, enabled = A.Enabled(TankRoutesDB),
        hasRoute = id and hasRoute(id), autoOpened = autoOpened,
    })
    prevID = id
    if action == "open" then
        TR.MapWindow.ShowMap(id, name)
        autoOpened = true
    elseif action == "close" then
        TR.MapWindow.Hide()
    end
    if not id then
        autoOpened = false
    end
end

-- /tr auto: turn auto-open on or off.
function TR.ToggleAutoOpen()
    TankRoutesDB = TankRoutesDB or {}
    TankRoutesDB.autoOpen = not A.Enabled(TankRoutesDB)
    TR:Print("Auto-open " .. (TankRoutesDB.autoOpen and "on" or "off")
        .. ": the map " .. (TankRoutesDB.autoOpen and "opens" or "no longer opens")
        .. " when you enter a dungeon with a route.")
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", onEnteringWorld)
