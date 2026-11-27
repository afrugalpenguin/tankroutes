-- Minimal WoW API mocks for testing
_G.TankRoutes = nil
_G.TankRoutesDB = {}
_G.SlashCmdList = {}

_G.GetTime = function() return os.time() end

-- Chat frame that records messages so specs can assert on output
_G.DEFAULT_CHAT_FRAME = {
    messages = {},
    AddMessage = function(self, msg) table.insert(self.messages, msg) end,
}
