local fightModule = require "module.fightModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local battle = require "config.battle"

local goCheckpoint = {}

function goCheckpoint:Start(data)
    DispatchEvent("LOCAL_SELECTMAP_PUSH_GOCHECKPOINT")
    self:initData(data)
    self:initUi()
end

function goCheckpoint:initData(data)
    if data == nil or data.gid == nil then
        data = {}
        data.gid = self.savedValues.checkPoint or 10010101
    end
    self.gid = data.gid
    self.savedValues.checkPoint = self.gid
    self:upData()
    print(self.chapterCfg.name)
end

function goCheckpoint:upData()
    self.pveCfg = fightModule.GetConfig(nil, nil, self.gid)
    self.fightInfo = fightModule.GetFightInfo(self.gid)
    self.battleCfg = fightModule.GetConfig(nil, self.pveCfg.battle_id, nil)
    self.chapterCfg = fightModule.GetConfig(self.battleCfg.chapter_id)
end

function goCheckpoint:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:initDesc()
    self:initMiddle()
    self:initEnemys()
    self:initBottom()
    self:initStarLab()
    self:upBottom()
end

function goCheckpoint:initTop()
    self.bossNodeBase = CS.UnityEngine.GameObject.Find("goCheBossNode")
    if self.bossNodeBase == nil then
        self.bossNodeBase = UnityEngine.GameObject("goCheBossNode")
    end
    self:initBoss()
end

function goCheckpoint:OnDestroy()
    if self.bossNodeBase then
        UnityEngine.GameObject.Destroy(self.bossNodeBase.gameObject)
    end
    if self.topDesc then
        UnityEngine.GameObject.Destroy(self.view.goCheckpointRoot.top.topDesc.gameObject)
    end
end

function goCheckpoint:initBoss()
    local _go = UnityEngine.GameObject("boss")
    _go.transform.parent = self.bossNodeBase.gameObject.transform
    _go.transform.localScale = Vector3.one * (self.battleCfg.scale*1.8)
    _go.transform.localPosition = _go.transform.localPosition - Vector3(2, 2, 0)


    local _boss = _go:AddComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
    --_go:GetComponent(typeof(UnityEngine.MeshRenderer)).sortingOrder = 1

    SGK.ResourcesManager.LoadAsync(_boss, "roles/"..self.battleCfg.mode_id.."/"..self.battleCfg.mode_id.."_SkeletonData.asset", function(o)
        _boss.skeletonDataAsset = o;
        _boss:Initialize(true)
        _boss.state:SetAnimation(0,"idle",true)
    end)
end

function goCheckpoint:Update()
    if self.desc then
        local p = self.desc.gameObject.transform.localPosition
        local _p = self.desc.gameObject:GetComponent(typeof(UnityEngine.RectTransform)).sizeDelta
        if p.x < (-(UnityEngine.Screen.width/2 + _p[0]))  then
            self.desc.gameObject.transform.localPosition = Vector3(445, 278, 0)
        else
            self.desc.gameObject.transform.localPosition = self.desc.gameObject.transform.localPosition + Vector3(-1 * 100 * UnityEngine.Time.deltaTime, 0, 0) 
        end

        local _tp = self.topDesc.gameObject.transform.localPosition
        local _tpp = self.topDesc.gameObject:GetComponent(typeof(UnityEngine.RectTransform)).sizeDelta
        if _tp.x < (-(UnityEngine.Screen.width/2 + _tpp[0])) then
            self.topDesc.gameObject.transform.localPosition = Vector3(445, 485, 0)
        else
            self.topDesc.gameObject.transform.localPosition = self.topDesc.gameObject.transform.localPosition + Vector3(-1 * 130 * UnityEngine.Time.deltaTime, 0, 0) 
        end
    end
end

function goCheckpoint:initDesc()
    self.desc = self.view.goCheckpointRoot.bottom.descNode.desc
    self.desc[UI.Text].text = self.battleCfg.desc

    self.topDesc = self.view.goCheckpointRoot.top.topDesc.desc
    self.topDesc[UI.Text].text = self.chapterCfg.name.." "..self.battleCfg.desc
end

function goCheckpoint:initEnemys()
    self.enemys = self.view.goCheckpointRoot.bottom.enemyList.enemys
    local _enemy = fightModule.GetWaveConfig(self.gid)
    local _enemysItem = SGK.ResourcesManager.Load("prefabs/selectMap/enemys/enemysItem.asset")
    --local _iconItem = SGK.ResourcesManager.Load("prefabs/selectMap/enemys/iconItem")
    for k,v in pairs(_enemy) do
        local _obj = CS.UnityEngine.GameObject.Instantiate(_enemysItem, self.enemys.gameObject.transform)
        local _view = CS.SGK.UIReference.Setup(_obj)
        _view.numberBg.number[UI.Text].text = tostring(k)
        local _scrollView = _view.ScrollView[CS.UIMultiScroller]
        _scrollView.RefreshIconCallback = function ( obj, idx )
            local _view = CS.SGK.UIReference.Setup(obj)
            local _tab = v[idx+1]
            _view.icon[UI.Image]:LoadSprite("icon/"..battle.LoadNPC(_tab.role_id, _tab.role_lev).icon)
            obj.gameObject:SetActive(true)
        end
        _scrollView.DataCount = #v
        -- for i,p in pairs(v) do
        --     if p.role_id and p.role_lev then
        --         local _iconObj = CS.UnityEngine.GameObject.Instantiate(_iconItem, _view.list.gameObject.transform)
        --         local _iconView = CS.SGK.UIReference.Setup(_iconObj)
        --         local _icon = _iconView.icon[UI.Image]
        --         _icon:LoadSprite("icon/"..battle.LoadNPC(p.role_id, p.role_lev).icon)
        --     end
        -- end
    end
end

function goCheckpoint:initRewardList()
    local _list = fightModule.GetDropConfig(self.gid)
    if _list then
        local _rewardItem = SGK.ResourcesManager.Load("prefabs/base/ItemIcon.prefab")
        for i = 1, 6 do
            if _list["drop"..i.."_id"] ~= nil and _list["drop"..i.."_id"] ~= 0 then
                local obj = CS.UnityEngine.GameObject.Instantiate(_rewardItem, self.rewardList.gameObject.transform)
                obj.gameObject.transform.localScale = Vector3(0.5, 0.5, 0.5)
                local _item = ItemHelper.Get(_list["drop"..i.."_type"], _list["drop"..i.."_id"], nil, 0)
                obj:GetComponent(typeof(SGK.ItemIcon)):SetInfo(_item)
                obj.gameObject:SetActive(true)
            end
        end
    end
end

function goCheckpoint:initMiddle()
    self.mySquadBtn = self.view.goCheckpointRoot.middle.mySquad[UI.Button].onClick
    self.mySquadBtn:RemoveAllListeners()
    self.mySquadBtn:AddListener(function()
        DialogStack.Push("FormationDialog", {fromSelectMap = true}, "stage_item")
        DispatchEvent("LOCAL_SELECTMAP_UPSH_FORMATION")
    end)
end

function goCheckpoint:initBottom()
    self.rewardList = self.view.goCheckpointRoot.bottom.rewardList
    self.rewardNumb = self.view.goCheckpointRoot.bottom.rewardNumb[UI.Text]
    self:initRewardList()
    self:initBottomBtn()
    self:initBuff()
end

function goCheckpoint:upBottom()
    self.rewardNumb.text = (self.pveCfg.count_per_day - self.fightInfo.today_count).."/"..self.pveCfg.count_per_day
end

function goCheckpoint:initBuff()
    self.buffItem = self.view.goCheckpointRoot.bottom.buff
    for i=1,2 do
        if self.pveCfg["buff"..i] then

        end
    end 
end

function goCheckpoint:initStarTab()
    self.starTab = {}
    table.insert(self.starTab, {key = 1, value = {0, 0}}) --第一条固定key为1
    for i = 1, 2 do
        local _key = self.pveCfg["star"..i.."_type"]
        local _value = {}
        for j = 1, 2 do
            table.insert(_value, self.pveCfg["star"..i.."_para"..j])
        end
        table.insert(self.starTab, {key = _key, value = _value})
    end
end

function goCheckpoint:getDecText(key, value1, value2)
    local _value1 = value1
    local _value2 = value2
    if key == 6 then    ---技能
        if value1 ~= 0 then
            _value1 = fightModule.GetDecCfgType(tonumber(value1))
        end
    elseif key == 7 or key == 8 then ---怪物
        if value1 ~= 0 then
            _value1 = battle.LoadNPC(_value1).name
        end
        if key ~= 8 then
            if value2 ~= 0 then
                _value2 = battle.LoadNPC(value2).name
            end
        end
    end
    return string.format(fightModule.GetStarDec(key), _value1, _value2)
end


function goCheckpoint:initStarLab()
    self:initStarTab()
    for i = 1 ,3 do
        local _view = self.view.goCheckpointRoot.top.starNode.allLab[i]
        _view.Text[UI.Text].text = self:getDecText(self.starTab[i].key, self.starTab[i].value[1], self.starTab[i].value[2])
        if fightModule.GetOpenStar(self.fightInfo.star, i) == 0 then
            _view.Text[UI.Text].color = UnityEngine.Color.white
            _view.icon[UI.Image]:LoadSprite("icon/fuben_05")
        else
            _view.Text[UI.Text].color = UnityEngine.Color.yellow
            _view.icon[UI.Image]:LoadSprite("icon/fuben_06")
        end
    end
end

function goCheckpoint:initBottomBtn()
    self.challNumb = self.view.goCheckpointRoot.bottom.challenge.numb[UI.Text]
    self.challNumb.text = tostring(self.pveCfg.cost_item_value)
    self.challenge = self.view.goCheckpointRoot.bottom.challenge[UI.Button].onClick
    self.challenge:RemoveAllListeners()
    self.challenge:AddListener(function()
        if self.pveCfg.cost_item_value > ItemModule.GetItemCount(90010) then
            showDlgError(self.view, "时之力不足")
            return
        end
        if self.pveCfg.count_per_day - self.fightInfo.today_count <= 0 then
            showDlgError(self.view, "挑战次数不足")
            return
        end
        fightModule.StartFight(self.gid)
        DialogStack.Pop()
    end)

    self.sweeping = self.view.goCheckpointRoot.bottom.sweeping[UI.Button].onClick
    self.sweeping:RemoveAllListeners()
    self.sweeping:AddListener(function ()
        if fightModule.GetOpenStar(self.fightInfo.star, 1) ~= 0 then
            DialogStack.PushPrefStact("selectMap/sweeping", {gid = self.gid})
        else
            showDlgError(self.view, "未通关无法扫荡")
        end
    end)
end

function goCheckpoint:listEvent()
    return {
        "FIGHT_INFO_CHANGE",
    }
end

function goCheckpoint:onEvent(event, ...)
    if event == "FIGHT_INFO_CHANGE" then
        self:upData()
        self:upBottom()
    end
end

return goCheckpoint