local activityConfig = require "config.activityConfig"
local ItemHelper= require"utils.ItemHelper"
local taskList = {}

function taskList:Start()
    self:initData()
    self:initUi()
end

function taskList:initData()
   self.mainMission = activityConfig.GetBaseTittleByType(activityConfig.TitleType.Task)
   self.rewardTab = {}
   self.Type = {
        NowTask = 1,
        PickUpTask = 2,
    }
    self.cityContuctId = {41, 42, 43, 44}
    self.nowType = self.Type.NowTask
    self.nowSelectCfg = nil
end

function taskList:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.ScrollView = self.view.taskListRoot.ScrollView[SGK.dropdownView]
    self.noTask = self.view.taskListRoot.noTask
    self.noPickUp = self.view.taskListRoot.noPickUp
    self:initBtn()
    self:initScrollView()
    self:initRight()
    self:initRewardScrollView()
    self:initFirstRight()
end

function taskList:finedTittle(p)
    self.nowList = {}
    if self.nowType == self.Type.PickUpTask then
        local _list = module.QuestModule.GetCanAccept()
        for k,v in pairs(_list) do
            if v.type ~= 10 then
                table.insert(self.nowList, v)
            end
        end
    elseif self.nowType == self.Type.NowTask then
        self.nowList = module.QuestModule.GetList()
    end
    for k,v in pairs(self.nowList) do
        if v.is_show_on_task == 0 and v.status == 0 or (self.nowType == self.Type.PickUpTask and v.status ~= 0) then
            local _type = v.type
            if v.type == 2 then
                _type = v.bountyType
            end
            local _tempTab = activityConfig.GetActivity(_type)
            if _tempTab and _tempTab.up_tittle2 == p then
                return true
            end
        end
    end
    return false
end

function taskList:setNowselect(obj, p)
    if self.nowSelectObj then
        self.nowSelectObj:SetActive(false)
    end
    self.nowSelectObj = obj
    if self.nowSelectObj then
        self.nowSelectObj:SetActive(true)
        if p then
            self:upRight(p)
        end
    end
end

function taskList:initScrollView()
    self:setNowselect(nil)
    self.ScrollView:removeAllItem()
    local _i = 0
    for k,v in pairs(self.mainMission) do
        if self:finedTittle(k) then
            _i = _i + 1
            local _obj = self.ScrollView:addItemMenu(k)
            local _view = CS.SGK.UIReference.Setup(_obj)
            local _selectType = _view.Button.selectType
            local _arrow = _view.Button.arrow.transform
            local _tab = self.mainMission[k]
            _view.name[UI.Text].text = _tab.name
            _selectType:SetActive(false)
            _arrow:DOLocalRotate(Vector3(0, 0, 0), 0.05)
            CS.UGUIClickEventListener.Get(_view.Button.gameObject).onClick = function()
                if _selectType.activeSelf then
                    self.ScrollView:removeSecondItem(k)
                    _selectType:SetActive(false)
                    _arrow:DOLocalRotate(Vector3(0, 0, 0),0.2)
                else
                    local _status = false
                    for j,p in pairs(self.nowList) do
                        if p.status == 0 or (self.nowType == self.Type.PickUpTask and v.status ~= 0) then
                            local _type = p.type
                            if p.type == 2 then
                                _type = p.bountyType
                            end
                            local _tempTab = activityConfig.GetActivity(_type)
                            if _tempTab and _tempTab.up_tittle2 == k then
                                local _scObj = self.ScrollView:addSecondItem(k)
                                local _viewObj = CS.SGK.UIReference.Setup(_scObj)
                                _viewObj.Button.Text[UI.Text].text = p.name
                                CS.UGUIClickEventListener.Get(_viewObj.Button.gameObject).onClick = function()
                                    self:setNowselect(_viewObj.Button.bg.gameObject, p)
                                    self:upRight(p)
                                end
                                if not _status then
                                    self:setNowselect(_viewObj.Button.bg.gameObject, p)
                                end
                                _status = true
                            end
                        end
                    end
                    if _status then
                        _selectType:SetActive(true)
                        _arrow:DOLocalRotate(Vector3(0, 0, 180),0.2)
                    end
                end
            end
        end
    end
    self.view.taskListRoot.abandon.gameObject:SetActive(self.nowType == self.Type.NowTask)
    if self.nowType == self.Type.NowTask then
        self.noPickUp.gameObject:SetActive(false)
        self.noTask.gameObject:SetActive(_i == 0)
    elseif self.nowType == self.Type.PickUpTask then
        self.noTask.gameObject:SetActive(false)
        self.noPickUp.gameObject:SetActive(_i == 0)
    end
end

function taskList:initRewardScrollView()
    local _itemI = SGK.ResourcesManager.Load("prefabs/base/ItemIcon.prefab")
    local _item = CS.UnityEngine.GameObject.Instantiate(_itemI)
    local _rect = _item:GetComponent(typeof(UnityEngine.RectTransform))
    _item.gameObject.transform.localScale = Vector3(0.5, 0.5, 0.5)
    _rect.pivot = CS.UnityEngine.Vector2(0, 1)
    _item:AddComponent(typeof(CS.UIMultiScrollIndex))
    _item:SetActive(false)

    self.rewardScrollView = self.view.taskListRoot.rewardScrollView[CS.UIMultiScroller]
    self.rewardScrollView.itemPrefab = _item
    self.rewardScrollView.RefreshIconCallback = (function (obj,idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.rewardTab[idx+1]
        local _itemCfg = ItemHelper.Get(_tab.type, _tab.id, nil, _tab.value)
        _view[SGK.ItemIcon]:SetInfo(_itemCfg)
        obj.gameObject:SetActive(true)
    end)
end

function taskList:initRight()
    self.taskName = self.view.taskListRoot.name.key[UI.Text]
    self.taskDec = self.view.taskListRoot.name.value[UI.Text]
    self.decValue = self.view.taskListRoot.dec.value[UI.Text]
end

function taskList:initFirstRight()
    for j,p in pairs(self.mainMission) do
        for k,v in pairs(self.nowList) do
            if v.status == 0 or (self.nowType == self.Type.PickUpTask and v.status ~= 0) then
                local _tempTab = activityConfig.GetActivity(v.type)
                if _tempTab and _tempTab.up_tittle2 == j then
                    if v and v.name then
                        self:upRight(v)
                        return
                    end
                end
            end
        end
    end
end

function taskList:upRight(cfg)
    local _name = cfg.name
    for i,v in ipairs(self.cityContuctId) do
        if cfg.type == v and self.nowType == self.Type.NowTask then
            local info = module.QuestModule.CityContuctInfo();
            _name = _name.."("..(info.round_index+1).."/".."10)"
        end
    end
    self.view.taskListRoot.abandon:SetActive(true)
    if self.nowType == self.Type.PickUpTask then
        self.view.taskListRoot.abandon:SetActive(false)
    else
        self.view.taskListRoot.abandon:SetActive(not (cfg.type == 2 or cfg.type == 10))
    end
    -- if cfg.type == 2 then
    --     local teamInfo = module.TeamModule.GetTeamInfo()
    --     self.view.taskListRoot.abandon:SetActive(teamInfo.id <= 0 or module.playerModule.Get().id == teamInfo.leader.pid)
    -- end

    self.taskName.text = _name or ""
    self.taskDec.text = cfg.desc or ""
    self.decValue.text = cfg.desc2 or ""
    self.rewardTab = cfg.reward or {}
    self.rewardScrollView.DataCount = #self.rewardTab
    self.nowSelectCfg = cfg
    for i,v in ipairs(self.cityContuctId) do
        if cfg.type == v and self.nowType == self.Type.NowTask then
            for i = 1, 2 do
                if cfg.condition[i].type == 2 then
                    self.taskDec.text = self.taskDec.text.."("..cfg.records[i].."/"..cfg.condition[i].count..")"
                    return
                end
            end
        end
    end
end

function taskList:initBtn()
    CS.UGUIClickEventListener.Get(self.view.taskListRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.taskListRoot.abandon.gameObject).onClick = function()
        print("放弃任务")
        if self.nowSelectCfg then
            module.QuestModule.Cancel(self.nowSelectCfg.uuid)
        end
    end
    CS.UGUIClickEventListener.Get(self.view.taskListRoot.transfer.gameObject).onClick = function()
        print("马上传送")
        if self.nowSelectCfg then
            local teamInfo = module.TeamModule.GetTeamInfo();
            if teamInfo.group == 0 or module.playerModule.Get().id == teamInfo.leader.pid then
                --不在一个队伍中或自己为队长
                module.QuestModule.StartQuestGuideScript(self.nowSelectCfg, self.nowType == self.Type.PickUpTask)
                --module.QuestModule.SetOldUuid(self.nowSelectCfg.uuid)
            end
        end
    end

    for i = 1, 2 do
        local _item = self.view.taskListRoot.btnToggle[i][UI.Toggle]
        _item.onValueChanged:AddListener(function ( value )
            if value then
                if i == 1 then
                    self.nowType = self.Type.NowTask
                else
                    self.nowType = self.Type.PickUpTask
                end
                self:initScrollView()
                self:initFirstRight()
            end
        end)
    end
end

function taskList:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function taskList:onEvent(event, ...)
    if event == "QUEST_INFO_CHANGE" then
        self:initScrollView()
        self:initFirstRight()
    end
end

return taskList
