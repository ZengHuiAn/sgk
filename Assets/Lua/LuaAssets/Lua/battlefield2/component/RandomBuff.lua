local class = require "utils.class"

local M = class()

function M:_init_(creater)
    self.creater = creater;
    self.holder = 0;
    self._last_holer = 0;
end

function M:Serialize()
    return {self.creater, self.holder}
end

function M:DeSerialize(data)
    self.creater = data[1]
    self.holder = data[2]
end

function M:SerializeChange()
    if self._last_holer ~= self.holder then
        self._last_holer = self.holder;
        return {self.holder}
    end
end

function M:ApplyChange(changes)
    self.holder = changes[1];
end
 
return M;
