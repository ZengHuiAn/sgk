local dailyTask = {}

function dailyTask:Start()
    self:initData()
    self:initUi()
    self:initFx()
end

function dailyTask:initData()
    -- local _list = module.QuestModule.GetList(21)
    -- self.questList = {}
    -- for i,v in ipairs(_list) do
    --     if v.depend_level <= module.HeroModule.GetManager():Get(11000).level then
    --         table.insert(self.questList, v)
    --     end
    -- 
    -- table.sort(self.questList, function(a, b)
    --     local _idA = a.id
    --     local _idB = b.id
    --     if module.QuestModule.CanSubmit(a.id) then
    --         _idA = _idA - 1000
    --     end
    --     if module.QuestModule.CanSubmit(b.id) then
    --         _idB = _idB - 1000
    --     end
    --     if a.status == 1 then
    --         _idA = _idA + 1000
    --     end
    --     if b.status == 1 then
    --         _idB = _idB + 1000
    --     end
    --     return _idA < _idB
    -- end)

    local _list = module.QuestModule.GetConfigType(21)
    self.questList = {}
    for i,v in ipairs(_list) do
        if CheckActiveTime(v) then
            if module.QuestModule.CanAccept(v.id) and not module.QuestModule.Get(v.id) then
                module.QuestModule.Accept(v.id)
            end
           table.insert(self.questList, v)
        end
    end

    self:sortList()
end

function dailyTask:sortList()
    table.sort(self.questList, function(a, b)
        local _idA = a.id + a.depend_level*100
        local _idB = b.id + b.depend_level*100
        --可完成的任务
        if module.QuestModule.CanSubmit(a.id) then
            _idA = _idA -100000
        end
        if module.QuestModule.CanSubmit(b.id) then
            _idB = _idB - 100000
        end

        --已完成的任务
        if module.QuestModule.Get(a.id) and module.QuestModule.Get(a.id).status==1 then
            _idA = _idA +100000
        end
        if module.QuestModule.Get(b.id) and module.QuestModule.Get(b.id).status==1 then
            _idB = _idB + 100000
        end

        --已接任务
        if module.QuestModule.Get(a.id) and module.QuestModule.Get(a.id).status==1 then
            _idA = _idA -10000
        end
        if module.QuestModule.Get(b.id) and module.QuestModule.Get(b.id).status==1 then
            _idB = _idB - 10000
        end

        return _idA < _idB
    end)
end

function dailyTask:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.bg.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    self:initScrollView()
    self:upDailyTask()
end

local function GetShowTime(str)
    local strTab = StringSplit(str,"|")
    if #strTab>1 then
        local _showTime = nil
        for i=1,#strTab do
            local _timer = StringSplit(strTab[i],"~")
            if _timer and not _showTime then
                local _end = _timer[1],_timer[2]
                if _end and not _showTime then
                    local end_HH_MM = StringSplit(_end,":")
                    if not _showTime and end_HH_MM and end_HH_MM[1] and end_HH_MM[2] then
                        local endTime = os.time({year =os.date("%Y",module.Time.now()), month = os.date("%m",module.Time.now()) ,day = os.date("%d",module.Time.now()),hour = end_HH_MM[1],min = end_HH_MM[2],sec = 0})
                        if module.Time.now()<endTime then
                            _showTime = strTab[i]
                        end
                    end
                end
            end
            if _showTime then
                break
            end
        end
        _showTime = _showTime or "活动已结束"
        return _showTime
    else
        return strTab[1]
    end
end

function dailyTask:initScrollView()
    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = self.questList[idx + 1]
        _view.root.icon[UI.Image]:LoadSprite("guideLayer/".._cfg.icon)
        
        _view.root.time:SetActive(_cfg.button_des ~= "0")
        if _cfg.button_des ~= "0" then
            local showTime = GetShowTime(_cfg.button_des)
            _view.root.time.Text[UI.Text].text = showTime and showTime or _cfg.button_des
        end
        
        _view.root.getBtn:SetActive(module.QuestModule.CanSubmit(_cfg.id) and _cfg.depend_level <=module.HeroModule.GetManager():Get(11000).level)
        local _quest = module.QuestModule.Get(_cfg.id)
        if _quest then
            _view.root.number[UI.Text].text = _quest.records[1].."/".._cfg.condition[1].count
            
            _view.root.goBtn:SetActive((_quest.status ~= 1) and (not _view.root.getBtn.activeSelf) and _cfg.depend_level <=module.HeroModule.GetManager():Get(11000).level)
            _view.root.gotNode:SetActive(_quest.status == 1)
            _view.root.gotMask:SetActive(_quest.status == 1)
        else
            _view.root.number[UI.Text].text = "0/".._cfg.condition[1].count

            _view.root.goBtn:SetActive(false)
            _view.root.gotNode:SetActive(false)
            _view.root.gotMask:SetActive(false)
        end
        --_view.root.number[UI.Text].text = _cfg.records[1].."/".._cfg.condition[1].count
        _view.root.activeNode.number[UI.Text].text = "+".._cfg.desc2

        --未开启
        _view.root.unOpen:SetActive(_cfg.depend_level > module.HeroModule.GetManager():Get(11000).level)
        if _cfg.depend_level > module.HeroModule.GetManager():Get(11000).level then
            _view.root.desc[UI.Text].text = SGK.Localize:getInstance():getValue("tips_lv_02", _cfg.depend_level)
        else
            _view.root.desc[UI.Text].text = _cfg.desc1
        end
        CS.UGUIClickEventListener.Get(_view.root.unOpen.gameObject,true).onClick = function()
            showDlgError(nil,SGK.Localize:getInstance():getValue("meirirenwu_05"))
        end

        CS.UGUIClickEventListener.Get(_view.root.goBtn.gameObject).onClick = function()
            local teamInfo = module.TeamModule.GetTeamInfo();
            if teamInfo.group == 0 or module.playerModule.Get().id == teamInfo.leader.pid then
                --不在一个队伍中或自己为队长
                module.QuestModule.StartQuestGuideScript(_cfg, true)
            else
                showDlgError(nil,"你正在队伍中，无法进行该操作")
            end
        end

        CS.UGUIClickEventListener.Get(_view.root.getBtn.gameObject).onClick = function()
            _view.root.getBtn[CS.UGUIClickEventListener].interactable = false
            _view.root.getBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
            coroutine.resume(coroutine.create(function()
                module.QuestModule.Finish(_quest.uuid)
                _view.root.getBtn[CS.UGUIClickEventListener].interactable = true
                _view.root.getBtn[UI.Image].material = nil
            end))
        end


        local _scrollView = _view.root.ScrollView[CS.UIMultiScroller]
        _scrollView.RefreshIconCallback = function (sObj, sIdx)
            local _sView = CS.SGK.UIReference.Setup(sObj.gameObject)
            local _rCfg = _cfg.reward[sIdx + 1]
            utils.IconFrameHelper.Create(_sView.IconFrame, {type = _rCfg.type, id = _rCfg.id, count = _rCfg.value, showDetail = true})
            sObj:SetActive(true)
        end
        _scrollView.DataCount = #_cfg.reward

        obj:SetActive(true)
    end
    self.scrollView.DataCount = #self.questList
end

function dailyTask:initFx()
    for i = 1, 5 do
        local _view = self.view.root.activeNode.rewardList[i]
        SGK.ResourcesManager.LoadAsync("prefabs/effect/UI/fx_item_reward.prefab", function(obj)
            CS.UnityEngine.GameObject.Instantiate(obj.transform, _view.fx.transform)
        end)
    end
end

function dailyTask:upDailyTask()
    self.view.root.activeNode.number[UI.Text].text = tostring(module.ItemModule.GetItemCount(90012))
    self.view.root.activeNode.Scrollbar[UI.Scrollbar].size = module.ItemModule.GetItemCount(90012) / module.QuestModule.Get(5).consume[1].value
    for i = 1, 5 do
        local _quest = module.QuestModule.Get(i)
        local _view = self.view.root.activeNode.rewardList[i]
        _view.number[UI.Text].text = tostring(_quest.consume[1].value)
        _view.number[UI.Text].color = {r = 1, g = 1, b = 1, a = 1}
        local _idx = 1
        local _submitFlag = module.QuestModule.CanSubmit(i)
        _view.fx:SetActive(_submitFlag)
        if _submitFlag or (_quest.status == 1) then
            _idx = 0
            _view.number[UI.Text].color = {r = 0, g = 0, b = 0, a = 1}
        end
        _view[CS.UGUISpriteSelector].index = _idx
        _view.select:SetActive(_quest.status == 1)
        if _quest.status == 1 then
            _view[UI.Image].color = {r = 126/255, g = 126/255, b = 126/255, a = 1}
        else
            _view[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
        end
        if _submitFlag then
            CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
                _view[CS.UGUIClickEventListener].interactable = false
                _view[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                coroutine.resume(coroutine.create(function()
                    module.QuestModule.Finish(_quest.uuid)
                    _view[CS.UGUIClickEventListener].interactable = true
                    _view[UI.Image].material = nil
                end))
            end
        else
            CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
                DialogStack.PushPrefStact("mapSceneUI/dailyTaskBox", {itemTab = _quest.reward, interactable = false, textName = SGK.Localize:getInstance():getValue("meirirenwu_04"), textDesc = ""}, UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject.transform)
            end
        end
    end
end

function dailyTask:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true
end

function dailyTask:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function dailyTask:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        if self.view and not self.Refreshing then
            self.Refreshing = true
            self.view.transform:DOScale(Vector3.one,0.2):OnComplete(function ( ... )
                self:sortList()
                self:upDailyTask()
                self.scrollView:ItemRef()
                self.Refreshing = false
            end)
        end
    end
end


return dailyTask
