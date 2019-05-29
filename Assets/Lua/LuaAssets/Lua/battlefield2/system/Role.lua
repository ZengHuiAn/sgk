local Property  = require "battlefield2.component.Property"
local Health    = require "battlefield2.component.Health"
local EntityBag = require "battlefield2.component.EntityBag"
local Skill     = require "battlefield2.component.Skill"
local Input     = require "battlefield2.component.Input"
local Force     = require "battlefield2.component.Force"
local Round     = require "battlefield2.component.Round"
local Config    = require "battlefield2.component.Config"
local Position  = require "battlefield2.component.Position"
local Timeout   = require "battlefield2.component.Timeout"

local Entity    = require "battlefield2.Entity"

local M = {API = {}}

function M.Start(game)
end

function M.Tick(game)
    local list = game:FindAllEntityWithComponent("BuffInventory", "PetInventory", "Health")
    for _, v in ipairs(list) do
        local Health = v:GetComponent("Health")
        if not v:Alive() and not Health.dead then
            v.BuffInventory:Clean();
            v.PetInventory:Clean();
            Health.dead = true
            game:DispatchEvent('UNIT_DEAD', v.uuid)
        elseif v:Alive() then
            if Health.dead then
                game:DispatchEvent('UNIT_RELIVE', v.uuid)
            end
            Health.dead = false
        end
    end
end

function M.Add(game, pid, side, wave, property, cfg)
    local entity = Entity();

    entity:AddComponent('Property',      Property(property));
    entity:AddComponent('Health',        Health());

    if not entity:Alive() then
        return
    end

    local Skill_Component = entity:AddComponent('Skill',         Skill(cfg.skills));
    entity:AddComponent('Input',         Input());
    entity:AddComponent('Force',         Force(pid or 0, side or 2));
    entity:AddComponent('Round',         Round(1, Skill_Component.ids[5] and 1 or 0));
    -- entity:AddComponent('Timeout',       Timeout(6));


    entity:AddComponent("Config",        Config("ROLE", cfg.id, {
        refid      = cfg.refid,
        level      = cfg.level,
        mode       = cfg.mode,
        grow_star  = cfg.grow_star,
        grow_stage = cfg.grow_stage,
    }));

    entity:AddComponent("Position",      Position(cfg.pos,cfg.x,cfg.y,cfg.z));

    entity:AddComponent('BuffInventory', EntityBag());
    entity:AddComponent('PetInventory',  EntityBag());

    -- entity:AddComponent('PetInventory',  EntityBag());
    -- entity:AddComponent('Input',         Component.Input());

    game:AddEntity(entity);

    game:LOG('CreateRole', entity.uuid, entity.Config.refid, entity.Config.name, entity.Force.pid);

    return entity;
end

function M.API.UnitChangeMP(skill, role, n, typa)

    typa = typa or 'mp';
    local pp = typa .. "p"

    local v, max = role.Property:Get(typa), role.Property:Get(pp)
    v = v + n

    if v < 0 then
        v = 0
    elseif v > max then
        v = max
    end

    -- print('<color=red>', 'UnitChangeMP',  '</color>', role.name, n, typa, v, max);

    role.Property:Set(typa, v)
end

function M.API.UnitPlay(skill, entity, action, ...)
    skill.game:DispatchEvent('UNIT_PLAY_ACTION', entity.uuid, action);
end

function M.SetFocusTag(game, uuid, type)
    local entity = game:GetEntity(uuid)
    if entity and entity:Alive() then
        entity.Property:Set(8005, type)
    end
end

return M;
