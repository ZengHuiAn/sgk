local TAG = "FishModule"
local Time = require "module.Time"
local NetworkService = require 'utils.NetworkService'
local EventManager = require 'utils.EventManager';
local FishConfig = require "config.FishConfig"
local ItemModule = require "module.ItemModule"
local PlayerModule = require "module.playerModule"

local function show_tips(id)
	-- print("FishModule================>>ERROR:", id)
end

local roomData = nil;

local function getMyRoomData()
	return roomData;
end

--查询房间
local function queryRoom()
	NetworkService.Send(16233);
end
NetworkService.Listen(16233,function (event,cmd,data)
	-- print(TAG,"============>>16233查询钓鱼房间：",sprinttb(data))
	if data[2] ~= 0 then --3 不在钓鱼房间中
		return;
	end
	roomData = {};
	roomData.leaderID = data[3];
	local mates = {};
	roomData.teamMates = mates;
	for i,v in ipairs(data[4] or {}) do
		mates[i] = {};
		mates[i].pid = v[1];
		mates[i].status = v[2]; -- 玩家状态（正常钓鱼 = 0、自动钓鱼 = 1， 停止钓鱼 = 2）
		local fishes = {};
		mates[i].fishes = fishes;
		local fish_times = 0;
		if v[4] and type(v[4]) == "table" then
			for _,fish in pairs(v[4] or {}) do
				local fish_id = fish[2];
				fishes[fish_id] = fishes[fish_id] or 0;
				fishes[fish_id] = fishes[fish_id] + 1;
				fish_times = fish_times + 1;
			end
		end
		mates[i].fish_times = fish_times;
	end
	DispatchEvent("FISH_QUERY_ROOM");
end)


--创建房间
local function createRoom(flag)
	if roomData then
		return roomData
	else
		if flag then
			NetworkService.Send(16231);
		end
	end
end
NetworkService.Listen(16231,function (event,cmd,data)
	-- print(TAG,"============>>16231申请房间：",sprinttb(data))
	if data[2] == 0 then
		queryRoom();
	else
		DispatchEvent("showDlgError", {nil, "创建失败"})
	end
end)


--离开钓鱼
local function quitRoom(force)
	NetworkService.Send(16255);
end
NetworkService.Listen(16255,function (event,cmd,data)
	-- print(TAG,"============>>16255退出房间：",sprinttb(data))
	if data[2] ~= 0 then
		return DispatchEvent("showDlgError", {nil, "创建失败"}) ;
	end
	roomData = nil;
	DispatchEvent("FISH_QUIT_ROOM");
end)

--tp:1免费 2付费 nil总的次数
local function getTimesCount(tp)
	local fish_consume = FishConfig.getConsumeInfo()
	local freeTimes = ItemModule.GetItemCount(fish_consume.free_consume.id);
	local moneyTimes = ItemModule.GetItemCount(fish_consume.money_consume.id);
	local totleTimes = 0;
	-- print(TAG,"===========>>免费,付费:",freeTimes,moneyTimes);
	if tp == 1 then
		return freeTimes;
	elseif tp == 2 then
		return moneyTimes;
	else
		return freeTimes + moneyTimes;
	end
end

local isPushing = false;--是否抛竿
local minPullTime = nil;--最早收竿时间
local needPullTime = nil;--需要几秒才能收竿
local last_fish_reward = {};--钓鱼奖励
local function checkPushing()
	return isPushing;
end
local function getMinPullTime()
	return minPullTime,needPullTime;
end
local function getFishReward()
	return last_fish_reward;
end
--甩竿 type:奖池
local function pushRod(type)
	last_fish_reward = nil
	if type then
		local isFree = 1;
		local freeCount = getTimesCount(1);
		if freeCount <= 0 then
			isFree = 2;
		end
		local moneyTimes = getTimesCount(2);
		if isFree == 1 or moneyTimes > 0 then
			NetworkService.Send(16243,{nil,tonumber(type),isFree});
		end
	end
end
NetworkService.Listen(16243,function (event,cmd,data)
	-- print(TAG,"============>>16243甩竿：",sprinttb(data))
	if data[2] == 10 then
		return DispatchEvent("showDlgError", {nil, "鱼饵不足"})
	elseif data[2] ~= 0 then
		return showDlgError(nil,"甩竿失败！");
	end
	isPushing = true;
	local offTime = data[3];--consume_cfg and consume_cfg.gofish_time or 20;
	minPullTime = Time.now() + offTime;
	needPullTime = offTime;
	-- print(TAG,"============>>>最小收竿时间", minPullTime, offTime);
	DispatchEvent("FISH_PUSH_ROD");
end)

local function outRoom()
	isPushing = false;
	minPullTime = nil;
	needPullTime = nil;
	last_fish_reward = nil;
end


--收竿
local function pullRod()
	-- print(TAG,"ccccccccccccccc收竿请求");
	NetworkService.Send(16245);
end
NetworkService.Listen(16245,function (event,cmd,data)
	-- print(TAG,"============>>16245收竿返回：",Time.now(),sprinttb(data))
	if data[2] == 12 then
		
		return showDlgError(nil," 收竿时间未到！");
	elseif data[2] == 3 then --鱼溜走了
		return DispatchEvent("FISH_PULL_ROD", data[2])
	elseif data[2] ~= 0 then
		return showDlgError(nil," 收竿失败！");
	end
	isPushing = false;
	local sub_type = data[3];
	last_fish_reward = {}
	last_fish_reward.sub_type = sub_type;--( 0是普通鱼，直接收，1是特殊鱼，2是大型鱼，nil鱼溜走了 )
	if data[4] then
		last_fish_reward.type = data[4][1];
		last_fish_reward.id = data[4][2];
		last_fish_reward.value = data[4][3];
	end
	minPullTime = nil;
	needPullTime = nil;
	queryRoom();
	DispatchEvent("FISH_PULL_ROD", data[3]);
end)


--溜鱼 协助的那个人的Id（如果是遛鱼，则是自己id）
local function playFish(pid)
	pid = pid or PlayerModule.GetSelfID();
	NetworkService.Send(16247,{nil,pid});
end
NetworkService.Listen(16247,function (event,cmd,data)
	-- print(TAG,"============>>16247溜鱼：",sprinttb(data))
	if data[2] ~= 0 then
		return
	end
	--data[3]:fight_id(可能有)
	DispatchEvent("FISH_PLAY_FISH");
end)

--自动钓鱼和取消自动钓鱼 16251/16252
local function autoFish(status)
	if status then
		NetworkService.Send(16251,{nil,status});
		-- print(TAG,"========================来请求自动钓鱼",status);
	end
end
NetworkService.Listen(16251,function (event,cmd,data)
	-- print(TAG,"============>>16251是否自动钓鱼：",sprinttb(data))
	if data[2] ~= 0 then
		return DispatchEvent("showDlgError", {nil, "切换钓鱼状态失败！"})
	end
end)


local fishRanks = nil;
local last_rank_time = 0;
--查询排行榜 16253/16254
local function getFishRank(force)
	local now = TimeTools.now();
	if not fishRanks or (last_rank_time + 60 < now) or force then
		NetworkService.Send(16253);
		return;
	end
	return fishRanks;
end
NetworkService.Listen(16253,function (event,cmd,data)
	-- print(TAG,"============>>16253查询排行榜：",sprinttb(data))
	if data[2] ~= 0 then
		return DispatchEvent("showDlgError", {nil, "查询排行榜失败！"});
	end
	last_rank_time = TimeTools.now();
	fishRanks = {};
	fishRanks.all = {};
	fishRanks.mine = {};
	for i,v in ipairs(data[3] or {}) do
		fishRanks.all[i] = {pid = v[1], score = v[2]};
	end
	if data[4] then
		fishRanks.mine.rank = data[4][1];
		fishRanks.mine.score = data[4][2];
	end

	DispatchEvent("FISH_QUERY_RANK");
end)


--QTE操作确认 16257/16258 1:正确  2：错误
local flag = false
local function playQTE(status)
	-- print(TAG,"=======>>playQTE",status,Time.now(),flag);
	if flag then
		return
	end
	flag = true
	if status then
		NetworkService.Send(16257,{nil,status});
	end
end
NetworkService.Listen(16257,function (event,cmd,data)
	-- print(TAG,"============>>16257QTE操作：",sprinttb(data))
	flag = false
	queryRoom();
	DispatchEvent("FISH_PLAYER_QTE",data[3]);
end)


--4.通知其他玩家自己钓到什么鱼 16274
NetworkService.Notify(16274,function (event,cmd,data)---------->
	-- print(TAG,"...==========>>16274notify钓到非普通鱼:",sprinttb(data))
	-- respond[1] = 钓到鱼的玩家id
	-- respond[2] = 钓到的鱼type
	-- respond[3] = 钓到的鱼id
	-- respond[4] = 钓到的鱼value
	-- respond[5] = 钓到的鱼类型(普通0 稀有1 大2)
	-- local id = PlayerModule.GetSelfID();
	-- if id and id == data[1] then
	-- 	last_fish_reward.type = data[2];
	-- 	last_fish_reward.id = data[3];
	-- 	last_fish_reward.value = data[4];
	-- 	last_fish_reward.sub_type = data[5];
	-- 	if data[5] == 2 then
	-- 		DispatchEvent("FISH_SHOW_BIG");
	-- 		cacheRoomBigFish[data[1]].later_help_time = 0;
	-- 		synCacheToData();
	-- 	end
	-- end
	-- queryRoom();
end)

local function doQuitRoom()
	if roomData and roomData.leaderID then
		quitRoom(true);
	end
end

local function resetPushing()
	isPushing = false;
end

EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, pid)
	queryRoom();
end)

return{
	CreateRoom 		= createRoom,
	QuitRoom 		= quitRoom,
	QueryRoom 		= queryRoom,
	GetMyRoomData 	= getMyRoomData,
	PushRod 		= pushRod,
	PullRod 		= pullRod,
	CheckPushing 	= checkPushing,
	GetFishReward 	= getFishReward,
	GetMinPullTime 	= getMinPullTime,
	AutoFish 		= autoFish,
	PlayQTE 		= playQTE,
	GetFishRank 	= getFishRank,
	PlayFish 		= playFish,
	GetTimesCount 	= getTimesCount,
	DoQuitRoom		= doQuitRoom,
	OutRoom 		= outRoom, --清空数据
	ResetPushing    = resetPushing,
}