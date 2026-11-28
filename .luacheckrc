-- Luacheck configuration for TankRoutes WoW addon
std = "lua51"
max_line_length = false

-- Addon globals (writable)
globals = {
    "TankRoutes",
    "TankRoutesDB",
    "SLASH_TANKROUTES1",
    "SlashCmdList",
}

read_globals = {
    -- WoW Frame API
    "CreateFrame", "UIParent", "GameTooltip", "DEFAULT_CHAT_FRAME",

    -- WoW game state
    "GetTime", "GetInstanceInfo", "IsInInstance", "InCombatLockdown",
    "GetCursorPosition", "IsShiftKeyDown", "IsControlKeyDown", "IsMouseButtonDown", "GetBuildInfo",

    -- Modern client APIs (Forever)
    "issecretvalue", "C_Timer", "C_Map", "C_ChatInfo", "Enum",

    -- Lua globals exposed by WoW
    "strsplit", "strjoin", "tinsert", "tremove", "wipe", "format", "date",
    "floor", "ceil", "abs", "min", "max",
}

ignore = {
    "211",  -- Unused local variable
    "212",  -- Unused argument (common in WoW callbacks)
    "213",  -- Unused loop variable
    "311",  -- Value assigned to variable is unused
    "412",  -- Redefining local variable
    "421",  -- Shadowing local variable
    "431",  -- Shadowing upvalue (common with 'self' in nested callbacks)
    "432",  -- Shadowing upvalue argument
    "542",  -- Empty if branch
    "611",  -- Line contains only whitespace
}

exclude_files = {
    ".lua",
    ".luarocks",
    "lua_modules",
}

files["tests/**/*.lua"] = {
    std = "+busted",
    -- specs reset mock state on these between runs
    globals = { "DEFAULT_CHAT_FRAME", "TankRoutesDB" },
}
