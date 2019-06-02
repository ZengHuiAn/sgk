local Property     = require "battlefield2.component.Property"
local Buff         = require "battlefield2.component.Buff"
local Config       = require "battlefield2.component.Config"
local BuffAction   = require "battlefield2.component.BuffAction"
local SandBox      = require "utils.SandBox2"

local Entity    = require "battlefield2.Entity"
local battle_config = require "config.battle";

local M = {EVENT={}, API = {}, NOTIFY = {}}

function M.Start(game)
end

function M.Stop(game)
end

function M.EVENT.ENTITY_WILL_REMOVE(game, uuid, entity)
    if entity.BuffInventory then
        entity.BuffInventory:Clean();
    end

    if entity.Buff then
        local owner = game:GetEntity(entity.Buff.target)
        if owner and owner.BuffInventory then
            game:LOG('REMOVE BUFF', entity.Config.name or entity.Config.id, '->', owner.Config.name);
            owner.BuffInventory:Remove(entity.uuid);
            if owner.Property then
                owner.Property:Remove(entity.uuid);
            end
        end

        if not game.client then
            local onEnd = entity:GetComponent("BulletFilter_onEnd")
            if onEnd then
                onEnd:Do(owner:Export(), entity:Export());
            end
        end
    end
end

function M.EVENT.ENTITY_ADD(game, uuid, entity)
    if not entity.Buff then return end

    local owner = game:GetEntity(entity.Buff.target)
    if not owner then
        game:LOG('buff target', entity.uuid, ' not exists');
        return;
    end

    if owner and owner.BuffInventory then
        game:LOG('ADD BUFF', entity.Config.name or entity.Config.id, '->', owner.Config.name);
        owner.BuffInventory:Add(entity);

        if entity.Property and owner.Property then
            owner.Property:Add(entity.uuid, entity.Property);
        end
    end

    if not game.client then
        local onStart = entity:GetComponent("BulletFilter_onStart")
        if onStart then
            onStart:Do(owner:Export(), entity:Export());
        end
    end
end

local function buffExport(e)
    return setmetatable({e = e:Export()}, {__index=function(t, k)
        if k == "target" then
            return t.e.game:GetEntity(t.e.Buff.target):Export();
        end
        return t.e[k];
    end, __newindex=function(t, k, v)
        t.e[k] = v; 
    end})
end

function M.EVENT.ROUND_START(game)
    local list = game:FindAllEntityWithComponent("BulletFilter_onRoundStart","Buff")
    for _, v in ipairs(list) do
        local entity = game:GetEntity(v.Buff.target)
        v.BulletFilter_onRoundStart:Do(entity:Export(), buffExport(v))
    end
end

function M.EVENT.WAVE_ALL_ENTER(game)
    local list = game:FindAllEntityWithComponent("BulletFilter_afterAllEnter","Buff")
    for _, v in ipairs(list) do
        local entity = game:GetEntity(v.Buff.target)
        v.BulletFilter_afterAllEnter:Do(entity:Export(), buffExport(v))
    end
end

function M.EVENT.UNIT_DEAD(game, uuid)
    local list = game:FindAllEntityWithComponent("BulletFilter_onRoleDead","Buff")
    for _, v in ipairs(list) do
        local entity = game:GetEntity(v.Buff.target)
        local dead_entity = game:GetEntity(uuid)
        v.BulletFilter_onRoleDead:Do(entity:Export(), buffExport(v), dead_entity:Export())
    end
end

function M.API.UnitAddBuff(skill, target, id, _round, context, extra)
    target = target or skill.entity;
    return buffExport(M.Add(skill.game, target.uuid, id, _round, context, extra));
end

function M.API.UnitAddBuff2(skill, id, duration, property, extra)
    M.Add(skill.game, skill.entity.uuid, id, duration, property, extra);
end

function M.API.UnitRemoveBuff(skill, buff)
    skill.game:RemoveEntity(buff.uuid);
end

function M.API.UnitBuffList(skill, target, ...)
    if not target.BuffInventory then
        return {}
    end

    local list = target.BuffInventory:FindAllEntityWithComponent("Buff")
    local buffs = {}
    for _, v in ipairs(list) do
        table.insert(buffs, buffExport(v));
    end
    return buffs;
end

function M.API.LoadBuffCfg(skill, id)
    return battle_config.LoadBuffConfig(id)
end

function M.DoAction(game, entity, action, ...)
    if not entity then return end

    -- game:LOG('Buff.DoAction start', action);

    local bag = entity:GetComponent("BuffInventory");
    if not bag then return end;

    local list = bag:FindAllEntityWithComponent(action);

    for _, e in ipairs(list) do
        local comp = e:GetComponent(action);
        if comp then
            -- game:LOG('buff action', e.Config.name, action);
            comp:Do(entity:Export(), buffExport(e), ...);
        end
    end
    -- game:LOG('Buff.DoAction end', action);
end


function M.Add(game, uuid, id, duration, property, extra)
    -- game:LOG('BuffSystem.Add', uuid, id, duration, property);

    local target_entity = game:GetEntity(uuid);
    if not target_entity then
        -- game:LOG('  target not exists');
        return;
    end

    local bag = target_entity:GetComponent("BuffInventory");
    if not bag then
        -- game:LOG('  BuffInventory not exists');
        return;
    end

    local entity = Entity();

    local round_info = game:GetGlobalData();

    entity:AddComponent("Buff", Buff(target_entity.uuid, round_info.round + duration));

    local buff_property;
    if true or property then
        buff_property = entity:AddComponent("Property", Property(property));
    end

    local cfg = entity:AddComponent("Config", Config("BUFF", id, extra))

    local script_id = cfg and cfg.script_id or id;

    local script;

    game.__shared_library = game.__shared_library or {}
    script = SandBox.New(string.format('script/buff/%s.lua', script_id), setmetatable({
        game = game,
        entity = target_entity,
        attacker = target_entity:Export(),
    }, {__index=function(t, k)
        local func = t.game.API[k]
        if func then
            return function(...)
                return func(script, ...)
            end
        elseif UnityEngine then
            return function(...)
                -- game:LOG('<color=red>', 'UNKNOWN API', k, '</color>\n', debug.traceback());
            end
        else
            return function() end
        end
    end}), game.__shared_library)

    script:LoadLib("script/common.lua", game.__shared_library);

    script:Call();

    -- local script = {} -- TOD: load script

    local function addFilter(name)
        if rawget(script, name) then
            entity:AddComponent("BulletFilter_" .. name, BuffAction(script[name]))
        end
    end

    addFilter('onStart');
    addFilter('onEnd');

    addFilter('onRoundStart');

    addFilter('attackerBeforeAttack');
    addFilter('targetBeforeAttack');

    addFilter('attackerFilter');

    addFilter('attackerAfterAttack');
    addFilter('targetAfterAttack');

    addFilter('attackerBeforeHit')
    addFilter('targetBeforeHit')

    addFilter('targetFilter')

    addFilter('attackerWillHit')
    addFilter('targetWillHit')

    addFilter('attackerAfterCalc');
    addFilter('targetAfterCalc');

    addFilter('attackerAfterHit')
    addFilter('targetAfterHit')

    addFilter('onTick')
    addFilter('beforePostTick')
    addFilter('onPostTick')

    addFilter('afterAllEnter')

    addFilter('onRoleDead')

    game:AddEntity(entity);

    return entity;
end

return M;
