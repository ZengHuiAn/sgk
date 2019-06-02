local heroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local activityModule = require "module.unionActivityModule"

local newUnionExplainBattle = {}

function newUnionExplainBattle:initData(data)
    self.Manage = activityModule.ExploreManage
    if data then
        self.mapId = data.mapid
        self.index = data._index
    else
        self.mapId = self.savedValues.mapId or 1
        self.index = self.savedValues.index or 1
    end
    self.savedValues.mapId = self.mapId
    self.savedValues.index = self.index
    self.selectHeroTab = {}
    self:upData()
end

function newUnionExplainBattle:upData()
    self:getHeroList()
end

function newUnionExplainBattle:canStart()
    if not self.Manage:GetTempHeroTab(self.index) then
        return false
    end
    for k,v in pairs(self.Manage:GetTempHeroTab(self.index)) do
        if v ~= 0 then
            return true
        end
    end
    return false
end

function newUnionExplainBattle:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    self:initBossNode()
    self:upBossNode()
    self:initScrollView()
    CS.UGUIClickEventListener.Get(self.view.root.startBtn.gameObject).onClick = function()
        if self:canStart() then
            self.Manage:startExplore(self.mapId, self.Manage:GetTempHeroTab(self.index), self.mapId)
            DialogStack.Pop()
        else
            showDlgError(nil, "请选择英雄")
        end
    end
    module.guideModule.PlayByType(18, 0.3)
end

function newUnionExplainBattle:initBossNode()
    self.selectHeroTab = {}
    for i,v in ipairs(self.Manage:GetTempHeroTab(self.index) or {}) do
        self.selectHeroTab[i] = v
    end
end

function newUnionExplainBattle:sendHeroTab()
    local _tab = {}
    for i = 1, 5 do
        if self.selectHeroTab[i] then
            _tab[i] = self.selectHeroTab[i]
        else
            _tab[i] = 0
        end
    end
    DispatchEvent("LOCAL_UNION_GOTO_EXPLORE", {index = self.index, tab = _tab})
end

function newUnionExplainBattle:upBossFightNumber()
    local _allCapacity = 0
    for i,v in ipairs(self.selectHeroTab) do
        if v and v ~= 0 then
            local _hero = ItemHelper.Get(ItemHelper.TYPE.HERO, v)
            _allCapacity = _hero.capacity + _allCapacity
        end
    end
    self.view.root.middle.top.fightNumber[UI.Text].text = tostring(_allCapacity)
end

function newUnionExplainBattle:upBossNode()
    for i = 1, #self.view.root.middle.top.heroNode do
        local _view = self.view.root.middle.top.heroNode[i]
        local _tempHeroTab = self.selectHeroTab
        if _tempHeroTab and _tempHeroTab[i] and _tempHeroTab[i] ~= 0 then
            local _hero = ItemHelper.Get(ItemHelper.TYPE.HERO, _tempHeroTab[i])
            local _boss = _view.boss1:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic))
            _view.boss1:SetActive(true)
            SGK.ResourcesManager.LoadAsync(_boss, "roles_small/".._hero.showMode.."/".._hero.showMode.."_SkeletonData.asset", function(o)
                if o then
                    if not _boss.skeletonDataAsset then
                        _boss.skeletonDataAsset = o
                        _boss:Initialize(true)
                        local _sprite = _view.boss1:GetComponent(typeof(SGK.DialogSprite))
                        _sprite:SetDirty()
                    end
                else
                    _boss.skeletonDataAsset = nil
                    _boss:SetActive(false)
                end
            end)
        else
            _view.boss1:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic)).skeletonDataAsset = nil
            _view.boss1:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic)).material = nil
            _view.boss1:SetActive(false)
        end
    end
    self:upBossFightNumber()
end

function newUnionExplainBattle:sendHeroTab()
    local _tab = {}
    for i = 1, 5 do
        if self.selectHeroTab[i] then
            _tab[i] = self.selectHeroTab[i]
        else
            _tab[i] = 0
        end
    end
    DispatchEvent("LOCAL_UNION_GOTO_EXPLORE", {index = self.index, tab = _tab})
end

function newUnionExplainBattle:initScrollView()
    self.ScrollView = self.view.root.bottom.ScrollView[CS.UIMultiScroller]
    self.ScrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.order_list[idx + 1]
        local _hero = ItemHelper.Get(ItemHelper.TYPE.HERO, _tab)
        utils.IconFrameHelper.Create(_view.IconFrame, {type = 42, uuid = _hero.uuid})
        _view.fightNumber[UI.Text].text = tostring(_hero.capacity)
        _view.select:SetActive(false)
        local _i = 0
        for i = 1, 5 do
            local v = self.selectHeroTab[i]
            if v == _tab then
                _i = i
                _view.select:SetActive(true)
                break
            end
        end
        CS.UGUIClickEventListener.Get(_view.gameObject, true).onClick = function()
            if _view.select.activeSelf then
                self.selectHeroTab[_i] = 0
            else
                for i = 1, 5 do
                    if self.selectHeroTab[i] == nil or self.selectHeroTab[i] == 0 then
                        self.selectHeroTab[i] = _tab
                        break
                    end
                end
            end
            self:upBossNode()
            self:sendHeroTab()
            self.ScrollView.DataCount = #self.order_list
        end
        obj:SetActive(true)
    end
    self.ScrollView.DataCount = #self.order_list
end

function newUnionExplainBattle:getTempHeroList()
    local _tab = {}
    for k,v in pairs(self.Manage:GetTempHeroTab()) do
        if k ~= self.index then
            for j,p in pairs(v) do
                _tab[p] = 1
            end
        end
    end
    return _tab
end

function newUnionExplainBattle:getHeroList()
    local list = heroModule.GetManager():GetAll()
    local _heroTab = self:getTempHeroList()
    self.order_list = {}
    for k, v in pairs(list) do
        if not self.Manage:GetHeroState(v.id) then
            if _heroTab[v.id] ~= 1 then
                table.insert(self.order_list, v.id)
            end
        end
    end
    table.sort(self.order_list)
end

function newUnionExplainBattle:Start(data)
    self:initData(data)
    self:initUi()
end

function newUnionExplainBattle:listEvent()
    return {
        "LOCAL_GUIDE_CHANE",
    }
end

function newUnionExplainBattle:onEvent(event, data)
    if event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(18, 0.3)
    end
end

function newUnionExplainBattle:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return newUnionExplainBattle
