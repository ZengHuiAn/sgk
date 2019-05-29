local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Time = require "module.Time"
local playerModule = require "module.playerModule"

local C_GUILD_GRABWAR_APPLY_REQUEST = 3405  --决赛报名    
local C_GUILD_GRABWAR_APPLY_RESPOND = 3406

local C_GUILD_GRABWAR_QUERY_REQUEST = 3403  --查询决赛信息    
local C_GUILD_GRABWAR_QUERY_RESPOND = 3404

local C_GUILD_GRABWAR_ENTER_REQUEST = 3395  --进入资源点
local C_GUILD_GRABWAR_ENTER_RESPOND = 3396

local C_GUILD_MAP_OWNER_QUERY_REQUEST = 3423  --查询关卡归属
local C_GUILD_MAP_OWNER_QUERY_RESPOND = 3424

local C_GUILD_GRABWAR_FETCH_BUFF_REQUEST = 3407 --拾取buff
local C_GUILD_GRABWAR_FETCH_BUFF_RESPOND = 3408

local NOTIFY_GRABWAR_PLAYERINFO_CHANGE = 3397   --玩家信息变化通知
local NOTIFY_GRABWAR_FIGHT_BEGIN = 3398         --战斗开始通知
local NOTIFY_GRABWAR_FIGHT_FINISH = 3399        --战斗结束通知
local NOTIFY_GRABWAR_SCORE_CHANGE = 3400        --分数变化通知
local NOTIFY_GRABWAR_START = 3401               --争夺战开始通知
local NOTIFY_GRABWAR_FINISH = 3402              --争夺战结束通知
local NOTIFY_GRABWAR_BUFF_GENERATE = 3410       --buff生成通知
local NOTIFY_GRABWAR_BUFF_DISAPPEAR = 3409      --buff消失
local NOTIFY_GRABWAR_BUFF_IS_FETCHING = 3447    --buff拾取
local NOTIFY_MAP_OWNER_CHANGE = 3466            --关卡占领者改变

local function ON_SERVER_RESPOND(id, callback)
    EventManager.getInstance():addListener("server_respond_" .. id, callback);
end

local function ON_SERVER_NOTIFY(id, callback)
    EventManager.getInstance():addListener("server_notify_" .. id, callback);
end

local GuildGrabWarInfo = {};
local Sn2Data = {};

function GuildGrabWarInfo.New(id)
    return setmetatable({
        id = id,
        war_info = {},
        player_info = {},
        buff_info = {},
        point_info = {},
        sea_info = {},
        group_winner = {},
        final_winner = -1,
    }, {__index = GuildGrabWarInfo});
end

function GuildGrabWarInfo:Apply()
    NetworkService.Send(C_GUILD_GRABWAR_APPLY_REQUEST);
end

function GuildGrabWarInfo:Query()
    -- print("查询争夺战决赛", self.id, debug.traceback())
    local sn = NetworkService.Send(C_GUILD_GRABWAR_QUERY_REQUEST, {nil, self.id});
    Sn2Data[sn] = {id = self.id};
    if coroutine.isyieldable() then
        Sn2Data[sn].co = coroutine.running();
        coroutine.yield();
    end
end

function GuildGrabWarInfo:Enter(pos)
    print("进入资源点", pos)
    local sn = NetworkService.Send(C_GUILD_GRABWAR_ENTER_REQUEST, {nil, pos});
    Sn2Data[sn] = pos;
end

function GuildGrabWarInfo:GetBuff(uuid)
    print("捡buff", uuid)
    NetworkService.Send(C_GUILD_GRABWAR_FETCH_BUFF_REQUEST, {nil, uuid});
end

function GuildGrabWarInfo:UpdateWarInfo(data)
    local war_info = {};
    war_info.attacker_gid = data[1];
    war_info.defender_gid = data[2];
    war_info.attacker_score = data[3];
    war_info.defender_score = data[4];
    war_info.finish_time = data[5];
    -- war_info.next_time_to_refresh_buff =  data[6] or 0;
    self.war_info = war_info;
    DispatchEvent("GUILD_GRABWAR_WARINFO_CHANGE", self.id);
end

function GuildGrabWarInfo:UpdatePlayerInfo(v)
    local player_info = {};
    player_info.pid = v[1];
    player_info.enter_time = v[2];
    player_info.next_time_to_fight = v[3];
    player_info.next_time_to_born = v[4];
    player_info.last_pos = self.player_info[v[1]] and self.player_info[v[1]].pos or 0;
    player_info.pos = v[5];
    player_info.last_score = self.player_info[v[1]] and self.player_info[v[1]].score or 0;
    player_info.score = v[6];
    player_info.is_attacker = v[7];
    player_info.fight_time = v[8];
    player_info.last_status = self.player_info[v[1]] and self.player_info[v[1]].status or 0;
    player_info.status = (Time.now() > player_info.next_time_to_born) and 1 or 0;
    player_info.buffs = {};
    if v[9] then
        for i,j in ipairs(v[9]) do
            local buff = {};
            buff.uuid = j[1];
            buff.id = j[2];
            buff.type = j[3];
            buff.effect_type = j[4];
            buff.effect_value = j[5];
            player_info.buffs[i] = buff;
        end
    end
    player_info.time = v[10];
    player_info.win_count = v[11];
    self.player_info[v[1]] = player_info;
    return player_info;
end

function GuildGrabWarInfo:UpdateBuffInfo(v)
    local buff_info = {};
    buff_info.uuid = v[1];
    buff_info.id = v[2];
    buff_info.type = v[3];
    buff_info.effect_type = v[4];
    buff_info.effect_value = v[5];
    buff_info.pos = v[6];
    self.buff_info[v[1]] = buff_info;
end

function GuildGrabWarInfo:UpdatePointInfo(data)
    print("资源点数据", sprinttb(data))
    self.point_info = {};
    for i,v in ipairs(data) do
        local point_info = {};
        point_info.type = v[1];
        point_info.pos = {v[2], v[3], v[4]};
        self.point_info[i] = point_info;
    end
    DispatchEvent("GUILD_GRABWAR_POINTINFO_CHANGE");
end

function GuildGrabWarInfo:Clear()
    self.war_info = {};
    self.player_info = {};
    self.buff_info = {};
    self.final_winner = -1;
end

function GuildGrabWarInfo:GetWarInfo()
    return self.war_info;
end

function GuildGrabWarInfo:GetPointInfo()
    return self.point_info;
end

function GuildGrabWarInfo:GetBuffInfo(uuid)
    if uuid then
        return self.buff_info[uuid];
    end
    return self.buff_info;
end

function GuildGrabWarInfo:GetPlayerInfo(pid)
    if pid then
        return self.player_info[pid];
    end
    return self.player_info;
end

local cur_map = 0;
local GuildGrabWarManager = {};
local function GetGuildGrabWarInfo(id)
    id = id or SceneStack.CurrentSceneID();
    if GuildGrabWarManager[id] == nil then
        GuildGrabWarManager[id] = GuildGrabWarInfo.New(id);
    end
    return GuildGrabWarManager[id];
end

local function SetCurMap(id)
    cur_map = id;
end

ON_SERVER_RESPOND(C_GUILD_GRABWAR_APPLY_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    print("报名返回", sprinttb(data))    
    if result ~= 0 then
        return;
    end
end)

ON_SERVER_RESPOND(C_GUILD_GRABWAR_QUERY_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    print("查询争夺战决赛返回", Sn2Data[sn] and Sn2Data[sn].id, sprinttb(data))    
    if result ~= 0 then
        if Sn2Data[sn] then
            DispatchEvent("GUILD_GRABWAR_QUERY_FAILED", Sn2Data[sn].id);
            if Sn2Data[sn].co then
                coroutine.resume(Sn2Data[sn].co);
            end
        end
        return;
    end
    local war_info = data[3];
    local info = GetGuildGrabWarInfo(war_info[9]);
    info:UpdateWarInfo(war_info);
    if war_info[6] and #war_info[6] > 0 then
        for i,v in ipairs(war_info[6]) do
            info:UpdatePlayerInfo(v);
        end
        DispatchEvent("GUILD_GRABWAR_PLAYERINFO_REFRESH", war_info[9]);
    end
    if war_info[7] and #war_info[7] > 0 then
        for i,v in ipairs(war_info[7]) do
            info:UpdateBuffInfo(v);
        end
        DispatchEvent("GUILD_GRABWAR_BUFFINFO_REFRESH", war_info[9]);
    end
    if war_info[8] then
        info:UpdatePointInfo(war_info[8]);
    end
    if war_info[10] == 1 then
        info.final_winner = info.war_info.attacker_gid;
    elseif war_info[10] == 2 then
        info.final_winner = info.war_info.defender_gid;
    else
        info.final_winner = war_info[10];
    end
    if Sn2Data[sn] and Sn2Data[sn].co then
        coroutine.resume(Sn2Data[sn].co);
    end
end)


ON_SERVER_RESPOND(C_GUILD_GRABWAR_ENTER_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        if result == 1011 then
            print("捡buff不能进点")
        end
        print("进入资源点失败", result)    
        return;
    end
    DispatchEvent("GUILD_GRABWAR_ENTER_POINT", Sn2Data[sn]);
    -- print("进入资源点成功", sprinttb(data))  
end)

ON_SERVER_RESPOND(C_GUILD_GRABWAR_FETCH_BUFF_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        if result == 1009 then
            showDlgError(nil, "这个buff已经有人在捡了")
        elseif result == 1010 then
            print("正在战斗不能捡buff")
        elseif result == 1011 then
            print("不能同时捡2个buff")
        elseif result == 2 then
            showDlgError(nil, "你身上已经有这个buff了")
        end
        print("获取buff失败", result)    
        return;
    end
    print("获取buff成功", sprinttb(data))  
end)

ON_SERVER_NOTIFY(NOTIFY_GRABWAR_PLAYERINFO_CHANGE, function ( event, cmd, data )
    -- print("争夺战玩家信息推送",sprinttb(data))
    local info = GetGuildGrabWarInfo(data[12]);
    local player_info = info:UpdatePlayerInfo(data)
    DispatchEvent("GUILD_GRABWAR_PLAYERINFO_CHANGE", {player_info = player_info, map_id = data[12]});
end)
ON_SERVER_NOTIFY(NOTIFY_GRABWAR_FIGHT_BEGIN, function ( event, cmd, data )
    print("争夺战战斗开始",sprinttb(data))
    local info = {};
    info.attacker_pid = data[1];
    info.defender_pid = data[2];
    info.map_id = data[3];
    DispatchEvent("GUILD_GRABWAR_FIGHT_START", info);
end)
ON_SERVER_NOTIFY(NOTIFY_GRABWAR_FIGHT_FINISH, function ( event, cmd, data )
    print("争夺战战斗结束",sprinttb(data))
    local info = {};
    info.attacker_pid = data[1];
    info.defender_pid = data[2];
    info.winner = data[data[3]];
    info.map_id = data[4];
    DispatchEvent("GUILD_GRABWAR_FIGHT_END", info);
end)
ON_SERVER_NOTIFY(NOTIFY_GRABWAR_SCORE_CHANGE, function ( event, cmd, data )
    -- print("分数变化通知",sprinttb(data))
    local info = GetGuildGrabWarInfo(data[3]);
    if info.war_info and info.war_info.attacker_score and info.war_info.defender_score then
        local delta = {side = 0, score = 0, map_id = data[3]};
        if data[1] == 1 then
            delta.side = 1;
            delta.score = data[2] - info.war_info.attacker_score or 0;
            info.war_info.attacker_score = data[2];
        elseif data[1] == 2 then
            delta.side = 2;
            delta.score = data[2] - info.war_info.defender_score or 0;
            info.war_info.defender_score = data[2];
        end
        DispatchEvent("GUILD_GRABWAR_SCORE_CHANGE", delta);
    end
end)
ON_SERVER_NOTIFY(NOTIFY_GRABWAR_FINISH, function ( event, cmd, data )
    print("争夺战结束通知",sprinttb(data))
    local info = GetGuildGrabWarInfo(data[2]);
    info.final_winner = data[1];
    DispatchEvent("GUILD_GRABWAR_FINISH", {map_id = data[2], winner = data[1]});
end)
ON_SERVER_NOTIFY(NOTIFY_GRABWAR_START, function ( event, cmd, data )
    print("争夺战开始通知",sprinttb(data))
    local info = GetGuildGrabWarInfo(data[7]);
    info:Clear();
    info:UpdateWarInfo(data)
    info:UpdatePointInfo(data[6]);
end)
ON_SERVER_NOTIFY(NOTIFY_GRABWAR_BUFF_GENERATE, function ( event, cmd, data )
    -- print("buff生成通知",sprinttb(data))
    local info = GetGuildGrabWarInfo(data[7]);
    info:UpdateBuffInfo(data)
    DispatchEvent("GUILD_GRABWAR_BUFFINFO_CHANGE", {uuid = data[1], map_id = data[7]});
end)
ON_SERVER_NOTIFY(NOTIFY_GRABWAR_BUFF_DISAPPEAR, function ( event, cmd, data )
    print("buff消失通知",sprinttb(data))
    local info = GetGuildGrabWarInfo(data[2]);
    info.buff_info[data[1]] = nil;
    DispatchEvent("GUILD_GRABWAR_BUFF_DISAPPEAR", {uuid = data[1], map_id = data[2]});
end)
ON_SERVER_NOTIFY(NOTIFY_GRABWAR_BUFF_IS_FETCHING, function ( event, cmd, data )
    print("buff拾取通知",sprinttb(data))
    local info = {};
    info.uuid = data[1];
    info.take_effect_time = data[2];
    info.pid = data[3];
    info.type = data[4];
    info.map_id = data[5];
    DispatchEvent("GUILD_GRABWAR_BUFF_IS_FETCHING", info);
end)
ON_SERVER_NOTIFY(NOTIFY_MAP_OWNER_CHANGE, function ( event, cmd, data )
    print("关卡拥有者变更", sprinttb(data))
    DispatchEvent("MAP_OWNER_CHANGE", {map_id = data[1], guild_id = data[2]});
end)

return{
    Get = GetGuildGrabWarInfo,
    SetCurMap = SetCurMap,
}