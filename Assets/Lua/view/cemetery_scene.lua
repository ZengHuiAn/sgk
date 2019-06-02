local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local NetworkService = require "utils.NetworkService"
local HeroModule = require "module.HeroModule"
local unionModule = require "module.unionModule"
local ChatManager = require 'module.ChatModule'
local CemeteryModule = require "module.CemeteryModule"
local MapConfig = require "config.MapConfig"
local cemeteryConf = require "config.cemeteryConfig"
local View = {}
function View:Start(data)
	--self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.stage = 0--副本阶段
	for k,v in pairs(SmallTeamDungeonConf.GetTeam_battle_conf())do
		if v.mapid == SceneStack.GetStack()[SceneStack.Count()].savedValues.mapId then
			ERROR_LOG("当前副本",v.gid_id)
			CemeteryModule.Setactivityid(v.gid_id)
			break
		end
	end
	self.MaxState = 0--副本最大阶段
	for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(CemeteryModule.Getactivityid()).idx) do
		for i = 1,#v do
			if v[i].sequence > self.MaxState then
				self.MaxState = v[i].sequence
			end
		end
	end
	if CemeteryModule.GetCombat_results_query() then
		local conf = SmallTeamDungeonConf.GetTeam_pve_fight_gid(CemeteryModule.GetCombat_results_query())
		if conf.after_fight_story ~= 0 then
			LoadStory(conf.after_fight_story)
		end
		CemeteryModule.Combat_results_query()
	else
		self:QUERY_TEAM_PROGRESS_REQUEST()
	end
end

function View:onEvent(event, data)
	if event == "ClickOBJIdx" then
		print(data.idx)
		if data.idx == 0 then
			showDlg(nil," 是否需要离开副本？.",function()
				SceneStack.EnterMap("map_scene");
			end,function ( ... )
				
			end,"是","否")
		-- elseif data.idx == TeamModule.GetFightIndex() then
		-- 	local teamInfo = TeamModule.GetTeamInfo();
		-- 	local battle_id = SmallTeamDungeonConf.Getgroup_list_id(teamInfo.group).Incident
		-- 	print(battle_id)
		-- 	TeamModule.NewReadyToFight(SmallTeamDungeonConf.GetTeam_pve_fight(battle_id).idx[TeamModule.GetFightIndex()].gid)--战前确认
		else
			showDlg(nil,"哥们你找错人了吧.",function()
				-- 	print("点击了确定")
			end)
		end
	--elseif event == "TEAM_INFO_CHANGE" then 
	elseif event == "update_monster_schedule" then
		--CemeteryModule.Query_Team_Fight_Win_Count()--加载团队进度
		self:QUERY_TEAM_PROGRESS_REQUEST()
	elseif event == "QUERY_PLAYER_FIGHT_WIN_COUNT_REQUEST" then
		self:QUERY_TEAM_PROGRESS_REQUEST()
	elseif event == "Leave_team_succeed" then
		if data.pid == module.playerModule.GetSelfID() then
			DlgMsg({msg = "您已退出队伍，5秒后将被移除副本.",confirm = function()
				local activityid = CemeteryModule.Getactivityid()
				local uuid = module.CemeteryModule.GetTEAM_PveStateUid(activityid)
				if uuid then
	            	module.QuestModule.Cancel(uuid)
		            module.QuestModule.SetOldUuid(nil)
		        end
				SceneStack.EnterMap(10)
			end,time = 5,NotExit = true})
		end
	end
end
function View:QUERY_TEAM_PROGRESS_REQUEST()
	local teamInfo = module.TeamModule.GetTeamInfo();
	if teamInfo.group == 0 then
		return
	end
	CemeteryModule.Query_Team_Fight_Win_Count()--加载团队进度
	local dieArr = {}
	local activityid = CemeteryModule.Getactivityid()
	for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(activityid).idx) do
		for i = 1,#v do
			if CemeteryModule.GetTEAMRecord(v[i].gid) > 0 then
				dieArr[v[i].gid] = CemeteryModule.GetTEAMRecord(v[i].gid)
				if self.stage < SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence then
					self.stage = SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence
				end
			end
			
		end
	end
	
	local conf = nil
	local list = {}
	module.CemeteryModule.SetMonsterg_state(list)
	if activityid ~= 0 and SmallTeamDungeonConf.GetTeam_pve_fight(activityid) then
		for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(activityid).idx) do
			for i = 1,#v do
				--ERROR_LOG(v[i].gid.." "..v[i].sequence.." "..self.stage)
				if v[i].sequence <= self.stage+1 and dieArr[v[i].gid] == nil then
					if v[i].sequence == self.stage + 1 then
						list [v[i].monster_id] = true
					end
					conf = MapConfig.GetMapMonsterConf(v[i].monster_id)
					--module.CemeteryModule.SetNextMonstergid(conf.gid)
					LoadNpc(conf)
				end
			end
		end
	end
	module.CemeteryModule.SetMonsterg_state(list)
	if self.MaxState == self.stage then
		showDlgError(nil,"副本完成")
	else
		--showDlgError(nil,"队伍进入第"..self.stage+1 .."阶段")
		-- if not DialogStack.GetPref_list("PveSchedule") then
		-- 	DialogStack.PushPref('PveSchedule',nil,UnityEngine.GameObject.FindWithTag("MapSceneUIRootMid").gameObject);
		-- end
		if not DialogStack.GetPref_list("TeamPveTime") then
			DialogStack.PushPref('TeamPveTime',nil,UnityEngine.GameObject.FindWithTag("MapSceneUIRootMid").gameObject);
		end
	end
	if module.QuestModule.GetOldUuid() ~= nil and module.QuestModule.GetOldUuid() == module.CemeteryModule.GetTEAM_PveStateUid(activityid) then
		--进入副本自动寻找当前阶段npc
		-- local teamDescribeConf = cemeteryConf.GetteamDescribeConf(module.CemeteryModule.Getactivityid())[self.stage+1]
		-- module.EncounterFightModule.GUIDE.Interact("NPC_"..teamDescribeConf.find_npc)
	end
	AssociatedLuaScript("guide/"..SmallTeamDungeonConf.GetTeam_battle_conf(activityid).script..".lua")
	--DispatchEvent("TASK_reactivation")
end
function View:listEvent()
	return{
	    "ClickOBJIdx",
	    "TEAM_INFO_CHANGE",
	    "QUERY_PLAYER_FIGHT_WIN_COUNT_REQUEST",
	    "update_monster_schedule",
	    "Leave_team_succeed",
}
end
return View