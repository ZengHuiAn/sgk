local class = require "utils.class"

local M = class();

function M:_init_(duration)
    self.duration = duration or 0; 
    self.timeout_tick = nil;
    self.last_timeout_tick = nil;
end

function M:Serialize()
    return {self.timeout_tick}
end

function M:DeSerialize(data)
    self.timeout_tick = data[1]
end

function M:SerializeChange()
    if self.last_timeout_tick ~= self.timeout_tick then
        self.last_timeout_tick = self.timeout_tick;
        return {self.timeout_tick}
    end
end

function M:ApplyChange(changes)
    self.timeout_tick = changes[1];
end


return M;
