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

        it("rejects a non-table route", function()
            local ok, err = R.Validate(nil)
            assert.is_false(ok)
            assert.matches("not a table", err)
        end)

        it("rejects a missing title", function()
            local r = route({})
            r.title = nil
            local ok, err = R.Validate(r)
            assert.is_false(ok)
            assert.matches("title", err)
        end)

        it("rejects missing points", function()
            local ok, err = R.Validate(route(nil))
            assert.is_false(ok)
            assert.matches("points", err)
        end)

        it("accepts an empty points list", function()
            assert.is_true(R.Validate(route({})))
        end)

        it("rejects a non-table point", function()
            local ok, err = R.Validate(route({ 5 }))
            assert.is_false(ok)
            assert.matches("point 1", err)
        end)

        it("rejects a string coordinate", function()
            local ok, err = R.Validate(route({ { "1", 2 } }))
            assert.is_false(ok)
            assert.matches("point 1", err)
        end)

        it("rejects a missing u", function()
            local ok, err = R.Validate(route({ { [2] = 2 } }))
            assert.is_false(ok)
            assert.matches("point 1", err)
        end)

        it("rejects an infinite coordinate", function()
            local ok, err = R.Validate(route({ { math.huge, 2 } }))
            assert.is_false(ok)
            assert.matches("point 1", err)
        end)

        it("rejects a non-string note on a stop", function()
            local ok, err = R.Validate(route({ { 1, 2, stop = true, note = 5 } }))
            assert.is_false(ok)
            assert.matches("point 1", err)
        end)
    end)
end)
