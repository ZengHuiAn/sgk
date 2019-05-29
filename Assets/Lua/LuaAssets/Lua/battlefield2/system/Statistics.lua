local Bullet   = require "battlefield2.component.Bullet"
local Property = require "battlefield2.component.Property"

local BuffSystem = require "battlefield2.system.Buff"

local Entity    = require "battlefield2.Entity"

local M = {
    API = {},
    EVENT = {},
}

function M.Init(game)
    game.statistics = {
        partners = {},
        monsters = {},
        skills_used = {},
        max_damage = 0,
        total_round = 0,
        total_hurt = 0,
        event_records = {},
        input_records = {},
    }
    game.player_statistics = {}
    game.statistics.event_records = {}
end

function M.Tick(game)
    for uuid, v in pairs(game.statistics.monsters) do
        local e = game:GetEntity(uuid);
        if e and not e:Alive() and not v.leave_round then
            v.leave_round = game.round_info.round;
        elseif e and e:Alive() and v.leave_round then
            v.leave_round = nil;
        end
    end
end

function M.API.AddRecord(skill, pid, id, type, value)
    local game = skill.game;
    game.statistics.event_records[pid] = game.statistics.event_records[pid] or {}
    if type == "max" then
        if not game.statistics.event_records[pid][id] or value > game.statistics.event_records[pid][id] then
            game.statistics.event_records[pid][id] = value;
        end
    elseif type == "min" then
        if not game.statistics.event_records[pid][id] or value < game.statistics.event_records[pid][id] then
            game.statistics.event_records[pid][id] = value;
        end
    else
        game.statistics.event_records[pid][id] = (game.statistics.event_records[pid][id] or 0) + (value or 1);
    end
end

function M.EVENT.ENTITY_ADD(game, uuid, entity)
    if entity.Force and entity.Property and entity.Health and entity.Round then
        if entity.Force.side == 1 then
            game.statistics.partners[entity.uuid] = {hurt = 0, health = 0, damage = 0}
        else
            game.statistics.monsters[entity.uuid] = {enter_round = game.round_info and game.round_info.round or 1}
        end
    end
end

function M.EVENT.UNIT_CAST_SKILL(game, info)
    game.statistics.skills_used[info.skill_type or 0] = true;
end

function M.EVENT.UNIT_HURT(game, info) -- {uuid = data[1], value = data[2], flag = data[3], name_id = data[4], attacker = data[5]});
    local target = game:GetEntity(info.uuid)

    if target.Force and target.Force.side == 2 and info.value > game.statistics.max_damage then
        game.statistics.max_damage = info.value;
    elseif target.Force and target.Force.side == 1 then
        game.statistics.total_hurt = game.statistics.total_hurt + info.value;
    end

    local statistics = game.statistics.partners[info.attacker]
    if statistics then
        statistics.damage = statistics.damage + info.value;
        -- statistics.health = statistics.health + info.value
    end

    local statistics = game.statistics.partners[info.uuid]
    if statistics then
        statistics.hurt = statistics.hurt + info.value
    end
    
    local attacker = game:GetEntity(info.attacker)
    if not attacker then
        return
    end

    local pid = attacker.Force.pid 
    if game.player_statistics[pid] then
        game.player_statistics[pid].Hurt = game.player_statistics[pid].Hurt + info.value
    end

end

function M.EVENT.UNIT_HEALTH(game, info, tick) 
    local target = game:GetEntity(info.uuid)

    local statistics = game.statistics.partners[info.attacker]
    if statistics then
        statistics.health = statistics.health + info.value;
    end

    local attacker = game:GetEntity(info.attacker)
    if not attacker then
        return
    end

    local pid = attacker.Force.pid 
    if game.player_statistics[pid] then
        game.player_statistics[pid].Health = game.player_statistics[pid].Health + info.value
    end
end

local star_checker = {
    [1] = function(game) 
        return game.round_info.final_winner == 1;
    end,
    [2] = function(game, value) -- "全队平均血量X%血量";
        local hp, hpp = 0, 0;
        for uuid, v in pairs(game.statistics.partners) do
            local e = game:GetEntity(uuid);
            if e then -- TODO: removed entity ???
                hp  = hp  + e.Property.hp;
                hpp = hpp + e.Property.hpp
            end
        end

        if hpp == 0 then
            return false;
        end

        return (hp / hpp) >= (value / 100)
    end,

    [3] = function(game, value) -- 通关关卡时血量最少的角色剩余X%血量
        for uuid, v in pairs(game.statistics.partners) do
            local e = game:GetEntity(uuid);
            if not e or e.Property.hp / e.Property.hpp < value / 100 then
                    return false;
            end
        end
        return true
    end,

    [4] = function(game, value) --  通过阵亡人数少于N
        local dead = 0;
        for uuid, v in pairs(game.statistics.partners) do
            local e = game:GetEntity(uuid);
            if not e or not e:Alive() then
                dead = dead + 1;
            end
        end
        return dead < value
    end,

    [5] = function(game, value) -- 在X回合内通关
        return game.statistics.total_round <= value
    end,

    [6] = function(game, value) -- 没有使用XX技能通关
        return not game.statistics.skills_used[value]
    end,

    [7] = function(game, id1, id2) -- 在同一回合内击杀怪物1和怪物2
        if not game.statistics.monsters[id1] or not game.statistics.monsters[id2] then
            return false
        end
        return game.statistics.monsters[id1].leave_round == game.statistics.monsters[id2].leave_round
    end,

    [8] = function(game, id, round) -- 怪物(id)存活不超过round回合
        if not game.statistics.monsters[id] then
            return false
        end
        return game.statistics.monsters[id].leave_round - game.statistics.monsters[id].enter_round <= round
    end,

    [9] = function(game, value) -- 通过关卡时造成最高伤害达到
        return game.statistics.max_damage >= value
    end,

    [10] = function(game, value) -- 通过关卡时己方受到伤害不超过x
        return game.statistics.total_hurt <= value
    end,
}

local function upDateGameStatistics(game)
    game.statistics.total_round = game.round_info.round
end

function M.CheckStar(game, mustWin)
    upDateGameStatistics(game)
    local sync_data = game:GetSingleton('GlobalData');
    local sc = sync_data.star;

    if not sc[1] then
        return {};
    end

    local info = {};
    
    info[1] = star_checker[1](game);
    for k, v in ipairs(sc) do
        local checker = star_checker[v.type];
        if not checker then
            info[k+1] = false;
        else
            info[k+1] = checker(game, v.v1, v.v2);
        end
    end

    return info,sc;
end

local sync_target_maps = {
    enemy   = 100,
    partner = 101,
}

function M.EVENT.UNIT_CAST_SKILL(game, data)
    local cmd = {
        tick    = game.tick,
        type    = "INPUT",
        sync_id = data.uuid,
        skill   = data.skill,
        target  = sync_target_maps[data.target] or data.target,
    }
    table.insert(game.statistics.input_records, cmd);
end

function M.EVENT.FIGHT_FINISHED(game, data)
    if not game.player_statistics then return end

    local list = game:FindAllEntityWithComponent('Force', 'Input', 'Property', 'Round', 'Health');

    for pid, statistics in pairs(game.player_statistics) do 
        statistics.total_round = game.round_info.round
        local dead_count = 0
        for k, v in ipairs(list) do
            if not v:Alive() and v.Force.pid == pid then
                dead_count = dead_count + 1
            end
        end
        statistics.total_dead = dead_count
    end
end

function M.AddPlayerStatistics(game, pid, level)
    if not game.player_statistics then
        game.player_statistics = {}
    end

    game.player_statistics[pid] = {
        level  = level,
        Hurt   = 0,
        Health = 0,
        total_round = 0,
        total_dead  = 0,
    }
end

return M;
