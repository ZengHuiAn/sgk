local unionModule = require "module.unionModule"
local unionConfig = require "config.unionConfig"
local playerModule = require "module.playerModule"
local timeModule = require "module.Time"

local newUnionList = {}

function newUnionList:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self:initBottom()
    self:initRight()
    self:initScrollView()
end

function newUnionList:Update()
    if self.nextTime and self.nextTime.activeSelf then
        if self.cdTime then
            local _time = self.cdTime - timeModule.now()
            if _time < 0 then
                self.nextTime:SetActive(false)
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
            self.nextCdTime.text = _hours..":".._minutes..":".._seconds
        end
    end
end

function newUnionList:initCdTime()
    self.nextTime = self.view.root.bottom.nextTime
    self.nextCdTime = self.view.root.bottom.nextTime.time[UI.Text]
    if unionModule.Manage:GetUionId() == 0 then
        unionModule.queryPlayerUnioInfo(playerModule.GetSelfID(),(function ( ... )
            self.cdTime = unionModule.GetPlayerUnioInfo(playerModule.GetSelfID()).unfreezeTime
            if self.cdTime and self.cdTime ~= 0 then
                self.nextTime:SetActive(true)
            else
                self.nextTime:SetActive(false)
            end
        end))
    else
        self.nextTime:SetActive(false)
    end
end

function newUnionList:initBottom()
    self:initCdTime()
    CS.UGUIClickEventListener.Get(self.view.root.bottom.createUnion.gameObject).onClick = function()
        if unionModule.Manage:GetUionId() ~= 0 then
            showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_02"))
            return
        end
        DialogStack.PushPrefStact("newUnion/newUnionCreate")
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.joinUnion.gameObject).onClick = function()
        if unionModule.Manage:GetUionId() ~= 0 then
            showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_02"))
            return
        end
        if self.selectUnionIndex == 0 then
            showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_01"))
            return
        end
        unionModule.Join(self.selectUnionIndex)
    end
    CS.UGUIClickEventListener.Get(self.view.root.explainBtn.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("juntuan_shuoming_02"), SGK.Localize:getInstance():getValue("juntuan_shuoming_01"))
    end
end

function newUnionList:initData()
    self.Manage = unionModule.Manage
    self.unionTab = self.Manage:GetTopUnion()
    self.index = 0
    self.selectUnionIndex = 0
end

function newUnionList:upScrollView()
    local _index = #self.unionTab - (self.index * 10)
    if _index > 10 then
        _index = 10
    end
    self.scrollView.DataCount = (_index or 0)
    self.view.root.right.IconFrame:SetActive(self.scrollView.DataCount > 0)
    self.view.root.right.desc:SetActive(self.scrollView.DataCount > 0)
end

function newUnionList:showSelect(_view, _tab)
    if self.lastUnionIndex then
        self.lastUnionIndex:SetActive(false)
    end
    self.lastUnionIndex = _view.mask
    self.lastUnionIndex:SetActive(true)
    self.desc.text = _tab.notice
    self.selectUnionIndex = _tab.unionId

    utils.IconFrameHelper.Create(self.view.root.right.IconFrame, {pid = _tab.leaderId})
    self.view.root.right.name[UI.Text].text = _tab.leaderName

    -- utils.PlayerInfoHelper.GetPlayerAddData(_tab.leaderId, 99, function (playerAddData)
    --     self.view.root.right.newCharacterIcon[SGK.newCharacterIcon].headFrame = playerAddData.HeadFrame
    --     self.view.root.right.newCharacterIcon[SGK.newCharacterIcon].sex = playerAddData.Sex
    -- end)
    -- if playerModule.IsDataExist(_tab.leaderId) then
    --     local _id = playerModule.IsDataExist(_tab.leaderId).head
    --     if _id == 0 then _id = 11000 end
    --     self.heroIcon.icon = tostring(_id)
    --     self.heroIcon.level = playerModule.IsDataExist(_tab.leaderId).level
    -- else
    --     playerModule.Get(_tab.leaderId,(function( ... )
    --         local _id = playerModule.IsDataExist(_tab.leaderId).head
    --         if _id == 0 then _id = 11000 end
    --         self.heroIcon.icon = tostring(_id)
    --         self.heroIcon.level = playerModule.IsDataExist(_tab.leaderId).level
    --     end))
    -- end
end

function newUnionList:initScrollView()
    self.scrollView = self.view.root.left.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.unionTab[idx+(self.index*10)+1]

        _view.rank[UI.Text].text = tostring(_tab.rank)
        _view.name[UI.Text].text = _tab.unionName
        _view.level[UI.Text].text = tostring(_tab.unionLevel)
        _view.member[UI.Text].text = _tab.mcount.."/"..(unionConfig.GetNumber(_tab.unionLevel).MaxNumber + _tab.memberBuyCount)
        _view.leaderName[UI.Text].text = _tab.leaderName
        _view.hook:SetActive(_tab.joining == 1)

        if idx == 0 and not self.lastUnionIndex then
            self:showSelect(_view, _tab)
        end

        CS.UGUIClickEventListener.Get(_view.gameObject, true).onClick = function()
            self:showSelect(_view, _tab)
        end
        obj:SetActive(true)
    end
    self:upListNumb()
    CS.UGUIClickEventListener.Get(self.view.root.left.bottom.left.gameObject).onClick = function()
        if self.index > 0 then
            self.index = self.index - 1
            self:upListNumb()
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.left.bottom.right.gameObject).onClick = function()
        if self.index + 1 < (#self.unionTab/10) then
            self.index = self.index + 1
            self:upListNumb()
        end
    end
end

function newUnionList:upListNumb()
    self.view.root.right.leader:SetActive(#self.unionTab > 0)
    self.view.root.nothing:SetActive(#self.unionTab == 0)
    
    self.view.root.left.bottom.number[UI.Text].text = (self.index+1).."/"..math.ceil(#self.unionTab/10)
    self:upScrollView()
end

function newUnionList:Start()
    self:initData()
    self:initUi()
    self:initGuide()
end

function newUnionList:changeFindUnion()
    self.index = 0
    if self.lastUnionIndex then
        self.lastUnionIndex:SetActive(false)
    end
    self.lastUnionIndex = nil
    self.unionTab = self.Manage:GetFindUnion()
    self:upListNumb()
    self.view.root.returnBtn:SetActive(true)
end

function newUnionList:initRight()
    self.inputField = self.view.root.right.InputField[UI.InputField]
    --self.heroIcon = self.view.root.right.newCharacterIcon[SGK.newCharacterIcon]
    self.desc = self.view.root.right.desc.desc[UI.Text]
    CS.UGUIClickEventListener.Get(self.view.root.right.findBtn.gameObject).onClick = function()
        if self.inputField.text == "" then
            showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_03"))
            return
        end
        unionModule.FindUnion(self.inputField.text)
    end
    CS.UGUIClickEventListener.Get(self.view.root.returnBtn.gameObject).onClick = function()
        if self.lastUnionIndex then
            self.lastUnionIndex:SetActive(false)
        end
        self.lastUnionIndex = nil
        self.unionTab = self.Manage:GetTopUnion()
        self:upListNumb()
        self.view.root.returnBtn:SetActive(false)
    end
end

function newUnionList:initGuide()
    module.guideModule.PlayByType(126,0.2)
end

function newUnionList:listEvent()
    return {
        "CONTAINER_UNION_LIST_CHANGE",
        "LOCAL_UNION_FINDUNION",
        "LOCAL_UNION_JOINOVER",
        "LOCAL_GUIDE_CHANE",
    }
end

function newUnionList:onEvent(event, data)
    if event == "CONTAINER_UNION_LIST_CHANGE" then
        self.unionTab = self.Manage:GetTopUnion()
        self:upListNumb()
    elseif event == "LOCAL_UNION_FINDUNION" then
        self:changeFindUnion()
    elseif event == "LOCAL_UNION_JOINOVER" then
        self.scrollView:ItemRef()
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    end
end

function newUnionList:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return newUnionList
