local InputSystem = require "battlefield2.system.Input"
local DelaySystem = require "battlefield2.system.Delay"
local SkillConfig = require "config.skill"
local Property    = require "battlefield2.component.Property" -- utils.Property2"

local SandBox = require "utils.SandBox2"

local M = {
    EVENT = {},
    API   = {},
}

function M.Start(game)
end

function M.Tick(game)
end

function M.Stop(game)
    game.sleeping_thread ={} -- release
end

function M.API.ChooseSkill(skill, ...)
    local skill = skill.entity:GetComponent("Skill")
    if not skill then return; end

    for i, key in ipairs(...) do
        skill.script[i] = skill.save[key]
    end
end

local function load_skill_script(skill, filename)
    skill.game.__shared_library = skill.game.__shared_library or {}
    local sandbox = SandBox.New(string.format("script/skill/%s.lua", filename), 
            setmetatable({
                attacker = skill.entity:Export(),
                _Skill = skill,
            }, {__index=function(t, k)
                local func = skill.game.API[k]
                if func then
                    return function(...)
                        return func(skill, ...)
                    end
                elseif UnityEngine then
                    return function(...)
                        -- skill.game:ERROR('<color=red>', 'UNKNOWN API', k, '</color>\n', debug.traceback());
                    end
                else
                    return function() end
                end
            end}), skill.game.__shared_library)


    sandbox:LoadLib("script/common.lua", skill.game.__shared_library);

    return sandbox;
end

local function init_skill(skill, game, entity, id, script_file_name)
    skill.id          = id
    skill.game        = game
    skill.entity      = entity
    skill._origin_id  = skill._origin_id or id;
    skill.owner       = entity:Export();
    skill.disabled    = false;
    skill.target_list = {}

    local round_info = game:GetGlobalData()

    skill.cfg = script_file_name and {} or SkillConfig.GetConfig(id);

    if not skill.cfg then
        if entity.Pet then
            skill.property = Property();
            skill.script = load_skill_script(skill, id);
            skill.check  = load_skill_script(skill, "find_empty");
            return skill
        else
            game:LOG("<color=red>skill config not found (" .. (id or script_file_name) .. ")</color>");
            skill.script = function()            end;
            skill.check  = function() return {} end;
            return;
        end
    end

    assert(skill.cfg, "skill config not found (" .. (id or script_file_name) .. ")");

    skill.property = Property(skill.cfg.property_list);

    -- skill.property[8003] = round_info.round + skill.property.skill_init_cd;

    local script_id = script_file_name or skill.cfg.script_id;
    if not script_file_name and script_id == 0 then
        script_id = id;
    end

    if skill.cfg.check_script_id and skill.cfg.check_script_id ~= '0' then
        skill.check = load_skill_script(skill, skill.cfg.check_script_id)
    elseif not script_file_name then
        skill.check = load_skill_script(skill, "find_one_enemy");
    else
        skill.check = false
    end

    assert(script_id and script_id ~= 0, 'script_id is nil');

    skill.script = load_skill_script(skill, script_id);
    skill.sort_index = 0;

    setmetatable(skill, {__index=function(t, k)
        if t.cfg[k] ~= nil then return t.cfg[k] end
        
        --[[
        if k == "current_cd" then
            if skill.property[8003] <= round_info.round then
                return 0;
            end
            return skill.property[8003] - round_info.round;
        end
        --]]

        return t.property[k];
    end, __newindex=function(t,k,v)
        assert(false, 'set ' .. k .. '\n' .. debug.traceback());
    end})

    return skill;
end


local function createSkillScript(game, entity, id, script_file_name)
    return init_skill({}, game, entity, id, script_file_name);
end

local function initSkill(game, entity, ids)
    if not entity.Skill then return end
    local skill = entity.Skill

    skill.script = {}
    skill.save   = {};

    for k, id in ipairs(ids or {}) do
        if id ~= 0 then
            skill.save[id] = createSkillScript(game, entity, id)
            if k >= 1 and k <= 5 and skill.save[id] then
                skill.script[k] = skill.save[id]
                skill.script[k].sort_index = k;
            end
        end
    end

    skill.script[11] = createSkillScript(game, entity, 0, "def");

--[[
    if entity.Config.id == 11000 then
        skill.script[13] = createSkillScript(game, entity, 0, "diamond");
    end
--]]
end

function M.EVENT.ENTITY_ADD(game, uuid, entity)
    if entity.Skill and not entity.Skill.script then
        initSkill(game, entity, entity.Skill.ids);
    end
end

function M.API.SkillChangeId(skill, target, index, id) 
    skill.game:DispatchEvent("SKILL_CHANGE_ID", target.uuid, index, id)
    --[[
    if script.property_add_to_owner then
        target_skill.entity.Property:Add('skill', target_skill.property);
    end
    --]]
end

function M.EVENT.SKILL_CHANGE_ID(game, uuid, index, id) 
    local target = game:GetEntity(uuid)
    if not target then return end

    if id == 0 then
        target.Skill.script[index] = nil
        target.Skill.save[index] = nil
        target.Skill.ids[index] = 0
    else
        local new_skill = init_skill({}, game, target, id);
        new_skill.sort_index = index
        target.Skill.script[index] = new_skill
        target.Skill.save[index] = new_skill
        new_skill.property[8006] = 1
        target.Skill.ids[index] = id
    end
end

function M.API.SkillChangCD(skill, target_skill, cd) 
    local round_info = skill.game:GetGlobalData();

    target_skill = target_skill or skill;
    skill.property[8003] = round_info.round + cd;
end

function M.API.SkillGetInfo(skill, target, index)
    local target = target or skill.entity
    if index then
        return target.Skill.script[index] or target.Skill.save[index]
    else
        return skill
    end
end

function M.Prepare(entity)
    local round_info = entity.game:GetGlobalData();

    for _, v in ipairs(entity.Skill.script) do
        v.disabled = false
        if v.property[8003] > round_info.round then
            v.disabled = true;
        elseif v.check then
            local target_list = v.check:Call();
            if not target_list or #target_list == 0 then
                v.disabled = true
                v.target_list = {}
            else
                v.target_list = target_list;
            end
        end
    end
end

local function getAutoScript(entity)
    entity.Input.auto_script = entity.Input.auto_script or 
        SandBox.New("script/autoAction.lua", setmetatable({
            attacker = entity:Export(),
        }, {__index=function(t, k)
            local func = entity.game.API[k]
            if func then
                return function(...)
                    return func({game = entity.game}, ...)
                end
            else
                entity.game:ERROR('UNKNOWN API', k, debug.traceback());
            end
        end}))

    return entity.Input.auto_script;
end

function M.GetAutoInput(entity)
    M.Prepare(entity);

    local auto_script = getAutoScript(entity);

    local skill_index, target_index = auto_script:Call();
    if skill_index == "def" then
        skill_index = 11
    end

    entity.game:Sleep(1);

    local skill = entity.Skill.script[skill_index]

    assert(skill, 'auto input get unknsown skill: ' .. tostring(skill_index));

    if skill.target_list[target_index] then
        target_index = skill.target_list[target_index].target;
        if type(target_index) == "table" then
            target_index = target_index.uuid;
        end
    end

    -- TODO: translate to data
    -- game:LOG('<color=red>', entity.Config.id, 'autoinput get', skill_index, target_index, '</color>');
    return {skill = skill_index, target = target_index}
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

        script.script:Call(target_info);

        if script.property and entity.Property then
            entity.Property:Remove('SKILL');
        end

        local round_info = game:GetGlobalData();
        script.property[8003] = round_info.round + script.property.skill_cast_cd;
        
        game:DispatchEvent('UNIT_SKILL_FINISHED', {uuid = skill.entity.uuid})

        game:LOG('SkillSystem.Finished', skill.entity.uuid);
    until true;
end

return M;
