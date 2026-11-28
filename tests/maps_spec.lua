require("wow_api")

describe("Map data", function()
    local Maps

    before_each(function()
        _G.TankRoutes = nil
        dofile("Core.lua")
        dofile("Data/Maps.lua")
        Maps = TankRoutes.Maps
    end)

    local MIT_IDS = { 33, 34, 36, 43, 47, 70, 90, 109, 129, 189, 209, 229, 230, 249, 289,
        329, 349, 389, 429, 2959, 2998, 2999, 3065 }
    local RESTRICTED_IDS = { 48, 2970, 2974, 2994, 3001, 3039 }

    it("has every MIT-sourced dungeon", function()
        for _, id in ipairs(MIT_IDS) do
            assert.is_table(Maps[id], "missing map " .. id)
        end
    end)

    it("never contains All Rights Reserved layouts", function()
        for _, id in ipairs(RESTRICTED_IDS) do
            assert.is_nil(Maps[id], "restricted map " .. id .. " must not be bundled")
        end
    end)

    it("has only the allowed dungeons", function()
        local allowed = {}
        for _, id in ipairs(MIT_IDS) do allowed[id] = true end
        for id in pairs(Maps) do
            assert.is_true(allowed[id] == true, "unexpected map " .. tostring(id))
        end
    end)

    it("stores rooms as seven numbers with a fileID", function()
        for id, map in pairs(Maps) do
            assert.is_string(map.name)
            assert.is_true(#map.rooms > 0, "map " .. id .. " has no rooms")
            for i, r in ipairs(map.rooms) do
                assert.equals(7, #r, "map " .. id .. " room " .. i)
                for j = 1, 7 do
                    assert.is_number(r[j], "map " .. id .. " room " .. i .. " field " .. j)
                end
            end
        end
    end)
end)
