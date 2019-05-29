
local EventManager = require 'utils.EventManager';

local fightModule = require "module.fightModule";
local Time = require "module.Time"
local trialTowerConfig = require "config.trialTowerConfig"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"

local function GetFightInfo(gid)
	local info = fightModule.GetFightInfo(gid);
	return info ;
end

--当前层数
local current = nil

local data = nil


local function buildCfg()
	local info = fightModule.GetBattleConfigListOfChapter(6000);
	-- print("试练塔信息",sprinttb(info));

	-- print("试练塔配置信息",sprinttb(info[1].pveConfig));

	
end
--获取到当前层数
local isTop = false
local function GetBattleConfigListOfChapter()
	-- buildCfg();
	local info = fightModule.GetBattleConfigListOfChapter(6000);
	if not data then
		--todo
		for k,v in pairs(info[1].pveConfig) do
			data = data or {};
			table.insert(data,v);
		end
		
		table.sort( data, function ( a,b )
			return a._data.gid <b._data.gid ;
		end )
	end
	--print("配置信息",sprinttb(data));
	local temp = nil;
	for i=1,#data do
		local value = GetFightInfo(data[i]._data.gid);
		-- ERROR_LOG("试练塔信息",sprinttb(value));
		-- print(value:IsPassed());
		if not value:IsPassed() then
			temp = value;
			break;
		end
	end
	if not temp then
		isTop = true
		current = GetFightInfo(data[#data]._data.gid)
	else
		isTop = false
		current = temp;
	end
	return current,current and info[1].pveConfig[current.gid] or nil;
end

local function GetIsTop()
	return isTop
end

local function GetFightIDAndWaveByNpcID(npc_id)
	local allCfg = trialTowerConfig.GetConfig()
	--ERROR_LOG("shilianta全部配置",sprinttb(allCfg))
	for i,v in pairs(allCfg) do
		if v.map_npc_gid1 == npc_id then
			--ERROR_LOG("试练塔怪物配置",sprinttb(v))
			return v.fight_id,v.wave
		end
	end
	return 60000100
end

local function GetWaveByNPCHelpID(npc_id)
	local allCfg = trialTowerConfig.GetConfig()
	--ERROR_LOG("shilianta全部配置",sprinttb(allCfg))
	for i,v in pairs(allCfg) do
		if v.map_npc_gid2 == npc_id then
			--ERROR_LOG("试练塔怪物配置",sprinttb(v))
			return v.wave
		end
	end
	return 10
end

local function StartFight(callback)
	if not current then
		GetBattleConfigListOfChapter();
	end 
	-- print("开始打"..tostring(current.gid));
	if current and current.gid then
		fightModule.StartFight(current.gid);
	end
end

local isSweep = false
local function IsSweep(bool)
	if bool then
		isSweep = true
	else
		return isSweep
	end
end

local sweepWave = 0
local function GetSweepWave(value)
	if value then
		sweepWave = value
	else
		return sweepWave
	end
end

local sweepLayer = 0
local function SetSweepLayer(layer)
	if layer then
		sweepLayer = layer
	else
		return sweepLayer
	end
end

local function ClearAllSweepData()
	isSweep = false
	sweepWave = 0
	sweepLayer = 0
end

local function GetIsSweeping()

	if not current then
		GetBattleConfigListOfChapter();
	end

	if current and current.gid then
		--todo
		local cfg = trialTowerConfig.GetConfig(current.gid-1);
		--print("==============",cfg);
		if not cfg then
			return;
		end

		local quest_id = cfg.reward_quest;
		local info = module.QuestModule.Get(quest_id);
		ERROR_LOG(sprinttb(info));
		if info and info.status == 0 then
			return true;
		end
	end
end

local function GetReward(fight_id)
	local fightCfg = fightModule.GetConfig(nil,nil,fight_id)
	--ERROR_LOG("战斗配置",sprinttb(fightCfg))
	local Fight_reward = SmallTeamDungeonConf.GetFight_reward(fightCfg.drop1)
	local reward = {firstReward = {},accumulate = {}}
	for k,v in pairs(Fight_reward) do
		if v.first_drop == 1 then
			table.insert(reward.firstReward,{id = v.id,type =v.type,count = v.min_value})
		elseif v.first_drop == 0 then
			table.insert(reward.accumulate,{id = v.id,type =v.type,count = v.min_value})
		end
	end
	return reward
end

EventManager.getInstance():addListener("FIGHT_INFO_CHANGE",function ( event,cmd,data )
	-- ERROR_LOG("FIGHT_INFO_CHANGE=====================>>>>>>>>",sprinttb(data));
	local flag = current
	if not current then
		flag = nil
	end 
	GetBattleConfigListOfChapter();
	if flag then
		if flag ~=current then
			DispatchEvent("TOWER_FLOOR_CHANGE");
		end
	else
		if current then
			DispatchEvent("TOWER_FLOOR_CHANGE");
		end
	end
end)

local fresh_Fightid = nil;

local function GetCurrent()
	return fresh_Fightid;
end

local function SetCurrent(id)
	if fresh_Fightid == id then
		-- print("当前id和战斗id相同");
	else
		fresh_Fightid = id;
	end
end

local function GetLayer()
	local gid = GetBattleConfigListOfChapter().gid
	local index = gid - 60000000
	local third = math.floor(index / 100) 
	local second = math.floor(index / 10)
	local first = index % 10
	return first,second,third
end

local wave = nil
local function GetNowWave(bool)
	if bool then
		wave = nil
	else
		if wave then
			return wave
		else
			wave = trialTowerConfig.GetConfig(GetBattleConfigListOfChapter().gid).wave
			return wave
		end
	end 
end

local function GetPos()
	local gid = GetBattleConfigListOfChapter().gid
	local cfg = trialTowerConfig.GetConfig(gid)
	if cfg then
		return {cfg.initialposition_x,cfg.initialposition_y,cfg.initialposition_z}
	else
		return {-14.3,5.34,14.36}
	end
end

local LayarGid = 0
local function SaveLayarGid(gid)
	if gid then
		LayarGid = gid
	else
		return LayarGid
	end
end

return {
	Get               = GetFightInfo,
	GetBattleConfig   = GetBattleConfigListOfChapter,
	GetIsTop          = GetIsTop,
	GetFightIDAndWaveByNpcID = GetFightIDAndWaveByNpcID,
	GetWaveByNPCHelpID = GetWaveByNPCHelpID,
	StartFight		  = StartFight,
	GetCurrent		  = GetCurrent,
	GetReward         = GetReward,
	SetCurrent		  = SetCurrent,
	IsSweep           = IsSweep,
	GetSweepWave      = GetSweepWave,
	SetSweepLayer     = SetSweepLayer,
	ClearAllSweepData = ClearAllSweepData,
	GetIsSweeping     = GetIsSweeping,
	GetLayer          = GetLayer,
	GetNowWave        = GetNowWave,
	GetPos            = GetPos,
	SaveLayarGid      = SaveLayarGid,
}