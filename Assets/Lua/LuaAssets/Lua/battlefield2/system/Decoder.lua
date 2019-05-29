local RoleSystem    = require "battlefield2.system.Role"
local SkillSystem   = require "battlefield2.system.Skill"
local RoundSystem   = require "battlefield2.system.Round"
local Statistics    = require 'battlefield2.system.Statistics'
local Entity        = require "battlefield2.Entity"
local Player        = require "battlefield2.component.Player"
local Timeout       = require "battlefield2.component.Timeout"
local FightListener = require "battlefield2.system.FightListener"

local battle_config = require "config.battle";

local M = {API={}, EVENT = {}}

local function addRole(game, pid, side, data, wave)
    wave = wave or 0;
    local property = {};
    for _, vv in ipairs(data.propertys) do
        if vv.type == 7094 and game.attacker_player_count < vv.value then
            return
        end

        property[vv.type] = (property[vv.type] or 0) + vv.value;
    end

    local npc = battle_config.LoadNPC(data.id)
    assert(npc, 'config_npc id = ' .. data.id .. " not exists");

    local entity = RoleSystem.Add(game, pid, side, wave, property, {
        refid = data.refid,
        id    = data.id,
        pos   = data.pos,
        level = data.level,
        mode  = data.mode,

        name  = npc.name,

        x     = data.x or 0,
        y     = data.y or 0,
        z     = data.z or 0,

        grow_star  = data.grow_star,
        grow_stage = data.grow_stage,

        skills     = data.skills,
    });

    return true;
end

local WAVE_ENTER_STATUS = {
    DEFAULT      = 1,
    CHECK_ENTER  = 2,
    ENTERING     = 3,
}

function M.Init(game)
    local round_info = game:GetSingleton('GlobalData');
    round_info.partner_enter_queue = {}
    round_info.enemy_enter_queue = {}
    round_info.wave_enter_status = WAVE_ENTER_STATUS.DEFAULT
end

function M.Tick(game)
    local round_info = game:GetSingleton('GlobalData');

    if round_info.wave_enter_status == WAVE_ENTER_STATUS.ENTERING then
        if next(round_info.partner_enter_queue) then
            for pid, roles in pairs(round_info.partner_enter_queue) do
                if roles[1] then
                    addRole(unpack(roles[1]))
                    table.remove(roles, 1)
                else
                    round_info.partner_enter_queue[pid] = nil
                end
            end
        elseif round_info.enemy_enter_queue[1] then
            addRole(unpack(round_info.enemy_enter_queue[1]))
            table.remove(round_info.enemy_enter_queue, 1)
        else
            round_info.wave_enter_status = WAVE_ENTER_STATUS.DEFAULT
        end
    end
end

function M.SetFightData(game, data)
    -- fight_data = ProtobufDecode(root.args.fight_data, "com.agame.protocol.FightData")
    local sync_data = game:GetSingleton('GlobalData');

    sync_data.win_type    = data.win_type
    sync_data.fight_type  = data.fight_type
    sync_data.scene       = data.scene
    sync_data.fight_id    = data.defender.pid
    sync_data.star        = data.star
    sync_data.seed        = data.seed;

    local round_limit = 20;

    if data.duration and data.duration > 0 then
        round_limit = data.duration;
    end
    sync_data.failed_round_limit = round_limit;

    if sync_data.win_type == 1 and data.win_para > 0 then
        sync_data.win_round_limit = data.win_para + 1;
    end

    local max_wave = {};
    for k, v in pairs(data.defender.roles) do
        max_wave[v.wave] = true;
    end
    sync_data.max_wave = #max_wave;

    sync_data.battle_data = data;

    local pos_cfg = {
        {3},
        {2,4},
        {1,3,5},
        {1,2,3,4},
    }

    local function adjustAttackPosition(attacker)
        local n = #(attacker.roles)
        local cfg = pos_cfg[n];
        if cfg then
            for k, v in ipairs(attacker.roles) do
                local pos = v.pos;
                v.pos = cfg[k] or pos;
            end
        end

        local entity = Entity();   
        entity:AddComponent('Player', Player(attacker.pid, attacker.level, attacker.name));
        entity:AddComponent("Timeout", Timeout(0));
        game:AddEntity(entity);

        if attacker.auto_input then
            game:SetAutoInput(true, attacker.pid);
        end
    end

    adjustAttackPosition(data.attacker);
    Statistics.AddPlayerStatistics(game, data.attacker.pid, data.attacker.level)

    game.attacker_player_count = 1
    for _, attacker in ipairs(data.additional_attackers or {}) do
        game.attacker_player_count = game.attacker_player_count + 1
        adjustAttackPosition(attacker);
    end

    FightListener.AddFightListener(game, sync_data.fight_id, sync_data.fight_type, "events")
end

function M.GetCharacterModes(game)
    local sync_data = game:GetSingleton('GlobalData');
    local data = sync_data.battle_data

    local list = {}
    local function addMode(player)
        for _, v in ipairs(player.roles) do
            list[v.mode] = true;
        end    
    end

    addMode(data.attacker);

    for _, attacker in ipairs(data.additional_attackers or {}) do
        addMode(attacker);
    end

    addMode(data.defender);

    return list;
end

function M.EVENT.ROUND_START(game, event, ...)
    local round_info = game:GetGlobalData();

	if round_info.failed_round_limit and round_info.failed_round_limit > 0 and round_info.round > round_info.failed_round_limit then
        game.round_info.final_winner = 2
        game:LOG('-- FIGHT_FINISHED --', game.round_info.final_winner);
        game:DispatchEvent('FIGHT_FINISHED', game.round_info.final_winner);    
        return
    end

	if round_info.win_round_limit and round_info.win_round_limit > 0 and round_info.round >= round_info.win_round_limit then
        game.round_info.final_winner = 1
        game:LOG('-- FIGHT_FINISHED --', game.round_info.final_winner);
        game:DispatchEvent('FIGHT_FINISHED', game.round_info.final_winner);    
        return
	end
end

function M.EVENT.WAVE_FINISHED(game, event, ...)
    if game.round_info.final_winner then
        return
    end

    -- TODO: wait for 3 sec
    -- game:DispatchEvent("WAVE_FINISHED");
    print('decoder', 'WAVE_FINISHED');

    local have_new_entity = false;

    local round_info = game:GetGlobalData();
    local data = round_info.battle_data;

    local next_wave = game.round_info.wave + 1;

    local function haveMoveEntity(player, next_wave)
        print('WAVE_FINISHED CHECK', player.pid)
        for _, v in ipairs(player.roles) do
            if v.wave == next_wave then
                return true;
            end
        end
    end

    if game.round_info.winner ~= 1 then
        have_new_entity = have_new_entity or haveMoveEntity(data.attacker, next_wave);

        for _, attacker in ipairs(data.additional_attackers or {}) do
            have_new_entity = have_new_entity or haveMoveEntity(attacker, next_wave);
        end
    end

    if game.round_info.winner ~= 2 then
        have_new_entity = have_new_entity or haveMoveEntity(data.defender, next_wave);
    end

    if have_new_entity then
        round_info.wave_enter_status = WAVE_ENTER_STATUS.CHECK_ENTER
        RoundSystem.StartNextWave(game, (round_info.wave == 0) and 0 or 1);
        return;
    end

    game.round_info.final_winner = game.round_info.winner;

    game:LOG('-- FIGHT_FINISHED --', game.round_info.winner);
    game:DispatchEvent('FIGHT_FINISHED', game.round_info.winner);
end

function M.EVENT.WAVE_START(game, event, ...)
    local round_info = game:GetGlobalData();
    local data = round_info.battle_data;
    round_info.wave_enter_status = WAVE_ENTER_STATUS.ENTERING

    local function addCurrentWaveRole(player, wave, side)
        round_info.partner_enter_queue[player.pid] = round_info.partner_enter_queue[player.pid] or {}
        for _, v in ipairs(player.roles) do
            if v.wave == wave then
                if wave == 1 then
                    if side == 1 then
                        table.insert(round_info.partner_enter_queue[player.pid], {game, player.pid, side, v, wave})
                    else
                        table.insert(round_info.enemy_enter_queue, {game, player.pid, side, v, wave})
                    end
                else
                    addRole(game, player.pid, side, v, wave)
                end
            end
        end    
    end

    addCurrentWaveRole(data.attacker, round_info.wave, 1);

    for _, attacker in ipairs(data.additional_attackers or {}) do
        addCurrentWaveRole(attacker, round_info.wave, 1);
    end

    addCurrentWaveRole(data.defender, round_info.wave, 2);
end

function M.API.AddEnemyInWave(skill, id, pos)
    local game = skill.game
    local list = game:FindAllEntityWithComponent('Position', 'Property', 'Round', 'Health');
    for k, v in ipairs(list) do
        if v.Position and v.Position.pos == pos then
            if v:Alive() then
                ERROR_LOG("______________________________ this pos has a role already")
                return
            else
                game:RemoveEntity(v.uuid)
                break
            end
        end
    end

    local data = game.round_info.battle_data;
    local fight_id = game.round_info.fight_id
    for _, v in ipairs(data.defender.roles) do
        if v.id == id then
            v.pos = pos
            addRole(game, fight_id, 2, v, game.round_info.wave)
            break
        end
    end    
end

return M;
