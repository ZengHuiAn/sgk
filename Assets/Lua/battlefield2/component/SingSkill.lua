local class = require "utils.class"

local M = class();

function M:_init_(creator, type, total, current, beat_back, certainly_increase)
    self.creator            = creator;
    self.type               = type;
    self.total              = total;
    self.current            = current;
    self.beat_back          = beat_back;
    self.certainly_increase = certainly_increase;

    self.last_current       = current;
    self.last_beat_back     = beat_back;
    self.last_certainly_increase = certainly_increase;
end

function M:Serialize()
    return {self.creator, self.type, self.total, self.current, self.beat_back, self.certainly_increase}
end

function M:DeSerialize(data)
    self.creator, self.type, self.total, self.current, self.beat_back, self.certainly_increase = data[1], data[2], data[3], data[4], data[5], data[6]
end

function M:SerializeChange()
    if self.last_current ~= self.current 
    or self.last_beat_back ~= self.beat_back
    or self.last_certainly_increase ~= self.certainly_increase then
        self.last_current            = self.current;
        self.last_beat_back          = self.beat_back;
        self.last_certainly_increase = self.certainly_increase;

        return {self.current, self.beat_back, self.certainly_increase}
    end
end

function M:ApplyChange(changes)
    self.current            = changes[1];
    self.beat_back          = changes[2];
    self.certainly_increase = changes[3];
end
 
return M;
