-- Tank Routes: Blizzard's painted dungeon maps, keyed by instance ID.
-- Each floor is Interface\WorldMap\<Folder>\<Folder><floor>_1..12 (4 x 3 tiles of 256 px).
-- These are paths to the game client's own art; nothing is copied into the addon.
local _, TR = ...
TR = TR or TankRoutes

local function floors(folder, ...)
    local list = {}
    for i, n in ipairs({ ... }) do
        list[i] = { path = "Interface\\WorldMap\\" .. folder .. "\\" .. folder .. n .. "_" }
    end
    return list
end

TR.Art = {
    [33] = { name = "Shadowfang Keep", floors = floors("ShadowfangKeep", 1, 7, 6) },
    [34] = { name = "Stormwind Stockade", floors = floors("TheStockade", 1) },
    [36] = { name = "Deadmines", floors = floors("TheDeadmines", 1, 2) },
    [43] = { name = "Wailing Caverns", floors = floors("WailingCaverns", 1) },
    [47] = { name = "Razorfen Kraul", floors = floors("RazorfenKraul", 1) },
    [48] = { name = "Blackfathom Deeps", floors = floors("BlackFathomDeeps", 1, 2, 3) },
    [70] = { name = "Uldaman", floors = floors("Uldaman", 1, 2) },
    [90] = { name = "Gnomeregan", floors = floors("Gnomeregan", 1, 2, 3, 4) },
    [129] = { name = "Razorfen Downs", floors = floors("RazorfenDowns", 1) },
    [189] = { name = "Scarlet Monastery", floors = floors("ScarletMonastery", 1, 2, 3, 4) },
    [230] = { name = "Blackrock Depths", floors = floors("BlackrockDepths", 1, 2) },
    [289] = { name = "Scholomance", floors = floors("ScholomanceOLD", 1, 2, 3, 4) },
    [329] = { name = "Stratholme", floors = floors("Stratholme", 1, 2) },
    [349] = { name = "Maraudon", floors = floors("Maraudon", 1, 2) },
    [389] = { name = "Ragefire Chasm", floors = floors("Ragefire", 1) },
    [429] = { name = "Dire Maul", floors = floors("DireMaul", 1, 2, 3, 4, 5, 6) },
}
