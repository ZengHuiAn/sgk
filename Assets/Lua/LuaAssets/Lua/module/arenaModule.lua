local EventManager=require 'utils.EventManager';
local NetworkService=require'utils.NetworkService';
local PlayerModule = require "module.playerModule";
local battleConfig = require "config.battle"
local ItemModule=require"module.ItemModule"
local HeroModule = require "module.HeroModule"

local npc_config = nil
local function getGuardConfigByID(gid)
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
					info.quality = row["evolution"..j];
					info.star = row["star"..j];
					data.heros[j] = info;
				end
			end
			npc_config[row.gid] = data;
		end)
	end
	return npc_config[gid];
end

local function getNpcHerosConfigByID(pid)
	local TempGuardCfg=battleConfig.load(pid)
	local herosCfg={}
	for k,v in pairs(TempGuardCfg.rounds) do
		for m,n in pairs(v.enemys) do
			table.insert(herosCfg,n)		
		end
	end
	return herosCfg;
end

local rewardConfig=nil
local function getArenaReward(id)
	if rewardConfig==nil then
		rewardConfig= LoadDatabaseWithKey("Arena_reward", "id");
	end
	return rewardConfig[id] or {}
end

--字符串分割的方法
local function Split(szFullString, szSeparator)
	local nFindStartIndex = 1  
	local nSplitIndex = 1  
	local nSplitArray = {}  
	while true do  
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)  
		if not nFindLastIndex then  
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))  
			break  
		end  
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)  
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)  
		nSplitIndex = nSplitIndex + 1  
	end  
	return nSplitArray  
end  

local buffConfigByGroup = nil
local buffConfigByBuff=nil
local function loadBuffConfig()
	local data_list = {};
	buffConfigByGroup={}
	buffConfigByBuff={}

	DATABASE.ForEach("arena_buff_type", function(data)
		table.insert(data_list, data);

		buffConfigByBuff[data.buff_type1]=data
		if data.buff_type2~=0 then
			buffConfigByBuff[data.buff_type2]=data
		end
		buffConfigByGroup[data.condition]=buffConfigByGroup[data.condition] or {}
		table.insert(buffConfigByGroup[data.condition], data);
	end)
	return data_list;
end

local function getBuffConfigByCondition(Condition)
	if buffConfigByGroup==nil then
		loadBuffConfig()
	end
	return buffConfigByGroup[Condition] or buffConfigByGroup
end
local function getBuffConfigByBuffType(buff)
	if buffConfigByBuff==nil then
		loadBuffConfig()
	end
	return buffConfigByBuff[buff] or {}
end

local arenaData=nil;
local function getPlayerArenaData()
	if not arenaData then return nil end
	if arenaData.ArenaData==nil then
		print("arenaData[ArenaData] is nil")
	end
	return arenaData.ArenaData;
end

local function  getGuardsData()	
	if arenaData.GuardsData==nil then		
		print("arenaData[GuardsData] is nil")
	end
	return arenaData.GuardsData;
end

local BoxReward=nil
local function  upDatePlayerInfo(data)
	arenaData=arenaData or {}
	arenaData.ArenaData=arenaData.ArenaData or {}
	
	if data then
		arenaData.ArenaData.lastResetTime=tonumber(data[1])
		arenaData.ArenaData.GetBuffTime=data[4]
		arenaData.ArenaData.WinRate=tonumber(data[5] or 0)
		arenaData.ArenaData.MatchCapacity=tonumber(data[6])

		--self.ArenaData.buffs
		local buff=data[3]
		local tempBuffs={}
		if buff~="" then
			local bufflist =Split(buff, "|")
			for _,v in pairs(bufflist) do
				local tempBuff={}
				tempBuff=Split(v, ":")
				local k, v = tonumber(tempBuff[1]), tonumber(tempBuff[2])
				tempBuffs[k]=(tempBuffs[k] or 0) + v;
			end
		end	
		arenaData.ArenaData.buffs=tempBuffs;

		--self.ArenaData.winNum		
		local winNum=0;
		if arenaData.GuardsData then
			for _,v in pairs(arenaData.GuardsData) do
				if v.status==1 then
					winNum=winNum+1;
				end
			end
		end
		arenaData.ArenaData.winNum=winNum or 0;

		--宝箱领取状态
		local GetNum=data[2]
		if 	arenaData.ArenaData.GetRewardStatus==nil then
			arenaData.ArenaData.GetRewardStatus={}
		end
	
		for i=1,3 do
			if 	arenaData.ArenaData.GetRewardStatus[i]==nil then
				arenaData.ArenaData.GetRewardStatus[i]={}
			end
			arenaData.ArenaData.GetRewardStatus[i].IsGet=(1<<i-1&GetNum~=0) and 1 or 0;
		end

		local Capacity=HeroModule.GetManager():GetCapacity();
		arenaData.ArenaData.startbattlepoint=Capacity;
		local formation={}
		local _formation =HeroModule.GetManager():GetFormation()
		for i,v in ipairs(_formation) do
			if v ~= 0 then
				formation[v] = HeroModule.GetManager():Get(v);
			end
		end
		arenaData.ArenaData.selfFormation=formation

		DispatchEvent("SELF_INFO_CHANGE");
	end
end

local function updateTotalRewards(data)
	if arenaData==nil then
		arenaData={}
	end
	if arenaData.ArenaData==nil then
		arenaData.ArenaData={}
	end
	if data then
		if arenaData.ArenaData.BoxRewards==nil then
			arenaData.ArenaData.BoxRewards={}
		end
		for i=1,#data do
			if arenaData.ArenaData.BoxRewards[i]==nil then
				arenaData.ArenaData.BoxRewards[i]={}
			end
			for j=1,#data[i] do
				arenaData.ArenaData.BoxRewards[i][j]={data[i][j][1],data[i][j][2],data[i][j][3]}
			end
		end
	end
end

local SnArr={}
local function UpdatePersonReward(rewardCfg,idx)
	if arenaData and arenaData.GuardsData[idx] then
		SnArr[idx]={}
		SnArr[idx].SnArr1={}
		SnArr[idx].SnArr2={}
		arenaData.GuardsData[idx].Rewards={}
		for i=1,3 do		
			if rewardCfg["reward_id"..i]~=0 then
				local _tab={rewardCfg["reward_type"..i],rewardCfg["reward_id"..i],rewardCfg["reward_num"..i]}
				table.insert(arenaData.GuardsData[idx].Rewards,_tab)
				table.insert(SnArr[idx].SnArr1,_tab)
				table.insert(SnArr[idx].SnArr2,_tab)
			end
		end
		-- arenaData.GuardsData[idx].exRewards={}
		-- if rewardCfg.extra_reward_id~=0 then
		-- 	local _tab={rewardCfg.extra_reward_type,rewardCfg.extra_reward_id,rewardCfg.extra_reward_num}
		-- 	table.insert(arenaData.GuardsData[idx].exRewards,_tab)
		-- 	table.insert(SnArr[idx].SnArr2,_tab)
		-- end
	end
end

local function upDateGuardsInfo(data)
	table.sort(data,function (a,b)
		return a[6] <b[6];
	end);

	for i,v in ipairs(data) do
		if arenaData==nil then
			arenaData={}
		end
		if arenaData.GuardsData==nil then
			arenaData.GuardsData={}
		end
		if arenaData.GuardsData[i]==nil then
			arenaData.GuardsData[i]={}
		end

		arenaData.GuardsData[i].status=v[3];
		arenaData.GuardsData[i].buffIncrease=v[4];
		arenaData.GuardsData[i].FightNum=v[5];
		arenaData.GuardsData[i].StartBattlePoint=v[6]
		
		--守卫的奖励 
		local rewardCfg=getArenaReward(v[7])
		arenaData.GuardsData[i].difficulty=tonumber(rewardCfg.condition);
		UpdatePersonReward(rewardCfg,i)

		--根据 pid 获取 rold ID 拿到roleIcon
		arenaData.GuardsData[i].pid=v[1];
		arenaData.GuardsData[i].name=v[2];
	end
end

local function GetGuardHeros(Index)
	local pid=arenaData.GuardsData[Index].pid
	if pid <110000 and pid >100000 then
		arenaData.GuardsData[Index].heroes = getNpcHerosConfigByID(pid)
	else
		if arenaData.GuardsData[Index].heroes ==nil then
			NetworkService.Send(515, {nil,pid})
		end
	end
	return arenaData.GuardsData[Index].heroes
end

local function sendApplyJoinArena()
	local Capacity=HeroModule.GetManager():GetCapacity();
	NetworkService.Send(501, {nil,Capacity})
end

EventManager.getInstance():addListener("server_respond_502", function(event,cmd,data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		NetworkService.Send(503, {nil})	--申请获取对手
		NetworkService.Send(513,{nil})--申请获取selfInfo
	else
		print("err", err);
	end
end)

EventManager.getInstance():addListener("server_respond_504", function(event,cmd,data)
	-- print("@@@504GetGuardInfo"..sprinttb(data))
	local sn = data[1];
	local err = data[2];
	if err==0 then
		updateTotalRewards(data[4]);	
		upDateGuardsInfo(data[3])
		DispatchEvent("GUARDS_INFO_CHANGE");	
	else
		print("获取Guards err", err);
	end
end)

EventManager.getInstance():addListener("server_respond_514", function(event,cmd,data)
	-- print("@514@"..sprinttb(data))
	local sn = data[1];
	local err = data[2];
	if err==0 then
		upDatePlayerInfo(data[3])	
	else
		print("err", err);
	end
end)

--刷新战斗数据
local sn2fightresult = {}
local function sendUpdateFightResult(guardId,fightResult)
	local sn = NetworkService.Send(505, {nil,guardId,fightResult})
	sn2fightresult[sn] = fightResult;
end

EventManager.getInstance():addListener("server_respond_506", function(event,cmd,data)
	-- ERROR_LOG("@@506"..sprinttb(data))
	local sn = data[1];
	local err = data[2];
	local fightResult = sn2fightresult[sn] or 0;
	sn2fightresult[sn] = nil;
	if err == 0 then
		EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT",fightResult,data[5])	
	else
		print("刷新err", err);
	end
end)

--重置
local function sendApplyReset(unFree)
	local sn = NetworkService.Send(507, {nil,unFree})
	if not unFree then
		SnArr[sn] = true
	end
end

EventManager.getInstance():addListener("server_respond_508", function(event,cmd,data)
	-- ERROR_LOG("@@508"..sprinttb(data))
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		if arenaData and arenaData.ArenaData then
			if SnArr[sn] then
				arenaData.ArenaData.lastResetTime = module.Time.now()
				SnArr[sn] = nil
			end	
			upDateGuardsInfo(data[3])
			updateTotalRewards(data[4]);
			DispatchEvent("RESET_INFO");
		else
			ERROR_LOG("ArenaData is nil")
		end
	else
		DispatchEvent("RESET_INFO_FAILED");
		print("重置err", err);
	end
end)

--鼓舞
local function sendAddBuff(gid)
	NetworkService.Send(509, {nil,gid})
end
EventManager.getInstance():addListener("server_respond_510", function(event,cmd,data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		NetworkService.Send(513,{nil})
		DispatchEvent("GET_BUFF_SUCCEED");
	else
		print("err", err);
	end
end)

--领取奖励
local tb = {}
local function sendGetAwards(index)
	local sn = NetworkService.Send(511, {nil,index})
	tb[sn] = index
end
EventManager.getInstance():addListener("server_respond_512", function(event,cmd,data)
	local sn = data[1];
	local err = data[2];
	local index = tb[sn]
	tb[sn] = nil
	if err == 0 then
		DispatchEvent("AWARD_INFO_CHANGE");
	else
		print("err", err);
	end
end)


--挑战
local fightGuardId=0
local EnemyIndex=0
local _challengeTime=0
local tbFight={}
local function sendStartChallenge(enemy_id,Index,challengeTime)
	--print("@@515=="..enemy_id)
	local sn=NetworkService.Send(515, {nil,enemy_id})
	tbFight[sn]={}
	tbFight[sn].fightGuardId=enemy_id
	tbFight[sn].EnemyIndex=Index
	tbFight[sn]._challengeTime=challengeTime
end

EventManager.getInstance():addListener("server_respond_516", function(event,cmd,data)
	-- print("@startChanllge"..sprinttb(data))
	local sn = data[1];
	local err = data[2];
	if err ~= 0 then
        print("请求战斗失败", err)
        return;
    end
    if tbFight[sn] then
		local fightGuardId=tbFight[sn].fightGuardId
		local  EnemyIndex=tbFight[sn].EnemyIndex
		local  _challengeTime=tbFight[sn]._challengeTime
		tbFight[sn]=nil

		SceneStack.Push('battle', 'view/battle.lua', { fight_id = nil, fight_data = data[3], callback = function(win, heros, fightid, starInfo, input_record)		
			sendUpdateFightResult(fightGuardId,win and 1 or 0)
			--EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT",win and 1 or 0,_challengeTime>=1 and SnArr[EnemyIndex].SnArr2 or SnArr[EnemyIndex].SnArr1);			
			local prefab = SGK.ResourcesManager.Load("prefabs/base/ArenaAI_Fight_Result.prefab");
        	local obj =UnityEngine.Object.Instantiate(prefab);
        	EventManager.getInstance():dispatch("ADD_OBJECT_TO_FIGHT_RESULT", obj);
			CS.SGK.UIReference.Setup(obj.gameObject)[SGK.LuaBehaviour]:Call("UpdateResult",{PlayerModule.GetSelfID(),win})
			return true      	
		end});
	else
		local fight_data=data[3]
		local info = ProtobufDecode(fight_data, "com.agame.protocol.FightData")

		for i,v in ipairs(arenaData.GuardsData) do
			if arenaData.GuardsData[i].pid==info.defender.pid  then
				arenaData.GuardsData[i].heroes=info.defender.roles
				DispatchEvent("HEROS_INFO_CHANGE",i);
				break	
			end
		end
	end
end)


EventManager.getInstance():addListener("PLAYER_FIGHT_INFO_CHANGE", function(event,pid,data)
	-- print("===439==",pid)
	if PlayerModule.GetSelfID()~=pid then
		if arenaData and arenaData.GuardsData then
			for i,v in ipairs(arenaData.GuardsData) do
				if arenaData.GuardsData[i].pid==pid  then
					arenaData.GuardsData[i].fightCfg=PlayerModule.GetFightData(pid)	
					DispatchEvent("HEROS_INFO_CHANGE",i);
					break	
				end
			end
		end
	end
end)

return{
		ApplyJoinArena=sendApplyJoinArena,
		GetArenaData=getPlayerArenaData,
		GetGuardsData=getGuardsData,
		ApplyReset=sendApplyReset,
		UpdateFightResult=sendUpdateFightResult,
		SendAddBuff=sendAddBuff,
		SendGetAwards=sendGetAwards,
		startChanllge=sendStartChallenge,

		GetBuffCfgByCondition=getBuffConfigByCondition,
		GetGuardHeros=GetGuardHeros,
		GetGuardData=getGuardConfigByID,
		GetBuffConfigByBuffType=getBuffConfigByBuffType,
}
