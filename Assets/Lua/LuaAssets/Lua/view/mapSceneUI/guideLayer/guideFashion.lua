local guideFashion = {}

function guideFashion:Start()
    self:initData()
    self:initUi()
end

function guideFashion:initData()
    self.cfg = module.guideLayerModule.GetFashionCfg()
    self.quest = module.QuestModule.Get(self.cfg.finishQuest)
end

function guideFashion:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.backBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    for i = 1, #self.view.root.ScrollView.Viewport.Content do
        local _view = self.view.root.ScrollView.Viewport.Content[i]
        utils.IconFrameHelper.Create(_view.IconFrame, {customCfg={
                icon    = 11003,
                quality = 0,
                star    = 0,
                level   = 0,
        }, type = 42});
    end
    CS.UGUIClickEventListener.Get(self.view.root.ScrollView.Viewport.Content.item1.activite.Image.gameObject, true).onClick = function()
        self.view.root.fashionNode:SetActive(true)
    end
    CS.UGUIClickEventListener.Get(self.view.root.fashionNode.gameObject, true).onClick = function()
        self.view.root.fashionNode:SetActive(false)
    end
    self:upUi()
    local _view = self.view.root.ScrollView.Viewport.Content.item3
    CS.UGUIClickEventListener.Get(_view.open.gameObject, true).onClick = function()
        if module.QuestModule.CanSubmit(self.quest.uuid) then
            _view.open[CS.UGUIClickEventListener].interactable = false
            _view.open[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
            coroutine.resume(coroutine.create(function()
                module.QuestModule.Finish(self.quest.uuid)
                showDlgError(nil, SGK.Localize:getInstance():getValue("xiaobai_shuangzixingwushi_9"))
                DialogStack.Pop()
                _view.open[UI.Image].material = nil
                _view.open[CS.UGUIClickEventListener].interactable = true
            end))
        else
            showDlgError(nil, self.quest.name)
        end
    end
end

function guideFashion:questList()
    for i = 1, 5 do
        local _view = self.view.root.ScrollView.Viewport.Content.item2.activite.taskNode[i]
        local _cfg = module.QuestModule.Get(self.cfg.conditions[i])
        if _cfg then
            _view.info[UI.Text].text = _cfg.name
            local _idx = 0
            if _cfg.status == 1 then
                _idx = 1
            end
            _view[CS.UGUISpriteSelector].index = _idx
        end
    end
end

function guideFashion:Update()
    self:upOverTime()
end

function guideFashion:upOverTime()
    if self.view.root.ScrollView.Viewport.Content.item1.activite.Text then
        if self.quest then
            local _time = (self.quest.end_time - 1) * 86400
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
        if self.view.root.ScrollView.Viewport.Content.item2.activeSelf then
            self.view.root.ScrollView.Viewport.Content.item2.activite.Text[UI.Text].text = self.view.root.ScrollView.Viewport.Content.item1.activite.Text[UI.Text].text
        end
        if self.view.root.ScrollView.Viewport.Content.item3.activeSelf then
            self.view.root.ScrollView.Viewport.Content.item3.time[UI.Text].text = self.view.root.ScrollView.Viewport.Content.item1.activite.Text[UI.Text].text
        end
    end
end

function guideFashion:jumpTo()
    self.view.root.ScrollView.Viewport.Content[UI.VerticalLayoutGroup].enabled = false
    self.view.root.ScrollView.Viewport.Content[UI.VerticalLayoutGroup].enabled = true
end

function guideFashion:upUi()
    self.view.root.ScrollView.Viewport.Content.item3:SetActive(self.quest and (self.quest.status == 1 or module.QuestModule.CanSubmit(self.quest.id)))
    if self.view.root.ScrollView.Viewport.Content.item3.activeSelf then
        self:jumpTo()
    end
    self:questList()
end

function guideFashion:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function guideFashion:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        self:upUi()
    end
end

return guideFashion
