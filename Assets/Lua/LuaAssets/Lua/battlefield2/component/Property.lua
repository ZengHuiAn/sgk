local class = require "utils.class"
local default_formula = require "utils.PropertyFormula"

local M = class()

local warp_meta = {
    __index    = function(t, k)    return t.P:Get(k)   end,
    __newindex = function(t, k, v) return t.P:Set(k,v) end,
}

function M:_init_(values)
    self.values = values or {}

    self.property_list = self.values;

    self.formula = default_formula

    self.merge  = {}
    self.change = {}
    self.cache  = {}

    self.path    = {}
    self.depends = {}

    self.property_keys = {}
    for k, v in pairs(self.property_list) do 
        self.property_keys[k] = v
    end

    self.change_record = {}

    self.warp = setmetatable({P=self}, warp_meta)
end

function M:Start()
end

function M:OnDestroy()
end

function M:Get(key)
    if #self.path > 0 then
        self.depends[key] = self.depends[key] or {};
        for _, v in ipairs(self.path) do
            self.depends[key][v] = true;
            -- depend loop check
            if key == v then
                local str = '\n[WARNING] ' .. key .. " depend loop: ";
                for _, v in ipairs(self.path) do
                    str = str .. v .. " -> ";
                end
                str = str .. key;
                assert(false, str);
            end
        end
    end

    local change = self.change[key] or 0;

    local v = self.cache[key];
    if v then
        return v + change;
    end

    local c = self.formula[key];
    if c then
        self.path[#self.path + 1] = key;
        v = c and c(self.warp) or 0;
        self.path[#self.path] = nil;
    else
        v = self.values[key] or 0;
        for xx, m in pairs(self.merge) do
            v = v + (m and m[key] or 0)
        end
    end

    self.cache[key] = v;
    return v + change;
end

function M:_getter_(key)
    return self:Get(key);
end

function M:_setter_(key, value)
    return self:Set(key, value);
end

function M:Set(key, value)
    assert(type(value) == "number", debug.traceback())

    if type(key) ~= "number" and self.formula[key] == nil then
        rawset(self, key, value);
        return;
    end

    local diff = value - self[key]
    if diff == 0 then
        return;
    end

    local change = (self.change[key] or 0) + diff;

    self.change[key] = change
    self.change_record[key] = change;
    if type(key) == "number" then
        self.property_keys[key] = value
    end

    for k, _ in pairs(self.depends[key] or {}) do
        self.cache[k] = nil;
    end
end

function M:Add(key, values)
    self.merge[key] = values;
    self.cache = {}
end

function M:Remove(key)
    if self.merge[key] then
        self.merge[key] = nil
        self.cache = {}
    end
end

function M:Formula(k, func)
    self.formula[k] = func
end

function M:Serialize()
    local list = {{}}
    for k, v in pairs(self.values) do
        table.insert(list[1], {k, v})
    end

    list[2] = self:SerializeChange(true);

    return list;
end

function M:DeSerialize(data)
    self.values  = {}
    self.cache   = {}

    for _, v in ipairs(data[1]) do
        self.values[ v[1] ] = v[2]
    end

    self.change = {}
    self:ApplyChange(data[2] or {});
end

function M:SerializeChange(keep_change_record)
    local list = {}

    for k, v in pairs(self.change_record) do
        table.insert(list, {k, v});
    end
    if not keep_change_record then
        self.change_record = {}
    end

    if #list > 0 then
        return list
    end
end

function M:ApplyChange(changes)
    for _, v in pairs(changes) do
        self.change[ v[1] ] = v[2]
    end
    self.cache = {}
end

M.exports = {}

return M
