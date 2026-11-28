-- Tank Routes: route rules. Pure functions, no WoW calls.
-- A route is { instanceID, title, version = 1, points = { { u, v, stop = true, note = "..." }, { u, v } } }.
-- Stop numbers are never stored; they come from the order of the points.
local _, TR = ...
TR = TR or TankRoutes

local R = {}
TR.Route = R

R.VERSION = 1

-- Returns { [pointIndex] = stopNumber } and the number of stops.
function R.StopNumbers(points)
    local nums, n = {}, 0
    for i, p in ipairs(points) do
        if p.stop then
            n = n + 1
            nums[i] = n
        end
    end
    return nums, n
end

-- Returns true, or false and a message saying what is wrong.
function R.Validate(route)
    if type(route) ~= "table" then
        return false, "route is not a table"
    end
    if type(route.instanceID) ~= "number" then
        return false, "instanceID missing"
    end
    if route.version ~= R.VERSION then
        return false, "unsupported version " .. tostring(route.version)
    end
    if type(route.points) ~= "table" then
        return false, "points missing"
    end
    for i, p in ipairs(route.points) do
        if type(p[1]) ~= "number" or type(p[2]) ~= "number" then
            return false, "point " .. i .. " has no coordinates"
        end
        if p.note ~= nil and (type(p.note) ~= "string" or not p.stop) then
            return false, "point " .. i .. " has an invalid note"
        end
    end
    return true
end
