local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local NetworkService = require "utils.NetworkService"
local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule"
local ActivityTeamlist = require "config.activityConfig"
local CemeteryConf = require "config.cemeteryConfig"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data

	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		DialogStack.Pop()
	end
	self.view.Dialog.Close[CS.UGUIClickEventListener].onClick = function ( ... )
		DialogStack.Pop()
	end

	self.PveView_1_Pool = {}
	self.PveView_1 = {}

	self.PveViewClickId = nil
	self.GroupId = 999
	self.PveView_2_Pool = {}
	self.PveView_2 = {}

	local teamInfo = TeamModule.GetTeamInfo();
	-- print(sprinttb(teamInfo))
	self.now_group_id = teamInfo.group
	local cfg = ActivityTeamlist.GetActivitylist()
	self:UIloadData(999,cfg[999])
	self.Activity_list = self:Activitylist_sort()
	--for k,v in pairs(cfg) do
	for i = 1,#self.Activity_list do
		if self.Activity_list[i].TitleData.id ~= 999 and playerModule.Get().level >= self.Activity_list[i].TitleData.lv_limit then
			self:UIloadData(self.Activity_list[i].id,self.Activity_list[i])
		end
	end

	self.view.yBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--ERROR_LOG(self.GroupId)
		local list = DialogStack.GetPref_list("lvlimitFrame")
		if list then
			local behavior = list:GetComponent(typeof(CS.SGK.LuaBehaviour))
			if behavior then
				behavior:Call("Close")
			end
		end
		if self.now_group_id == self.GroupId then
		else
			TeamModule.TeamMatching(false)
			utils.NetworkService.Send(18178,{nil,self.GroupId})
		end
		DialogStack.Pop()
	end
	-- self.view.matchingBtn[CS.UGUIClickEventListener].onClick = function ( ... )
	-- 	--自动匹配
	-- 	if SceneStack.GetBattleStatus() then
	--         showDlgError(nil, "战斗内无法进行该操作")
	--         return
	--     end
	--     if self.view.matchingBtn[UnityEngine.UI.Button].interactable then
	-- 		local teamInfo = TeamModule.GetTeamInfo()--获取当前自己的队伍
	-- 		if teamInfo.leader.pid == playerModule.Get().id then
	-- 			if TeamModule.GetTeamInfo().auto_match and (self.GroupId == 999 or self.GroupId == self.now_group_id) then
	-- 				TeamModule.TeamMatching(false)
	-- 			else 
	-- 				local lv_limit = ActivityTeamlist.Get_all_activity(self.GroupId).lv_limit
	-- 				local unqualified_name = {}
	-- 				for k,v in ipairs(module.TeamModule.GetTeamMembers()) do
	-- 					if v.level < lv_limit then
	-- 						unqualified_name[#unqualified_name+1] = {v.pid,"队伍成员"..v.name.."未达到副本所需等级"}
	-- 					end
	-- 				end
	-- 				if #unqualified_name == 0 then
	-- 					if self.GroupId ~= 0 and self.GroupId ~= 999 then
	-- 						utils.NetworkService.Send(18178,{nil,self.GroupId})
	-- 						TeamModule.TeamMatching(true)
	-- 					else
	-- 						TeamModule.TeamMatching(false)
	-- 					end
	-- 				else
	-- 					for i =1 ,#unqualified_name do
	-- 						module.TeamModule.SyncTeamData(107,{unqualified_name[i][1],unqualified_name[i][2]})
	-- 					end
	-- 				end
	-- 			end
	-- 		else
	-- 			showDlgError(nil,"只有队长可以发起匹配")
	-- 		end
	-- 	end
	-- end
	-- if TeamModule.GetTeamInfo().auto_match then
	-- 	self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_02")--"取消匹配"
	-- 	self.view.matchingBtn[UnityEngine.UI.Button].interactable = true
	-- else
	-- 	self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_01")--"开始匹配"
	-- 	self.view.matchingBtn[UnityEngine.UI.Button].interactable = (self.GroupId ~= 999 and self.GroupId ~= 0)
	-- end
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
function View:UIloadData(k,v)
	if #v.ChildNode > 0 or v.IsTittle == false then
		local ContentView = self.view.MapScrollView.Viewport.Content
		--local obj = nil
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
		self.PveView_1[k].state:SetActive(TeamModule.GetTeamInfo().auto_match and self.now_group_id == v.TitleData.id)
		self.PveView_1[k].toggle[UI.Toggle].isOn = (self.now_group_id == v.TitleData.id)
		self.PveView_1[k][CS.UGUIClickEventListener].onClick = (function ( ... )
			self:PveViewRef(self.PveViewClickId,false)
			if (ActivityTeamlist.GetActivitylist()[self.PveViewClickId] and ActivityTeamlist.GetActivitylist()[self.PveViewClickId].IsTittle) or (v.IsTittle == false and self.PveViewClickId ~= k)then
				local cfg = ActivityTeamlist.GetActivitylist()
				if cfg[self.PveViewClickId] then
					self.PveView_1[self.PveViewClickId].name[UnityEngine.UI.Text].text = cfg[self.PveViewClickId].TitleData.name
				end
			end
			if self.PveViewClickId ~= k then
				self.PveViewClickId = k
				self:PveViewRef(k,true)
			else
				self.PveViewClickId = nil
			end
			if #v.ChildNode == 0 then
				--一级标题作为类型直接搜索队伍
				self:GroupChange(v.TitleData,2)
			end
		end)
		if self.Data and self.Data.id == v.TitleData.id then--临时方案，如果id相匹配则直接执行self.PveView_1[k] onclick的代码
			if (ActivityTeamlist.GetActivitylist()[self.PveViewClickId] and ActivityTeamlist.GetActivitylist()[self.PveViewClickId].IsTittle) or (v.IsTittle == false and self.PveViewClickId ~= k)then
				self:PveViewRef(self.PveViewClickId,false)
			end
			if self.PveViewClickId ~= k then
				self.PveViewClickId = k
				self:PveViewRef(k,true)
			else
				self.PveViewClickId = nil
			end
			if #v.ChildNode == 0 then
				--一级标题作为类型直接搜索队伍
				self:GroupChange(v.TitleData,1)
				--self.GroupId = v.TitleData.id
				--print("->"..self.GroupId)
			end
		end
		self:unfold_tab(k,v,true)
	end
end
function View:unfold_tab(key,data,state)
	local value = data.ChildNode
	if #value > 0 then
		local _state = false
		local _target = false
		local Is_lock = false--代表标题栏是否已经被选中
		local suggest = false
		for i = 1,#value do
			local activity_cfg = ActivityTeamlist.GetActivity(value[i].id)
			if playerModule.Get().level >= activity_cfg.lv_limit then
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
				if TeamModule.GetTeamInfo().auto_match and self.now_group_id == value[i].id then
					_state = true
				end
				self.PveView_2[#self.PveView_2].toggle[UI.Toggle].isOn = (self.now_group_id == value[i].id)
				if self.now_group_id == value[i].id then
					_target = true
				end
				self.PveView_2[#self.PveView_2].state:SetActive(TeamModule.GetTeamInfo().auto_match and self.now_group_id == value[i].id)
				local index = #self.PveView_2
				self.PveView_2[#self.PveView_2][CS.UGUIClickEventListener].onClick = (function ( ... )
					for k,v in pairs(self.PveView_1) do
						v.select:SetActive(false)
					end
					for j =1,#self.PveView_2 do
						self.PveView_2[j].bg:SetActive(false)
						--self.PveView_2[j].name[UI.Text].color = {r=1,g=1,b=1,a=1}
					end
					-------------------------------------------------
					self:GroupChange(value[i],2)
					-------------------------------------------------
					self.PveView_2[index].bg:SetActive(true)
					self.PveView_2[index].toggle[UnityEngine.UI.Toggle].isOn = true
					self.PveView_1[key].name[UnityEngine.UI.Text].text = data.TitleData.name.."\n<color=#676767FF><size=22>"..value[i].name.."</size></color>"
					--self.PveView_2[index].name[UI.Text].color = {r=253/255,g=231/255,b=120/255,a=1}
				end)
				if self.Data and self.Data.id == value[i].id then--临时方案，如果id相匹配则直接执行self.PveView_2[#self.PveView_2] onclick的代码
					Is_lock = true
					
					for k,v in pairs(self.PveView_1) do
						v.select:SetActive(false)
					end
					for j =1,#self.PveView_2 do
						self.PveView_2[j].bg:SetActive(false)
					end
					-------------------------------------------------
					self:GroupChange(value[i],1)
					--self.GroupId = value[i].id
					--print("->"..self.GroupId)
					
					-------------------------------------------------
					self.PveView_2[index].bg:SetActive(true)
					self.PveView_1[key].name[UnityEngine.UI.Text].text = data.TitleData.name.."\n<color=#676767FF><size=22>"..value[i].name.."</size></color>"
				end
				local cfg = CemeteryConf.Getteam_battle_conf(value[i].id)
				-- local activity_data = ActivityTeamlist.GetActiveCountById(value[i].id)
				-- if cfg and activity_cfg and activity_data.finishCount < value[i].advise_times and playerModule.Get().level >= activity_cfg.lv_limit and playerModule.Get().level < activity_cfg.lv_limit_out then
				-- 	--ERROR_LOG(cc.finishCount)
				-- 	--ERROR_LOG(cfg,value[i].name)
				-- 	suggest = true
				-- 	self.PveView_2[#self.PveView_2].suggest:SetActive(true)
				-- else
				-- 	self.PveView_2[#self.PveView_2].suggest:SetActive(false)
				-- end
			end
		end
		if Is_lock then
			self.PveViewClickId = key
			self:PveViewRef(key,true)--展开标题栏
		end
		self.PveView_1[key].state:SetActive(_state)
		-- self.PveView_1[key].suggest:SetActive(false)
		self.PveView_1[key].toggle[UI.Toggle].isOn = _target
	end
end
function View:PveViewRef(k,state)
	-- print(k,state)
	if k then
		local v = ActivityTeamlist.GetActivitylist()[k]
		-- if v.IsTittle then
			self.PveView_1[k].Group:SetActive(state)
			local ViewCount = self.PveView_1[k].Group.transform.childCount
			--self.PveView_1[k][UnityEngine.RectTransform].sizeDelta = state and CS.UnityEngine.Vector2(295,90*ViewCount) or CS.UnityEngine.Vector2(295,90)
			self.PveView_1[k].arrows.transform.localEulerAngles = state and Vector3(0,0,-180) or Vector3(0,0,-90)
			self.PveView_1[k].bg[CS.UGUISpriteSelector].index = state and 1 or 0
			self.PveView_1[k].toggle[UnityEngine.UI.Toggle].isOn = state
			--self.PveView_1[k].state:SetActive(state)
			--self.PveView_1[k].state[UnityEngine.UI.Image].color = state and {r=1,g=1,b=1,a=0} or {r=1,g=1,b=1,a=1}
		-- else
		-- 	if state then
		-- 		for j =1,#self.PveView_2 do
		-- 			self.PveView_2[j].bg:SetActive(false)
		-- 		end
		-- 		for k,v in pairs(self.PveView_1) do
		-- 			v.select:SetActive(false)
		-- 		end
		-- 	end
		-- 	self.PveView_1[k].select:SetActive(state)
		-- end
	end
end
function View:GroupChange(cfg,type)
	self.GroupId = cfg.id
	--ERROR_LOG("->"..self.GroupId)
	if cfg.type < 3 then
		if playerModule.Get().level >= cfg.lv_limit then
			self.view.level[UI.Text].text = cfg.parameter
		else
			self.view.level[UI.Text].text = "限制:达到<color=#FF0000FF>"..cfg.lv_limit.."</color>级"
		end
	else
		self.view.level[UI.Text].text = ""
	end
	self.view.time[UI.Text].text = "时间："..cfg.activity_time
	if cfg.advise_times > 0 then
		local activity_data = ActivityTeamlist.GetActiveCountById(cfg.id)
		self.view.desc[UI.Text].text = "次数："..activity_data.finishCount.."/"..cfg.advise_times--cfg.join_limit
	else
		self.view.desc[UI.Text].text = "简介："..cfg.des
	end
	local team_battle_cfg = CemeteryConf.Getteam_battle_conf(cfg.id)
	local data = {}
	local _lower_limit = 1
	local _upper_limit = 80
	if team_battle_cfg then
		_lower_limit = team_battle_cfg.limit_level
		_upper_limit = team_battle_cfg.des_limit
	end
	local teamInfo = TeamModule.GetTeamInfo()
	data = {lower_limit = _lower_limit,
			upper_limit = _upper_limit,
			team_lower = teamInfo.lower_limit,
			team_upper = teamInfo.upper_limit}
	--ERROR_LOG(type)
	if type == 1 then
		DialogStack.PushPref("lvlimitFrame",data,self.view)
	else
		DispatchEvent("LvLimitChange",data)
	end
	
	-- if TeamModule.GetTeamInfo().auto_match then
	-- 	self.view.matchingBtn[UnityEngine.UI.Button].interactable = true
	-- 	if self.now_group_id == self.GroupId or self.GroupId == 999 then
	-- 		self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_02")--"取消匹配"
	-- 	else
	-- 		self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_01")--"开始匹配"
	-- 	end
	-- else
	-- 	self.view.matchingBtn[UnityEngine.UI.Button].interactable = (self.GroupId ~= 999 and self.GroupId ~= 0)
	-- end
end
function View:onEvent(event, data)
	if event == "QUERY_PLAYER_FIGHT_WIN_COUNT_REQUEST" then
		
	elseif event == "GROUP_CHANGE" or event == "TeamMatching_succeed" then
		local teamInfo = TeamModule.GetTeamInfo();
		self.now_group_id = teamInfo.group
		self.Data.id = teamInfo.group
		for i = 1,#self.PveView_2 do
    		self.PveView_2_Pool[#self.PveView_2_Pool + 1] = self.PveView_2[i]
    	end
    	self.PveView_2 = {}
    	for i = 1,#self.Activity_list do
			--if self.Activity_list[i].TitleData.id ~= 999 then
				self:UIloadData(self.Activity_list[i].id,self.Activity_list[i])
			--end
		end
		-- if TeamModule.GetTeamInfo().auto_match then
		-- 	self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_02")--"取消匹配"
		-- 	self.view.matchingBtn[UnityEngine.UI.Button].interactable = true
		-- else
		-- 	self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_01")--"开始匹配"
		-- 	self.view.matchingBtn[UnityEngine.UI.Button].interactable = (self.GroupId ~= 999 and self.GroupId ~= 0)
		-- end
    end
end
function View:listEvent()
	return{
	    "QUERY_PLAYER_FIGHT_WIN_COUNT_REQUEST",
	    "GROUP_CHANGE",
	    "TeamMatching_succeed",
	}
end
return View