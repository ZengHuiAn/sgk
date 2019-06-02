local class = require "utils.class"

local M = class();

function M:_init_(id, index, duration, side, pet_id, pid)
    self.id       = id;
    self.duration = duration;
    self.index    = index;
    self.side     = side or 1;
    self.pet_id   = pet_id or 0;
    self.pid      = pid or 0;
end

function M:Serialize()
    if self.id then
        return {self.id, self.index, self.duration, self.side, self.pet_id, self.pid};
    end
end

function M:DeSerialize(data)
    self.id, self.index, self.duration, self.side, self.pet_id, self.pid = data[1], data[2], data[3], data[4], data[5], data[6];
end

return M;
