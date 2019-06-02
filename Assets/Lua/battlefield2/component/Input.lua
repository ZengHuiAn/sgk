
local class = require "utils.class"

local M = class()

function M:_init_()
    self.data = {}
    self.token = false;
    self._last_token = false;
end

function M:Start()
end

function M:OnDestroy()
end

function M:Serialize()
    return {self.token};
end

function M:DeSerialize(data)
    self.token = data[1];
end

function M:SerializeChange()
    if self._last_token ~= self.token then
        self._last_token = self.token;
        return {self.token}
    end
end

function M:ApplyChange(changes)
    self.token = changes[1];
end

return M;
