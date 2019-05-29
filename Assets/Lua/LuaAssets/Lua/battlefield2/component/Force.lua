local class = require "utils.class"

local M = class();

function M:_init_(pid, side)
    self.pid = pid or 0
    self.side = side or 0
end

function M:Serialize()
    return {self.pid, self.side}
end

function M:DeSerialize(data)
    self.pid, self.side = data[1], data[2]
end

M.exports = {
    {"side", "side"},
}

return M;
