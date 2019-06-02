local battle_config = require "config/battle";
local playerModule = require "module.playerModule"

local type_list = {
    [1] = 'hurt_normal.prefab',
    [2] = 'health_normal.prefab',
    [3] = 'hurt_dun.prefab',
    [4] = 'hurt_crit.prefab',
    [5] = 'health_crit.prefab',
    [6] = 'hurt_others.prefab',
}

local follow_effects = {
    [1] = {"nengliang_buff_up_r", "root"},
    [2] = {"nengliang_buff_down_r", "root"},
}

local targetSelectorManager = root.view.battle.TargetCanvas.targetSelectorPanel[SGK.Battle.BattlefieldTargetSelectorManager];

function showNumber(uuid, value, point, type, name, restrict, follow_effect)
    local script = GetBattlefiledObject(uuid) or GetBattlefiledPetsObject(uuid)
    if not script then
        -- ERROR_LOG('UnitShowNumber', 'target not exists', uuid, debug.traceback());
        return
    end

    point = point or "hitpoint"

    local pos = script:GetPosition(point) or Vector3.zero;

    local effectName = "prefabs/battlefield/" .. (type_list[type] or 'hurt_normal.prefab');
    local o = targetSelectorManager:AddUIEffect(effectName, pos)
    if not o then return; end
    local nm = o:GetComponent(typeof(CS.NumberMovement));
    if not nm.text then
        nm.text = o:GetComponent(typeof(UnityEngine.UI.Text));
    end

    nm.text.text = tostring(value);
    if nm.nameText ~= nil then
        nm.nameText.text = tostring(name or "")
    end

    if nm.restrictImage and not string.find(tostring(nm.restrictImage), "null:") then
        nm.restrictImage:SetActive(restrict and restrict > 0)
        local Selector = nm.restrictImage:GetComponent(typeof(CS.UGUISpriteSelector))
        Selector.index = restrict and restrict > 0 and restrict - 1 or 1
    end

    if follow_effects[follow_effect] then
        local entity = game:GetEntity(uuid)
        UnitAddEffect(entity, follow_effects[follow_effect][1], {hitpoint = follow_effects[follow_effect][2], duration = 2})
    end
end

local role_shownum_list = {}
local function addEntity(entity)
    if not entity.ShowNumber then return end    
    local uuid = entity.ShowNumber.uuid
    local wait_time = 0
    role_shownum_list[uuid] = role_shownum_list[uuid] or {}
    if #role_shownum_list[uuid] > 0 then
        wait_time = 0.3
    end

    table.insert(role_shownum_list[uuid], {fun = function()
        showNumber(entity.ShowNumber.uuid, entity.ShowNumber.value, nil, entity.ShowNumber.type, entity.ShowNumber.name, nil, entity.ShowNumber.follow_effect)
    end, wait_time = wait_time})
end

function Update()
    for uuid, show_list in pairs(role_shownum_list) do
        local first = show_list[1]
        if first then
            first.wait_time = first.wait_time - UnityEngine.Time.deltaTime
            if first.wait_time < 0 then
                table.remove(show_list, 1)
                first.fun();
            end
        end
    end
end

local function LoadBulletName(name_id, attacker)
    local entity = game:GetEntity(attacker)

    if entity and entity.Force.side == 1 and entity.Force.pid ~= root.pid then
        local player = playerModule.Get(entity.Force.pid)
        return player and player.name or "", 6
    end

    if entity and entity.Pet then
        return entity.Config.name
    end

    if battle_config.LoadSkill(name_id) then
        return battle_config.LoadSkill(name_id).name
    end

    if battle_config.LoadBuffConfig(name_id) then
        return battle_config.LoadBuffConfig(name_id).name
    end
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "ENTITY_ADD" then
        if root.speedUp then return end
        local uuid, entity = ...
        addEntity(entity)
    elseif event == "UNIT_HURT" then
        if root.speedUp then return end
        local info = select(1, ...)
        local name, flag = LoadBulletName(info.name_id, info.attacker)
        showNumber(info.uuid, math.floor(info.value), nil, flag or info.flag, name, info.restrict);
    elseif event == "UNIT_HEALTH" then
        if root.speedUp then return end
        local info = select(1, ...)
        local name, flag = LoadBulletName(info.name_id, info.attacker)
        showNumber(info.uuid, math.floor(info.value), nil, flag or info.flag, name);
    end
end
