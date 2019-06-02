local viewRoot = nil
local last_update_time = nil
local uuidIdx = 0
local randomPosList = {}
local userPosList = {}
local buffList = {}
local randomBuffCfg = require"config.battle"

function Preload()

end

function Start()
    viewRoot = root.view.battle.Canvas.UIRootTop
    local _randomPosList = randomBuffCfg.GetInteractBuffPosList()
    for i,v in ipairs(_randomPosList) do
        table.insert(randomPosList, v)
    end
end

local function removeBuffBase(idx)
    local _cfg = buffList[tostring(idx)]
    if _cfg then
        CS.UnityEngine.GameObject.Destroy(_cfg.obj.gameObject)
        if userPosList[_cfg.idx] then
            table.insert(randomPosList, userPosList[_cfg.idx])
            userPosList[_cfg.idx] = nil
        end
        buffList[tostring(_cfg.idx)] = nil
    end
end

local function useBuffer(buffCfg, hero)
    if buffCfg then
        DispatchEvent("ON_RANDOM_BUFF_CLICK", buffCfg.cfg.id, hero)
        removeBuffBase(buffCfg.idx)
    end
end

local function removeBuff(hero)
    if hero then
        for k,v in pairs(buffList) do
            if v and v.uuid then
                if v.uuid == hero.uuid then
                    removeBuffBase(k)
                    break
                end
            end
        end
    end
end

local function addTargetEff(view, list)
    for i,v in ipairs(list or {}) do
        local _info = root.roles[v.uuid]
        local _pos = Vector3.zero
        local _buffName = ""
        if v.side == 2 then
            _pos = UnityEngine.Camera.main:WorldToScreenPoint(_info.script:GetPosition("hitpoint") or Vector3.zero)
            _buffName = "prefabs/effect/UI/fx_r_buff_lizi.prefab"
        elseif v.side == 1 then
            _pos = _info.script.icon.image.transform.position
            _buffName = "prefabs/effect/UI/fx_r_buff_icon_ready.prefab"
        end
        LoadAsync(_buffName, function(o)
            if o then
                local _obj = SGK.UIReference.Instantiate(o, view.targeteffectRoot.transform)
                _obj.transform.position = _pos
            end
        end)
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

local function calculateCollision(view, buffCfg)
    for i,v in ipairs(buffCfg.list or {}) do
        local _info = root.roles[v.uuid]
        if _info then
            if v.side == 2 then
                if isCollision(view.bg, UnityEngine.Camera.main:WorldToScreenPoint(_info.script:GetPosition("hitpoint") or Vector3.zero)) then
                    return true, v
                end
            elseif v.side == 1 then
                if isCollision(view.bg, _info.script.icon.image.transform.position) then
                    return true, v
                end
            end
        end
    end
    return false
end

local function ListenPointer(buffView, idx)
    view = buffView.root
    CS.UGUIPointerEventListener.Get(view.gameObject).onPointerDown = function()
        if buffList[tostring(idx)]  then
            if not buffList[tostring(idx)].moveEffect then
                LoadAsync("prefabs/effect/UI/fx_r_buff_btn_run.prefab", function(o)
                    if o then
                        local _obj = SGK.UIReference.Instantiate(o, view.bg.transform)
                        buffList[tostring(idx)].moveEffect = _obj
                    end
                end)
            else
                buffList[tostring(idx)].moveEffect.gameObject:SetActive(true)
            end
            buffList[tostring(idx)].startPoint = view.transform.localPosition
        end
        buffView.targeteffectRoot:SetActive(true)
    end
    CS.UGUIPointerEventListener.Get(view.gameObject).onDrag2 = function(obj, delta, pos)
        view.gameObject.transform.localPosition = (view.gameObject.transform.localPosition + Vector3(delta.x, delta.y, 0))
    end
    CS.UGUIPointerEventListener.Get(view.gameObject).onPointerUp = function()
        if buffList[tostring(idx)]  then
            if buffList[tostring(idx)].moveEffect then
                buffList[tostring(idx)].moveEffect.gameObject:SetActive(false)
            end
            local _status, _hero = calculateCollision(view, buffList[tostring(idx)])
            if _status and _hero then
                useBuffer(buffList[tostring(idx)], _hero)
            else
                if buffList[tostring(idx)].startPoint then
                    view.transform.localPosition = buffList[tostring(idx)].startPoint
                end
            end
        end
        buffView.targeteffectRoot:SetActive(false)
    end
end

local function getHeroPos(hero)
    local _pos = Vector3.zero
    local _info = root.roles[hero.uuid]
    if hero.side == 2 then
        _pos = UnityEngine.Camera.main:WorldToScreenPoint(_info.script:GetPosition("hitpoint") or Vector3.zero)
    elseif hero.side == 1 then
        _pos = _info.script.icon.image.transform.position
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

local function initBuff(view, buffCfg, hero, list)
    local _tempTab = {}
    uuidIdx = uuidIdx + 1
    local _idx = uuidIdx
    _tempTab.idx = _idx
    _tempTab.list = list
    if buffCfg.type == 0 then
        view.root.transform.localPosition = GetRandomPos(_idx)
        view.root.icon.timing:SetActive(buffCfg.lastingtype == 2)
        view.root.icon.round:SetActive(buffCfg.lastingtype == 1)
        view.root.icon[UI.Image]:LoadSprite("icon/"..buffCfg.icon)
        if buffCfg.lastingtype == 2 then
            _tempTab.value = module.Time.now()
            _tempTab.textObj = view.root.icon.timing
        elseif buffCfg.lastingtype == 1 then
            _tempTab.value = game.timeline.total_round
            _tempTab.textObj = view.root.icon.round.count
        end
        if buffCfg.canmove == 1 then
            addTargetEff(view, list)
            ListenPointer(view, _idx)
        else
            CS.UGUIClickEventListener.Get(view.root.icon.gameObject).onClick = function()
                LoadAsync("prefabs/effect/UI/fx_r_buff_lizi_hit.prefab", function(o)
                    if o then
                        for k,v in pairs(list) do
                            local _obj = SGK.UIReference.Instantiate(o, view.root.bg.transform)
                            _obj.transform:DOMove(getHeroPos(v), 0.3):OnComplete(function()
                                useBuffer(buffList[tostring(_idx)], v)
                            end)
                        end
                    else
                        for k,v in pairs(list) do
                            useBuffer(buffList[tostring(_idx)], v)
                        end
                    end
                end)
            end
        end
        LoadAsync("prefabs/effect/UI/fx_r_buff_btn_idle.prefab", function(o)
            if o then
                local _obj = SGK.UIReference.Instantiate(o, view.root.bg.transform)
            end
        end)
    elseif buffCfg.type == 1 then
        view.timing:SetActive(buffCfg.lastingtype == 2)
        view.round:SetActive(buffCfg.lastingtype == 1)
        local _info = root.roles[hero.uuid]
        view.transform.position = UnityEngine.Camera.main:WorldToScreenPoint(_info.script:GetPosition("hitpoint") or Vector3.zero)
        view.right.info[UI.Text].text = buffCfg.des
        view.left.info[UI.Text].text = buffCfg.des
        view.icon[UI.Image]:LoadSprite("icon/"..buffCfg.icon)
        CS.UGUIClickEventListener.Get(view.icon.gameObject).onClick = function()
            if view.transform.position.x < UnityEngine.Screen.width / 2 then
                view.right:SetActive(not view.right.activeSelf)
            else
                view.left:SetActive(not view.left.activeSelf)
            end
        end
        if buffCfg.lastingtype == 2 then
            _tempTab.value = module.Time.now()
            _tempTab.textObj = view.timing
        elseif buffCfg.lastingtype == 1 then
            _tempTab.value = game.timeline.total_round
            _tempTab.textObj = view.round.count
        end
        _tempTab.uuid = hero.uuid
        CS.UGUIClickEventListener.Get(view.right.getBtn.gameObject).onClick = function()
            useBuffer(buffList[tostring(_idx)], hero)
        end
        CS.UGUIClickEventListener.Get(view.left.getBtn.gameObject).onClick = function()
            useBuffer(buffList[tostring(_idx)], hero)
        end
    end
    _tempTab.cfg = buffCfg
    _tempTab.obj = view
    buffList[tostring(_idx)] = _tempTab
end

local function createBuff(buffId, hero, list)
    if viewRoot then
        local _cfg = randomBuffCfg.LoadInteractBuff(buffId)
        if not _cfg then
            return
        end
        local _prefab = "prefabs/battlefield/randomBuffItem.prefab"
        if _cfg.type == 1 then
            _prefab = "prefabs/battlefield/randomHeroBuffItem.prefab"
        end
        LoadAsync(_prefab, function(o)
            if o then
                local _obj = SGK.UIReference.Instantiate(o, viewRoot.transform)
                local _view = CS.SGK.UIReference.Setup(_obj.gameObject)
                initBuff(_view, _cfg, hero, list)
            end
        end)
    end
end

local function upBuffTime()
    for k,v in pairs(buffList) do
        if v then
            local _count = 0
            if v.cfg.lastingtype == 1 then
                _count = (v.value + v.cfg.value) - game.timeline.total_round
            elseif v.cfg.lastingtype == 2 then
                _count = (v.value + v.cfg.value) - module.Time.now()
            end
            if _count < 0 then
                CS.UnityEngine.GameObject.Destroy(v.obj.gameObject)
                buffList[k] = nil
            else
                if v.cfg.lastingtype == 1 then
                    v.textObj[UI.Text].text = tostring(_count)
                elseif v.cfg.lastingtype == 2 then
                    v.textObj[UI.Text].text = GetTimeFormat(_count, 2, 2)
                end
            end
        end
    end
end

function Update()
    local now = math.floor(UnityEngine.Time.timeSinceLevelLoad)
    if last_update_time == now then
        return
    end
    last_update_time = now
    upBuffTime()
end

function EVENT.ShowRandomBuff(event, ...)
    createBuff(...)
end

function EVENT.UNIT_DEAD(event, info)
    removeBuff(info)
end

function EVENT.UNIT_Hurt(...)

end
