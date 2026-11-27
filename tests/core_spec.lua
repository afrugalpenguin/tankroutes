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
end)
