local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local guildTaskCfg = require "config.guildTaskConfig"
local Time = require "module.Time"
local MapConfig = require "config.MapConfig"
local UnionConfig = require "config.UnionConfig"


local npcid = nil;

local activity_score = nil;

local function setNpcid(_npcid)
	npcid = _npcid;
	-- ERROR_LOG(npcid,"设置NPCID=============>>>>>>>>>>>>>>");
end 

local rewardCfg = LoadDatabaseWithKey("guild_activity", "id");

-- ERROR_LOG("+++++++++++++++++",sprinttb(rewardCfg));
local function GetActivityReward(rankid)
	return rewardCfg[rankid];
end
--获取某个活动的周期
local function GetNowPeriod(index)
    local cfg = GetActivityReward(index)
    if not cfg then
        return nil
    end
    local begin_time = cfg.begin_time
    local end_time = cfg.end_time
    local period = cfg.period
    local duration = cfg.duration
    local ret = math.ceil((module.Time.now() + 1 - begin_time) / period);
    return ret
end

local SN_CallBack = nil;

local function GetRank(index,Period,co)

	SN_CallBack = SN_CallBack or {};
	
	local current = GetNowPeriod(index)
	-- ERROR_LOG(string.format( "获取第%s  周期%s",index,Period or current));
	local ret = NetworkService.Send(17103,{nil,index,Period or current,50})

	if co then
		SN_CallBack[ret] = { activityid = index,callback = co }
	end
end


local rankOpen = nil;

local function setOpen_Rank(flag)
	rankOpen = flag;
end

local function getOpen_Rank()
	return rankOpen;
end

EventManager.getInstance():addListener("server_respond_17104",function ( event,cmd,data )
	-- ERROR_LOG("server_respond_17104",sprinttb(data));

	local sn = data[1];

	if data[2] ==0 then
		local rank = {}
		for k,v in pairs(data[3]) do
			rank[k] = rank[k]  or {};

			rank[k].union_id = v[1];
			rank[k].rank = v[2];
			rank[k].score = v[3];
		end

		if SN_CallBack and SN_CallBack[sn] then
			SN_CallBack[sn].callback(rank);
		end	

	else
		if SN_CallBack and SN_CallBack[sn] then
			SN_CallBack[sn].callback(nil);
		end	
	end 
end)


local function GetRankReward(activityid,current,email)
	-- ERROR_LOG(string.format( "=======================获取奖励周期%s 方式%s,活动id%d",current,email or 0,activityid));
	NetworkService.Send(17105,{nil,activityid,current,email and email or 0})
end
-- 1142  

EventManager.getInstance():addListener("server_respond_17106",function ( event,cmd,data )
	ERROR_LOG("server_respond_17106",sprinttb(data));
	DispatchEvent("GET_RANK_REWARD_RET",data[2]);
end)

local SN_SELF = nil;
--获取自身工会的排行
local function GetSelfUnionRank(index,Period,func)
	local current = Period or GetNowPeriod(index)
	
	local union_id = module.unionModule.Manage:GetUionId()
	
	local sn = NetworkService.Send(17101,{nil,index,current,union_id})
	SN_SELF = SN_SELF or {};
	if func then
		SN_SELF[sn] = {activity = index,callback = func,union = union_id}
	end
end

local self_data = nil


EventManager.getInstance():addListener("server_respond_17102",function ( event,cmd,data )
	-- ERROR_LOG("server_respond_17102",sprinttb(data));

	local sn = data[1];
	activity_score = activity_score or {};

	activity_score[SN_SELF[sn].activity] = 0;
	print("活动ID",SN_SELF[sn].activity)
	if data[2] ~=0 then

		if SN_SELF and SN_SELF[sn] then
			SN_SELF[sn].callback(nil);
			print("重置节分")
			activity_score[SN_SELF[sn].activity] = 0;
		end
	else
		
		if SN_SELF and SN_SELF[sn] then
			self_data = {rank = data[3],union_id = SN_SELF[sn].union }
			activity_score[SN_SELF[sn].activity] = data[3][2];
			SN_SELF[sn].callback(self_data);
		end
	end
	
end)

local function getActivityScore( activity)
	return activity_score and activity_score[activity] or 0;
end

--接受到活动结束的通知

local function GetPeriodReward(activityid,offest)
	
	local period = GetNowPeriod(activityid) + (offest or 0) ;

	local config = UnionConfig.GetActivity(activityid);
	if config.activity_type == 1 then
		return;
	end
	local mapId = SceneStack.MapId();
	if tonumber(config.fuction) == mapId then
		GetRankReward(activityid,period);
	else
		if offest then
			GetRankReward(activityid,period + offest ,1)	
		end
		GetRankReward(activityid,period,1)
	end
end


EventManager.getInstance():addListener("server_notify_1142", function(event, cmd, data)
	-- module.TreasureModule.GetRankReward();
	-- ERROR_LOG("===============     ==================server_notify_1142",sprinttb(data));
	
	-- ERROR_LOG("activity id  is ",data[3]);
	if data[2] == 0 then
		local mapId = SceneStack.MapId();
		GetPeriodReward(data[3])
		DispatchEvent("GUILD_ACTIVITY_ENDNOTIFY",data[3]);		
	end

end)



EventManager.getInstance():addListener("server_notify_1145", function(event, cmd, data)
	-- ERROR_LOG("分数通知server_notify_1145",sprinttb(data));
	activity_score = activity_score or {};

	activity_score[data[1]] = data[2];
	DispatchEvent("GUILD_SCORE_INFO_CHANGE",data[1]);
end)


EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, cmd, data)

	for k,v in pairs(UnionConfig.GetActivity()) do
		if v.activity_type == 2 and v.id ~=5 then
			GetPeriodReward(k,-1);
		end
	end
end);

local oldTask = nil;

EventManager.getInstance():addListener("GUILD_TASK_CHANGEINFO", function(event, cmd, data)

	-- local mapId = SceneStack.MapId();

	-- local map_info = MapConfig.GetMapConf(mapid);

	if data then
		-- ERROR_LOG("任务发生改变");
		local info = guildTaskCfg.GetguildTask(data);
		local task = guildTaskModule.GetGuild_task_list();
		
		--已经完成
		if task[info.task_type][data] == 1 then
			oldTask = data;
		end
	end
	-- ERROR_LOG("LOCAL_HERO_QUEST_FINISH");
	-- if quest_id then
	-- 	ERROR_LOG("任务完成ID",quest_id)
	-- end
end);


local function GetSelfRank()
	return self_data;
end


local function getNpcid()
	return npcid;
end 


local rewardConfig = nil;

local function buildRewardCfg()
	
	rewardConfig = {}
	DATABASE.ForEach("rank_rewards_content", function(row)
		rewardConfig[row.id] = rewardConfig[row.id] or {};

		local reward = {};
		for i=1,3 do
			local _type = row["reward"..tostring(i).."_type"];
			local id = row["reward"..tostring(i).."_id"];
			local value = row["reward"..tostring(i).."_value"];

			if value ~=0 and id ~= 0 then
				table.insert(reward,{type = _type,value = value,id = id});
			end
			
		end
		row.reward = reward;
		table.insert( rewardConfig[row.id], row)
	end)
	for k,v in pairs(rewardConfig) do
		table.sort( v, function (a,b )
			return a.rank_range < b.rank_range;
		end )
	end
end


local function GetRewardConfig(id)

	if not rewardConfig then
		buildRewardCfg();
	end 
	print("奖励类型",id);
	return rewardConfig[id];
end
debug.traceback()


return {
	GetNowPeriod = GetNowPeriod,
	GetNpcid = getNpcid,
	SetNpcid = setNpcid,
	GetReward = GetRewardConfig,
	GetRank	 = GetRank,
	GetRankReward  = GetRankReward,
	GetUnionRank	= GetSelfUnionRank,
	GetSelfRank 	=GetSelfRank,
	GetActivity = GetActivityReward,
	SetOpen_Rank	= setOpen_Rank,
	GetOpen_Rank   	= getOpen_Rank,

	GetActivityScore = getActivityScore,
}