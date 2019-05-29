local EventManager = require "utils.EventManager"
local activityid = 0
local function Setactivityid(id)
	activityid = id
end
local function Getactivityid()
	return activityid
end
local NextMonstergid = 0
local function SetNextMonstergid(gid)
	NextMonstergid = gid
end
local function GetNextMonstergid()
	return NextMonstergid
end

local Combat_results_gid = nil
local function GetCombat_results_query()
	return Combat_results_gid
end
local function Combat_results_query(gid,reset)--战斗胜利后单独查询
	if gid or reset then
		Combat_results_gid = gid
	elseif Combat_results_gid then
		utils.NetworkService.Send(16066,{nil,{Combat_results_gid}})--查询个人战斗
		local teamInfo = module.TeamModule.GetTeamInfo();
		if teamInfo.group ~= 0 then
			utils.NetworkService.Send(16068,{nil,teamInfo.id,{Combat_results_gid}})--查询团队战斗
		end
		Combat_results_gid = nil
	end
end
EventManager.getInstance():addListener("server_notify_16048", function(event, cmd, data)
	-- ERROR_LOG("server_notify_16048",sprinttb(data))
	Combat_results_gid = data[1]
end)
---------------------------队伍墓园进度------------------------------------------
local function Query_Team_Record(gid,fights)
	local teamInfo = module.TeamModule.GetTeamInfo();
	if teamInfo and teamInfo.group ~= 0 then
		if fights then
			utils.NetworkService.Send(16068,{nil,teamInfo.id,fights})--查询团队战斗
		else
			local list1 = {}
            local list2 = {}
			local CemeteryConf = require "config.cemeteryConfig"
			local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
            local _count = 0
			for k,v in pairs(CemeteryConf.GetCemetery(gid) or {})do
				for k1,v1 in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(v.gid_id).idx) do
					for i = 1,#v1 do
                        if _count > 50 then
                            table.insert(list2, v1[i].gid)
                        else
                            table.insert(list1, v1[i].gid)
                            _count = _count + 1
                        end
					end
				end
			end
            if #list2 > 0 then
                utils.NetworkService.Send(16068,{nil, teamInfo.id, list2})
            end
			utils.NetworkService.Send(16068,{nil, teamInfo.id, list1})--查询团队战斗
		end
	end
end

local TEAM_PveStateUid = {}
local function GetTEAM_PveStateUid(gid)
	if gid then
		return TEAM_PveStateUid[gid]
	end
return TEAM_PveStateUid
end
local TEAMRecord = {}
local function GetTEAMRecord(gid)
	if gid then
		return TEAMRecord[gid]
	end
	return TEAMRecord
end
local function RestTEAMRecord()
	TEAMRecord = {}
	Query_Team_Record(1)
    Query_Team_Record(2)
end
local function SetTEAMRecord(data)
	for i = 1,#data do
		--if data[i][2] > 0 then
		TEAMRecord[data[i][1]] = data[i][2]
		--end
	end
end
local function Query_Team_Fight_Win_Count(data)
	local TeamModule = require "module.TeamModule"
	local teamInfo = TeamModule.GetTeamInfo();
	if teamInfo.group == 0 then
		return
	end
	local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
	local PveState = 0
	for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(activityid).idx) do
		for i = 1,#v do
			if TEAMRecord[v[i].gid] > 0 then
				if PveState < SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence then
					PveState = SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence
				end
			end
		end
	end
	local Team_battle_conf = SmallTeamDungeonConf.GetTeam_battle_conf(activityid)
	local _Type = Team_battle_conf.difficult
	local cemeteryConf = require "config.cemeteryConfig"
	--ERROR_LOG(activityid..">"..PveState)
	local teamDescribeConf = cemeteryConf.GetteamDescribeConf(activityid)[PveState+1]
	local test_info = {
	type = (_Type == 1 and 4 or 5),
	up_tittle2 = 2002,
	number = 0,
	desc = teamDescribeConf.des1,--"墓园队伍进度 "..(PveState+1).." 阶段",
	name = teamDescribeConf.des,
    desc2 = teamDescribeConf.des2,
	cfg = {name = teamDescribeConf.des,desc = teamDescribeConf.des1},
	is_show_on_task = 0,
    icon = teamDescribeConf.icon,
	reward = nil,
	status = 0,
    battleGid = Team_battle_conf.gid_id, --副本id
	find_npc = teamDescribeConf.find_npc,
	pos = {Team_battle_conf.enter_x,Team_battle_conf.enter_y,Team_battle_conf.enter_z},
	Accomplish = (cemeteryConf.GetteamDescribeConf(activityid)[PveState+2] == nil and true or false),
	script = "guide/10004.lua",
	uuid = TEAM_PveStateUid[activityid] and TEAM_PveStateUid[activityid] or nil,
    mapId = teamDescribeConf.mapid
	}
	local uid = module.QuestModule.RegisterQuest(test_info)
	local teamInfo = module.TeamModule.GetTeamInfo();
    if teamInfo.group == 0 or module.playerModule.Get().id == teamInfo.leader.pid then
		module.QuestModule.SetOldUuid(uid)
	end
	--ERROR_LOG("uid->"..uid)
	TEAM_PveStateUid[activityid] = uid
end
local function ContinuePve()
	local cemeteryConf = require "config.cemeteryConfig"
	local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
	local Team_battle_conf = SmallTeamDungeonConf.GetTeam_battle_conf(activityid)
	local PveState = 0
	for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(activityid).idx) do
		for i = 1,#v do
			if TEAMRecord[v[i].gid] > 0 then
				if PveState < SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence then
					PveState = SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence
				end
			end
		end
	end
	local teamDescribeConf = cemeteryConf.GetteamDescribeConf(activityid)[PveState+1]
    local quest = {
    	script = "guide/10004.lua",
		find_npc = teamDescribeConf.find_npc,
		pos = {Team_battle_conf.enter_x,Team_battle_conf.enter_y,Team_battle_conf.enter_z},
		Accomplish = (cemeteryConf.GetteamDescribeConf(activityid)[PveState+2] == nil and true or false),
	}
    module.QuestModule.callQuestScript(quest, "Guide")
end

local Monsterg_state = {}
local function SetMonsterg_state(list)
	Monsterg_state = list
end
local function GetMonsterg_state(id)
	return Monsterg_state[id]
end
local function LoadMap_Accomplish()--加载地图检测是否有副本任务可以完成（删除）
	for k,v in pairs(TEAM_PveStateUid) do
		local quest = module.QuestModule.Get(v)
    	if quest and quest.Accomplish then
    		module.CemeteryModule.RestCemetery(function ()
		        module.QuestModule.Cancel(v)
                module.QuestModule.SetOldUuid(nil)
		    end,k)
    	end
	end
end
---------------------重置副本---------------------------------------------
local RestCemeterySn = {}
local function RestCemetery(fun,id)
	local _activityid = nil
	if id then
		_activityid = id
	else
		_activityid = activityid
	end
	local TeamModule = require "module.TeamModule"
	local teamInfo = TeamModule.GetTeamInfo();
	if teamInfo.id <= 0 then
		return
	end
	local fights = {}
	local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
	if SmallTeamDungeonConf.GetTeam_pve_fight(_activityid) then
		for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(_activityid).idx) do
			for i = 1,#v do
				fights[#fights+1] = v[i].gid
			end
		end
		--local sn = utils.NetworkService.Send(16084,{nil,teamInfo.id,fights})--重置副本进度
		local sn = utils.NetworkService.Send(16084,{nil,teamInfo.id,_activityid})--重置副本进度
		RestCemeterySn[sn] = {fun = fun ,fights = fights,activityid = _activityid}
	end
end

EventManager.getInstance():addListener("server_respond_16085", function(event, cmd, data)
	--ERROR_LOG("重置副本16085->",sprinttb(data))
	local sn = data[1]
	local err = data[2]
    if err == 0 then
    	showDlgError(nil,"重置副本成功")
    	if RestCemeterySn[sn] then
    		module.TeamModule.SetTeamPveTime(RestCemeterySn[sn].activityid,0,0)--重置副本，直接重置当前副本时间
    		RestCemeterySn[sn].fun()--删除任务
    		local fights = RestCemeterySn[sn].fights
    		if fights then
    			for i = 1,#fights do
    				TEAMRecord[fights[i]] = 0--重置当前团本
    			end
    		end
    		RestCemeterySn[sn] = nil
    	end
    else
    	showDlgError(nil,"重置副本失败")
    end
end)
-------------------------个人墓园进度---------------------------------------------
local function Query_Player_Record(gid)
	local CemeteryConf = require "config.cemeteryConfig"
	local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
	local fights = {}
	for k,v in pairs(CemeteryConf.GetCemetery(gid) or {})do
		if SmallTeamDungeonConf.GetTeam_pve_fight(v.gid_id) then
			for k1,v1 in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(v.gid_id).idx) do
				for i = 1,#v1 do
					fights[#fights+1] = v1[i].gid
				end
			end
		else
			ERROR_LOG("config_team_battle_config的gid_id《"..v.gid_id.."》在config_team_pve_fight_config中gid_id不存在")
		end
	end
	utils.NetworkService.Send(16066,{nil,fights})--查询个人副本战斗胜利次数
	Query_Team_Record(gid,fights)
end
local PlayerRecord = {}
local function GetPlayerRecord(gid)
	return PlayerRecord[gid]
end
local function SetPlayerRecord(data)
	for i = 1,#data do
		--if data[i][2] > 0 then
			PlayerRecord[data[i][1]] = data[i][2]
		--end
	end
end
local function Query_Player_Fight_Win_Count(activityid)
	local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
	local PveState = 0
	for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(activityid).idx) do
		for i = 1,#v do
			if PlayerRecord[v[i].gid] > 0 then
				if PveState < SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence then
					PveState = SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence
				end
			end
		end
	end
	return PveState
end
-----------------个人进度用来显示活动数据---------------------------
local TeamPveFightList = {}
local TeamPveFightData = {}
local function SetTeamPveFight(gid,idx,count,data)
	if not TeamPveFightData[ gid ] then
		TeamPveFightData[ gid ] = {}
	end
	local playerdata = data
	local schedule = {count = 0,Max = count,list = {},gid = gid, idx = idx}
	local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
	-- ERROR_LOG(sprinttb(playerdata))
	for i = 1,#playerdata do
		if playerdata[i][2] and playerdata[i][2] > 0 then
			--if schedule[ SmallTeamDungeonConf.GetTeam_pve_fight_gid(playerdata[i][1]).sequence ] then
				schedule.list[ SmallTeamDungeonConf.GetTeam_pve_fight_gid(playerdata[i][1]).sequence ] = true
			--end
		elseif not schedule.list[ SmallTeamDungeonConf.GetTeam_pve_fight_gid(playerdata[i][1]).sequence ] then
			schedule.list[ SmallTeamDungeonConf.GetTeam_pve_fight_gid(playerdata[i][1]).sequence ] = false
		end
	end
	for i = 1, #schedule.list do
		if schedule.list[i] then
			schedule.count = schedule.count + 1
		end
	end
	--ERROR_LOG(">"..sprinttb(schedule))
	TeamPveFightData[ gid ][ idx ] = schedule
	local listData = nil
	for i = 1,#TeamPveFightData[ gid ] do
		if i == 1 then
			listData = TeamPveFightData[ gid ][i]--默认先存进去第一个进度的数据
		else
			if TeamPveFightData[ gid ][i].count > listData.count then--进度比对，拿最大进度的存TeamPveFightList
				listData = TeamPveFightData[ gid ][i]
			end
		end
	end
	--ERROR_LOG(sprinttb(listData))
	TeamPveFightList[listData.gid] = listData
end

local function GetTeamPveFight(gid)
	local idx = 0
	local CemeteryConf = require "config.cemeteryConfig"
	for k,v in pairs(CemeteryConf.GetCemetery(gid))do
		--self.CemeteryArr[#self.CemeteryArr+1] = v
		local fights = {}
		local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
		local count = 0
		for k1,v1 in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(v.gid_id).idx) do
			for i = 1,#v1 do
				fights[#fights+1] = {v1[i].gid,PlayerRecord[v1[i].gid]}
			end
			count = count + 1
		end
		idx = idx + 1
		SetTeamPveFight(gid,idx,count,fights)
	end
end

local function GetTeamPveFightList(gid)
	GetTeamPveFight(gid)
	--ERROR_LOG(sprinttb(TeamPveFightList[gid]))
	return TeamPveFightList[gid]
end
-----------------------------------------------------------------------------
local function GetTeam_stage(gid_id)
	if gid_id == nil then
		gid_id = activityid
	end
	local PveState = 0
	local max = 0
	local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
	for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(gid_id).idx) do
		for i = 1,#v do
			if GetTEAMRecord(v[i].gid) and GetTEAMRecord(v[i].gid) > 0 then
				if PveState < SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence then
					PveState = SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence
				end
			end
		end
		max = max + 1
	end
	return PveState,max
end
local function Query_Pve_Schedule(activity_id)
	local CemeteryConf = require "config.cemeteryConfig"
	local ItemModule = require "module.ItemModule"
	local data = CemeteryConf.Getteam_battle_activity(activity_id,1)
	if data then
		return ItemModule.GetItemCount(data.rewrad_count_one),ItemModule.GetItemCount(data.rewrad_count_ten)
	end
end
return{
	Setactivityid = Setactivityid,
	Getactivityid = Getactivityid,
	SetNextMonstergid = SetNextMonstergid,
	GetNextMonstergid = GetNextMonstergid,

	GetPlayerRecord = GetPlayerRecord,

	Query_Player_Fight_Win_Count = Query_Player_Fight_Win_Count,

	Query_Team_Fight_Win_Count = Query_Team_Fight_Win_Count,
	GetTEAM_PveStateUid = GetTEAM_PveStateUid,

	GetTEAMRecord = GetTEAMRecord,
	RestCemetery = RestCemetery,
	GetTeamPveFight = GetTeamPveFight,
	SetTeamPveFight = SetTeamPveFight,
	GetTeamPveFightList = GetTeamPveFightList,
	SetPlayerRecord = SetPlayerRecord,
	SetTEAMRecord = SetTEAMRecord,
	GetMonsterg_state = GetMonsterg_state,
	SetMonsterg_state = SetMonsterg_state,
	Combat_results_query = Combat_results_query,
	Query_Team_Record = Query_Team_Record,
	Query_Player_Record = Query_Player_Record,
	RestTEAMRecord = RestTEAMRecord,
	GetCombat_results_query = GetCombat_results_query,
	GetTeam_stage = GetTeam_stage,
	LoadMap_Accomplish = LoadMap_Accomplish,
	Query_Pve_Schedule = Query_Pve_Schedule,
	ContinuePve = ContinuePve,
}
