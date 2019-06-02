local class = require "utils.class"
local SkillConfig = require "config.skill"

local M = class()

function M:_init_(ids)
    self.ids = ids or {}
    self.script = nil;
end

function M:Start()
end

function M:OnDestroy()
end

function M:Serialize()
    return self.ids
end

function M:DeSerialize(data)
    self.ids = {}
    for k, v in ipairs(data) do
        self.ids[k] = v;
    end
    self.script = nil;
end

function M:SerializeChange()
    local info = {}
    for id, skill in pairs(self.save or {}) do
        local change = skill.property:SerializeChange();
        if change then
            table.insert(info, {id, change});
        end
    end

    if #info > 0 then
        return info;
    end
end

function M:ApplyChange(changes)
    if not self.save then
        return;
    end

    for _, info in ipairs(changes) do
        local id, data = info[1], info[2];
        local skill = self.save[id]
        if skill then
            skill.property:ApplyChange(data);
        else
            --TODO: create new skill
        end
    end
end

return M;
