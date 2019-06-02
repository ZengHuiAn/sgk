local openLevel = require "config.openLevel"
local HeroLevelup = require "hero.HeroLevelup"
local guideShaar = {}

function guideShaar:Start()
    self:initData()
    self:initUi()
end

function guideShaar:initData()
    self.quest = module.QuestModule.Get(module.guideLayerModule.Type.LevelUp)
    self.flag = true
end

function guideShaar:Update()
    self:upOverTime()
end

function guideShaar:upOverTime()
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
            self.view.root.ScrollView.Viewport.Content.item2.time[UI.Text].text = self.view.root.ScrollView.Viewport.Content.item1.activite.Text[UI.Text].text
        end
    end
    local _questTime, _condition = self:getLevelTime()
    local _time = _questTime - module.Time.now()
    if self.flag then
        if _time > 0 then
            self.view.root.ScrollView.Viewport.Content.item1.overTime[UI.Text].text = SGK.Localize:getInstance():getValue("xiaobai_shoucangjia_7", GetTimeFormat(_time, 2, 2))
        else
            self.view.root.ScrollView.Viewport.Content.item1.overTime[UI.Text].text = SGK.Localize:getInstance():getValue("xiaobai_shoucangjia_7", "00:00")
            module.QuestModule.Finish(module.guideLayerModule.Type.LevelUp)
            self.flag = false
        end
    end
end

function guideShaar:upUi()
    local _view = self.view.root.ScrollView.Viewport.Content.item2
    _view:SetActive((self.quest and true) and (module.QuestModule.CanSubmit(self.cfg) or self.quest.status == 1))
    _view.open:SetActive(module.ItemModule.GetItemCount(90032) > 0)
    _view.close:SetActive(not _view.open.activeSelf)
    self.view.root.ScrollView.Viewport.Content[UI.VerticalLayoutGroup].enabled = false
    self.view.root.ScrollView.Viewport.Content[UI.VerticalLayoutGroup].enabled = true
end

function guideShaar:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    for i = 1, #self.view.root.ScrollView.Viewport.Content do
        local _view = self.view.root.ScrollView.Viewport.Content[i]
        utils.IconFrameHelper.Create(_view.IconFrame, {customCfg={
                icon    = 19906,
                quality = 0,
                star    = 0,
                level   = 0,
        }, type = 42});
    end
    CS.UGUIClickEventListener.Get(self.view.root.backBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.ScrollView.Viewport.Content.item2.open.gameObject, true).onClick = function()
        if module.ItemModule.GetItemCount(90032) <= 0 then
            showDlgError(nil, "未到时间")
            return
        end
        local _view = self.view.root.ScrollView.Viewport.Content.item2.open
        local _func = function()
            _view[CS.UGUIClickEventListener].interactable = false
            _view[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
            coroutine.resume(coroutine.create(function()
                local hero = module.HeroModule.GetManager():Get(11000)
                local _data = module.HeroHelper.AddExpByItem(hero.uuid, 1)
                if _data and _data[2] == 0 then
                    utils.EventManager.getInstance():dispatch("QUEST_INFO_CHANGE")
                    DialogStack.Pop()
                    return
                end
                _view[CS.UGUIClickEventListener].interactable = true
                _view[UI.Image].material = nil
            end))
        end

        if module.unionModule.Manage:GetSelfUnion() == nil then
            local _msg = SGK.Localize:getInstance():getValue("xiayazhixin_3")
            local _infoMsg = ""
            if not openLevel.GetStatus(2101) then
                _msg = SGK.Localize:getInstance():getValue("xiayazhixin_6", openLevel.GetCfg(2101).open_lev)
                _infoMsg = _msg
            end
            showDlgMsg(SGK.Localize:getInstance():getValue("xiayazhixin_1", 5000),
            function()
                if openLevel.GetStatus(2101) then
                    utils.MapHelper.OpUnionList()
                else
                    showDlgError(nil, _msg)
                end
            end,function()
                _func()
            end,SGK.Localize:getInstance():getValue("xiayazhixin_3"),
                SGK.Localize:getInstance():getValue("xiayazhixin_2"), nil, _infoMsg)
        else
            showDlgMsg(SGK.Localize:getInstance():getValue("xiayazhixin_4", 5000),
                function()
                    _func()
            end, nil, SGK.Localize:getInstance():getValue("xiayazhixin_5", 5000))
        end
    end
    self:upUi()
end

function guideShaar:getLevelTime()
    local _quest = module.QuestModule.Get(module.guideLayerModule.Type.LevelUp)
    local _time = module.playerModule.Get().loginTime
    if _quest then
        if _quest.records[1] == 0 then
            _time = _quest.accept_time
        end
        return (_time + (_quest.condition[1].count - _quest.records[1])), _quest.condition[1].count
    else
        return 0
    end
end

function guideShaar:listEvent()
    return {
        "QUEST_INFO_CHANGE",
        "PLAYER_LEVEL_UP",
    }
end

function guideShaar:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" or event == "PLAYER_LEVEL_UP" then
        self:upUi()
    end
end

return guideShaar
