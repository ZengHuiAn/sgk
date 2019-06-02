local class = require "utils.class"

local M = class();

function M:_init_(duration, round)
    self.duration = duration or 0; 
    self.lasting_round = round or 0; 
end

function M:Serialize()
    return {self.duration, self.lasting_round}
end

function M:DeSerialize(data)
    self.duration, self.lasting_round = data[1], data[2]
end

return M;
