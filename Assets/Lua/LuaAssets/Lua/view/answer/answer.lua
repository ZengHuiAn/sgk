local timeModule = require "module.Time"
local answerModule = require "module.answerModule"
local ItemHelper= require"utils.ItemHelper"
local ChatManager = require 'module.ChatModule'
local unionModule = require "module.unionModule"

local answer = {}

function answer:Start()
    answerModule.QueryInfo()
    self:initData()
    self:initUi()
    if answerModule.GetInfo().questionId then
        self:upTop()
        self:upMiddle()
        self:upBottom()
    end
end

function answer:initData()
    self.answerCount = 10
    self.haveHelpCount = 3
    self.lastId = 0
    self.lastRound = 0
    self.answerTab = {}
    self.helpTab = {}
    self:upData()
end

function answer:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.answerRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.answerRoot.infoBtn.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("dati_shuoming_12"), SGK.Localize:getInstance():getValue("dati_shuoming_11"))
    end
    self:initTop()
    self:initBottom()
end

function answer:upUi()
    self:playTip()
end

function answer:playTip()
     for i = 1, 3 do
        if self.lastId ~= 0 and self.lastRound ~= 0 then
            local _view = self.view.answerRoot.middle.allBtn[i]
            local _rightCfg = answerModule.GetCfg(self.lastId).rightAnswer[self.lastRound]
            local _cfg = answerModule.GetCfg(self.lastId).answer[self.lastRound][i]
            _view.results.gameObject:SetActive(self.lasstCfgId == _cfg.id)
            if _cfg.id == _rightCfg.id then
                _view.results.correct.gameObject:SetActive(true)
                _view.results.wrong.gameObject:SetActive(false)
            else
                _view.results.correct.gameObject:SetActive(false)
                _view.results.wrong.gameObject:SetActive(true)
            end
        end
    end
    self.view.answerRoot.middle.mask:SetActive(true)
    if self.lastId ~= 0 and self.lastRound ~= 0 then
        local _cfg = answerModule.GetCfg(self.lastId).rightAnswer[self.lastRound]
        if _cfg then
            self.view.answerRoot.correctAnswer.gameObject:SetActive(true)
            self.view.answerRoot.correctAnswer.correct.Text[UI.Text].text = _cfg.id..".".._cfg.answer
        end
    end
    StartCoroutine(function()
        if self.lastId ~= 0 and self.lastRound ~= 0 then
            WaitForSeconds(2)
        end
        self.view.answerRoot.middle.mask:SetActive(false)
        self.view.answerRoot.correctAnswer.gameObject:SetActive(false)
        self:upTop()
        self:upMiddle()
        self:upBottom()
    end)
end

function answer:initTop()
    self.accuracy = self.view.answerRoot.top.accuracy.value[UI.Text]
    self.time = self.view.answerRoot.top.time.value[UI.Text]
    self.expKey = self.view.answerRoot.top.exp.key[UI.Text]
    self.expNumber = self.view.answerRoot.top.exp.value[UI.Text]
    self.cumulativeNumb = self.view.answerRoot.top.gift.number[UI.Text]
    self.moneyNumber = self.view.answerRoot.top.money.value[UI.Text]
    self.moneyKey = self.view.answerRoot.top.money.key[UI.Text]
    self.question = self.view.answerRoot.top.question[UI.Text]
    self.timeObj = self.view.answerRoot.top.time.gameObject
    self.helpCountLab = self.view.answerRoot.bottom.helpNumber[UI.Text]
    self:initTopGiftBox()
end

function answer:initTopGiftBox()
    CS.UGUIClickEventListener.Get(self.view.answerRoot.top.gitftBox.gameObject).onClick = function()
        if self.finishCount == self.answerCount then
            if self.rewardFlag == 1 then
                showDlgError(nil, "已领取")
            else
                answerModule.Reward()
            end
        else
            showDlgError(nil, "无法领取")
        end
    end
end

function answer:finish()
    self.view.answerRoot.middle.finishText.gameObject:SetActive(true)
    self.view.answerRoot.middle.allBtn.gameObject:SetActive(false)
    self.view.answerRoot.top.question.gameObject:SetActive(false)
    self.view.answerRoot.bg.finishBg:SetActive(false)
    self.view.answerRoot.middle:SetActive(false)
    self.view.answerRoot.bottom:SetActive(false)
    self.view.answerRoot.finish:SetActive(true)
    self.timeObj:SetActive(false)
end

function answer:upTop()
    if self.finishCount ~= 0 and self.finishCount == self.answerCount then
        self:finish()
    end

    self.accuracy.text = self.correctCount.."/"..self.finishCount
    if self.rewardTab then
        if self.rewardTab[1] then
            local _exp = ItemHelper.Get(self.rewardTab[1][1], self.rewardTab[1][2])
            self.expKey.text = _exp.name
            self.cumulativeNumb.text = tostring(self.rewardTab[1][3])
        end
        if self.rewardTab[2] then
            local _money = ItemHelper.Get(self.rewardTab[2][1], self.rewardTab[2][2])
            self.moneyKey.text = _money.name
            self.moneyNumber.text = tostring(self.rewardTab[2][3])
        end
    end
    self.helpCountLab.text = self.haveCount.."/"..self.haveHelpCount
    self.question.text = (self.finishCount+1).."/"..self.answerCount..". "..self.cfg.dec.."("..self.round.."/"..self.cfg.count..")"
end

function answer:upMiddle()
    self.answerTab = {}
    for i = 1, 3 do
        local _view = self.view.answerRoot.middle.allBtn[i].info
        local _cfg = self.cfg.answer[self.round][i]
        if _cfg.icon ~= "0" then
            _view.pic.gameObject:SetActive(true)
            _view.label.gameObject:SetActive(false)
            _view.pic.newCharacterIcon:SetActive(true)
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
        table.insert(self.answerTab, _cfg.id.."、".._cfg.answer)
        self.view.answerRoot.middle.allBtn[i].results.gameObject:SetActive(false)
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            _view.transform:DOScale(Vector3(0.95,0.95,0.95),0.1):OnComplete(function( ... )
                _view.transform:DOScale(Vector3(1,1,1),0.1)
            end)
            if self.finishCount == self.answerCount then
                showDlgError(nil, "答题完成")
                return
            end
            if self.timeObj.activeSelf then
                self.lastId = self.questionId
                self.lastRound = self.round
                self.lasstCfgId = _cfg.id
                answerModule.Answer(self.questionId, _cfg.id)
            else
                showDlgError(nil, "时间到无法答题")
            end
        end
    end
end

function answer:upBottom()
    local _cfg = answerModule.GetCfg(self.questionId).rightAnswer
    for i = 1, 3 do
        local _view = self.view.answerRoot.bottom.allAnswerBtn[i]
        local _tempCfg = _cfg[self.round - i]
        if _tempCfg then
            _view.gameObject:SetActive(true)
            if _tempCfg.icon ~= "0" then
                utils.IconFrameHelper.Create(_view.newCharacterIcon, {customCfg={
                        icon    = _tempCfg.icon,
                        quality = 0,
                        star    = 0,
                        level   = 0,
                }, type = 42})
                _view.newCharacterIcon.gameObject:SetActive(true)
                _view.Text.gameObject:SetActive(false)
            else
                _view.Text[UI.Text].text = _tempCfg.answer
                _view.newCharacterIcon.gameObject:SetActive(false)
                _view.Text.gameObject:SetActive(true)
            end
        else
            _view.gameObject:SetActive(false)
        end
    end
end

function answer:initBottom()
    CS.UGUIClickEventListener.Get(self.view.answerRoot.bottom.help.gameObject).onClick = function()
        if self.helpTab[self.questionId] then
            showDlgError(nil, SGK.Localize:getInstance():getValue("dati_tips_01"))
            return
        end
        if self.finishCount == self.answerCount then
            showDlgError(nil, SGK.Localize:getInstance():getValue("dati_tips_02"))
            return
        end
        if not self.timeObj.activeSelf then
            showDlgError(nil, SGK.Localize:getInstance():getValue("dati_tips_03"))
            return
        end
        if self.haveHelpCount <= self.haveCount then
            showDlgError(nil, SGK.Localize:getInstance():getValue("dati_tips_04"))
            return
        end
        if unionModule.Manage:GetUionId() == 0 then
            showDlgError(nil, SGK.Localize:getInstance():getValue("dati_tips_05"))
            return
        end
        self.helpTab[self.questionId] = true
        answerModule.Help()
    end
end

function answer:upTime()
    if not self.timeObj.activeSelf then
        return
    end
    if not self.tiemDDD then self.tiemDDD = timeModule.now() + 100 end
    local _time = self.tiemDDD - timeModule.now()
    if _time < 0 then
        self:finish()
        self.timeObj:SetActive(false)
        return
    end
    local _minutes = 0
    local _hours = 0
    while(_time > 60) do
        _minutes = _minutes + 1
        _time = _time - 60
    end
    while (_minutes > 60) do
        _hours = _hours + 1
        _minutes = _minutes - 60
    end
    local _seconds, _s = math.modf(_time)
    if _hours < 10 then _hours = "0".._hours end
    if _minutes < 10 then _minutes = "0".._minutes end
    if _seconds < 10 then _seconds = "0".._seconds end
    self.time.text = _hours..":".._minutes..":".._seconds
end

function answer:Update()
    self:upTime()
end

function answer:upData()
    self.questionId = answerModule.GetInfo().questionId or 1
    self.cfg = answerModule.GetCfg(self.questionId)
    self.finishCount = answerModule.GetInfo().finishCount or 0
    self.round = answerModule.GetInfo().round or 1
    self.correctCount = answerModule.GetInfo().correctCount or 0
    self.correct = answerModule.GetInfo().correct
    self.tiemDDD = answerModule.GetInfo().deadline
    self.rewardFlag = answerModule.GetInfo().rewardFlag
    self.rewardTab = answerModule.GetInfo().reward
    self.haveCount = answerModule.GetInfo().helpCount or 0
end

function answer:listEvent()
    return {
        "LOCAL_ANSWER_INFO_CHANGE",
        "LOCAL_ANSWER_HELP_OK",
        "LOCAL_ANSWER_REWARD_OK",
        "LOCAL_ANSWER_NOTINTIME"
    }
end

function answer:callHelp()
    local _text = "\n"
    for i,v in ipairs(self.answerTab) do
        _text = _text.." "..v
    end
    ChatManager.ChatMessageRequest(3, "#答题求助# "..self.cfg.dec.._text)
end

function answer:onEvent(event, ...)
    print(event)
    if event == "LOCAL_ANSWER_INFO_CHANGE" then
        self:upData()
        self:upUi()
    elseif event == "LOCAL_ANSWER_HELP_OK" then
        self:upData()
        self:upTop()
        self:callHelp()
    elseif event == "LOCAL_ANSWER_REWARD_OK" then
        self:upData()
        self:upTop()
    elseif event == "LOCAL_ANSWER_NOTINTIME" then
        showDlgError(nil, "不在答题时间")
        DialogStack.Pop()
    end
end

function answer:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return answer
