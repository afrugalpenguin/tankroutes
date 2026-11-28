require("wow_api")

describe("Core", function()
    before_each(function()
        _G.TankRoutes = nil
        DEFAULT_CHAT_FRAME.messages = {}
        dofile("Core.lua")
    end)

    it("exposes the global table", function()
        assert.is_table(TankRoutes)
    end)

    it("has a semantic version", function()
        assert.matches("^%d+%.%d+%.%d+$", TankRoutes.version)
    end)

    it("registers /tr and prints with the [TR] prefix", function()
        assert.equals("/tr", SLASH_TANKROUTES1)
        SlashCmdList["TANKROUTES"]("")
        assert.matches("%[TR%]", DEFAULT_CHAT_FRAME.messages[1])
    end)

    it("mirrors printed lines into TankRoutesDB.log", function()
        _G.TankRoutesDB = {}
        TankRoutes:Print("hello")
        assert.same({ "hello" }, _G.TankRoutesDB.log)
    end)

    it("keeps at most 200 log lines", function()
        _G.TankRoutesDB = {}
        for i = 1, 205 do TankRoutes:Print("line " .. i) end
        assert.equals(200, #_G.TankRoutesDB.log)
        assert.equals("line 6", _G.TankRoutesDB.log[1])
    end)

    it("creates TankRoutesDB on ADDON_LOADED", function()
        _G.TankRoutesDB = nil
        TankRoutes.OnEvent(nil, "ADDON_LOADED", "TankRoutes")
        assert.is_table(_G.TankRoutesDB)
    end)
end)
