local playerModule = require "module.playerModule"
local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Time = require "module.Time"
local UserDefault = require "utils.UserDefault"
local heroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local Property = require "utils.Property"

local Sn2Data = {};
local Arena_data = {}
Arena_data.formation = {};
Arena_data.info = {};
Arena_data.log = {};
Arena_data.fight_data = nil;
Arena_data.fight_info = nil;
Arena_data.pvp_fight_info = nil;
Arena_data.pvp_fight_data = nil;
Arena_data.pvp_flag = nil;
Arena_data.fight_result = 0;
local found_opponent = false;
local found_pvp_opponent = false;
local wealth_change = false;
local matching_time = 0;
local show_battle_result = false;


local  C_PILLAGE_ARENA_FIGHT_PERPARE_REQUEST = 517	--战斗数据请求
local  C_PILLAGE_ARENA_FIGHT_PERPARE_RESPOND = 518	--战斗数据请求返回

local  C_PILLAGE_ARENA_FIGHT_CHECK_REQUEST = 519	--战斗结果验证
local  C_PILLAGE_ARENA_FIGHT_CHECK_RESPOND = 520	--战斗结果验证返回

local  C_PILLAGE_ARENA_QUERY_RANK_LIST_REQUEST = 521	--查询排行榜
local  C_PILLAGE_ARENA_QUERY_RANK_LIST_RESPOND = 522	--查询排行榜返回

local  C_PILLAGE_ARENA_QUERY_LAST_PERIOD_CHAMPION_REQUEST = 523		--查询上期排行榜前三
local  C_PILLAGE_ARENA_QUERY_LAST_PERIOD_CHAMPION_RESPOND = 524		--查询上期排行榜前三返回

local  C_PILLAGE_ARENA_QUERY_FORMATION_REQUEST = 525	--查询玩家阵容
local  C_PILLAGE_ARENA_QUERY_FORMATION_RESPOND = 526	--查询玩家阵容返回

local  C_PILLAGE_ARENA_CHANGE_FORMATION_REQUEST = 527	--改变玩家阵容
local  C_PILLAGE_ARENA_CHANGE_FORMATION_RESPOND = 528	--改变玩家阵容返回

local  C_PILLAGE_ARENA_QUERY_PLAYER_INFO_REQUEST = 529	--查询玩家信息
local  C_PILLAGE_ARENA_QUERY_PLAYER_INFO_RESPOND = 530	--查询玩家信息返回

local  C_PILLAGE_ARENA_QUERY_PLAYER_LOG_REQUEST = 531	--查询玩家战斗记录
local  C_PILLAGE_ARENA_QUERY_PLAYER_LOG_RESPOND = 532	--查询玩家战斗记录返回

local  NOTIFY_ARENA_LOG_CHANGE = 550  --玩家战斗记录变化通知

local  C_PILLAGE_ARENA_PVP_FIGHT_START_MATCHING_REQUEST = 553;	--PVP开始匹配
local  C_PILLAGE_ARENA_PVP_FIGHT_START_MATCHING_RESPOND = 554;	--PVP开始匹配返回

local  C_PILLAGE_ARENA_PVP_FIGHT_CANCEL_MATCHING_REQUEST = 555;		--取消PVP匹配
local  C_PILLAGE_ARENA_PVP_FIGHT_CANCEL_MATCHING_RESPOND = 556;		--取消PVP匹配返回

local  NOTIFY_ARENA_PVP_FIGHT_MATCHING_SUCCESS = 557;				--PVP匹配成功
local  NOTIFY_ARENA_PVP_FIGHT_RESULT = 583;							--战斗结果
 
local  C_PILLAGE_ARENA_PVP__START_FIGHT_REQUEST = 558;	--开始PVP战斗
local  C_PILLAGE_ARENA_PVP__START_FIGHT_RESPOND = 559;	--开始PVP战斗返回

local C_PILLAGE_ARENA_SERVER_CHECK_REQUEST = 593	--服务器检查战斗
local C_PILLAGE_ARENA_SERVER_CHECK_RESPOND = 594	

local npc_config = nil
local function GetNPCStatus(gid)
	if npc_config == nil then
		npc_config = {};
		DATABASE.ForEach("random_arena_ai", function(row)
			local data = {};
			data.cfg = row;
			data.heros = {};
			for j=1,5 do
				if row["level"..j] ~= 0 then
					local info = {};
					info.level = row["level"..j];
					info.evolution = row["evolution"..j];
					info.star = row["star"..j];
					data.heros[j] = info;
				end
			end
			npc_config[row.gid] = data;
		end)
	end
	return npc_config[gid];
end

local arena_property = nil
local function GetArenaProperty(id)
    if arena_property == nil then
        arena_property = LoadDatabaseWithKey("arena_property", "id");
    end
    if id == nil then
        return arena_property;
    end
   return arena_property[id]
end

local rank_config = nil
local rank_class = {};
local function GetRankReward(type, rank)
	if rank_config == nil then
		rank_config = {};
		DATABASE.ForEach("arena_rank", function(row)
			if rank_class[row.Order] == nil then
				rank_class[row.Order] = {};
			end
			table.insert(rank_class[row.Order], row.Rank2);
			if rank_config[row.Order] == nil then
				rank_config[row.Order] = {};
			end
			rank_config[row.Order][row.Rank2] = row;
		end)
	end
	if rank then
		return rank_config[type][rank];
	else
		return rank_config
	end
end

local function GetRankName(wealth)
	local stage,num,class = 0,0,0;
	local str = "";
	if wealth < 10000000 then
		num = math.max(math.floor(wealth/1000000),1);
		if num == 1 then
			stage = 1;
		else
			stage = math.ceil(num/2) + 1;
		end
		str = "百万";
		class = num;
	elseif wealth < 100000000 then
		num = math.floor(wealth/10000000);
		stage = math.ceil(num/2) + 6;
		str = "千万";
		class = num + 9;
	elseif wealth < 1000000000 then
		num = math.floor(wealth/100000000)
		stage = math.ceil(num/2) + 11;
		str = "破亿";
		class = num + 18;
	elseif wealth >= 1000000000 then
		stage = 15;
		num = 9;
		class = 27
		str = "破亿";
	end
	return str,stage,num,class
end

local function ON_SERVER_RESPOND(id, callback)
     EventManager.getInstance():addListener("server_respond_" .. id, callback);
end

local function ON_SERVER_NOTIFY(id, callback)
     EventManager.getInstance():addListener("server_notify_" .. id, callback);
end

local hero_change = true;

local function SetFormation(tab,type)
	local pid = playerModule.GetSelfID();
	type = type or 3
	local temp = {type, unpack(tab)}
	print("设置", sprinttb(temp));
	local sn = NetworkService.Send(C_PILLAGE_ARENA_CHANGE_FORMATION_REQUEST,{nil,type, unpack(tab)});
	Sn2Data[sn] = {pid = pid, type = type,tab = tab};
end

local function GetPlayerFormationFromServer(type,pid, func)
	type = type or 3;
	pid = pid or playerModule.GetSelfID();
	local sn = NetworkService.Send(C_PILLAGE_ARENA_QUERY_FORMATION_REQUEST,{nil, type});
	Sn2Data[sn] = {pid = pid, type = type, func = func};
end

ON_SERVER_RESPOND(C_PILLAGE_ARENA_CHANGE_FORMATION_RESPOND, function(event, cmd, data)
	local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("change player formation failed",result)
		DispatchEvent("ARENA_SET_FORMATION_FAILED");
        return; 
    end
    -- if Arena_data.formation[Sn2Data[sn].pid] == nil then
   	-- 	Arena_data.formation[Sn2Data[sn].pid] = {};
   	-- end
   	-- Arena_data.formation[Sn2Data[sn].pid][Sn2Data[sn].type] = Sn2Data[sn].tab;
	-- DispatchEvent("ARENA_FORMATION_CHANGE", {lineup = Sn2Data[sn].tab, type = Sn2Data[sn].type})
	if Sn2Data[sn].type == 2 or Sn2Data[sn].type == 3 then
		hero_change = true;
	end
	GetPlayerFormationFromServer(Sn2Data[sn].type);
end)

ON_SERVER_RESPOND(C_PILLAGE_ARENA_QUERY_FORMATION_RESPOND, function(event, cmd, data)
	local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("query player formation failed",result)
        return; 
    end

   	if Arena_data.formation[Sn2Data[sn].pid] == nil then
   		Arena_data.formation[Sn2Data[sn].pid] = {};
   	end
	-- print("获取阵容1", Sn2Data[sn].type, sprinttb(data[3]));
	local info = {};
	if Sn2Data[sn].type == 1 or Sn2Data[sn].type == 2 then
		info.formation = data[3][1];
		info.data = ProtobufDecode(data[3][2], "com.agame.protocol.FightPlayer")
	elseif Sn2Data[sn].type == 3 then
		info[1] = {};
		info[1].formation = data[3][1][1];
		info[1].data = ProtobufDecode(data[3][1][2], "com.agame.protocol.FightPlayer")
		info[2] = {};
		info[2].formation = data[3][2][1];
		info[2].data = ProtobufDecode(data[3][2][2], "com.agame.protocol.FightPlayer")
	end
	print("获取阵容2", Sn2Data[sn].type, sprinttb(info));
	Arena_data.formation[Sn2Data[sn].pid][Sn2Data[sn].type] = info;
	if Sn2Data[sn] then
		if Sn2Data[sn].type == 1 --[[ or Sn2Data[sn].type == 2  ]]then
			local empty = true;
			for i,v in ipairs(info.formation) do
				if v ~= 0 then
					empty = false;
					break;
				end
			end
			if empty then
				local formation = {}
				print("阵容为空,自动设置")
				local _formation = heroModule.GetManager():GetFormation();
				for i,v in ipairs(_formation) do
					if v ~= 0 then
						formation[i] = heroModule.GetManager():Get(v).uuid;
					else
						formation[i] = v;
					end
				end
				SetFormation(formation, Sn2Data[sn].type)
			end
		end
		if Sn2Data[sn].func then
			Sn2Data[sn].func(info);
		end
	end
    DispatchEvent("ARENA_FORMATION_CHANGE", {lineup = data[3], type = Sn2Data[sn].type})
end)

local function GetRankListFromServer()
	NetworkService.Send(C_PILLAGE_ARENA_QUERY_RANK_LIST_REQUEST);
end

ON_SERVER_RESPOND(C_PILLAGE_ARENA_QUERY_RANK_LIST_RESPOND, function(event, cmd, data)
	local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("query ranklist failed",result)
        return; 
    end
    local rankList = {};
    for i,v in ipairs(data[3]) do
    	local info = {};
    	info.pid = v[1];
    	info.score = v[2];
    	info.name = v[3];
    	table.insert(rankList, info);
    end
    print("排行榜", sprinttb(data[3]))
    Arena_data.ranklist = rankList;
    DispatchEvent("ARENA_GET_RANKLIST_SUCCESS");
end)

local showRankChange = 0;
local wealthChange = {};
local function ShowRankChange(old,new)
	if new - old ~= 0 then
		wealthChange = {old, new};
		DispatchEvent("ARENA_WEALTH_CHANGE",old, new);
	end
	if new - old > 0 then
		local _,stage1,num1,class1 = GetRankName(old);
		local _,stage2,num2,class2 = GetRankName(new);
		showRankChange = showRankChange + (class2 - class1);
	end
end

local function GetWealthChange()
	local change = {wealthChange[1] or 0, wealthChange[2] or 0, Arena_data.fight_result or 0}
	return change
end

local function CheckRankChange()
	--showRankChange = 1;
	if showRankChange > 0 then
		local rank_up = SGK.ResourcesManager.Load("prefabs/base/PVP_RankUp.prefab");
		GetUIParent(rank_up);
		--CS.UnityEngine.GameObject.Instantiate(rank_up,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
	end
	showRankChange = 0;
end 

local function GetPlayerInfoFromServer(pid)
	pid = pid or playerModule.GetSelfID();
	-- print("查询竞技场个人信息")
	local sn = NetworkService.Send(C_PILLAGE_ARENA_QUERY_PLAYER_INFO_REQUEST, {nil, pid});
	Sn2Data[sn] = {pid = pid};
end

ON_SERVER_RESPOND(C_PILLAGE_ARENA_QUERY_PLAYER_INFO_RESPOND, function(event, cmd, data)
	local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("get player info failed",result)
        return; 
    end
    local info = {};
    info.wealth = data[3][1];
    info.win_count = data[3][2];
    info.fight_count = data[3][3];
    info.today_win_streak_count = data[3][4];
    info.defend_win_count = data[3][5];
    info.defend_fight_count = data[3][6];
	info.rank = data[3][7];
	info.matching_count = data[3][8];
	info.pvp_matching_count = data[3][9];
	info.pvp_win_streak_count = data[3][10] or 0;

	if Sn2Data[sn] then
		if Sn2Data[sn].pid == playerModule.GetSelfID() and Arena_data.info[Sn2Data[sn].pid] then
			ShowRankChange(Arena_data.info[Sn2Data[sn].pid].wealth, info.wealth);
		end
	
		if Sn2Data[sn].pid == playerModule.GetSelfID() then
			wealth_change = false;
		end
		Arena_data.info[Sn2Data[sn].pid] = info;
	end

    print("玩家信息",sprinttb(info),sprinttb(data))
    DispatchEvent("ARENA_GET_PLAYER_INFO_SUCCESS");
end)

local function GetBattleLogFromServer()
	NetworkService.Send(C_PILLAGE_ARENA_QUERY_PLAYER_LOG_REQUEST);
end

local function SetBattleLog(index,info)
	if info.wealth_change > 0 then
		if info.attacker == playerModule.GetSelfID() then
			if info.defender > 110000 or info.defender < 100000 then
				playerModule.Get(info.defender,function ( ... )
					local player = playerModule.Get(info.defender);
					Arena_data.log[index] = "你成功抢夺了"..player.name.." "..info.wealth_change.."点财力"..(info.extra_wealth > 0 and (",连胜奖励 +"..info.extra_wealth.."点财力") or "");
				end)
			else
				local name = GetNPCStatus(info.defender).cfg.name;
				Arena_data.log[index] = "你成功抢夺了"..name.." "..info.wealth_change.."点财力"..(info.extra_wealth > 0 and (",连胜奖励 +"..info.extra_wealth.."点财力") or "");
			end
		else
			if info.attacker > 110000 or info.attacker < 100000 then
				playerModule.Get(info.attacker,function ( ... )
					local player = playerModule.Get(info.attacker);
					Arena_data.log[index] = player.name.."试图抢夺你的财力但失败了，被你抢夺了"..info.wealth_change.."点财力";
				end)
			else
				local name = GetNPCStatus(info.attacker).cfg.name;
				Arena_data.log[index] = name.."试图抢夺你的财力但失败了，被你抢夺了"..info.wealth_change.."点财力";
			end
		end
	else
		if info.attacker == playerModule.GetSelfID() then
			if info.defender > 110000 or info.defender < 100000 then
				playerModule.Get(info.defender,function ( ... )
					local player = playerModule.Get(info.defender);
					Arena_data.log[index] = "你试图抢夺"..player.name.."的财力但失败了，损失了"..math.floor(-info.wealth_change).."点财力";
				end)
			else
				local name = GetNPCStatus(info.defender).cfg.name;
				Arena_data.log[index] = "你试图抢夺"..name.."的财力但失败了，损失了"..math.floor(-info.wealth_change).."点财力";
			end
		else
			if info.attacker > 110000 or info.attacker < 100000 then
				playerModule.Get(info.attacker,function ( ... )
					local player = playerModule.Get(info.attacker);
					Arena_data.log[index] = player.name.."成功抢夺了你"..math.floor(-info.wealth_change).."点财力";
				end)
			else
				local name = GetNPCStatus(info.attacker).cfg.name;
				Arena_data.log[index] = name.."成功抢夺了你"..math.floor(-info.wealth_change).."点财力";
			end
		end
    end
end

ON_SERVER_RESPOND(C_PILLAGE_ARENA_QUERY_PLAYER_LOG_RESPOND, function(event, cmd, data)
	local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("get battle log failed",result)
        return; 
    end
    Arena_data.log = {};
    for i,v in ipairs(data[3]) do
    	local info = {};
    	info.attacker = v[1];
    	info.defender = v[2];
    	info.wealth_change = v[3];
    	info.extra_wealth = v[4];
    	--table.insert(log, info);
    	SetBattleLog(i,info);
    end
    DispatchEvent("ARENA_BATTLE_LOG_SUCCESS");
end)

ON_SERVER_NOTIFY(NOTIFY_ARENA_LOG_CHANGE, function(event, cmd, data)
	local log = {};
	log.attacker = data[1];
	log.defender = data[2];
	log.wealth_change = data[3];
	log.extra_wealth = data[4];
	--table.insert(Arena_data.log, log);
	wealth_change = true;
	SetBattleLog(#Arena_data.log + 1,log);
	GetPlayerInfoFromServer();
	-- print("战斗日志",sprinttb(log))
end)

local function SendFightRequest()
	NetworkService.Send(C_PILLAGE_ARENA_FIGHT_PERPARE_REQUEST);
end

local function CloseFight()
	NetworkService.Send(C_PILLAGE_ARENA_SERVER_CHECK_REQUEST)
end

local test_times = 3;
local start_test = false;

ON_SERVER_RESPOND(C_PILLAGE_ARENA_FIGHT_PERPARE_RESPOND, function(event, cmd, data)
	local sn = data[1];
    local result = data[2];
    if result ~= 0 then
    	if result == 823 then
    		print("未找到对手")
			DispatchEvent("ARENA_NOT_FOUND_OPPONENT")
    	else
    		print("found opponent failed",result)
			found_opponent = false;
			-- DispatchEvent("ARENA_NOT_FOUND_OPPONENT")
			DispatchEvent("ARENA_FOUND_OPPONENT_FAILED")
    	end
        return; 
    end
    local fight_data = data[3];
    found_opponent = false;
    matching_time = 0;
    local info = ProtobufDecode(fight_data, "com.agame.protocol.FightData")
    info.opponent_wealth = data[4];
    print("pve找到对手",sprinttb(info))
    Arena_data.fight_data = fight_data;
	Arena_data.fight_info = info;
	show_battle_result = true;
	if not start_test then
		DispatchEvent("ARENA_FOUND_OPPONENT",{fight_info = info, fight_data = fight_data});
	end
end)

local function CheckFight(result)
	NetworkService.Send(C_PILLAGE_ARENA_FIGHT_CHECK_REQUEST,{nil, result});
end

ON_SERVER_RESPOND(C_PILLAGE_ARENA_FIGHT_CHECK_RESPOND, function(event, cmd, data)
	local sn = data[1];
    local result = data[2];
    if result ~= 0 then
    	print("验证失败");
    end
end)

local function StartPVPMatching()
	NetworkService.Send(C_PILLAGE_ARENA_PVP_FIGHT_START_MATCHING_REQUEST)
end

local function RunPVPMatching()
	local count = 0;
	coroutine.resume(coroutine.create( function ()
		while found_pvp_opponent do
			count = count + 1;
			if count == 1 then
				Sleep(3)
			else
				Sleep(math.random(5,7))
			end
			if found_pvp_opponent then
				print("未到对手，播放动画")
				DispatchEvent("ARENA_NOT_FOUND_OPPONENT")
			end
		end
	end));
end

ON_SERVER_RESPOND(C_PILLAGE_ARENA_PVP_FIGHT_START_MATCHING_RESPOND, function(event, cmd, data)
	local sn = data[1];
    local result = data[2];
    if result ~= 0 then
    	print("found pvp opponent failed",result)
        return; 
    end
	found_pvp_opponent = true;
	RunPVPMatching();
    matching_time = Time.now();
	Arena_data.pvp_fight_info = nil;
	Arena_data.pvp_fight_data = nil;
	Arena_data.pvp_flag = nil;
	DispatchEvent("ARENA_START_FOUND_PVP_OPPONENT");
end)

local function CancelPVPMatching()
	NetworkService.Send(C_PILLAGE_ARENA_PVP_FIGHT_CANCEL_MATCHING_REQUEST)
end

ON_SERVER_RESPOND(C_PILLAGE_ARENA_PVP_FIGHT_CANCEL_MATCHING_RESPOND, function(event, cmd, data)
	local sn = data[1];
    local result = data[2];
    if result ~= 0 then
    	print("cancel pvp matching failed",result)
        return; 
    end
    found_pvp_opponent = false;
    matching_time = 0;
	Arena_data.pvp_fight_info = nil;
	Arena_data.pvp_fight_data = nil;
	Arena_data.pvp_flag = nil;
	DispatchEvent("ARENA_CANCEL_FOUND_PVP_OPPONENT");
end)

local function StartPVPFight()
	if Arena_data.pvp_flag and Arena_data.pvp_flag == 1 then
		-- ERROR_LOG("PVE匹配");
		SceneStack.Push('battle', 'view/battle.lua', { fight_id = nil, fight_data = Arena_data.pvp_fight_data, callback = function(win, heros)
			local result = 0
			if win then
				result = 1;
			end
			EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT", result);
			CheckFight(result);
			if win then
				return true;
			end
		end } );
	else
		-- ERROR_LOG("正常");
		NetworkService.Send(C_PILLAGE_ARENA_PVP__START_FIGHT_REQUEST)
	end
end

ON_SERVER_RESPOND(C_PILLAGE_ARENA_PVP__START_FIGHT_RESPOND, function(event, cmd, data)
	local sn = data[1];
	local result = data[2];
	if result ~= 0 then
    	print("start pvp fight failed",result)
        return; 
	end
end)

ON_SERVER_NOTIFY(NOTIFY_ARENA_PVP_FIGHT_MATCHING_SUCCESS, function(event, cmd, data)
	local info = ProtobufDecode(data[3], "com.agame.protocol.FightData")
    info.opponent_wealth = data[4];
	Arena_data.pvp_fight_data = data[3];
	Arena_data.pvp_fight_info = info;
	-- Arena_data.pvp_flag = data[5];
	found_pvp_opponent = false;
	show_battle_result = true;
	print("pvp匹配成功",sprinttb(Arena_data.pvp_fight_info))
	DispatchEvent("ARENA_FOUND_PVP_OPPONENT");
end)

ON_SERVER_NOTIFY(NOTIFY_ARENA_PVP_FIGHT_RESULT, function(event, cmd, data)
	ERROR_LOG("战斗结果", sprinttb(data));
	Arena_data.fight_result = data[2];
	DispatchEvent("ARENA_FIGHT_RESULT", Arena_data.fight_result);
end)

local function StartFight()
	SceneStack.Push('battle', 'view/battle.lua', { fight_id = nil, fight_data = Arena_data.fight_data, callback = function(win, heros)
        local result = 0
        if win then
            result = 1;
        end
        EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT", result);
        CheckFight(result);
        if win then
            return true;
        end
	end } );
	-- NetworkService.Send(C_PILLAGE_ARENA_PVP__START_FIGHT_REQUEST)
end

local function GetPlayerFormation(type,pid,func)
	type = type or 3;
	pid = pid or playerModule.GetSelfID();
	if Arena_data.formation[pid] and Arena_data.formation[pid][type] then
		local info = Arena_data.formation[pid][type];
		if #info.formation == 0 then
			local _formation = heroModule.GetManager():GetFormation();
			for i,v in ipairs(_formation) do
				if v ~= 0 then
					info.formation[i] = heroModule.GetManager():Get(v).uuid;
				else
					info.formation[i] = v;
				end
			end
		end	
		-- info.data = 0;
		if func then
			func(info);
		end
		
		return info;
	else
		GetPlayerFormationFromServer(type, pid, func);
		return nil;
	end
end

local function GetRankList(refresh)
	if refresh then
		GetRankListFromServer();
	end
	if Arena_data.ranklist ~= nil then
		local ranklist = Arena_data.ranklist;
		return ranklist;
	end
end

local function GetPlayerInfo(pid)
	pid = pid or playerModule.GetSelfID();
	if Arena_data.info[pid] == nil or wealth_change then		
		GetPlayerInfoFromServer(pid);
	end
	return Arena_data.info[pid];
end

local function GetBattleLog()
	if #Arena_data.log == 0 then
		GetBattleLogFromServer();
		return {};
	else
		return Arena_data.log;
	end
end

local function CleanData()
	print("清理数据")
	Arena_data.fight_data = nil;
	Arena_data.fight_info = nil;
	Arena_data.pvp_fight_info = nil;
	Arena_data.pvp_fight_data = nil;
	Arena_data.pvp_flag = nil;
	Arena_data.fight_result = 0;
	matching_time = 0;
	show_battle_result = false;
	wealthChange = {0,0};
end

local function GetFightInfo()
	return Arena_data.fight_info,Arena_data.fight_data
end

local function GetPVPFightInfo()
	return Arena_data.pvp_fight_info
end

local function GetMatchingState()
	return found_opponent,matching_time;
end

local function SetViewData(data)
	Arena_data.content = data;
	Arena_data.controller = data[SGK.DialogPlayerMoveController];
end

local function StartPVEMatching(sure)
	if sure then
		found_opponent = true;
		Arena_data.fight_data = nil;
		Arena_data.fight_info = nil;
		matching_time = Time.now();
		--start_test = true;
		if start_test then
			coroutine.resume(coroutine.create( function ()
				for i=1,test_times do
					if i ~= test_times then
						DispatchEvent("ARENA_NOT_FOUND_OPPONENT")
					else
						DispatchEvent("ARENA_FOUND_OPPONENT",{fight_info = Arena_data.fight_info, fight_data = Arena_data.fight_data});
					end
					Sleep(4)
				end
			end));
		else
			coroutine.resume(coroutine.create( function ()
				while found_opponent do
					if found_opponent then
						SendFightRequest();
					end
					Sleep(4)
				end
			end));
		end
	else
		found_opponent = false;		
		matching_time = 0;
		CloseFight();
	end
end

local capacity_change = false;
local change_value = 0;
local function CheckCapacity()
	if hero_change then
		capacity_change = false;
		local info = GetPlayerFormation(2);
		if info and info.formation and info.data then
			hero_change = false;
			local now_capacity = 0;
			for i,v in ipairs(info.formation) do
				if v ~= 0 then
					local hero = heroModule.GetManager():GetByUuid(v);
					now_capacity = hero.capacity + now_capacity;
				end
			end
			local sever_capacity = 0;
			for _,v in ipairs(info.data.roles) do
				local hero = heroModule.GetManager():Get(v.id);
				-- print("---------------对比", hero.name)
				local property_list = {};
				for _,k in ipairs(v.propertys) do
					property_list[k.type] = k.value;
					-- print("id "..k.type, k.value, hero.property_list[k.type])
				end
				sever_capacity = sever_capacity + Property(property_list).capacity;
			end
			print("检查", now_capacity, sever_capacity);
			change_value = now_capacity - sever_capacity;
			if now_capacity > sever_capacity  then
				capacity_change = true;
			end
		end
	end
	return capacity_change, change_value;
end

EventManager.getInstance():addListener("HERO_INFO_CHANGE", function ()
	hero_change = true;
end);
EventManager.getInstance():addListener("HERO_CAPACITY_CHANGE", function ()
	hero_change = true;
end);
EventManager.getInstance():addListener("LOGIN_SUCCESS", function ()
	NetworkService.Send(C_PILLAGE_ARENA_SERVER_CHECK_REQUEST)
end);
EventManager.getInstance():addListener("LOCAL_RECONNECTION", function ()
	NetworkService.Send(C_PILLAGE_ARENA_SERVER_CHECK_REQUEST)
end);
-- local last_sync_time = 0;
-- SGK.CoroutineService.Schedule(function()
-- 	if start_test and Time.now() - last_sync_time >= 3 then
-- 		if test_times == 0 then
-- 			start_test = false;
-- 			test_times = 3;
-- 			DispatchEvent("ARENA_FOUND_OPPONENT",{fight_info = Arena_data.fight_info, fight_data = Arena_data.fight_data});
-- 		else
-- 			last_sync_time = Time.now();
-- 			DispatchEvent("ARENA_NOT_FOUND_OPPONENT")
-- 			test_times = test_times - 1;
-- 		end		
-- 	end

-- 	if not start_test and not found_opponent and not found_pvp_opponent then
-- 		last_sync_time = Time.now() + 3;
-- 		return;
-- 	end

--     if found_opponent and Time.now() >= last_sync_time then
--         last_sync_time = Time.now() + 4;
--     	SendFightRequest();
-- 	end
-- 	if found_pvp_opponent and Time.now() >= last_sync_time then
-- 		last_sync_time = Time.now() + math.random(5,7);
-- 		print("未到对手，播放动画")
--     	DispatchEvent("ARENA_NOT_FOUND_OPPONENT")
-- 	end
	
-- end);

EventManager.getInstance():addListener("BATTLE_SCENE_READY", function ()
	if show_battle_result then
		-- ERROR_LOG("添加结果")
		CleanData();
		local prefab = SGK.ResourcesManager.Load("prefabs/base/Arena_Fight_Result.prefab");
		local obj = UnityEngine.Object.Instantiate(prefab);
		EventManager.getInstance():dispatch("ADD_OBJECT_TO_FIGHT_RESULT", obj);
	end
end);

--------------------策划用接口----------------------
local function GetPVPFormation()
	if Arena_data.pvp_fight_info then
		return Arena_data.pvp_fight_info.attacker.roles,Arena_data.pvp_fight_info.defender.roles;
	end
	return {};
end

local function GetPVEFormation()
	if Arena_data.fight_info then
		return Arena_data.fight_info.attacker.roles,Arena_data.fight_info.defender.roles;
	end
	return {};
end

local function AddCharacter(id , pos, type)
	DispatchEvent("ARENA_ADD_CHARACTER",id , pos, type);
end

local function AddCharacterByPosition(id , pos, type)
	DispatchEvent("ARENA_ADD_CHARACTER_BY_POS",id , pos, type);
end

local function RemoveCharacter(id,type)
	DispatchEvent("ARENA_REMOVE_CHARACTER",id , type);
end

local function MoveCharacter(id, pos, callback, type)
	DispatchEvent("ARENA_MOVE_CHARACTER",id, pos, callback, type);
end

local function MoveCharacterByPosition( id, pos, callback, type )
	-- print("测试",debug.traceback())
	DispatchEvent("ARENA_MOVE_CHARACTER_BY_POS",id, pos, callback, type);
end
local function CharacterTalk(id, str, talk_type, callback, type)
	DispatchEvent("ARENA_CHARACTER_TALK",id, str, talk_type, callback, type);
end

return {
	GetPlayerFormation = GetPlayerFormation,
	SetFormation = SetFormation,
	GetRankList = GetRankList,
	GetPlayerInfo = GetPlayerInfo,
	GetPlayerInfoFromServer = GetPlayerInfoFromServer,
	QueryLog = GetBattleLogFromServer,
	GetBattleLog = GetBattleLog,
	StartPVEMatching = StartPVEMatching,
	GetMatchingState = GetMatchingState,
	GetNPCStatus = GetNPCStatus,
	GetFightInfo = GetFightInfo,
	StartFight = StartFight,
	GetRankReward = GetRankReward,
	GetPVPFormation = GetPVPFormation,
	SetViewData = SetViewData,
	AddCharacter = AddCharacter,
	AddCharacterByPosition = AddCharacterByPosition,
	RemoveCharacter = RemoveCharacter,
	MoveCharacter = MoveCharacter,
	StartPVPMatching = StartPVPMatching,
	CancelPVPMatching = CancelPVPMatching,
	CharacterTalk = CharacterTalk,
	MoveCharacterByPosition = MoveCharacterByPosition,
	GetPVPFightInfo = GetPVPFightInfo,
	GetRankName = GetRankName,
	GetPVEFormation = GetPVEFormation,
	StartPVPFight = StartPVPFight,
	CheckRankChange = CheckRankChange,
	CleanData = CleanData,
	GetArenaProperty = GetArenaProperty,
	GetWealthChange = GetWealthChange,
	CheckCapacity = CheckCapacity,
}