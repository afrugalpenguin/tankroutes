-- Tank Routes: slash commands.
--   /tr          toggle the window for the current dungeon
--   /tr show ID  preview the map for an instance ID (works anywhere)
--   /tr list     list the dungeons that have a map
local _, TR = ...
TR = TR or TankRoutes

local function currentInstance()
    local name, instanceType, _, _, _, _, _, instanceID = GetInstanceInfo()
    if instanceType == "party" or instanceType == "raid" then
        return instanceID, name
    end
end

function TR.HandleSlash(msg)
    local cmd, rest = msg:match("^%s*(%S*)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()

    if cmd == "show" then
        local id = tonumber(rest)
        if not id then
            TR:Print("Usage: /tr show <instanceID>   (see /tr list)")
            return
        end
        TR.MapWindow.ShowMap(id)
    elseif cmd == "list" then
        local ids = {}
        for id in pairs(TR.Maps) do ids[#ids + 1] = id end
        table.sort(ids)
        for _, id in ipairs(ids) do
            TR:Print(id .. ": " .. TR.Maps[id].name .. " (" .. #TR.Maps[id].rooms .. " rooms)")
        end
    elseif cmd == "" then
        if TR.MapWindow.IsShown() then
            TR.MapWindow.Hide()
            return
        end
        local id, name = currentInstance()
        if not id then
            TR:Print("Not in a dungeon. Use /tr show <instanceID> to preview a map.")
            return
        end
        TR.MapWindow.ShowMap(id, name)
    else
        TR:Print("Commands: /tr, /tr show <instanceID>, /tr list")
    end
end
