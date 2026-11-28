-- Tank Routes: core table, version, chat output and slash command.
local ADDON, TR = ...
TR = TR or {}
TankRoutes = TR

TR.version = "0.1.0"

local LOG_MAX = 200

-- Print to chat with the [TR] prefix, and mirror into TankRoutesDB.log so results
-- can be read from disk after a /reload.
function TR:Print(msg)
    local text = tostring(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[TR]|r " .. text)
    end
    if TankRoutesDB then
        TankRoutesDB.log = TankRoutesDB.log or {}
        local log = TankRoutesDB.log
        log[#log + 1] = text
        while #log > LOG_MAX do
            table.remove(log, 1)
        end
    end
end

function TR.OnEvent(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "TankRoutes" then
        TankRoutesDB = TankRoutesDB or {}
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", TR.OnEvent)

SLASH_TANKROUTES1 = "/tr"
SlashCmdList["TANKROUTES"] = function(msg)
    if TR.HandleSlash then
        TR.HandleSlash(msg or "")
    else
        TR:Print("Tank Routes " .. TR.version .. ".")
    end
end
