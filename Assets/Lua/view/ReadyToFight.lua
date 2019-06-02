local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule"
local NetworkService = require "utils.NetworkService"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local Time = require "module.Time"
local ActivityTeamlist = require "config.activityConfig"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local CemeteryConf = require "config.cemeteryConfig"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.IsReady = false
	self.ReadyType = 0

	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		--UnityEngine.GameObject.Destroy(self.gameObject)
		if self.view.mask[UnityEngine.UI.Button].interactable then
			--DispatchEvent("KEYDOWN_ESCAPE")
			UnityEngine.GameObject.Destroy(self.gameObject)
		end
	end
	self.view.ExitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--UnityEngine.GameObject.Destroy(self.gameObject)
		if self.view.mask[UnityEngine.UI.Button].interactable then
			--DispatchEvent("KEYDOWN_ESCAPE")
			UnityEngine.GameObject.Destroy(self.gameObject)
		end
	end
	self.view.NBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.NBtn[UnityEngine.UI.Button].interactable then
			TeamModule.PlayerReady(2,data.gid)
			self.view.mask[UnityEngine.UI.Button].interactable = true
		end
	end
	self.view.YBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.YBtn[UnityEngine.UI.Button].interactable then
			TeamModule.PlayerReady(1,data.gid)
		end
	end
	self.view.StartBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.StartBtn[UnityEngine.UI.Button].interactable then
			self.view.StartBtn[UnityEngine.UI.Button].interactable = false
			self.view.Grid.transform:DOScale(Vector3(1,1,1),0):SetDelay(1):OnComplete(function( ... )
				if self.ReadyType ~= 0 then
					if TeamModule.GetTeamInfo().leader.pid == playerModule.Get().id then
						NetworkService.Send(16070, {nil,self.ReadyType})
					end
				end
				UnityEngine.GameObject.Destroy(self.gameObject)
			end)
		end
	end
	local list = TeamModule.GetTeamMembers()
	self.TeamMembers = {}
	for i = 1,#list do
		self.TeamMembers[i] = list[i]
	end
	if data.gid then--强制改为就位确认
		data.gid = 0
	end
	self.Data = data
	self:RefUI(data)
	self:MemberReady()
	self.EndTime = data.EndTime
	self.timeCD = math.floor(data.EndTime - Time.now())
	-- local time = math.floor(data.EndTime - Time.now())
	-- self.view.Slider[UnityEngine.UI.Image]:DOFillAmount(0,time):OnComplete(function ( ... )
	-- 	self:verifyDesc()
	-- 	if not self.IsReady then
	-- 		TeamModule.PlayerReady(2,data.gid)
	-- 	end
	-- 	--self.view.mask[UnityEngine.UI.Button].interactable = true
	-- 	--DispatchEvent("KEYDOWN_ESCAPE")
	-- 	UnityEngine.GameObject.Destroy(self.gameObject)
	-- end)
	self.view.mask[UnityEngine.UI.Button].interactable = false
	local teamInfo = TeamModule.GetTeamInfo();
	if data.gid == 0 and playerModule.Get().id == teamInfo.leader.pid then
		--队长自动确认
		TeamModule.PlayerReady(1,data.gid)
	end
end
function View:Update()
	if self.gameObject and self.Data and self.view.time and self.timeCD then
		local time = math.floor(self.EndTime - Time.now())
		if time >= 0 then
			self.view.TimeProcess[UnityEngine.UI.Slider].value = time/self.timeCD
			self.view.time[UnityEngine.UI.Text].text = math.floor(self.EndTime - Time.now())
		else
			self.timeCD = nil
			self:verifyDesc()
			if not self.IsReady then
				TeamModule.PlayerReady(2,self.Data.gid)
			end
			UnityEngine.GameObject.Destroy(self.gameObject)
		end
	end
end
function View:verifyDesc()
--[[
	local ys = ""
	local ns = ""
	local ot = ""
	local members = self.TeamMembers
	local index = 0
	for k,v in ipairs(members) do
		index = index + 1
		local desc = self.view.Grid[index].state[UnityEngine.UI.Text].text
		if desc == "<color=#FEBA01>已确认</color>" then
			if ys ~= "" then
				ys = ys.."、"
			end
			ys = ys..v.name
		elseif desc == "<color=#FF410A>已拒绝</color>" then
			if ns ~= "" then
				ns = ns.."、"
			end
			ns = ns..v.name
		else
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
		desc = desc.."<color=#23FFE3>"..ot.."</color> 未确认"
	end
	showDlgError(nil,desc)
--]]
end
function View:RefUI(data)
	local teamInfo = TeamModule.GetTeamInfo();
	local members = self.TeamMembers
	for i = 1,5 do
		self.view.Grid[i].gameObject:SetActive(false)
	end
	--print(sprinttb(members))
	local index = 0
	for k,v in ipairs(members) do
		--print(k.."->"..tostring(v.is_ready))
		index = index + 1
		--local index = v.pos
		self.view.Grid[index].gameObject:SetActive(true)
		--self.view.Grid[index].lv[UnityEngine.UI.Text].text = tostring(v.level)
		self.view.Grid[index].name[UnityEngine.UI.Text].text = v.name
		--self.view.Grid[index].title[UnityEngine.UI.Text].text = v.pid == teamInfo.leader.pid and "队长" or "队员"
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
		self.view.Grid[index].state:SetActive(false) -- [UnityEngine.UI.Text].text = "<color=#23FFE3>待确认</color>"
		self.view.Grid[index].Gray:SetActive(true) -- [UnityEngine.UI.Text].text = "<color=#23FFE3>待确认</color>"
		self.view.Grid[index].name[UnityEngine.UI.Text].color = UnityEngine.Color(0, 0, 0, 0.7);
	end
	if data.gid ~= 0 and ActivityTeamlist.GetActivity(teamInfo.group) then
		self.view.title[UnityEngine.UI.Text].text = ActivityTeamlist.GetActivity(teamInfo.group).name--SmallTeamDungeonConf.Getgroup_list_id(teamInfo.group).List_name
	end
	self.ReadyType = data.gid
end
function View:MemberReady()
	local teamInfo = TeamModule.GetTeamInfo()
	local members = self.TeamMembers
	local Team_Ready_list = TeamModule.GetTeam_Ready_list()
	local IsReadyCount = 0
	local IsClickCount = 0
	for i = 1,#members do
		for j = 1,#Team_Ready_list do
			local data = Team_Ready_list[j]
			if members[i].pid == data.pid then
				if data.ready == 1 then
					IsReadyCount = IsReadyCount + 1
				else
					--DispatchEvent("KEYDOWN_ESCAPE")
				end
				IsClickCount = IsClickCount + 1
				if self.ReadyType ~= 0 then
					local gid = SmallTeamDungeonConf.GetTeam_pve_fight_gid(self.ReadyType).gid_id
					local conf = CemeteryConf.Getteam_battle_activity(gid)
					--ERROR_LOG(self.ReadyType)
					if conf then
						self.view.StartBtn.desc[UI.Text].text = "≥"..conf.team_member.."人"
						if IsReadyCount >= conf.team_member then
							self.view.StartBtn[UnityEngine.UI.Button].interactable = true
						else
							self.view.StartBtn[UnityEngine.UI.Button].interactable = false
						end
					end
				end
				self.IsReady = true
				if data.ready == 1 then
					self.view.Grid[i].state[CS.UGUISpriteSelector].index = 0;
					showDlgError(nil,"<color=#FEBA01>"..members[i].name.."</color> 已确认")
				else
					self.view.Grid[i].state[CS.UGUISpriteSelector].index = 1;
					showDlgError(nil,"<color=#FF410A>"..members[i].name.."</color> 已拒绝")
				end

				self.view.Grid[i].state:SetActive(true) -- [UnityEngine.UI.Text].text = "<color=#23FFE3>待确认</color>"
				self.view.Grid[i].Gray:SetActive(false)
				self.view.Grid[i].name[UnityEngine.UI.Text].color = UnityEngine.Color(0, 0, 0, 1);
				if members[i].pid == playerModule.Get().id then
					if self.ReadyType~=0 and playerModule.Get().id == teamInfo.leader.pid then
						self.view.StartBtn:SetActive(true)
						self.view.NBtn:SetActive(false)
						self.view.YBtn:SetActive(false)
					else
						self.view.StartBtn:SetActive(false)
						self.view.NBtn:SetActive(true)
						self.view.YBtn:SetActive(true)

					end

					self:SetButtonEnable(self.view.NBtn, false);
					self:SetButtonEnable(self.view.YBtn, false);
				end
				break
			end
		end
	end

	self.view.countDesc2[UnityEngine.UI.Text].text = string.format("%d/%d", IsReadyCount, #self.TeamMembers);

	--ERROR_LOG(IsReadyCount..">"..#members)
	if IsReadyCount == #members then
		print("所有人都确认了");
		self:verifyDesc()
		self.view.mask[UnityEngine.UI.Button].interactable = false
		if playerModule.Get().id ~= teamInfo.leader.pid or self.ReadyType == 0 then
			self.view.Grid.transform:DOScale(Vector3(1,1,1),0):SetDelay(1):OnComplete(function( ... )
				UnityEngine.GameObject.Destroy(self.gameObject)
			end)
		end

		local call = module.TeamModule.GetCallBack();

		if call then
			call(0);
		end
	elseif IsClickCount == #members then
		print("所有人都点击乐");
		self:verifyDesc()
		self.view.mask[UnityEngine.UI.Button].interactable = false
		self.view.Grid.transform:DOScale(Vector3(1,1,1),0):SetDelay(1):OnComplete(function( ... )
		--SGK.Action.DelayTime.Create(1):OnComplete(function()
			UnityEngine.GameObject.Destroy(self.gameObject)
		end)

		local call = module.TeamModule.GetCallBack();

		if call then
			call(1);
		end
	end
end

function View:SetButtonEnable(btn, enable)
	btn[UnityEngine.UI.Button].interactable = enable
	btn[UnityEngine.UI.Image].color = UnityEngine.Color(1,1,1, enable and 1 or 0.5)
	btn.Text[UnityEngine.UI.Text].color = UnityEngine.Color(0,0,0, enable and 1 or 0.5)
end

function View:onEvent(event,data) 
	if event == "ready_Player_succeed" then
		--self:RefUI()
		print("->>>>>>>>"..tostring(data.ready))
		self:MemberReady()
	end
end
  
function View:listEvent()
    return {
    "ready_Player_succeed",
    "TEAM_MEMBER_READY",
}
end
return View