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
        local seen = {}
        for id in pairs(TR.Art) do seen[id] = true; ids[#ids + 1] = id end
        for id in pairs(TR.Maps) do
            if not seen[id] then ids[#ids + 1] = id end
        end
        table.sort(ids)
        for _, id in ipairs(ids) do
            local art = TR.Art[id]
            if art then
                local n = #art.floors
                TR:Print(id .. ": " .. art.name .. " (painted, " .. n .. (n == 1 and " floor)" or " floors)"))
            else
                local n = #TR.Maps[id].rooms
                TR:Print(id .. ": " .. TR.Maps[id].name .. " (rooms, " .. n .. (n == 1 and " room)" or " rooms)"))
            end
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
