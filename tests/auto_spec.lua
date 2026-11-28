require("wow_api")

describe("Auto", function()
    local A

    before_each(function()
        _G.TankRoutes = nil
        dofile("Core.lua")
        dofile("Core/Auto.lua")
        A = TankRoutes.Auto
    end)

    describe("Enabled", function()
        it("is on by default", function()
            assert.is_true(A.Enabled({}))
            assert.is_true(A.Enabled(nil))
        end)

        it("is off only when turned off", function()
            assert.is_false(A.Enabled({ autoOpen = false }))
            assert.is_true(A.Enabled({ autoOpen = true }))
        end)
    end)

    describe("Decide", function()
        it("opens on entering a dungeon with a route", function()
            assert.equals("open", A.Decide({ prev = nil, new = 36, enabled = true, hasRoute = true }))
        end)

        it("opens when moving straight into another dungeon", function()
            assert.equals("open", A.Decide({ prev = 33, new = 36, enabled = true, hasRoute = true }))
        end)

        it("does nothing without a route", function()
            assert.is_nil(A.Decide({ prev = nil, new = 36, enabled = true, hasRoute = false }))
        end)

        it("does nothing when turned off", function()
            assert.is_nil(A.Decide({ prev = nil, new = 36, enabled = false, hasRoute = true }))
        end)

        it("does not reopen inside the same dungeon", function()
            assert.is_nil(A.Decide({ prev = 36, new = 36, enabled = true, hasRoute = true }))
        end)

        it("closes on leaving when it opened the window", function()
            assert.equals("close", A.Decide({ prev = 36, new = nil, autoOpened = true }))
        end)

        it("leaves a window the player opened", function()
            assert.is_nil(A.Decide({ prev = 36, new = nil, autoOpened = false }))
        end)

        it("does nothing outside dungeons", function()
            assert.is_nil(A.Decide({ prev = nil, new = nil, autoOpened = true }))
        end)
    end)
end)
