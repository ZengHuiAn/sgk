local NetworkService = require "utils.NetworkService";
local EventManager = require 'utils.EventManager';
local Time = require "module.Time"
local Property = require "utils.Property"

local AllReward = LoadDatabaseWithKey("expedition_reward", "gid", "type");
-- local BattleReward = {};
for k,v in pairs(AllReward) do
	local temp = {type = v.reward_type,id = v.reward_id,value = v.reward_value};
	v.reward = v.reward or {};
	table.insert(v.reward,temp);
end

-- print(sprinttb(AllReward));



local buff_config = LoadDatabaseWithKey("expedition_random", "gid")

local flag = nil;

local function buildStorys(base,num)
	local temp = {};

	for i=0, num-1 do
		table.insert(temp,base+i);
	end
	return temp;
end
local function buildRandomConfig()
	if not flag then
		for k,v in pairs(buff_config) do
			if v.story ~=0 then
				v.storys = buildStorys(v.story,v.storymax);
			end
		end
	end
	flag = true;
end

local function GetBuffConfig(id)

	buildRandomConfig();
	return id and buff_config[id] or buff_config;
end


local consume_config = nil;


local function LoadConsumeConfig()
	if consume_config  then return end
	consume_config = {}

	DATABASE.ForEach("expedition_consume", function(row)
		consume_config[row.type] = consume_config[row.type] or {};
		consume_config[row.type][row.id] = row;
    end)
    -- ERROR_LOG("消耗品",sprinttb(consume_config));
end




local function GetConsumeConfig(type,id)
	LoadConsumeConfig();

	return consume_config[type][id];
end



-- local BattleReward = {};
-- for k,v in pairs(AllReward) do
-- 	local temp = {type = v.reward_type,id = v.reward_id,value = v.reward_value};
-- 	v.reward = v.reward or {};
-- 	table.insert(v.reward,temp);
-- end

-- print(sprinttb(AllReward));

--当前层数
local currentSteps = 0;

local function getCurrent()
	-- ERROR_LOG("当前层数",currentSteps);
	return currentSteps;
end

local FightSN = nil

--开战
local function StartFight(func)

	FightSN = FightSN or {};
	local ret = NetworkService.Send(541,{nil,currentSteps});
	FightSN[ret] = func;
end 

EventManager.getInstance():addListener("server_respond_542",function ( event,cmd,data )
	-- ERROR_LOG("开战","server_respond_542",sprinttb(data));
	if FightSN[data[1]] then

		FightSN[data[1]](data[2]);
		DispatchEvent("EXP_FIGHT_SUCCESS");
		FightSN[data[1]] = nil;
	end
end)

local battleRew = nil;


local monsterPid = nil;

--npc减血的列表
local cutList = nil
local selfBuff = nil;

--敌人阵容列表数据
local monsters = nil;
local enemyBuff = nil;

--影子数据
local ghosts = nil;

--获取敌人阵容数据
local function  GetMonsters( ... )
	return monsters;
end

local function GetMonsterPid()
	return monsterPid;
end

local function GetBattleReward(steps)
	battleRew = AllReward[steps or currentSteps]
	return battleRew and battleRew.reward or {};
end

--获取自己的玩家角色列表
local function  GetCutList()
	return cutList or {};
end 

--获取影子数据
local function GetGhostsData()
	return ghosts or {};
end

-- GetBuffConfig();

--处理buff数据
local function UpdateBuffData(_data)
	local temp = {}

	if _data and #_data>0 then
		for k,v in pairs(_data) do
			if v[1] ~= 0 then
				local flag = nil
				for _k,_v in pairs(temp) do

					
					local cfg = GetBuffConfig(v[1]);
					local _cfg = GetBuffConfig(_v.id);
					if cfg.reward_type == _cfg.reward_type and _v.value == v[2] then
						local rate = math.abs(cfg.reward_value or 0) / cfg.rate;
						_v.rate = _v.rate + rate;
						_v.count = _v.count +1;
						flag = true;
					end
				end
				if not flag then
					local cfg = GetBuffConfig(v[1]);

					local _value = (math.abs(cfg.reward_value)  or 0) / cfg.rate;
					local _flag = (cfg.rate ==100 and "%" or ""); 
					local data = { type = cfg.reward_type,id = v[1],count = 1,value = v[2], status = _flag,desc = cfg.desc , rate = _value,icon = cfg.icon};
					table.insert(temp,data);
				end
			end
		end
		local buff = nil;
		for k,v in pairs(_data) do
			if v[1] ==0 then
				local data = { id = v[1],value = v[2] };
				if not buff then
					buff = data;
				else
					buff.value = buff.value + 1;
				end
			end
		end
		if buff then
			table.insert( temp,buff )
		end
	end
	return temp;
end

--鼓舞士气更新自己的buff
local function UpdateSelfBuff(_data)
	selfBuff = selfBuff or {};

	table.insert(selfBuff,UpdateBuffData(_data));
end

local function UpdateEnemyBuff(_data)
	enemyBuff = enemyBuff or {};
	table.insert(enemyBuff,UpdateBuffData(_data));
end

local Queryflag = nil;
local function QueryBuffInfo( flag )
	Queryflag = (not flag and 1 or 2);
	NetworkService.Send(601,{nil,Queryflag});
end

local moraleSn = nil

--鼓舞士气
local function getMorale(func)
	moraleSn = moraleSn or {};	
	local ret = NetworkService.Send(545,{nil});

	moraleSn[ret] = func;
end

local ghostSn = nil

local function InterGhosts(id,func)
	ghostSn = ghostSn or {};	
	-- print("发协议")
	local ret = NetworkService.Send(543,{nil,id});
	ghostSn[ret] = func;
end

EventManager.getInstance():addListener("server_respond_544",function ( event,cmd,data )
	-- ERROR_LOG("交互结果","server_respond_544",sprinttb(data));
	if ghostSn[data[1]] then
		ghostSn[data[1]](data);
		ghostSn[data[1]] = nil;
	end


	if data[2] == 0 then
		--自己加buff
		ghosts[data[5]] = 1;
	end
end)






local sn = nil;
--获取准备数据
local function GetPrepare(func)
	-- print("发送协议");
	sn = sn or {};

	local ret = NetworkService.Send(539,{nil});

	sn[ret] = func;
end 


local function ChangeEnemy(  )
	NetworkService.Send(547,{nil});
end



--处理角色数据
local function UpdateNpcData(_data)
	-- ERROR_LOG("&& 血量&&",sprinttb(_data));
	local temp = {};

	if _data and #_data>0 then
		for k,v in pairs(_data) do
			local data = {id = v[1],value = v[2]};
			table.insert(temp,data);
		end
	end
	return temp;
end




local function GetMonsterHP(hero)
	local propertys = hero.propertys;

	for k,v in pairs( propertys ) do
		if v.type == 1598 then
			return (10000 - v.value)/100;
		end
	end
end

local battle = nil;

local function GetBattle( )
	return battle;
end

local function  GetCapacityByFormation(_info)
	
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


local function UpdateEnemyList(Binary)
	local fight_data = ProtobufDecode(Binary, "com.agame.protocol.FightPlayer")
	ERROR_LOG("对方战斗数据",sprinttb(fight_data));
	battle = fight_data;
	local ret = {};
	monsterPid = fight_data.pid;
	ERROR_LOG("对手PID",monsterPid);
	for k,v in pairs(fight_data.roles) do

		local _value = GetMonsterHP(v);
		ret[k] = {id = v.id,level = v.level,value = _value,star = v.star};
	end
	return ret;
end

local changeCount = 0;

local function GetChangeCount()
	return changeCount;
end


local changeBuffCount = 0;

local function GetChangeBuffCount()
	return changeBuffCount;
end


local function InitghostsData(data)
	local temp = {};

	for k,v in pairs(data) do
		temp[v[1]] = v;
	end
	return temp;
end

local function FreshHeroUUidData(data)
	if #data ==0 then return {} end 
	local temp = {};
	for k,v in pairs(data) do
		local gid = module.HeroModule.GetManager():GetByUuid(v.id);
		temp[gid.id] = (10000 - v.value)/100;
	end
	return temp;
end

EventManager.getInstance():addListener("server_respond_540",function ( event,cmd,data )
	-- ERROR_LOG("获取准备数据","server_respond_540",sprinttb(data));

	if sn[data[1]] then
		sn[data[1]](data[2]);
		sn[data[1]] = nil;
	end

	if data[2] == 0 then

		selfBuff = UpdateBuffData(data[3][1]);

		currentSteps = data[5];

		cutList = FreshHeroUUidData(UpdateNpcData(data[3][2]));
		monsters = UpdateEnemyList(data[4][1]);

		enemyBuff = UpdateBuffData(data[4][2]);

		ghosts = InitghostsData(data[8]);


		changeCount = data[6];

		changeBuffCount = data[7];

		
		DispatchEvent("GET_READY_DATA");
	else
		ERROR_LOG("获取失败");
	end
end)


--获取自己身上的buff
local function GetSelfBuff()
	return selfBuff or {};
end

local function GetEnemyBuff()
	return enemyBuff or {};
end


--获取宝箱奖励
local boxInfo = nil;

local function QueryBoxInfo()
	NetworkService.Send(535,{});
end

EventManager.getInstance():addListener("server_respond_536",function ( event,cmd,data )
	-- ERROR_LOG("查询奖励","server_respond_536",sprinttb(data));

	if data[2] == 0 then
		-- ERROR_LOG("初始化奖励");

		local temp = InitghostsData(data[3]);
		local info = {};
		for k,v in pairs(temp) do
			if v[2] == 0 then
				info[k] = nil;

			else
				info[k] = v;
			end
		end
		boxInfo = info;
	end
	DispatchEvent("GET_BOX_REWARD",(data[2] == 0));
end)

local function GetBoxInfo()
	return boxInfo or {}
end


local function AwardsBox(gid)

	-- ERROR_LOG("领取奖励的gid",gid);
	NetworkService.Send(537,{nil,gid});
end

EventManager.getInstance():addListener("server_respond_538",function ( event,cmd,data )
	-- ERROR_LOG("领取奖励","server_respond_538",sprinttb(data));

	DispatchEvent("GET_BOX_AWARDS",(data[2] == 0));
end)



EventManager.getInstance():addListener("FIGHT_INFO_CHANGE",function ( event,cmd,data )
	-- ERROR_LOG("FIGHT_INFO_CHANGE=====================>>>>>>>>",sprinttb(data));
end)

EventManager.getInstance():addListener("server_respond_548",function ( event,cmd,data )
	-- ERROR_LOG("更换对手","server_respond_548",sprinttb(data));

	if data[2] == 0 then
		-- body
		monsters = UpdateEnemyList(data[3]);

		-- print("敌人血量",sprinttb(monsters))
		changeCount = changeCount + 1
	end
	DispatchEvent("EXP_CHANGE_ENEMY",data[2])
	
end)

EventManager.getInstance():addListener("server_respond_602",function ( event,cmd,data )
	-- ERROR_LOG("查询buff","server_respond_602",sprinttb(data));

	if data[2] == 0 then

		if Queryflag == 1 then
			selfBuff = UpdateBuffData(data[3]);
		else
			enemyBuff = UpdateBuffData(data[3]);
		end
		
		DispatchEvent("EXP_QUERY_BUFF",Queryflag);

		Queryflag = nil;
	end
	
end)

--鼓舞士气结果
EventManager.getInstance():addListener("server_respond_546",function ( event,cmd,data )
	-- ERROR_LOG("鼓舞士气","server_respond_546",sprinttb(data));
	if moraleSn[data[1]] then

		moraleSn[data[1]](data[2]);

		moraleSn[data[1]] = nil;
	end

	if data[2] == 0 then
		changeBuffCount = changeBuffCount + 1;
		-- print("次数====",changeCount)
	end
	DispatchEvent("MORALE_SUCCUSS",data[2]);
end)




return
{
	GetMorale 		= getMorale,
	StartFight	 	= StartFight,
	GetMonsters 	= GetMonsters,
	GetBattleReward = GetBattleReward,
	GetCutList 		= GetCutList,
	GetPrepare		= GetPrepare,
	GetGhostsData	= GetGhostsData,
	GetCurrent		= getCurrent,
	GetEnemyBuff	= GetEnemyBuff,
	GetMonsterPid	= GetMonsterPid,
	GetSelfBuff		= GetSelfBuff,
	GetBuffConfig	= GetBuffConfig,
	--查询奖励
	QueryBoxInfo	= QueryBoxInfo,

	GetBoxInfo 		= GetBoxInfo,

	--领取奖励
	AwardsBox		= AwardsBox,
	--获取更换对手的次数
	GetChangeCount  = GetChangeCount,
	--获取鼓舞士气的次数
	GetChangeBuffCount = GetChangeBuffCount,
	--获取消耗配置
	GetConsumeConfig = GetConsumeConfig,
	--交互影子
	InterGhosts     = InterGhosts,
	--获取本场战斗数据
	GetBattle   	= GetBattle,

	GetCapacityByFormation = GetCapacityByFormation,

	ChangeEnemy = ChangeEnemy, 
	QueryBuffInfo = QueryBuffInfo,
}