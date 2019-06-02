local guideOnlineRewards = {}

function guideOnlineRewards:Start()
    self.nextTime = 1
    self:initData()
    self:initUi()
end

function guideOnlineRewards:initData()
    self.questListCfg = module.QuestModule.GetConfigType(97)
end

function guideOnlineRewards:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.backBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    for i = 1, #self.view.root.ScrollView.Viewport.Content do
        local _view = self.view.root.ScrollView.Viewport.Content[i]
        utils.IconFrameHelper.Create(_view.IconFrame, {customCfg={
                icon    = 11013,
                quality = 0,
                star    = 0,
                level   = 0,
        }, type = 42});
    end
    self:initItemQuest()
    self:upUi()
end

function guideOnlineRewards:upQuestList()
    local _view = self.view.root.ScrollView.Viewport.Content.item1.activite.taskNode
    for i,v in ipairs(self.questListCfg) do
        if _view[i] then
            _view[i].info[UI.Text].text = v.name
            local _scrollView = _view[i].ScrollView[CS.UIMultiScroller]
            local _status = module.QuestModule.CanSubmit(v.id)
            local _idx = 0
            if _status or (module.QuestModule.Get(v.id) and module.QuestModule.Get(v.id).status == 1) then
                _idx = 1
            end
            _view[i][CS.UGUISpriteSelector].index = _idx
            _scrollView.RefreshIconCallback = function (_obj, _idx)
                local _rewardView = CS.SGK.UIReference.Setup(_obj.gameObject)
                local _rewardTab = v.reward[_idx + 1]
                utils.IconFrameHelper.Create(_rewardView.newItemIcon, {id = _rewardTab.id, type = _rewardTab.type, showDetail = true, count = _rewardTab.value})
                _obj:SetActive(true)
            end
            _scrollView.DataCount = #v.reward
        end
    end
end

function guideOnlineRewards:Update()
    self:upOverTime()
    if self.nextTime and self.nextTime > 0 then
        self.nextTime = self.nextTime - UnityEngine.Time.deltaTime
        if self.nextTime < 0 then
            self:getLastQuestTime()
            self.nextTime = 1
        end
    end
end

function guideOnlineRewards:upOverTime()
    if self.view.root.ScrollView.Viewport.Content.item1.activite.Text then
        if self.questListCfg[1] then
            local _time = (self.questListCfg[1].end_time - 1) * 86400
            local _off = (module.playerModule.Get().create_time + _time) - module.Time.now()
            local _day = math.floor(_off / 86400)
            local _hour = math.floor((_off - _day * 86400) / 3600)
            local _min = math.floor((_off - _day * 86400 - _hour * 3600) / 60)
            if _day == 0 then
                self.view.root.ScrollView.Viewport.Content.item1.activite.Text[UI.Text].text = SGK.Localize:getInstance():getValue("online_reward_2", _hour, _min)
            else
                self.view.root.ScrollView.Viewport.Content.item1.activite.Text[UI.Text].text = SGK.Localize:getInstance():getValue("online_reward_1", _day, _hour, _min)
            end
        else
            self.view.root.ScrollView.Viewport.Content.item1.activite.Text[UI.Text].text = ""
        end
        for i = 1, 7 do
            if self.view.root.ScrollView.Viewport.Content["itemQuest"..i].activeSelf then
                self.view.root.ScrollView.Viewport.Content["itemQuest"..i].time[UI.Text].text = self.view.root.ScrollView.Viewport.Content.item1.activite.Text[UI.Text].text
            end
        end
    end
end

function guideOnlineRewards:initItemQuest()
    for i = 1, 7 do
        local _view = self.view.root.ScrollView.Viewport.Content["itemQuest"..i]
        CS.UGUIClickEventListener.Get(_view.open.gameObject, true).onClick = function()
            if not module.QuestModule.CanSubmit(self.questListCfg[i].id) then
                showDlgError(nil, "未达成")
            else
                _view.open[CS.UGUIClickEventListener].interactable = false
                _view.open[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                coroutine.resume(coroutine.create(function()
                    module.QuestModule.Finish(self.questListCfg[i].id)
                    _view.open[CS.UGUIClickEventListener].interactable = true
                    _view.open[UI.Image].material = nil
                end))
            end
        end
    end
end

function guideOnlineRewards:getLastQuestTime()
    for i,p in ipairs(self.questListCfg or {}) do
        local v = module.QuestModule.Get(p.id)
        if v and v.status == 0 and not module.QuestModule.CanSubmit(v.id) then
            if self.lastQuest == v then
                return self.recordLastTime
            else
                local _time = module.playerModule.Get().loginTime
                if v.records[1] == 0 then
                    _time = v.accept_time
                end
                if self.lastQuest ~= nil then
                    self:upUi()
                end
                self.lastQuest = v
                self.recordLastTime = (_time + (v.condition[1].count - v.records[1]))
                return self.recordLastTime
            end
        end
    end
end

function guideOnlineRewards:upItemQuest()
    local _questIdx = nil
    for i,v in ipairs(self.questListCfg) do
        local _view = self.view.root.ScrollView.Viewport.Content["itemQuest"..i]
        local _cfg = module.QuestModule.Get(self.questListCfg[i].id)
        _view:SetActive(_cfg and true and (module.QuestModule.CanSubmit(self.questListCfg[i].id) or _cfg.status == 1))
        if _view.activeSelf then
            _view.open:SetActive(_cfg.status == 0)
            _view.close:SetActive(_cfg.status == 1)
            if _cfg.status == 0 and (_questIdx == nil) then
                _questIdx = i
            end
        end
    end
    self.view.root.ScrollView.Viewport.Content[UI.VerticalLayoutGroup].enabled = false
    self.view.root.ScrollView.Viewport.Content[UI.VerticalLayoutGroup].enabled = true
    self.view.transform:DOLocalRotate(Vector3(0, 0, 0), 0.3):OnComplete(function()
        if _questIdx then
            --self.view.root.ScrollView.Viewport.Content.transform.localPosition = Vector3(0, self.view.root.ScrollView.Viewport.Content.transform.localPosition.y + _questIdx * 300, 0)
            self.view.root.ScrollView.Viewport.Content.transform:DOLocalMove(Vector3(0, self.view.root.ScrollView.Viewport.Content.transform.localPosition.y + _questIdx * 300, 0), 0.2):SetEase(CS.DG.Tweening.Ease.OutCubic)
        end
    end)
end

function guideOnlineRewards:upUi()
    self:upItemQuest()
    self:upQuestList()
end

function guideOnlineRewards:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function guideOnlineRewards:onEvent(event, data)
    if "QUEST_INFO_CHANGE" then
        self:upUi()
    end
end

return guideOnlineRewards
