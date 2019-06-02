local OpenLevel = require "config.openLevel"
local guideGetTitle = {}

function guideGetTitle:Start(data)
    self:initData(data)
end

function guideGetTitle:initData(data)
    if data then
        self.savedValues.cfgData = data
    end
    self.cfg = data or self.savedValues.cfgData
    self.quest = module.QuestModule.Get(self.cfg)
    self:initUi()
    self:upUi()
end

function guideGetTitle:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.backBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    for i = 1, #self.view.root.ScrollView.Viewport.Content do
        local _view = self.view.root.ScrollView.Viewport.Content[i]
        utils.IconFrameHelper.Create(_view.IconFrame, {customCfg={
                icon    = 11025,
                quality = 0,
                star    = 0,
                level   = 0,
        }, type = 42});
    end
    CS.UGUIClickEventListener.Get(self.view.root.ScrollView.Viewport.Content.item1.activite.Image.gameObject, true).onClick = function()
        if not self.view.root.ScrollView.Viewport.Content.item3.activeSelf then
            self.view.root.ScrollView.Viewport.Content.item3:SetActive(true)
            self.view.root.ScrollView.Viewport.Content.item3.transform:SetSiblingIndex(5)
            self:jumpTo()
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.ScrollView.Viewport.Content.item2.activite.Image.gameObject, true).onClick = function()
        if OpenLevel.GetStatus(1201) then
            DialogStack.Pop()
            DialogStack.Push("mapSceneUI/newMapSceneActivity")
        else
            showDlgError(nil, SGK.Localize:getInstance():getValue("tips_lv_02", OpenLevel.GetCfg(1201).open_lev))
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.getBtn.gameObject).onClick = function()
        if not self.view.root.ScrollView.Viewport.Content.item2.activeSelf then
            self.view.root.ScrollView.Viewport.Content.item2:SetActive(true)
            self.view.root.ScrollView.Viewport.Content.item2.transform:SetSiblingIndex(5)
            self:jumpTo()
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.previewBtn.gameObject).onClick = function()
        if not self.view.root.ScrollView.Viewport.Content.item3.activeSelf then
            self.view.root.ScrollView.Viewport.Content.item3:SetActive(true)
            self.view.root.ScrollView.Viewport.Content.item3.transform:SetSiblingIndex(5)
            self:jumpTo()
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.ScrollView.Viewport.Content.item4.open.gameObject, true).onClick = function()
        if self.quest and module.QuestModule.CanSubmit(self.quest.uuid) then
            local _view = self.view.root.ScrollView.Viewport.Content.item4
            _view.open[CS.UGUIClickEventListener].interactable = false
            _view.open[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
            coroutine.resume(coroutine.create(function()
                module.QuestModule.Finish(self.quest.uuid)
                module.playerModule.ChangeHonor(2003)
                showDlgError(nil, SGK.Localize:getInstance():getValue("xiaobai_xiaositaya_6"))
                _view.open[UI.Image].material = nil
                _view.open[CS.UGUIClickEventListener].interactable = true
            end))
        end
    end
end

function guideGetTitle:Update()
    self:upOverTime()
end

function guideGetTitle:upOverTime()
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
        for i = 2, 3 do
            if self.view.root.ScrollView.Viewport.Content["item"..i] then
                if self.view.root.ScrollView.Viewport.Content["item"..i].activeSelf then
                    self.view.root.ScrollView.Viewport.Content["item"..i].activite.Text[UI.Text].text = self.view.root.ScrollView.Viewport.Content.item1.activite.Text[UI.Text].text
                end
            end
        end
        if self.view.root.ScrollView.Viewport.Content.item4.activeSelf then
            self.view.root.ScrollView.Viewport.Content.item4.time[UI.Text].text = self.view.root.ScrollView.Viewport.Content.item1.activite.Text[UI.Text].text
        end
    end
end

function guideGetTitle:upUi()
    local _view = self.view.root.ScrollView.Viewport.Content.item4
    _view:SetActive((self.quest and true) and (module.QuestModule.CanSubmit(self.cfg) or self.quest.status == 1))
    _view.open:SetActive(module.QuestModule.CanSubmit(self.cfg))
    _view.close:SetActive(not _view.open.activeSelf)
    if _view.activeSelf then
        self:jumpTo()
    end
    self.view.root.ScrollView.Viewport.Content.item2.activite.topText[UI.Text].text = SGK.Localize:getInstance():getValue("xiaobai_xiaositaya_5", module.ItemModule.GetItemCount(90012))
end

function guideGetTitle:jumpTo()
    self.view.root.ScrollView.Viewport.Content[UI.VerticalLayoutGroup].enabled = false
    self.view.root.ScrollView.Viewport.Content[UI.VerticalLayoutGroup].enabled = true
    self.view.root.ScrollView.Viewport.Content.transform.localPosition = Vector3(0, 700, 0)
end

function guideGetTitle:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function guideGetTitle:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        if data and data.id == self.cfg then
            self.quest = module.QuestModule.Get(self.cfg)
            self:upUi()
        end
    end
end

return guideGetTitle
