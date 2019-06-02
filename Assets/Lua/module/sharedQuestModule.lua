local MapConfig = require "config.MapConfig"
local MapNPCModule = require "module.MapNPCModule"

local C_SHARED_QUEST_QUERY_INFO_REQUEST = 3369
local C_SHARED_QUEST_QUERY_INFO_RESPOND = "server_respond_3370"
local C_SHARED_QUEST_ACCEPT_REQUEST     = 3371
local C_SHARED_QUEST_ACCEPT_RESPOND     = "server_respond_3372"
local C_SHARED_QUEST_CANCEL_REQUEST     = 3373
local C_SHARED_QUEST_CANCEL_RESPOND     = "server_respond_3374"
local C_SHARED_QUEST_SUBMIT_REQUEST     = 3375
local C_SHARED_QUEST_SUBMIT_RESPOND     = "server_respond_3376"
local NOTIFY_SHARED_QUEST_CHANGE        = "server_notify_1139"

local questInfo = {}
local questCfgList = nil
local questCfgByMapId = nil
local questCfgByNpcId = nil

local function GetCfg(questId, mapId, npcId)
    if not questCfgList then
        questCfgList = {}
        questCfgByMapId = {}
        questCfgByNpcId = {}
        DATABASE.ForEach("shared_quest", function(v)
            local _cfg = {}
            _cfg.questId = v.quest_id
            _cfg.npcId = v.npc_id
            _cfg.dependLevel = v.depend_level
            _cfg.posIdx = v.pool_id
            _cfg.acceptLimit = v.accept_limit
            _cfg.finishCount = v.finish_count
            _cfg.only_accept_by_other_activity = v.only_accept_by_other_activity
            _cfg.depend_level = v.depend_level
            _cfg.depend_item = v.depend_item
            _cfg.reward = {}
            _cfg.consume = {}
            _cfg.duration = v.duration
            _cfg.begin_time = v.begin_time
            _cfg.end_time = v.end_time
            _cfg.period = v.period
            
            for i = 1, 3 do
                table.insert(_cfg.reward, {type = v["reward_type"..i], id = v["reward_id"..i], value = v["reward_value"..i]})
            end
            for i = 1, 2 do
                table.insert(_cfg.consume, {type = v["consume_type"..i], id = v["consume_id"..i], value = v["consume_value"..i], need_reset = v["need_reset"..i]})
            end
            if MapConfig.GetMapMonsterConf(v.npc_id) then
                _cfg.mapId = MapConfig.GetMapMonsterConf(v.npc_id).mapid
                if not questCfgByMapId[_cfg.mapId] then questCfgByMapId[_cfg.mapId] = {} end
                table.insert(questCfgByMapId[_cfg.mapId], _cfg)
            else
                ERROR_LOG(v.quest_id,  "npc not find")
            end
            if not questCfgByNpcId[v.npc_id] then questCfgByNpcId[v.npc_id] = {} end
            table.insert(questCfgByNpcId[v.npc_id], _cfg)
            questCfgList[v.quest_id] = _cfg
        end)
    end
    if questId then
        return questCfgList[questId]
    end
    if mapId then
        return questCfgByMapId[mapId]
    end
    if npcId then
        return questCfgByNpcId[npcId]
    end
    return questCfgList
end

local function GetQuestInfo(questId)
    if questId then
        return questInfo[questId]
    end
    return questInfo
end

local function CanAccept(id, showError)
    local _questInfo = questInfo[id]
    if not _questInfo then
        return false, 0
    end
    local _cfg = GetCfg(_questInfo.questId)
    if _cfg then
        if _cfg.dependLevel > module.HeroModule.GetManager():Get(11000).level then
            return false, 1 --接取等级不足
        end
    else
        return false, 0
    end
    if questInfo[_cfg.posIdx] then
        if _cfg.acceptLimit < #questInfo[_cfg.posIdx].player then
            return false, 2 --接取人数达到上限
        end
    else
        return false, 0
    end
    if questInfo[_cfg.posIdx].startTime > module.Time.now() then
        return false, 3 --未到接取时间
    end

    local function IsAcceptConsume(flag)
        flag = flag or 0;
        return (flag&0x04) ~= 0
    end

    for _, consume in ipairs(_cfg.consume) do
        if consume.type ~= 0 and IsAcceptConsume(consume.need_reset) then
            local item = utils.ItemHelper.Get(consume.type, consume.id);
            if item.count < consume.value then
                if showError then showDlgError(nil, item.name .. '数量不足'); end
                return false, 4
            end
        end
    end

    if _cfg.depend_item ~= 0 then
        local _count = module.ItemModule.GetItemCount(_cfg.depend_item)
        if _count <= 0 then
            return false, 4
        end
    end

    return true
end

local function CanSubmit(id)
    local _questInfo = questInfo[id]
    if not _questInfo then
        return false, 0
    end
    return true
end

local function QueryInfo(idList)
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(C_SHARED_QUEST_QUERY_INFO_REQUEST, {nil, idList})
    else
        utils.NetworkService.Send(C_SHARED_QUEST_QUERY_INFO_REQUEST, {nil, idList})
    end
end

local function Accept(id)
    if not CanAccept(id) then
        return
    end
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(C_SHARED_QUEST_ACCEPT_REQUEST, {nil, id})
    else
        utils.NetworkService.Send(C_SHARED_QUEST_ACCEPT_REQUEST, {nil, id})
    end
end

local function Cancel(id)
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(C_SHARED_QUEST_CANCEL_REQUEST, {nil, id})
    else
        utils.NetworkService.Send(C_SHARED_QUEST_CANCEL_REQUEST, {nil, id})
    end
end

local function Finish(id)
    if not CanSubmit(id) then
        return
    end
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(C_SHARED_QUEST_SUBMIT_REQUEST, {nil, id})
    else
        utils.NetworkService.Send(C_SHARED_QUEST_SUBMIT_REQUEST, {nil, id})
    end
end


local function GetShareQuestPeroid(_cfg)
    -- ERROR_LOG(sprinttb(_cfg));
    local start_time = (math.floor((module.Time.now() - _cfg.begin_time)/_cfg.period)) * _cfg.period + _cfg.begin_time;


	return  start_time+_cfg.duration,start_time+_cfg.period;
end

local Map_share_quest = {}

local function GetQuestNPC(npcId)
    return Map_share_quest[npcId]
end

local function ClearShareQuestNPC( ... )
    Map_share_quest = {}
end

local Action = {};
local function upMapPoint()
    if SceneStack.GetBattleStatus() then
        return
    end

    local _posList = GetCfg(nil, SceneStack.MapId()) or {}

    local delteList = {}

    for i,v in ipairs(_posList) do
        delteList[v.npcId] = true;
        -- module.NPCModule.deleteNPC(v.npcId)
    end
    for k,v in pairs(questInfo) do
        local _cfg = GetCfg(v.questId)
        if _cfg then
            if v.finishCount ~= _cfg.finishCount then
                if v.startTime <= module.Time.now() then
                    if MapNPCModule.GetConfig(nil,nil,_cfg.npcId) then
                        local end_time,period_time = GetShareQuestPeroid(_cfg)
                        
                        local dur = end_time - module.Time.now();
                        -- ERROR_LOG(string.format("当前周期结束时间 %s   %s %s",os.date("%Y-%m-%d   %H:%M:%S",end_time),os.date("%Y-%m-%d   %H:%M:%S",module.Time.now()),dur));
                        if dur >0 then
                            if Action[v.id] then
                                Action[v.id]:Kill();
                            end

                            Action[v.id] = SGK.Action.DelayTime.Create(dur):OnComplete(function()
                                if _cfg.mapId then
                                    if SceneStack.MapId() == _cfg.mapId then
                                        coroutine.resume(coroutine.create(function()
                                            local _data = QueryInfo({v.id});
                                            -- ERROR_LOG("协议------->>>>",sprinttb(_data))
                                            if _data[2] == 0 then
                                                for k,v in pairs(_data[3]) do
                                                    module.sharedQuestModule.upQuestInfo(v, true)
                                                end
                                            end

                                        end))
                                    end
                                end

                                Action[v.id] = nil;
                            end)
                        elseif period_time then
                            local offest = period_time - module.Time.now()
                            if Action[v.id] then
                                Action[v.id]:Kill();
                            end
                            -- ERROR_LOG("已过活动时间----------->>>"..offest.."秒后刷新下一个宝箱");
                            Action[v.id] = SGK.Action.DelayTime.Create(offest):OnComplete(function()
                                if _cfg.mapId then
                                    if SceneStack.MapId() == _cfg.mapId then
                                        coroutine.resume(coroutine.create(function()
                                            local _data = QueryInfo({v.id});
                                            -- ERROR_LOG("协议------->>>>",sprinttb(_data))
                                            if _data[2] == 0 then
                                                upMapPoint();
                                            end
                                        end))
                                    end
                                end

                                Action[v.id] = nil;
                            end)
                        end
                    end
                    module.NPCModule.LoadNpcOBJ(_cfg.npcId)
                    delteList[_cfg.npcId] = nil;
                    Map_share_quest[_cfg.npcId] = true
                    -- duration
                    -- ERROR_LOG("npc已刷新",sprinttb(v),sprinttb(_cfg));
                else
                    -- ERROR_LOG(string.format("%d秒后刷新地图宝箱%d",v.startTime - module.Time.now(),_cfg.mapId));
                    SGK.Action.DelayTime.Create(v.startTime - module.Time.now()):OnComplete(function()
                        
                        if _cfg.mapId then
                            if SceneStack.MapId() == _cfg.mapId then
                                upMapPoint()
                            end
                        end
                    end)
                end
                -- QueryInfo
            end
        else
            --ERROR_LOG(v.questId, "error", sprinttb(v))
        end
    end
    
    for npcId, _ in pairs(delteList) do
        Map_share_quest[npcId] = nil
    end

    module.NPCModule.Ref_NPC_LuaCondition()
end

-- local upPoint = true
-- utils.EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, cmd, data)
--     if upPoint then
--         upPoint = false
--         StartCoroutine(function()
--             while true do
--                 WaitForSeconds(120)
--                 upMapPoint()
--             end
--         end)
--     end
-- end)

local function upQuestInfo(data, update_map_point)
    local _tab = {
        id          = data[1],
        questId     = data[2],
        startTime   = data[3],
        finishCount = data[4],
    }
    _tab.player = {}
    _tab.playerPisList = {}
    for i,v in ipairs(data[5]) do
        local _playerData = {
            pid         = v[1],
            status      = v[2],
            record1     = v[3],
            record2     = v[4],
            count       = v[5],
            acceptTime  = v[6],
            submitTime  = v[7],
        }
        table.insert(_tab.player, _playerData)
        _tab.playerPisList[v[1]] = _playerData
    end
    questInfo[data[1]] = _tab

    if update_map_point then
        upMapPoint()
        DispatchEvent("LOCAL_SHAREDQUEST_INFO_CHANGE")
    end
end

utils.EventManager.getInstance():addListener(NOTIFY_SHARED_QUEST_CHANGE, function(event, cmd, data)
    upQuestInfo(data, true)
end)

utils.EventManager.getInstance():addListener("LOCAL_ACTIVITY_STATUS_CHANGE", function(event, data)
    if data and data.id == 2107 then
        module.NPCModule.Ref_NPC_LuaCondition()
    end
end)

local TYPE = {
    ONENTERMAP = 1, --登录状态
    INFOCHANGE = 2, --任务状态改变
}

local function queryQuestByMap(_posList)
    local _list = {}
    for k,v in ipairs(_posList or {}) do
        _list[v.posIdx] = true
    end
    local _posList_ = {}
    for k,v in pairs(_list) do
        table.insert(_posList_, k)
    end
    local _data = QueryInfo(_posList_)
    if _data[2] == 0 then
        for i,v in ipairs(_data[3]) do
            upQuestInfo(v, false)
        end
    end

    upMapPoint()
    DispatchEvent("LOCAL_SHAREDQUEST_INFO_CHANGE",TYPE.ONENTERMAP)
end

utils.EventManager.getInstance():addListener("MAP_SCENE_READY", function(event, data)
    local _posList = GetCfg(nil, SceneStack.MapId()) or {}
    if #_posList <= 0 then
        return
    end
    coroutine.resume(coroutine.create(function()
        queryQuestByMap(_posList)
    end))
end)


return {
    GetCfg       = GetCfg,
    GetQuestInfo = GetQuestInfo,
    QueryInfo    = QueryInfo,
    Accept       = Accept,
    Cancel       = Cancel,
    Finish       = Finish,
    CanAccept    = CanAccept,

    upQuestInfo = upQuestInfo,

    GetShareQuestPeroid = GetShareQuestPeroid,
    GetQuestNPC = GetQuestNPC,
    ClearShareQuestNPC = ClearShareQuestNPC,
}
