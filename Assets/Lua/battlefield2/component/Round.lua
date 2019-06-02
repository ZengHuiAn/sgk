local class = require "utils.class"

local M = class();

function M:_init_(round, invisible)
    -- self.wave      = 0;
    self.round     = round or 1;
    self.act_point = 1;
    self.invisible = invisible or 0;
    self.last_invisible = self.invisible;
    self.last_round = self.round;
    self.action    = false;
end

function M:Serialize()
    return {self.round, self.act_point, self.invisible}
end

function M:DeSerialize(data)
    self.round, self.act_point, self.invisible = data[1], data[2], data[3]
end

function M:ChangeRound(round)
    self.round = round
end

function M:SerializeChange()
    if self.last_invisible ~= self.invisible then
        self.last_invisible = self.invisible
        return {self.round, self.invisible}
    end

    if self.last_round ~= self.round then
        self.last_round = self.round
        return {self.round}
    end
end

function M:ApplyChange(changes)
    self.round = changes[1]
    self.invisible = changes[2] or self.invisible
end
 
return M;
