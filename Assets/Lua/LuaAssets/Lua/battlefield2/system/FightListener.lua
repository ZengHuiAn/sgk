local BuffAction   = require "battlefield2.component.BuffAction"
local SandBox      = require "utils.SandBox2"

local Entity    = require "battlefield2.Entity"
local battle_config = require "config.battle";

local M = {EVENT={}, API = {}, NOTIFY = {}}

function M.AddFightListener(game, fight_id, fight_type,script_id)
    local entity = Entity();
    entity:AddComponent("FightListener", {fight_id = fight_id});

    if not script_id then
        script_id = fight_id
    end

    local script;
    script = SandBox.New(string.format('script/fight/%s.lua', script_id), setmetatable({
        game = game,
        __fight_id = fight_id ,
        __fight_type = fight_type,
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

    game.__shared_library = game.__shared_library or {}
    script:LoadLib("script/common.lua", game.__shared_library);
    script:Call();

    local function addFilter(name)
        if rawget(script, name) then
            return entity:AddComponent("Fight_" .. name, BuffAction(script[name]))
        end
    end

    addFilter('onWaveStart');
    addFilter('onRoundStart');
    addFilter('afterAllEnter');
    local onFightStart = addFilter('onFightStart');
    if onFightStart then
        onFightStart:Do();
    end
    addFilter('onFightEnd');

    game:AddEntity(entity);
    game.fight_listner = entity.uuid;

    return entity;
end

function M.EVENT.ROUND_START(game)
    if not game.fight_listner then
        return
    end

    local fight_listner = game:GetEntity(game.fight_listner)
    if not fight_listner then
        return
    end

    local onRoundStart = fight_listner:GetComponent("Fight_onRoundStart")
    if onRoundStart then
        onRoundStart:Do(game.round_info.round, game.round_info.wave);
    end
end

function M.EVENT.WAVE_START(game)
    if not game.fight_listner then
        return
    end

    local fight_listner = game:GetEntity(game.fight_listner)
    if not fight_listner then
        return
    end

    local onWaveStart = fight_listner:GetComponent("Fight_onWaveStart")
    if onWaveStart then
        onWaveStart:Do(game.round_info.round, game.round_info.wave);
    end
end

function M.EVENT.FIGHT_FINISHED(game, winner)
    if not game.fight_listner then
        return
    end

    local fight_listner = game:GetEntity(game.fight_listner)
    if not fight_listner then
        return
    end

    local onFightEnd = fight_listner:GetComponent("Fight_onFightEnd")
    if onFightEnd then
        onFightEnd:Do(game.round_info.round, game.round_info.wave, winner);
    end
end

function M.EVENT.WAVE_ALL_ENTER(game)
    if not game.fight_listner then
        return
    end

    local fight_listner = game:GetEntity(game.fight_listner)
    if not fight_listner then
        return
    end

    local afterAllEnter = fight_listner:GetComponent("Fight_afterAllEnter")
    if afterAllEnter then
        afterAllEnter:Do(game.round_info.round, game.round_info.wave);
    end
end

return M;
