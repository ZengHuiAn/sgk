
local battle_config = require "config.battle";

local M = { API={} }

function M.API.FindAllEnemy(skill)
    local entity,game = skill.entity, skill.game

    if entity.Force == nil then
        return {}
    end

    local list = game:FindAllEntityWithComponent('Force', 'Input', 'Property', 'Round', 'Health');
    local result = {}
    for _, v in ipairs(list) do
        if v.Force.side ~= entity.Force.side 
            and v:Alive()
        then
            table.insert(result, v:Export());
        end
    end
    return result;
end

function M.API.FindAllPartner(skill)
    local entity,game = skill.entity, skill.game

    if entity.Force == nil then
        return {}
    end

    local list = game:FindAllEntityWithComponent('Force', 'Input', 'Property', 'Round', 'Health');
    
    local result = {}

    for _, v in ipairs(list) do
        if v.Force.side == entity.Force.side
            and v:Alive()
            and v.Force.pid == entity.Force.pid
        then
            table.insert(result, v:Export());
        end
    end

    return result;
end

function M.API.FindAllRoles(skill)
    local entity,game = skill.entity, skill.game

    local list = game:FindAllEntityWithComponent('Force', 'Input', 'Property', 'Round', 'Health');
    
    local side_1 = {}
    local side_2 = {}
    local all = {}

    for _, v in ipairs(list) do
        if v.Force.side == 1 and v:Alive() then
            table.insert(side_1, v:Export());
            table.insert(all, v:Export());
        elseif v.Force.side == 2 and v:Alive() then
            table.insert(side_2, v:Export());
            table.insert(all, v:Export());
        end
    end

    return all, side_1, side_2;
end

function M.API.GetDeadList(skill)
    local entity,game = skill.entity, skill.game

    local list = game:FindAllEntityWithComponent('Force', 'Input', 'Property', 'Round', 'Health');

    local result = {}

    for _, v in ipairs(list) do
        if not v:Alive() then
            table.insert(result, v:Export());
        end
    end

    return result;
end

function M.API.GetBattleData(skill)
    return skill.game:GetGlobalData();
end

function M.API.GetFightData(skill)
    return skill.game:GetGlobalData();
end

function M.API.GetSkillEffectCfg(skill, id)
    return battle_config.LoadSkillEffectCfg(id)
end

function M.API.AddBattleDialog(skill, id)
    skill.game:DispatchEvent('ADD_BATTLE_DIALOG', {dialog_id = id});
end

function M.API.PlayBattleGuide(skill, id)
    skill.game:DispatchEvent('PALY_BATTLE_GUIDE', {id = id});
end

function M.API.ShowErrorInfo(skill, id)
    skill.game:DispatchEvent('SHOW_ERROR_INFO', {id = id});
end

function M.API.ShowBuffEffect(skill, target, icon, name, up)
    skill.game:DispatchEvent('SHOW_BUFF_EFFECT', target.uuid, icon, name, up);
end

return M;


