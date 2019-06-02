local class = require "utils.class"

local M = class();

function M:_init_(pos, x, y, z)
    self.pos = pos;
    self.x   = x;
    self.y   = y;
    self.z   = z;
end

function M:Serialize()
    return {self.pos, self.x, self.y, self.z}
end

function M:DeSerialize(data)
    self.pos, self.x, self.y, self.z = data[1], data[2], data[3], data[4];
end

M.exports = {
    {"pos", "pos"},
}

return M;
