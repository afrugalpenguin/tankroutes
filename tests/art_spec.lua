require("wow_api")

describe("Painted map data", function()
    local Art

    before_each(function()
        _G.TankRoutes = nil
        dofile("Core.lua")
        dofile("Data/Art.lua")
        Art = TankRoutes.Art
    end)

    local IDS = { 33, 34, 36, 43, 47, 48, 70, 90, 129, 189, 230, 289, 329, 349, 389, 429 }

    it("has exactly the 16 painted dungeons", function()
        local want = {}
        for _, id in ipairs(IDS) do
            want[id] = true
            assert.is_table(Art[id], "missing " .. id)
        end
        for id in pairs(Art) do
            assert.is_true(want[id] == true, "unexpected " .. tostring(id))
        end
    end)

    it("has a name and Blizzard WorldMap floor paths", function()
        for id, a in pairs(Art) do
            assert.is_string(a.name, "name for " .. id)
            assert.is_true(#a.floors > 0, "floors for " .. id)
            for i, f in ipairs(a.floors) do
                assert.is_truthy(f.path:match("^Interface\\WorldMap\\(%a+)\\%1%d+_$"),
                    "map " .. id .. " floor " .. i .. ": " .. tostring(f.path))
            end
        end
    end)
end)
