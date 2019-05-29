local class = require "utils.class"

local M = class();

function M:_init_(uuid, value, type, name, follow_effect)
    self.uuid = uuid; 
    self.value = value;
    self.type = type;
    self.name = name;
    self.follow_effect = follow_effect or 0;
end

function M:Serialize()
    return {self.uuid, self.value, self.type, self.name, self.follow_effect};
end

function M:DeSerialize(data)
    self.uuid, self.value, self.type, self.name, self.follow_effect = data[1], data[2], data[3], data[4], data[5];
end

return M;
