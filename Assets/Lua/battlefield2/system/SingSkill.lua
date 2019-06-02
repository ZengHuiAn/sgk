local Entity       = require "battlefield2.Entity"
local SingSkill    = require "battlefield2.component.SingSkill"
local Skill        = require "battlefield2.component.Skill"
local SkillSystem  = require "battlefield2.system.Skill"
local RngSystem    = require "battlefield2.system.RNG"

local M = {EVENT={}, API = {}, NOTIFY = {}}

function M.Start(game)
end

function M.Tick(game)
end

function M.Stop(game)
end

function M.GetRoleSingSkill(game, target_uuid)
    local list = game:FindAllEntityWithComponent("SingSkill")
    for _, v in ipairs(list) do
        if v.SingSkill.creator == target_uuid then
            return v;
        end
    end
end

function M.Add(skill, id, creator, type, total, current, beat_back, certainly_increase)
    if M.GetRoleSingSkill(skill.game, creator) then
        ERROR_LOG("_____this role already has a SingSKill")
        return
    end

    local entity = Entity();
    entity:AddComponent("SingSkill", SingSkill(creator, type, total, current, beat_back, certainly_increase));
    skill.game:AddEntity(entity);
end

function M.API.CreateSingSkill(skill, id, creator, type, total, current, beat_back, certainly_increase)
    M.Add(skill, id, creator.uuid, type, total, current, beat_back, certainly_increase)
end

function M.API.RemoveCurrentSingSkill(skill, target)
    local entity = M.GetRoleSingSkill(skill.game, target.uuid)
    if entity then
        skill.game:RemoveEntity(entity.uuid)
    end
end

function M.API.GetCurrentSingSkill(skill, target)
    return M.GetRoleSingSkill(skill.game, target.uuid)
end

function M.API.SetCurrentSingSkill(skill, target, current, beat_back, certainly_increase)
    local entity = M.GetRoleSingSkill(skill.game, target.uuid)
    if not entity then
        ERROR_LOG("_____this role do not has a SingSKill")
        return
    end

    entity.SingSkill.current            = current
    entity.SingSkill.beat_back          = beat_back
    entity.SingSkill.certainly_increase = certainly_increase
end

function M.API.CurrentSingSkillCast(skill, target, index)
    M.Cast(skill.game, target, {skill=index, target=0})
end

function M.Cast(game, entity, data)
    local skill = entity.Skill;
    if not skill then return; end

    local skill_pos, target_id = data.skill, data.target;

    local skillName = skill.entity.Config and skill.entity.Config.name or '-';

    repeat
        local script = skill.script[skill_pos]
        if not script then
            game:LOG('script not exist', skill_pos)
            break
        end

        local target_info;
        if script.check then
            local target_list = script.check:Call("SingSkill");
            if not target_list then
                game:LOG('script is disabled', skill)
                break
            end

            if target_id == 0 then
                target_info = target_list[RngSystem.RAND(game, 1, #target_list)]
            end

            if target_id and target_id ~= 0 then
                local m = {}
                for _, v in ipairs(target_list) do
                    if type(v.target) == "table" then
                        m[v.target.uuid] = v;
                    else
                        m[v.target] = v;
                    end
                end
    
                target_info = m[target_id];
                if not target_info then
                    game:LOG('target not exists', skill_pos, target_id, entity.uuid, skillName, script.script.__file, script.check.__file);
                    return
                end
            end
        end

        game:LOG('SkillSystem.Cast', skillName, script.script.__file, target_id);

        game:DispatchEvent('UNIT_CAST_SKILL', {
                     uuid = skill.entity.uuid, 
                     skill = skill_pos,
                     target = target_id,
                     skill_type = script.skill_type,
                });

        -- TODO: add skill property to entity
        if script.property and entity.Property then
            entity.Property:Add('SKILL', script.property);
        end

        target_info = target_info or {}
        target_info.SingSkill = true
        script.script:Call(target_info);

        if script.property and entity.Property then
            entity.Property:Remove('SKILL');
        end
        
        game:DispatchEvent('UNIT_SKILL_FINISHED', {uuid = skill.entity.uuid})

        game:LOG('SkillSystem.Finished', skill.entity.uuid);
    until true;
end

return M;
