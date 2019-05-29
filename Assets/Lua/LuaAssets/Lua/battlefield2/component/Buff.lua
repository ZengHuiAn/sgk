local class = require "utils.class"

local M = class()

function M:_init_(target, duration, pass)
    self.target   = target;
    self.duration = duration;
end

function M:Start()
end

function M:OnDestroy()
end

function M:Serialize()
    return {self.duration, self.target}
end

function M:DeSerialize(data)
    self.duration, self.target = data[1], data[2]
end

function M:ChangeDuration(duration)
    self.duration = duration;
    self.duration_changed = true;
end

function M:SerializeChange()
    if self.duration_changed then
        self.duration_changed = nil;
        return {self.duration, self.target}
    end
end

function M:ApplyChange(changes)
    self.duration = changes[1]
    self.target   = changes[2]
end

return M;
