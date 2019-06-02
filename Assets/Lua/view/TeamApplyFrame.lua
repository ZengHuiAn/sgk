local TeamModule = require "module.TeamModule"
local unionModule = require "module.unionModule"
local NetworkService = require "utils.NetworkService"
local playerModule = require "module.playerModule"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data
	self.inviteList = {}
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		--UnityEngine.GameObject.Destroy(self.gameObject);
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	self.view.cleanBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--清理
		if data.Type == 1 then
		local teamInfo = TeamModule.GetTeamInfo()
			if teamInfo.id > 0 then
				if teamInfo.leader.pid == playerModule.Get().id then
					TeamModule.delApply(0)
				else
					showDlgError(nil,"只有队长可以进行清理操作")
				end
			else
				showDlgError(nil,"请先加入一个队伍")
			end	
		elseif data.Type == 5 then
			unionModule.ClearInviteList()
			self:loadlist()
		else
			NetworkService.Send(18156,{nil,0,false});
		end
	end
	self.view.closeBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--UnityEngine.GameObject.Destroy(self.gameObject);
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	self.view.exitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--UnityEngine.GameObject.Destroy(self.gameObject);
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	self.list = {};
	self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
	self.nguiDragIconScript.RefreshIconCallback = (function (obj,idx)
		obj:SetActive(true)
		local pid = 0
		local desc = "{0}"
		if data.Type == 1 then
			--入队申请
			pid = self.list[idx + 1].pid
			desc = "玩家<color=#FFC03C>{0}</color>申请加入队伍"
		elseif data.Type == 2 then
			--玩家邀请
			pid = self.list[idx + 1].leader_id
			desc = "玩家<color=#FFC03C>{0}</color>邀请你加入队伍"
		elseif data.Type == 5 then
			--工会邀请
			pid = self.list[idx + 1].hostId
			desc = "玩家<color=#FFC03C>{0}</color>邀请你加入公会"
		end
		local Teamview = CS.SGK.UIReference.Setup(obj)
		if playerModule.IsDataExist(pid) then
			self:GetPlayerData(pid,Teamview,desc)
		else
		    playerModule.Get(pid,(function( ... )
		    	self:GetPlayerData(pid,Teamview,desc)
		    end))
		end
		Teamview.ignoreBtn[CS.UGUIClickEventListener].onClick = function ( ... )
			--忽略
			if data.Type == 1 then
				local teamInfo = TeamModule.GetTeamInfo()
				if teamInfo.id > 0 then
					if teamInfo.leader.pid == playerModule.Get().id then
						TeamModule.delApply(self.list[idx +1].pid)
					else
						showDlgError(nil,"只有队长可以进行忽略操作")
					end
				else
					showDlgError(nil,"请先加入一个队伍")
				end
			elseif data.Type == 5 then
				unionModule.RemoveInviteList(idx + 1)
				self:loadlist()
			else
				NetworkService.Send(18156,{nil,self.list[idx + 1].team_id,false});
			end
		end


		local teamInfo = TeamModule.GetTeamInfo()

		print(sprinttb(teamInfo),sprinttb(self.list[idx +1]));

		Teamview.consentBtn[CS.UGUIClickEventListener].onClick = function ( ... )
			--同意
			if data.Type == 1 then
				local teamInfo = TeamModule.GetTeamInfo()

				print(sprinttb(teamInfo));
				if teamInfo.id <= 0 then
					return showDlgError(nil,"请先加入一个队伍")
				end

				if teamInfo.leader.pid ~= playerModule.Get().id then
					return showDlgError(nil,"只有队长可以进行同意操作")
				end
				local lev = self.list[idx+1].level;
				if lev > teamInfo.upper_limit or lev < teamInfo.lower_limit then
					return showDlgError(nil,"未满足队伍条件");
				end


				if #teamInfo.members >= 5 then
					return showDlgError(nil,"队伍人数已满");
				end



				TeamModule.ConfiremTeamJoinRequest(self.list[idx +1].pid);
				unionModule.RemoveInviteList(idx + 1)
				self:loadlist()
			elseif data.Type == 5 then
				unionModule.AcceptInvite(self.list[idx +1].inviteId, self.list[idx +1].gid)
			else
				if SceneStack.GetBattleStatus() then
			        showDlgError(nil, "战斗内无法进行该操作")
			        return
			    end
				NetworkService.Send(18156,{nil,self.list[idx + 1].team_id,true});
			end
		end
	end)
	self:loadlist()
	if data.Type == 2 then
		--查询玩家邀请列表
		NetworkService.Send(18154);
	end
end
function View:GetPlayerData(pid,PlayerView,desc)
	--ERROR_LOG(pid)
	--ERROR_LOG(math.floor(module.playerModule.GetFightData(pid).capacity))
	local playerData = playerModule.IsDataExist(pid)
	PlayerView.title:TextFormat(desc,playerData.name)
	PlayerView.name[UnityEngine.UI.Text].text = playerData.name
	local FightData = playerModule.GetFightData(pid)
	PlayerView.combat[UnityEngine.UI.Text].text = math.floor(FightData.capacity)
	--PlayerView.heroicon.lv[UnityEngine.UI.Text].text = playerData.level
	local head = playerModule.IsDataExist(pid).head ~= 0 and playerModule.IsDataExist(pid).head or 11001
	local PLayerIcon = nil
	if PlayerView.heroicon.transform.childCount == 2 then
		PLayerIcon = IconFrameHelper.Hero({},PlayerView.heroicon)
		PLayerIcon.transform.localScale = Vector3(0.8,0.8,1)
	else
		local objClone = PlayerView.heroicon.transform:GetChild(2)
		PLayerIcon = SGK.UIReference.Setup(objClone)
	end
 	PlayerInfoHelper.GetPlayerAddData(pid,99,function (addData)
		IconFrameHelper.UpdateHero({pid = pid,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
	end)
	--PlayerView.heroicon.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..head)
	local unionName = unionModule.GetPlayerUnioInfo(pid).unionName
	if unionName then
		PlayerView.union[UnityEngine.UI.Text].text = "公会:"..unionName
	else
		unionModule.queryPlayerUnioInfo(pid,(function ( ... )
			local unionName = unionModule.GetPlayerUnioInfo(pid).unionName or "无"
			PlayerView.union[UnityEngine.UI.Text].text = "公会:"..unionName
		end))
	end
end
function View:loadlist( ... )
	if self.Data and self.Data.Type then
		self.list = {}
		if self.Data.Type == 1 then--申请
		    local waiting = TeamModule.GetTeamWaitingList(3)
		    for k, v in pairs(waiting) do
		        --print(v.pid, v.level, v.name)
		        table.insert(self.list, {
		            pid = v.pid, level = v.level, name = v.name
		        })
		    end
		elseif self.Data.Type == 2 then--邀请
			self.list = self.inviteList
		elseif self.Data.Type == 5 then--公会邀请
			self.list = unionModule.GetInviteList()
		end
		if #self.list == 0 then
	    	--DispatchEvent("KEYDOWN_ESCAPE")
	    	--DispatchEvent("team_toggle_change",1)
	    end
		self.nguiDragIconScript.DataCount = #self.list
		print(sprinttb(self.list));
		self.view.tips.gameObject:SetActive( #self.list < 1); 
	end
end

function View:onEvent(event, data) 

	print(event)
	if event == "TEAM_MEMBER_CHANGE" or event == "delApply_succeed"  or event == "TEAM_JOIN_REQUEST_CHANGE" then

		-- print(event)
		self:loadlist()
	elseif event == "TEAM_PLAYER_QUERY_INVITE_REQUEST" then
		--查询玩家邀请列表[team_id, group, leader_id, leader_name, leader_level]
		self.inviteList = TeamModule.getTeamInvite()
		self:loadlist()
		if #self.inviteList == 0 then
			--DispatchEvent("KEYDOWN_ESCAPE")
			--DispatchEvent("team_toggle_change",1)
			--showDlgError(nil,"邀请列表为空")
		end
	elseif event == "TEAM_PLAYER_REPLY_INVITATION_REQUEST" then
		--回复小队邀请回调查询玩家邀请列表
		NetworkService.Send(18154);
	elseif event == "LOCAL_UNION_ACCEPTINVITE_OK" then
		--DispatchEvent("KEYDOWN_ESCAPE")
		DispatchEvent("team_toggle_change",1)
	end
end

function View:listEvent()
    return {
    "TEAM_MEMBER_CHANGE",
    "delApply_succeed",
    "TEAM_PLAYER_QUERY_INVITE_REQUEST",
    "TEAM_PLAYER_REPLY_INVITATION_REQUEST",
    "LOCAL_UNION_ACCEPTINVITE_OK",
    "PLAYER_INFO_CHANGE",
    "TEAM_JOIN_REQUEST_CHANGE"
}
end
return View 