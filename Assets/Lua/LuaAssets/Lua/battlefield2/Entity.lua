local class = require "utils.class"

local Entity = class({})

function Entity:_init_(uuid)
    self.uuid = uuid or 0;
    self.component = {}
    self.caches = {}
    self.api = {}
end

function Entity:AddComponent(name, comp)
    self.component[name] = comp;
    rawset(comp, "entity", self);

    for _, v in pairs(comp.exports or {}) do
        local k, f = v[1], v[2]
        if self.api[k] then
            assert(false, string.format('duplicate api %s from %s - %s',
                        k, self.api[k].n, name));
        end
        self.api[k] = {c = comp, f = f, n = name};
    end

    return comp;
end

function Entity:GetComponent(name)
    return self.component[name];
end

function Entity:Serialize()
    local data = {self.uuid, {}}

    for name, comp in pairs(self.component) do
        if comp.Serialize and comp.hide ~= false then
            table.insert(data[2], {name, comp:Serialize()});
        end
    end

    return data;
end

function Entity:SerializeChange()
    local data = {self.uuid, {}}

    for name, comp in pairs(self.component) do
        if comp.SerializeChange then
            local change = comp:SerializeChange();
            if change then
                table.insert(data[2], {name, change})
            end
        end
    end

    if #data[2] > 0 then
        return data;
    end
end

function Entity:DeSerialize(data)
    self.uuid = data[1];
    self.component = {}

    n = #data;

    for i = 2, n do
        local name, comp = ComponentFactory.DeSerialize(data[i]);
        self.component[name] = comp;
    end
end


function Entity:ApplyChange(data)
    local uuid = self.uuid;
    assert(uuid == self.uuid);

    local uuid, changes = data[1], data[2];

    local n = #changes;

    for i = 1, n do
        local name, change = changes[i][1], changes[i][2];
        local comp = self.component[name]
        if comp then
            comp:ApplyChange(change);
        end
    end
end

function Entity:Start(game)
    rawset(self, 'game', game);

    for _, v in pairs(self.component) do
        if v.Start then
            v:Start(game);
        end
    end
end

function Entity:_getter_(k)
    local api = self.api[k]

    if not api then
        return self.component[k];
    end

    if type(api.f) == "function" then
        return function(_, ...)
            return api.f(api.c, ...);
        end
    elseif type(api.f) == "string" then
        return api.c[k]
    end
end

function Entity:_setter_(k, v)
    assert(self.component[k] == nil and self.api[k] == nil, 
            string.format('entity:_setter_ --> %s', tostring(k)));
    rawset(self, k, v);
end

function Entity:OnDestroy(game)
    rawset(self, 'game', nil);

    for _, v in pairs(self.component) do
        if v.OnDestroy then
            v:OnDestroy(game);
        end
    end
end

local function roleGetter(t, k)
    if t.entity[k] ~= nil then
        return t.entity[k];
    end

    if t.entity.Config and t.entity.Config[k] ~= nil then
        return t.entity.Config[k];
    end

    return t.entity.Property[k];
end

local function roleSetter(t, k, v)
    if t.entity[k] ~= nil then
        t.entity[k] = v;
        return;
    end

    if t.entity.Config and t.entity.Config[k] ~= nil then
        assert(false, "cant't set role config  " .. k);
    end

    if type(v) == "number" then
        t.entity.Property:Set(k, v);
    else
        t.entity[k] = v;
    end
end

local entity_to_role_metatable = {
    __index = roleGetter,
    __newindex = roleSetter,
}

function Entity:Export()
    return setmetatable({entity = self, _visit_count_ = 0}, entity_to_role_metatable);
end

return Entity;
