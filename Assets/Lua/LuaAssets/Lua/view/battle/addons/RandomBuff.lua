local viewRoot = nil
local last_update_time = nil
local randomPosList = {}
local userPosList = {}
local buffList = {}
local ItemBoxPanel = nil

local randomBuffCfg = require"config.battle"

local RandomBuffSystem = require "battlefield2.system.RandomBuff"

local random_buff_slots = {

}

function Preload()
    local obj = Load("prefabs/battlefield/RandomBuffSlots.prefab");
    random_buff_slots.view = SGK.UIReference.Instantiate(obj, root.view.battle.transform);
    local n = #random_buff_slots.view;

    random_buff_slots.slots = {}

    for i = 1, n do
        table.insert(random_buff_slots.slots, i)
    end
end

local function GetRandomBuffSlot(uuid)
    if not random_buff_slots.slots then return end;

    local n = #random_buff_slots.slots;
    if n == 0 then
        return;
    end

    --引导 固定出现位置
    if game.round_info.fight_id == 10100201 then
        return random_buff_slots.view[1].transform, 1;
    end

    local sel = uuid % n + 1;

    local pos = random_buff_slots.slots[sel];
    table.remove(random_buff_slots.slots, sel)

    return random_buff_slots.view[pos].transform, pos;
end

local function ReleaseRandomBuffSlot(n)
    if random_buff_slots.slots then
        table.insert(random_buff_slots.slots, n);
    end
end


function Start()
    viewRoot = root.view.battle.Canvas.UIRootTop
    local _randomPosList = randomBuffCfg.GetInteractBuffPosList()
    for i,v in ipairs(_randomPosList) do
        table.insert(randomPosList, v)
    end
end

local function removeBuff(uuid)
    local _cfg = buffList[uuid]
    if not _cfg then
        -- print('uuid not exists', uuid);
        return
    end

    -- print('REMOVE', uuid);

    buffList[uuid] = nil

    if _cfg.obj then
        CS.UnityEngine.GameObject.Destroy(_cfg.obj)
    end

    if _cfg.random_pos then
        ReleaseRandomBuffSlot(_cfg.random_pos);
    end

    if userPosList[_cfg.uuid] then
        table.insert(randomPosList, userPosList[_cfg.uuid])
        userPosList[_cfg.uuid] = nil
    end
end

local function useBuffer(uuid, target)
    if buffList[uuid] then
        print('USE BUFF', uuid, target);

        if root.args.remote_server then
            SendPlayerCommand(uuid, 98001, target);
        else
            local game = root.server or root.game;
            RandomBuffSystem.Cast(game, uuid, target, {pid = root.pid});
        end
    end
end

local targetEffectList = {}
local function addTargetEff(view, list)
    local currentMap = {}
    for i,v in ipairs(list or {}) do
        currentMap[v.uuid] = true;
        if not targetEffectList[v.uuid] then
            local script = GetBattlefiledObject(v.uuid)
            local _pos = Vector3.zero
            local _buffName = ""
            if v.side == 2 then
                _pos = UnityEngine.Camera.main:WorldToScreenPoint(script:GetPosition("hitpoint") or Vector3.zero)
                _buffName = "prefabs/effect/UI/fx_r_buff_lizi.prefab"
            elseif v.side == 1 then
                _pos = script.icon.image.transform.position
                _buffName = "prefabs/effect/UI/fx_r_buff_icon_ready.prefab"
            end
            LoadAsync(_buffName, function(o)
                if o then
                    local _obj = SGK.UIReference.Instantiate(o, view.targeteffectRoot.transform)
                    _obj.transform.position = _pos
                    targetEffectList[v.uuid] = _obj;
                end
            end)
        end
    end

    for uuid, o in pairs(targetEffectList) do
        if not currentMap[uuid] then
            CS.UnityEngine.GameObject.Destroy(o.gameObject);
            targetEffectList[uuid] = nil;
        end
    end

    view.targeteffectRoot:SetActive(false)
end

local function isCollision(view, pos)
    local _canvas = viewRoot.transform:GetComponentInParent(typeof(UnityEngine.Canvas))
    if CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(view:GetComponent(typeof(UnityEngine.RectTransform)), UnityEngine.Vector2(pos.x, pos.y), _canvas.worldCamer) then
        return true
    end
    return false
end

local function calculateCollision(view, target_list)
    for i,v in ipairs(target_list) do
        local _info = GetBattlefiledObject(v.uuid)
        if _info then
            if v.Force.side == 2 then
                if isCollision(view.bg, UnityEngine.Camera.main:WorldToScreenPoint(_info:GetPosition("hitpoint") or Vector3.zero)) then
                    print('isCollision', v.uuid);
                    return true, v
                end
            elseif v.side == 1 then
                if isCollision(view.bg, _info.icon.image.transform.position) then
                    return true, v
                end
            end
        end
    end
    return false
end

local function ListenPointer(buffView, uuid, target_list)
    view = buffView.root
    CS.UGUIPointerEventListener.Get(view.gameObject).onPointerDown = function()
        if buffList[uuid] then
            if root.remote_server then
                local entity = game:GetEntity(uuid)
                if entity and entity.RandomBuff.holder == 0 then
                    SendPlayerCommand(uuid, 98002, 1);
                end
            end

            buffList[uuid].downTime = module.Time.now()
            if not buffList[uuid].moveEffect then
                LoadAsync("prefabs/effect/UI/fx_r_buff_btn_run.prefab", function(o)
                    if o then
                        local _obj = SGK.UIReference.Instantiate(o, view.bg.transform)
                        buffList[uuid].moveEffect = _obj
                    end
                end)
            else
                buffList[uuid].moveEffect.gameObject:SetActive(true)
            end
            buffList[uuid].startPoint = view.transform.localPosition
        end
        buffView.targeteffectRoot:SetActive(true)
    end

    CS.UGUIPointerEventListener.Get(view.gameObject).onDrag2 = function(obj, delta, pos)
        view.gameObject.transform.localPosition = (view.gameObject.transform.localPosition + Vector3(delta.x, delta.y, 0))
    end

    CS.UGUIPointerEventListener.Get(view.gameObject).onPointerUp = function()
        if buffList[uuid] then
            if root.remote_server then
                local entity = game:GetEntity(uuid)
                if entity and entity.RandomBuff.holder == 0 then
                    SendPlayerCommand(uuid, 98002, 0);
                end
            end
            
            buffList[uuid].downTime = 0
            buffList[uuid].view.root.buffInfoRoot.buffInfo[UnityEngine.CanvasGroup].alpha = 0
            if buffList[uuid].moveEffect then
                buffList[uuid].moveEffect.gameObject:SetActive(false)
            end
            local _status, _hero = calculateCollision(view, target_list)
            if _status and _hero then
                useBuffer(uuid, _hero.uuid)
            else
                if buffList[uuid].startPoint then
                    view.transform.localPosition = buffList[uuid].startPoint
                end
            end
        end
        buffView.targeteffectRoot:SetActive(false)
    end
end

local function getHeroPos(hero)
    local _pos = Vector3.zero

    local script = GetBattlefiledObject(hero.uuid);
    if hero.Force.side == 2 then
        _pos = UnityEngine.Camera.main:WorldToScreenPoint(script:GetPosition("hitpoint") or Vector3.zero)
    elseif hero.Force.side == 1 then
        _pos = script.icon.image.transform.position
    end
    return _pos
end

local function GetRandomPos(uuid)
    if not (#randomPosList > 1) then
        return Vector3.zero
    end
    local _idx = math.random(1, #randomPosList)
    local _pos = randomPosList[_idx]
    if _pos then
        userPosList[uuid] = _pos
        table.remove(randomPosList, _idx)
        return Vector3(UnityEngine.Screen.width / 2 * _pos.x, UnityEngine.Screen.height / 2 * _pos.y, _pos.z)
    else
        return Vector3.zero
    end
end

local ItemBoxPanel_loading = nil
local function ShowDetails(buff_uuid)
    if ItemBoxPanel_loading then
        return
    end

    if not ItemBoxPanel then
        ItemBoxPanel_loading = true
        LoadAsync("prefabs/battlefield/ItemBoxPanel.prefab", function(o)
            if not o then return; end;
            ItemBoxPanel = CS.SGK.UIReference.Setup(SGK.UIReference.Instantiate(o, root.view.battle.PersistenceCanvas.transform))
            ItemBoxPanel_loading = nil        
       
            CS.UGUIClickEventListener.Get(ItemBoxPanel.itembox_detail.btn.gameObject).onClick = function()
                useBuffer(buff_uuid)
                ItemBoxPanel:SetActive(false)
            end
        
            local info = buffList[buff_uuid];
            local pos = UnityEngine.Camera.main:WorldToScreenPoint(info.obj.transform.position)
            pos.y = pos.y + 80
            ItemBoxPanel.itembox_detail.transform.position = pos
            ItemBoxPanel.itembox_detail.Text[UI.Text].text = info.cfg.des

            ItemBoxPanel:SetActive(true)
            ItemBoxPanel.itembox_detail.transform.localScale = Vector3(1, 0.1, 1)
            ItemBoxPanel.itembox_detail.transform:DOScale(Vector3.one, 0.2)
        end)
    else
        CS.UGUIClickEventListener.Get(ItemBoxPanel.itembox_detail.btn.gameObject).onClick = function()
            useBuffer(buff_uuid)
            ItemBoxPanel:SetActive(false)
        end

        local info = buffList[buff_uuid];
        local pos = UnityEngine.Camera.main:WorldToScreenPoint(info.obj.transform.position)
        pos.y = pos.y + 80
        ItemBoxPanel.itembox_detail.transform.position = pos
        ItemBoxPanel.itembox_detail.Text[UI.Text].text = info.cfg.des
        
        ItemBoxPanel:SetActive(true)
        ItemBoxPanel.itembox_detail.transform.localScale = Vector3(1, 0.1, 1)
        ItemBoxPanel.itembox_detail.transform:DOScale(Vector3.one, 0.2)
    end
end

local function createFloatButton(entity, buffCfg) -- view, buffCfg, entity, target)
    local buff_uuid = entity.uuid;

    local info = {}

    buffList[buff_uuid] = info;
    info.cfg = buffCfg;

    local prefabName = buffCfg.prefab
    if prefabName == "" or prefabName == nil or prefabName == '0' or prefabName == 0 then
        prefabName = "buffitem_box";
    end

    LoadAsync("prefabs/effect/" .. prefabName .. ".prefab", function(o)
        if not o then return; end;

        local parent, pos = GetRandomBuffSlot(entity.uuid)
        if not parent then
            return;
        end

        info.view = SGK.UIReference.Instantiate(o, parent);

        info.obj = info.view.gameObject;
        info.random_pos = pos;

        info.time_text = info.view.gameObject:GetComponentInChildren(typeof(UnityEngine.UI.Text))

        CS.ModelTouchEventListener.Get(info.view.gameObject).onTouchEnd = function()
            ShowDetails(buff_uuid);
            --useBuffer(buff_uuid);
        end
    end)
end

local function createFollowButton(entity, buffCfg)
    local target_uuid = entity.RandomBuff.creater
    local target = GetBattlefiledObject(target_uuid or 0);
    if not target then
        print('buff target not exists', target_uuid);
        return;
    end

    local buff_uuid = entity.uuid;

    local info = {}

    buffList[buff_uuid] = info;
    info.cfg = buffCfg;

    local prefabName = buffCfg.prefab
    if prefabName == "" or prefabName == nil or prefabName == '' then
        prefabName = "buffitem_box";
    end

    LoadAsync("prefabs/effect/" .. prefabName .. ".prefab", function(o)
        if not o then return; end;

        local parent, pos = GetRandomBuffSlot(entity.uuid)
        if not parent then
            return;
        end

        info.view = SGK.UIReference.Instantiate(o, parent);

        info.obj = info.view.gameObject;
        info.random_pos = pos;

        info.time_text = info.view.gameObject:GetComponentInChildren(typeof(UnityEngine.UI.Text))

        CS.ModelTouchEventListener.Get(info.view.gameObject).onTouchEnd = function()
            ShowDetails(buff_uuid);
            --useBuffer(buff_uuid);
        end
    end)
end

--[[
local function createFloatButtonWithChooseTarget(entity, buffCfg)
    local info = {}

    local buff_uuid = entity.uuid;
    buffList[buff_uuid] = info;

    LoadAsync("prefabs/battlefield/randomBuffItem.prefab", function(o)
        if not o then return end

        local view = SGK.UIReference.Instantiate(o, viewRoot.transform)
        info.obj = view.gameObject;
        
        view.root.transform.localPosition = GetRandomPos(entity.uuid)

        info.cfg  = buffCfg;
        info.uuid = entity.uuid
        info.obj  = view.gameObject;
        info.view = view;
        info.value = game:GetTime() + buffCfg.value;

        local list = entity.Skill.script[1].check:Call(root.pid) or {};
        local _list = {}
        for _, v in ipairs(list) do
            table.insert(_list, v.target)
        end
    
        addTargetEff(view, _list)
        ListenPointer(view, buff_uuid, _list)
        view.root.buffInfoRoot.buffInfo.Text[UI.Text].text = buffCfg.des
        view.root.icon[UI.Image]:LoadSprite("icon/"..buffCfg.icon)
        view.root.moveLable:SetActive(true)

        info.textObj = view.root.icon.timing[UnityEngine.UI.Text];
    end)
end

local function initBuff(view, buffCfg, entity, target) -- target_uuid, list)
    local _tempTab = {}
    view.root.transform.localPosition = GetRandomPos(entity.uuid)
    if buffCfg.type == 0 then
        _tempTab.textObj = createFloatButton(view, buffCfg, entity, target);
    elseif buffCfg.type == 1 then
        _tempTab.textObj = createFollowButton(view, buffCfg, entity, target)
    elseif buffCfg.type == 2 then
        _tempTab.textObj = createFloatButtonWithChooseTarget(view, buffCfg, entity, target)
    end

    _tempTab.uuid = entity.uuid
    _tempTab.cfg  = buffCfg
    _tempTab.obj  = view

    if buffCfg.lastingtype == 2 then
        _tempTab.value = game:GetTime() + buffCfg.value;
    elseif buffCfg.lastingtype == 1 then
        _tempTab.value = entity.AutoKill.lasting_round;
    end

    buffList[entity.uuid] = _tempTab
end
--]]

local function createBuff(entity)
    if not viewRoot then return end

    local buffId = entity.Skill.ids[1];

    local _cfg = randomBuffCfg.LoadInteractBuff(buffId)
    if not _cfg then return end

    -- print('RANDOM BUFF', _cfg.type, buffId, entity.RandomBuff.creater);

    if _cfg.type == 0 then
        createFloatButton(entity, _cfg);
    elseif _cfg.type == 1 then
        createFollowButton(entity, _cfg)
    end
end

local function upBuffTime()
    for uuid, info in pairs(buffList) do
        if info.time_text then
            local entity = game:GetEntity(uuid)
            if not entity then return end

            if info.cfg.lastingtype == 1 then
                info.time_text.text = tostring(entity.AutoKill.lasting_round - game:GetGlobalData().round + 1) .. "回合";
            elseif info.cfg.lastingtype == 2 then
                local total = math.floor((entity.AutoKill.duration - game:GetTick())/10)
                local minute = math.floor(total/60)
                local second = total%60
                info.time_text.text = (minute < 10 and "0" or "") .. minute .. ":" .. (second < 10 and "0" or "") .. second
            end
        end
    end
end

local function showBuffInfo(uuid)
    if (not uuid) or (not buffList[uuid]) then
        return
    end
    buffList[uuid].view.root.buffInfoRoot.buffInfo[UnityEngine.CanvasGroup].alpha = 1
end

local function upBuffDescInfo()
    for i,v in pairs(buffList) do
        if (v and v.downTime) and (v.downTime ~= 0) then
            if (module.Time.now() - v.downTime) >= 1 then
                if v.obj then
                    showBuffInfo(v.uuid)
                end
            end
        end
    end
end

function Update()
    upBuffDescInfo()
    local now = math.floor(UnityEngine.Time.timeSinceLevelLoad)
    if last_update_time == now then
        return
    end
    last_update_time = now
    upBuffTime()
end

--[[
function EVENT.ShowRandomBuff(event, ...)
    createBuff(...)
end

function EVENT.UNIT_DEAD(event, info)
    removeBuff(info)
end

function EVENT.UNIT_Hurt(...)

end
--]]


local function addEntity(entity)
    if not entity.RandomBuff then return end;

    createBuff(entity) -- , nil, {})
end

local function removeEntity(uuid)
    removeBuff(uuid)
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "ENTITY_ADD" then
        if root.speedUp then return end
        local uuid, entity = ...
        addEntity(entity)
    elseif event == "ENTITY_REMOVED" then
        removeEntity(...)
    end
end

function EVENT.LOCAL_GUIDE_PASS(...)
    local event, id = ...

    if id == 7029 then
        for uuid, buff in pairs(buffList) do
            ShowDetails(uuid)
            break  
        end
    end
end
