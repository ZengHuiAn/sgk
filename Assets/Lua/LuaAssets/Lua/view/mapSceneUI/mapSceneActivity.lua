local activityConfig = require "config.activityConfig"
local heroModule = require "module.HeroModule"
local ItemHelper=require"utils.ItemHelper"

local mapSceneActivity = {}

function mapSceneActivity:Start(data)
    self:initData(data)
    self:initUi()
    self:initGuide()
end

function mapSceneActivity:initData(data)
    self.nowSelect = nil
    self.fighting = data
    self:upData()
end

function mapSceneActivity:upData()
    self.activityTab = {}
    self.nowType = {}
    for j,p in pairs(activityConfig.GetAllActivityTitle(activityConfig.TitleType.Activity, 1001)) do
        if p.lv_limit <= module.HeroModule.GetManager():Get(11000).level then
            table.insert(self.nowType, p)
        end
    end
end

function mapSceneActivity:initGuide()
    module.guideModule.PlayByType(2)
end

function mapSceneActivity:selectNow(_view)
    if self.nowSelect then
        self.nowSelect.gameObject:SetActive(false)
    end
    self.nowSelect = _view.select
    self.nowSelect.gameObject:SetActive(true)
end

function mapSceneActivity:initLeftScrollView()
    self.leftScrollView = self.view.mapSceneActivityRoot.left.ScrollView[SGK.dropdownView]
    for k,v in pairs(activityConfig.GetBaseTittleByType(activityConfig.TitleType.Activity)) do
        local _obj = self.leftScrollView:addItemMenu(k)
        local _view = CS.SGK.UIReference.Setup(_obj)
        _view.Text[UI.Text].text = v.name
        if k == 1001 then
            self:selectNow(_view)
        else
            _view.select.gameObject:SetActive(false)
        end
        CS.UGUIClickEventListener.Get(_obj.gameObject).onClick = function()
            local _tab = activityConfig.GetAllActivityTitle(activityConfig.TitleType.Activity, k)
            self.nowType = {}
            if _tab == nil then
                for k,v in pairs(activityConfig.GetAllActivityTitle(activityConfig.TitleType.Activity)) do
                    for j,p in pairs(v) do
                        if p.lv_limit > module.HeroModule.GetManager():Get(11000).level then
                            table.insert(self.nowType, p)
                        end
                    end
                end
            else
                for j,p in pairs(_tab) do
                    if p.lv_limit <= module.HeroModule.GetManager():Get(11000).level then
                        table.insert(self.nowType, p)
                    end
                end
            end
            self.scrollView.DataCount = #self.nowType
            self:selectNow(_view)
        end
    end
end

function mapSceneActivity:initTopBtn()
    CS.UGUIClickEventListener.Get(self.view.mapSceneActivityRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
end

function mapSceneActivity:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTopBtn()
    self:initBottom()
    self:initScrollView()
    self:initLeftScrollView()

    self:upUi()
end

function mapSceneActivity:initScrollView()
    self.scrollView = self.view.mapSceneActivityRoot.right.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function ( obj, idx )
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.nowType[idx+1]
        local _quest = module.QuestModule.Get(_tab.huoyuedu)
        local _active = 0
        _view.name[UI.Text].text = _tab.name
        _view.icon[UI.Image]:LoadSprite("icon/".._tab.use_icon)
        local _finishCount = 0
        if _tab.id == 4 then
            local _list = module.CemeteryModule.GetTeamPveFightList(1)
            if _list and _list.count then
                _finishCount = _list.count
            end
        elseif _tab.id == 5 then
            local _list = module.CemeteryModule.GetTeamPveFightList(2)
            if _list and _list.count then
                _finishCount = _list.count
            end
        elseif _tab.id == 7 then
            if module.answerModule.GetWeekCount() then
                _finishCount = module.answerModule.GetWeekCount()
            end
        else
            if _tab.huoyuedu ~= 0 and _quest then
                _finishCount = _quest.finishCount
            end
        end

        if _quest then
            if _tab.id then
                if _quest.reward_value1 then
                    _active = _finishCount * _quest.reward_value1
                else
                    ERROR_LOG("reward_value1 nil")
                end
            end
        end
        _view.unLock.count.value[UI.Text].text = _finishCount.."/".._tab.join_limit
        _view.unLock.active.value[UI.Text].text = _active.."/".._tab.vatality

        if _finishCount ~= 0 and _tab.advise_times ~= 0 and _finishCount >= _tab.advise_times then
            _view.finsh.gameObject:SetActive(true)
        else
            _view.finsh.gameObject:SetActive(false)
        end
        _view.unLock.join.gameObject:SetActive(not _view.finsh.gameObject.activeSelf)

        _view.close.Text[UI.Text]:TextFormat("{0}级解锁", _tab.lv_limit)
        _view.close.gameObject:SetActive(_tab.lv_limit > module.HeroModule.GetManager():Get(11000).level)
        _view.unLock.gameObject:SetActive(not _view.close.gameObject.activeSelf)

        if _tab.huoyuedu == 0 then
            _view.unLock.active.value[UI.Text]:TextFormat("无")
        end
        --_view.unLock.active:SetActive(_tab.huoyuedu ~= 0)
        --_view.unLock.count:SetActive(_tab.huoyuedu ~= 0)
        local _material = nil
        if self.fighting and _tab.gototype ~= 2 then
            _material = _view.unLock.join[CS.UnityEngine.MeshRenderer].materials[0]
        end
        _view.unLock.join[UI.Image].material = _material

        CS.UGUIClickEventListener.Get(_view.unLock.join.gameObject).onClick = function()
            if self.fighting then
                if _tab.gototype == 2 then
                    DialogStack.Pop()
                    DialogStack.Push(_tab.gotowhere)
                end
            else
                DispatchEvent("LOCAL_MAPSCENE_PUSHSCENE", {gototype = _tab.gototype, gotowhere = _tab.gotowhere, npcId = _tab.findnpcname})
                DialogStack.Pop()
            end
        end

        CS.UGUIClickEventListener.Get(_view.btn.gameObject).onClick = function()
            DispatchEvent("LOCAL_MAPSCENE_OPEN_ACTIVITYINFO", {index = _tab.id, count = _finishCount})
        end
        obj.gameObject:SetActive(true)
    end
    self.scrollView.DataCount = #self.nowType
end

function mapSceneActivity:initBottom()
    self.refreshTime = self.view.mapSceneActivityRoot.bottom.refreshTime[UI.Text]
    self:initSlider()
end

function mapSceneActivity:initSlider()
    self.slider = self.view.mapSceneActivityRoot.bottom.Slider[UI.Slider]
    self.slider.maxValue = activityConfig.ActiveCfg(5).limit_point
    self.number = self.view.mapSceneActivityRoot.bottom.Slider.FillArea.point.number[UI.Text]
    self.slider.value = module.ItemModule.GetItemCount(90012)
    self.number.text = tostring(module.ItemModule.GetItemCount(90012))
    self:upSlider()
end

function mapSceneActivity:upSlider()
    for i = 1, 5 do
        local _view = self.view.mapSceneActivityRoot.bottom.numberNode[i]
        local _cfg = activityConfig.ActiveCfg(i)
        if _cfg then
            _view[UI.Text].text = tostring(_cfg.limit_point)
            local _item = ItemHelper.Get(_cfg.show_reward_type,_cfg.show_reward_id)
            _view.icon[UI.Image]:LoadSprite("icon/".._item.icon)
            if self.slider.value >= _cfg.limit_point then
                _view.mask.gameObject:SetActive(module.QuestModule.Get(i).status ~= 0)
            else
                _view.mask.gameObject:SetActive(true)
            end
            local Material = nil
            if _view.mask.activeSelf then
                Material = _view.icon[CS.UnityEngine.MeshRenderer].materials[0]
            end
            _view.icon[UI.Image].material = Material
            CS.UGUIClickEventListener.Get(_view.mask.gameObject).onClick = function()
                if module.QuestModule.Get(i).status ~= 0 then
                    showDlgError(nil, "已领取")
                else
                    showDlgError(nil, "进度不足")
                end
            end
            CS.UGUIClickEventListener.Get(_view.btn.gameObject).onClick = function()
                module.QuestModule.Finish(i)
            end
        end
    end
end

function mapSceneActivity:upUi()
    self:upBottom()
end

function mapSceneActivity:upBottom()
    self.refreshTime:TextFormat("每日<color=#2CFFC6>0点</color>刷新")
end

function mapSceneActivity:listEvent()
    return {
        "QUEST_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
    }
end

function mapSceneActivity:onEvent(event, ...)
    if event == "QUEST_INFO_CHANGE" then
        self:upSlider()
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    end
end

return mapSceneActivity
