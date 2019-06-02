local zeroPlan = {}
local ParameterShowInfo = require "config.ParameterShowInfo"

function zeroPlan:Start()
    self.clickTime = 0
    self.clickNumber = 0
    self:initData()
    self:initUi()
    module.guideModule.PlayByType(124,0.2)
end

function zeroPlan:initData()
    self.rewardList = module.zeroPlanModule.Get()
    self.idx = 0
    for k,v in pairs(self.rewardList) do
        if v[6] then
            local _quest = module.QuestModule.Get(v[6].quest_id)
            if not _quest or _quest.status ~= 1 then
                self.idx = self.idx + 1
                break
            end
        end
        self.idx = self.idx + 1
    end
    self.parameterList = {
        [1] = {id = 1003, name = "攻击"},
        [2] = {id = 1302, name = "防御"},
        [3] = {id = 1502, name = "血量"},
    }
    self:upData()
end

function zeroPlan:upData()
    self.honor = {}
    self.openDescList = {}
    self.questList = module.zeroPlanModule.GetQuestList(self.idx)
    self.rewardQuestList = {}
    for i,v in ipairs(self.rewardList[self.idx] or {}) do
        if v.honor then
            self.honor = v.honor
        end
        if v.openLevel then
            table.insert(self.openDescList, v.openLevel)
        end
        if v.quest_id ~= 0 then
            table.insert(self.rewardQuestList, v)
        end
    end
    table.sort(self.rewardQuestList, function(a, b)
        return a.id < b.id
    end)
end

function zeroPlan:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    self:initBtn()
    self:initScrollView()
    self:iconBtn()
    self:upUi()
end

function zeroPlan:upProgress()
    local _buffList = {}
    for i = 1, 5 do
        local _view = self.view.root.middle.progressNode[i]
        if self.rewardQuestList[i] then
            local _quest = module.QuestModule.Get(self.rewardQuestList[i].quest_id)
            _view.show:SetActive(_quest ~= nil and _quest.status == 1)
            local _buff = self.rewardQuestList[i].buff
            for i,v in ipairs(_buff) do
                _buffList[v.key] = _buffList[v.key] or 0
                if _quest and _quest.status == 1 then
                    _buffList[v.key] = _buffList[v.key] + v.value
                end
            end
        else
            _view.show:SetActive(false)
        end
    end
    local _parameterViewList = {}
    for i,v in ipairs(self.parameterList) do
        local _view = self.view.root.middle.buff[i]
        if _view and _buffList[v.id] then
            _view.info[UI.Text].text = v.name
            if _buffList[v.id] ~= 0 then
                _view.info[UI.Text].text = _view.info[UI.Text].text.."+".._buffList[v.id]
            end
            _parameterViewList[v.id] = _view
        end
    end
    self.nextQuest = nil
    for i = 1, 5 do
        if self.rewardQuestList[i] and self.rewardQuestList[i].quest_id then
            local _quest = module.QuestModule.Get(self.rewardQuestList[i].quest_id)
            if _quest and _quest.status == 0 then
                self.nextQuest = _quest
                local _buff = self.rewardQuestList[i].buff
                for i,v in ipairs(_buff) do
                    local _v = _parameterViewList[v.key]
                    if _v then
                        _v.info[UI.Text].text = _v.info[UI.Text].text.."<color=#00FF40>+"..v.value.."</color>"
                    end
                end
                break
            end
        end
    end
end

function zeroPlan:iconBtn()
    CS.UGUIClickEventListener.Get(self.view.root.top.iconBtn.gameObject).onClick = function()
        if self.doTweenCfg then
            self.doTweenCfg:Kill()
        end
        self.clickNumber = self.clickNumber + 1
        self.view.root.top.desc:SetActive(true)
        if self.clickTime == 0 then
            self.clickTime = module.Time.now()
        end
        local _lastTime = module.Time.now() - self.clickTime
        self.clickTime = module.Time.now()
        if _lastTime < 2 then
            if self.clickNumber >= 5 then
                self.view.root.top.desc.Text[UI.Text].text = SGK.Localize:getInstance():getValue(string.format("zeroplan99_%s", math.random(1, 3)))
            else
                self.view.root.top.desc.Text[UI.Text].text = SGK.Localize:getInstance():getValue(string.format("zeroplan%s_%s", self.idx, math.random(1, 3)))
            end
        else
            self.clickNumber = 0
            self.view.root.top.desc.Text[UI.Text].text = SGK.Localize:getInstance():getValue(string.format("zeroplan%s_%s", self.idx, math.random(1, 3)))
        end
        self.doTweenCfg = self.view.root.top.desc.transform:DOLocalMoveZ(0, 3):OnComplete(function()
            self.view.root.top.desc:SetActive(false)
        end)
    end
end

function zeroPlan:upUi()
    self.view.root.tittle.tittleName[UI.Text].text = self.honor.name
    ERROR_LOG(self.rewardQuestList[6].quest_id, module.QuestModule.GetCfg(self.rewardQuestList[6].quest_id))
    local _quest = module.QuestModule.GetCfg(self.rewardQuestList[6].quest_id)
    self.view.root.bg.Text[UI.Text].text = _quest and _quest.button_des or ""
    local _desc = ""
    for i,v in ipairs(self.openDescList) do
        _desc = _desc..v.."\n"
    end
    self.view.root.bottom.desc[UI.Text].text = _desc
    local _showItemCfg = module.ItemModule.GetShowItemCfg(self.honor.only_text) or {effect = "tx42"}
    local icon_id = _showItemCfg.effect
    self.view.root.bottom.honorIcon[UI.Image]:LoadSprite("icon/"..icon_id)
    self.scrollView.DataCount = #(self.questList or {})
    self:upProgress()
    local _material = nil
    if self.nextQuest == nil or (not module.QuestModule.CanSubmit(self.nextQuest.id)) then
        _material = SGK.QualityConfig.GetInstance().grayMaterial
    end
    self.view.root.middle.getBtn[UI.Image].material = _material
    if module.QuestModule.Get(self.rewardQuestList[6].quest_id) == nil or (not module.QuestModule.CanSubmit(self.rewardQuestList[6].quest_id)) then
        self.view.root.bottom.honorGetBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
    else
        self.view.root.bottom.honorGetBtn[UI.Image].material = nil
    end
    self:upBtn()
end

function zeroPlan:initScrollView()
    self.scrollView = self.view.root.top.infoList.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _questId = self.questList[idx + 1].quest_id
        local _cfg = module.QuestModule.GetCfg(_questId)
        _view.root.desc[UI.Text].text = _cfg.name
        local _quest = module.QuestModule.Get(_questId)
        _view.root.select:SetActive(_quest ~= nil and _quest.status == 1)
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if _quest then
                module.QuestModule.StartQuestGuideScript(_quest, true)
            end
        end
        obj:SetActive(true)
    end
end

function zeroPlan:upBtn()
    self.view.root.leftBtn:SetActive(self.idx ~= 1)
    self.view.root.rightBtn:SetActive(self.idx < #self.rewardList)
    if module.QuestModule.Get(self.rewardQuestList[6].quest_id) and module.QuestModule.Get(self.rewardQuestList[6].quest_id).status == 1 then
        self.view.root.bottom.honorGetBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("common_lingqu_02")
    else
        self.view.root.bottom.honorGetBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("common_lingqu_04")
    end
end

function zeroPlan:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.leftBtn.gameObject).onClick = function()
        if self.idx > 1 then
            self.idx = self.idx - 1
            self:upData()
            self:upUi()
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.rightBtn.gameObject).onClick = function()
        if self.idx < #self.rewardList then
            self.idx = self.idx + 1
            self:upData()
            self:upUi()
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.middle.getBtn.gameObject).onClick = function()
        if self.nextQuest and module.QuestModule.CanSubmit(self.nextQuest.id) then
            coroutine.resume(coroutine.create(function()
                module.QuestModule.Finish(self.nextQuest.id)
            end))
        else
            if self.nextQuest and self.nextQuest.status == 1 then
            else
                showDlgError(nil, SGK.Localize:getInstance():getValue("zeroplan99_5"))
            end
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.honorGetBtn.gameObject).onClick = function()
        if module.QuestModule.Get(self.rewardQuestList[6].quest_id) and module.QuestModule.CanSubmit(module.QuestModule.Get(self.rewardQuestList[6].quest_id).id) then
            coroutine.resume(coroutine.create(function()
                module.QuestModule.Finish(module.QuestModule.Get(self.rewardQuestList[6].quest_id).id)
                showDlgError(nil, module.QuestModule.Get(self.rewardQuestList[6].quest_id).desc1)
            end))
        else
            if module.QuestModule.Get(self.rewardQuestList[6].quest_id) and module.QuestModule.Get(self.rewardQuestList[6].quest_id).status == 1 then
            else
                showDlgError(nil, SGK.Localize:getInstance():getValue("zeroplan99_4"))
            end
        end
    end
end

function zeroPlan:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true
end

function zeroPlan:listEvent()
    return {
        "QUEST_INFO_CHANGE",
        "PLAYER_LEVEL_UP",
        "LOCAL_GUIDE_CHANE",
    }
end

function zeroPlan:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        self:upData()
        self:upUi()
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(124,0.2)
    end
end

return zeroPlan
