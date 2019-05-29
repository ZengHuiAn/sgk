local answerModule = require "module.answerModule"
local playerModule = require "module.playerModule"
local timeModule = require "module.Time"
local weekAnswer = {}

function weekAnswer:Start()
    self:initData()
    self:initUi()
end

function weekAnswer:initData()
    self.statusTab = {}
    self.addScoreTab = {}
    self:upData()
end

function weekAnswer:upData()
    self.teamInfo = answerModule.GetTeamInfo()
    self.queryInfo = answerModule.GetWeekQueryInfo()
    self.questId = self.queryInfo.queryId or 1
    self.round = self.queryInfo.round or 1
    self.queryRound = self.queryInfo.queryRound or 1
    self.cfg = answerModule.GetWeekCfg(self.questId)
    self.nextTime = self.queryInfo.nextTime
    self.answerStatus = false
    self.queryType = self.queryInfo.queryType or 1
    self.selectId = self.queryInfo.selectId or "ddd"
end

function weekAnswer:initMiddle()
    self.quest = self.view.weekAnswerRoot.middle.quest[UI.Text]
    self.questFrom = self.view.weekAnswerRoot.middle.questFrom[UI.Text]
    self:upMiddle()
end

function weekAnswer:upMiddle()
    local _name = ""
    if self.queryInfo.selectName then
        _name = self.queryInfo.selectName
    else
        if playerModule.IsDataExist(self.selectId) then
            _name = playerModule.IsDataExist(self.selectId).name
        else
            playerModule.Get(self.selectId,(function()
                _name = playerModule.IsDataExist(self.selectId).name
            end))
        end
    end
    self.quest.text = self.queryRound.."/".."15.".."<color=orange>"..answerModule.QuestTypeTab[answerModule.GetWeekQueryInfo().queryType].."</color>"..":"..self.cfg.dec
    
    self.questFrom:TextFormat("——该题目由<color=blue>{0}</color>玩家选择", _name)
    for i = 1, 3 do
        local _view = self.view.weekAnswerRoot.middle.allBtn[i]
        local _cfg = self.cfg.answer[self.round][i]
        if _cfg.icon ~= "0" then
            _view.pic.gameObject:SetActive(true)
            _view.label.gameObject:SetActive(false)
            utils.IconFrameHelper.Create(_view.pic.newCharacterIcon, {customCfg={
                    icon    = _cfg.icon,
                    quality = 0,
                    star    = 0,
                    level   = 0,
            }, type = 42})
            _view.pic.lab[UI.Text].text = _cfg.id.."、".._cfg.answer
        else
            _view.pic.gameObject:SetActive(false)
            _view.label.gameObject:SetActive(true)
            _view.label.text[UI.Text].text = _cfg.id.."、".._cfg.answer
        end
        _view.results.gameObject:SetActive(false)
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            _view.transform:DOScale(Vector3(0.95,0.95,0.95),0.1):OnComplete(function( ... )
                _view.transform:DOScale(Vector3(1,1,1),0.1)
            end)
            if _view.disable.gameObject.activeSelf then
                showDlgError(nil, "读题时间无法答题")
                return
            end
            if not self.answerStatus then
                self.lasstCfgId = _cfg.id
                answerModule.WeekAnswer(_cfg.id)
                self.answerStatus = true
            else
                showDlgError(nil, "此题已答")
            end
        end
    end
end

function weekAnswer:playTip()
    for i = 1, 3 do
        local _view = self.view.weekAnswerRoot.middle.allBtn[i]
        local _tab = self.cfg.rightAnswer[1]
        local _cfg = self.cfg.answer[self.round][i]
        _view.results.gameObject:SetActive(self.lasstCfgId == _cfg.id)
        if _cfg.id == _tab.id then
            _view.results.correct.gameObject:SetActive(true)
            _view.results.wrong.gameObject:SetActive(false)
        else
            _view.results.correct.gameObject:SetActive(false)
            _view.results.wrong.gameObject:SetActive(true)
        end
    end
    self.view.weekAnswerRoot.correctAnswer.gameObject:SetActive(true)
    if self.cfg.rightAnswer[1] then
        self.view.weekAnswerRoot.correctAnswer.correct.Text[UI.Text].text = self.cfg.rightAnswer[1].id.."、"..self.cfg.rightAnswer[1].answer
    end
end

function weekAnswer:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initMiddle()
    self:initScrollView()
    DispatchEvent("LOCAL_WEEKANSWER_QUERYINFO_CHANGE", true)
    for k,v in pairs(answerModule.GetPlayerStatus()) do
        self:setStatus(k, v)
    end
    if answerModule.GetWeekQueryInfo().nextTime - timeModule.now() < 0 then
        self:readTime(false)
    end
end

function weekAnswer:initScrollView()
    self.ScrollView = self.view.weekAnswerRoot.middle.ScrollView[CS.UIMultiScroller]
    self.ScrollView.RefreshIconCallback = function (obj,idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.teamInfo[idx+1]
        if _tab.name then
            _view.name[UI.Text].text = _tab.name
        else
            if playerModule.IsDataExist(_tab.id) then
                _view.name[UI.Text].text = playerModule.IsDataExist(_tab.id).name
            else
                playerModule.Get(_tab.id,(function( ... )
                    _view.name[UI.Text].text = playerModule.IsDataExist(_tab.id).name
                end))
            end
        end
        _view.score[UI.Text].text = tostring(_tab.score)
        _view.addScore[UI.Text].text ="+".._tab.addScore
        self.addScoreTab[idx+1] = _view.addScore
        self.statusTab[_tab.id] = _view.result
        _view.addScore.scoreIcon.num[CS.UGUISpriteSelector].index=_tab.addScore;
        obj.gameObject:SetActive(true)
    end
    self.ScrollView.DataCount = #self.teamInfo
end

function weekAnswer:showAddScore()

    for k,v in pairs(self.addScoreTab) do
        
        v[UnityEngine.CanvasGroup]:DOFade(1, 2):OnComplete(function()
            v[UnityEngine.CanvasGroup]:DOFade(0, 2)
        end)
    end
    self.view.weekAnswerRoot.correctAnswer.gameObject:SetActive(false)
end

function weekAnswer:readTime(type)
    for i = 1, 3 do
        local _view = self.view.weekAnswerRoot.middle.allBtn[i]
        _view.disable.gameObject:SetActive(type)
    end
end

function weekAnswer:setStatus(id, status)
    local _view = self.statusTab[id]
    if _view then
        _view.unknown.gameObject:SetActive(false)
        _view.right.gameObject:SetActive(false)
        _view.wrong.gameObject:SetActive(false)
        if not status then
            _view.unknown.gameObject:SetActive(true)
        elseif status == 1 then
            _view.right.gameObject:SetActive(true)
        elseif status == 0 then
            _view.wrong.gameObject:SetActive(true)
        end
    end
end

function weekAnswer:resetStatus()
    for k,v in pairs(self.statusTab) do
        self:setStatus(k)
    end
end

function weekAnswer:upTime()
    if not self.nextTime then return end

    local _time = self.nextTime - timeModule.now()
    if _time < 0 then
        if answerModule.GetTeamStatus() then
            if self.view.weekAnswerRoot.middle.allBtn[1].disable.activeSelf then
                self:readTime(false)
            end
        end
    end
end

function weekAnswer:Update()
    self:upTime()
end

function weekAnswer:listEvent()
    return {
        "LOCAL_WEEKANSWER_TEAMINFO_CHANGE",
        "LOCAL_WEEKANSWER_QUERYINFO_CHANGE",
        "LOCAL_WEEKANSWER_PLAYER_ANSWER_STATUS",
        "LOCAL_WEEKANSWER_ANSWER_OVER",
        "LOCAL_WEEKANSWER_SENDQUERY",
    }
end

function weekAnswer:onEvent(event, data)
    if event == "LOCAL_WEEKANSWER_TEAMINFO_CHANGE" then
        self:upData()
        self.ScrollView.DataCount = #self.teamInfo
        self:readTime(true)
        self:resetStatus()
    elseif event == "LOCAL_WEEKANSWER_QUERYINFO_CHANGE" then
        self:upData()
        self:upMiddle()
        self:readTime(true)
        if not data then
            self:resetStatus()
        else
            if answerModule.GetPlayerStatus()[playerModule.GetSelfID()] ~= nil then
                self:playTip()
                self.answerStatus = true
            end
        end
    elseif event == "LOCAL_WEEKANSWER_PLAYER_ANSWER_STATUS" then
        self:setStatus(data.id, data.status)
    elseif event == "LOCAL_WEEKANSWER_ANSWER_OVER" then
        self:playTip()
    elseif event == "LOCAL_WEEKANSWER_SENDQUERY" then
        self:showAddScore()
    end
end



return weekAnswer
