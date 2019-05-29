local effect_list = {
    [80000014] = {scene_effect = "fx_battle_duwu"},
    [11001]    = {scene_effect = "fx_battle_duwu"},
    [80000007] = {dead_effect = true},
    [10301]    = {dead_effect = true},
}

local function loadAsync(effectName, func)
    return LoadAsync("prefabs/effect/" .. effectName .. ".prefab", function(prefab)
        if prefab == nil then 
            print(effectName, 'not exists');
            return;
        end
        func(prefab);
    end)
end

local function add_scene_effect(...)
    local fight_id = game.round_info.fight_id
    if not effect_list[fight_id] or not effect_list[fight_id].scene_effect then return end

    local effectName = effect_list[fight_id].scene_effect

    loadAsync(effectName, function(prefab)
        if prefab == nil then return end;
        o = UnityEngine.GameObject.Instantiate(prefab, root.view.battle.transform)

        o.transform.localPosition = UnityEngine.Vector3.zero;
        o.transform.localScale = Vector3.one;
    end);
end

local dead_effect = nil
local deat_effect_uuid = nil
local function add_dead_effect(creater, entity)
    local fight_id = game.round_info.fight_id
    if not effect_list[fight_id] or not effect_list[fight_id].dead_effect then return end

    if creater.Property[5120003] > 0 then
        local script = GetBattlefiledObject(creater.uuid)

        loadAsync("fx_tudui", function(prefab)
            if prefab == nil then return end;
            o = UnityEngine.GameObject.Instantiate(prefab, script.gameObject.transform)
    
            o.transform.localPosition = UnityEngine.Vector3.zero;
            o.transform.localScale = Vector3.one;
            dead_effect = o;
            deat_effect_uuid = entity.uuid
        end);
    end
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "AFTER_PRELOAD" then
        game:CallAt(10 ,function()
            add_scene_effect()
        end)
    elseif event == "ENTITY_ADD" then
        if root.speedUp then return end
        local uuid, entity = ...
        if entity.RandomBuff then
            local creater = game:GetEntity(entity.RandomBuff.creater)
            add_dead_effect(creater, entity)
        end
    elseif event == "ENTITY_REMOVED" then
        if root.speedUp then return end
        local uuid, entity = ...
        if deat_effect_uuid and entity.uuid == deat_effect_uuid then
            UnityEngine.GameObject.Destroy(dead_effect, 0.1);
            dead_effect = nil
            deat_effect_uuid = nil
        end
    end
end
