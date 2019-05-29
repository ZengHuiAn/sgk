local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Time = require "module.Time";

local DataArr = {}
local SnArr = {}--活动sn
local PlaySnArr = {}--查询玩家信息的sn
local DrawCardSnArr = {}--抽卡信息的sn

local drawCardShowConfig = nil;
local function GetDrawCardShowConfig(id)
	if drawCardShowConfig == nil then
		drawCardShowConfig = LoadDatabaseWithKey("sweepstake_show", "id");
	end
	return drawCardShowConfig[id]
end

local drawCardRewardConfig = nil
local function GetDrawCardRewardConfig(id)
	if drawCardRewardConfig == nil then
		drawCardRewardConfig = {};
		DATABASE.ForEach("sweepstake_reward_show", function(row)
			drawCardRewardConfig[row.reward_pool_id] = drawCardRewardConfig[row.reward_pool_id] or {};
			table.insert(drawCardRewardConfig[row.reward_pool_id], row)
		end)
	end
	return drawCardRewardConfig[id]
end

local function CheckPoolOpen(data)
	for i,v in ipairs(data) do
		if v.begin_time <= Time.now() and v.end_time > Time.now() then
			local delta = Time.now() - v.begin_time;
			if v.duration == 0 or delta % v.period < v.duration then
				return true;
			end
		end	
	end
	return false;
end

local function Set(type,data)
	if type and data then
		local temp = {}
		for i = 1,#data do
			local gid = data[i][1]
			
			local active_time = {};
			if data[i][22] then
				for _,v in ipairs(data[i][22]) do
					local info = {};
					info.pool_type = v[1];
					info.begin_time = v[2];
					info.end_time = v[3];
					info.period = v[4];
					info.duration = v[5];
					table.insert(active_time, info);
				end
			end
			temp[gid] = {
				id = data[i][1],
				pool_type = tonumber(data[i][2]),
				begin_time = data[i][3],
				end_time = data[i][4],
				free_gap = data[i][5],
				guarantee_count = data[i][6],
				consume_type = data[i][7],
				consume_id = data[i][8],
				price = data[i][9],
				combo_price = data[i][10],
				combo_count = data[i][11],
				ref_consume_type = data[i][12],
				ref_consume_id = data[i][13],
				ref_price = data[i][14],
				free_Item_type = data[i][15],	--免费抽取时候扣除的道具类型	0不限制
				free_Item_id = data[i][16],--免费抽取时候扣除的道具id	0限制
				free_Item_consume = data[i][17],--免费抽取时候扣除的道具数量	0限制
				consume_type2 = data[i][18], 
				consume_id2 = data[i][19], 
				price2 = data[i][20], 
				combo_price2 = data[i][21],
				active_time = active_time,
				CardData = {
					last_free_time = 0,--最后免费抽取时间
					total_count = 0,--保底抽取次数
					has_used_gold = 0,--是否是首抽
					last_draw_time = 0,--最后抽取时间
					today_draw_count = 0,--今天抽取次数
					current_pool = 0,--上一次抽取的法阵id
					current_pool_draw_count = 0,--上一次法阵已抽取的数量
					current_pool_end_time = 0,--法阵消失的时间
					current_pool_draw_Max = 0,--法阵可抽取的最大值
				},
			}
			if CheckPoolOpen(active_time) then
				local sn = NetworkService.Send(15083,{nil, data[i][1]})--查询玩家抽奖信息
				PlaySnArr[sn] = gid
			end
			-- ERROR_LOG("数据", gid, sprinttb(temp[gid]))
		end
		DataArr[type] = temp
	end
end

local function Get(activity_type, id)
	DataArr = DataArr or {}
	if DataArr[activity_type] == nil then
		DataArr[activity_type] = {}
		local sn = NetworkService.Send(15081,{nil, activity_type});
		SnArr[sn] = activity_type
	end

	local list = DataArr[activity_type];
	if not id then
		return list
	end
	list = {}
	for _, v in pairs(DataArr[activity_type]) do
		--print(v.id)
		if v.id == id then
			list[#list + 1] = v;
		end
	end

	return list;
end
local Herolist = {}
local function GetSortHeroList()--获得已有英雄列表
	return Herolist
end

local is_draw = true 
local function DrawCard(id,pool_type,consume,isCombo,use_consume2)
	print("抽奖", id,pool_type,consume,isCombo,use_consume2, sprinttb(consume))
	if id and consume and isCombo then
		Herolist = module.HeroModule.GetSortHeroList(1)--抽奖前刷新已有英雄列表
		local sn = NetworkService.Send(15079,{nil, id, pool_type, consume, isCombo, 0, use_consume2});
		DrawCardSnArr[sn] = id
		is_draw = true
	end
end

local function MagicCircle(id,pool_type,consume,isCombo,use_free)
	if id and consume and isCombo then
		Herolist = module.HeroModule.GetSortHeroList(1)--法阵刷新前刷新已有英雄列表
		local sn = NetworkService.Send(15097,{nil, id,pool_type,consume,isCombo,use_free and use_free or false});
		DrawCardSnArr[sn] = id
		is_draw = false
	end
end
local DrawIndex = {}
local function GetDrawIndex()
	local idx = DrawIndex[1] or 0
	table.remove(DrawIndex,1)
	return idx
end
local function GetManager(activity_type, id)
	return Get(activity_type, id)
end

local function GetDrawCardRedDot()
	local activity_id = {1, 4, 5};
	for i,v in ipairs(activity_id) do
		local ActivityData = GetManager(v);
		for k,j in pairs(ActivityData) do
			if CheckPoolOpen(j.active_time) then
				local last_free_time = j.CardData.last_free_time
				local time =  math.floor(Time.now() - last_free_time)
				if time >= j.free_gap and (j.free_Item_id == 0 or module.ItemModule.GetItemCount(j.free_Item_id) > 0)then
					return true
				end
			end
		end
	end
	return false
end

local function StartDraw(type,idx)--开始抽取
	--type 1金币抽取2钻石抽取3刷新法阵
	local Time = require "module.Time"
	local ItemModule = require "module.ItemModule"
	local ActivityData = GetManager(1)
	DispatchEvent("DrawLockChange",false)--开始抽取锁定所有按钮点击
	if type == 1 then
		local data = ActivityData[type]
		local time =  math.floor(Time.now()  - data.CardData.last_free_time)
		if time >= data.free_gap then
			if data.free_Item_id == 0 or math.floor(ItemModule.GetItemCount(data.free_Item_id)/data.free_Item_consume) > 0 then
				local consume = {data.consume_type,data.consume_id,0}--0金币始终用免费
				DrawCard(data.id,data.pool_type,consume,0)
				return true
			else
				showDlgError(nil,"今日抽奖次数已用完")
			end
		else
			showDlgError(nil,"时间未到")
		end
	elseif type == 2 or type == 3 then
		SetItemTipsState(false)--暂时关闭物品获取提示
		local data = ActivityData[2]
		local time =  math.floor(Time.now()  - data.CardData.last_free_time)
		if ItemModule.GetItemCount(data.consume_id) >= data.price or time >= data.free_gap then
			local consume = {data.consume_type,data.consume_id,data.price}
			if time >= data.free_gap then
				consume[3] = 0--使用免费
			end
			if type == 2 then
				DrawIndex[#DrawIndex+1] = idx
				DrawCard(data.id,data.CardData.current_pool,consume,0)--抽一次
			else
				MagicCircle(data.id,data.pool_type,consume,0)--换法阵并抽一次
			end
			return true
		else
			local ItemHelper = require "utils.ItemHelper"
			local item = ItemHelper.Get(ItemHelper.TYPE.ITEM, data.consume_id);
			showDlgError(nil,item.name.."不足")
		end
	end
	DispatchEvent("DrawLockChange",true)
	return false
end

local ChangePoolSnArr = {}
local function ChangePool(activity_id,activity_type)
	local sn = NetworkService.Send(15095,{nil,activity_id});
	ChangePoolSnArr[sn] = {id = activity_id,type = activity_type}
end

EventManager.getInstance():addListener("server_respond_15096", function(event, cmd, data)
	local sn = data[1]
	local err = data[2];
	if err == 0 then
		-- print("更换奖池成功"..sprinttb(data));
		local activity_type = ChangePoolSnArr[sn].type
		local activity_id = ChangePoolSnArr[sn].id
		ChangePoolSnArr[sn] = nil
		DataArr[activity_type][activity_id].CardData.current_pool = data[3]
		DispatchEvent("Change_Pool_Succeed",data[3]);
	else
		print("更换奖池失败",err);
	end
end)

local UserDefault = require "utils.UserDefault"
local DrawCard_data = UserDefault.Load("DrawCard_data",true);
local function GetDrawNextIndex(type)	
	DrawCard_data.list =  DrawCard_data.list or {}
	local ActivityData = GetManager(1)
	local idxs = {}
	for i = 1,ActivityData[2].CardData.current_pool_draw_Max do
		if not DrawCard_data.list[i] then
			if type == 1 then
				idxs[#idxs+1] = i
			else
				return i
			end
		end
	end
	return idxs
end
--活动刷新
EventManager.getInstance():addListener("server_respond_15082", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		print("活动配置刷新Succeed",SnArr[sn],sprinttb(data[3]));
		local activity_type = SnArr[sn]
		if activity_type then
			SnArr[sn] = nil;
			Set(activity_type, data[3]);
		end
	else
		print("活动配置刷新err", err);
	end
end)
--玩家抽卡信息刷新
EventManager.getInstance():addListener("server_respond_15084", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		print("玩家抽卡信息刷新Succeed",PlaySnArr[sn],sprinttb(data[3]));
		local DrawCardid = PlaySnArr[sn]
		if DrawCardid then
			local activity_type = 0;
			for type,v in pairs(DataArr) do
				for id,j in pairs(v) do
					if id == DrawCardid then
						activity_type = type;
						break;
					end
				end
				if activity_type ~= 0 then
					break;
				end
			end
			PlaySnArr[sn] = nil;
			DataArr[activity_type][DrawCardid].CardData.last_free_time = data[3][1]
			DataArr[activity_type][DrawCardid].CardData.total_count = data[3][2]
			DataArr[activity_type][DrawCardid].CardData.has_used_gold = data[3][3]
			DataArr[activity_type][DrawCardid].CardData.last_draw_time = data[3][4]
			DataArr[activity_type][DrawCardid].CardData.today_draw_count = data[3][5]
			DataArr[activity_type][DrawCardid].CardData.current_pool = data[3][6]--上一次抽取的法阵id
			DataArr[activity_type][DrawCardid].CardData.current_pool_draw_count = data[3][7]--上一次法阵已抽取的数量
			DataArr[activity_type][DrawCardid].CardData.current_pool_end_time = data[3][8]--法阵消失的时间
			DataArr[activity_type][DrawCardid].CardData.current_pool_draw_Max = data[3][9] or 0--法阵可抽取的最大值
			-- if data[3][6] == 0 then
			-- 	print("奖池为0，更换奖池", DrawCardid, activity_type);
			-- 	ChangePool(DrawCardid, activity_type);
			-- end
		end
		DispatchEvent("Activity_INFO_CHANGE",is_draw);
		DispatchEvent("LOCAL_ACTIVITY_INFO_CHANGE",DrawCardid);
		if not is_draw then
			is_draw = true
		end
	else
		print("玩家抽卡信息刷新err",PlaySnArr[sn], err);
	end
end)

EventManager.getInstance():addListener("server_respond_15080", function(event, cmd, data)
	local sn = data[1]
	local err = data[2];
	if err == 0 then
		-- print("抽奖成功"..sprinttb(data[3]));
		if DrawCardSnArr[sn] then
			local sn2 = NetworkService.Send(15083,{nil,DrawCardSnArr[sn]})--查询玩家抽奖信息
			PlaySnArr[sn2] = DrawCardSnArr[sn]
			DrawCardSnArr[sn] = nil
		end
		SGK.ResourcesManager.LoadAsync("sound/posui.mp3",typeof(UnityEngine.AudioClip),function (Audio)
			SGK.BackgroundMusicService.PlayUIClickSound(Audio)
		end)
		DispatchEvent("DrawCard_Succeed",data[3]);
	else
		DispatchEvent("DrawCard_Failed", err);
		print("抽奖失败",err);
	end
	DispatchEvent("DrawCard_callback")
end)
EventManager.getInstance():addListener("server_respond_15098", function(event, cmd, data)
	local sn = data[1]
	local err = data[2];
	if err == 0 then
		-- ERROR_LOG("法阵刷新成功"..sprinttb(data));
		SGK.ResourcesManager.LoadAsync("sound/fazhen.mp3",typeof(UnityEngine.AudioClip),function (Audio)
			SGK.BackgroundMusicService.PlayUIClickSound(Audio)
		end)
		DispatchEvent("sweepstake_change_pool",data);
		if DrawCardSnArr[sn] then
			local sn2 = NetworkService.Send(15083,{nil,DrawCardSnArr[sn]})--查询玩家抽奖信息
			PlaySnArr[sn2] = DrawCardSnArr[sn]
			DrawCardSnArr[sn] = nil
		end
	else
		print("法阵刷新新失败",err);
	end
	DispatchEvent("sweepstake_callback")
end)

local function QueryDrawCardData(id)
	local sn2 = NetworkService.Send(15083,{nil,id})--查询玩家抽奖信息
	PlaySnArr[sn2] = id
end

--登录成功就查询 每日抽奖
EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, cmd, data)
	GetManager(1)--抽卡
	GetManager(2)--福利扭蛋机
	GetManager(3)--建设城市 抽奖
	GetManager(4)
	GetManager(5)
end)

return {
	GetManager = GetManager,
	DrawCard = DrawCard,
	ChangePool=ChangePool,
	QueryDrawCardData=QueryDrawCardData,
	MagicCircle = MagicCircle,
	GetSortHeroList = GetSortHeroList,
	GetDrawCardRedDot = GetDrawCardRedDot,
	StartDraw = StartDraw,
	GetDrawIndex = GetDrawIndex,
	GetDrawNextIndex = GetDrawNextIndex,
	GetDrawCardShowConfig = GetDrawCardShowConfig,
	GetDrawCardRewardConfig = GetDrawCardRewardConfig,
	CheckPoolOpen = CheckPoolOpen,
};


