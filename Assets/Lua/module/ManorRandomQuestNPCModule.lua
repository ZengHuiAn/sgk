local playerModule = require "module.playerModule"
local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Time = require "module.Time"
local UserDefault = require "utils.UserDefault"
local ManorModule = require "module.ManorModule"
local HeroModule = require "module.HeroModule"
local ItemModule = require "module.ItemModule"
local ShopModule = require "module.ShopModule"
local openLevel = require "config.openLevel"

local C_MANOR_QUERY_QUEST_REQUEST = 11087 --庄园npc查询
local C_MANOR_QUERY_QUEST_RESPOND = 11088

local NOTIFY_MANOR_RANDOM_NPC_CHANGE = 11087 -- 庄园npc变化通知

local C_MANOR_ACCEPT_QUEST_REQUEST = 11089 --领取庄园NPC任务
local C_MANOR_ACCEPT_QUEST_RESPOND = 11090

local function ON_SERVER_RESPOND(id, callback)
    EventManager.getInstance():addListener("server_respond_" .. id, callback);
end

local function ON_SERVER_NOTIFY(id, callback)
    EventManager.getInstance():addListener("server_notify_" .. id, callback);
end

local ManorQueryNPCSN = {}

local ManorNPCManager = {}

function ManorNPCManager.New(pid)
    pid = pid or playerModule.GetSelfID()
    return setmetatable({
        pid = pid,
        random_npc = {},
        random_npc_quest_cycle = 0
    }, {
        __index = ManorNPCManager
    });
end

local function npcAlive(npc)
    return npc and ((npc.dead_time == 0) or (module.Time.now() < npc.dead_time));
end

local managers = {}
local function GetManager(pid)
    pid = pid or playerModule.GetSelfID()
    if managers[pid] == nil then
        managers[pid] = ManorNPCManager.New(pid)
    end
    return managers[pid];
end

function ManorNPCManager:QueryNPC(force, watch)
    if Time.now() >= self.random_npc_quest_cycle + 1800 or force then
        self.random_npc_quest_cycle = Time.now();
        local sn = NetworkService.Send(C_MANOR_QUERY_QUEST_REQUEST, {nil, self.pid, watch and 1 or 0})
        ManorQueryNPCSN[sn] = {pid = self.pid}
        if coroutine.isyieldable() then
            ManorQueryNPCSN[sn].co = coroutine.running();
            coroutine.yield();
        end
    end
    return self.random_npc or {};
end

function ManorNPCManager:InteractNPC(id, operation, quest_id)
    if not id then
        for _, npc in pairs(self.random_npc) do
            if npcAlive(npc) and  npc.quest == quest_id then
                id = npc.mode;
                break;
            end
        end
    end

    if not id then
        ERROR_LOG('ManorNPCManager ERROR, id and quest_id not exist', id, quest_id)
        return;
    end

    if self.random_npc[id] then
        if self.random_npc[id].quest ~= 0 and not operation then
            ERROR_LOG('need operation')
            return;
        end
        NetworkService.Send(C_MANOR_ACCEPT_QUEST_REQUEST, {nil, self.pid, self.random_npc[id].uuid, operation})
        return true;
    else
        showDlgError(nil, "任务已过期")
    end
end


function ManorNPCManager:WatchNPC(watch)
    NetworkService.Send(C_MANOR_ACCEPT_QUEST_REQUEST, {nil, watch and self.pid or 0})
end

local function isInManorScene(pid)
    local mapInfo = SceneStack.MapId("all");
    return mapInfo.mapId == 26 and mapInfo.mapRoom == pid;
end

local function updateNPC(npc, v)
    local interact = {}
    for _, vv in ipairs(v[7] or {}) do
        table.insert(interact, {pid = vv[1]})
    end

    npc = npc or {}

    npc.uuid = v[1]
    npc.id   = v[2]
    npc.flag = v[3]
    npc.dead_time = v[4]
    npc.group = v[5]
    npc.mode = v[6]
    npc.interact = interact

    npc.quest = v[8]
    npc.fight = v[9]
    npc.drop  = v[10]
    npc.reward_count = v[11]
    
    return npc;
end

ON_SERVER_RESPOND(C_MANOR_QUERY_QUEST_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        return;
    end

    local pid = ManorQueryNPCSN[sn].pid;
    if not pid then
        ERROR_LOG('C_MANOR_QUERY_QUEST_RESPOND with no pid');
        return;
    end
    
    local manager = GetManager(pid);
    manager.random_npc = {}
    
    local npc_have_quest = false;
    for _, v in ipairs(data[3]) do
        local npc = updateNPC(nil, v)
        manager.random_npc[npc.mode] = npc;
        npc_have_quest = npc_have_quest or (npc.quest ~= 0);
    end
    
    if ManorQueryNPCSN[sn] and ManorQueryNPCSN[sn].co then
        coroutine.resume(ManorQueryNPCSN[sn].co);
    end

    ManorQueryNPCSN[sn] = nil;
    --[[
        local npc = updateNPC(nil, {
            [1] = 70,
        [2] = 30,
        [3] = 0,
        [4] = 1531365900 + 24 * 3600,
        [5] = 2,
        [6] = 10026202,
        [7] =
        {
        },
        [8] = 0,
        [9] = 0,
        [10] = 300000,
    })
    manager.random_npc[npc.mode] = npc;
    --]]
    print("查询庄园随机NPC返回", pid, sprinttb(manager.random_npc))
    DispatchEvent("MANOR_RANDOM_NPC_CHANGE", pid);

    if isInManorScene() then
        if npc_have_quest ~= 0 then DispatchEvent("QUEST_INFO_CHANGE"); end
    end
end)

ON_SERVER_NOTIFY(NOTIFY_MANOR_RANDOM_NPC_CHANGE, function(event, cmd, data)
    ERROR_LOG('NOTIFY_MANOR_RANDOM_NPC_CHANGE', sprinttb(data))

    local pid = data[1];

    local manager = managers[pid]
    if not manager then return; end

    local uuid = data[2][1];
    for _, v in pairs(manager.random_npc) do
        if v.uuid == uuid then
            if data[2][2] == 0 then
                manager.random_npc[v.mode] = nil;
                print("deleted", uuid, v.mode)
            else
                local mode = v.mode;
                updateNPC(v, data[2])
                assert(mode == v.mode);
                print("change", uuid, v.mode, v.quest)
            end

            DispatchEvent("MANOR_RANDOM_NPC_CHANGE", pid);
            if isInManorScene() then
                if v.quest ~= 0 then DispatchEvent("QUEST_INFO_CHANGE"); end
            end
            return;
        end
    end

    if data[2][2] ~= 0 then
        local npc = updateNPC(nil, data[2]) 
        manager.random_npc[npc.mode] = npc;
        if isInManorScene() then
            if npc.quest ~= 0 then DispatchEvent("QUEST_INFO_CHANGE"); end
        end
        DispatchEvent("MANOR_RANDOM_NPC_CHANGE", pid);
    end
end)


function ManorNPCManager:QuestAcceptable(quest_id)
    local self_pid = module.playerModule.GetSelfID();
    for _, npc in pairs(self.random_npc) do
        if npcAlive(npc) and  npc.quest == quest_id then
            for _, v in ipairs(npc.interact) do
                if v.pid == self_pid then
                    return false;
                end
            end
            return true;
        end
    end
    return false;
end


function ManorNPCManager:GetNPCOperation(gid)
    local npc = self.random_npc[gid]

    local opt_type = nil;
    if npc.fight ~= 0 then
        opt_type = 'fight'
    elseif npc.quest ~= 0 then
        opt_type = 'quest'
    elseif npc.drop ~= 0 then
        opt_type = 'reward'
    end
         
    if not npcAlive(npc) then
        return nil, '已经消失', opt_type, npc;
    end
    
    for _, v in ipairs(npc.interact) do
        if v.pid == module.playerModule.GetSelfID() then
            return nil, '已经交互过', opt_type, npc;
        end
    end

    if npc.quest ~= 0 then
        local quest = module.QuestModule.Get(npc.quest)
        if quest and quest.status == 0 then
            return 1, "完成任务", opt_type, npc
        else
            return 0, "接任务", opt_type, npc
        end
    elseif npc.fight ~= 0 then
        return 0, "挑战", opt_type, npc
    elseif npc.drop ~= 0 then
        return 0, "领取奖励", opt_type, npc
    end

    return nil, '没有操作可以执行', opt_type, npc
end

local function GetCurrentManager()
    local target_pid = module.playerModule.GetSelfID();

    local _, owner = module.ManorManufactureModule.GetManorStatus()
    if owner and owner ~= module.playerModule.GetSelfID() then
        target_pid = owner;
    end

    return GetManager(target_pid);
end

local function QuestAcceptable(quest_id)
    local manager = GetCurrentManager()
    return manager:QuestAcceptable(quest_id);
end

local function GetOperation(gid)
    local manager = GetCurrentManager()
    return manager:GetNPCOperation(gid);
end

local function Interact(pid, gid, operation, quest_id)
    local manager = {};
    if pid then
        manager = GetManager(pid);
    else
        manager = GetCurrentManager()
    end
    return manager:InteractNPC(gid, operation, quest_id);
end

return {
    GetManager = GetManager,

    QuestAcceptable = QuestAcceptable,
    GetOperation = GetOperation,
    Interact = Interact,
}