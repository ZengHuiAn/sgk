local Sync = {EVENT = {}, API = {}}

local NOTIFY = setmetatable({
}, {__index=function(t,k)
    return k
end})

local function SendLog(game, event, data)
    game.sync_writer = game.sync_writer or function(...)
        io.stdout(...);
    end
    game.sync_writer(game.tick, event, data);
end

function Sync.Start(game)
end

function Sync.Tick(game)
    local changes = {}
    for _, e in pairs(game.entities) do
        if not e:GetComponent('SERVER_ONLY') then
            local change = e:SerializeChange(); 
            if change then
                SendLog(game, NOTIFY.ENTITY_CHANGE, change);
            end
        end
    end
end

function Sync.Stop()
end

function Sync.EVENT.ENTITY_ADD(game, uuid)
    local entity = game:GetEntity(uuid);
    if entity and not entity:GetComponent('SERVER_ONLY') then
        SendLog(game, NOTIFY.ENTITY_ADD, entity:Serialize())
    end
end

function Sync.EVENT.ENTITY_REMOVED(game, uuid, entity, opt)
    if entity and entity:GetComponent('SERVER_ONLY') then return end;
    if entity and entity.AutoKill and opt and opt.auto_remove then return end;

    SendLog(game, NOTIFY.ENTITY_REMOVED, {uuid});
end

function Sync.EVENT.UNIT_HURT(game, data)
    SendLog(game, NOTIFY.UNIT_HURT, {data.uuid, data.value, data.flag, data.name_id, data.attacker, data.element, data.restrict});
end

function Sync.EVENT.UNIT_HEALTH(game, data)
    SendLog(game, NOTIFY.UNIT_HEALTH, {data.uuid, data.value, data.flag, data.name_id, data.attacker, data.element});
end

function Sync.EVENT.UNIT_CAST_SKILL(game, data)
    SendLog(game, NOTIFY.UNIT_CAST_SKILL, {data.uuid, data.skill, data.target, data.skill_type});
end

function Sync.EVENT.UNIT_SKILL_FINISHED(game, data)
    SendLog(game, NOTIFY.UNIT_SKILL_FINISHED, {data.uuid});
end

-- skill
function Sync.EVENT.UNIT_PREPARE_ACTION(game, uuid)
    SendLog(game, NOTIFY.UNIT_PREPARE_ACTION, {uuid});
end

function Sync.EVENT.UNIT_BEFORE_ACTION(game, uuid)
    SendLog(game, NOTIFY.UNIT_BEFORE_ACTION, {uuid});
end

function Sync.EVENT.UNIT_AFTER_ACTION(game, uuid)
    SendLog(game, NOTIFY.UNIT_AFTER_ACTION, {uuid});
end

function Sync.EVENT.WAVE_ALL_ENTER(game)
    SendLog(game, NOTIFY.WAVE_ALL_ENTER);
end

function Sync.EVENT.ROUND_START(game)
    SendLog(game, NOTIFY.ROUND_START);
end

function Sync.EVENT.WAVE_START(game)
    SendLog(game, NOTIFY.WAVE_START);
end

function Sync.EVENT.WAVE_FINISHED(game)
    SendLog(game, NOTIFY.WAVE_FINISHED);
end

function Sync.EVENT.UNIT_PLAY_ACTION(game, uuid, action)
    SendLog(game, NOTIFY.UNIT_PLAY_ACTION, {uuid, action});
end

function Sync.EVENT.FIGHT_FINISHED(game, winner)
    SendLog(game, NOTIFY.FIGHT_FINISHED, {winner})
end

function Sync.EVENT.ADD_BATTLE_DIALOG(game, data)
    SendLog(game, NOTIFY.ADD_BATTLE_DIALOG, {data.dialog_id});
end

function Sync.EVENT.PALY_BATTLE_GUIDE(game, data)
    SendLog(game, NOTIFY.PALY_BATTLE_GUIDE, {data.id});
end

function Sync.EVENT.SHOW_ERROR_INFO(game, data)
    SendLog(game, NOTIFY.SHOW_ERROR_INFO, {data.id});
end

function Sync.EVENT.SKILL_CHANGE_ID(game, uuid, index, id)
    SendLog(game, NOTIFY.SKILL_CHANGE_ID, {uuid, index, id});
end

function Sync.EVENT.SHOW_BUFF_EFFECT(game, uuid, icon, name, up)
    SendLog(game, NOTIFY.SHOW_BUFF_EFFECT, { uuid, icon, name, up});
end

function Sync.SetWriter(game, writer)
    game.sync_writer = writer;
end

function Sync.SYNC(game)
    local list = game:FindAllEntityWithComponent()
    
    local info = {game.tick, {}}
    for _, v in ipairs(list) do
        table.insert(info[2], v:Serialize())
    end

    SendLog(game, NOTIFY.SYNC, info);
end

return Sync;
