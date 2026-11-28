require("wow_api")

describe("Bundled routes", function()
    before_each(function()
        _G.TankRoutes = nil
        dofile("Core.lua")
        dofile("Core/Route.lua")
        dofile("Data/Maps.lua")
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
            assert.is_table(TankRoutes.Maps[id], "route " .. tostring(id) .. " has no map")
        end
    end)
end)
