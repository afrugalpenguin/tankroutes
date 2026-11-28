require("wow_api")

describe("Route", function()
    local R

    before_each(function()
        _G.TankRoutes = nil
        dofile("Core.lua")
        dofile("Core/Route.lua")
        R = TankRoutes.Route
    end)

    describe("StopNumbers", function()
        it("numbers stops in order and skips bends", function()
            local points = { { 0, 0, stop = true }, { 1, 1 }, { 2, 2, stop = true }, { 3, 3, stop = true } }
            local nums, count = R.StopNumbers(points)
            assert.same({ [1] = 1, [3] = 2, [4] = 3 }, nums)
            assert.equals(3, count)
        end)

        it("handles an empty route", function()
            local nums, count = R.StopNumbers({})
            assert.same({}, nums)
            assert.equals(0, count)
        end)
    end)

    describe("Validate", function()
        local function route(points)
            return { instanceID = 36, title = "Test", version = 1, points = points }
        end

        it("accepts a valid route", function()
            assert.is_true(R.Validate(route({ { 1, 2, stop = true, note = "pull" }, { 3, 4 } })))
        end)

        it("rejects a missing instanceID", function()
            local ok, err = R.Validate({ version = 1, points = {} })
            assert.is_false(ok)
            assert.matches("instanceID", err)
        end)

        it("rejects an unknown version", function()
            local r = route({})
            r.version = 2
            local ok, err = R.Validate(r)
            assert.is_false(ok)
            assert.matches("version", err)
        end)

        it("rejects a point without coordinates", function()
            local ok, err = R.Validate(route({ { 1, stop = true } }))
            assert.is_false(ok)
            assert.matches("point 1", err)
        end)

        it("rejects a note on a bend", function()
            local ok, err = R.Validate(route({ { 1, 2, note = "x" } }))
            assert.is_false(ok)
            assert.matches("point 1", err)
        end)
    end)
end)
