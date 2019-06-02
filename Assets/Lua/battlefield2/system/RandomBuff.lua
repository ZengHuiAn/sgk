local RandomBuff   = require "battlefield2.component.RandomBuff"
local SandBox      = require "utils.SandBox2"
local Skill        = require "battlefield2.component.Skill"
local SkillSystem  = require "battlefield2.system.Skill"
local AutoKill     = require "battlefield2.component.AutoKill"

local Entity       = require "battlefield2.Entity"
local battle_config = require "config.battle";

local M = {EVENT={}, API = {}, NOTIFY = {}}

function M.Start(game)
end

function M.Tick(game)
end

function M.Stop(game)
end

function M.Init(game)
    M.RdBuffWithListener = {}
    M.Have_Ai = false
end

function M.EVENT.ENTITY_ADD(game, uuid, entity)
    if entity.Player and entity.Player.pid <= 150000 then 
        M.Have_Ai = true
    end
end

function M.API.AddRandomBuff(skill, creater, id)
    return M.Add(skill.game, creater.uuid, id)
end

function M.API.RemoveRandomBuff(skill, uuid)
    local entity = uuid and skill.game:GetEntity(uuid) or skill.entity;
    if entity and entity.RandomBuff then
        skill.game:RemoveEntity(entity.uuid);
    end
end

function M.EVENT.ENTITY_WILL_REMOVE(game, uuid, entity, opt)
    if entity.RandomBuff and opt.auto_remove and not game.client then
        M.Cast(game, uuid, nil, {auto_remove = true})
    end

    if M.RdBuffWithListener[uuid] then
        M.RdBuffWithListener[uuid] = nil
    end
end

function M.API.GetRandomBuffList(skill)
    local list = skill.game:FindAllEntityWithComponent("RandomBuff")

    local ret = {}
    for _, v in ipairs(list) do
        table.insert(ret, v:Export())
    end
    return ret;
end

function M.Hold(game, uuid, pid)
    local entity = game:GetEntity(uuid);
    if not entity or not entity.RandomBuff then
        return
    end
    
    if entity.RandomBuff.holder ~= 0 then
        return
    end
    
    entity.RandomBuff.holder = pid
end

function M.Add(game, creater, id, extra)
    local entity = Entity();

    entity:AddComponent("RandomBuff", RandomBuff(creater));
    entity:AddComponent("Skill", Skill({id}));

    local cfg = battle_config.LoadInteractBuff(id)
    if not cfg then
        ERROR_LOG("________ random buff config not found")
        return
    end

    local round = game:GetGlobalData().round;

    if cfg.lastingtype == 1 then
        entity:AddComponent("AutoKill", AutoKill(nil, round + cfg.value));
    elseif cfg.lastingtype == 2 then
        entity:AddComponent("AutoKill", AutoKill(game:GetTick(cfg.value)));
    end

    entity.RandomBuff.remove_type = cfg.remove_type

    game:AddEntity(entity);

    if M.Have_Ai and cfg.auto_cast_script and cfg.auto_cast_script ~= "" then
        M.AddListener(game, entity, cfg.auto_cast_script)
    end

    return entity;
end

function M.API.RandomBuffCast(skill, entity, pid)
    M.Cast(skill.game, entity.uuid, nil, {pid = pid})
end

function M.Cast(game, uuid, target, info)
    local entity = game:GetEntity(uuid);
    if not entity or not entity.RandomBuff then return end;

    M.RandomBuffSkillCast(game, entity, {skill=1, target=target, auto_remove = info.auto_remove, pid = info.pid})
end

function M.RandomBuffSkillCast(game, entity, data)
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

        local target_info = {};
        --[[
        if script.check then
            local target_list = script.check:Call();
            if not target_list then
                game:LOG('script is disabled', skill)
                break
            end

            local m = {}
            for _, v in ipairs(target_list) do
                if type(v.target) == "table" then
                    m[v.target.uuid] = v;
                else
                    m[v.target] = v;
                end
            end

            if target_id then
                target_info = m[target_id];
                target_info.choose = true
                if not target_info then
                    game:LOG('target not exists', skill_pos, target_id, entity.uuid, skillName, script.script.__file, script.check.__file);
                    return
                end
            end
        end
        --]]
        target_info.user_pid = data.pid

        -- TODO: add skill property to entity
        if script.property and entity.Property then
            entity.Property:Add('SKILL', script.property);
        end
        
        if data.auto_remove then
            script.script:Call({auto_remove = data.auto_remove});
        else
            script.script:Call(target_info);
        end

        if script.property and entity.Property then
            entity.Property:Remove('SKILL');
        end
        
        -- game:DispatchEvent('UNIT_SKILL_FINISHED', {uuid = skill.entity.uuid})

        game:LOG('SkillSystem.Finished', skill.entity.uuid);
    until true;
end

function M.EVENT.UNIT_DEAD(game, uuid)
    local list = game:FindAllEntityWithComponent("RandomBuff")
    for _, v in ipairs(list) do
        if v.RandomBuff.creater == uuid and v.RandomBuff.remove_type == 1 then
            game:RemoveEntity(v.uuid);
        end
    end
end

function M.EVENT.WAVE_START(game)
    local list = game:FindAllEntityWithComponent("RandomBuff")
    for _, v in ipairs(list) do
        if v.RandomBuff.remove_type == 2 then
            game:RemoveEntity(v.uuid);
        end
    end
end

function M.AddListener(game, entity, script_id)
    if not script_id then
        return
    end

    local script;
    script = SandBox.New(string.format('script/fight/%s.lua', script_id), setmetatable({
        game = game,
        RdBuff = entity,
    }, {__index=function(t, k)
        local func = t.game.API[k]
        if func then
            return function(...)
                return func(script, ...)
            end
        elseif UnityEngine then
            return function(...)
                game:LOG('<color=red>', 'UNKNOWN API', k, '</color>\n', debug.traceback());
            end
        else
            return function() end
        end
    end}))
    script:Call();

    local function addFilter(name)
        if rawget(script, name) then
            return entity:AddComponent("Fight_" .. name, BuffAction(script[name]))
        end
    end

    addFilter('onRoundStart');
    addFilter('afterAllEnter');

    M.RdBuffWithListener[entity.uuid] = entity
end

function M.EVENT.ROUND_START(game)
    for _, v in pairs(M.RdBuffWithListener) do
        local onRoundStart = fight_listner:GetComponent("Fight_onRoundStart")
        if onRoundStart then
            onRoundStart:Do(game.round_info.round, game.round_info.wave);
        end
    end
end

return M;