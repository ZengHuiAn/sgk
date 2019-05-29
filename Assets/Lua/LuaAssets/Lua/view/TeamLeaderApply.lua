local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule"
local NetworkService = require "utils.NetworkService"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local Time = require "module.Time"
local ActivityTeamlist = require "config.activityConfig"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.mask[UnityEngine.UI.Button].interactable then
			UnityEngine.GameObject.Destroy(self.gameObject)
		end
	end
	self.view.ExitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.mask[UnityEngine.UI.Button].interactable then
			UnityEngine.GameObject.Destroy(self.gameObject)
		end
	end
	self.view.NBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.NBtn[UnityEngine.UI.Button].interactable then
			TeamModule.TEAM_Leader_vote(0)
			self.view.mask[UnityEngine.UI.Button].interactable = true
		end
	end
	self.view.YBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.YBtn[UnityEngine.UI.Button].interactable then
			TeamModule.TEAM_Leader_vote(1)
		end
	end
	self.Data = data
	self:RefUI(data)
	self.EndTime = data.EndTime
	self.timeCD = math.floor(data.EndTime - Time.now())
	self.view.mask[UnityEngine.UI.Button].interactable = false
end
function View:Update()
	if self.gameObject and self.Data and self.view.time and self.timeCD then
		local time = math.floor(self.EndTime - Time.now())
		if time >= 0 then
			self.view.Slider[UnityEngine.UI.Image].fillAmount = time/self.timeCD
			self.view.time[UnityEngine.UI.Text].text = math.floor(self.EndTime - Time.now()).."s"
		else
			self.timeCD = nil
			self:verifyDesc()
			UnityEngine.GameObject.Destroy(self.gameObject)
		end
	end
end
function View:verifyDesc()
	local ys = ""
	local ns = ""
	local ot = ""
	local members = TeamModule.GetTeamMembers()
	local LeaderApply_list = TeamModule.GetLeaderApply_list()
	local index = 0
	for k,v in ipairs(members) do
		index = index + 1
		local desc = self.view.Grid[index].state[UnityEngine.UI.Text].text
		local is_ready = false
		for i = 1,#LeaderApply_list do
			if LeaderApply_list[i].pid == v.pid then
				if LeaderApply_list[i].agree == 1 then
					if ys ~= "" then
						ys = ys.."、"
					end
					ys = ys..v.name
				else
					if ns ~= "" then
						ns = ns.."、"
					end
					ns = ns..v.name
				end
				is_ready = true
				break
			end
		end
		if not is_ready then
			if ot ~= "" then
				ot = ot.."、"
			end
			ot = ot..v.name
		end
	end
	local desc = ""
	if ys ~= "" then
		desc = "<color=#FEBA01>"..ys.."</color> 已确认"
	end
	if ns ~= "" then
		if desc ~= "" then
			desc = desc..","
		end
		desc = desc.."<color=#FF410A>"..ns.."</color> 已拒绝"
	end
	if ot ~= "" then
		if desc ~= "" then
			desc = desc..","
		end
		desc = desc.."<color=#23FFE3>"..ot.."</color> 未投票"
	end
	showDlgError(nil,desc)
end
function View:RefUI(data)
	local teamInfo = TeamModule.GetTeamInfo();

	local pid = playerModule.GetSelfID();
	if teamInfo[pid] then
		return
	end

	local members = TeamModule.GetTeamMembers()
	local LeaderApply_list = TeamModule.GetLeaderApply_list()
	for i = 1,5 do
		self.view.Grid[i].gameObject:SetActive(false)
	end
	--print(sprinttb(members))
	local index = 0
	for k,v in ipairs(members) do
		if not teamInfo.afk_list[v.pid] then
			index = index + 1
			--local index = v.pos
			self.view.Grid[index].gameObject:SetActive(true)
			self.view.Grid[index].name[UnityEngine.UI.Text].text = v.name
			self.view.Grid[index].leader:SetActive(v.pid == teamInfo.leader.pid)
			local PLayerIcon = nil
			if self.view.Grid[index].icon.transform.childCount == 0 then
				PLayerIcon = IconFrameHelper.Hero({},self.view.Grid[index].icon)
			else
				local objClone = self.view.Grid[index].icon.transform:GetChild(0)
				PLayerIcon = SGK.UIReference.Setup(objClone)
			end
			PlayerInfoHelper.GetPlayerAddData(v.pid,99,function (addData)
				IconFrameHelper.UpdateHero({pid = v.pid,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
	 		end)
			self.view.Grid[index].state[UnityEngine.UI.Text].text = "<color=#23FFE3>待确认</color>"
			for i = 1,#LeaderApply_list do
				if LeaderApply_list[i].pid == v.pid then
					if LeaderApply_list[i].agree == 1 then
						self.view.Grid[index].state[UnityEngine.UI.Text].text = "<color=#FEBA01>已确认</color>"
					else
						self.view.Grid[index].state[UnityEngine.UI.Text].text = "<color=#FF410A>已拒绝</color>"
					end
					if v.pid == playerModule.Get().id then
						self.view.NBtn[UnityEngine.UI.Button].interactable = false
						self.view.YBtn[UnityEngine.UI.Button].interactable = false
					end
				end
			end
			if data.pid == v.pid then
				self.view.title[UI.Text].text = v.name.."申请队长"
			end
		end
	end
	
end
function View:onEvent(event,data) 
	if event == "NOTIFY_TEAM_VOTE" then
		self:RefUI(self.Data)
	elseif event == "NOTIFY_TEAM_VOTE_FINISH" then
		self.timeCD = nil
		self:verifyDesc()
		UnityEngine.GameObject.Destroy(self.gameObject)
	end
end
  
function View:listEvent()
    return {
    "NOTIFY_TEAM_VOTE",
    "NOTIFY_TEAM_VOTE_FINISH",
}
end
return View