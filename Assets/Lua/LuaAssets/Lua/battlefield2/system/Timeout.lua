local InputSystem = require "battlefield2.system.Input"
local Timeout = require "battlefield2.component.Timeout"

local M = {
    EVENT={}
}

function M.Init(game)
    game.player_timeount_list = {}
    game.role_timeount_list = {}
end

function M.ReStart(game, component)
    component.timeout_tick = game:GetTick(component.duration)
    return component
end

function M.EVENT.UNIT_BEFORE_ACTION(game, uuid)
    local entity = game:GetEntity(uuid)
    if not entity.Timeout then return end

    local component = M.ReStart(game, entity.Timeout)
    game.role_timeount_list[uuid] = component.timeout_tick
end

function M.EVENT.UNIT_AFTER_ACTION(game, uuid)
    local entity = game:GetEntity(uuid)
    if not entity.Timeout then return end

    game.role_timeount_list[uuid] = nil
end

function M.EVENT.ROUND_START(game)
    if not game.timeout_config then
        return
    end
    
    game.player_timeount_list = {}
    local Player_list = game:FindAllEntityWithComponent("Timeout","Player")
    
    for _, entity in ipairs(Player_list) do
        local component = M.ReStart(game, entity.Timeout)
        table.insert(game.player_timeount_list, {uuid = entity.uuid, timeout_tick = component.timeout_tick}) 
    end

    table.sort(game.player_timeount_list, function (a, b)
        if a.timeout_tick == b.timeout_tick then
            return a.uuid < b.uuid
        end
        return a.timeout_tick < b.timeout_tick
    end)

    for pid, _ in pairs(game.next_wave_auto_input or {}) do
        game:SetAutoInput(true, pid)
    end
    game.next_wave_auto_input = {}
end

function M.Tick(game)
    if game.player_timeount_list[1] and game:GetTick() > game.player_timeount_list[1].timeout_tick then
        local role_list = game:FindAllEntityWithComponent("Input")
        for _, list in ipairs(game.player_timeount_list) do
            local player = game:GetEntity(list.uuid)
            if player and game:GetTick() >= list.timeout_tick then
                for _, role in ipairs(role_list) do
                    if role.Force.pid == player.Player.pid and role.Input.token then
                        if game.timeout_config and game.timeout_config.type == 0 then
                            game.next_wave_auto_input = game.next_wave_auto_input or {}
                            game.next_wave_auto_input[role.Force.pid] = true;
                        end
                        InputSystem.Push(role.Input, "DEF", "SKILL");
                    end
                end
            else
                break
            end
        end
    end

    for uuid, timeout_tick in pairs(game.role_timeount_list) do
        local entity = game:GetEntity(uuid)
        if not entity or not entity.Input then
            game.role_timeount_list[uuid] = nil
        elseif game:GetTick() > timeout_tick and entity.Input.token then
            if game.timeout_config and game.timeout_config.type == 0 then
                game.next_wave_auto_input = game.next_wave_auto_input or {}
                game.next_wave_auto_input[role.Force.pid] = true;
            end
            InputSystem.Push(entity.Input, "DEF", "SKILL");
        end
    end
end

function M.SetTimeout(game, time, type)
    game:ERROR('set timeout')
    game.timeout_config = {  time = time, type = type or 0 }
    local Player_list = game:FindAllEntityWithComponent("Player", "Timeout")
    for k, v in ipairs(Player_list) do
        v.Timeout.duration = time
    end
end

function M.EVENT.ENTITY_ADD(game, uuid, entity)
    local cfg = game.timeout_config;

    if not cfg then
        game:ERROR('NO TIMEOUT CONFIG')
    end

    if not cfg then return; end;

    if entity.Player and cfg.type == 0 then
        entity:AddComponent("Timeout", Timeout(cfg.time))
    elseif entity.Input and entity.Force and entity.Round and cfg.type == 1 then
        entity:AddComponent("Timeout", Timeout(cfg.time))
    end
end

return M;
