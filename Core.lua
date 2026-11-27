-- Tank Routes: core table, version and slash command.
local ADDON, TR = ...
TR = TR or {}
TankRoutes = TR

TR.version = "0.1.0"

function TR:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[TR]|r " .. tostring(msg))
    end
end

SLASH_TANKROUTES1 = "/tr"
SlashCmdList["TANKROUTES"] = function()
    TR:Print("Tank Routes " .. TR.version .. ". Nothing to show yet.")
end
