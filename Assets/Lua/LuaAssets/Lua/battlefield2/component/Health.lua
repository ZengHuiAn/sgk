local class = require "utils.class"

local M = class();

local function range(v, a, b)
    return (v<a) and a or ( (v>b) and b or v )
end

function M:Change(value)
    local property = self.entity:GetComponent("Property");
    if property then
        local hp, hpp = property:Get('hp'), property:Get('hpp');
        property:Set('hp', range(hp + value, 0, hpp));
    end
end

function M:Alive()
    local property = self.entity:GetComponent("Property");
    if property then
        return property:Get('hp') > 0
    end
end

function M:Serialize()
end

function M:Hurt(value)
    if value <= 0 then return end
    self:Change(-value);
end

function M:Health(value)
    if value <= 0 then return end
    self:Change(-value);
end

function M:HP()
    return self.entity.Property:Get('hp');
end

function M:MaxHP()
    return self.entity.Property:Get('hpp');
end

M.exports = {
    {"Hurt",   M.Hurt},
    {"Health", M.Health},

    {"ChangeHP", M.Change},

    {"HP",     M.HP},
    {"MaxHP",  M.MaxHP},

    {"Alive",  M.Alive},
}

return M;
