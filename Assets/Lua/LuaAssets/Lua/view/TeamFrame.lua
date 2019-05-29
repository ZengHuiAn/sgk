local TeamModule = require "module.TeamModule"
local EncounterFightModule = require "module.EncounterFightModule"
local playerModule = require "module.playerModule"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	-- self.view.Group[1][1][CS.UGUIClickEventListener].onClick = function ( ... )
	-- 	local teamInfo = module.TeamModule.GetTeamInfo()--获取当前自己的队伍
	-- 	if teamInfo.id > 0 then
	-- 		self.view.Group[1][UnityEngine.UI.Toggle].isOn = true
	-- 		self.view.Group[1].Label[UI.Text].color = {r=89/255,g=57/255,b=16/255,a=1}
	-- 		self.view.Group[2][UnityEngine.UI.Toggle].isOn = false
	-- 		self.view.Group[2].Label[UI.Text].color = {r=202/255,g=174/255,b=111/255,a=1}
	-- 		self:loadFrameview(1)
	-- 	else
	-- 		showDlgError(nil,"请先创建一个队伍")
	-- 	end
	-- end
	-- self.view.Group[2][1][CS.UGUIClickEventListener].onClick = function ( ... )
	-- 	self.view.Group[1][UnityEngine.UI.Toggle].isOn = false
	-- 	self.view.Group[1].Label[UI.Text].color = {r=202/255,g=174/255,b=111/255,a=1}
	-- 	self.view.Group[2][UnityEngine.UI.Toggle].isOn = true
	-- 	self.view.Group[2].Label[UI.Text].color = {r=89/255,g=57/255,b=16/255,a=1}
	-- 	self:loadFrameview(2)
	-- end
	local teamInfo = TeamModule.GetTeamInfo()--获取当前自己的队伍
	if teamInfo.id <= 0 then
		self.view.Group[1].Image[UI.Image].color = {r=255/255,g=255/255,b=255/255,a=0.5}
	end
	self.index = data and data.idx or 1
    if not utils.SGKTools.GetTeamState() then
        self.index = 2
    end
	for i = 1,#self.view.Group do
		self.view.Group[i][1][CS.UGUIClickEventListener].onClick = function ( ... )
			if i == 1 then
				teamInfo = TeamModule.GetTeamInfo()
				if teamInfo.id <= 0 then
					showDlgError(nil,"请先创建一个队伍")
					return
				end
			end
			self:ToggleChange(i)
		end
	end
	self.view.Dialog.Close[CS.UGUIClickEventListener].onClick = function ( ... )
		--DispatchEvent("KEYDOWN_ESCAPE")
		DialogStack.Pop()
		--DialogStack.CleanAllStack()
	end
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		--DispatchEvent("KEYDOWN_ESCAPE")
		DialogStack.Pop()
		--DialogStack.CleanAllStack()
	end
	self.view.Group[self.index][UnityEngine.UI.Toggle].isOn = true
	self.view.Group[self.index].select:SetActive(true)
	--self.view.Group[self.index].Label[UI.Text].color = {r=89/255,g=57/255,b=16/255,a=1}
	self.viewDatas = data and data.viewDatas or {}
	self.viewFrameArr = {}
	self:loadFrameview(self.index)
	--self:MyTeamChange()
	TeamModule.getTeamInvite()
	-----------------------------------------------------------------------------------
	self:JoinRequestChange()
	--self:INVITE_REF()
	self.view.Group[3]:SetActive(true)
	self.view.Group[5]:SetActive(false)
end
function View:loadFrameview(idx)
	self.viewFrameArr[self.index] = DialogStack.GetPref_list(self.viewFrameArr[self.index])
	if self.viewFrameArr[self.index] and self.index ~= idx then
		--self.viewFrameArr[self.index]:SetActive(false)
		self.viewDatas[self.index] = nil
		self.savedValues.viewDatas = self.viewDatas
		UnityEngine.GameObject.Destroy(self.viewFrameArr[self.index])
		self.viewFrameArr[self.index] = nil
	end
	self.index = idx
	self.savedValues.index = self.index
	if self.viewFrameArr[self.index] and self.viewFrameArr[self.index].gameObject then
		self.viewFrameArr[self.index]:SetActive(true)
	else
		if self.index == 1 then
			self.view.Dialog.Title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_wodeduiwu_01")--"<size=40>我</size>的队伍"
			self.viewFrameArr[self.index] = "MyTeamFrame"
			DialogStack.PushPref("MyTeamFrame",self.viewDatas[self.index],self.view.gameObject)
		elseif self.index == 2 then
			self.view.Dialog.Title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_chazhaoduiwu_01")--"<size=40>查</size>找队伍"
			self.viewFrameArr[self.index] = "SmallTeamDungeon"
			DialogStack.PushPref("SmallTeamDungeon",self.viewDatas[self.index],self.view.gameObject)
			--TeamModule.TEAM_AFK_REQUEST()
		elseif self.index == 3 or self.index == 4 or self.index == 5 then
			if self.index == 3 then
				self.view.Dialog.Title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_duiwushenqing_01")--"<size=40>队</size>伍申请"
			elseif self.index == 4 then
				self.view.Dialog.Title[UI.Text].text = "<size=40>队</size>伍邀请"
			elseif self.index == 5 then
				self.view.Dialog.Title[UI.Text].text = "<size=40>邀</size>请入会"
			end
			if not self.viewDatas[self.index] then
				self.viewDatas[self.index] = {Type = self.index-2}
			end
			self.viewFrameArr[self.index] = "TeamApplyFrame"
			DialogStack.PushPref("TeamApplyFrame",self.viewDatas[self.index],self.view.gameObject)
			--TeamModule.TEAM_AFK_RESPOND()
		else
			ERROR_LOG("索引错误_> ",self.index)
		end
	end
end
function View:JoinRequestChange()
    local waiting = TeamModule.GetTeamWaitingList(3)
    local count = 0
    for k, v in pairs(waiting) do
        count = count + 1
    end
    local teamInfo = TeamModule.GetTeamInfo();
    local applyBtn = false
    if count > 0 and teamInfo.leader.pid == playerModule.Get().id then
        applyBtn = true
    end
    self.view.Group[3].reddot:SetActive(applyBtn)
end
function View:INVITE_REF()
    --查询玩家邀请列表
    local teamInfo = TeamModule.GetTeamInfo();
    if teamInfo.group == 0 or (teamInfo.group ~= 0 and module.playerModule.GetSelfID() ~= teamInfo.leader.pid)then
        self.view.Group[4]:SetActive(#TeamModule.getTeamInvite()>0)
    end
end
function View:onEvent(event, data)
	if event == "team_toggle_change" then
		if data then
			self:ToggleChange(data)
		end
		-- if data == 1 then

		-- else
		-- 	self.view.Group[1][UnityEngine.UI.Toggle].isOn = false
		-- 	-- self.view.Group[1].Label[UI.Text].color = {r=202/255,g=174/255,b=111/255,a=1}
		-- 	self.view.Group[2][UnityEngine.UI.Toggle].isOn = true
		-- 	-- self.view.Group[2].Label[UI.Text].color = {r=89/255,g=57/255,b=16/255,a=1}
		-- 	self:loadFrameview(2)
		-- end
	elseif event == "TEAM_JOIN_REQUEST_CHANGE" or event == "JOIN_CONFIRM_REQUEST" or event == "delApply_succeed" then
        --队伍申请列表变化通知 or 审批玩家申请 or 拒绝玩家申请
        self:JoinRequestChange()
    elseif event == "TEAM_PLAYER_QUERY_INVITE_REQUEST" or event == "TEAM_PLAYER_INVITE_LIST_CHANGE" then
        --查询邀请列表返回 or 邀请列表更新通知
        --self:INVITE_REF()
    elseif event == "TEAM_INFO_CHANGE" then
    	self:MyTeamChange()
	end
end
function View:MyTeamChange()
	local teamInfo = TeamModule.GetTeamInfo();
	if teamInfo.id <= 0 then--没有队伍
		self.view.Group[1].Image[UI.Image].color = {r=255/255,g=255/255,b=255/255,a=0.5}
		if self.index == 3 then--申请队伍
			self:ToggleChange(4)
		end
		self.view.Group[3]:SetActive(false)
		self.view.Group[4]:SetActive(true)
	else
		self.view.Group[1].Image[UI.Image].color = {r=255/255,g=255/255,b=255/255,a=1}
		if self.index == 4 then--邀请队伍
			self:ToggleChange(3)
		end
		self.view.Group[3]:SetActive(true)
		self.view.Group[4]:SetActive(false)
	end
end
function View:ToggleChange(i)
	if self.index then
		self.view.Group[self.index][UnityEngine.UI.Toggle].isOn = false
		self.view.Group[self.index].select:SetActive(false)
	end
	self.view.Group[i][UnityEngine.UI.Toggle].isOn = true
	self.view.Group[i].select:SetActive(true)
	self:loadFrameview(i)
end
function View:listEvent()
    return {
    "team_toggle_change",
    "TEAM_JOIN_REQUEST_CHANGE",
    "JOIN_CONFIRM_REQUEST",
    "delApply_succeed",
    "TEAM_PLAYER_QUERY_INVITE_REQUEST",
    "TEAM_PLAYER_INVITE_LIST_CHANGE",
    "TEAM_INFO_CHANGE",
}
end
return View
