-- Tank Routes: bundled routes, keyed by instance ID.
-- Test route for the map window. Replace with real routes in build step 5.
-- Points on painted maps are 0 to 1 positions on a floor (floor defaults to 1).
local _, TR = ...
TR = TR or TankRoutes

TR.Routes = {
    [36] = {
        instanceID = 36, title = "Test route", version = 1,
        points = {
            { 0.20, 0.70, stop = true, note = "Test stop one" },
            { 0.35, 0.55 },
            { 0.50, 0.50, stop = true },
            { 0.65, 0.40 },
            { 0.80, 0.30, stop = true, note = "Test stop three" },
            { 0.50, 0.50, stop = true, floor = 2, note = "Test stop on floor 2" },
        },
    },
}
