-- Tank Routes: bundled routes, keyed by instance ID.
-- Test route for the map window. Replace with real routes in build step 5.
local _, TR = ...
TR = TR or TankRoutes

TR.Routes = {
    [36] = {
        instanceID = 36, title = "Test route", version = 1,
        points = {
            { 17414.2, 17130.2, stop = true, note = "Test stop one" },
            { 17448.8, 17136.6 },
            { 17489.6, 17194.6, stop = true },
            { 17461, 17227 },
            { 17550.3, 17257.7, stop = true, note = "Test stop three" },
        },
    },
}
