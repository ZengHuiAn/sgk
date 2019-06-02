local Property  = require "battlefield2.component.Property"
local EntityBag = require "battlefield2.component.EntityBag"
local Skill     = require "battlefield2.component.Skill"
local Pet       = require "battlefield2.component.Pet"
local PetHealth = require "battlefield2.component.PetHealth"
local Force     = require "battlefield2.component.Force"
local Entity    = require "battlefield2.Entity"
local Config    = require "battlefield2.component.Config"

local M = {API = {}, EVENT = {}}

function M.Start(game)
end

function M.Tick(game)
    local list = game:FindAllEntityWithComponent("Health","Pet")
    for _, v in ipairs(list) do        
        if not v:Alive() or v.Pet:FirstCount() == 0 then
            game:RemoveEntity(v.uuid);
        end
    end
end

function M.Stop(game)
end

function M.EVENT.ENTITY_WILL_REMOVE(game, uuid, entity)
    if entity.PetInventory then
        entity.PetInventory:Clean();
    end
end

function M.EVENT.ENTITY_ADD(game, uuid, entity)
    if not entity.Pet then return end

    local owner = game:GetEntity(entity.Pet.target)
    if owner and owner.PetInventory then
        owner.PetInventory:Add(entity);
        --[[
        if entity.Property and owner.Property then
            owner.Property:Add(entity.uuid, entity.Property);
        end
        --]]
    end
end

function M.Add(game, owner, id, count, cd, property)
    local entity = Entity();

    entity:AddComponent('Pet',           Pet(owner.uuid));
    entity:AddComponent('Force',         Force(owner.Force.pid, owner.Force.side));
    entity:AddComponent('BuffInventory', EntityBag());

    local cfg = entity:AddComponent('Config', Config('PET', id));

    if cfg.cfg and cfg.cfg.property_list then
        for k, v in pairs(cfg.cfg.property_list) do
            property[k] = (property[k] or 0) + v
        end
    end

    local p = entity:AddComponent('Property',      Property(property));

    local skill_id = (p.skill and p.skill ~= 0) and p.skill or cfg.skill

    entity:AddComponent('Health',        PetHealth(cfg.hp_type));
    entity:AddComponent('Skill',         Skill({skill_id}));

    entity:Increace(count, cd);

    game:LOG('AddPet', id, cfg.name, skill_id);

    game:AddEntity(entity);

    return entity;
end

function M.API.UnitPetList(skill, target)
    if not target.PetInventory then
        return {}
    end

    local list = target.PetInventory:FindAllEntityWithComponent("Pet")
    local Pets = {}
    for _, v in ipairs(list) do
        table.insert(Pets, v:Export());
    end
    return Pets;
end

function M.API.SummonPet(skill, id, count, cd, property)
    if not skill.entity.PetInventory then
        return;
    end

    local pet_list = skill.entity.PetInventory:FindAllEntityWithComponent();
    local round_info = skill.game:GetGlobalData();
    local cd = cd + round_info.round

    for _, v in ipairs(pet_list) do
        if v.Config.id == id then
            skill.game:DispatchEvent('PAT_COUNT_CHANGE');
            v:Increace(count, cd);
            return v:Export()
        end
    end

    return M.Add(skill.game, skill.entity, id, count, cd, property):Export()
end

function M.API.GetPetCount(skill, pet)
    return pet:Count();
end

return M;
