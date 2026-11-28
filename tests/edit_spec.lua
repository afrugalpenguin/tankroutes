require("wow_api")

describe("Edit", function()
    local E

    before_each(function()
        _G.TankRoutes = nil
        dofile("Core.lua")
        dofile("Core/Route.lua")
        dofile("Core/Edit.lua")
        E = TankRoutes.Edit
    end)

    local function route(points)
        return { instanceID = 36, title = "Test", version = 1, points = points }
    end

    describe("Copy", function()
        it("copies nested tables so changes do not leak", function()
            local r = route({ { 1, 2, stop = true, note = "a" } })
            local c = E.Copy(r)
            assert.same(r, c)
            c.points[1][1] = 9
            c.points[1].note = "b"
            assert.equals(1, r.points[1][1])
            assert.equals("a", r.points[1].note)
        end)
    end)

    describe("NewPoint", function()
        it("makes a stop or a bend", function()
            assert.same({ 1, 2, stop = true }, E.NewPoint(1, 2, true, 1))
            assert.same({ 1, 2 }, E.NewPoint(1, 2, false, 1))
        end)

        it("stores the floor only when it is not 1", function()
            assert.same({ 1, 2, stop = true, floor = 3 }, E.NewPoint(1, 2, true, 3))
            assert.is_nil(E.NewPoint(1, 2, true, nil).floor)
        end)
    end)

    describe("point edits", function()
        local pts

        before_each(function()
            pts = { { 0, 0, stop = true }, { 1, 1 }, { 2, 2, stop = true } }
        end)

        it("appends at the end", function()
            E.Append(pts, { 3, 3 })
            assert.equals(4, #pts)
            assert.same({ 3, 3 }, pts[4])
        end)

        it("inserts so the new point takes the index", function()
            E.Insert(pts, 2, { 9, 9, stop = true })
            assert.same({ 9, 9, stop = true }, pts[2])
            assert.same({ 1, 1 }, pts[3])
            local _, n = TankRoutes.Route.StopNumbers(pts)
            assert.equals(3, n)
        end)

        it("moves a point and keeps its other fields", function()
            pts[1].note = "pull"
            E.Move(pts, 1, 5, 6)
            assert.same({ 5, 6, stop = true, note = "pull" }, pts[1])
        end)

        it("deletes a point", function()
            E.Delete(pts, 2)
            assert.equals(2, #pts)
            assert.same({ 2, 2, stop = true }, pts[2])
        end)

        it("sets a trimmed note on a stop", function()
            assert.is_true(E.SetNote(pts, 1, "  pull with next  "))
            assert.equals("pull with next", pts[1].note)
        end)

        it("clears the note when the text is empty", function()
            pts[1].note = "x"
            assert.is_true(E.SetNote(pts, 1, "   "))
            assert.is_nil(pts[1].note)
        end)

        it("refuses a note on a bend", function()
            assert.is_false(E.SetNote(pts, 2, "x"))
            assert.is_nil(pts[2].note)
        end)

        it("keeps the route valid", function()
            E.Insert(pts, 2, E.NewPoint(4, 4, true, 2))
            E.SetNote(pts, 2, "upstairs")
            E.Delete(pts, 3)
            assert.is_true(TankRoutes.Route.Validate(route(pts)))
        end)
    end)

    describe("history", function()
        it("pops entries newest first", function()
            local h = E.NewHistory()
            E.Push(h, "a")
            E.Push(h, false)
            local ok, v = E.Pop(h)
            assert.is_true(ok)
            assert.is_false(v)
            ok, v = E.Pop(h)
            assert.is_true(ok)
            assert.equals("a", v)
        end)

        it("reports when there is nothing to undo", function()
            assert.is_false((E.Pop(E.NewHistory())))
        end)

        it("keeps only the last UNDO_MAX entries", function()
            local h = E.NewHistory()
            for i = 1, E.UNDO_MAX + 5 do E.Push(h, i) end
            local count, first = 0, nil
            while true do
                local ok, v = E.Pop(h)
                if not ok then break end
                count, first = count + 1, v
            end
            assert.equals(20, E.UNDO_MAX)
            assert.equals(E.UNDO_MAX, count)
            assert.equals(6, first)
        end)
    end)

    describe("storage", function()
        local bundled

        before_each(function()
            bundled = { [36] = route({ { 0.5, 0.5, stop = true } }) }
        end)

        it("shows the bundled route when nothing is saved", function()
            local r, source = E.Active({}, bundled, 36)
            assert.equals(bundled[36], r)
            assert.equals("bundled", source)
        end)

        it("shows nothing when there is no route", function()
            assert.is_nil((E.Active({}, bundled, 99)))
        end)

        it("prefers the saved route", function()
            local db = { routes = { [36] = route({}) } }
            local r, source = E.Active(db, bundled, 36)
            assert.equals(db.routes[36], r)
            assert.equals("saved", source)
        end)

        it("falls back to the bundled route when the saved one is invalid", function()
            local db = { routes = { [36] = { version = 1 } } }
            local r, source, err = E.Active(db, bundled, 36)
            assert.equals(bundled[36], r)
            assert.equals("bundled", source)
            assert.matches("title", err)
            assert.same({ version = 1 }, db.routes[36])
        end)

        it("copies the bundled route on the first edit", function()
            local db = {}
            local r = E.Editable(db, bundled, 36, "Custom route")
            assert.equals(db.routes[36], r)
            assert.same(bundled[36], r)
            r.points[1][1] = 0.1
            assert.equals(0.5, bundled[36].points[1][1])
            assert.equals(r, E.Editable(db, bundled, 36, "Custom route"))
        end)

        it("starts an empty route when nothing is bundled", function()
            local db = {}
            local r = E.Editable(db, bundled, 99, "Custom route")
            assert.same({ instanceID = 99, title = "Custom route", version = 1, points = {} }, r)
            assert.is_true(TankRoutes.Route.Validate(r))
        end)

        it("replaces an invalid saved route on the first edit", function()
            local db = { routes = { [36] = { version = 1 } } }
            local r = E.Editable(db, bundled, 36, "Custom route")
            assert.same(bundled[36], r)
        end)

        it("snapshots and restores the saved route", function()
            local db = {}
            assert.is_false(E.Saved(db, 36))
            local r = E.Editable(db, bundled, 36, "Custom route")
            local snap = E.Saved(db, 36)
            assert.same(r, snap)
            assert.are_not.equal(r, snap)
            E.Restore(db, 36, false)
            assert.is_nil(db.routes[36])
            E.Restore(db, 36, snap)
            assert.same(r, db.routes[36])
            assert.are_not.equal(snap, db.routes[36])
        end)
    end)
end)
