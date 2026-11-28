require("wow_api")

describe("Bundled routes", function()
    before_each(function()
        _G.TankRoutes = nil
        dofile("Core.lua")
        dofile("Core/Geometry.lua")
        dofile("Core/Route.lua")
        dofile("Data/Maps.lua")
        dofile("Data/Art.lua")
        dofile("Data/Routes.lua")
    end)

    it("are all valid and match their key", function()
        assert.is_table(TankRoutes.Routes)
        assert.is_not_nil(next(TankRoutes.Routes), "no bundled routes")
        for id, route in pairs(TankRoutes.Routes) do
            local ok, err = TankRoutes.Route.Validate(route)
            assert.is_true(ok, "route " .. tostring(id) .. ": " .. tostring(err))
            local _, stops = TankRoutes.Route.StopNumbers(route.points)
            assert.is_true(stops > 0, "route " .. tostring(id) .. " has no stops")
            assert.equals(id, route.instanceID)
        end
    end)

    it("only exist for dungeons that have a map", function()
        for id in pairs(TankRoutes.Routes) do
            assert.is_table(TankRoutes.Art[id] or TankRoutes.Maps[id], "route " .. tostring(id) .. " has no map")
        end
    end)

    it("use 0 to 1 positions and real floors on painted maps", function()
        for id, route in pairs(TankRoutes.Routes) do
            local art = TankRoutes.Art[id]
            for i, p in ipairs(route.points) do
                local where = "route " .. tostring(id) .. " point " .. i
                if art then
                    assert.is_true(p[1] >= 0 and p[1] <= 1 and p[2] >= 0 and p[2] <= 1, where)
                    assert.is_true((p.floor or 1) <= #art.floors, where .. " floor")
                else
                    assert.is_true((p.floor or 1) == 1, where .. " floor on a room map")
                end
            end
        end
    end)
end)
