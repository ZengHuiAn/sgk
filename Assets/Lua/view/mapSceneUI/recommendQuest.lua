local activityConfig = require "config.activityConfig"
local MapConfig = require "config.MapConfig"
local DialogCfg = require "config.DialogConfig"

local recommendQuest = {}

function recommendQuest:Start()
    self.upDateTime = 0
    self.idx = 1
    self.lastUpTime = 0
    self:initData()
    self:initUi()
end

function recommendQuest:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:upUi()
end

function recommendQuest:upGuideNode()
    self.view.guideRoot.guideNode:SetActive(false)
end

function recommendQuest:upOtherQuestList()
    if not self.showFlag then
        return
    end
    self.view.otherQuestRoot:SetActive(false)
    for i,v in pairs(module.QuestModule.GetList()) do
        if v.mapId and v.mapId == SceneStack.MapId() then
            self.view.otherQuestRoot.quest.desc[UI.Text].text = v.desc
            CS.UGUIClickEventListener.Get(self.view.otherQuestRoot.quest.gameObject).onClick = function()
                local teamInfo = module.TeamModule.GetTeamInfo();
                if teamInfo.group == 0 or module.playerModule.Get().id == teamInfo.leader.pid then
                    module.QuestModule.StartQuestGuideScript(v)
                else
                    showDlgError(nil,"你正在队伍中，无法进行该操作")
                end
            end
            self.view.otherQuestRoot:SetActive(true)
            return
        end
    end
end

function recommendQuest:initData()
    self.mapCfg = MapConfig.GetMapConf(SceneStack.MapId())
    self.showFlag = true
    local _tab = BIT(self.mapCfg.Uishow or 0)
    for i,v in ipairs(_tab) do
        if tonumber(v) == 1 and i == 6 then
            self.showFlag = false
        end
    end
    self:upData()
end

function recommendQuest:upData()
    self.questCfg = module.QuestRecommendedModule.GetRecommend(1)
    if self.questCfg then
        self.nowQuestCfg = module.QuestRecommendedModule.GetQuest(self.questCfg.id)
    end
    self.questTime = module.QuestRecommendedModule.GetRecommend(2) or {}
    if self.questTime[self.idx] then
        self.activeCfg = activityConfig.GetActivity(self.questTime[self.idx].quest_type)
    else
        self.activeCfg = nil
    end
    self:getTimeBossCfg()
end

function recommendQuest:getTimeBossCfg()
    self.bossList = {}
    self.timeBossCfg = nil
    for i,v in pairs(module.QuestModule.GetList(105)) do
        table.insert(self.bossList, v)
    end
    table.sort(self.bossList, function(a, b)
        return a.id < b.id
    end)
    for i,v in ipairs(self.bossList) do
        local _quest = module.QuestModule.Get(v.id)
        if _quest and _quest.status == 0 then
            self.timeBossCfg = _quest
            return
        end
    end
    self.timeBossCfg = self.bossList[1]
end

function recommendQuest:upActiveTime()
--    ERROR_LOG("activeCfg==========>>>",sprinttb(self.activeCfg))
--     for i,v in ipairs(self.questTime) do
--         ERROR_LOG("questTime==========>>>",i,sprinttb(v))
--     end
    
    if self.activeCfg then
        if self.questTime[self.idx].quest_type == 3000 then
            if self.timeBossCfg then
                local _time = (self.timeBossCfg.accept_time + self.timeBossCfg.extrareward_timelimit) - module.Time.now()
                if _time > 0 then
                    if _time > 3600 then
                        self.view.guideRoot.taskTimeItem.dec[UI.Text].text = SGK.Localize:getInstance():getValue("xianshitiaozhan_08", GetTimeFormat(_time, 2))
                    else
                        self.view.guideRoot.taskTimeItem.dec[UI.Text].text = SGK.Localize:getInstance():getValue("xianshitiaozhan_08", GetTimeFormat(_time, 2, 2))
                    end
                else
                    self.view.guideRoot.taskTimeItem.dec[UI.Text].text = self.questTime[self.idx].des
                end
            end
        else
            local total_pass = module.Time.now() - self.activeCfg.begin_time
            local period_pass = total_pass - math.floor(total_pass / self.activeCfg.period) * self.activeCfg.period
            local period_begin = 0
            if period_pass >= self.activeCfg.loop_duration then
                period_begin = self.activeCfg.begin_time + math.ceil(total_pass / self.activeCfg.period) * self.activeCfg.period
            else
                period_begin = self.activeCfg.begin_time + math.floor(total_pass / self.activeCfg.period) * self.activeCfg.period
            end
            local _offTime = period_begin - module.Time.now()
            if _offTime > 0 then
                self.view.guideRoot.taskTimeItem.dec[UI.Text].text = os.date("%H:%M开启", self.activeCfg.begin_time)
            else
                local _endTime = _offTime + self.activeCfg.loop_duration
                if _endTime > 0 then
                    if _endTime > 3600 then
                        self.view.guideRoot.taskTimeItem.dec[UI.Text].text = SGK.Localize:getInstance():getValue("xianshitiaozhan_09", GetTimeFormat(_endTime, 2))
                    else
                        self.view.guideRoot.taskTimeItem.dec[UI.Text].text = SGK.Localize:getInstance():getValue("xianshitiaozhan_09", GetTimeFormat(_endTime, 2, 2))
                    end
                else
                    self.view.guideRoot.taskTimeItem.dec[UI.Text].text = self.questTime[self.idx].des
                end
            end
        end
    end
end

function recommendQuest:showQuest()
    return false
end

function recommendQuest:showActivity()
    if #self.questTime > 0 then
        local _questCfg = self.questTime[self.idx]
        local _view = self.view.guideRoot.taskTimeItem
        _view.name[UI.Text].text = _questCfg.name
        _view.dec[UI.Text].text = _questCfg.des
        _view.icon.tip.Text[UI.Text].text = tostring(#self.questTime)
        _view.icon.tip:SetActive(#self.questTime > 1)
        local _tab = activityConfig.GetActivity(_questCfg.quest_type)
        CS.UGUIClickEventListener.Get(_view.icon.gameObject).onClick = function()
            self.view.guideRoot.timeIcon:SetActive(not self.view.guideRoot.timeIcon.activeSelf)
            for i = 1, #self.view.guideRoot.timeIcon.bg do
                local _iconQuest = self.questTime[i]
                self.view.guideRoot.timeIcon.bg[i]:SetActive(_iconQuest and true)
                if self.view.guideRoot.timeIcon.bg[i].activeSelf then
                    self.view.guideRoot.timeIcon.bg[i].Image[UI.Image]:LoadSprite(_iconQuest.icon)
                end
                CS.UGUIClickEventListener.Get(self.view.guideRoot.timeIcon.bg[i].gameObject).onClick = function()
                    self.idx = i
                    self:showActivity()
                    self:upActiveTime()
                    self.view.guideRoot.timeIcon:SetActive(false)
                end
            end
            if  #self.questTime>3 then
                self.view.guideRoot.timeIcon.bg:SetActive(false)
                self.view.guideRoot.timeIcon.ScrollView:SetActive(true)
                self.scrollView = self.view.guideRoot.timeIcon.ScrollView[CS.UIMultiScroller]
                self.scrollView.RefreshIconCallback = function(obj, i)
                    local _iconview = CS.SGK.UIReference.Setup(obj.gameObject)
                    local _cfg = self.questTime[i+1]
                    _iconview.Image[UI.Image]:LoadSprite(_cfg.icon)
                    _iconview:SetActive(true)
                    CS.UGUIClickEventListener.Get(_iconview.Image.gameObject).onClick=function()
                        self.idx=i+1
                        self:showActivity()
                        self:upActiveTime()
                        self.view.guideRoot.timeIcon:SetActive(false)
                    end
                end
                self.scrollView.DataCount = #self.questTime
            else
                self.view.guideRoot.timeIcon.bg:SetActive(true)
                self.view.guideRoot.timeIcon.ScrollView:SetActive(false)
            end
        end
        

        CS.UGUIClickEventListener.Get(_view.icon.gameObject).tweenStyle = 1
        _view.icon.image[UI.Image]:LoadSprite(_questCfg.icon)
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            -- if _questCfg.result_type == 1 then
            --     if SceneStack.GetBattleStatus() then
            --         showDlgError(nil, "战斗内无法进行该操作")
            --         return
            --     end
            --     if not utils.SGKTools.GetTeamState() or utils.SGKTools.isTeamLeader() then
            --         utils.SGKTools.Map_Interact(tonumber(_questCfg.result_count))
            --     else
            --         showDlgError(nil, "队伍内无法进行该操作")
            --     end
            -- elseif _questCfg.result_type == 2 then
            --     if _questCfg.id == 39 then
            --         local flag = module.answerModule.QueryInfo()
            --         if flag then
            --             DialogStack.Push(_questCfg.result_count)
            --             return
            --         end
            --     else
            --         DialogStack.Push(_questCfg.result_count)
            --     end
            -- elseif _questCfg.result_type == 3 then
            --     DialogStack.Push(_questCfg.result_count, {activityId = 2102})
            -- end
            local env = setmetatable({
                EnterMap = module.EncounterFightModule.GUIDE.EnterMap,
                Interact = module.EncounterFightModule.GUIDE.Interact,
                GetCurrentMapName = module.EncounterFightModule.GUIDE.GetCurrentMapName,
                GetCurrentMapID = module.EncounterFightModule.GUIDE.GetCurrentMapID,
            }, {__index=_G})
            local _luaFunc = loadfile("guide/strongerGuide.lua", "bt", env)
            if _luaFunc then
                _luaFunc({cfg = {guideValue = tonumber(_questCfg.result_count)}})
            end
        end
    end
    self.view.guideRoot.taskTimeItem.gameObject:SetActive(#self.questTime > 0)
end

function recommendQuest:upUi()
    self:upGuideNode()
    -- self.view.taskItem:SetActive(false)
    if self:showQuest() then
        self:showActivity()
        return
    end
    --[[
    if self.questCfg then
        local _view = self.view.taskItem
        _view.name[UI.Text].text = self.questCfg.name
        _view.dec[UI.Text].text = self.questCfg.des
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if self.questCfg.result_type then
                if self.questCfg.result_type == 1 then
                    if SceneStack.GetBattleStatus() then
                        showDlgError(nil, "战斗内无法进行该操作")
                        return
                    end
                    if not utils.SGKTools.GetTeamState() or utils.SGKTools.isTeamLeader() then
                        utils.SGKTools.Map_Interact(tonumber(self.questCfg.result_count))
                    else
                        showDlgError(nil, "队伍内无法进行该操作")
                    end
                elseif self.questCfg.result_type == 2 then
                    DialogStack.Push(self.questCfg.result_count)
                end
            end
        end
    end
    --]]
    self:showActivity()
end

function recommendQuest:showGuide(show)
    --self.view.taskItem.guide:SetActive(show)
end

function recommendQuest:OnEnable()
    self:upData()
    self:upUi()
    self:showGuide(module.QuestRecommendedModule.ShowGuide())
end

function recommendQuest:queryWaitTime()
    self:upData()
    self:upUi()
end

function recommendQuest:Update()
    local now = math.floor(UnityEngine.Time.timeSinceLevelLoad);
    if self.last_update_time == now then
        return;
    end
    self.last_update_time = now;
    self.upDateTime = self.upDateTime + UnityEngine.Time.deltaTime
    if self.upDateTime > 60 then
        self:queryWaitTime()
        self.upDateTime = 0
    end
    self:upActiveTime()
end

-- function recommendQuest:AcceptSideQuest()
--     if (module.Time.now() - self.lastUpTime) > 0.5 then
--         self.lastUpTime = module.Time.now()
--         module.QuestModule.AcceptSideQuest()
--     end
-- end


function recommendQuest:listEvent()
    return {
        "QUEST_INFO_CHANGE",
        "CITY_CONTRUCT_INFO_CHANGE",
        "ShowActorLvUp",
        "QUEST_LIST_CHANGE",
        "LOCAL_TASKLIST_GUIDE",
        "DrawCard_callback",
        "Activity_INFO_CHANGE",
        "LOCAL_TASKLIST_ARROW_CHANGE",
        "LOCAL_ANSWER_NOTINTIME",
    }
end

function recommendQuest:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" or event == "CITY_CONTRUCT_INFO_CHANGE" or event == "ShowActorLvUp" or event == "QUEST_LIST_CHANGE" then
        self:upData()
        self:upUi()
        --self:AcceptSideQuest()
    elseif event == "LOCAL_TASKLIST_GUIDE" then
        self:showGuide(data)
    elseif event == "Activity_INFO_CHANGE" then
        self:queryWaitTime()
    elseif event == "LOCAL_TASKLIST_ARROW_CHANGE" then
        self:upUi()
    elseif event == "LOCAL_ANSWER_NOTINTIME" then
        showDlgError(nil,SGK.Localize:getInstance():getValue("xinashi_tip1"))
    end
end


return recommendQuest
