local class = require "utils.class"

local M = class();

function M:_init_()
    self.entities = {}
end

function M:Serialize()
end

function M:Add(e)
    if self.entities[e.uuid] then
        return;
    end

    self.entities[e.uuid] = e;
end

function M:Remove(uuid)
    local e = self.entities[uuid]
    if e then
        self.entities[uuid] = nil
    end
end

function M:Get(uuid)
    return self.entities[uuid];
end

function M:Clean()
    local list = {}
    for _, v in pairs(self.entities) do
        table.insert(list, v)
    end
    self.entities = {}

    for _, v in ipairs(list) do
        v.game:RemoveEntity(v.uuid);
    end
end

local function entity_sort(a, b ) 
    return a.uuid < b.uuid
end

function M:FindAllEntityWithComponent(...)
    local game = self.entity.game;

    local list = {}
    for uuid, _ in pairs(self.entities) do
        local e = game:GetEntity(uuid);
        if e then
            local skip = false;
            for _, v in ipairs({...}) do
                if not e:GetComponent(v) then
                    skip = true;
                    break;
                end
            end

            if not skip then
                table.insert(list, e);
            end
        else
            self.entities[uuid] = nil;
        end
    end

    table.sort(list, entity_sort);

    return list;
end

return M;
