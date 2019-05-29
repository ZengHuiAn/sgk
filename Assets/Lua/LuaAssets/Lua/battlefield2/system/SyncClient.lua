local OrderQueue = require "battlefield2.OrderQueue"
local Entity = require "battlefield2.Entity"

local InputSystem = require "battlefield2.system.Input"

-- 打印表的格式的方法
local function _sprinttb(tb, tabspace, deep)
    deep = deep or 0

    if deep > 20 then return '...' end

    tabspace =tabspace or ''
    local str =string.format(tabspace .. '{\n' )
    for k,v in pairs(tb or {}) do
        if type(v)=='table' then
            if type(k)=='string' then
                str =str .. string.format("%s%s =\n", tabspace..'  ', k)
                str =str .. _sprinttb(v, tabspace..'  ', deep + 1)
            elseif type(k)=='number' then
                str =str .. string.format("%s[%d] =\n", tabspace..'  ', k)
                str =str .. _sprinttb(v, tabspace..'  ', deep + 1)
            end
        else
            if type(k)=='string' then
                str =str .. string.format("%s%s = %s,\n", tabspace..'  ', tostring(k), tostring(v))
            elseif type(k)=='number' then
                str =str .. string.format("%s[%s] = %s,\n", tabspace..'  ', tostring(k), tostring(v))
            end
        end
    end
    str =str .. string.format(tabspace .. '},\n' )
    return str
end

function sprinttb(tb, tabspace)
    local function ss()
        return _sprinttb(tb, tabspace);
    end
    return setmetatable({}, {
        __concat = ss,
        __tostring = ss,
    });
end



local Sync = {NOTIFY = {}}

--[[
local NOTIFY = {
    ENTITY_ADD     = 'ENTITY_ADD', -- 1,
    ENTITY_CHANGE  = 'ENTITY_CHANGE', -- 2,
    ENTITY_REMOVED = 'ENTITY_REMOVED', -- 3,

    UNIT_HURT      = 'UNIT_HURT', -- 101,
    UNIT_HEALTH    = 'UNIT_HEALTH', -- 102,
}
--]]

function Sync.Init(game)
    game.inputQueue = OrderQueue();
end

function Sync.Start(game)
end

function Sync.Tick(game)
    while game.sync_reader do
        local tick, event, data = game.sync_reader(game);
        if not tick then
            break;
        end

        -- game:LOG('+', tick, event, data);
        game.inputQueue:Append(tick, event, data);
    end

    while true do
        local tick, event, data = game.inputQueue:Pop(game.tick)
        if not tick then
            break;
        end

        -- game:LOG('-', tick, event, data);
        if Sync.NOTIFY[event] then
            Sync.NOTIFY[event](game, data, tick);
        end
    end
end

function Sync.Stop()
end

local Component = {
    Property      = require "battlefield2.component.Property",
    Skill         = require "battlefield2.component.Skill",
    Health        = require "battlefield2.component.Health",
    Force         = require "battlefield2.component.Force",
    Round         = require "battlefield2.component.Round",
    GameRound     = require "battlefield2.component.Round",
    Input         = require "battlefield2.component.Input",
    Buff          = require "battlefield2.component.Buff",

    Pet           = require "battlefield2.component.Pet",

    Bullet        = require "battlefield2.component.Bullet",
    MagicField    = require "battlefield2.component.MagicField",

    BuffInventory = require "battlefield2.component.EntityBag",
    PetInventory  = require "battlefield2.component.EntityBag",

    Config        = require "battlefield2.component.Config",
    Position      = require "battlefield2.component.Position",

    GlobalData    = require "battlefield2.component.GlobalData",

    PetHealth     = require "battlefield2.component.PetHealth",

    ShowNumber    = require "battlefield2.component.ShowNumber",
    RandomBuff    = require "battlefield2.component.RandomBuff",

    AutoKill      = require "battlefield2.component.AutoKill",
    Timeout       = require "battlefield2.component.Timeout",
    Player        = require "battlefield2.component.Player",
    SingSkill     = require "battlefield2.component.SingSkill",
    AutoInput     = require "battlefield2.component.AutoInput",
}

function Sync.Decode(data)
    local entity = Entity(data[1]);
    
    for _, v in ipairs(data[2] or {}) do
        local class = Component[ v[1] ]
        if v[1] == "Health" and v[2] then
            class = Component['PetHealth'];
        end

        local comp = nil;
        if class then
            comp = entity:AddComponent(v[1], class());
        else
            assert(false, 'unknown component ' .. v[1])
        end

        if comp and comp.DeSerialize then
            comp:DeSerialize(v[2]);
        end
    end

    return entity;
end

function Sync.NOTIFY.ENTITY_ADD(game, data, tick)
    game:LOG('Sync.NOTIFY.ENTITY_ADD', tick, sprinttb(data));
    -- game.sync_server:DispatchEvent(NOTIFY.ENTITY_ADD, entity:Serialize());
    local entity = Sync.Decode(data)
    
--[[
    if entity.Buff then
        game:LOG('add buff', entity.uuid);
    end

    if entity.Input and entity.Property then
        game:LOG('add role', entity.uuid);
    end

    if entity.Bullet then
        game:LOG('add bullet', entity.uuid);
    end
--]]

    game:AddEntity(entity);
end

function Sync.NOTIFY.ENTITY_REMOVED(game, data, tick)
    -- game.sync_server:DispatchEvent(NOTIFY.ENTITY_REMOVED, {uuid});
    game:LOG('entity removed', data[1]);
    game:RemoveEntity(data[1]);
end

function Sync.NOTIFY.ENTITY_CHANGE(game, data, tick)
    game:LOG('Sync.NOTIFY.ENTITY_CHANGE', sprinttb(data));

    local entity = game:GetEntity(data[1]);
    if entity then
        entity:ApplyChange(data);
    end
    game:DispatchEvent('ENTITY_CHANGE', data[1], entity);
end

function Sync.NOTIFY.UNIT_HURT(game, data, tick)
    -- game:LOG('UNIT_HURT', data[1], data[2]);
    game:DispatchEvent('UNIT_HURT', {uuid = data[1], value = data[2], flag = data[3], name_id = data[4], attacker = data[5], element = data[6], restrict = data[7]});
end

function Sync.NOTIFY.UNIT_HEALTH(game, data, tick) 
    -- game:LOG('UNIT_HEALTH', data[1], data[2]);
    game:DispatchEvent('UNIT_HEALTH', {uuid = data[1], value = data[2], flag = data[3], name_id = data[4], attacker = data[5], element = data[6]});
end

function Sync.NOTIFY.UNIT_CAST_SKILL(game, data, tick)
    game:LOG('UNIT_CAST_SKILL', data[1], data[2], data[3])
    game:DispatchEvent('UNIT_CAST_SKILL', {uuid = data[1], skill = data[2], target = data[3], skill_type = data[4]});
end

function Sync.NOTIFY.UNIT_SKILL_FINISHED(game, data, tick)
    game:LOG('UNIT_SKILL_FINISHED', data[1]);
    game:DispatchEvent('UNIT_SKILL_FINISHED', {uuid = data[1]})
end

function Sync.NOTIFY.UNIT_BEFORE_ACTION(game, data)
    game:DispatchEvent('UNIT_BEFORE_ACTION', data[1]);
end

function Sync.NOTIFY.UNIT_AFTER_ACTION(game, data)
    game:DispatchEvent('UNIT_AFTER_ACTION', data[1]);
end

function Sync.NOTIFY.UNIT_PREPARE_ACTION(game, data)
    game:DispatchEvent('UNIT_PREPARE_ACTION', data[1]);
end

function Sync.NOTIFY.WAVE_ALL_ENTER(game)
    game:DispatchEvent('WAVE_ALL_ENTER');
end

function Sync.NOTIFY.ROUND_START(game)
    game:DispatchEvent('ROUND_START');
end

function Sync.NOTIFY.WAVE_START(game)
    game:DispatchEvent('WAVE_START');
end

function Sync.NOTIFY.WAVE_FINISHED(game)
    game:DispatchEvent('WAVE_FINISHED');
end

function Sync.NOTIFY.UNIT_PLAY_ACTION(game, data)
    game:DispatchEvent("UNIT_PLAY_ACTION", data[1], data[2]);
end

function Sync.NOTIFY.FIGHT_FINISHED(game, data)
    game.round_info.final_winner = data[1];
    game:DispatchEvent("FIGHT_FINISHED", data[1]);
end

function Sync.NOTIFY.UNIT_SHOW_NUMBER(game, data)
    game:DispatchEvent("UNIT_SHOW_NUMBER", {uuid = data[1], value = data[2], type = data[3], name = data[4]});
end

function Sync.NOTIFY.ADD_BATTLE_DIALOG(game, data)
    game:DispatchEvent("ADD_BATTLE_DIALOG", {dialog_id = data[1]});
end

function Sync.NOTIFY.PALY_BATTLE_GUIDE(game, data)
    game:DispatchEvent("PALY_BATTLE_GUIDE", {id = data[1]});
end

function Sync.NOTIFY.SHOW_ERROR_INFO(game, data)
    game:DispatchEvent("SHOW_ERROR_INFO", {id = data[1]});
end

function Sync.NOTIFY.SKILL_CHANGE_ID(game, data)
    game:DispatchEvent("SKILL_CHANGE_ID", data[1], data[2], data[3]);
end

function Sync.NOTIFY.SHOW_BUFF_EFFECT(game, data)
    game:DispatchEvent("SHOW_BUFF_EFFECT", data[1], data[2], data[3], data[4]);
end

function Sync.NOTIFY.SYNC(game, data)
    game.tick = data[1]

    for _, v in ipairs(data[2]) do
        Sync.NOTIFY.ENTITY_ADD(game, data)
    end
end

function Sync.SetReader(game, reader)
    game.sync_reader     = reader
end

return Sync;
