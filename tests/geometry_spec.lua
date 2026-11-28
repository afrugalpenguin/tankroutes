require("wow_api")

describe("Geometry", function()
    local G

    before_each(function()
        _G.TankRoutes = nil
        dofile("Core.lua")
        dofile("Core/Geometry.lua")
        G = TankRoutes.Geometry
    end)

    describe("HalfExtents", function()
        it("is half the size when not rotated", function()
            local ex, ey = G.HalfExtents(64, 32, 0)
            assert.near(32, ex, 1e-9)
            assert.near(16, ey, 1e-9)
        end)

        it("swaps width and height at a quarter turn", function()
            local ex, ey = G.HalfExtents(64, 32, math.pi / 2)
            assert.near(16, ex, 1e-9)
            assert.near(32, ey, 1e-9)
        end)
    end)

    describe("Bounds", function()
        it("contains every room", function()
            local rooms = {
                { 1, 100, 200, 20, 10, 0, 0 },
                { 2, 150, 260, 40, 40, 0, 0 },
            }
            assert.same({ 90, 195, 170, 280 }, G.Bounds(rooms))
        end)

        it("returns nil for no rooms", function()
            assert.is_nil(G.Bounds({}))
        end)
    end)

    describe("FitScale", function()
        it("fits the limiting side", function()
            -- 200 x 100 yards into 300 x 300 pixels: width limits, 1.5 px per yard
            assert.near(1.5, G.FitScale({ 0, 0, 200, 100 }, 300, 300, 0), 1e-9)
        end)

        it("applies the margin", function()
            assert.near(1.35, G.FitScale({ 0, 0, 200, 100 }, 300, 300, 0.1), 1e-9)
        end)

        it("returns 1 for degenerate input", function()
            assert.equals(1, G.FitScale({ 0, 0, 0, 0 }, 300, 300, 0))
        end)
    end)

    describe("ToScreen", function()
        local view = { k = 2, cu = 100, cv = 50, w = 300, h = 200 }

        it("puts the view centre in the middle", function()
            local x, y = G.ToScreen(100, 50, view)
            assert.equals(150, x)
            assert.equals(100, y)
        end)

        it("moves east right and south down", function()
            local x, y = G.ToScreen(110, 60, view)
            assert.equals(170, x)
            assert.equals(120, y)
        end)
    end)

    describe("Pan", function()
        it("dragging right shows land further west", function()
            local view = { k = 2, cu = 100, cv = 50, w = 300, h = 200 }
            G.Pan(view, 20, 10)
            assert.equals(90, view.cu)
            assert.equals(45, view.cv)
        end)
    end)

    describe("Zoom", function()
        it("multiplies the scale and clamps it", function()
            local view = { k = 2 }
            G.Zoom(view, 2, 1, 3)
            assert.equals(3, view.k)
            G.Zoom(view, 0.1, 1, 3)
            assert.equals(1, view.k)
        end)
    end)
end)
