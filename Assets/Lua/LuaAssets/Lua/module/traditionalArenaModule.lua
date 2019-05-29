
local NetworkService = require "utils.NetworkService";
local EventManager = require 'utils.EventManager';
local Property = require "utils.Property"
local QuestModule = require "module.QuestModule"
local ShopModule = require "module.ShopModule"

local npc_config = nil
local function getNpcConfig(gid)
	if npc_config == nil then
		npc_config = {};	
		DATABASE.ForEach("random_arena_ai", function(row)
			local _heros = {};
			for j=1,5 do
				if row["level"..j] ~= 0 then
					local info = {};
					local level = row["level"..j];
					local quality = row["evolution"..j];
					local star = row["star"..j];
					_heros[j] = {level=level,quality=quality,star=star}
				end
			end
			npc_config[row.gid] = setmetatable({heros=_heros},{__index=row});
		end)
	end
	if gid then
		return npc_config[gid];
	end
end

local rewardConfig = nil
local function getArenaReward(pos)
	if rewardConfig == nil then
		rewardConfig = {}
		DATABASE.ForEach("rank_jjc", function(data)
			local _rewards= {}
			for i=1,3 do
				if data["reward_type"..i]~=0 and data["reward_id"..i]~=0 and data["reward_value"..i]~=0 then
					local _type = data["reward_type"..i]
					local _id   = data["reward_id"..i]
					local _count = data["reward_value"..i]

					table.insert(_rewards,{type = _type, id = _id, count = _count})
				end
			end

			local _lowPos = data.Rank2
			local _topPos =data.Rank1 
			rewardConfig[data.id] = setmetatable({topPos = _topPos,lowPos = _lowPos, rewards =_rewards},{__index = data})
		end)
	end
	if pos then
		local _rewardCfg = nil 
		for k,v in pairs(rewardConfig) do
			if v.topPos <= pos  and v.lowPos >= pos then
				_rewardCfg = v 
				break
			end
		end
		return _rewardCfg
	else
		return rewardConfig
	end
end

local scoreRewards = nil
local function LoadScoreRewards(type)
	if scoreRewards == nil then
		scoreRewards = {}
		DATABASE.ForEach("jjc_score", function(data)
			local _cfg = {}
			local _product_gids = {}
			if data.type == 1 then
				for i=1,4 do
					if data["reward"..i] and data["reward"..i]~=0 then
						table.insert(_product_gids,data["reward"..i])
					end
				end
				_cfg = {product_gids = _product_gids,shop_id = data.type_id,rankPos = data.rank}
			else
				local quest_id = data.type_id
				local questCfg = QuestModule.GetCfg(quest_id)
				if questCfg then
					_cfg = {quest_id = data.type_id,rewards = questCfg.reward,questLimit = questCfg.consume_value1}
				else
					ERROR_LOG("questCfg is nil,id",quest_id)
				end
				
			end
			scoreRewards[data.type] = scoreRewards[data.type] or {}
			table.insert(scoreRewards[data.type],_cfg)
		end)
	end
	if type then
		return scoreRewards[type]
	else
		return scoreRewards
	end
end

local function GetScoreRewards(type)
	if type ==1 then
		local score_cfgs = LoadScoreRewards(type)
		local list = {}
		for i=1,#score_cfgs do
			local shop_id = score_cfgs[i].shop_id
			local _rankPos = score_cfgs[i].rankPos
			local _product_gids = score_cfgs[i].product_gids
			local _rewards = {}
			local _status = false
			local consumeValue,consumeType,consumeId = 0,0,0
			for j=1,#_product_gids do
				local product_gid = _product_gids[j]
				local product = ShopModule.GetProductCfg(shop_id,product_gid)
				if product then
					local _type = product.product_item_type
					local _id = product.product_item_id
					local _count = product.product_item_value
					table.insert(_rewards,{type = _type,id = _id,value = _count})

					consumeType = consumeType~=0 and consumeType or product.consume_item_type1
					consumeId = consumeId~= 0 and consumeId or product.consume_item_id1
					consumeValue = consumeValue + product.consume_item_value1
					_status = product.product_count >0
				else
					ERROR_LOG("product is nil,gid",product_gid,shop_id)
				end
			end
			table.insert(list,{rewards= _rewards,shop_id = shop_id,product_gids = _product_gids,status = _status,rankPos= _rankPos,consume={type = consumeType,id =consumeId ,value =consumeValue}})
		end
		table.sort(list,function(a,b)
			if a.status ~= b.status then
				return a.status
			end
			return a.rankPos > b.rankPos
		end)
		return list
	else
		return LoadScoreRewards(type)
	end
end

local function  GetCapacityByFormation(data)
	local _info = ProtobufDecode(data,"com.agame.protocol.FightPlayer")
	
	local heros = {}
	local capacity = 0
	for k, v in ipairs(_info.roles) do
		heros[k] = {
			id = v.id,
			level = v.level,
			mode = v.mode,
			skills = v.skills,
			equips = v.equips,
			uuid = v.uuid,
			star = v.grow_star,
			stage = v.grow_stage,
			pos = v.pos,
		}

		local t = {}
		for _, vv in ipairs(v.propertys) do
			t[vv.type] = vv.value
		end

		heros[k].property = Property(t);
		capacity = capacity + heros[k].property.capacity;
	end
	return capacity,heros
end

local lastQueryTime = nil
--每次名次发生变化 再次进入界面从新获取 （完整）列表
--否则读取本地

local selfPid = nil
local function QueryJoinArena()
	if not lastQueryTime then
		selfPid = module.playerModule.GetSelfID()
		NetworkService.Send(567)--加入JJC
	end
	--查询自身排行信息
	NetworkService.Send(561)
end
local rankList={}

-- C_ARENA_QUERY_REQUEST = 561 -- 竞技场查询请求
-- req[1] = sn
-- C_ARENA_QUERY_RESPOND = 562 -- 竞技场查询返回
-- ret[1] = sn
-- ret[2] = result
-- ret[3] = pos   --排行
-- ret[4] = pid
-- ret[8] = formation:[uuid]     --阵容 如果表为空或者uuid全为0， 则阵容为默认阵容
-- ret[9] = today_win_count
-- ret[10] = fight_data and encode('FightPlayer', fight_data) or ""

local playerInfo={}
EventManager.getInstance():addListener("server_respond_562", function(event, cmd, data)
	--ERROR_LOG("server_respond_562",sprinttb(data))
	local sn = data[1];
	local err = data[2];

	if data[2]==0 then
		local pos               = data[3]
		local pid               = data[4]
		local fight_Formation   = data[10]

		playerInfo.pos = pos
		playerInfo.pid = pid
		playerInfo.fight_Formation = fight_Formation

		--将玩家自己插入ranklist
		local _capacity,_heros = GetCapacityByFormation(fight_Formation) 

		rankList.selfInfo = {pos = pos,pid = pid, capacity = _capacity,heros = _heros,lastGetTime = module.Time.now()}
		DispatchEvent("TRADITIONAL_ARENA_PLAYERINFO_CHANGE",playerInfo)
		if not lastQueryTime or module.Time.now()-lastQueryTime>=60 then
	    	NetworkService.Send(575)--查询排行榜
	    else
	    	DispatchEvent("TRADITIONAL_ARENA_RANKLIST_CHANGE",rankList)
		end
	else
		ERROR_LOG("query ArenaInfo failed",err)
	end   
end)

local function GetSelfRankPos()
	if playerInfo and next(playerInfo) then
		return playerInfo.pos
	else
		local acceptSideQuestCo = coroutine.create(function()
			local data = NetworkService.SyncRequest(561)
			if data[2]==0 then
				local pos               = data[3]
				local pid               = data[4]
				local fight_Formation   = data[10]

				playerInfo.pos = pos
				playerInfo.pid = pid
				playerInfo.fight_Formation = fight_Formation
			end
		end)

		assert(coroutine.resume(acceptSideQuestCo)); 
		return playerInfo.pos
	end
end

--对手列表
EventManager.getInstance():addListener("server_respond_568", function(event, cmd, data)
	--ERROR_LOG("server_respond_568",sprinttb(data))
	local sn = data[1];
	local err = data[2];

	if data[2]==0 then
		if data[4] and next(data[4]) ~= nil then
			rankList.CanAttackList = {}
			for i=1,#data[4] do
				local pos = data[4][i][1]
				local pid = data[4][i][2]
			 	local fight_Formation = data[4][i][3]
				
				local _capacity,_heros = GetCapacityByFormation(fight_Formation)
				rankList.CanAttackList[pid] = {pos = pos,pid = pid,capacity = _capacity,heros = _heros,lastGetTime = module.Time.now()}
			end
			if lastQueryTime then
				DispatchEvent("TRADITIONAL_ARENA_RANKLIST_CHANGE",rankList)	
			end
		else
			ERROR_LOG("can challenge list err",data[4],sprinttb(data[4] and data[4] or {}))
		end
	else
		ERROR_LOG("query JoinArena failed",err)
	end   
end)

-- C_ARENA_QUERY_TOP_REQUEST = 575   --查询排行榜
EventManager.getInstance():addListener("server_respond_576", function(event, cmd, data)
	--ERROR_LOG("server_respond_576",sprinttb(data))
	local sn = data[1];
	local err = data[2];

	if data[2]==0 then
		if data[3] and next(data[3])~=nil then
			rankList.list = {}
			for i=1,10 do
				local pos = i
				local pid = data[3][i][1]
				local fight_Formation = data[3][i][2]
				local _capacity,_heros = GetCapacityByFormation(fight_Formation)
				rankList.list[pid] = {pos = pos,pid = pid,capacity = _capacity,heros = _heros,lastGetTime = module.Time.now()}
			end

		else
			ERROR_LOG("RankList err",data[3],sprinttb(data[3] and data[3] or {}))
		end
		lastQueryTime = module.Time.now()
		NetworkService.Send(567)--对手列表
    else
        ERROR_LOG("query QueryRankList failed",err)
    end   
end)  

-- C_ARENA_QUERY_LOG_REQUEST = 597
-- req[1] = sn
local fightLog = nil
local tempLogTab = {}
local function getFightlog()
	if not fightLog then
		NetworkService.Send(597)
	else
		if #tempLogTab~=0 then
			for i=1,#tempLogTab do
				table.insert(fightLog,tempLogTab[i])
			end
			tempLogTab = {}
		end
		return fightLog
	end
end

local function updateFightLog(data)
	local log={}
	local attacker_id = data[1]
	local defender_id = data[2]
	local fight_id = data[3]
	local attacker_pos = data[4]
	local defender_pos = data[5]
	local winner = data[6]
	local fight_time = data[7]
	local fight_data = data[8]

	log.attacker_id = attacker_id
	log.defender_id = defender_id
	log.fight_id = fight_id
	log.attacker_pos = attacker_pos
	log.defender_pos = defender_pos
	
	log.fight_time = fight_time
	log.fight_data = fight_data
	if winner == 1  then--进攻方获胜
		--1是胜利
		log.winner = selfPid == attacker_id and 1 or 0
	else
		log.winner = selfPid == defender_id and 1 or 0
	end
	--高的打低的排名不变
	if attacker_pos < defender_pos then
		--对手win
		log.change_pos = 0
	else
		--低的打高的进攻方获胜
		log.change_pos = winner==1 and attacker_pos-defender_pos or 0
	end
	return log
end

EventManager.getInstance():addListener("server_respond_598", function(event, cmd, data)
	--ERROR_LOG("查询排行榜返回server_respond_598",#data[3],sprinttb(data))
	local sn = data[1];
	local err = data[2];
	if data[2]==0 then
		fightLog = {}
		tempLogTab = {}
		for i=1,#data[3] do
			local _log = updateFightLog(data[3][i])
			table.insert(fightLog,_log)	
		end
		DispatchEvent("TRADITIONAL_ARENA_LOG_CHANGE")
	else
		ERROR_LOG("query FightLog failed",err)
	end   
end)

EventManager.getInstance():addListener("server_notify_599", function(event, cmd, data)
	--ERROR_LOG("排行榜变化server_respond_599",sprinttb(data))
   	local _log = updateFightLog(data)
	table.insert(tempLogTab,_log)
end)

-- C_ARENA_QUERY_FORMATION_REQUEST = 533
--rankInfo
local SnArr = {}
local function GetRankInfo(pid)
	local _rankInfo = nil
	if rankList.list and rankList.list[pid] then
		_rankInfo = rankList.list[pid]
	elseif rankList.CanAttackList and rankList.CanAttackList[pid] then
		_rankInfo = rankList.CanAttackList[pid]
	elseif rankList.selfInfo then
		_rankInfo = rankList.selfInfo
	end
	if _rankInfo then
		if module.Time.now()-_rankInfo.lastGetTime >=300 then
			local sn = NetworkService.Send(533,{nil,pid})
			SnArr[sn] = pid
		else
			return _rankInfo
		end
	else
		ERROR_LOG("rankInfo is nil,pid",pid)
	end
end

EventManager.getInstance():addListener("server_respond_534", function(event, cmd, data)
	--ERROR_LOG("server_respond_534",sprinttb(data))
	local sn = data[1];
	local err = data[2];
	if data[2]==0 then
		if SnArr[sn] then
			local pid = SnArr[sn]
			SnArr[sn] = nil

			local fight_Formation = data[3]
			local _capacity,_heros = GetCapacityByFormation(fight_Formation)

			local _rankInfo = nil
			if rankList.list and rankList.list[pid] then
				rankList.list[pid].capacity = _capacity
				rankList.list[pid].heros = _heros
				rankList.list[pid].lastGetTime = module.Time.now()
				_rankInfo = rankList.list[pid]
			elseif rankList.CanAttackList and rankList.CanAttackList[pid] then
				rankList.CanAttackList[pid].capacity = _capacity
				rankList.CanAttackList[pid].heros = _heros
				rankList.CanAttackList[pid].lastGetTime = module.Time.now()
				_rankInfo = rankList.CanAttackList[pid]
			elseif rankList.selfInfo then
				rankList.selfInfo.capacity = _capacity
				rankList.selfInfo.heros = _heros
				rankList.selfInfo.lastGetTime = module.Time.now()
				_rankInfo = rankList.selfInfo
			end

			if _rankInfo then
				DispatchEvent("TRADITIONAL_RANKINFO_CHANGE",_rankInfo)
			else
				ERROR_LOG("rankInfo is nil,pid",pid)
			end
		end
	else
		ERROR_LOG("query Formation failed",err)
	end   
end)

local winner 
local rewards
local function GetArenaResult()
	return winner,rewards
end

local function startFight(fight_data,_reward,_winner)
	winner,rewards = _winner,_reward

	if utils.SGKTools.GetTeamState() then
		if utils.SGKTools.isTeamLeader() or module.TeamModule.GetAfkStatus() then
			SceneStack.Push('battle', 'view/battle.lua', {fight_id = nil, fight_data = fight_data, rankJJC=true,callback = function(win, heros, fightid, starInfo, input_record)
				EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT",win and 1 or 2,rewards)
			end});
		else
			showDlgError(nil, "队伍内无法进行该操作")
		end
	else
		SceneStack.Push('battle', 'view/battle.lua', {fight_id = nil, fight_data = fight_data, rankJJC=true,callback = function(win, heros, fightid, starInfo, input_record)
			EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT",win and 1 or 2,rewards)
		end});
	end
end

local not_pos_change_tip_flag = false
-- C_ARENA_ATTACK_REQUEST = 595 -- 竞技场攻击请求
local function QueryChallengeData(pos,pid)
	NetworkService.Send(595,{nil,pos,pid})
	not_pos_change_tip_flag = true
end

-- ret[2] = result       错误号为4表示排名和pid不匹配，要重新查一下数据
EventManager.getInstance():addListener("server_respond_596", function(event, cmd, data)
	ERROR_LOG("server_respond_596","奖励",sprinttb(data[4]),data[5],sprinttb(data))  --data[4]--奖励
	local sn = data[1];
	local err = data[2];
	if data[2]==0 then--攻击请求返回  进入战斗
		startFight(data[3],data[4],data[5])
		DispatchEvent("TRADITIONAL_ARENA_FINISHED_CHALLENGE")
	elseif data[2]==4 then
		showDlgError(nil, "挑战的玩家排名变动请选择其他玩家")
		if rankList.selfInfo.pos-3 <=10 then
			NetworkService.Send(575)
		else
			NetworkService.Send(567)--对手列表
		end
	else
		ERROR_LOG("query StartChallenge failed",err)
	end
end)

-- C_ARENA_CHANGE_FORMATION_REQUEST = 579
-- req[1] = sn
-- req[2] = roles:[uuid]     PS：table中必须有五个元素，空位uuid填0  
-- C_ARENA_CHANGE_FORMATION_RESPOND = 580
-- ret[1] = sn
-- ret[2] = result

local function QueryChangeFormation(uuids)
	--ERROR_LOG("579",sprinttb(uuids))
	local sn = NetworkService.Send(579,{nil,uuids})
	SnArr[sn] = uuids
end

EventManager.getInstance():addListener("server_respond_580", function(event, cmd, data)
	--ERROR_LOG("server_respond_580",sprinttb(data))
	local sn = data[1];
	local err = data[2];
	if data[2]==0 then
		if SnArr[sn] then
			local _formation = SnArr[sn]
			if playerInfo and playerInfo.formation then
				for k,v in pairs(_formation) do
					playerInfo.formation[k] = v
				end
			end
			--阵容发生变化,刷新玩家数据
			NetworkService.Send(561)
			DispatchEvent("TRADITIONAL_ARENA_FORMATION_CHANGE")
			SnArr[sn] = nil
		end
	else
		DispatchEvent("TRADITIONAL_ARENA_FORMATION_CHANGE_FAILD")
		ERROR_LOG("query ChangeFormation failed",err)
	end
end)

-- NOTIFY_ARENA_ATTACK = 581   排名发生变化
EventManager.getInstance():addListener("server_notify_581", function(event, cmd, data)
	if data[2] ~= data[3] and data[5]~= data[6] then
		--能挑战到 第10名可能产生影响前10名，名次变化的
		if rankList.selfInfo.pos-10 <=10 then
			NetworkService.Send(575)
		else
			NetworkService.Send(567)--对手列表
		end
	end
end)

local function GetDefenceFormation()
	if playerInfo and playerInfo.fight_Formation then
		local _capacity,_heros = GetCapacityByFormation(playerInfo.fight_Formation)

		local defenedFormation = {}
		for i=1,5 do
			defenedFormation[i] = _heros[i] and _heros[i].uuid or 0
		end
		playerInfo.formation = defenedFormation
		return playerInfo.formation
	end
end

--90169
-- C_ARENA_ADD_FIGHTCOUNT_REQUEST = 573 -- 加体力
-- C_ARENA_ADD_FIGHTCOUNT_RESPOND = 574 
local function QueryAddFightCount(num)
	--NetworkService.Send(573,{nil,num})
end

EventManager.getInstance():addListener("server_respond_574", function(event, cmd, data)
    --ERROR_LOG("server_respond_574",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if data[2]==0 then
    	showDlgError(nil,"购买成功")
    	DispatchEvent("TRADITIONAL_ARENA_FIGHTCOUNT_CHANGE")
    else
        ERROR_LOG("query AddFightCount failed",err)
    end   
end)

-- C_ARENA_REFRESH_ENEMY_LIST_REQUEST = 577    --刷新对手
-- req[1] = sn
-- C_ARENA_REFRESH_ENEMY_LIST_RESPOND = 578
-- ret[1] = sn
-- ret[2] = result
-- ret[3] = enemy_list:[pos, pid, player_data]  对手列表
local lastChangeDefenceTime = 0
local function QueryRefreshEnemyList()
	if module.Time.now()-lastChangeDefenceTime >= 5 then
		lastChangeDefenceTime = module.Time.now()
		NetworkService.Send(577)
	else
		showDlgError(nil,"刷新频率过快")
	end
end

EventManager.getInstance():addListener("server_respond_578", function(event, cmd, data)
    --ERROR_LOG("server_respond_578",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if data[2]==0 then
    	if data[3] and next(data[3])~=nil then
			rankList.CanAttackList = {}
			for i=1,#data[3] do
				local pos = data[3][i][1]
				local pid = data[3][i][2]
				local fight_Formation = data[3][i][3]		
				local _capacity,_heros = GetCapacityByFormation(fight_Formation)
				rankList.CanAttackList[pid] = {pos = pos,pid = pid,capacity = _capacity,heros = _heros,lastGetTime = module.Time.now()}
			end
		end
		showDlgError(nil,"更换成功")
		DispatchEvent("TRADITIONAL_ARENA_RANKLIST_CHANGE",rankList)
    else
        ERROR_LOG("query RefreshEnemyList failed",err)
    end   
end)

local capacity_change = false;
local change_value = 0;
local function CheckCapacity()
	if playerInfo and playerInfo.fight_Formation then
		local sever_capacity = GetCapacityByFormation(playerInfo.fight_Formation)
		local now_capacity = 0
		local nowFormation = GetDefenceFormation()
		if next(nowFormation)~= nil then
			for k,v in pairs(nowFormation) do
				if v~= 0 then
					local hero = module.HeroModule.GetManager():GetByUuid(v);
					if hero then
						now_capacity = hero.capacity + now_capacity;
					end
				end
			end
		end
		if now_capacity~=sever_capacity then
			capacity_change = true
			change_value = now_capacity - sever_capacity;
		end
	end
	return capacity_change, change_value;
end

local function GetCopyUIItem(parent,prefab,i)
    local obj = nil
    if i <= parent.transform.childCount then
        obj = parent.transform:GetChild(i-1).gameObject
    else
        obj = CS.UnityEngine.GameObject.Instantiate(prefab.gameObject,parent.transform)
        obj.transform.localPosition = Vector3.zero
        obj.name = "rankItem_"..i
    end
    obj:SetActive(true)
    local item = CS.SGK.UIReference.Setup(obj)
    return item
end

local function ShowTip(name1,name2,pos)
	local desc = SGK.Localize:getInstance():getValue("jingjichang_paomadeng_01",name1,name2,pos)
	if pos<= 3 then
		utils.SGKTools.showScrollingMarquee(desc)
	end
	module.ChatModule.SystemChatMessage(desc)
end

local save_pos_change_tips = {}
local function showPosChangeTip(data)
	if module.playerModule.IsDataExist(data[1]) then
		local name1,name2 = module.playerModule.IsDataExist(data[1]).name
		if data[2]<= 500000 then --AI
			name2 = getNpcConfig(data[2]) and getNpcConfig(data[2]).name or "神秘玩家"
			ShowTip(name1,name2,data[3])
		else
			if module.playerModule.IsDataExist(data[2]) then
				name2 = module.playerModule.IsDataExist(data[2]).name
				ShowTip(name1,name2,data[3])
			else
				module.playerModule.Get(data[2],(function( ... )
					name2 =  module.playerModule.IsDataExist(data[2]).name
					ShowTip(name1,name2,data[3])
				end))
			end
		end
	else
		module.playerModule.Get(data[1],(function( ... )
			local name1,name2 = module.playerModule.IsDataExist(data[1]).name
			if data[2]<= 500000 then --AI
				name2 = getNpcConfig(data[2]) and getNpcConfig(data[2]).name or "神秘玩家"
				ShowTip(name1,name2,data[3])
			else
				if module.playerModule.IsDataExist(data[2]) then
					name2 = module.playerModule.IsDataExist(data[2]).name
					ShowTip(name1,name2,data[3])
				else
					module.playerModule.Get(data[2],(function( ... )
						name2 =  module.playerModule.IsDataExist(data[2]).name
						ShowTip(name1,name2,data[3])
					end))
				end
			end
		end))
	end
end

EventManager.getInstance():addListener("server_notify_584", function(event, cmd, data)
	-- ERROR_LOG("server_notify_584==============",sprinttb(data))
	if not_pos_change_tip_flag then--自己挑战，引起的排位变化 等战斗结束后在播提示
		table.insert(save_pos_change_tips,data)
	else
		if data[3]<= 3 and utils.SceneStack.CurrentSceneName() == 'battle' then--战斗中前3名跑马灯
			table.insert(save_pos_change_tips,data)
		else
			showPosChangeTip(data)
		end
	end
end)

utils.EventManager.getInstance():addListener("SCENE_LOADED", function(event, name)
    if 'battle' == name then
    	not_pos_change_tip_flag = true
        return;
    end
    if next(save_pos_change_tips)~=nil then
    	for i=#save_pos_change_tips,1,-1 do
    		showPosChangeTip(save_pos_change_tips[i])
    		table.remove(save_pos_change_tips,i)
    	end
    end
end)

return {
    QueryJoinArena = QueryJoinArena,
    GetNpcCfg      = getNpcConfig,

    GetChallengeData      = QueryChallengeData,
    ChangeFormation = QueryChangeFormation,

    GetFightLog = getFightlog,
    startFight = startFight,

    GetDefenderFightInfo = GetRankInfo,

    AddFightCount = QueryAddFightCount,
    Refresh = QueryRefreshEnemyList,

    GetRewardsCfg = getArenaReward,
    GetDefenceFormation = GetDefenceFormation,--获取玩家防守阵容

    GetScoreRewards = GetScoreRewards,

    CheckCapacity = CheckCapacity,

    GetSelfRankPos = GetSelfRankPos,

    GetCopyUIItem =GetCopyUIItem,

    GetRankArenaFightResult = GetArenaResult,
}
