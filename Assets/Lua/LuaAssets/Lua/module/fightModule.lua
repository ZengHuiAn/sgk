local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local playerModule = require "module.playerModule"
local Time = require 'module.Time'
local ItemHelper = require "utils.ItemHelper"
local UserDefault = require "utils.UserDefault"
local SceneStack = require "utils.SceneStack";
local HeroModule = require "module.HeroModule"
local player_settings = {}

local function setupDataByKeyword(name, field)
	local data_list = {};

	DATABASE.ForEach(name, function(data)
		if data[field] then
			data_list[data[field]] = setmetatable({_data=data}, {__index=function(t, k) return t._data[k] end});
		end
	end)
	return data_list;
end

local function sortByDepend(t, depend_key)
        local nt = {}
        local first = nil;

        local n = 0;
        for k, v in pairs(t) do
                local nk = v[depend_key];

                nt[nk] = nt[nk] or {}
                nt[k] = nt[k] or {};

                nt[k].target = v;

                nt[k].prev = nt[nk];
                nt[nk].next = nt[k];

                if not t[nk] then
                        first = nt[k];
                end
                n = n + 1;
        end

        assert(first, "depend error");

        local list = {}

        local ln = 0;
        while first and first.target do
                table.insert(list, first.target);
                first = first.next;
                ln = ln  + 1;
        end

		if ln ~= n then
        	ERROR_LOG('not all element in order');
		end

        return list;
end

local chapter_data = nil;

local function loadChapterData()
	if chapter_data == nil then
		chapter_data = setupDataByKeyword("chapter_config", "chapter_id");
		chapter_data[0] = nil
		for _,v in pairs(chapter_data) do
			v.battleConfig = {}
		end
	end
end


local starDecCfgTab = nil
local function starDecCfg(index)
	if starDecCfgTab == nil then
		starDecCfgTab = LoadDatabaseWithKey("starshow", "id")
	end
	if starDecCfgTab[index] and starDecCfgTab[index].starshow then
		return starDecCfgTab[index].starshow
	else
		return "未配置"
	end
end

local function getDecCfgType(index)
	if starDecCfgTab == nil then
		starDecCfgTab = LoadDatabaseWithKey("starshow", "id")
	end
	if starDecCfgTab[index] then
		return starDecCfgTab[index].type
	else
		return "未配置"
	end
end

local function getOpenStar(star, k)
	return star & (1 << ((k-1)*2))
end

local battle_config = nil;
local function loadBattleData()
	if battle_config == nil then
		battle_config = setupDataByKeyword("battle_config", "battle_id")
		battle_config[0] = nil
		for _, v in pairs(battle_config) do
			v.pveConfig = {};
			if chapter_data[v.chapter_id ] then
				chapter_data[v.chapter_id].battleConfig[v.battle_id] = v;
				if chapter_data[v.chapter_id].count == nil then
					chapter_data[v.chapter_id].count = 1;
				else
					chapter_data[v.chapter_id].count = chapter_data[v.chapter_id].count + 1;
				end
			else
				print("chapter", v.chapter_id, "of battle", v.battle_id, "not exists");
			end
		end
	end
end


local pve_fight_config = nil;
local function loadPVEFightData()
	if pve_fight_config == nil then
		pve_fight_config = setupDataByKeyword("pve_fight_config", "gid")
		for _, v in pairs(pve_fight_config) do
			local battle = battle_config[v.battle_id];
			if battle then
				battle.pveConfig[v.gid] = v;
				v.chapter_id = battle.chapter_id;
				if battle.count == nil then
					battle.count = 1;
				else
					battle.count = battle.count + 1;
				end
			elseif v.battle_id > 0 then
				print("battle", v.battle_id, "of fight", v.gid, "not exists");
			end
		end
	end
end

local function InitData()
	loadChapterData();
	loadBattleData();
	loadPVEFightData();
end


local drop_config = nil;
local function getDropConfig(gid)
	if drop_config == nil then
		drop_config = {};

		DATABASE.ForEach("drop_client_config", function(row)
			if row.gid ~= nil then
				drop_config[row.gid] = row;
			end
		end)
	end

	if gid ~= nil then
		return drop_config[gid];
	else
		return drop_config;
	end
end

local wave_config = nil;
local function getWaveConfig(gid)
	if wave_config == nil then
		wave_config = {};
		DATABASE.ForEach("wave_config", function(row)
			if row.gid ~= nil  then
				if wave_config[row.gid] == nil then
					wave_config[row.gid] = {};
				end

				if wave_config[row.gid][row.wave] == nil then
					wave_config[row.gid][row.wave] = {};
				end

				table.insert(wave_config[row.gid][row.wave], row)
			end
		end)
	end
	if gid ~= nil then
		return wave_config[gid];
	else
		return wave_config;
	end
end

-- preload
getWaveConfig();


local function getConfigByID(chapter_id, battle_id, pve_id)
	InitData();

	if pve_id then
		return pve_fight_config[pve_id];
	end

	if battle_id then
		return battle_config[battle_id];
	end

	if chapter_id then
		return chapter_data[chapter_id];
	end
	return chapter_data;
end

local function getBattleConfig(battle_id)
    InitData();
    if battle_id then
        return battle_config[battle_id]
    end
    return battle_config
end

local function getPveConfigByID(gid)
	InitData();

	return pve_fight_config[gid]
end

local chapter_data_sorted = nil;
local function getChapterConfigList(index)
	InitData();

	if not chapter_data_sorted then
		chapter_data_sorted = sortByDepend(chapter_data, "rely_chapter");
	end

	return chapter_data_sorted;
end

local function getBattleConfigListOfChapter(chapter_id)
	InitData();
	local chapter = chapter_data[chapter_id];
	if not chapter then
		return {};
	end

	local sorted_battle_list = chapter.sorted_battle_list;
	if not sorted_battle_list then
		print("sort battle", chapter_id);
		sorted_battle_list = sortByDepend(chapter.battleConfig, "rely_battle");
		chapter.sorted_battle_list = sorted_battle_list;
	end

	return sorted_battle_list;
end

local function getFightConfigListOfBattle(battle_id)
	local battle = battle_config[battle_id];
	if not battle then
		return {};
	end

	local sorted_fight_list = battle.sorted_fight_list;
	if not sorted_fight_list then
		sorted_fight_list = sortByDepend(battle.pveConfig, "depend_fight0_id"); -- TODO
		battle.sorted_fight_list = sorted_fight_list;
	end

	return sorted_fight_list;
end

local StarNum = {};
local function GetStarNum()
	return StarNum;
end

local PlayerFightInfo = {}

local Fight = {}
function Fight.New( v )
	return Fight.Update(setmetatable({}, {__index=Fight}), v)
end

function Fight:Update(v)
	if v then
		local gid, flag, today_count, update_time, star = v[1], v[2], v[3], v[4], v[5];
		self.gid = gid;
		self.flag = flag;
		self.today_count = today_count;
		self.update_time = update_time;
		self.star = star;
		StarNum[gid] = star;
	end
	return self;
end

local function GetFightInfo(gid)
	if not PlayerFightInfo[gid] then
		PlayerFightInfo[gid] = Fight.New({gid, 0, 0, 0, 0})
	end
	local fight = PlayerFightInfo[gid];
	fight:BeforeQuery();
	return fight;
end

function Fight:BeforeQuery()
	if Time.day(self.update_time) < Time.day() then
		self.update_time = Time.now();
		self.today_count = 0;
	end
end

function Fight:IsPassed()
	return self.flag > 0;
end

function Fight:IsOpen()
	local cfg = getPveConfigByID(self.gid);
	if not cfg then
		return true;
	end
	if not playerModule.Get() then
	    return false, SGK.Localize:getInstance():getValue("tips_lv_02", cfg.depend_level_id)
	end
	if cfg.depend_level_id > playerModule.Get().level then
		return false, SGK.Localize:getInstance():getValue("tips_lv_02", cfg.depend_level_id)
	end

	if cfg.check_item_type ~= 0 and cfg.check_item_id ~= 0 then
        local _count = module.ItemModule.GetItemCount(cfg.check_item_id)
        if _count < cfg.check_item_value then
            return false, SGK.Localize:getInstance():getValue("huiyilu_tips_03", utils.ItemHelper.Get(cfg.check_item_type, cfg.check_item_id).name, cfg.check_item_value)
        end
    end
	if cfg.depend_fight0_id ~= 0 and  not GetFightInfo(cfg.depend_fight0_id):IsPassed() then
		--return false, SGK.Localize:getInstance():getValue("huiyilu_tips_01")
		local _charperId,_depend_charperId = string.sub(cfg.gid,1,6),string.sub(cfg.depend_fight0_id,1,6)
		local desc = ""
		--同一副本
		if _charperId == _depend_charperId then
			local _difficultIdx = string.sub(cfg.depend_fight0_id,-2,-2)
			--desc = SGK.Localize:getInstance():getValue(_difficultIdx=="0" and "huiyilu_tips_05" or "huiyilu_tips_06")
			local _cfg = getPveConfigByID(cfg.depend_fight0_id);
			desc = SGK.Localize:getInstance():getValue("huiyilu_tips_08",_cfg.scene_name)
		else
			local _cfg = getPveConfigByID(cfg.depend_fight0_id);
			if _cfg then
				desc = SGK.Localize:getInstance():getValue("huiyilu_tips_08",_cfg.scene_name)
			else
				ERROR_LOG("getPveConfigByID,ID",cfg.depend_fight0_id)
			end
		end
		return false, desc
	end

	if cfg.depend_quest ~= 0 then
		if not module.QuestModule.Get(cfg.depend_quest) or module.QuestModule.Get(cfg.depend_quest).status == 0 then
			local allQuestCfg=module.QuestModule.GetCfg()
			local desc = nil
			for i,v in pairs(allQuestCfg) do
	            if v.id == cfg.depend_quest then
	                desc = "通关副本"..v.name.."后解锁"
	                break
	            end
	        end
			return false, desc
		end	
	end

	if cfg.depend_fight1_id ~= 0 and  not GetFightInfo(cfg.depend_fight1_id):IsPassed() then
		local _charperId,_depend_charperId = string.sub(cfg.gid,1,6),string.sub(cfg.depend_fight1_id,1,6)
		local desc = ""
		--同一副本
		if _charperId == _depend_charperId then
			local _difficultIdx = string.sub(cfg.depend_fight1_id,-2,-2)
			desc = SGK.Localize:getInstance():getValue(_difficultIdx=="0" and "huiyilu_tips_05" or "huiyilu_tips_06")
		else
			desc = SGK.Localize:getInstance():getValue("huiyilu_tips_08",cfg.scene_name)
			local _cfg = getPveConfigByID(cfg.depend_fight1_id);
			if _cfg then
				desc = SGK.Localize:getInstance():getValue("huiyilu_tips_08",_cfg.scene_name)
			else
				ERROR_LOG("getPveConfigByID,ID",cfg.depend_fight1_id)
			end
		end
		return false, desc
	end

    if cfg.depend_star_count > (module.playerModule.Get().starPoint or 0) then
        return false, SGK.Localize:getInstance():getValue("huiyilu_tips_07", cfg.depend_star_count)
    end

	return true
end


-- query
EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, cmd, data)
	NetworkService.QueueRequest(49)
end);

EventManager.getInstance():addListener("server_respond_50", function(event, cmd, data)
	local sn, result = data[1], data[2];
	if result ~= 0 then
		print("query fight info failed")
		return;
	end

	local fight_list = data[3];

	PlayerFightInfo = {};
	for _, v in ipairs(fight_list) do
		local gid = v[1];
		PlayerFightInfo[gid] = Fight.New(v)
	end

	EventManager.getInstance():dispatch("FIGHT_INFO_CHANGE");
end);

EventManager.getInstance():addListener("server_notify_54", function(event, cmd, v)
	local gid, flag, today_count, update_time, star = v[1], v[2], v[3], v[4], v[5];
	if PlayerFightInfo[gid] then
		PlayerFightInfo[gid]:Update(v);
	else
		PlayerFightInfo[gid] = Fight.New(v);
	end
	EventManager.getInstance():dispatch("FIGHT_INFO_CHANGE");
end);

local function getStageIsLock(gid)
	return not GetFightInfo(gid):IsOpen();
end

local command_running = 0;
local function StartFightInThread(gid, isPVP)
	local needPrepare = true;
	local cfg = getPveConfigByID(gid);
	if not cfg or isPVP then
		print("fight config not exist")
		needPrepare = false;
		-- return;
	else
		local fight = GetFightInfo(gid)
		if not fight:IsOpen() then
			print("fight is not open")
			return;
		end

		if cfg.cost_item_type ~= 0 and cfg.cost_item_id ~= 0 then
			local itemInfo = ItemHelper.Get(cfg.cost_item_type, cfg.cost_item_id);
			if itemInfo.count <= 0 or itemInfo.count < cfg.cost_item_value then
				print("consume item not enough")
				return;
			end
		end
	end

	command_running = os.time() + 5;
	local assist_uuid = {};
	local assists = module.HeroModule.GetAssistList();
	for _, v in ipairs(assists) do
		table.insert(assist_uuid, v.uuid);
	end

	print("start request")
	local data = NetworkService.SyncRequest(16001, {nil, gid, isPVP and 0 or 1, {}, assist_uuid});
	command_running = 0;
	print("finished request")

	local sn, result, fight_id, fight_data = data[1], data[2], data[3], data[4];
	if result ~= 0 then
		print("prepare failed", result);
		return;
	end

	local co = coroutine.running();
	SceneStack.Push('battle', 'view/battle.lua', { fight_id = gid, fight_data = fight_data,
		callback = function(win, heros, fightid, starInfo, input_record, info)
			coroutine.resume(co, win, heros, starInfo, input_record, info)
		end});

	local win, heros, starInfo, input_record, info = coroutine.yield();
	if not win  then
		return
	end

	local starValue = 0;
	for k, v in ipairs(starInfo or {}) do
		if v then
			starValue = starValue | (1 << ((k-1)*2));
		end
	end

	command_running = os.time() + 5;
	print('start check', gid, starValue);
	local data = NetworkService.SyncRequest(16005, {nil, gid, starValue, input_record, info.record})
	command_running = 0;

	-- print("check result", sprinttb(data));
	EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT", data[3], data[4]);

	print("wait for scene exist");
	EventManager.getInstance():ThreadWait("SCENE_LOADED");
	if data[2] == 0 then
		return win, data[3], data[4];
	end
end

local function CheckFight(gid, fightid, star, input_record, info)
	if not GetFightInfo(gid):IsOpen() then
		print("fight" .. gid .. " is not open");
		return;
	end

	if command_running > os.time() then
		print("prev command is running")
		return;
	end

	command_running = os.time() + 5;
	coroutine.resume(coroutine.create( function()
		print('start check', gid, star);
		local data = NetworkService.SyncRequest(16005, {nil, fightid, star, input_record, info.record})
		command_running = 0;
		print("check result", sprinttb(data));
		EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT", data[3], data[4]);
	end));
end

local function StartFight(gid, isPVP, callback)
	local needPrepare = true;
	local cfg = getPveConfigByID(gid);
	local next_fight_id = 0;
	local is_repeat = 0;
	if not cfg or isPVP then
		print("fight config not exist")
		needPrepare = false;
		-- return;
	else
		local fight = GetFightInfo(gid)
		if not fight:IsOpen() then
			print("fight is not open")
			return;
		end

		if cfg.cost_item_type ~= 0 and cfg.cost_item_id ~= 0 then
			local itemInfo = ItemHelper.Get(cfg.cost_item_type, cfg.cost_item_id);
			if itemInfo.count <= 0 or itemInfo.count < cfg.cost_item_value then
				print("consume item not enough")
				return;
			end
		end

		if not fight:IsPassed() then
			next_fight_id = cfg.next_fight_id or 0;
		end
		is_repeat = cfg.fight_again
	end

	if command_running > os.time() then
		print("prev command is running")
		return;
	end

	command_running = os.time() + 5;
	coroutine.resume(coroutine.create( function()
		--[[
		if needPrepare then
			local data = NetworkService.SyncRequest(45, {nil, gid, 0, 0});
			local sn, result = data[1], data[2];
			if result ~= 0 then
				print("prepare failed", result);
				command_running = false;
				return;
			end
		end
		--]]

		local assist_uuid = {};
		local assists = module.HeroModule.GetAssistList();
		for _, v in ipairs(assists) do
			table.insert(assist_uuid, v.uuid);
		end

		local data = NetworkService.SyncRequest(16001, {nil, gid, isPVP and 0 or 1, {}, assist_uuid});
		command_running = 0;

		local sn, result, fight_id, fight_data = data[1], data[2], data[3], data[4];
		if result ~= 0 then
			print("prepare failed", result);
			return;
		end

		local next_fight_info = nil;
		ERROR_LOG("next_fight_id", gid , '->', next_fight_id)
		if next_fight_id > 0 then
			next_fight_info = {id = next_fight_id};
		end

		local replay_fight_info = nil
		if is_repeat and is_repeat == 1 then
			replay_fight_info = {id = gid}
		end

		DispatchEvent("battle_event_close_result_panel");
		ERROR_LOG("StartFight Push",module.Time.now())
		SceneStack.Push('battle', 'view/battle.lua', { fight_id = gid, fight_data = fight_data,
			next_fight_info = next_fight_info,
			--再来一次功能
			replay_fight_info = replay_fight_info,
			
			callback = function(win, heros, fightid, starInfo, input_record, info)
				print("fight result", win, callback)
				if callback then
					callback(win, heros, starInfo, fightid, input_record, info);
				else
					if win then
						local starValue = 0;
						for k, v in ipairs(starInfo or {}) do
							if v then
								starValue = starValue | (1 << ((k-1)*2));
							end
						end
						CheckFight(gid, fightid, starValue, input_record, info);
						return true;
					end
				end
			end } );
	end))
end

local function CheckBattleOpen(battleId)
    loadBattleData()
    local _cfg = battle_config[battleId]
    if not _cfg then
        return false, 0
    end
    if _cfg.quest_id ~= nil and _cfg.quest_id ~= 0 then
        if module.QuestModule.Get(_cfg.quest_id) == nil or module.QuestModule.Get(_cfg.quest_id).status ~= 1 then
            return false, 2
        end
    end
    if _cfg.rely_battle ~= nil and _cfg.rely_battle ~= 0 then
        local _cfgBattle = module.fightModule.GetBattleConfig(_cfg.rely_battle)
        if _cfgBattle then
             for k,v in pairs(_cfgBattle.pveConfig) do
                 if not module.fightModule.GetFightInfo(k):IsPassed() then
                     return false, 1
                 end
             end
        end
    end

    return true
end

local nowSelectChapter = nil
local function GetNowSelectChapter()
	if nowSelectChapter then
		return nowSelectChapter
	else
		return {chapterId=1010, idx = 1, difficultyIdx = 1, chapterNum = 1}
	end
end

local function SetNowSelectChapter(chapter)
	nowSelectChapter = chapter
end

local newSelectMapScroolbarValue = {}
local function GetScroolbarValue(chapter_id,idx)
	if newSelectMapScroolbarValue[chapter_id] then
		return newSelectMapScroolbarValue[chapter_id][idx]
	else
		newSelectMapScroolbarValue[chapter_id] = {}
		newSelectMapScroolbarValue[chapter_id][idx] = 0
		return nil
	end
end

local function SetScroolbarValue(chapter_id,idx,value)
	if newSelectMapScroolbarValue[chapter_id] then
		newSelectMapScroolbarValue[chapter_id][idx]= value
	else
		newSelectMapScroolbarValue[chapter_id]={}
		newSelectMapScroolbarValue[chapter_id][idx]= value
	end
	--print("zoe",sprinttb(newSelectMapScroolbarValue))
end

EventManager.getInstance():addListener("battle_event_next_fight", function(event, data)
	ERROR_LOG("battle_event_next_fight", data and data.id)
	if data and data.id then
		StartFight(data.id);
	end
end);

EventManager.getInstance():addListener("battle_event_replay_fight", function(event, data)
	ERROR_LOG("battle_event_replay_fight", data)
	if data and data.id then
		StartFight(data.id);
	end
end);

local function  sweeping(gid, count)
	NetworkService.Send(84, {nil, gid, count or 1})
end

local function resetFightCount(gid)
    NetworkService.Send(53, {nil, gid})
end

EventManager.getInstance():addListener("server_respond_85", function(event, cmd, data)
	local sn = data[1];
    local err = data[2];
    if err == 0 then
        EventManager.getInstance():dispatch("LOCAL_FIGHT_SWEEPING", data[3])
    else
    	print("server_respond_85 error", err)
    end
end);

EventManager.getInstance():addListener("server_respond_54", function(event, cmd, data)
	local sn = data[1];
    local err = data[2];
    if err == 0 then
        showDlgError(nil, "重置成功")
        EventManager.getInstance():dispatch("LOCAL_FIGHT_COUNT_CHANGE")
    else
        showDlgError(nil, "重置失败")
    	print("server_respond_54 error", err)
    end
end);

return {
	GetConfig = getConfigByID,
	GetPveConfig = getPveConfigByID,
	-- SetPass = setPassStatus,
	-- GetChapterConfig = getChapterConfigByIndex,
	-- Sort = sortConfig, -- TODO:
	-- GetPlayerData = getCurPlayerData, -- TODO
	IsLock = getStageIsLock,

	GetWaveConfig = getWaveConfig,
	GetDropConfig = getDropConfig,

	GetFightInfo = GetFightInfo,

	GetChapterConfigList = getChapterConfigList,
	GetBattleConfigListOfChapter = getBattleConfigListOfChapter,
	GetFightConfigListOfBattle = getFightConfigListOfBattle,

	StartFight = StartFight,
	CheckFight = CheckFight,
	StartFightInThread = StartFightInThread,
	GetStarDec = starDecCfg,
	GetDecCfgType = getDecCfgType,
	GetOpenStar = getOpenStar,

	GetStarNum = GetStarNum,
	Sweeping = sweeping,
    ResetFightCount = resetFightCount,
    GetBattleConfig = getBattleConfig,
	CheckBattleOpen = CheckBattleOpen,
	player_settings = player_settings,

	GetNowSelectChapter = GetNowSelectChapter,
	SetNowSelectChapter = SetNowSelectChapter,

	GetScroolbarValue = GetScroolbarValue,
	SetScroolbarValue = SetScroolbarValue,
}
