local QuestConfig = utils.class();

local auto_accept_quest_list = {}
local npc_quest_list = {};
local npc_submit_list = {}  ---交任务的npc
local npc_status_funcList = {}
local mutex_id_list = {} --互斥Id任务分组
local AutoAcceptNextIdList = {} --自动接下一任务id

local CityContuctId = {41, 42, 43, 44}
local ActivityBountyId = {51, 52, 53, 54}

local _cityContuctInfo = nil;
function QuestConfig:_init_(row, advance)
    self.id   = row.id;
    self.type = row.type;
    self.day7_type = row.day7_type;
    self.guide_type = row.is_fuben_quest;

    self.depend = {fight = 0, quest = 0, level = 0};
    self.condition = {};
    self.time = {from=0, to=0xffffffff, period = 0xffffffff, duration = 0xffffffff};
    self.count_limit = 0;

    self.auto_accept = false;
    self.only_accept_by_other_activity = true;
    if advance then
        self.desc = row.desc1;

        self.auto_accept = (row.auto_accept ~= 0)
        self.autoAcceptType = row.auto_accept
        self.only_accept_by_other_activity = (row.only_accept_by_other_activity ~= 0)

        self.depend.fight = row.depend_fight_id;
        self.depend.quest = row.depend_quest_id;
        self.depend.level = row.depend_level;

        table.insert(self.condition, {type=row.event_type1, id=row.event_id1, count=row.event_count1})
        table.insert(self.condition, {type=row.event_type2, id=row.event_id2, count=row.event_count2})

        self.time.from = row.begin_time;
        if row.end_time > 0 then
            self.time.to   = row.end_time;
        end

        if row.period > 0 then
            self.time.period = row.period;
        else
            self.time.period = self.time.to - self.time.from;
        end

        if row.duration > 0 then
            self.time.duration = row.duration;
        else
            self.time.duration = self.time.period;
        end

        self.count_limit = row.count;
    end
    self.consume = {}
    self.reward = {}

    if row.consume_type1 ~= 0 then
        if row.consume_need_reset1 == 0 then row.consume_need_reset1 = 1 end
        table.insert(self.consume, {type=row.consume_type1,id=row.consume_id1,value=row.consume_value1,need_reset=row.consume_need_reset1})
    end

    if row.consume_type2 ~= 0 then
        if row.consume_need_reset2 == 0 then row.consume_need_reset2 = 1 end
        table.insert(self.consume, {type=row.consume_type2,id=row.consume_id2,value=row.consume_value2,need_reset=row.consume_need_reset2})
    end

    for i = 1, 3 do
        if row["reward_type"..i] ~= 0 then
            local _type = row["reward_type"..i]
            local _id = row["reward_id"..i]
            local _value = row["reward_value"..i]
            local _item = utils.ItemHelper.Get(_type, _id)
            if _item then
                if  _type == utils.ItemHelper.TYPE.ITEM then
                    if _item.is_show ~= 0 then
                        table.insert(self.reward, {type = _type, id = _id, value = _value})
                    end
                else
                    table.insert(self.reward, {type = _type, id = _id, value = _value})
                end
            end
        end
    end
    self.raw = row;

    if self.auto_accept and self.depend.query == 0 then
        auto_accept_quest_list[self.id] = self;
    end
end

function QuestConfig:_getter_(k)
    return self.raw[k]
end
-- config --
local questConfig = nil;
local acceptSideQuestList = {}
local submitSideQuestList = {}
local questConfigByType = {};
local questConfigType = {};
local questConfigByGuideType = {};
local questConfigByMemory = {};
local function GetQuestConfig(id, stage)
    if questConfig == nil then
        questConfig = {}

        DATABASE.ForEach("advance_quest", function(row)
            local cfg_row = QuestConfig(row, true);
            --修改 建设 任务，交任务Npc
            local cfg = setmetatable({cfg = cfg_row}, {__index = function(t, k)
                if k ~= "npc_id" then
                    return cfg_row[k]  
                else  
                    --建设城市任务
                    if CityContuctId[1]==cfg_row.type or CityContuctId[2]==cfg_row.type or CityContuctId[3]==cfg_row.type or CityContuctId[4]==cfg_row.type then
                        
                        if cfg_row.npc_id ~= 0 then
                            return cfg_row.npc_id
                        --没有任务 交付Npc 找建设城市指定Npc    
                        else
                            local cityQuestFinishNpc = nil
                            local questOwenerCityType = _cityContuctInfo and _cityContuctInfo.current_city
                            if questOwenerCityType then
                                local ActivityConfig = require "config.activityConfig"
                                local _city_cfg =  ActivityConfig.GetCityConfig(nil,questOwenerCityType)
                                if _city_cfg and _city_cfg.donate_npc_id then
                                    cityQuestFinishNpc = _city_cfg.donate_npc_id
                                end
                            end
                            return cityQuestFinishNpc
                        end
                    else
                        return cfg_row.npc_id
                    end
                end
            end})
    
            if questConfig[cfg.id] == nil then
                if cfg.accept_npc_id and cfg.accept_npc_id ~= 0 then
                    npc_quest_list[cfg.accept_npc_id] = npc_quest_list[cfg.accept_npc_id] or {}
                    table.insert(npc_quest_list[cfg.accept_npc_id], cfg);
                end
                if cfg.npc_id and cfg.npc_id ~= 0 then
                    npc_submit_list[cfg.npc_id] = npc_submit_list[cfg.npc_id] or {}
                    table.insert(npc_submit_list[cfg.npc_id], cfg);
                end
                if cfg.mutex_id and cfg.mutex_id ~= 0 then
                    mutex_id_list[cfg.mutex_id] = mutex_id_list[cfg.mutex_id] or {}
                    table.insert(mutex_id_list[cfg.mutex_id], cfg);
                end
                if cfg.autoAcceptType == 4 or cfg.autoAcceptType == 5 or cfg.type == 20 then
                    table.insert(acceptSideQuestList, cfg);
                end
                if cfg.autoAcceptType == 5 or cfg.autoAcceptType == 8 then
                    table.insert(submitSideQuestList, cfg)
                end
                if cfg.type and cfg.type ~= 0 then
                    if questConfigType[cfg.type] == nil then questConfigType[cfg.type] = {} end
                    if cfg.type == 100 then
                        if questConfigByType[cfg.type] == nil then
                            questConfigByType[cfg.type] = {};
                        end
                        local day = tonumber(cfg.desc1);
                        if questConfigByType[cfg.type][day] == nil then
                            questConfigByType[cfg.type][day] = {};
                        end
                        if questConfigByType[cfg.type][day][cfg.day7_type] == nil then
                        questConfigByType[cfg.type][day][cfg.day7_type] = {};
                        end
                        table.insert(questConfigByType[cfg.type][day][cfg.day7_type], cfg);
                    end
                    table.insert(questConfigType[cfg.type], cfg)
                end
                if cfg.guide_type and cfg.guide_type ~= 0 then
                    if questConfigByGuideType[cfg.guide_type] == nil then
                        questConfigByGuideType[cfg.guide_type] = {};
                    end
                    table.insert(questConfigByGuideType[cfg.guide_type], cfg);
                end
                if cfg.memory_chapter and cfg.memory_chapter ~= 0 then
                    if questConfigByMemory[cfg.memory_chapter] == nil then
                        questConfigByMemory[cfg.memory_chapter] = {};
                    end
                    if questConfigByMemory[cfg.memory_chapter][cfg.memory_stage] == nil then
                        questConfigByMemory[cfg.memory_chapter][cfg.memory_stage] = {};
                    end
                    table.insert(questConfigByMemory[cfg.memory_chapter][cfg.memory_stage], cfg);
                end
                questConfig[cfg.id] = setmetatable({{}}, {__index = function(t, k)
                    return questConfig[cfg.id][1][k]
                end});
            end
            questConfig[cfg.id][cfg.stage] = cfg;
        end)
    end

    if stage then
        return questConfig[id][stage];
    end
    if id then
        return questConfig[id];
    end
    return questConfig;
end

local questChapter = nil
local questChapterGroup = nil
local function GetChapter(id)
    if not questChapter or not questChapterGroup then
        questChapter = {}
        questChapterGroup = {}
        DATABASE.ForEach("xiaobai_mainstory", function(row, idx)
            questChapter[row.quest_id] = row.group
            questChapterGroup[row.group] = questChapterGroup[row.group] or {}
            table.insert(questChapterGroup[row.group], row.quest_id)
        end)
    end
    if not id then
        return questChapterGroup
    end
    return questChapter[id]
end

local gotoWhereConfig = nil;
local function GetGoWhereConfig(gid)
    if gotoWhereConfig == nil then
        gotoWhereConfig = LoadDatabaseWithKey("7day_go_where", "gid");
    end
    return gotoWhereConfig[gid]
end

local quest_delayConfig = nil;
local function GetQuestDelayConfig(gid)
    if quest_delayConfig == nil then
        quest_delayConfig = LoadDatabaseWithKey("7day_delay", "quest_id");
    end
    return quest_delayConfig[gid]
end

local function GetRewardConfig(id)
    local cfg = GetQuestConfig(id);
    return cfg and cfg.reward;
end

local questSequenceCfg = nil
local function GetQuestSequenceCfg(questType)
    if not questSequenceCfg then
        questSequenceCfg = LoadDatabaseWithKey("quest_sequence", "quest_type")
    end
    return questSequenceCfg[questType]
end

local function GetQuestConfigByType(type,time,desc)
    GetQuestConfig()
    if desc then
        return questConfigByType[type][time][desc];
    end
    if time then
        return questConfigByType[type][time];
    end
    if type then
        return questConfigByType[type];
    end
end

local function GetQuestConfigByGuideType(type)
    GetQuestConfig()
    if type then
        return questConfigByGuideType[type];
    end
    return questConfigByGuideType;
end

local function GetQuestConfigByMemory(chapter, stage)
    GetQuestConfig()
    if stage then
        return questConfigByMemory[chapter][stage];
    end
    return questConfigByMemory[chapter];
end

local function CreateObject(name, pos)
    pos = pos or {}
    local prefab = SGK.ResourcesManager.Load(name)
    if not prefab then
        print("load prefab failed", name)
        return;
    end

    local o = UnityEngine.GameObject.Instantiate(prefab);
    o.transform.position = Vector3(pos[1] or 0, pos[2] or 0, pos[3] or 0);
end

local eventHandle = nil;

local function GetQuestEnv(quest)
    if not quest.script then
        return {}
    end

    if not quest._env then
        if quest.script == nil or quest.script == "" or quest.script == "0" or quest.script == 0 then
            quest._env = {};
            return quest._env;
        end

        local script = quest.script;

        if script == "guide/bounty/eventHandle.lua" then
            if eventHandle == nil then
                eventHandle = setmetatable({
                    CreateObject = CreateObject,
                    EnterMap = module.EncounterFightModule.GUIDE.EnterMap,
                    Interact = module.EncounterFightModule.GUIDE.Interact,
                    GetCurrentMapName = module.EncounterFightModule.GUIDE.GetCurrentMapName,
                    GetCurrentMapID = module.EncounterFightModule.GUIDE.GetCurrentMapID,
                }, {__index=_G, __newindex=function(t,k,v)
                    ERROR_LOG('canot set global in eventHandle.lua', k, debug.traceback());
                    rawset(t, k, v);
                end})

                assert(loadfile(script, 'bt', eventHandle))();
                -- setmetatable(eventHandle, nil);
            end

            quest._env = {
                OnEnterMap = eventHandle.OnEnterMap,
                Guide = eventHandle.Guide,
                OnAccept = eventHandle.OnAccept,
            }
        else
            local env = setmetatable({
                CreateObject = CreateObject,
                EnterMap = module.EncounterFightModule.GUIDE.EnterMap,
                Interact = module.EncounterFightModule.GUIDE.Interact,
                GetCurrentMapName = module.EncounterFightModule.GUIDE.GetCurrentMapName,
                GetCurrentMapID = module.EncounterFightModule.GUIDE.GetCurrentMapID,
            }, {__index=_G})

            ERROR_LOG("GetQuestEnv", quest.id, quest.name, quest.status)

            local func = loadfile(script, 'bt', env)
            if func then func(); end

            quest._env = env;
        end
    end

    return quest._env;
end

local function callQuestScript(quest, name, ...)
    local env = GetQuestEnv(quest);
    if rawget(env, name) then
        coroutine.resume(coroutine.create(env[name]), quest, ...);
        return true;
    end
end

local function startQuestScript(quest)
    if isNil(quest.script) then
        return ;
    end

    if quest.status ~= 0 then
        return ;
    end

    if quest.events then
        return;
    end

    local env = GetQuestEnv(quest);

    quest.events = {}

    if callQuestScript(quest, "OnEnterMap", SceneStack.MapId(), SceneStack.CurrentSceneName()) then
        quest.events["MAP_SCENE_READY"] = function(event, name)
            if quest.status == 0 then
                env.OnEnterMap(quest, SceneStack.MapId(), name);
            end
        end;
        utils.EventManager.getInstance():addListener("MAP_SCENE_READY", quest.events["MAP_SCENE_READY"]);
    end
end

local function cancelQusetScript(quest)
    if quest then
        for k, v in pairs(quest.events or {}) do
            utils.EventManager.getInstance():removeListener(k, v);
        end
        quest.events = nil
    end
end

local function doQuestAcceptScrpt(quest)
    callQuestScript(quest, "OnAccept");
end

local function startQuestGuideScript(quest, acceptable)
    local teamInfo = module.TeamModule.GetTeamInfo();
    if not (teamInfo.group == 0 or module.playerModule.Get().id == teamInfo.leader.pid) then
        showDlgError(nil,"你正在队伍中，无法进行该操作")
        return
    end
    if quest.status == 0 or acceptable == true then
        for i = 1, 2 do
            if quest.condition then
                if quest.condition[i].type == 1 then
                    if quest.condition[i].id == 1 then
                        if module.HeroModule.GetManager():Get(11000).level < quest.condition[i].count then
                            if quest.type == 10 then
                                LoadStory(tonumber(tostring(quest.id).."1"), function()
                                    utils.MapHelper.OpSelectMap()
                                end)
                                return
                            else
                                showDlgError(nil, "等级不足")
                                return
                            end
                        end
                    end
                end
            end
        end
        coroutine.resume(coroutine.create(function()
            callQuestScript(quest, "Guide")
        end));
    end
end

-- quest --
local Quest = utils.class()

local function addGiveItem(quest, needTip)
    if quest.cfg and quest.cfg.give_id and quest.cfg.give_id ~= 0 and quest.cfg.give_value and quest.cfg.give_value ~= 0 then
        if quest.status == 0 then
            if module.ItemModule.GetItemCount(quest.cfg.give_id) == 0 then
                module.ItemModule.UpItemData({quest.cfg.give_id, quest.cfg.give_value, quest.uuid}, needTip)
            end
        end
    end
end

local function RemoveQuestItem(quest)
    if quest and quest.status ~= 0 and quest.cfg.give_id and quest.cfg.give_id ~= 0 and quest.cfg.give_value and quest.cfg.give_value ~= 0 then
        if module.ItemModule.GetItemCount(quest.cfg.give_id) > 0 then
            module.ItemModule.RemoveQuestItem(quest.cfg.give_id)
        end
    end
end

function Quest:Init(data, register)
    local cfg = GetQuestConfig(data[2]);
    if not cfg then
        return nil;
    end

    self.uuid   = data[1];
    self.id     = data[2];
    self.status = data[3];
    self.records = {data[4], data[5]}
    self.finishCount = data[6]
    self.accept_time = data[9]
    self.finish_time = data[10]
    self.cfg = cfg;
    self.stageFlag = 1;
    if data[11] then
        for i=1,30 do
            if (data[11] & (1 << (i - 1))) == 0 then
                if self.cfg[i] then
                    self.stageFlag = i;
                elseif i ~= 1 then
                    self.stageFlag = i - 1;
                end
                break;
            end
        end
    end
    self.reward = GetRewardConfig(self.id) or {}
    cancelQusetScript(self);
    addGiveItem(self, register)
    --startQuestGuideScript(self);
    -- print("Quset:Init", self.uuid, self.id, self.cfg.name, self.status);
    return self;
end

function Quest:_getter_(k)
    return self.cfg[self.stageFlag][k];
end

-- quest list --
local quest_list = nil;
local waiting_thread = {};
local quest_by_type_and_status_cache = {};

local function QueryQuestList(first)
    utils.NetworkService.Send(76, {nil, 1})
    if first then
        if coroutine.isyieldable() and waiting_thread then
            waiting_thread[#waiting_thread+1] = coroutine.running();
            return coroutine.yield();
        end
    end
end

local function GetQuestList(type, status)
    local already_have_data = true;
    if quest_list == nil then
        quest_list = {}
        quest_by_type_and_status_cache = {}
        utils.NetworkService.Send(76, {nil, 1})
    end

    if not type and not status then
        return quest_list
    end

    local cache_status = status or -1;
    local cache_type = type or -1;
    if not quest_by_type_and_status_cache[cache_type] then
        quest_by_type_and_status_cache[cache_type] = {}
    end

    if quest_by_type_and_status_cache[cache_type][cache_status] then
        return quest_by_type_and_status_cache[cache_type][cache_status];
    end

    local list = {};

    for _, quest in pairs(quest_list) do
        if type == nil or quest.type == type then
            if status == nil or quest.status == status then
                table.insert(list, quest);
            end
        end
    end

    quest_by_type_and_status_cache[cache_type][cache_status] = list;

    return list;
end

local function GetQuest(uuid)
    return GetQuestList()[uuid];
end

local _questNs = {}
local _quest_update_status_info = {};
local function CheckQuestServerRequestStatus(uuid)
    if _quest_update_status_info[uuid] and os.time() - _quest_update_status_info[uuid].time < 3 then
        --print('quest waiting for server respond', uuid);
        return false;
    end
    return true;
end

local function RecordQuestServerRequestStatus(uuid, sn)
    _questNs[sn] = uuid;
    if coroutine.isyieldable() then
        _quest_update_status_info[uuid] = { time = os.time(), co = coroutine.running() }
        return coroutine.yield();
    else
        _quest_update_status_info[uuid] = { time = os.time() }
    end
end

local function CleanQuestServerRequestStatus(sn, result)
    local uuid = _questNs[sn]
    if not uuid then
        return;
    end

    _questNs[sn] = nil;

    local info = _quest_update_status_info[uuid]
    _quest_update_status_info[uuid] = nil;

    if info and info.co then
        assert(coroutine.resume(info.co, result == 0));
    end
end

local function SetQuestStatus(uuid, status, nextId, stage)
    -- print("设置任务状态", uuid, status, nextId, stage, debug.traceback())
    stage = stage or 0;
    local quest = GetQuest(uuid)
    if quest == nil and status ~= 0 then
        return false;
    end

    if quest and quest.uuid < 0 then
        quest:SetStatus(status);
    else
        if not CheckQuestServerRequestStatus(uuid) then
            return false;
        end
        local _sn = utils.NetworkService.Send(78, {nil, uuid, status, nextId, stage})
        RecordQuestServerRequestStatus(uuid, _sn);
        return true
    end
end

local quest_index = 0;
local function RegisterQuest(quest)
    -- ERROR_LOG("RegisterQuest", debug.traceback())

    quest_list = quest_list or {}
    quest_by_type_and_status_cache = {}

    local doAccept = false;

    if not quest.uuid then
        quest_index = quest_index - 1;
        quest.uuid = quest_index
        quest.id = quest_index
        doAccept = true;
    end

    quest_list[quest.uuid] = quest

    if quest.status == 0 then
        startQuestScript(quest);
    end

    if doAccept and quest.status == 0 then
        doQuestAcceptScrpt(quest);
    end
    --startQuestGuideScript(quest);
    if not quest.accept_time then
        quest.accept_time = module.Time.now()
    end
    if quest.is_show_on_task then
        utils.EventManager.getInstance():dispatch("QUEST_LIST_CHANGE", quest);
    end

    utils.EventManager.getInstance():dispatch("QUEST_INFO_CHANGE");

    return quest.uuid;
end

local function RemoveQuest(uuid)
    --ERROR_LOG(uuid..debug.traceback())
    if uuid < 0 then
        local quest = quest_list[uuid];
        if quest and quest.bountyType then --试炼任务
            module.BountyModule.Cancel(quest.bountyType)
        end
        quest_list[uuid] = nil;
        quest_by_type_and_status_cache = {}
        cancelQusetScript(quest);
        RemoveQuestItem(quest)
        utils.EventManager.getInstance():dispatch("QUEST_INFO_CHANGE");
    end
end

local SnArr = {}
local function CityContuctAcceptQuest(type)
    ERROR_LOG('CityContuctAcceptQuest', type, debug.traceback())
    local sn = utils.NetworkService.Send(11041, {nil, type});
    SnArr[sn] = type
end


local function CityContuctCancelQuest(uuid)
    if not CheckQuestServerRequestStatus(uuid or "city_contruct") then
        return;
    end

    local sn = utils.NetworkService.Send(11043, {nil, uuid});
    RecordQuestServerRequestStatus(uuid or "city_contruct", sn);
end

local function CityContuctSubmitQuest(uuid)
    if not CheckQuestServerRequestStatus(uuid or "city_contruct") then
        return;
    end

    local sn = utils.NetworkService.Send(11045, {nil, uuid});

    RecordQuestServerRequestStatus(uuid or "city_contruct", sn);
end

local function CanAcceptQuest(id, showError)
    local cfg = GetQuestConfig(id);
    if not cfg then
        if showError then  showDlgError(nil, "任务不存在");  end
        return;
    end

    if cfg.type == 1 then
        return true;
    end

    -- print("任务信息", sprinttb(cfg))
    if cfg.depend.quest ~= 0 then
        local dq = GetQuest(cfg.depend.quest);
        if dq == nil or dq.status ~= 1 then
            if showError then  showDlgError(nil, "前置任务未完成");  end
            return;
        end
    end

    if cfg.depend.fight ~= 0 then
        local info = module.fightModule.GetFightInfo(cfg.depend.fight)
        if not info or not info:IsPassed() then
            if showError then  showDlgError(nil, "依赖副本未完成");  end
            return;
        end
    end

    if cfg.mode~=0 and not utils.SGKTools.CheckPlayerMode(cfg.mode) then
        if showError then  showDlgError(nil, "形象不符合任务要求") end
        return false
    end

    if cfg.mutex_id~=0 and mutex_id_list[cfg.mutex_id] and mutex_id_list[cfg.mutex_id] ~= {} then--互斥任务不可重复领取
        local _reject=false
        for i=1,#mutex_id_list[cfg.mutex_id] do
            local _id=mutex_id_list[cfg.mutex_id][i].id
            local quest = GetQuest(_id);
            if quest and quest.status == 0 then
                _reject=true
                break
            end
        end
        if _reject then
            if showError then  showDlgError(nil, "任务已领取");  end
            return false;
        end
    end

    if module.HeroModule.GetManager():Get(11000) and module.HeroModule.GetManager():Get(11000).level < cfg.depend.level then
        if showError then  showDlgError(nil, "未达到任务领取等级");  end
        return false;
    end

    local function IsAcceptConsume(flag)
        flag = flag or 0;
        return (flag & 0x24) ~= 0
    end

    for _, consume in ipairs(cfg.consume) do
        if consume.type ~= 0 and IsAcceptConsume(consume.need_reset) then
            local item = utils.ItemHelper.Get(consume.type, consume.id);
            if item.count < consume.value then
                if showError then showDlgError(nil, item.name .. '数量不足'); end
                return false;
            end
        end
    end

    local quest = GetQuest(id);

    if quest and cfg.count_limit ~= 0 and quest.finishCount >= cfg.count_limit then
        if showError then  showDlgError(nil, cfg.count_limit == 1 and "任务已经完成" or "任务已经达到最大可完成次数");  end
        return false;
    end

    if cfg.begin_time > 0 and cfg.end_time > 0 and cfg.period > 0 then
        local begin_time, end_time = cfg.begin_time, cfg.end_time;
        if cfg.relative_to_born == 1 then
            begin_time = module.playerModule.GetCreateTime() + ((cfg.begin_time - 1) * 86400)
            end_time = module.playerModule.GetCreateTime() + ((cfg.end_time - 1) * 86400) - 1
        end
    
        local period, duration = cfg.period, cfg.duration;
        local now = module.Time.now();
        if now < begin_time then
            if showError then  showDlgError(nil, "任务还未开启");  end
            return false
        end

        if now >= end_time then
            if showError then  showDlgError(nil, "任务已结束");  end
            return false
        end

        if period ~= 0 then
            local period_count = math.floor((now - begin_time) / period);
            local start_time = begin_time+period_count * period;      
            if now - start_time >= duration then
                if showError then  showDlgError(nil, "任务不在开启时间内");  end
                return false
            end
        end
    end


    ---判断是否需要刷新
    if quest and cfg.begin_time >= 0 and cfg.end_time >= 0 and cfg.period >= 0 and cfg.relative_to_born == 0 then
        local total_pass = module.Time.now() - cfg.begin_time
        local period_pass = total_pass - math.floor(total_pass / cfg.period) * cfg.period
        local period_begin = module.Time.now() - period_pass;
        if quest.accept_time < period_begin then
            return true
        end
    end

    ---开服任务 判断是否在开服任务活动时间中
    ---relative_to_born为1的
    --[[
    if cfg.type == 100 or cfg.type == 97 or cfg.relative_to_born == 1 then
        local _beginTime = module.playerModule.GetCreateTime() + ((cfg.begin_time - 1) * 86400)
        local _endTime = module.playerModule.GetCreateTime() + ((cfg.end_time - 1) * 86400) - 1

        local now = module.Time.now();
        if (now < _beginTime) or (now >= _endTime) then
            if showError then  showDlgError(nil, "任务不在开启时间内");  end
            return false
        end
    end
    --]]

    --庄园任务
    if cfg.type == 14 or cfg.type == 23 then
        if not module.ManorRandomQuestNPCModule.QuestAcceptable(cfg.id) then
            return false;
        end
    end

    if quest and quest.status == 0 then
        if showError then  showDlgError(nil, "任务已领取");  end
        return false;
    end
    return true;
end

local function IsSumitConsume(flag)
    return (flag == nil) or (flag == 0) or ((flag&0x41) ~= 0)
end

local function GetQuestEndTime(quest)
    local _endTime = 0;
    if quest.relative_to_born == 1 then
        _endTime = module.playerModule.GetCreateTime() + ((quest.end_time - 1) * 86400) - 1;
    else
        local total_pass = module.Time.now() - quest.time.from;
        local period_pass = total_pass % quest.time.period;
        local period_end = module.Time.now() - period_pass + quest.time.duration;
        _endTime = math.min(period_end, quest.time.to);
    end
    return _endTime;
end

local function CanSubmitQuest(uuid, showError)
    local quest = GetQuest(uuid);
    if not quest then
        --print('quest', uuid, "not exists");
        if showError then
            showDlgError(nil, "任务不存在");
        end
        return;
    end

    if quest.status and quest.status ~= 0 then
        if showError then
            showDlgError(nil, "任务不处于已接未完成状态");
        end
        return false, 6;
    end

    for i, _ in ipairs(quest.condition or {}) do
        if quest.condition[i].type == 1 then
            if quest.condition[i].id == 1 then
                local level = module.HeroModule.GetManager():Get(11000).level;
                if level < quest.condition[i].count then
                    if showError then
                        showDlgError(nil, "没有达到完成任务所需等级");
                    end
                    return false, 1, level, i;
                end
            end
        elseif quest.condition[i].type == 34 then --拥有角色X个
            local _endTime = GetQuestEndTime(quest);
            if quest.condition[i].id == 1 then
                local count = module.HeroModule.GetHeroCount(_endTime);
                if count < quest.condition[i].count then
                    if showError then
                        showDlgError(nil, "角色数量不足");
                    end
                    return false, 3, count, i;
                end
            end
        elseif quest.condition[i].type == 37 then --拥有护符装备
            local _endTime = GetQuestEndTime(quest);
            if quest.condition[i].id == 1 then  --护符
                local count = module.equipmentModule.EquipCount(_endTime);
                if count < quest.condition[i].count then
                    if showError then
                        showDlgError(nil, "护符数量不足");
                    end
                    return false, 4, count, i;
                end
            elseif quest.condition[i].id == 2 then --铭文
                local count = module.equipmentModule.InscripCount(_endTime);
                if count < quest.condition[i].count then
                    if showError then
                        showDlgError(nil, "铭文数量不足");
                    end
                    return false, 5, count, i;
                end
            end
        elseif (quest.condition[i].type == 2 or quest.condition[i].type == 3) and quest.condition[i].count > quest.records[i] then --type  为 2 和 3 则需要战斗
            if showError then
                showDlgError(nil, "任务所需战斗未完成");
            end
            return false, 2, quest.records[i], i;
        elseif quest.condition[i].type == 60 then   --在线时长任务
            local _time = module.playerModule.Get().loginTime
            if quest.records[i] == 0 then
                _time = quest.accept_time
            end
            local needTime = _time + (quest.condition[i].count - quest.records[i]) - module.Time.now();
            if needTime > 0 then
                if showError then
                    showDlgError(nil, "未到时间");
                end
                return false, 8, needTime, i;
            end
        elseif quest.condition[i].type == 65 then  --主角穿戴某种品质的护符(装备)X个
            local _count = module.EquipHelp.GetQualityCount(11000, 0, quest.condition[i].id)
            if _count < quest.condition[i].count then
                if showError then
                   showDlgError(nil, "主角穿戴某种品质的护符不足");
                end
                return false, 9, _count, i;
            end
        elseif quest.condition[i].type == 66 then  --主角穿戴某种品质的铭文(守护)X个
            local _count = module.EquipHelp.GetQualityCount(11000, 1, quest.condition[i].id)
            if _count < quest.condition[i].count then
                if showError then
                   showDlgError(nil, "主角穿戴某种品质的铭文不足");
                end
                return false, 10, _count, i;
            end
        elseif quest.condition[i].type == 68 then  --穿了几件套装
            if quest.condition[i].id ~= 0 then
                local _count = module.EquipHelp.GetSuitCount(quest.condition[i].id, 0)
                local _flag = false
                for k,v in pairs(_count) do
                    if v >= quest.condition[i].count then
                        _flag = true
                        break
                    end
                end
                if not _flag then
                    if showError then
                       showDlgError(nil, "穿戴几件套装");
                    end
                    return false, 11, _count, i;
                end
            end
        elseif quest.condition[i].type == 62 then --拥有某个等级的英雄X个
            local _endTime = GetQuestEndTime(quest);
            local count = module.HeroModule.GetHeroCount(_endTime, quest.condition[i].id);
            if count < quest.condition[i].count then
                if showError then
                    showDlgError(nil, "角色数量不足");
                end
                return false, 12, count, i;
            end
        elseif quest.condition[i].type == 63 then --拥有某个品质护符(装备)X个
            local _endTime = GetQuestEndTime(quest);
            local count = module.equipmentModule.EquipCount(_endTime, quest.condition[i].id);
            if count < quest.condition[i].count then
                if showError then
                    showDlgError(nil, "护符数量不足");
                end
                return false, 13, count, i;
            end
        elseif quest.condition[i].type == 64 then --拥有某个品质铭文(守护)X个
            local _endTime = GetQuestEndTime(quest);
            local count = module.equipmentModule.InscripCount(_endTime, quest.condition[i].id);
            if count < quest.condition[i].count then
                if showError then
                    showDlgError(nil, "铭文数量不足");
                end
                return false, 14, count, i;
            end
        elseif quest.condition[i].type == 71 then --拥有道具X个
            local _count = module.ItemModule.GetItemCount(quest.condition[i].id)
            if _count < quest.condition[i].count then
                if showError then
                    showDlgError(nil, "道具数量不足");
                end
                return false, 15, _count, i;
            end
        elseif quest.condition[i].type == 72 then --阶数X
            local _hero = module.HeroModule.GetManager():Get(quest.condition[i].id)
            if _hero then
                if _hero.stage < quest.condition[i].count then
                    if showError then
                        showDlgError(nil, "阶数不足");
                    end
                    return false, 16, _hero.stage, i;
                end
            else
                return false, 16;
            end
        elseif quest.condition[i].type == 74 then --武器星数
            local _hero = module.HeroModule.GetManager():Get(quest.condition[i].id)
            if _hero then
                if _hero.star < quest.condition[i].count then
                    if showError then
                        showDlgError(nil, "武器星数不足");
                    end
                    return false, 17, _hero.star, i;
                end
            else
                return false, 17
            end
        elseif quest.condition[i].type == 81 then --X个角色加了Y个技能点的任务
            local _heroList = module.HeroModule.GetManager():GetAll()
            local _count = 0
            for k,v in pairs(_heroList or {}) do
                if module.HeroHelper.GetTalentCount(v.id) >= quest.condition[i].id then
                    _count = _count + 1
                end
            end
            if _count < quest.condition[i].count then
                return false, 18, _count, i;
            end
        elseif quest.condition[i].type == 82 then --X护符进阶Y阶的任务
            local _count = module.EquipHelp.GetAdvCount(quest.condition[i].id)
            if _count < quest.condition[i].count then
                if showError then
                    showDlgError(nil, "数量不足")
                end
                return false, 19, _count, i;
            end
        elseif quest.condition[i].type == 83 then --拥有Y件套套装效果数量X
            local _heroList = module.HeroModule.GetManager():GetAll()
            local _count = 0
            for p,v in pairs(_heroList) do
                local _suit = module.HeroModule.GetManager():GetEquipSuit(v.id)
                if _suit and _suit[0] then
                    for k,v in pairs(_suit[0]) do
                        if #v.IdxList >= quest.condition[i].id then
                            _count = _count + 1
                            break
                        end
                    end
                end
            end
            if _count < quest.condition[i].count then
                return false, 20, _count, i;
            end
        elseif quest.condition[i].type == 91 then
            local _list = utils.ItemHelper.GetList(utils.ItemHelper.TYPE.ITEM, quest.condition[i].id)
            local _count = 0
            for i,v in ipairs(_list) do
                _count = _count + module.ItemModule.GetItemCount(v.id)
            end
            if _count < quest.condition[i].count then
                return false, 21, _count, i;
            end
        elseif quest.condition[i].type == 98 then
            local _info = module.fightModule.GetFightInfo(quest.condition[i].id)
            local _count = 0
            if _info then
                for i = 1, 3 do
                    if module.fightModule.GetOpenStar(_info.star, i) ~= 0 then
                        _count = _count + 1
                    end
                end
            end
            if _count < quest.condition[i].count then
                return false, 22, _count, i;
            end
        elseif quest.condition[i].type == 100 then
            local _info = module.fightModule.GetFightInfo(quest.condition[i].id)
            if not _info:IsPassed() then
                return false, 23, 0, i;
            end
        elseif quest.condition[i].type == 101 then
            local starPoint = module.playerModule.Get().starPoint or 0;
            if starPoint < quest.condition[i].count then
                if showError then
                   showDlgError(nil, "任务所需未完成");
                end
                return false, 24, starPoint, i;
            end
        elseif quest.condition[i].type == 102 then --装备升级次数
            local _endTime = GetQuestEndTime(quest)
            local count = module.equipmentModule.EquipLevelCount(_endTime, quest.condition[i].id);
            if count < quest.condition[i].count then
                if showError then
                    showDlgError(nil, "装备升级数不足");
                end
                return false, 25, count, i;
            end
        elseif quest.condition[i].type == 110 then --特定角色达到多少级
            local manager = module.HeroModule.GetManager()
            local hero = manager:Get(quest.condition[i].id) or {level = -1}
            if hero.level < quest.condition[i].count then
                if showError then
                    local cfg = module.HeroModule.GetConfig(quest.condition[i].id);
                    showDlgError(nil, string.format("%s等级没有达到%d", cfg and cfg.name or '角色', quest.condition[i].count));
                end
                return false, 26, hero.level, i;
            end
        elseif quest.condition[i].type == 112 then  --完成某个任务
            local quest = GetQuest(quest.condition[i].id);
            if quest == nil or quest.status ~= 1 then
                if showError then
                    showDlgError(nil, "任务未完成");
                end
                return false, 27, 0, i;
            end
        elseif quest.condition[i].count > quest.records[i] then
            if showError then
               showDlgError(nil, "任务所需未完成");
            end
            return false, 7, quest.records[i], i;
        end
    end

    for _, consume in ipairs(quest.consume or {}) do
        if consume.type ~= 0 and IsSumitConsume(consume.need_reset) then
            local item = utils.ItemHelper.Get(consume.type, consume.id) or {count = 0}
            if item.count < consume.value then
                if showError then
                    print("item", item.name, "not enough");
                    showDlgError(nil, item.name .. '数量不足');
                end
                return false, 3;
            end
        end
    end

    return true;
end

local function GetQuestSubmitItemList(uuid)
    local quest = GetQuestConfig(uuid)
    local list = {}
    for _, consume in ipairs(quest.consume) do
        if consume.type ~= 0 and IsSumitConsume(consume.need_reset) then
            print("---------------",consume.need_reset)
            table.insert(list, consume)
        end
    end

    if #list > 0 then
        return list;
    end
end

local function AcceptQuest(id)
    if not CanAcceptQuest(id) then
        --print("quest can't accept")
        return;
    end
    -- print("接任务", id);
    return SetQuestStatus(id, 0);
end

---登录成功接取注册日常活动任务
local function AcceptActivityQuest()
    local _count = 0
    if not questConfig then
        GetQuestConfig(1)
    end
    for k,v in pairs(questConfig) do
        --[[
        if v.type == 20 or v.type == 100 or v.type == 30 then
            if AcceptQuest(v.id) then
                _count = _count + 1
            end
        end
        --]]
    end
    return _count
end

local function FinishQuest(uuid, data, stage)
    local quest = GetQuest(uuid);
    if not quest then
        --print('quest', uuid, "not exists");
        return;
    end

    stage = stage or quest.stageFlag
    -- if data and data.nextId then
    --     AutoAcceptNextIdList[uuid] = data.nextId
    -- end

    for i,v in ipairs(CityContuctId) do
        if quest.type == v then
            return CityContuctSubmitQuest(uuid);
        end
    end

    if not CanSubmitQuest(uuid) then
        local case1,case2=CanSubmitQuest(uuid)
        --print("quest can't submit",case2);
        return;
    end
    data = data or {nextId = 0}
    -- print("完成任务", uuid, debug.traceback());
    --任务栏可见的任务增加奖励确认弹窗
    if quest.is_show_on_task and quest.is_show_on_task == 0 and quest.reward and next(quest.reward) then
        utils.SGKTools.ShowTaskItem(quest,function ()
            if quest.reward and next(quest.reward) then
                local _tab = {}
                for i=1,#quest.reward do
                    table.insert(_tab,{quest.reward[i].type,quest.reward[i].id,quest.reward[i].value})
                end
                DispatchEvent("ADD_FILTER_REWARDS",_tab)
            end
            SetQuestStatus(uuid, 1, data.nextId, stage)
        end)
    else
        SetQuestStatus(uuid, 1, data.nextId, stage)
    end
end

local BountyId = 2
local function CancelQuest(uuid)
    if uuid == nil or type(uuid) ~= "number" then
        ERROR_LOG('remove quest failed, uuid is nil')
        return;
    end
    if uuid < 0 then
        RemoveQuest(uuid)
    else
        local quest = quest_list[uuid]
        for i,v in ipairs(CityContuctId) do
            if quest and quest.type == v then
                return CityContuctCancelQuest(uuid);
            end
        end
        if quest and quest.type == BountyId then
            return module.BountyModule.Cancel()
        end
        SetQuestStatus(uuid, 2);
    end
end

local function SendSevenDayEmail(addEmail)
    local TipCfg = require "config.TipConfig"
    for day,v in pairs(addEmail) do
        local list = {};
        -- list.id = "sevenDay"..day;
        -- list.type = 101;
        list.title = TipCfg.GetAssistDescConfig(61005).info;
        list.status = 2;
        list.time = module.playerModule.GetCreateTime() + ((v[1].end_time - 1) * 86400)
        list.attachment_count = 1;
        list.attachment_opened = 0;
        local reward = {}
        for _,questCfg in ipairs(v) do
            local quest = GetQuest(questCfg.id);
            -- local _reward = GetRewardConfig(questCfg.id);
            -- ERROR_LOG("奖励", sprinttb(quest.reward))
            for _,item in ipairs(quest.reward) do
                if reward[item.id] then
                    reward[item.id].value = reward[item.id].value + item.value;
                else
                    reward[item.id] = {};
                    reward[item.id].type = item.type;
                    reward[item.id].id = item.id;
                    reward[item.id].value = item.value;
                end
            end
        end
        local items = {};
        items.content = TipCfg.GetAssistDescConfig(61005 + day).info;
        items.id = 0;
        items.item = {};
        for _,item in pairs(reward) do
            local info = {};
            info[1] = item.type;
            info[2] = item.id;
            info[3] = item.value;
            table.insert(items.item, info);
        end
        list.content = items;
        list.fun = function (id,type,data)
            if type == 1 then --打开邮件

            elseif type == 2 then --领取邮件
                for _,questCfg in ipairs(v) do
                    print("完成任务",questCfg.id, questCfg.name)
                    FinishQuest(questCfg.id);
                end
                module.MailModule.SetAttachment_opened(id,1);
            elseif type == 3 then --删除邮件
                for _,questCfg in ipairs(v) do
                    local quest = GetQuest(questCfg.id);
                    if quest and quest.status == 0 then
                        print(quest.name.."未完成")
                        return;
                    end
                end
                module.MailModule.DelMail(id)
            end
        end
        -- for _,questCfg in ipairs(v) do
        --     ERROR_LOG("可完成", questCfg.id, questCfg.name)
        -- end
        -- ERROR_LOG("添加邮件", sprinttb(list))
        -- module.MailModule.SetManager(list, true);
    end
end

local checkDelayQuest = false;
local function GetSevenDayOpen()
    local allQuest = GetQuestConfigByType(100);
    if checkDelayQuest then
        for i,v in ipairs(allQuest or {}) do
            for _,j in pairs(v) do
                for _,k in ipairs(j) do
                    local _endTime = module.playerModule.GetCreateTime() + ((k.end_time - 1) * 86400) - 1
                    if module.Time.now() > _endTime then
                        -- ERROR_LOG("超时", k.end_time, module.playerModule.GetCreateTime(), module.Time.now(), _endTime)
                        return false;
                    else
                        return true;
                    end
                end
            end
        end
    else
        checkDelayQuest = true;
        local isopen = true;
        local addEmail = {};
        for day,v in ipairs(allQuest or {}) do
            for _,j in pairs(v) do
                for _,k in ipairs(j) do
                    local _endTime = module.playerModule.GetCreateTime() + ((k.end_time - 1) * 86400) - 1
                    if module.Time.now() > _endTime then
                        local delay_config = GetQuestDelayConfig(k.id);
                        if delay_config and module.Time.now() < _endTime + delay_config.delay_time then
                            local quest = GetQuest(k.id);
                            if quest and quest.status == 0 and quest.consume_id1 == 0 then
                                local submit = CanSubmitQuest(k.id);
                                if submit then
                                    -- ERROR_LOG(k.name.."可以延时提交");
                                    -- FinishQuest(k.id);
                                    if addEmail[day] == nil then
                                        addEmail[day] = {};
                                    end
                                    table.insert(addEmail[day], k);
                                -- else
                                --     ERROR_LOG(k.name.."未完成");
                                end
                            -- elseif quest == nil then
                            --     ERROR_LOG(k.name.."不存在");
                            -- elseif quest.status ~= 0 then
                            --     ERROR_LOG(k.name.."已完成");
                            end
                        end
                        if isopen then
                            isopen = false;
                        end
                    end
                end
            end
        end
        SendSevenDayEmail(addEmail)
        return isopen;
    end
end

local OldUuid = nil
local function GetOldUuid()
    return OldUuid
end
local function SetOldUuid(Uuid)
    OldUuid = Uuid
end

local NpcStatus = {
    Finish   = 1, --可完成
    Accept   = 2, --可接
    UnAccept = 3, --不可交
}

local NpcStatusSortIndex = {
    [5] = 1,
    [1] = 2,
    [2] = 3,
    [8] = 4,
    [7] = 5,
    [3] = 6,
    [4] = 7,
    [10] = 8,
    [11] = 9,
}

local function getNpcStatus(npcId, func)
    GetQuestConfig(0)

    if not quest_list then
        table.insert(npc_status_funcList, {npcId = npcId, func = func})
        return nil
    end

    local list = npc_quest_list[npcId] or {}
    local _subList = npc_submit_list[npcId] or {}

    local _acceptTab = {}
    local _subTab = {}
    local _unSubTab = {}
    for i,v in ipairs(list) do
        if CanAcceptQuest(v.id) then
            table.insert(_acceptTab, v)
        end
    end

    for i,v in ipairs(_subList) do
        if CanSubmitQuest(v.id) then
            table.insert(_subTab, v)
        elseif GetQuest(v.id) and GetQuest(v.id).status == 0 then
            table.insert(_unSubTab, v)
        end
    end

    if #_subTab >= 1 then
        table.sort(_subTab, function(a, b)
            return (NpcStatusSortIndex[a.type] or 1) > (NpcStatusSortIndex[b.type] or 1)
        end)
        if func then
            func(NpcStatus.Finish, _subTab[1].is_show_on_task)
            return
        end
        return {status = NpcStatus.Finish, type = _subTab[1].is_show_on_task}
    end

    if #_acceptTab >= 1 then
        table.sort(_acceptTab, function(a, b)
            return (NpcStatusSortIndex[a.type] or 1) > (NpcStatusSortIndex[b.type] or 1)
        end)
        if func then
            func(NpcStatus.Accept, _acceptTab[1].is_show_on_task)
            return
        end
        return {stauts =  NpcStatus.Accept, type = _acceptTab[1].is_show_on_task}
    end

    if #_unSubTab >= 1 then
        table.sort(_unSubTab, function(a, b)
            return (NpcStatusSortIndex[a.type] or 1) > (NpcStatusSortIndex[b.type] or 1)
        end)
        if func then
            func(NpcStatus.UnAccept, _unSubTab[1].is_show_on_task)
            return
        end
        return {stauts =  NpcStatus.UnAccept, type = _unSubTab[1].is_show_on_task}
    end
    func()
    return nil
end

local function notifyNpcStatusChange()
    for i,v in ipairs(npc_status_funcList) do
        if v.npcId and v.func then
            getNpcStatus(v.npcId, v.func)
        end
    end
    npc_status_funcList = {}
end

local otherQuestTab = {}
local function UpdateOtherQuest(data,pid)
    if data and pid then
        local uuid   = data[1];
        local id     = data[2];
        local status = data[3];
        local records = {data[4], data[5]}
        local finishCount = data[6]
        local accept_time = data[9]
        local finish_time = data[10]

        otherQuestTab[pid] = otherQuestTab[pid] or {}
        otherQuestTab[pid][id] = otherQuestTab[pid][id] or {}
       
        otherQuestTab[pid][id].uuid = uuid
        otherQuestTab[pid][id].id = id
        otherQuestTab[pid][id].status = status;
        otherQuestTab[pid][id].records = records
        otherQuestTab[pid][id].finishCount = finishCount
        otherQuestTab[pid][id].accept_time = accept_time
        otherQuestTab[pid][id].finish_time = finish_time

        otherQuestTab[pid][id].lastQueryTime = module.Time.now()
    end
end

-- network event --
utils.EventManager.getInstance():addListener("server_respond_77", function(event, cmd, data)
    if data[2] ~= 0 then
        --print("query quest failed", data[2])

        local _last_waiting_thread = waiting_thread or {};
        waiting_thread = nil;
        for _, co in ipairs(_last_waiting_thread) do
            coroutine.resume(co, {});
        end
        return;
    end
    local sn = data[1]
    if SnArr[sn] then
        -- ERROR_LOG("server_respond_77",sprinttb(data))
        if data[3] and next(data[3])~=nil then
            UpdateOtherQuest(data[3][1],SnArr[sn].pid)
            if SnArr[sn].func then
               SnArr[sn].func() 
            else
                DispatchEvent("COOPERAQUEST_INFO_CHANGE",{SnArr[sn].quest_id,module.playerModule.GetSelfID()})
            end
        end
        SnArr[sn] = nil
    else
        quest_list = quest_list or {}
        quest_by_type_and_status_cache = {}

        for k, v in pairs(quest_list) do
            if k > 0 then
                quest_list[k] = nil;
            end
        end
        for _, v in ipairs(data[3]) do
            local quest = Quest():Init(v);
            if quest then
                quest_list[quest.uuid] = quest;
                if quest.status == 0 then
                    startQuestScript(quest)
                end
            end
        end

        notifyNpcStatusChange()
        utils.EventManager.getInstance():dispatch("QUEST_INFO_CHANGE");

        local _last_waiting_thread = waiting_thread;
        waiting_thread = nil;

        for _, co in ipairs(_last_waiting_thread or {}) do
            coroutine.resume(co, quest_list);
        end
    end
end);

utils.EventManager.getInstance():addListener("server_respond_79", function(event, cmd, data)
    local sn, result = data[1], data[2];

    CleanQuestServerRequestStatus(sn, result);
end)


local have_quest_change = false;
utils.EventManager.getInstance():addListener("server_notify_56", function(event, cmd, data)
    -- print("server_notify_56", unpack(data));
    local uuid = data[1];

    quest_list = quest_list or {};
    quest_by_type_and_status_cache = {}

    local oldStatus = quest_list[uuid] and quest_list[uuid].status;

    local quest = quest_list[uuid] or Quest();
    if not quest:Init(data, true) then
        return;
    end

    if quest.id == 0 then
        quest_list[uuid] = nil;
    else
        quest_list[uuid] = quest;
        startQuestScript(quest);
    end

    if quest.status == 0 and oldStatus ~= quest.status then
        doQuestAcceptScrpt(quest);
    end

    RemoveQuestItem(quest)

    if quest.status == 1 and quest.is_show_on_task == 0 then
        --utils.EventManager.getInstance():dispatch("QUEST_FINISH");
        if quest.show_reward ~= 0 then
            --完成任务提示
            -- GetFinishQuest()
        end
    end

    if quest.status == 1 then
        DispatchEvent("LOCAL_HERO_QUEST_FINISH", {questId = quest.id})
    end

    
    if quest.status ~= 0 then
        module.EncounterFightModule.RemoveFightDataByType("quest_" ..  quest.id);
    end
    utils.EventManager.getInstance():dispatch("QUEST_INFO_CHANGE", quest);
    have_quest_change = true;
    if quest.is_show_on_task then
        utils.EventManager.getInstance():dispatch("QUEST_LIST_CHANGE", quest);
    end
    if quest.status == 1 and (quest.type == 31 or quest.type == 32) then
        utils.EventManager.getInstance():dispatch("LOCAL_ACHIEVEMENT_CHANGE", {quest_id = quest.id})
    end
end);

utils.EventManager.getInstance():addListener("server_notify_end", function(event, cmd, data)
    if have_quest_change then
        have_quest_change = false
        utils.EventManager.getInstance():dispatch("AFTER_QUEST_INFO_CHANGE");
    end
end)

utils.EventManager.getInstance():addListener("server_notify_58", function(event, cmd, data)
    local quest_id = data[1];
    local rewards = {};

    for k, v in ipairs(data) do
        if k ~= 1 then
            table.insert(rewards, {type=v[1],id=v[2],value=v[3],uuid=v[4] or 0})
        end
    end

    local cfg = GetQuestConfig(quest_id);
    if cfg and cfg.is_show_on_task then
        utils.EventManager.getInstance():dispatch("QUEST_FINISH_REWARD", cfg, rewards);
    end
end);

local lastQueryTime=0
local function CityContuctInfo(reset,flag)
    --flag --查询本地不查服务器
    if flag then
        return _cityContuctInfo;
    end

    local need_send_request = false;
    if lastQueryTime+20<module.Time.now() or reset or _cityContuctInfo == nil then
        need_send_request = true;
    end

    _cityContuctInfo = _cityContuctInfo or {today_count = 0,  round_index = 0, current_city = 0, boss = {}};

    if need_send_request then
        utils.NetworkService.Send(11049)
        lastQueryTime=module.Time.now()
    end

    return _cityContuctInfo;
end

local function CityContructFightBoss(id)
    utils.NetworkService.Send(11047, {nil, id})
end

local canAcceptList = {}
local function findActivityQuest(typeId)
    for k,v in pairs(quest_list) do
        if v.type and v.type == typeId and v.status == 0 then
            return true
        end
    end
    return false
end
local function findActivityQuestByQuestType(v)
    if v.quest_type ~= "0" then
        local _questType = StringSplit(v.quest_type, "|")
        for i,p in ipairs(CityContuctId) do
            if p == v.id then
                for i,v in ipairs(_questType) do
                    local _list = GetQuestList(tonumber(p), 0)
                    if _list and #_list > 0 then
                        return false
                    end
                end
            end
        end
        for i,p in ipairs(ActivityBountyId) do
            if p == v.id then
                local _list = module.QuestModule.GetList()
                for i,t in ipairs(_questType) do
                    for k,d in pairs(_list) do
                        if d.bountyId == tonumber(t) and d.status == 0 then
                            return false
                        end
                    end
                end
            end
        end
    end
    return true
end
local function activityQuestDependId(_cfg)
    if _cfg.depend_quest_id and _cfg.depend_quest_id ~= 0 then
        local _questCfg = GetQuest(_cfg.depend_quest_id)
        if not _questCfg or (_questCfg and _questCfg.status ~= 1) then
            return false
        end
    end
    return true
end
---活动构成成任务结构
local function addCanAcceptActivityQuest(tab)
    local activityConfig = require "config.activityConfig"
    for k,v in pairs(activityConfig.GetActivity()) do
        if v.activity_type == 1 then
           if findActivityQuestByQuestType(v) and not findActivityQuest(v.id) and activityQuestDependId(v) then
                local _cfg = activityConfig.GetActivity(v.id)
                if _cfg and _cfg.lv_limit <= module.HeroModule.GetManager():Get(11000).level then
                    local _questCfg = {}
                    _questCfg.name = _cfg.name
                    _questCfg.type = _cfg.id
                    _questCfg.desc = _cfg.des
                    _questCfg.desc2  = _cfg.des2
                    _questCfg.script = "guide/bounty/activityQuest.lua"
                    _questCfg.npc_id = _cfg.findnpcname
                    _questCfg.map_id = _cfg.gotowhere
                    _questCfg.icon = _cfg.icon
                    _questCfg.reward = {}
                    for i = 1, 3 do
                        if _cfg["reward_id"..i] ~= 0 then
                            local _temp = {}
                            _temp.type = _cfg["reward_type"..i]
                            _temp.id = _cfg["reward_id"..i]
                            _temp.value = _cfg["reward_value"..i] or 0
                            local _item = utils.ItemHelper.Get(_temp.type, _temp.id)
                            if _item and _item.is_show ~= 0 then
                                table.insert(_questCfg.reward, _temp)
                            end
                        end
                    end
                    table.insert(tab, _questCfg)
                end
            end
        end
    end
end

local function GetCanAccept()
    if not questConfig then
        GetQuestConfig(1)
    end
    canAcceptList = {}
    for k,v in pairs(questConfig) do
        if CanAcceptQuest(k) and (v.type == 10 or v.type == 11 or v.type == 12) then
            table.insert(canAcceptList, v)
        end
    end
    --插入活动
    addCanAcceptActivityQuest(canAcceptList)
    return canAcceptList
end

utils.EventManager.getInstance():addListener("server_respond_11042", function(event, cmd, data)
    local sn, result = data[1], data[2];
    if result == 0 then
        if SnArr[sn] then
            utils.EventManager.getInstance():dispatch("CITY_CONTUCT_ACCEPT_SUCCEED",SnArr[sn]);
            SnArr[sn] = nil
        end
        _cityContuctInfo.current_city = data[4];
    else
        if SnArr[sn] then
            utils.EventManager.getInstance():dispatch("CITY_CONTUCT_ACCEPT_FAILD",SnArr[sn]);
            SnArr[sn] = nil
        end
    end
end);

utils.EventManager.getInstance():addListener("server_respond_11050", function(event, cmd, data)
    --ERROR_LOG("server_respond_11050",sprinttb(data))
    if data[2] ~= 0 then
        print("query city contuct info failed")
        return;
    end
    _cityContuctInfo = {boss = {}};
    _cityContuctInfo.round_index  = data[3];
    _cityContuctInfo.today_count  = data[4];
    _cityContuctInfo.current_city = data[6];

    for _, v in ipairs(data[5] or {}) do
        _cityContuctInfo.boss[v[1]] = { id = v[1], exp = v[2], quest_group = v[3],lastSetTime=v[4] }
    end

     print("_cityContuctInfo", _cityContuctInfo.round_index, _cityContuctInfo.today_count);

    utils.EventManager.getInstance():dispatch("CITY_CONTRUCT_INFO_CHANGE");
end);

utils.EventManager.getInstance():addListener("server_respond_11044", function(event, cmd, data)
    local sn, result = data[1], data[2];
    if result ~= 0 then
        print("query city contuct info failed")
    else
        _cityContuctInfo = _cityContuctInfo or {};
        _cityContuctInfo.round_index = data[3];
        _cityContuctInfo.today_count = data[4];
        _cityContuctInfo.current_city = 0;

        -- print("_cityContuctInfo", _cityContuctInfo.round_index, _cityContuctInfo.today_count);
        utils.EventManager.getInstance():dispatch("CITY_CONTRUCT_INFO_CHANGE",sn);
    end
    CleanQuestServerRequestStatus(sn, result)
end)

utils.EventManager.getInstance():addListener("server_respond_11046", function(event, cmd, data)
    local sn, result = data[1], data[2];
    if result ~= 0 then
        print("query city contuct info failed")
    else
        _cityContuctInfo = _cityContuctInfo or {};
        _cityContuctInfo.round_index = data[3];
        _cityContuctInfo.today_count = data[4];

        print("_cityContuctInfo", _cityContuctInfo.round_index, _cityContuctInfo.today_count);

        utils.EventManager.getInstance():dispatch("CITY_CONTRUCT_INFO_CHANGE");
    end
    CleanQuestServerRequestStatus(sn, result)
end)

utils.EventManager.getInstance():addListener("LOCAL_RECONNECTION", function(event, data)
    coroutine.resume(coroutine.create(function()
        QueryQuestList(true)
    end))
end)

local function GetQuestConfigByMutexId(mutexId)
    if questConfig == nil then
        GetQuestConfig()
    end
    return mutex_id_list[mutexId]
end

local function GetQuestConfigByNPC(npc, only_can_accept)
    GetQuestConfig(0);

    local list = npc_quest_list[npc] or {}

    if not only_can_accept then
        return list;
    end

    local t = {}
    for _, v in ipairs(list) do
        if CanAcceptQuest(v.id) and v.only_accept_by_other_activity == 0 then
            table.insert(canAcceptList, v)
        end
        table.insert(t, v);
    end

    return t;
end

local function GetRedPointState(full)
    local allQuest = GetQuestConfigByType(100);
    local nowDay = math.ceil((module.Time.now() - module.playerModule.GetCreateTime()) / 86400);
    if full then
        local pointState = {};
        for day,v in ipairs(allQuest) do
           if pointState[day] == nil then
                pointState[day] = {};
           end
           for type,k in pairs(v) do
                local state = false;
                if nowDay >= day then
                    for _,j in ipairs(k) do
                        if CanSubmitQuest(j.id) and j.day7_type ~= 2 then
                            local quest = GetQuest(j.id);
                            -- ERROR_LOG("任务可以提交", quest.name);
                            state = true;
                            break;
                        end
                    end
                end
                pointState[day][type] = state;
           end
        end
        return pointState;
    else
        for day,v in ipairs(allQuest or {}) do      --天
            if nowDay >= day then
                for _,k in pairs(v) do                --类别
                    for _,j in ipairs(k) do           --任务
                        if CanSubmitQuest(j.id) and j.day7_type ~= 2 then
                            local quest = GetQuest(j.id);
                            -- ERROR_LOG("任务可以提交", quest.name);
                            return true;
                        end
                    end
                end
            end
        end
        return false
    end
end

local function getOtherRecords(quest, idx)
    local i = idx or 1
    if quest.condition[i].type == 1 then
        if quest.condition[i].id == 1 then
            return module.HeroModule.GetManager():Get(11000).level
        end
    elseif quest.condition[i].type == 34 then
        local _endTime = GetQuestEndTime(quest);
        if quest.condition[i].id == 1 then
            return module.HeroModule.GetHeroCount(_endTime)
        end
    elseif quest.condition[i].type == 37 then
        local _endTime = GetQuestEndTime(quest);
        if quest.condition[i].id == 1 then
            return module.equipmentModule.EquipCount(_endTime)
        elseif quest.condition[i].id == 2 then
            return module.equipmentModule.InscripCount(_endTime)
        end
    elseif quest.condition[i].type == 62 then
        local _endTime = GetQuestEndTime(quest);
        return module.HeroModule.GetHeroCount(_endTime, quest.condition[i].id)
    elseif quest.condition[i].type == 63 then
        local _endTime = GetQuestEndTime(quest);
        return module.HeroModule.EquipCount(_endTime, quest.condition[i].id)
    elseif quest.condition[i].type == 64 then
        local _endTime = GetQuestEndTime(quest);
        return module.HeroModule.InscripCount(_endTime, quest.condition[i].id)
    elseif quest.condition[i].type == 71 then
        return module.ItemModule.GetItemCount(quest.condition[i].id)
    elseif quest.condition[i].type == 72 then
        local _hero = module.HeroModule.GetManager():Get(quest.condition[i].id)
        _hero = _hero or {stage = 0}
        return _hero.stage
    elseif quest.condition[i].type == 74 then
        local _hero = module.HeroModule.GetManager():Get(quest.condition[i].id)
        _hero = _hero or {star = 0}
        return _hero.star
    elseif quest.condition[i].type == 91 then
        local _list = utils.ItemHelper.GetList(utils.ItemHelper.TYPE.ITEM, quest.condition[i].id)
        local _count = 0
        for i,v in ipairs(_list) do
            _count = _count + module.ItemModule.GetItemCount(v.id)
        end
        return _count
    elseif quest.condition[i].type == 98 then
        local _info = module.fightModule.GetFightInfo(quest.condition[i].id)
        local _count = 0
        if _info then
            for i = 1, 3 do
                if module.fightModule.GetOpenStar(_info.star, i) ~= 0 then
                    _count = _count + 1
                end
            end
        end
        if _count > 1 then
            _count = 1
        end
        return _count
    elseif quest.condition[i].type == 100 then
        local _info = module.fightModule.GetFightInfo(quest.condition[i].id)
        if _info:IsPassed() then
            return 1
        end
        return 0
    elseif quest.condition[i].type == 101 then
        return (module.playerModule.Get().starPoint or 0)
    elseif quest.condition[i].type == 102 then
        local _endTime = GetQuestEndTime(quest)
        local _count = module.equipmentModule.EquipLevelCount(_endTime, quest.condition[i].id)
        return _count
    else
        return quest.records[i]
    end
end

local function GetConfigType(type)
    return questConfigType[type] or {}
end

local acceptSideQuestCo = nil;
local needAccept = false;
local function AcceptSideQuest()
    GetQuestConfig()

    if acceptSideQuestCo then
        needAccept = true;
        return;
    end

    needAccept = false;
    acceptSideQuestCo = coroutine.create(function()
        for i,v in ipairs(acceptSideQuestList) do
            if CanAcceptQuest(v.id) then
                local data = utils.NetworkService.SyncRequest(78, {nil, v.id, 0})
                if data[2] ~= 0 then
                    print("自动接", v.id, v.name, sprinttb(v.consume), sprinttb(data));
                end
            end
        end

        for i,v in ipairs(submitSideQuestList) do
            if CanSubmitQuest(v.id) then
                local quest = GetQuest(v.id);
                local data = utils.NetworkService.SyncRequest(78, {nil, v.id, 1, 0, quest.stageFlag})
                if data[2] ~= 0 then
                    print("自动交", v.id, v.name, quest.stageFlag, sprinttb(data), debug.traceback());
                end
            end
        end

        acceptSideQuestCo = nil;
        if needAccept then
            AcceptSideQuest();
        end
    end)
    coroutine.resume(acceptSideQuestCo);
end

utils.EventManager.getInstance():addListener("AFTER_QUEST_INFO_CHANGE", function(event, data)
    if SceneStack.MapId() ~= 0 then
        AcceptSideQuest()
    end
end)

utils.EventManager.getInstance():addListener("EQUIPMENT_INFO_CHANGE", function(event, data)
    if SceneStack.MapId() ~= 0 then
        AcceptSideQuest()
    end
end)

utils.EventManager.getInstance():addListener("ShowActorLvUp", function(event, data)
    if SceneStack.MapId() ~= 0 then
        AcceptSideQuest()
    end
end)

utils.EventManager.getInstance():addListener("ITEM_INFO_CHANGE", function(event, data)
    if SceneStack.MapId() ~= 0 then
        AcceptSideQuest()
    end
end)

local function checkChangeNameQuest()
    local _quest = GetQuest(101081)
    if _quest and _quest.status == 0 then
        local _count = module.ItemModule.GetItemCount(90115)
        if utils.SGKTools.matchingName(module.playerModule.Get().name) ~= "陆水银" then
            FinishQuest(101081)
        end
    end
end

local function GetOtherQuest(pid,quest_id,CoopQuest_id,refresh,func)
    if not refresh and otherQuestTab[pid] and otherQuestTab[pid][quest_id] and otherQuestTab[pid][quest_id].lastQueryTime+15>= module.Time.now() then
        if otherQuestTab[pid][quest_id].status == 0 or otherQuestTab[pid][quest_id].status == 1 then
            if func then
                func()
            else
                return otherQuestTab[pid][quest_id]
            end  
        end
    else
        local sn = utils.NetworkService.Send(76, {nil, 0,0,pid,quest_id})
        SnArr[sn] = {quest_id = CoopQuest_id,pid = pid,func = func}
    end
end

return {
    GetList = GetQuestList,
    Get = GetQuest,
    GetCfg = GetQuestConfig,
    GetCfgByType = GetQuestConfigByType,
    GetConfigType = GetConfigType,
    GetQuestConfigByNPC = GetQuestConfigByNPC,
    GetQuestConfigByGuideType = GetQuestConfigByGuideType,
    GetQuestConfigByMemory = GetQuestConfigByMemory,
    GetGoWhereConfig = GetGoWhereConfig,
    GetQuestSequenceCfg = GetQuestSequenceCfg,
    GetQuestSubmitItemList = GetQuestSubmitItemList,
    GetCfgByMutexId=GetQuestConfigByMutexId,--获取相同互斥ID的任务

    Accept = AcceptQuest,
    Finish = FinishQuest,
    Submit = FinishQuest,
    Cancel = CancelQuest,
    CanAccept = CanAcceptQuest,
    CanSubmit = CanSubmitQuest,

    CityContuctInfo = CityContuctInfo,
    CityContuctAcceptQuest = CityContuctAcceptQuest,
    CityContuctCancelQuest = CityContuctCancelQuest,
    CityContuctSubmitQuest = CityContuctSubmitQuest,
    CityContructFightBoss = CityContructFightBoss,

    RegisterQuest = RegisterQuest,
    RemoveQuest = RemoveQuest,
    GetCanAccept = GetCanAccept,

    StartQuestGuideScript = startQuestGuideScript,

    GetOldUuid = GetOldUuid,
    SetOldUuid = SetOldUuid,

    GetNpcStatus = getNpcStatus,
    GetRedPointState = GetRedPointState,
    GetOtherRecords = getOtherRecords,

    GetSevenDayOpen = GetSevenDayOpen,
    AcceptActivityQuest = AcceptActivityQuest,
    QueryQuestList = QueryQuestList,
    AcceptSideQuest = AcceptSideQuest,
    GetChapter = GetChapter,
    NotifyNpcStatusChange = notifyNpcStatusChange,

    callQuestScript = callQuestScript,
    CheckChangeNameQuest = checkChangeNameQuest,
    AutoAcceptNextIdList = AutoAcceptNextIdList,

    GetOtherQuest = GetOtherQuest,
}
