local answerModule = require "module.answerModule"
local timeModule = require "module.Time"
local weekAnswerFrame = {}

function weekAnswerFrame:Start()
    self:initData()
    self:initUi()
end

function weekAnswerFrame:moveUI()
    self.view.weekAnswerFrameRoot.infoBtn[UnityEngine.RectTransform].anchoredPosition=UnityEngine.Vector2(-300,455);
    self.view.weekAnswerFrameRoot.top.Dropdown[UnityEngine.RectTransform].anchoredPosition=UnityEngine.Vector2(-86,424);
    --print("2222222222222222wo",self.view.weekAnswerFrameRoot.bg.top[UnityEngine.RectTransform].anchoredPosition);
    self.view.weekAnswerFrameRoot.top.bg[UnityEngine.RectTransform].anchoredPosition=UnityEngine.Vector2(-29,62);
    self.view.weekAnswerFrameRoot.top.label[UnityEngine.RectTransform].anchoredPosition=UnityEngine.Vector2(-157,-63);
    self.view.weekAnswerFrameRoot.bg.tip[UnityEngine.RectTransform].anchoredPosition=UnityEngine.Vector2(-60,422);
    self.view.weekAnswerFrameRoot.bg.tip.tipText[UI.Text].text="我的出题类型";
    self.view.weekAnswerFrameRoot.bg.Bg:SetActive(false);
    self.view.weekAnswerFrameRoot.top.timeBg:SetActive(true);
end

function weekAnswerFrame:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.weekAnswerFrameRoot.top.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.weekAnswerFrameRoot.infoBtn.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("dati_shuoming_02"), SGK.Localize:getInstance():getValue("dati_shuoming_01"))
    end
    self:initTop()
end

function weekAnswerFrame:initTop()
    self.dialogNode = self.view.dialogNode
    self.timeLab = self.view.weekAnswerFrameRoot.top.label.value[UI.Text]
    self.topTipLab = self.view.weekAnswerFrameRoot.top.label.key[UI.Text]
    self.nowDialog = nil
    self:initDropdown()

    if not answerModule.GetTeamStatus() then
        self.nowDialog = "answer/weekAnswer/matching"
        DialogStack.PushPref("answer/weekAnswer/matching", {index = self.dropdown.value + 1}, self.dialogNode)
    else
        self:moveUI()
        self.nowDialog = "answer/weekAnswer/weekAnswer"
        DialogStack.PushPref("answer/weekAnswer/weekAnswer", nil, self.dialogNode)

    end
    --DialogStack.PushPrefStact("answer/weekAnswer/weekRanking", nil, self.dialogNode)
end

function weekAnswerFrame:changeType(i)
    if answerModule.GetTeamStatus() then
        answerModule.NextQueryType(i + 1)
    end
    self.view.weekAnswerFrameRoot.top.bg.questionType[UI.Text]:TextFormat(answerModule.QuestTypeTab[i + 1])
    DispatchEvent("LOCAL_WEEKANSWER_TYPEID_CHANGE", i + 1)
end

function weekAnswerFrame:initDropdown()
    self.dropdown = self.view.weekAnswerFrameRoot.top.Dropdown[CS.UnityEngine.UI.Dropdown]
    if answerModule.GetNowLocalInfo().selectIndex then
        self.dropdown.value = answerModule.GetNowLocalInfo().selectIndex
        self.view.weekAnswerFrameRoot.top.bg.questionType[UI.Text]:TextFormat(answerModule.QuestTypeTab[answerModule.GetNowLocalInfo().selectIndex + 1])
        self.firstChange = false
        DispatchEvent("LOCAL_WEEKANSWER_TYPEID_CHANGE", answerModule.GetNowLocalInfo().selectIndex + 1)
    end
    CS.UGUIClickEventListener.Get(self.dropdown.gameObject).onClick = function()
        if self.firstChange then
            self:changeType(0)
            self.firstChange = false
        end
    end
    CS.UGUIClickEventListener.Get(self.view.weekAnswerFrameRoot.top.matchingMask.gameObject, true).onClick = function()
        showDlgError(nil, SGK.Localize:getInstance():getValue("dati_tips_06"))
    end
    self.dropdown.onValueChanged:AddListener(function (i)
        self:changeType(i)
        answerModule.GetNowLocalInfo().selectIndex = i
    end)
end

function weekAnswerFrame:initData()
    self.timeTab = {
        {dec = "匹配计时", add = true},
        {dec = "阅读剩余时间"},
        {dec = "答题剩余时间"},
    }
    self.answerTime = 30
    self.firstChange = true
end

function weekAnswerFrame:upTime()
    if not self.view.weekAnswerFrameRoot.top.label.gameObject.activeSelf then
        return
    end
    if not self.timeIndex or not self.timeTab[self.timeIndex] or not self.timeNow then
        return
    end

    local _time = nil
    if self.timeTab[self.timeIndex].add then
        _time = timeModule.now() - self.timeNow
    else
        _time = self.timeNow - timeModule.now()
    end

    self.view.weekAnswerFrameRoot.top.label.value:SetActive(_time >= 0)

    if _time < 0 then
        if answerModule.GetWeekQueryInfo().nextTime then
            self:upTimeIndex(3, answerModule.GetWeekQueryInfo().nextTime + self.answerTime)
        end
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
    self.timeLab.text = _hours..":".._minutes..":".._seconds
end

function weekAnswerFrame:Update()
    self:upTime()
end

function weekAnswerFrame:listEvent()
    return {
        "LOCAL_WEEKANSWER_MATCHING_OK",
        "LOCAL_WEEKANSWER_MATCHING_START",
        "LOCAL_WEEKANSWER_MATCHING_STOP",
        "LOCAL_WEEKANSWER_QUERYINFO_CHANGE",
        "LOCAL_WEEKANSWER_OVER",
        "server_respond_17024",
        "server_respond_17026",
    }
end

function weekAnswerFrame:upTimeIndex(index, time)
    self.timeIndex = index
    self.timeNow = time
    if index then
        self.topTipLab.text = self.timeTab[index].dec
    end
end

function weekAnswerFrame:onEvent(event, data)
    if event == "LOCAL_WEEKANSWER_MATCHING_OK" then
        self.nowDialog = DialogStack.GetPref_list(self.nowDialog)
        if self.nowDialog then
            CS.UnityEngine.GameObject.Destroy(self.nowDialog)
        end
        self:upTimeIndex(2, answerModule.GetWeekQueryInfo().nextTime)
        self.nowDialog = "answer/weekAnswer/weekAnswer"
        self.view.weekAnswerFrameRoot.top.matchingMask:SetActive(false)
        self:moveUI()
        DialogStack.PushPref("answer/weekAnswer/weekAnswer", nil, self.dialogNode)
    elseif event == "LOCAL_WEEKANSWER_MATCHING_START" then
        self:upTimeIndex(data.index, data.time)
        self.view.weekAnswerFrameRoot.top.label.gameObject:SetActive(true)
    elseif event == "LOCAL_WEEKANSWER_MATCHING_STOP" then
        self:upTimeIndex(nil, nil)
        self.view.weekAnswerFrameRoot.top.label.gameObject:SetActive(false)
    elseif event == "LOCAL_WEEKANSWER_QUERYINFO_CHANGE" then
        self.view.weekAnswerFrameRoot.top.label.gameObject:SetActive(true)
        if answerModule.GetWeekQueryInfo().nextTime - timeModule.now() < 0 then
            self:upTimeIndex(3, answerModule.GetWeekQueryInfo().nextTime + self.answerTime)
        else
            self:upTimeIndex(2, answerModule.GetWeekQueryInfo().nextTime)
        end
    elseif event == "LOCAL_WEEKANSWER_OVER" then
        self.nowDialog = DialogStack.GetPref_list(self.nowDialog)
        if self.nowDialog then
            UnityEngine.GameObject.Destroy(self.nowDialog)
        end
        DialogStack.Pop()
        DialogStack.Push("answer/weekAnswer/weekRanking")
    elseif event == "server_respond_17024" then
        self.view.weekAnswerFrameRoot.top.matchingMask:SetActive(true)
    elseif event == "server_respond_17026" then
        self.view.weekAnswerFrameRoot.top.matchingMask:SetActive(false)
    end
end

function weekAnswerFrame:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return weekAnswerFrame
