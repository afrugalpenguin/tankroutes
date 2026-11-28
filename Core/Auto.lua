-- Tank Routes: when to open and close the map window on its own. Pure functions, no WoW calls.
local _, TR = ...
TR = TR or TankRoutes

local A = {}
TR.Auto = A

-- Auto-open is on unless the player turned it off.
function A.Enabled(db)
    return not (db and db.autoOpen == false)
end

-- s = { prev, new = instance IDs before and after (nil outside dungeons), enabled, hasRoute, autoOpened }
-- Returns "open", "close" or nil.
function A.Decide(s)
    if s.new and s.new ~= s.prev then
        if s.enabled and s.hasRoute then
            return "open"
        end
    elseif not s.new and s.prev and s.autoOpened then
        return "close"
    end
    return nil
end
