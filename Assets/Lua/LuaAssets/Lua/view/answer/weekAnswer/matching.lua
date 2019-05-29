local answerModule = require "module.answerModule"
local ItemHelper= require"utils.ItemHelper"
local timeModule = require "module.Time"

local matching = {}

function matching:Start(data)
    self:initData(data)
    self:initUi()
end

function matching:initData(data)
    self.index = data and data.index or 1
    self.queryTypeFlag = false
end

function matching:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initScrollView()
    self:initTop()
    self:initBtn()
end

function matching:initTop()
    self.matchingText = self.view.matchingRoot.matchingText.gameObject
end

function matching:initBtn()
    CS.UGUIClickEventListener.Get(self.view.matchingRoot.matchingBtn.gameObject).onClick = function()
        if self.queryTypeFlag then
            self.matchingText:SetActive(true)
            DispatchEvent("LOCAL_WEEKANSWER_MATCHING_START", {index = 1, time = timeModule.now()})
            answerModule.Matching(self.index or 1)
            self.view.matchingRoot.matchingBtn:SetActive(false)
            self.view.matchingRoot.unMatchingBtn:SetActive(true)
        else
            showDlgError(nil, "请先选择题目类型")
        end
    end
    CS.UGUIClickEventListener.Get(self.view.matchingRoot.unMatchingBtn.gameObject).onClick = function()
        self.matchingText:SetActive(false)
        DispatchEvent("LOCAL_WEEKANSWER_MATCHING_STOP")
        answerModule.CancelMatch()
        self.view.matchingRoot.matchingBtn:SetActive(true)
        self.view.matchingRoot.unMatchingBtn:SetActive(false)
    end
end

function matching:OnDestroy()
    if self.view.matchingRoot.unMatchingBtn.activeSelf and not answerModule.GetTeamStatus() then
        answerModule.CancelMatch()
        showDlgError(nil, "匹配已取消，请重新匹配")
    end
end

function matching:initScrollView()
    self.ScrollView = self.view.matchingRoot.ScrollView[CS.UIMultiScroller]
    self.ScrollView.RefreshIconCallback = function (obj,idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = answerModule.GetWeekReward()[idx + 1]
        utils.IconFrameHelper.Create(_view.IconFrame, {id = _tab.id, type = _tab.type, showDetail = true, count = _tab.value})
        obj.gameObject:SetActive(true)
    end
    self.ScrollView.DataCount = #answerModule.GetWeekReward()
end

function matching:listEvent()
    return {
        "LOCAL_WEEKANSWER_TYPEID_CHANGE",
    }
end

function matching:onEvent(event, data)
    if event == "LOCAL_WEEKANSWER_TYPEID_CHANGE" then
        self.index = data
        self.queryTypeFlag = true
    end
end

return matching
