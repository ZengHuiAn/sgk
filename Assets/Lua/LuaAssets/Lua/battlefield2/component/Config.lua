local class = require "utils.class"

local battle_config = require "config.battle";

local M = class();

local ConfigType = {
    ROLE  = 1,
    PET   = 2,
    BUFF  = 3,
}

function M:_init_(type, id, extra)
    self.id    = id or 0;
    self.type  = ConfigType[type] or type or 0;
    self.extra = extra or {}
    self.cfg   = {}

    M.loadConfig(self);
end

function M:Serialize()
    local info = {self.type, self.id, {}}
    for k, v in pairs(self.extra) do
        if type(v) == "number" or type(v) == "string" or type(v) == "boolean" then
            table.insert(info[3], {k, v}); 
        else
            self.entity.game:LOG('extra', k, "can not serialize"); 
        end
    end
    return info;
end

function M:DeSerialize(data)
    self.type, self.id = data[1], data[2]
    
    for _, v in ipairs(data[3]) do
        self.extra[ v[1] ] = v[2]
    end

    self:loadConfig();
end

function M:loadConfig()
    if self.type == 0 then self.cfg = {}; return end

    if self.type == 1 then
        local cfg = battle_config.LoadNPC(self.id)
        assert(cfg, 'npc config', self.id, "not exists");

        self.cfg = cfg;
    elseif self.type == 2 then
        local cfg = battle_config.load_pet(self.id)
        assert(cfg, 'pet config', self.id, 'not exists');

        self.cfg = cfg;
    elseif self.type == 3 then
        local cfg = battle_config.LoadBuffConfig(self.id) or {}
        assert(cfg, 'buff config', self.id, 'not exists');
        
        self.cfg = cfg;
    else
        assert(false, 'unknown config type ' .. tostring(self.type));
        self.cfg = {}
    end
end

function M:_getter_(k)
    return self.extra[k] or self.cfg[k]
end

M.exports = { 
    {"id", "id"},
}

return M;
