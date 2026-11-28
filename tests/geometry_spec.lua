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

        it("uses absolute values for oblique and negative angles", function()
            local diag = (64 + 32) * math.sqrt(0.5) / 2
            local ex, ey = G.HalfExtents(64, 32, -math.pi / 4)
            assert.near(diag, ex, 1e-9)
            assert.near(diag, ey, 1e-9)
            ex, ey = G.HalfExtents(64, 32, math.pi)
            assert.near(32, ex, 1e-9)
            assert.near(16, ey, 1e-9)
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

        it("uses the rotated size", function()
            local b = G.Bounds({ { 1, 0, 0, 64, 32, math.pi / 2, 0 } })
            assert.near(-16, b[1], 1e-9)
            assert.near(-32, b[2], 1e-9)
            assert.near(16, b[3], 1e-9)
            assert.near(32, b[4], 1e-9)
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

    describe("QuarterTurn", function()
        it("maps multiples of a quarter turn to 0..3", function()
            assert.equals(0, G.QuarterTurn(0))
            assert.equals(1, G.QuarterTurn(math.pi / 2))
            assert.equals(3, G.QuarterTurn(-math.pi / 2))
            assert.equals(2, G.QuarterTurn(math.pi))
        end)

        it("accepts angles within half a degree", function()
            assert.equals(3, G.QuarterTurn(-1.5708))
        end)

        it("returns nil for other angles", function()
            assert.is_nil(G.QuarterTurn(3.1241))
            assert.is_nil(G.QuarterTurn(0.3))
        end)
    end)

    describe("Art", function()
        it("has the 1002 x 668 art bounds", function()
            assert.same({ 0, 0, 1002, 668 }, G.ART_BOUNDS)
        end)

        it("lays out 12 tiles 4 x 3 as rooms", function()
            local rooms = G.ArtRooms("P")
            assert.equals(12, #rooms)
            assert.same({ "P1", 128, 128, 256, 256, 0, 0 }, rooms[1])
            assert.same({ "P4", 896, 128, 256, 256, 0, 0 }, rooms[4])
            assert.same({ "P5", 128, 384, 256, 256, 0, 0 }, rooms[5])
            assert.same({ "P12", 896, 640, 256, 256, 0, 0 }, rooms[12])
        end)

        it("converts 0 to 1 positions to art pixels", function()
            local u, v = G.ArtToMap(0.5, 0.25)
            assert.equals(501, u)
            assert.equals(167, v)
        end)
    end)
end)
