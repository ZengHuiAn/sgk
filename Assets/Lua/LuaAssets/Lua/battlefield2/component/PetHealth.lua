local class = require "utils.class"

local M = class()

function M:_init_(hp_type)
    -- assert(hp_type >= 1 and hp_type <= 3, "unknown hp_type " .. hp_type);
    self.hp_type   = hp_type;
    self.hp_reduce = 0;
    self.changed = false;
end

function M:Start()
end

function M:OnDestroy()
end

function M:Serialize()
    return {self.hp_reduce, self.hp_type}
end

function M:DeSerialize(data)
    self.hp_reduce, self.hp_type = data[1], data[2] or self.hp_type;
end

function M:SerializeChange()
    if self.changed then
        self.changed = false;
        return {self.hp_reduce}
    end
end

function M:ApplyChange(changes)
    self:DeSerialize(changes);
end

function M:TotalMaxHP()
    return self.entity.Property.hpp * self.entity.Pet:Count()
end

function M:MaxHP()
    return self.entity.Property.hpp;
end

function M:Count()
    return self.entity.Pet:Count();
end

function M:FirstHP()
    local count = self:Count();
    if self.hp_type == 3 then
        return (count > 0) and math.ceil((self:TotalMaxHP() - self.hp_reduce) / count) or 0;
    else
        return (count > 0) and self:MaxHP() - self.hp_reduce or 0;
    end
end

function M:HP()
    return self:TotalMaxHP() - self.hp_reduce;
end

function M:Change(value)
    if value >= 0 then
        self:Health(value)
    else
        self:Hurt(-value)
    end
end

function M:Health(value)
    if value <= 0 then
        return;
    end

    self.hp_reduce = self.hp_reduce - value;
    if self.hp_reduce < 0 then
        self.hp_reduce = 0;
    end
    self.changed = true;
end

function M:Hurt(value)
    if value <= 0 then return; end

    local current_count = self:Count();
    if current_count == 0 then
        return;
    end

    self.changed = true;
    local total_max_hp  = self:TotalMaxHP();
    local single_max_hp = self:MaxHP();

    self.hp_reduce = self.hp_reduce + value;

    if self.hp_type == 1 then
        local left_total_hp = total_max_hp - self.hp_reduce;

        if left_total_hp <= 0 then return self:RemoveAllPet() end

        local left_full_hp_count = math.floor(left_total_hp / single_max_hp);
        local first_hp  = left_total_hp - (left_full_hp_count * single_max_hp);

        local left_count = left_full_hp_count;
        local hp_reduce = 0;
        if first_hp > 0 then
            left_count = left_count + 1;
            hp_reduce = single_max_hp - first_hp;
        end

        if left_count < current_count then
            self.entity.Pet:Remove(current_count - left_count);
        end
        self.hp_reduce = hp_reduce;
    elseif self.hp_type == 2 then
        if self.hp_reduce >= single_max_hp then
            self.hp_reduce = 0;
            self.entity.Pet:Remove(1)
        end
    elseif self.hp_type == 3 then
        if self.hp_reduce >= total_max_hp then
            self:RemoveAllPet();
        end
    else
        assert(false, "unknown hp_type " .. self.hp_type);
    end
end

function M:RemoveAllPet()
    local count = self:Count();
    self.entity.Pet:Remove(count);
    self.hp_reduce = 0;
end

function M:Alive()
    return self:Count() > 0;
end

function M:Reduce(n)
    if n <= 0 then return; end

    local current_count = self:Count();

    if current_count <= n then
        return self:RemoveAllPet();
    end

    if self.hp_type == 1 or self.hp_type == 2 then
        self.hp_reduce = 0;
    elseif self.hp_type == 3 then
        self.hp_reduce = math.floor((self.hp_reduce * (current_count - n)) / current_count)
    end
    self.entity.Pet:Remove(n);
end

function M:Increace(n, round)
    self.entity.Pet:Add(n, round);
end

M.exports = {
    {"Hurt",          M.Hurt},
    {"Health",        M.Health},
    {"Change",        M.Change},
    
    {"Reduce",        M.Reduce},
    {"Increace",      M.Increace}, 

    {"HP",            M.HP},
    {"MaxHP",         M.TotalMaxHP},

    {"Alive",         M.Alive},

    {"FirstHP",       M.FirstHP},
    {"FirstMaxHP",    M.MaxHP},

    {"TotalHP",       M.HP},
    {"TotalMaxHP",    M.TotalMaxHP},
}

return M;
