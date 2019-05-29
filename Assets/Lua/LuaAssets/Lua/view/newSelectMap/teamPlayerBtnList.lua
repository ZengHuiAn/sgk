local teamPlayerBtnList = {}

function teamPlayerBtnList:Start(data)
    self:initData(data)
    self:initUi()
end

function teamPlayerBtnList:initData(data)
    self.pid = data.pid
    self.teamInfo = module.TeamModule.GetTeamInfo()
end

function teamPlayerBtnList:initTop()
    utils.IconFrameHelper.Create(self.view.bg.top.IconFrame, {pid = self.pid})
    self.view.bg.top.id[UI.Text].text = "ID: "..math.floor(self.pid)
    if module.playerModule.IsDataExist(self.pid) then
        self.view.bg.top.name[UI.Text].text = module.playerModule.IsDataExist(self.pid).name
    else
        playerModule.Get(self.pid,(function()
            self.view.bg.top.name[UI.Text].text = module.playerModule.IsDataExist(self.pid).name
        end))
    end

    utils.PlayerInfoHelper.GetPlayerAddData(self.pid, 99, function(addData)
        if addData and addData.PersonDesc then
            self.view.bg.top.signature.signatureLab[UI.Text]:TextFormat("签名:"..addData.PersonDesc)
        else
            self.view.bg.top.signature.signatureLab[UI.Text]:TextFormat("签名:")
        end
    end)
end

function teamPlayerBtnList:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self.selfPid = module.playerModule.GetSelfID()
    self.view.bg.itemGroup.leaveBy:SetActive(self.pid == self.selfPid)
    self.view.bg.itemGroup.addFriend:SetActive(self.pid ~= self.selfPid)
    self.view.bg.itemGroup.chat:SetActive(self.pid ~= self.selfPid)
    self.view.bg.itemGroup.leave:SetActive((self.pid ~= self.selfPid) and (self.teamInfo.leader.pid == self.selfPid))
    self.view.bg.itemGroup.handOver:SetActive((self.teamInfo.leader.pid == self.selfPid) and (self.pid ~= self.selfPid))
    self.view.bg.itemGroup.applyLeader:SetActive((self.teamInfo.leader.pid ~= self.selfPid) and (self.pid == self.teamInfo.leader.pid))
    self:initTop()
    self:initBtn()
end

function teamPlayerBtnList:initBtn()
    CS.UGUIClickEventListener.Get(self.view.bg.itemGroup.leaveBy.gameObject).onClick = function()
        module.TeamModule.KickTeamMember()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.bg.itemGroup.addFriend.gameObject).onClick = function()
        module.unionModule.AddFriend(self.pid)
    end
    CS.UGUIClickEventListener.Get(self.view.bg.itemGroup.chat.gameObject).onClick = function()
        DialogStack.Pop()
        DialogStack.Push("FriendSystemList",{idx = 1, viewDatas = {{pid = self.pid, name = module.playerModule.IsDataExist(self.pid).name}}})
    end
    CS.UGUIClickEventListener.Get(self.view.bg.itemGroup.leave.gameObject).onClick = function()
        module.TeamModule.KickTeamMember(self.pid)
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.bg.itemGroup.handOver.gameObject).onClick = function()
        local status = module.TeamModule.MoveHeader(self.pid)
        if status == 1 then
            showDlgError(nil, "对方处于暂离状态,不能移交队长")
        else
            DialogStack.Pop()
        end
    end
    CS.UGUIClickEventListener.Get(self.view.bg.itemGroup.applyLeader.gameObject).onClick = function()
        module.TeamModule.LeaderApplySend()
        DialogStack.Pop()
    end
end

return teamPlayerBtnList
