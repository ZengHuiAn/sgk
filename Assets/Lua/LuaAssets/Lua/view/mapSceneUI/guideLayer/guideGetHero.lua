local guideGetHero = {}

function guideGetHero:Start(data)
    self:initData(data)
    self:initUi()
end

function guideGetHero:initData(data)
    if data then
        self.savedValues.cfgData = data
    end
    self.cfg = data or self.savedValues.cfgData
end

function guideGetHero:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.backBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    for i = 1, #self.view.root.ScrollView.Viewport.Content do
        local _view = self.view.root.ScrollView.Viewport.Content[i]
        utils.IconFrameHelper.Create(_view.IconFrame, {customCfg={
                icon    = 11001,
                quality = 0,
                star    = 0,
                level   = 0,
        }, type = 42});
        _view:SetActive(false)
        _view.transform:DOLocalRotate(Vector3(0, 0, 0), (i - 1 * 1.5)):OnComplete(function()
            _view:SetActive(true)
            self:upUi()
        end)
    end
end

function guideGetHero:upUi()
    self.quest = module.QuestModule.Get(self.cfg)
    local _view = self.view.root.ScrollView.Viewport.Content.item3
    _view:SetActive((self.quest and true) and (module.QuestModule.CanSubmit(self.cfg) or self.quest.status == 1))
    _view.open:SetActive(module.QuestModule.CanSubmit(self.cfg))
    _view.close:SetActive(not _view.open.activeSelf)
    if _view.activeSelf then
        self:jumpTo()
    end
    CS.UGUIClickEventListener.Get(_view.open.gameObject, true).onClick = function()
        if module.QuestModule.CanSubmit(self.quest.uuid) then
            _view.open[CS.UGUIClickEventListener].interactable = false
            _view.open[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
            coroutine.resume(coroutine.create(function()
                module.QuestModule.Finish(self.quest.uuid)
                _view.open[UI.Image].material = nil
                _view.open[CS.UGUIClickEventListener].interactable = true
                DialogStack.Pop()
            end))
        else
            showDlgError(nil, self.quest.name)
        end
    end
end

function guideGetHero:Update()
    self:upOverTime()
end

function guideGetHero:upOverTime()
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
        if self.view.root.ScrollView.Viewport.Content.item3.activeSelf then
            self.view.root.ScrollView.Viewport.Content.item3.time[UI.Text].text = self.view.root.ScrollView.Viewport.Content.item1.activite.Text[UI.Text].text
        end
    end
end

function guideGetHero:jumpTo()
    self.view.root.ScrollView.Viewport.Content[UI.VerticalLayoutGroup].enabled = false
    self.view.root.ScrollView.Viewport.Content[UI.VerticalLayoutGroup].enabled = true
end

function guideGetHero:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function guideGetHero:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        if data and data.id == self.cfg then
            self.quest = module.QuestModule.Get(self.cfg)
            self:upUi()
        end
    end
end

return guideGetHero
