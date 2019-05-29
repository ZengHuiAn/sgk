local activityConfig = require"config.activityConfig"

local mapSceneTaskList = {}

function mapSceneTaskList:Start()
    self.lastUpTime = 0
    self:initData()
    self:initUi()
    self.updateTime = 0.5
    self:AcceptSideQuest()
end

function mapSceneTaskList:upData()
    local _tab = module.QuestModule.GetList()
    local _accept = 0
    local _recommend = 0
    self.taskList = {}
    if module.guideModule.GetFirstQuestFlag() then
        module.guideModule.GetFirstQuestFlag(false)
        local _quest = module.QuestModule.Get(100002)
        if _quest and _quest.status == 0 then
            LoadStory(10000211, function()
                utils.MapHelper.ClearGuideCache(9901)
                utils.MapHelper.PlayGuide(9901, 0.2)
            end)
        end
    end
    local questCfg = module.QuestRecommendedModule.GetRecommend(1)
    self.nowQuestCfg = nil
    if questCfg then
        self.nowQuestCfg = module.QuestRecommendedModule.GetQuest(questCfg.id)
    end
    for k,v in pairs(_tab) do
        if v.status == 0 and (v.name or (v.cfg and v.cfg.name)) then
            if v.is_show_on_task == 0 then
                if v.accept_time then
                    if v.accept_time > _accept then
                        self.lastQuest = v
                        _accept = v.accept_time
                    end
                end
                if self.nowQuestCfg and self.nowQuestCfg.id == v.id then

                else
                    table.insert(self.taskList, v)
                end
            end
        end
    end
    table.sort(self.taskList, function(a, b)
        local _a = module.QuestModule.GetQuestSequenceCfg(a.type)
        if not _a then
            _a = {sequence = 100}
        end
        local _b = module.QuestModule.GetQuestSequenceCfg(b.type)
        if not _b then
            _b = {sequence = 100}
        end
        return _a.sequence < _b.sequence
    end)
    self.showGuideId = self:showGuide()
end

function mapSceneTaskList:initData()
    self:upData()
end

function mapSceneTaskList:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initScrollView()
    self:initBtn()
    if utils.UserDefault.Load("TaskListState", true).state and (#self.itemTab > 0 or self.nowQuestCfg) then
        --self:upShowTaskList()
        local _recommend = self.view.mapSceneTaskListRoot.ScrollView.recommend
        if self.itemTab and #self.itemTab <= 0 and not self.nowQuestCfg then
            self.view.mapSceneTaskListRoot.recommend.arrow.close[CS.UGUISpriteSelector].index = 1
            DispatchEvent("LOCAL_TASKLIST_ARROW_CHANGE", false)
            self.view.transform:DOLocalMove(Vector3(0, 0, 0), 0):OnComplete(function()
                self.view.mapSceneTaskListRoot.recommend.arrow.Image.transform:DOLocalRotate(Vector3(0, 0, 90), 0)
            end)
            self.view.mapSceneTaskListRoot.ScrollView:SetActive(false)
            utils.UserDefault.Load("TaskListState", true).state = true
        else
            self.view.mapSceneTaskListRoot.recommend.arrow.close[CS.UGUISpriteSelector].index = 0
            DispatchEvent("LOCAL_TASKLIST_ARROW_CHANGE", true)
            self.view.transform:DOLocalMove(Vector3(-134, 0, 0), 0):OnComplete(function()
                self.view.mapSceneTaskListRoot.recommend.arrow.Image.transform:DOLocalRotate(Vector3(0, 0, -90), 0)
            end)
            self.view.mapSceneTaskListRoot.ScrollView:SetActive(true)
            utils.UserDefault.Load("TaskListState", true).state = true
        end
    end
end

function mapSceneTaskList:hideTaskList()
    self.view.mapSceneTaskListRoot.recommend.arrow.close[CS.UGUISpriteSelector].index = 1
    DispatchEvent("LOCAL_TASKLIST_ARROW_CHANGE", false)
    self.view.transform:DOLocalMove(Vector3(50, 0, 0), 0):OnComplete(function()
        self.view.mapSceneTaskListRoot.recommend.arrow.Image.transform:DOLocalRotate(Vector3(0, 0, 90), 0)
    end)
    self.view.mapSceneTaskListRoot.ScrollView:SetActive(false)
end

function mapSceneTaskList:upShowTaskList()
    local _recommend = self.view.mapSceneTaskListRoot.ScrollView.recommend
    if self.itemTab and #self.itemTab <= 0 and not self.nowQuestCfg then
        self.view.mapSceneTaskListRoot.recommend.arrow.close[CS.UGUISpriteSelector].index = 1
        DispatchEvent("LOCAL_TASKLIST_ARROW_CHANGE", false)
        self.view.transform:DOLocalMove(Vector3(0, 0, 0),0.2):OnComplete(function()
            self.view.mapSceneTaskListRoot.recommend.arrow.Image.transform:DOLocalRotate(Vector3(0, 0, 90), 0.2)
        end)
        self.view.mapSceneTaskListRoot.ScrollView:SetActive(false)
        utils.UserDefault.Load("TaskListState", true).state = true
    else
        self.view.mapSceneTaskListRoot.recommend.arrow.close[CS.UGUISpriteSelector].index = 0
        DispatchEvent("LOCAL_TASKLIST_ARROW_CHANGE", true)
        self.view.transform:DOLocalMove(Vector3(-134, 0, 0),0.2):OnComplete(function()
            self.view.mapSceneTaskListRoot.recommend.arrow.Image.transform:DOLocalRotate(Vector3(0, 0, -90), 0.2)
        end)
        self.view.mapSceneTaskListRoot.ScrollView:SetActive(true)
        utils.UserDefault.Load("TaskListState", true).state = true
    end
end

function mapSceneTaskList:initScrollView()
    self.scrollViewContent = self.view.mapSceneTaskListRoot.ScrollView.Viewport.Content.gameObject.transform
    self.item = self.view.mapSceneTaskListRoot.taskItem
    self:upScrollView()
    if utils.UserDefault.Load("TaskListState", true).scrollViewMoveY then
        self.scrollViewContent:DOLocalMove(Vector3(self.scrollViewContent.localPosition.x, utils.UserDefault.Load("TaskListState", true).scrollViewMoveY, self.scrollViewContent.localPosition.z), 0.2)
    else
        SGK.Action.DelayTime.Create(1):OnComplete(
        function()
            self:moveToGuide()
        end)
    end
end

function mapSceneTaskList:showGuide()
    local _tab = {}
    for i,v in ipairs(self.taskList) do
        _tab[i] = v
    end
    table.sort(_tab, function(a, b)
        local _a = a.accept_time or 0
        local _b = b.accept_time or 0
        if _a == _b then
            return a.uuid < a.uuid
        end
        return _a > _b
    end)
    if _tab[1] then
        if _tab[1].type == 10 then
            if _tab[1].condition[1].type == 1 then
                local _Herolevel = module.HeroModule.GetManager():Get(11000) or {level = 1}
                if _Herolevel.level < _tab[1].condition[1].count then
                    DispatchEvent("LOCAL_TASKLIST_GUIDE", true)
                    return nil
                end
            end
        end
        DispatchEvent("LOCAL_TASKLIST_GUIDE", false)
        return _tab[1].id
    end
    DispatchEvent("LOCAL_TASKLIST_GUIDE", true)
end

function mapSceneTaskList:utf8sub(size, input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local _count = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        if i ~= 1 then
            _count = _count + i
        else
            cnt = cnt + 1
        end
        if (cnt + _count) >= size then
            return string.sub(input, 1, cnt + _count)
        end
    end
    return input;
end

function mapSceneTaskList:getLastMainQuest()
    local _list = module.QuestModule.GetList(10, 1)
    table.sort(_list, function(a, b)
        return a.uuid > b.uuid
    end)
    return _list[1]
end

function mapSceneTaskList:canShowActivityCfg(idx, cfg)
    local _questType = StringSplit(cfg.quest_type, "|")
    --local _questType = {}
    if idx == 1 then
        for i,v in ipairs(_questType) do
            local _list = module.QuestModule.GetList(tonumber(v), 0)
            if _list and #_list > 0 then
                return false
            end
        end
        return true
    elseif idx == 2 then
        local _list = module.QuestModule.GetList()
        for i,v in ipairs(_questType) do
            for k,p in pairs(_list) do
                if p.bountyId == tonumber(v) and p.status == 0 then
                    return false
                end
            end
        end
        return true
    end
end

function mapSceneTaskList:activityQuest(_cfg)
    if _cfg.depend_quest_id and _cfg.depend_quest_id ~= 0 then
        local _questCfg = module.QuestModule.Get(_cfg.depend_quest_id)
        if not _questCfg or (_questCfg and _questCfg.status ~= 1) then
            return false
        end
    end
    return true
end

function mapSceneTaskList:Update()
    if self.updateTime and self.updateTime > 0 then
        self.updateTime = self.updateTime - UnityEngine.Time.deltaTime
        if self.updateTime <= 0 then
            self.updateTime = 0.5
            for i,v in ipairs(self.itemTab or {}) do
                if v.cfg.time_limit and v.cfg.time_limit ~= 0 then
                    self:upDesc(v.obj, v.cfg)
                end
            end
        end
    end
end

function mapSceneTaskList:upDesc(obj, _tab)
    local _view = CS.SGK.UIReference.Setup(obj).root
    _view.dec[UI.Text].text = self:utf8sub(36*2, _tab.desc)
    _view.icon[UI.Image].sprite = SGK.ResourcesManager.Load("icon/"..(_tab.icon or "bg_rw_4") .. ".png",  typeof(UnityEngine.Sprite))
    for j,k in ipairs({41, 42, 43, 44}) do
        if _tab.type == k then
            for i = 1, 2 do
                if _tab.condition and _tab.condition[i].type == 2 then
                    if module.QuestModule.GetOtherRecords(_tab, i) >= _tab.condition[i].count then
                        _view.dec[UI.Text].text = _view.dec[UI.Text].text.."("..module.QuestModule.GetOtherRecords(_tab, i).."/".._tab.condition[i].count..")"
                    else
                        _view.dec[UI.Text].text = _view.dec[UI.Text].text.."("..module.QuestModule.GetOtherRecords(_tab, i).."/".._tab.condition[i].count..")"
                    end
                end
            end
        end
    end
    if _tab.type == 60 or _tab.type == 11 then
        for i = 1, 1 do
            if _tab.condition[i].count ~= 0 and _tab.condition[i].type ~= 1 then
                if module.QuestModule.CanSubmit(_tab.id) then
                    _view.dec[UI.Text].text = _view.dec[UI.Text].text.."("..module.QuestModule.GetOtherRecords(_tab, i).."/".._tab.condition[i].count..")"
                else
                    _view.dec[UI.Text].text = _view.dec[UI.Text].text.."("..module.QuestModule.GetOtherRecords(_tab, i).."/".._tab.condition[i].count..")"
                end
            end
        end
    end
    if _tab.time_limit and _tab.time_limit ~= 0 and _tab.status == 0 then
        local _endTime = _tab.accept_time + _tab.time_limit
        local _off = _endTime - module.Time.now()
        if _off >= 0 then
            if _off > 10 then
                _view.dec[UI.Text].text = SGK.Localize:getInstance():getValue("renwu_liebiao_10_bai", GetTimeFormat(_off, 2))
            else
                _view.dec[UI.Text].text = SGK.Localize:getInstance():getValue("renwu_liebiao_10_hong", GetTimeFormat(_off, 2))
            end
        else
            local _quest = module.QuestModule.Get(_tab.id)
            _quest.status = 2
            DispatchEvent("QUEST_INFO_CHANGE")
        end
    end
end

function mapSceneTaskList:upScrollView()
    if self.itemTab then
        for k,v in pairs(self.itemTab) do
            UnityEngine.GameObject.Destroy(v.obj.gameObject)
        end
    end
    self.itemTab = {}
    for k,v in ipairs(self.taskList) do
        local _obj = CS.UnityEngine.GameObject.Instantiate(self.item.gameObject, self.scrollViewContent)
        local _view = CS.SGK.UIReference.Setup(_obj).root
        local _tab = v
        local _name = _tab.name
        local _activityCfg = activityConfig.GetActivity(1)
        local _questType = StringSplit(_activityCfg.quest_type, "|")
        if _questType then
            for i,v in ipairs(_questType) do
                if _tab.type == tonumber(v) then
                    local info = module.QuestModule.CityContuctInfo();
                    _name = _name.."("..(info.round_index+1).."/".."10)"
                    break
                end
            end
        end
        if _tab.show_item_type and _tab.show_item_type ~= 0 then
            _view.newItemIcon:SetActive(true)
            utils.IconFrameHelper.Create(_view.newItemIcon, {type = _tab.show_item_type, id = _tab.show_item_id, count = 0})
        else
            _view.newItemIcon:SetActive(false)
        end
        _obj.name = self.item.gameObject.name.._tab.uuid
        _view.name[UI.Text].text = utils.SGKTools.GetQuestColor(_tab.icon, _name)

        self:upDesc(_obj, _tab)

        local _nameLevel = ""
        for i = 1, 2 do
            if _tab.condition then
                if _tab.condition[i].type == 1 then
                    if _tab.condition[i].id == 1 then
                        local _Herolevel = module.HeroModule.GetManager():Get(11000) or {level = 1}
                        if _Herolevel.level < _tab.condition[i].count then
                            _nameLevel = "(".._tab.condition[i].count..")"
                        end
                    end
                end
            end
        end
        if _tab.id == 103012 or _tab.id == 102143 then
            if _tab.condition[2].count ~= 0 and _tab.condition[2].type ~= 1 then
                if module.QuestModule.CanSubmit(_tab.id) then
                    _view.dec[UI.Text].text = _view.dec[UI.Text].text.."(".._tab.records[2].."/".._tab.condition[2].count..")"
                else
                    _view.dec[UI.Text].text = _view.dec[UI.Text].text.."(".._tab.records[2].."/".._tab.condition[2].count..")"
                end
            end
        end
        _view.name[UI.Text].text = _view.name[UI.Text].text.._nameLevel
        _view.guide:SetActive(self.showGuideId == _tab.id)
        _view.recommend:SetActive(_tab.type == 50)
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            local teamInfo = module.TeamModule.GetTeamInfo();
            if teamInfo.group == 0 or module.playerModule.Get().id == teamInfo.leader.pid then
                --不在一个队伍中或自己为队长
                module.QuestModule.StartQuestGuideScript(_tab, _tab.type == 50);
            else
                showDlgError(nil,"你正在队伍中，无法进行该操作")
            end
        end
        _obj.gameObject:SetActive(true)
        table.insert(self.itemTab, {obj = _obj, idx = k, cfg = _tab})
    end
    for i,v in ipairs(self.itemTab) do
        v.obj.transform:SetSiblingIndex(#self.itemTab - v.idx)
    end
    --self:getActivityCfg()
end

function mapSceneTaskList:moveToGuide(isOnEnable)
    if #self.taskList < 3 then
        return
    end
    for i = 0, self.scrollViewContent.childCount - 1 do
        local _child = self.scrollViewContent:GetChild(i)
        if _child then
            local _view = CS.SGK.UIReference.Setup(_child.gameObject).root
            if _view.guide.activeSelf then
                if _view.activeSelf then
                    self.scrollViewContent.localPosition = Vector3(0, - (i) * 65, 0)
                    return
                end
            end
        end
    end
end

function mapSceneTaskList:initBtn()
    CS.UGUIClickEventListener.Get(self.view.mapSceneTaskListRoot.recommend.arrow.gameObject).onClick = function()
        if self.view.mapSceneTaskListRoot.ScrollView.activeSelf then
            self.view.mapSceneTaskListRoot.recommend.arrow.close[CS.UGUISpriteSelector].index = 1
            DispatchEvent("LOCAL_TASKLIST_ARROW_CHANGE", false)
            self.view.transform:DOLocalMove(Vector3(50, 0, 0),0.2):OnComplete(function()
                self.view.mapSceneTaskListRoot.recommend.arrow.Image.transform:DOLocalRotate(Vector3(0, 0, 90), 0.2)
            end)
        else
            self.view.mapSceneTaskListRoot.recommend.arrow.close[CS.UGUISpriteSelector].index = 0
            DispatchEvent("LOCAL_TASKLIST_ARROW_CHANGE", true)
            self.view.transform:DOLocalMove(Vector3(-134, 0, 0),0.2):OnComplete(function()
                self.view.mapSceneTaskListRoot.recommend.arrow.Image.transform:DOLocalRotate(Vector3(0, 0, -90), 0.2)
            end)
        end
        self.view.mapSceneTaskListRoot.ScrollView:SetActive(not self.view.mapSceneTaskListRoot.ScrollView.activeSelf)
        --utils.UserDefault.Load("TaskListState", true).state = self.view.mapSceneTaskListRoot.ScrollView.activeSelf
        utils.UserDefault.Load("TaskListState", true).state = true
    end

    CS.UGUIClickEventListener.Get(self.view.mapSceneTaskListRoot.find.gameObject).onClick = function()
        DialogStack.Push("mapSceneUI/newQuestList")
    end
end

function mapSceneTaskList:listEvent()
    return {
        "QUEST_INFO_CHANGE",
        "CITY_CONTRUCT_INFO_CHANGE",
        "ShowActorLvUp",
        "QUEST_LIST_CHANGE",
        "LOCAL_GUIDE_CHANE",
        "HIDE_TASK_LIST"
    }
end

function mapSceneTaskList:AcceptSideQuest()
    if (module.Time.now() - self.lastUpTime) > 2 then
        self.lastUpTime = module.Time.now()
        module.QuestModule.AcceptSideQuest()
    end
end

function mapSceneTaskList:onEvent(event, ...)
    if event == "QUEST_INFO_CHANGE" or event == "CITY_CONTRUCT_INFO_CHANGE" or event == "ShowActorLvUp" then
        self:AcceptSideQuest()
        self:upData()
        self:upScrollView()
        if utils.UserDefault.Load("TaskListState", true).state then
            self:upShowTaskList()
        end
        if not self.moveToGuideFlag then
            self.moveToGuideFlag = true
            SGK.Action.DelayTime.Create(1):OnComplete(
             function()
                self:moveToGuide()
                self.moveToGuideFlag = false
            end)
        end
    elseif event == "QUEST_LIST_CHANGE" then
        self:upShowTaskList()
    elseif event == "LOCAL_GUIDE_CHANE" then
        if ... == 9901 then
            self:upData()
            self:upScrollView()
        end
    elseif event == "HIDE_TASK_LIST" then
        self:hideTaskList();
    end
end

function mapSceneTaskList:OnDestroy()
    utils.UserDefault.Load("TaskListState", true).scrollViewMoveY = self.scrollViewContent.localPosition.y
end

function mapSceneTaskList:OnEnable()
    self:upData()
    self:upScrollView()
    --SGK.Action.DelayTime.Create(0.3):OnComplete(
    --function()
        --self:moveToGuide(true)
    --end)
    --self:upShowTaskList()
    self:AcceptSideQuest()
end

return mapSceneTaskList
