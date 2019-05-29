local class = require "utils.class"

local M = class();

function M:_init_(pid, level, name)
    self.pid   = pid; 
    self.level = level;
    self.name  = name;
    self.ready = 0;
    self.last_ready = self.ready;
end

function M:Serialize()
    return {self.pid, self.level, self.name, self.ready}
end

function M:DeSerialize(data)
    self.pid, self.level, self.name, self.ready = data[1], data[2], data[3], data[4]
end

function M:SerializeChange()
    if self.last_ready ~= self.ready then
        self.last_ready = self.ready
        return {self.ready}
    end
end

function M:ApplyChange(changes)
    self.ready = changes[1]
end

return M;
