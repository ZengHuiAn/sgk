local battle_config = require "config/battle";
local Buff = require "config/battle";

local cameraEffectSlot = root.view.battle.player.MainCamera.CameraEffectSlot.transform;
local targetSelectorManager = root.view.battle.TargetCanvas.targetSelectorPanel[SGK.Battle.BattlefieldTargetSelectorManager];

local cameraController = root.view.battle.cameraController[SGK.Battle.BattleCameraController]
cameraController:CameraMoveReset(root.view.battle.CameraSlot[3].transform, 0.1);
cameraController:CameraLookReset(root.view.battle.enemyStage.slot11.transform, 0.1);

local function updateSkeletonDataAsset(skeletonAnimation, name, hitpoint)
    CS.SkeletonAnimationAnchoredPosition.Attach(skeletonAnimation, hitpoint);
    skeletonAnimation:UpdateSkeletonAnimation(string.format("roles/%s/%s_SkeletonData", name, name), {"idle"});
end

local function findInChild(o, T)
    return o.transform:GetComponentsInChildren(typeof(T), true)
end

local function findSpine(o, cfg)
    if not cfg.spine_action then return end
    local objects = findInChild(o, CS.Spine.Unity.SkeletonAnimation)
    objects[0].AnimationState:SetAnimation(0 , cfg.spine_action, false)
end

local function findText(o, cfg)
    if not cfg.text then return end

    local objects = findInChild(o, UnityEngine.TextMesh)
    if type(cfg.text) == "string" then
        for i = 1, objects.Length do
            if objects[i-1].gameObject.tag == "big_skill" then
                objects[i-1].text = cfg.text;
                break;
            end
        end
    elseif type(cfg.text) == "table" then
        local slots = {};
        for i = 1, objects.Length do
            if objects[i-1].gameObject.tag == "big_skill" then
                table.insert(slots, objects[i-1]);
            end
        end

        for k, v in ipairs(cfg.text) do
            if slots[k] then
                slots[k].text = v
            end
        end
    end
end

local function findMode(o, cfg)
    if cfg.modes then
        local slots = {};
        local objects = findInChild(o, Spine.Unity.SkeletonAnimation);
        for i = 1, objects.Length do
            if objects[i-1].gameObject.tag == "big_skill" then
                table.insert(slots, objects[i-1]);
            end
        end

        for k, v in ipairs(cfg.modes) do
            if slots[k] then
                updateSkeletonDataAsset(slots[k], v, cfg.hitpoint or "root")
            end
        end
    elseif cfg.mode then
        local objects = findInChild(o, Spine.Unity.SkeletonAnimation);
        for i = 1, objects.Length do
            if objects[i-1].gameObject.tag == "big_skill" then
                updateSkeletonDataAsset(objects[i-1], cfg.mode, cfg.hitpoint or "root")
            end
        end
    end
end

local function findHalo(o, cfg)
    if not cfg.Halo_icon then return end;

    local slots = {};
    local objects = findInChild(o, UnityEngine.SpriteRenderer)
    for i = 1, objects.Length do
        if objects[i-1].gameObject.tag == "big_skill" then
            table.insert(slots, objects[i-1]);
        end
    end

    for k, v in ipairs(cfg.Halo_icon) do
        if slots[k] then
            slots[k].sprite = SGK.ResourcesManager.Load("icon/" .. v .. ".png", typeof(UnityEngine.Sprite));
        end
    end
end

local function loadAsync(effectName, func)
    return LoadAsync("prefabs/effect/" .. effectName .. ".prefab", function(prefab)
        if prefab == nil then 
            print(effectName, 'not exists');
            return;
        end
        func(prefab);
    end)
end

--[=[
function API.AddStageEffect(skill, effectName, cfg)
    cfg = cfg or {};

--[[
    if cfg.click_skip and self.auto_input and not self:NeedSyncData() then
        self.game:CleanSleep()
        return
    end
--]]

    if skill.entity and effectName == "UI/fx_zhaohuanwu" 
        and skill.entity.Force.side ~= 1 then
        effectName = "UI/fx_zhaohuanwu_di"
    end

    local position = cfg.offset and Vector3(unpack(cfg.offset)) or Vector3.zero;

    local duration = cfg.duration or 1.0;
    local scale    = cfg.scale or 1;
    local rotation = cfg.rotation or 0;

    local hitpoint = cfg.hitpoint or "root";

    if not effectName then
        return
    end

    loadAsync(effectName, function(prefab)
        local o = UnityEngine.GameObject.Instantiate(prefab)

        if o.tag == "camera_skill_effect" then
            o.transform.parent = cameraEffectSlot
        end

        o.transform.localPosition = position;
        findSpine(o, cfg);
        findText(o, cfg);
        findMode(o, cfg);
        findHalo(o, cfg);

        o.transform.localScale = Vector3.one * scale;
        if cfg.opposite then o.transform.localScale = Vector3(1, 1, -1) * scale end
        o.transform.localRotation = Quaternion.Euler(0, 0, rotation);

        if duration > 0 then
            UnityEngine.GameObject.Destroy(o, duration);
        end
--[[
        if cfg.click_skip then
            self.current_long_time_effect = o
            self.view.battle.PersistenceCanvas.EffectSkipMask:SetActive(true)
            self:CallAfter(duration, function ()
                self.view.battle.PersistenceCanvas.EffectSkipMask:SetActive(false)
                self.current_long_time_effect = nil
            end)
        end
        
        self.gameObjectPool:Release(o, duration);
--]]
    end);
end
--]=]
local function CanvasGroupActive(view, active)
    view[UnityEngine.CanvasGroup].alpha = active and 1 or 0;
    view[UnityEngine.CanvasGroup].interactable = not not active;
    view[UnityEngine.CanvasGroup].blocksRaycasts = not not active;
end


function ShowUI(show)    
    local roles = GetAllBattlefiledObject();
    for _, v in pairs(roles) do
        CanvasGroupActive(v.ui, show);
    end

    CanvasGroupActive(root.view.battle.Canvas, show);
    CanvasGroupActive(root.view.battle.EnemyBossCanvas, show);
end

function UnitAddEffect(target, effectName, cfg, callback)
    if not effectName then
        return
    end

    cfg = cfg or {}
    local point = cfg.hitpoint or "hitpoint"

    local duration = cfg.duration or 3
    local scale = cfg.scale or 1;
    
    -- scale = scale * (target.effect_scale > 0 and target.effect_scale or 1);

    local rotation = cfg.rotation or 0;

    local script = GetBattlefiledObject(target.uuid)
    local ispet
    if not script then
        script = GetBattlefiledPetsObject(target.uuid)
        ispet = true
        -- return
    end

    if not script then
        return;
    end

    local sortOrder;
    if target.Force.side == 1 then
        sortOrder = 5;
        scale = scale * 0.4;
    end

    loadAsync(effectName, function(prefab)
        local o = UnityEngine.GameObject.Instantiate(prefab);
        o.transform:Rotate(Vector3.forward * rotation);

        findSpine(o, cfg);
        findText(o, cfg);

        local cameraScripts = o:GetComponents(typeof(SGK.BattleCameraScriptAction));
        if cameraScripts then
            for i = 0, cameraScripts.Length - 1 do
                local cameraScript = cameraScripts[i]
                if cameraScript.autoTarget then
                    cameraScript.target = script.transform;
                else
                    cameraScript.target = root.view.battle.player.gameObject.transform;
                end
            end
        end

        if duration > 0 then
            UnityEngine.GameObject.Destroy(o, duration);
        else
            callback(o);
            -- return o;
        end

        local offset = cfg.offset and Vector3(unpack(cfg.offset)) or Vector3.zero;
        -- print(">>>>>AddEffectToSlot>>>>>>>>>", point, o.name, offset)
        if not ispet then
            script:AddEffectToSlot(point, o, offset, cfg.effect_auto_hide_type or 0)
        else
            CS.FollowTarget.Follow(o.gameObject, GetBattlefiledPetsObject(target.uuid).transform, -1) -- self.skillManager:GetButtonTransform(index);
        end

        o.transform.localScale = Vector3.one * scale;
        if cfg.opposite then o.transform.localScale = Vector3(1, 1, -1) * scale end
    end);

end

local function showStageEffect(entity)
    if entity.MagicField.side == 1 and entity.MagicField.pid ~= 0 and entity.MagicField.pid ~= root.pid then
        return
    end

    if entity.MagicField.duration <= game.tick then
        return;
    end

    local id = entity.MagicField.id;
    local cfg = battle_config.LoadSkillEffectCfg(id);
    local side = entity.MagicField.side;
    local pet_id = entity.MagicField.pet_id;
    if not cfg then return end

    local effectName = nil;
    local sleep_time = 0;
    if entity.MagicField.index == 1 and cfg.stage_effect_1 ~= '0' then
        effectName = cfg.stage_effect_1
        sleep_time = cfg.sleep_1
    elseif entity.MagicField.index == 2 and cfg.stage_effect_2 ~= '0' then
        effectName = cfg.stage_effect_2
        sleep_time = cfg.sleep_2
    end

    if not effectName then
        return
    end

    if effectName == "UI/fx_zhaohuanwu" and side == 2 then
        effectName = "UI/fx_zhaohuanwu_di"
    end

    local hit_time = game:GetTime(entity.MagicField.duration - game.tick);

    local scale    = 1;
    local rotation = 0;

    loadAsync(effectName, function(prefab)
        if prefab == nil then return end;
        if hit_time <= game:GetTime() then return end;

        local o = nil;

        if prefab.tag == "camera_skill_effect" then
            ShowUI(false)
            o = UnityEngine.GameObject.Instantiate(prefab, cameraEffectSlot);
            game:CallAt(game:GetTick(sleep_time), function()
                ShowUI(true);
            end, entity.uuid);      
        elseif side == 1 then
            o = UnityEngine.GameObject.Instantiate(prefab, root.view.battle.StageEffectSlot.gameObject.transform)
        elseif side == 2 then
            o = UnityEngine.GameObject.Instantiate(prefab, root.view.battle.StageEffectSlot2.gameObject.transform)
        end

        if prefab.tag == "spine_effect" then
            local objects = o.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation), true)
            objects[0].AnimationState:SetAnimation(0 , "ruchang", false)
            objects[0].AnimationState:AddAnimation(0 , "idle", true, 0)
        end

        if pet_id and pet_id ~= 0 then
            local objects = o.transform:GetComponentsInChildren(typeof(Spine.Unity.SkeletonAnimation), true)
            for i = 1, objects.Length do
                if objects[i-1].gameObject.tag == "big_skill" then
                    CS.SkeletonAnimationAnchoredPosition.Attach(objects[i-1], "root");
                    objects[i-1]:UpdateSkeletonAnimation(string.format("roles/%s/%s_SkeletonData", pet_id, pet_id), {"idle"})
                end
            end
        end

        o.transform.localPosition = UnityEngine.Vector3.zero;
--[[
        findSpine(o, cfg);
        findText(o, cfg);
        findMode(o, cfg);
        findHalo(o, cfg);
--]]
        o.transform.localScale = Vector3.one * scale;
        -- if cfg.opposite then o.transform.localScale = Vector3(1, 1, -1) * scale end
        o.transform.localRotation = Quaternion.Euler(0, 0, rotation);

        UnityEngine.GameObject.Destroy(o, hit_time - game:GetTime());
--[[
        if cfg.click_skip then
            self.current_long_time_effect = o
            self.view.battle.PersistenceCanvas.EffectSkipMask:SetActive(true)
            self:CallAfter(duration, function ()
                self.view.battle.PersistenceCanvas.EffectSkipMask:SetActive(false)
                self.current_long_time_effect = nil
            end)
        end
        
        self.gameObjectPool:Release(o, duration);
--]]
    end);
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "ENTITY_ADD" then
        if root.speedUp then return end
        local entity = select(2, ...)
        if entity and entity.MagicField then
            showStageEffect(entity);
        end
    end
end

function Start()
    local list = game:FindAllEntityWithComponent("MagicField")
    for _, v in ipairs(list) do
        showStageEffect(v);
    end
end
