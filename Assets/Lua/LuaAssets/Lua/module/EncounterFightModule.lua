local MapConfig = require "config.MapConfig"
local battle_config = require "config.battle"
local NetworkService = require "utils.NetworkService"

local FightData = {}

local function SetFightData(data)--mapid,fun)
	if not data.fun then
		ERROR_LOG("不能注册一个空的战斗")
		return;
	end

	FightData[data.map_id] = FightData[data.map_id] or {};
	if data.type then
		FightData[data.map_id][data.type] = data;
	else
		table.insert(FightData[data.map_id],data)
	end

	DispatchEvent("Reset_EncounterFight")
end
local function GetFightData(mapid)
	return FightData[mapid]
end

local function ResetFightData(mapid)
	FightData[mapid] = nil;
end

local function RemoveFightDataByType(type)
	for _, v in pairs(FightData) do
		v[type] = nil;
	end
end

local function EncounterFight(mapid)
	local events = FightData[mapid] or {};

	local list = {};
	for k, v in pairs(events) do
		table.insert(list, {k, v});
	end

	if #list == 0 then
		return false;
	end

	local idx = math.random(1, #list);
	local key, data = list[idx][1], list[idx][2];

	local teamInfo = module.TeamModule.GetTeamInfo();
	if teamInfo.group ~= 0 then
		local list = ""
		local members = module.TeamModule.GetTeamMembers()
		for k,v in ipairs(members) do
			if v.level < data.depend_level then
				list = list..v.name.."、"
			end
		end
		if list ~= "" then
			showDlgError(nil,"队员"..list.."等级不符合要求")
			return false
		end
	else
		if module.playerModule.Get().level < data.depend_level then
			showDlgError(nil,"您的等级不符合要求")
			return false
		end
	end

	showDlgError(nil,"触发战斗")
	if not data.type then
		table.remove(FightData[mapid], key)
	end

	assert(coroutine.resume(coroutine.create(data.fun)));
	return true
end

local CombatTYPE = 0--0可进入战斗1玩家主动退出战斗
local function SetCombatTYPE(TYPE)
	CombatTYPE = TYPE
end

local CombatData = nil
local function CombatDataPersistence(data)
	--ERROR_LOG("->"..tostring(data))
	CombatData = data
	CombatTYPE = 0
end
local function GetCombatData()
	if CombatData then
		return true
	end
	return false
end
local function StartCombat(Fightdata)
	if Fightdata then
		CombatData = Fightdata
	end
	if CombatData and CombatTYPE == 0 then
		if CombatData then--直接启动战斗
			local data = CombatData

			-- for i = 1, 100 do
			-- 	if not utils.DialogStack:Top() then -- 临时方案、关闭所有窗口、防止恢复时候错误
			-- 		break;
			-- 	end
			-- 	utils.DialogStack:Pop();
			-- end

			SceneStack.Push('battle', 'view/battle.lua', {
				fight_data      = data[2][1],
				round_timeout   = data[2][2],
				commandQueue    = data[2][3],
				fastforward     = {tick = data[2][4]},
				hero_timeout    = data[2][5] or {999},
				partner_data    = data[2][6],
				force_sync_data = true,
				remote_server   = true,
				callback = function(win, heros)
					-- print("!!!!!!!!!!!!!!!! fight result", win)
					if win then

					end
					CombatData = nil
			end } )
		else
			module.TeamModule.SyncFightData(10)--战斗重启
		end
	end
end

local current_guide_action = nil;
local function GUIDE_EnterMap(name,arg)
	if SceneStack.CurrentSceneName() == name or name == SceneStack.CurrentSceneID() then
		return;
	end

	SceneStack.EnterMap(name,arg)
	current_guide_action = {map = {name=name} }

	if coroutine.isyieldable() then
		current_guide_action.co = coroutine.running();
		coroutine.yield();
	end
end

local function GUIDE_Interact(name)
	current_guide_action = {interact={name=name}}
	DispatchEvent("GUIDE_INTERACT", current_guide_action.interact);
	if coroutine.isyieldable() then
		current_guide_action.co = coroutine.running();
		coroutine.yield();
	end
end

local function GUIDE_ON_Interact()
	if current_guide_action then
		local co = current_guide_action.co;
		current_guide_action = nil;
		if co then
			coroutine.resume(co)
		end
	end
end

utils.EventManager.getInstance():addListener("NPC_OBJ_INFO_CHANGE", function(event, data)
	if current_guide_action then
		if data and current_guide_action.interact and "NPC_"..data == current_guide_action.interact.name then
			DispatchEvent("GUIDE_INTERACT", current_guide_action.interact);
		end
	end
end)

local function GUIDE_GetInteractInfo()
	return current_guide_action and current_guide_action.interact;
end

local function GUIDE_Stop()
	utils.SGKTools.SetTaskId(0)
	current_guide_action = nil;
end

local function GUIDE_Stop_Push_Dialog()
    local _guide = module.EncounterFightModule.GUIDE.GetInteractInfo()
    if _guide and _guide.name then
        utils.SGKTools.StopPlayerMove()
    end
end

local function GUIDE_GetCurrentMapName()
	return SceneStack.CurrentSceneName();
end

local function GUIDE_GetCurrentMapID()
	return SceneStack.CurrentSceneID();
end

local function GUIDE_StartPVEFight(fightID)
	if not coroutine.isyieldable() then
		module.FightModule.StartFight(fightID)
	else
		return module.FightModule.StartFightInThread(fightID)
	end
end

utils.EventManager.getInstance():addListener("MAP_SCENE_READY", function(event, name)
	if current_guide_action and current_guide_action.map and (name == current_guide_action.map.name or SceneStack.CurrentSceneID() == tonumber(current_guide_action.map.name))then
		local co = current_guide_action.co;
		current_guide_action = nil;
		if co then
			coroutine.resume(co)
		end
	end
end)

local NPC_Script = {}
function NPC_Script.New(gameObject)
	return setmetatable({player=gameObject:GetComponent(typeof(SGK.MapPlayer))}, {__index=NPC_Script});
end

function NPC_Script:MoveTo(...)
	local co = coroutine.running();
	assert(co and coroutine.isyieldable(), "can't sleep in main thread");
	self.player:MoveTo(...);
	self.player:WaitForArrive(function()
		coroutine.resume(co);
	end)
	return coroutine.yield();
end

function NPC_Script:Interact(obj)
	local co = coroutine.running();
	assert(co and coroutine.isyieldable(), "can't sleep in main thread");
	self.player:Interact(obj);
	self.player:WaitForArrive(function()
		coroutine.resume(co);
	end)
	return coroutine.yield();
end

function NPC_Script:Sleep(n)
	local co = coroutine.running();
	assert(co and coroutine.isyieldable(), "can't sleep in main thread");
	self.player:WaitForSeconds(n or 0, function()
		coroutine.resume(co);
	end)
	return coroutine.yield();
end

function NPC_Script:Roll(n)
	self.player.rolling = 0.1;
	self:Sleep(0.1 * n);
	self.player.rolling = 0;
end

local function NPC_init(gameObject)
	return NPC_Script.New(gameObject);
end

local function StartGuideTeamFight()
	assert(coroutine.resume(coroutine.create(function()
		local data = NetworkService.SyncRequest(16001, {nil, 11701, 1});

		module.TeamModule.GetTeamPveFightId(11701)--设置组队战斗Id
		local guideResultModule = require "module.GuidePubRewardAndLuckyDraw"
		guideResultModule.CheckGuideStatus()

		local sn, result, fight_id, fight_data_binary = data[1], data[2], data[3], data[4];
		if result ~= 0 then
			print("prepare failed", result);
			return;
		end

		local fight_data = ProtobufDecode(fight_data_binary, "com.agame.protocol.FightData");
		local function createFightRoles(...)
			local args = {...}
			local roles = {}
			for i = 1, 5 do
				if args[i] then
					local r = battle_config.LoadNPCFightData(args[i][1], args[i][2], i);
					if r then table.insert(roles, r); end
				end
			end
			return roles;
		end

		fight_data.additional_attackers = {}

		fight_data.additional_attackers[1] = {
			pid = -10001, level = 15, name = "玩家1", auto_input = 3,
			roles = createFightRoles({60022, 19}, {60023, 15}, {60024, 15}, {60025, 15}, {60027, 15})
		}

		fight_data.additional_attackers[2] = {
			pid = -10002, level = 17, name = "玩家2", auto_input = 3,
			roles = createFightRoles({60022, 15}, {60023, 17}, {60024, 17}, {60025, 17}, {60028, 17})
		}
		fight_data.additional_attackers[3] = {
			pid = -10003, level = 16, name = "玩家3", auto_input = 3,
			roles = createFightRoles({60022, 16}, {60023, 16}, {60024, 16}, {60025, 16}, {60026, 16})
		}
		fight_data.additional_attackers[4] = {
			pid = -10004, level = 19, name = "玩家4", auto_input = 3,
			roles = createFightRoles({60022, 17}, {60023, 19}, {60024, 19}, {60025, 19}, {60029, 19})
		}

		local co = coroutine.running();
		SceneStack.Push('battle', 'view/battle.lua', {
			fight_id   = fight_id,
			fight_data = fight_data,
			callback = function(win, heros, fightid, starInfo, input_record, info)
				-- return false;
				guideResultModule.UpdateGuideStatus(win)
			end});
	end)));
end

return {
	SetFightData = SetFightData,
	GetFightData = GetFightData,
	ResetFightData = ResetFightData,
	RemoveFightDataByType = RemoveFightDataByType,
	EncounterFight = EncounterFight,
	CombatDataPersistence = CombatDataPersistence,
	StartCombat = StartCombat,
	SetCombatTYPE = SetCombatTYPE,
	GetCombatData = GetCombatData,
	StartGuideTeamFight = StartGuideTeamFight,
	GUIDE = {
		EnterMap = GUIDE_EnterMap,
		Interact = GUIDE_Interact,
		Stop     = GUIDE_Stop,
        StopPushDialog = GUIDE_Stop_Push_Dialog,
		GetCurrentMapName = GUIDE_GetCurrentMapName,
		GetCurrentMapID = GUIDE_GetCurrentMapID,
		StartPVEFight = GUIDE_StartPVEFight,

		ON_Interact = GUIDE_ON_Interact,
		GetInteractInfo = GUIDE_GetInteractInfo,

		NPCInit = NPC_init,
	}
}
