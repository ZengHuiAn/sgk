local class = require "utils.class"

local M = class();

function M:_init_(from, to, duration, id)
    self.from = from or 0; 
    self.to = to or 0;
    self.duration = duration;
    self.id = id;
end

function M:Serialize()
    if self.id then
        return {self.from, self.to, self.duration, self.id};
    end
end

function M:DeSerialize(data)
    self.from, self.to, self.duration, self.id = data[1], data[2], data[3], data[4];
end

return M;
