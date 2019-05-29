local ReadOnlyObject = {}
function ReadOnlyObject.New(data)
    if type(data) == "table" then
        return setmetatable({
            __data = data
        }, {__index=ReadOnlyObject.Index, __pairs=ReadOnlyObject.Pairs});
    else
        return data;
    end
end

function ReadOnlyObject:Index(k)
    return ReadOnlyObject.New(self.__data[k])
end

function ReadOnlyObject:Pairs()
    return ReadOnlyObject.Next, self, nil
end

function ReadOnlyObject:Next(k)
    local k, v = next(self.__data, k);
    return k, ReadOnlyObject.New(v);
end

local activity_config = LoadDatabaseWithKey("team_activity", "id");
local npc_config = LoadDatabaseWithKey("team_activity_npc", "id");

local function NewTeamBattle(id) 
    return {
        id = id,
        npcs = {},
        players = {},
        cfg = activity_config[id],
        startTime = nil;
        endTime = nil;
    }
end

local function UpdateTeamBattleNpc(activity, data)
    local uuid, id, value = data[1], data[2], data[3]
    if id == 0 then
        print("activity", activity.id, 'npc', uuid, 'removed')
        activity.npcs[uuid] = nil; -- remove npc
        return uuid;
    end

    print("activity", activity.id, 'npc', uuid, 'update')

    local npc = activity.npcs[uuid] or {uuid = uuid, birth = module.Time.now()}
    npc.id = id;
    npc.cfg = npc_config[id] or {id = id}
    -- ERROR_LOG("npc表的信息",sprinttb(npc_config));
    npc.value = {value[1],value[2],value[3],value[4],value[5]};
    npc.dead = data[4];
    activity.npcs[uuid] = npc;

    return uuid;
end

local function UpdateTeamBattlePlayer(activity, data)
    local pid, value = data[2], data[3]
    if not value then
        print("activity", activity.id, 'player', pid, 'removed')
        activity.players[pid] = nil; -- remove player data
        return pid;
    end

    print("activity", activity.id, 'player', pid, 'update')

    local player = activity.players[pid] or {pid = pid}
    player.pid = pid;
    player.value = {value[1],value[2],value[3],value[4],value[5]};

    activity.players[pid] = npc;

    return pid;
end


local info = nil;
local function CheckBattleData()
    local current_team_id = module.TeamModule.GetTeamInfo().id;
    if current_team_id <= 0 then
        info = nil;
        return;
    end

    if not info or current_team_id ~= info.team_id then
        info = {loading = true, team_id = current_team_id, activitys = {}}
        print("qeury team activity", current_team_id)
        utils.NetworkService.Send(16204)
        return true;
    end
    return true;
end

local function GetBattleData(activity_id, create_if_not_exists)
    return info.activitys[activity_id];
end

local function UpdateBattleData(data)
    local team_id, activity_id, is_finished = data[1][1], data[1][2], data[1][3]
    if team_id ~= info.team_id then -- old team message, ignore
        return;
    end

    if is_finished then
        info.activitys[activity_id] = nil;
        print('activity', activity_id, 'finished')
        DispatchEvent("TEAM_ACTIVITY_FINISHED", activity_id);
        return;
    end

    local activity = info.activitys[activity_id]
    if not activity then
        print('activity', activity_id, 'start')
        activity = NewTeamBattle(activity_id);

        info.activitys[activity_id] = activity;
        DispatchEvent("TEAM_ACTIVITY_START", activity_id);

        activity.startTime = data[4][1];
        activity.endTime = data[4][2];
    end



    for _, v in ipairs(data[2]) do
        local pid = UpdateTeamBattlePlayer(activity, v)
        DispatchEvent("TEAM_ACTIVITY_PLAYER_CHANGE", pid);
    end

    for _, v in ipairs(data[3]) do
        local uuid = UpdateTeamBattleNpc(activity, v)
        DispatchEvent("TEAM_ACTIVITY_NPC_CHANGE", uuid);
    end
end

utils.EventManager.getInstance():addListener("server_notify_16200", function(_, _, data)
    ERROR_LOG('C_TEAM_ACTIVITY_NOTIFY', sprinttb(data))
    CheckBattleData();

    if not info or info.loading then  -- activity data is not ready
        return;
    end

    UpdateBattleData(data);
end)

--[[
utils.EventManager.getInstance():addListener("server_respond_16201", function(_, _, data) -- C_TEAM_ACTIVITY_START_RESPOND
    print('C_TEAM_ACTIVITY_START_RESPOND', sprinttb(data))
end)


--]]

utils.EventManager.getInstance():addListener("server_respond_16203", function(_, __, data) -- C_TEAM_ACTIVITY_INTERACT_RESPOND
    ERROR_LOG('C_TEAM_ACTIVITY_INTERACT_RESPOND',_,__, sprinttb(data))
    local callback = module.mazeModule.GetCallBack();
    local err = data[2];
    if callback then
        ERROR_LOG("回调成功",err);
        callback(tonumber(err));
    end

end);

utils.EventManager.getInstance():addListener("server_respond_16205", function(_, _, data) -- C_TEAM_ACTIVITY_QUERY_RESPOND

    ERROR_LOG("server_respond_16205",sprinttb(data));
    local sn, success = data[1], data[2]
    if not data[2] then
        return;
    end

    print(info, info.team_id, module.TeamModule.GetTeamInfo().id);
    if info == nil or info.team_id ~= module.TeamModule.GetTeamInfo().id then -- team is change after query request
        print('team is change after query request', info and info.team_id or '-', module.TeamModule.GetTeamInfo().id)
        return;
    end

    info.loading = nil;

    for _, v in ipairs(data[3]) do
        UpdateBattleData(v);
    end
end);

local function GetBattle(activity_id)
    if not CheckBattleData() then
        ERROR_LOG('team is not ready')
        return;
    end

    return ReadOnlyObject.New(info.activitys[activity_id]), info.loading;
end

local function StartBattle(activity_id)
    if not CheckBattleData() then
        ERROR_LOG('team is not ready')
        return;
    end

    if not activity_config[activity_id] then
        ERROR_LOG("team activity config not exists")
        return;
    end

    if info.loading then
        ERROR_LOG('team activity info is loading')
        return;
    end

    if info.activitys[activity_id] then
        ERROR_LOG('activity', activity_id, "is already exists");
        return;
    end

    local teamInfo = module.TeamModule.GetTeamInfo();
    if teamInfo.id <= 0 then
        ERROR_LOG('not in a team')
        return;
    end

    if teamInfo.leader.pid ~= module.playerModule.GetSelfID() then
        ERROR_LOG('only team leader can start activity')
        return;
    end

    print('start team activity', activity_id)
    utils.NetworkService.Send(16200, {nil, activity_id});
end

local function Interact(activity_id, npc_uuid, opt)
    if not CheckBattleData() then
        ERROR_LOG('team is not ready')
        return;
    end

    if info.loading then
        ERROR_LOG('team activity info is loading')
        return;
    end

    local activity = info.activitys[activity_id]
    
    if not activity then
        ERROR_LOG('activity', activity_id, "not exists")
        return;
    end
    ERROR_LOG(sprinttb(activity.npcs[3]));
    if not activity.npcs[npc_uuid] then
        ERROR_LOG(sprinttb(activity.npcs[npc_uuid]));

        ERROR_LOG('npc', npc_uuid, 'of activity', activity_id, "not exists")
        return;
    end

    print('team activity interact', activity_id, npc_uuid, opt)
    utils.NetworkService.Send(16202, {nil, activity_id, npc_uuid, opt})
end

local function Dump()
    if not CheckBattleData() then
        return;
    end

    for _, v in pairs(info.activitys) do
        print('activity', v.id)
        for _, npc in pairs(v.npcs) do
            print('      ', 'npc', npc.uuid, npc.id, npc.value[1], npc.value[2], npc.value[3], npc.value[4]);
        end
        for _, player in pairs(v.players) do
            print('      ', 'player', player.pid, player.value[1], player.value[2], player.value[3], player.value[4]);
        end
    end
end

local function WaitForEvent(event)
    local co = coroutine.running();
    local function callback(event, ...)
        utils.EventManager.getInstance().removeListener(event, callback);
        coroutine.resume(co, event, ...);
    end

    utils.EventManager.getInstance().addListener(event, callback);
    return coroutine.yield();
end

return {
    Get      = GetBattle,
    Interact = Interact,
    Start    = StartBattle,
    DUMP     = Dump,
}