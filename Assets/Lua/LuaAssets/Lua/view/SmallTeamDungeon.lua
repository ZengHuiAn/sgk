local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local ActivityTeamlist = require "config.activityConfig"
local NetworkService = require "utils.NetworkService"
local TeamModule = require "module.TeamModule"
local ItemHelper = require "utils.ItemHelper"
local playerModule = require "module.playerModule"
local Time = require "module.Time"
local IconFrameHelper = require "utils.IconFrameHelper"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local CemeteryModule = require "module.CemeteryModule"
local CemeteryConf = require "config.cemeteryConfig"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.PveView_1_Pool = {}--一级标题
	self.PveView_1 = {}

	self.PveViewClickId = nil
	self.GroupId = data and data.id or 0
	self.PveView_2_Pool = {}--二级标题
	self.PveView_2 = {}
	
	self.Teamlist = {};

	self.TeamDataCache = {}--队伍数据缓存
	self.ObserveTime = 0
	self.view.TeamView.Count[UI.Text].text = ""
	self.nguiDragIconScript3 = self.view.TeamView.TeamScrollView[CS.UIMultiScroller]
	self.nguiDragIconScript3.RefreshIconCallback = (function (obj,idx)--其他的队伍信息
		local info = self.Teamlist[idx + 1]
		if info then
			local Teamview = CS.SGK.UIReference.Setup(obj)
			Teamview.name[UnityEngine.UI.Text].text = "<color=#FDD01B>"..info.leader.name.."</color>的队伍"
			Teamview.okBtn[UnityEngine.UI.Button].interactable = true
			Teamview.okBtn.Text[UnityEngine.UI.Text].text = "申请"
			Teamview.okBtn[CS.UGUIClickEventListener].onClick = function ( ... )
				if not Teamview.okBtn[UnityEngine.UI.Button].interactable then
					return
				end
				local teamInfo = TeamModule.GetTeamInfo()
				if teamInfo.group == 0 then
					TeamModule.JoinTeam(info.id)
					Teamview.okBtn[UnityEngine.UI.Button].interactable = false
					Teamview.okBtn.Text[UnityEngine.UI.Text].text = "已申请"
				else
					showDlgError(nil,"当前已在队伍中")
				end
			end
			print("------------------>",info.leader.name)
			for i = 1,5 do
				local pid = info.member_id[i] or 0
				print(info.member_id[i])
				local PLayerIcon = nil

				PLayerIcon = Teamview.HeroPos[i]
				PLayerIcon.transform.localScale = Vector3(1,1,1)
				-- if i <= info.member_count then
				if tonumber(pid) ~= 0 then

					PlayerInfoHelper.GetPlayerAddData(pid,99,function (addData)
						local player = IconFrameHelper.Create(PLayerIcon,{pid = pid,sex = addData.Sex,headFrame = addData.HeadFrame,type = utils.ItemHelper.TYPE.PLAYER })
					end)
				else
					IconFrameHelper.Create(PLayerIcon,{type = utils.ItemHelper.TYPE.PLAYER,customCfg = {head = 10999,level = 0,name = ""} })
					
				end
		 	end
			--ERROR_LOG(info.leader.pid)
			obj:SetActive(true)
		else
			print("self.Teamlist->"..(idx+1).." nil")
		end
	end)

	self.view.TeamView.formTeamBtn[CS.UGUIClickEventListener].onClick = function ( ... )--我的队伍/创建队伍
		local members = TeamModule.GetTeamMembers()
		for _, v in ipairs(members) do
			DispatchEvent("team_toggle_change",1)
			return
		end
		if self.GroupId ~= 0 then
			local team_battle_cfg = CemeteryConf.Getteam_battle_conf(self.GroupId)
			if team_battle_cfg then
				TeamModule.CreateTeam(self.GroupId,nil,team_battle_cfg.limit_level,team_battle_cfg.des_limit);--创建队伍
			else
				TeamModule.CreateTeam(self.GroupId);--创建队伍
			end
		else
			TeamModule.CreateTeam(999);--创建空队伍
		end
	end

	local teamInfo = TeamModule.GetTeamInfo()
	if TeamModule.GetplayerMatchingType() ~= 0 then--如果在匹配中
		self.match = TeamModule.GetplayerMatchingType()
		self.GroupId = self.match
	elseif teamInfo.auto_match then
		self.match = teamInfo.group
	else
		self.match = 0
	end
	if teamInfo.group ~= 0 and teamInfo.group ~= 999 then--切换到当前队伍目标
		self.GroupId = teamInfo.group
		local _cfg = ActivityTeamlist.GetActivity(self.GroupId)
		self.tittle = _cfg.up_tittle3
	end

	self.view.TeamView.matchingBtn[CS.UGUIClickEventListener].onClick = function ( ... )--自动匹配
		if self.match then
			local teamInfo = TeamModule.GetTeamInfo()
			if teamInfo.group ~= 0 then
				TeamModule.TeamMatching(false)
			elseif teamInfo.group == 0 then
				TeamModule.playerMatching(0)
			end
		end
		if teamInfo.group ~= 0 then
			utils.SGKTools.SwitchTeamTarget(self.GroupId); 
		else
			utils.SGKTools.PlayerMatching(self.GroupId); 
		end
	end
	self.view.TeamView.matchingBtn.Text[UnityEngine.UI.Text].text = self.match ~= 0 and "取消匹配" or "自动匹配"
	self.view.TeamView.formTeamBtn.Text[UnityEngine.UI.Text].text = teamInfo.group == 0 and "创建队伍" or "我的队伍"
	
	self.view.TeamView.RefBtn[CS.UGUIClickEventListener].onClick = function ( ... )--刷新
		--刷新
		if self.GroupId ~= 0 then
			TeamModule.WatchTeamGroup(self.GroupId);
			TeamModule.GetTeamList(self.GroupId, true)
		else
			showDlgError(nil,SGK.Localize:getInstance():getValue("zudui_fuben_07"))
		end
	end

	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )--关闭
		DispatchEvent("KEYDOWN_ESCAPE")
	end

	self.Activity_list = self:Activitylist_sort()
	--print(sprinttb(self.Activity_list))
	for i = 1,#self.Activity_list do
		if self.Activity_list[i].TitleData.id ~= 999 and playerModule.Get().level >= self.Activity_list[i].TitleData.lv_limit then
			-- print(self.Activity_list[i].id,self.Activity_list[i],i)
			self:UIloadData(self.Activity_list[i].id,self.Activity_list[i],i)
		end
	end
end

function View:Activitylist_sort()
	local Activitylist = {}
	for k,v in pairs(ActivityTeamlist.GetActivitylist()) do
		Activitylist[#Activitylist+1] = v
	end
	table.sort(Activitylist,function(a,b)
		local a_suggest = 0
		for i = 1,#a.ChildNode do
			local value = a.ChildNode
			local cfg = CemeteryConf.Getteam_battle_conf(value[i].id)
			local activity_data = ActivityTeamlist.GetActiveCountById(value[i].id)
			local activity_cfg = ActivityTeamlist.GetActivity(value[i].id)
			if cfg and activity_data.finishCount < value[i].advise_times and playerModule.Get().level >= activity_cfg.lv_limit then
				a_suggest = 1--推荐
				break
			end
		end

		local b_suggest = 0
		for i = 1,#b.ChildNode do
			local value = b.ChildNode
			local cfg = CemeteryConf.Getteam_battle_conf(value[i].id)
			local activity_data = ActivityTeamlist.GetActiveCountById(value[i].id)
			local activity_cfg = ActivityTeamlist.GetActivity(value[i].id)
			if cfg and activity_data.finishCount < value[i].advise_times and playerModule.Get().level >= activity_cfg.lv_limit then
				b_suggest = 1--推荐
				break
			end
		end
		return a_suggest > b_suggest
	end)
	return Activitylist
end

function View:UIloadData(k,v,idx)
	if #v.ChildNode > 0 or v.IsTittle == false then
		local ContentView = self.view.TeamView.MapScrollView.Viewport.Content
		if #self.PveView_1_Pool > 0 then
			self.PveView_1[k] = self.PveView_1_Pool[1]
			table.remove(self.PveView_1_Pool,1)
		else
			if not self.PveView_1[k] then
				local obj = CS.UnityEngine.GameObject.Instantiate(ContentView[1].gameObject,ContentView.gameObject.transform)
				self.PveView_1[k] = CS.SGK.UIReference.Setup(obj)
			end
		end
		self.PveView_1[k]:SetActive(true)
		self.PveView_1[k].name[UnityEngine.UI.Text].text = v.TitleData.name
		if v.IsTittle == false then
			self.PveView_1[k].arrows:SetActive(false)
			--self.PveView_1[k].name[UnityEngine.RectTransform].transform.localPosition = Vector3(86,-24.5,0)
		end
		self.PveView_1[k].state:SetActive(TeamModule.GetplayerMatchingType() ~= 0 and TeamModule.GetplayerMatchingType() == v.TitleData.id)
		self.PveView_1[k][CS.UGUIClickEventListener].onClick = (function ( ... )
			-- self.PveViewClickId = k
			-- print(ActivityTeamlist.GetActivitylist()[self.PveViewClickId])
			-- print(ActivityTeamlist.GetActivitylist()[self.PveViewClickId].IsTittle)
			-- print(v.IsTittle)
			-- print(self.PveViewClickId,k)
			if (ActivityTeamlist.GetActivitylist()[self.PveViewClickId] and ActivityTeamlist.GetActivitylist()[self.PveViewClickId].IsTittle) or (v.IsTittle == false and self.PveViewClickId ~= k)then
				self:PveViewRef(self.PveViewClickId,false)
				local cfg = ActivityTeamlist.GetActivitylist()
				if cfg[self.PveViewClickId] then
					self.PveView_1[self.PveViewClickId].name[UnityEngine.UI.Text].text = cfg[self.PveViewClickId].TitleData.name
				end
			end
			print(self.PveViewClickId,k)
			if self.PveViewClickId ~= k then
				self.PveViewClickId = k
				self:PveViewRef(k,true)
			else
				self.PveViewClickId = nil
				self:PveViewRef(k,false)
			end
			if #v.ChildNode == 0 then
				--一级标题作为类型直接搜索队伍
				self.GroupId = v.TitleData.id
				--print("->"..self.GroupId)
				self.ObserveTime = Time.now()
				if self.TeamDataCache[self.GroupId] and self.TeamDataCache[self.GroupId].Time + 10 > Time.now() then
					self.Teamlist = self.TeamDataCache[self.GroupId].data
					self.nguiDragIconScript3.DataCount = #self.TeamDataCache[self.GroupId].data
					self.view.TeamView.tips:SetActive(#self.TeamDataCache[self.GroupId].data <= 0)
				else
					--TeamModule.WatchTeamGroup(self.GroupId);
					TeamModule.GetTeamList(self.GroupId, true)
				end
			end
		end)

		self:unfold_tab(k,v,true,idx)
	end
end

function View:unfold_tab(key,data,state,idx)
	local value = data.ChildNode
	if #value > 0 then
		local _state = false
		local suggest = false
		local PveView_2_count = 0
		for i = 1,#value do
			local activity_cfg = ActivityTeamlist.GetActivity(value[i].id)
			if playerModule.Get().level >= activity_cfg.lv_limit then
				PveView_2_count = PveView_2_count + 1
				if #self.PveView_2_Pool > 0 then
					self.PveView_2[#self.PveView_2+1] = self.PveView_2_Pool[1]
					self.PveView_2[#self.PveView_2].transform:SetParent(self.PveView_1[key].Group.gameObject.transform,false)
					table.remove(self.PveView_2_Pool,1)
				else
					local obj = CS.UnityEngine.GameObject.Instantiate(self.PveView_1[key].Group[1].gameObject,self.PveView_1[key].Group.gameObject.transform)
					self.PveView_2[#self.PveView_2+1] = CS.SGK.UIReference.Setup(obj)
				end
				self.PveView_2[#self.PveView_2]:SetActive(true)
				self.PveView_2[#self.PveView_2].name[UnityEngine.UI.Text].text = value[i].name
				_state = false
				if self.match == value[i].id then
					_state = true
					self.PveView_1[key].state:SetActive(_state)
				end
				self.PveView_2[#self.PveView_2].state:SetActive(TeamModule.GetplayerMatchingType() ~= 0 and TeamModule.GetplayerMatchingType() == value[i].id)
				local index = #self.PveView_2
				self.PveView_2[#self.PveView_2][CS.UGUIClickEventListener].onClick = (function ( ... )
					for k,v in pairs(self.PveView_1) do
						v.select:SetActive(false)
					end
					for j =1,#self.PveView_2 do
						self.PveView_2[j].bg:SetActive(false)
					end
					-------------------------------------------------
					self.GroupId = value[i].id
					-- print("->"..self.GroupId)
					self.ObserveTime = Time.now()
					if self.TeamDataCache[self.GroupId] and self.TeamDataCache[self.GroupId].Time + 10 > Time.now() then
						self.Teamlist = self.TeamDataCache[self.GroupId].data
						self.nguiDragIconScript3.DataCount = #self.TeamDataCache[self.GroupId].data
						self.view.TeamView.tips:SetActive(#self.TeamDataCache[self.GroupId].data <= 0)
					else
						TeamModule.GetTeamList(self.GroupId, true)
					end
					-------------------------------------------------
					self.PveView_2[index].bg:SetActive(true)
					self.PveView_1[key].name[UnityEngine.UI.Text].text = data.TitleData.name.."\n<color=#676767FF><size=22>"..value[i].name.."</size></color>"
					if self.match == value[i].id then--切换到其他标签
						self.view.TeamView.matchingBtn.Text[UnityEngine.UI.Text].text = "取消匹配"
					else
						self.view.TeamView.matchingBtn.Text[UnityEngine.UI.Text].text = "自动匹配"
					end
				end)

				local cfg = CemeteryConf.Getteam_battle_conf(value[i].id)
				local activity_data = ActivityTeamlist.GetActiveCountById(value[i].id)
				local activity_cfg = ActivityTeamlist.GetActivity(value[i].id)
				-- if cfg and activity_data.finishCount < value[i].advise_times and playerModule.Get().level >= activity_cfg.lv_limit and playerModule.Get().level < activity_cfg.lv_limit_out then
				-- 	suggest = true
				-- 	self.PveView_2[#self.PveView_2].suggest:SetActive(true)
				-- else
				-- 	self.PveView_2[#self.PveView_2].suggest:SetActive(false)
				-- end
				if self.GroupId > 0 and value[i].id == self.GroupId then
					self.PveViewClickId = key
					self:PveViewRef(key,true)--展开标题栏
					self:LoadTeam()
					self.PveView_2[index][CS.UGUIClickEventListener]:onClick()
				end
				self.PveView_2[index].state:SetActive(_state)
			end
		end
	end
end
function View:PveViewRef(k,state)
	if k then
		local v = ActivityTeamlist.GetActivitylist()[k]
		if v.IsTittle then
			self.PveView_1[k].Group:SetActive(state)
			local ViewCount = self.PveView_1[k].Group.transform.childCount
			self.PveView_1[k].arrows.transform.localEulerAngles = state and Vector3(0,0,-180) or Vector3(0,0,-90)
			self.PveView_1[k].bg[CS.UGUISpriteSelector].index = state and 1 or 0
			
		else
			if state then
				for j =1,#self.PveView_2 do
					self.PveView_2[j].bg:SetActive(false)
				end
				for k,v in pairs(self.PveView_1) do
					v.select:SetActive(false)
				end
			end
			self.PveView_1[k].select:SetActive(state)
		end
	end
end
function View:LoadTeam( ... )
	self.Teamlist = {}
	local teamInfo = TeamModule.GetTeamInfo()--获取当前自己的队伍
	local teams = TeamModule.GetTeamList(self.GroupId)
	local Leader_pid = teamInfo.leader and teamInfo.leader.pid or nil
    for k, v in pairs(teams) do
    	--if v.leader.pid ~= Leader_pid then
	        table.insert(self.Teamlist, {
	            id = v.id, member_count = v.member_count, leader = {pid = v.leader.pid, name = v.leader.name},
	            joinRequest = v.joinRequest,member_id = v.member_id,
	        })
	    --end
    end
   	print("UpdateTeamList--->", #self.Teamlist);
	self.nguiDragIconScript3.DataCount = #self.Teamlist
	self.view.TeamView.tips:SetActive(#self.Teamlist <= 0)
	self.TeamDataCache[self.GroupId] = {Time = Time.now(),data = self.Teamlist}
end
function View:Update()
	if self.GroupId ~= 0 and self.ObserveTime ~= 0 and self.ObserveTime + 10 < Time.now() then
		self.ObserveTime = 0
		TeamModule.WatchTeamGroup(self.GroupId)
	end
end
function View:onEvent(event, data)
	if event == "TEAM_LIST_CHANGE" then
    	self:LoadTeam()
    elseif event == "playerMatching_succeed" then
    	self.match = TeamModule.GetplayerMatchingType()
    	self.view.TeamView.matchingBtn.Text[UnityEngine.UI.Text].text = self.match ~= 0 and "取消匹配" or "自动匹配"
    	for i = 1,#self.PveView_2 do
    		self.PveView_2_Pool[#self.PveView_2_Pool + 1] = self.PveView_2[i]
    	end
    	self.PveView_2 = {}
    	for i = 1,#self.Activity_list do
			if self.Activity_list[i].TitleData.id ~= 999 and playerModule.Get().level >= self.Activity_list[i].TitleData.lv_limit then
				self:UIloadData(self.Activity_list[i].id,self.Activity_list[i],i)
			end
		end
	elseif event == "TeamMatching_succeed" then
		local teamInfo = TeamModule.GetTeamInfo()
		self.match = teamInfo.auto_match and teamInfo.group or 0
		self.view.TeamView.matchingBtn.Text[UnityEngine.UI.Text].text = self.match ~= 0 and "取消匹配" or "自动匹配"
		for i = 1,#self.PveView_2 do
    		self.PveView_2_Pool[#self.PveView_2_Pool + 1] = self.PveView_2[i]
    	end
    	self.PveView_2 = {}
    	for i = 1,#self.Activity_list do
			if self.Activity_list[i].TitleData.id ~= 999 and playerModule.Get().level >= self.Activity_list[i].TitleData.lv_limit then
				self:UIloadData(self.Activity_list[i].id,self.Activity_list[i],i)
			end
		end
    elseif event == "Add_team_succeed" then
    	--print("加入队伍")
    	if data.pid == playerModule.GetSelfID() then
    		DispatchEvent("team_toggle_change",1)
	    end
    end
end
function View:listEvent()
    return {
    "TeamMatching_succeed",
    "TEAM_LIST_CHANGE",
    "playerMatching_succeed",
    "Add_team_succeed",
}
end
return View