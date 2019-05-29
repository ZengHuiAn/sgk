local InputSystem = require "battlefield2.system.Input"
local SkillSystem = require "battlefield2.system.Skill"
local BuffSystem  = require "battlefield2.system.Buff"
local RngSystem   = require "battlefield2.system.RNG"

local SandBox = require "utils.SandBox2"

local M = {EVENT={}, API = {}}

local function more_speed(a, b)
    if a.Round.round ~= b.Round.round then
        return a.Round.round < b.Round.round;
    end 

    if a.Property:Get('speed') ~= b.Property:Get('speed') then
        return a.Property:Get('speed') > b.Property:Get('speed');
    end

    return a.uuid < b.uuid;
end

local function add_entity_to_round_info(round_info, entity)
    if entity.Force.side == 2 then
        round_info.enemy.entities[entity.uuid] = entity
    else
        local pid = entity.Force.pid;
        round_info.partner[pid] = round_info.partner[pid] or { entities = {}, }
        round_info.partner[pid].entities[entity.uuid] = entity
    end
end

local function array_remove(info, entity)
    if not info or not info.entities then
        return;
    end

    info.entities[entity.uuid] = nil;
end

local function remove_entity_from_round_info(round_info, entity)
    if entity.Force.side == 2 then
        array_remove(round_info.enemy, entity);
    else
        array_remove(round_info.partner[entity.Force.pid], entity);
    end
end

function M.Init(game)
    local round_info = game:GetSingleton('GlobalData');
    round_info.wave = 0
    round_info.winner   = false
    round_info.partner  = {}
    round_info.enemy    = { entities = {} }
    round_info.enter_script_count = 0
end

function M.Start(game)
end

local function entityThread(game, info, entity)
    info.co = coroutine.running();
    info.entity = entity;
    entity.Round.action = true

    local round_info = game:GetGlobalData();
    round_info.current_co = true;

    -- round_info.thread_count = round_info.thread_count + 1;

    game:DispatchEvent('UNIT_BEFORE_ACTION', entity.uuid);

    BuffSystem.DoAction(game, entity, "BulletFilter_onTick");

--[[
    if entity.BuffInventory then
        local list = entity.BuffInventory:FindAllEntityWithComponent();
        for _, e in ipairs(list) do
            if e.Buff.round < round_info.round then
                game:RemoveEntity(e.uuid);
            end
        end
    end
--]]


    local need_after_action = false;
    while true do
        if round_info.winner then -- game finished, maybe no enemy exists
            game:LOG('entityThread', entity.uuid, 'game finished');
            break;
        end

        if not entity:Alive() then
            game:LOG('entityThread', entity.uuid, 'entity not alive');
            break;
        end

        if entity.Round.act_point <= 0 then -- action done
            entity.Round.round = round_info.round + 1;
            game:LOG(entity.uuid, 'next round', entity.Round.round);
            entity.Round.act_point = 1;
            need_after_action = true;
            break; 
        end

        game:DispatchEvent('UNIT_PREPARE_ACTION', entity.uuid);

        local timeout = game:GetAutoInput(entity.Force.pid);

        if timeout == true or entity.Property.outcontrol > 0 then
            local data = SkillSystem.GetAutoInput(entity);
            game:Sleep(RngSystem.RAND(game, 1, 30)/100);
            SkillSystem.Cast(game, entity, data);
        else
            InputSystem.SetToken(entity.Input, true);
            local data = InputSystem.Read(entity.Input, 'SKILL', timeout)
            InputSystem.SetToken(entity.Input, nil);

            if not data then -- maybe input is reset
                break;
            end

            if data == "STOP" then
                break;
            elseif data == "DEF" then
                SkillSystem.Cast(game, entity, {skill = 11});
            elseif data == "AUTO" or data == "TIMEOUT" then
                game:Sleep(RngSystem.RAND(game, 1, 30)/100);
                data = SkillSystem.GetAutoInput(entity);
                SkillSystem.Cast(game, entity, data);
            else
                SkillSystem.Cast(game, entity, data);
            end
        end
        game:Sleep(0);
    end

    game:LOG('entity after action', entity.uuid, entity.Config.name);

    if need_after_action then
        BuffSystem.DoAction(game, entity, "BulletFilter_beforePostTick");
        BuffSystem.DoAction(game, entity, "BulletFilter_onPostTick");
        game:DispatchEvent('UNIT_AFTER_ACTION', entity.uuid);

        if entity.PetInventory then
            local pet_list = entity.PetInventory:FindAllEntityWithComponent("Skill");
            for _, v in ipairs(pet_list) do
                game:LOG('pet action', v.Config.name);
                SkillSystem.Cast(game, v, {skill=1});
                if v.Pet:FirstCD() == round_info.round then
                    v.Pet:RemoveFrist()
                end
            end
        end
    end

    -- round_info.thread_count = round_info.thread_count - 1;

    info.co = nil;
    round_info.current_co = nil;
    entity.Round.action = false
end

local function startWorkThread(game, info, entity)
    assert(coroutine.resume(coroutine.create(entityThread), game, info, entity))
end

local function find_fast_entity(game, list)
    local target = nil
    local total  = 0;

    local round_info = game:GetGlobalData();

    for k, v in pairs(list) do
        if not v:Alive() then
            -- entity will removed after wave
            -- list[k] = nil;
            -- game:RemoveEntity(k);
        else
            if v.Round.round <= round_info.round then
                if target == nil or more_speed(v, target) then
                    target = v;
                end
            end
            total = total + 1;
        end
    end

    return target, total;
end


local function cleanDeadEntity(game)
    local list = game:FindAllEntityWithComponent("Health")
    for _, v in ipairs(list) do
        if not v:Alive() and v.Force.side ~= 1 then
            game:RemoveEntity(v.uuid);
        end
    end
end

local function upDateEntityRound(game)
    local list = game:FindAllEntityWithComponent("Health", "Round")
    local round_info = game:GetGlobalData()
    for _, v in ipairs(list) do
        v.Round.round = round_info.round
    end
end

local function finisheWave(game)
    cleanDeadEntity(game);

    game:LOG('wave finished');

    game:DispatchEvent("ROUND_FINISHED");
    game:DispatchEvent("WAVE_FINISHED");
end

local function startWave(game)
    local round_info = game:GetGlobalData();
    round_info:ChangeRound(round_info.round + 1, round_info.wave + 1);
    
    game:LOG('wave start',  round_info.wave);
    game:LOG('round start', round_info.round);

    round_info.wave_start_round = round_info.round;

    if round_info.wave_enter_status ~= 1 then
        round_info.events_after_allenter = function()
            game:DispatchEvent("ROUND_START");
        end
    else
        game:DispatchEvent("ROUND_START");
    end
    game:DispatchEvent("WAVE_START");

    upDateEntityRound(game)
    return;
end

function M.Tick(game)
    local round_info = game:GetGlobalData();

    if round_info.events_after_allenter and round_info.wave_enter_status == 1 and round_info.enter_script_count == 0 then
        round_info.events_after_allenter()
        round_info.events_after_allenter = nil
    end

    if round_info.next_tick_action then
        if round_info.next_tick_action_delay and round_info.next_tick_action_delay > 0 then
            round_info.next_tick_action_delay = round_info.next_tick_action_delay - 1;
        else
            local func = round_info.next_tick_action;
            round_info.next_tick_action = nil;
            func(game)
        end
        return;
    end

    if round_info.winner or round_info.final_winner  then
        return
    end

    if round_info.enter_script_count > 0 then
        game:LOG("running enter_script", round_info.enter_script_count);
        return;
    end

    --[[
    if round_info.SkillCutIn_Running then
        return
    end

    if round_info.SkillCutIn_list and not round_info.current_co and next(round_info.SkillCutIn_list) then
        round_info.SkillCutIn_list[1]()
        table.remove(round_info.SkillCutIn_list, 1)
        return
    end
    ]]
    local enemy = round_info.enemy;

    local first_enemy, enemy_count = find_fast_entity(game, enemy.entities);

    local enemy_exists = (enemy_count > 0)

    local partner_thread_count = 0;
    local partner_left = 0;

    for pid, info in pairs(round_info.partner) do
        local first_entity, partner_count = find_fast_entity(game, info.entities);
        partner_left = partner_left + partner_count;

        if info.co then
            partner_thread_count = partner_thread_count + 1;
            if not enemy_exists then -- close input
                InputSystem.SetToken(info.entity.Input, nil);
            end
        else
            if first_entity 
                and enemy_exists 
                and ( (not first_enemy) or more_speed(first_entity, first_enemy) ) then
                game:LOG(pid, 'start work', first_entity.uuid);
                startWorkThread(game, info, first_entity);
                partner_thread_count = partner_thread_count + 1;
            end
        end
    end

    -- partner is running
    if partner_thread_count > 0 then
        return
    end

    -- enemy action
    if first_enemy and partner_left > 0 then
        if enemy.co == nil then
            game:LOG('enemy', first_enemy.uuid, 'start work');
            startWorkThread(game, enemy, first_enemy);
        elseif partner_left == 0 then
            InputSystem.SetToken(enemy.entity.Input, nil);
        end
        return;
    elseif enemy.co then
        InputSystem.SetToken(enemy.entity.Input, nil);
        return;
    end

    -- check winner
    if partner_left == 0 or enemy_count == 0 then
        if enemy_count == 0 and partner_left == 0 then
            round_info.winner = 0;
        elseif partner_left == 0 then
            round_info.winner = 2;
        else
            round_info.winner = 1;
        end

        -- call finishWave
        print('call finishWave next tick');
        round_info.next_tick_action = finisheWave;
        return;
    end

    -- next round
    round_info:ChangeRound(round_info.round + 1);
    game:LOG('next round', round_info.round);
    game:DispatchEvent("ROUND_START");
    upDateEntityRound(game)
end

function M.StartNextWave(game, delay)
    local round_info = game:GetGlobalData();

    if round_info.winner then
        round_info.next_tick_action_delay = math.floor(delay * 10);
        round_info.next_tick_action = startWave
    end
end

function M.Stop(game)
end

local function runEnterScript(round_info, entity)
    local game = entity.game;

    if not entity.Skill then return end;
    if not entity.Skill.script[5] then return end;
    
    local enter_script = entity.Skill.script[5] 
    game:LOG('enter_script', entity.Config.name, enter_script.name);
    -- TODO:

    round_info.enter_script_count = round_info.enter_script_count + 1
    local success, err = coroutine.resume(coroutine.create(function()
        enter_script.script:Call();
        entity.Round.invisible = 0
        round_info.enter_script_count = round_info.enter_script_count - 1
        if round_info.enter_script_count == 0 then
            game:DispatchEvent("WAVE_ALL_ENTER");
        end
    end))
    
    if not success then
        game:LOG('enter_script error', err);
    end
end

function M.EVENT.UNIT_RELIVE(game, uuid)
    local round_info = game:GetGlobalData();

    local entity = game:GetEntity(uuid)
    if entity.Round and entity.Force and entity.Input and entity.Property then
        add_entity_to_round_info(round_info, entity);
        round_info.winner = false;
    end

    runEnterScript(round_info, entity);
end

function M.EVENT.ENTITY_ADD(game, uuid)
    local round_info = game:GetGlobalData();

    local entity = game:GetEntity(uuid)
    if entity.Round and entity.Force and entity.Input and entity.Property then
        add_entity_to_round_info(round_info, entity);
        round_info.winner = false;
    end

    runEnterScript(round_info, entity);
end

function M.EVENT.ENTITY_REMOVED(game, uuid, entity)
    local round_info = game:GetGlobalData();

    if entity.Round and entity.Force and entity.Input and entity.Property then
        remove_entity_from_round_info(round_info, entity);
        InputSystem.Reset(entity.Input);
    end
end

function M.API.UnitConsumeActPoint(skill, n)
    if skill.entity.Round then
        skill.entity.Round.act_point = math.min(1, skill.entity.Round.act_point - n);
    end
end

function M.API.SkillCutInRound(skill, role, index, target)
    local round_info = skill.game:GetGlobalData();
    local entity = skill.game:GetEntity(role.uuid)
    round_info.SkillCutIn_list = round_info.SkillCutIn_list or {}

    local fun = function ()
        local success, err = coroutine.resume(coroutine.create(function()
            round_info.SkillCutIn_Running = true
            SkillSystem.Cast(skill.game, entity, {skill=index,target=target.uuid});
            round_info.SkillCutIn_Running = nil
        end))
    end

    table.insert(round_info.SkillCutIn_list, fun)
end

--[[
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
        then
            table.insert(result, v:Export());
        end
    end

    return result;
end
--]]

return M;
