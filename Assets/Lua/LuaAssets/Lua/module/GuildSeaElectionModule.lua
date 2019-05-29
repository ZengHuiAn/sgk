local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Time = require "module.Time"

local C_GUILD_GRABWAR_SEA_ELECTION_APPLY_REQUEST = 3419 --海选报名
local C_GUILD_GRABWAR_SEA_ELECTION_APPLY_RESPOND = 3420

local C_GUILD_GRABWAR_SEA_ELECTION_QUERY_REQUEST = 3421 --查询海选信息
local C_GUILD_GRABWAR_SEA_ELECTION_QUERY_RESPOND = 3422

local NOTIFY_SEA_ELECTION_BEGIN = 3413          --海选开始
local NOTIFY_GUILD_APPLY_FOR_SEA_ELECTION = 3414 --报名通知
local NOTIFY_SEA_ELECTION_GROUP_FIGHT_FINISH = 3415 --军团之间的战斗结束
local NOTIFY_SEA_ELECTION_GROUP_WINNER = 3416   --小组冠军产生
local NOTIFY_SEA_ELECTION_FINAL_WINNER = 3417   --海选冠军产生

local function ON_SERVER_RESPOND(id, callback)
    EventManager.getInstance():addListener("server_respond_" .. id, callback);
end

local function ON_SERVER_NOTIFY(id, callback)
    EventManager.getInstance():addListener("server_notify_" .. id, callback);
end

local GuildSeaElectionInfo = {};
local Sn2Data = {};

function GuildSeaElectionInfo.New(type)
    return setmetatable({
        type = type,
        sea_info = {},
        detail_report = {},
    }, {__index = GuildSeaElectionInfo});
end

function GuildSeaElectionInfo:SeaElectionApply()
    print("海选报名", self.type)
    NetworkService.Send(C_GUILD_GRABWAR_SEA_ELECTION_APPLY_REQUEST, {nil, self.type});
end

function GuildSeaElectionInfo:SeaElectionQuery()
    -- print("查询海选", self.type, debug.traceback())
    local sn = NetworkService.Send(C_GUILD_GRABWAR_SEA_ELECTION_QUERY_REQUEST, {nil, self.type});
    if coroutine.isyieldable() then
        Sn2Data[sn] = {co = coroutine.running()}
        coroutine.yield();
    end
end

function GuildSeaElectionInfo:GetSeaInfo()
    return self.sea_info;
end

function GuildSeaElectionInfo:GetDetailRecord(idx)
    return self.detail_report[idx];
end

function GuildSeaElectionInfo:CalculateReport(idx, info)
    self.detail_report[idx] = {};
    local Calculate = function ()
        if self.detail_report[idx].atk_mcount and self.detail_report[idx].def_mcount then
            self.detail_report[idx].time_line = {};
            local cur_atk_mcount, cur_def_mcount = self.detail_report[idx].atk_mcount, self.detail_report[idx].def_mcount;
            local time = Time.now();
            local index, flag = 0, 0;
            repeat
                for i=1,2 do
                    index = index + 1;
                    if info.detail_record[index] then
                        if info.detail_record[index][3] == 1 then
                            cur_def_mcount = cur_def_mcount - 1;
                            if info.detail_record[index][4] == 3 then
                                cur_atk_mcount = cur_atk_mcount - 1;
                            end
                        else
                            cur_atk_mcount = cur_atk_mcount - 1;
                            if info.detail_record[index][4] == 3 then
                                cur_def_mcount = cur_def_mcount - 1;
                            end
                        end
                    end
                end
                flag = flag + 1;
                self.detail_report[idx].time_line[time + flag] = {cur_atk_mcount = cur_atk_mcount, cur_def_mcount = cur_def_mcount}
            until info.detail_record[index + 1] == nil
            self.detail_report[idx].end_time = time + flag;
            DispatchEvent("SEA_ELECTION_DETAIL_REPORT_CHANGE", self.sea_info.map_id);
        end
    end
    coroutine.resume(coroutine.create(function ()
        local attacker_guild = utils.Container("UNION"):Get(info.side1);
        self.detail_report[idx].atk_mcount = attacker_guild.mcount;
        Calculate()
    end))
    coroutine.resume(coroutine.create(function ()
        local defender_guild = utils.Container("UNION"):Get(info.side2);
        self.detail_report[idx].def_mcount = defender_guild.mcount;
        Calculate()
    end))
end

function GuildSeaElectionInfo:UpdateSeaInfo(data)
    local sea_info = {};
    sea_info.map_id = data[1];
    sea_info.apply_list = {};
    for i,v in ipairs(data[2]) do
        table.insert(sea_info.apply_list, v);
    end
    sea_info.groupA = {};
    for i,v in ipairs(data[3]) do
        local info = {};
        info.gid = v[1];
        info.win_count = v[2];
        info.lose_count = v[3];
        table.insert(sea_info.groupA, info);
    end
    sea_info.groupB = {};
    for i,v in ipairs(data[4]) do
        local info = {};
        info.gid = v[1];
        info.win_count = v[2];
        info.lose_count = v[3];
        table.insert(sea_info.groupB, info);
    end
    sea_info.type = data[5];
    sea_info.apply_begin_time = data[6];
    sea_info.apply_end_time = data[7];
    sea_info.fight_begin_time = data[8];
    sea_info.final_begin_time = data[9];
    sea_info.refresh_time = data[10];
    sea_info.groupA_winer = data[11];
    sea_info.groupB_winer = data[12];
    sea_info.final_winer = data[13];
    sea_info.next_fight_time = data[15];
    sea_info.report = {};
    if data[14] then
        for i,v in ipairs(data[14]) do
            local info = {};
            info.side1 = v[1];
            info.side2 = v[2];
            info.winner = v[3];
            info.detail_record = v[4];
            table.insert(sea_info.report, info)
        end
    end
    self.sea_info = sea_info;
    DispatchEvent("GUILD_GRABWAR_SEAINFO_CHANGE");
end

local GuildSeaElectionManager = {};
local function GetGuildSeaElectionInfo(type)
    type = type or 1;
    if GuildSeaElectionManager[type] == nil then
        GuildSeaElectionManager[type] = GuildSeaElectionInfo.New(type);
    end
    return GuildSeaElectionManager[type];
end

ON_SERVER_RESPOND(C_GUILD_GRABWAR_SEA_ELECTION_APPLY_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    print("海选报名返回", sprinttb(data))    
    if result ~= 0 then
        return;
    end
    DispatchEvent("GUILD_SEA_ELECTION_APPLY_SUCCESS", data[1]);
end)

ON_SERVER_RESPOND(C_GUILD_GRABWAR_SEA_ELECTION_QUERY_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    print("查询海选返回", sprinttb(data))    
    if result ~= 0 then
        return;
    end
    if data[3] then
        local info = GetGuildSeaElectionInfo(data[3][5]);
        info:UpdateSeaInfo(data[3])
    end
    if Sn2Data[sn] and Sn2Data[sn].co then
        coroutine.resume(Sn2Data[sn].co);
    end
end)
ON_SERVER_NOTIFY(NOTIFY_SEA_ELECTION_BEGIN, function ( event, cmd, data )
    print("海选开始通知",sprinttb(data))
    local info = GetGuildSeaElectionInfo(data[1][5]);
    info:UpdateSeaInfo(data[1])
    DispatchEvent("GUILD_SEA_ELECTION_START")
end)
ON_SERVER_NOTIFY(NOTIFY_GUILD_APPLY_FOR_SEA_ELECTION, function ( event, cmd, data )
    print("海选报名通知",sprinttb(data))
    local info = GetGuildSeaElectionInfo(data[2]);
    if info.sea_info and info.sea_info.apply_list then
        table.insert(info.sea_info.apply_list, data[1]);
    end
    DispatchEvent("GUILD_APPLY_FOR_SEA_ELECTION", data[1]);
end)
ON_SERVER_NOTIFY(NOTIFY_SEA_ELECTION_GROUP_FIGHT_FINISH, function ( event, cmd, data )
    print("<color=#FF0000FF>军团之间的战斗结束通知</color>",sprinttb(data));
    local info = GetGuildSeaElectionInfo(data[4]);
    if info.sea_info.report then
        local _info = {};
        _info.side1 = data[1];
        _info.side2 = data[2];
        _info.winner = data[3];
        _info.detail_record = data[6];
        info:CalculateReport(#info.sea_info.report + 1, _info)
        -- table.insert(info.sea_info.report, _info)
        DispatchEvent("SEA_ELECTION_GROUP_FIGHT_FINISH", _info);
    end
    info:SeaElectionQuery();
end)
ON_SERVER_NOTIFY(NOTIFY_SEA_ELECTION_GROUP_WINNER, function ( event, cmd, data )
    print("海选小组冠军产生",sprinttb(data));
    local info = GetGuildSeaElectionInfo(data[3]);
    info:SeaElectionQuery();
    info.sea_info.groupA_winer = data[1];
    info.sea_info.groupB_winer = data[2];
end)
ON_SERVER_NOTIFY(NOTIFY_SEA_ELECTION_FINAL_WINNER, function ( event, cmd, data )
    print("海选冠军产生",sprinttb(data));
    local info = GetGuildSeaElectionInfo(data[2]);
    info:SeaElectionQuery();
    info.sea_info.final_winer = data[1];
end)
EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, cmd, data)
    for i=1,3 do
        local info = GetGuildSeaElectionInfo(i);
        info:SeaElectionQuery();
    end
end)

local function GetAllSeaElectionInfo(refresh, map_id)
    local allInfo = nil;
    for i=1,3 do
        local info = GetGuildSeaElectionInfo(i);
        if info.sea_info.map_id == nil or refresh or Time.now() > info.sea_info.refresh_time then
            info:SeaElectionQuery();
        end
        if info.sea_info.map_id then
            if map_id then
                if info.sea_info.map_id == map_id then
                    allInfo = info;
                    break;
                end
            else
                allInfo = allInfo or {};
                allInfo[info.sea_info.map_id] = info:GetSeaInfo();
            end
        end
    end
    return allInfo;
end

local function CheckAlreadyApply(map_id)
    local uninInfo = module.unionModule.Manage:GetSelfUnion();
    if uninInfo and uninInfo.id then
        local cityInfo = module.BuildScienceModule.QueryScience(map_id);
        local owner = cityInfo and cityInfo.title or 0;
        if owner == uninInfo.id then
            return 2;
        else
            local allInfo = GetAllSeaElectionInfo();
            if allInfo[map_id] and allInfo[map_id].apply_begin_time ~= -1 then
                for i,v in ipairs(allInfo[map_id].apply_list) do
                    if v == uninInfo.id then
                        return 1;
                    end
                end
                return 0;
            else
                return 0;
            end
        end
    else
        return 0;
    end 
end

local function Apply(map_id)
    local info = GetAllSeaElectionInfo(false, map_id);
    if info then
        if Time.now() < info.sea_info.apply_end_time then
            info:SeaElectionApply();
        else
            showDlgError(nil, "报名已结束")
        end
    end
end

local function CheckApplyTime()
    local memberInfo = module.unionModule.Manage:GetSelfInfo()
    if memberInfo == nil or memberInfo.title ~= 1 then
        return false;
    end
    local allInfo = GetAllSeaElectionInfo() or {};
    for k,v in pairs(allInfo) do
        if Time.now() < v.apply_begin_time or Time.now() >= v.apply_end_time then
            print("开始时间", os.date("%Y-%m-%d  %H:%M:%S",math.floor(v.apply_begin_time)))
            return false;
        end
        local flag = CheckAlreadyApply(v.map_id);
        if flag ~= 0 then
            return false;
        end
    end
    return true;
end

local function CheckGrabWarStatus(id)
    local status = 0; --0没有比赛信息 1报名未开始 2正在报名 3报名结束未开始战斗 4正在进行海选比赛 5正在进行决赛 6比赛结束  7无人参赛
    local allInfo = GetAllSeaElectionInfo() or {};
    local getGrabWarStatus = function (map_id)
        local warInfo = module.GuildGrabWarModule.Get(map_id);
        local cityInfo = module.BuildScienceModule.QueryScience(map_id);
        if warInfo.final_winner ~= -1 then
            status = 6
        elseif allInfo[map_id].apply_begin_time > Time.now() then	--尚未到报名时间
            status = 1;
        elseif allInfo[map_id].apply_end_time > Time.now() then
            status = 2;
        elseif allInfo[map_id].fight_begin_time > Time.now() then
            status = 3;
        elseif #allInfo[map_id].apply_list == 0 then
            status = 7;
        elseif #allInfo[map_id].apply_list == 1 and (cityInfo and cityInfo.title == 0 or cityInfo.title == allInfo[map_id].apply_list[1]) then --没人占领的城市，只有一个公会报名
            status = 6
        elseif allInfo[map_id].final_begin_time > Time.now() then
            status = 4;
        else
            status = 5;
        end
        return status
    end
    if id then
        status = getGrabWarStatus(id)
    else
        for map_id,v in pairs(allInfo) do
            if v.apply_begin_time ~= -1 then
                status = getGrabWarStatus(map_id);
                break;
            end
        end
    end
    return status;
end

local function CheckFightTime()
    local allInfo = GetAllSeaElectionInfo() or {};
    for k,v in pairs(allInfo) do
        local flag = CheckAlreadyApply(v.map_id);
        if flag ~= 0 then
            local status = CheckGrabWarStatus(v.map_id);
            print("争夺战状态", status)
            if status >= 3 and status <= 5 then
                return true;
            else
                return false;
            end
        end
    end
    return false;
end

local function OpenGrabWarFrame()
    local status = -1;
    local apply,apply_map = false, 0;
    local allInfo = GetAllSeaElectionInfo() or {};
    for k,v in pairs(allInfo) do
        if status == -1 then
            status = CheckGrabWarStatus(v.map_id);
        end
        local flag = CheckAlreadyApply(v.map_id);
        if flag ~= 0 then
            apply = true;
            apply_map = v.map_id;
            status = CheckGrabWarStatus(v.map_id);
        end
    end
    if status == 2 then
        DialogStack.Push("guildGrabWar/guildGrabWarApply")
    elseif apply then
        if status == 3 or status == 4 then
            DialogStack.Push("guildGrabWar/guildGrabWarReport", {map_id = apply_map, type = 1, pop = true})
        elseif status == 5 then
            DialogStack.Push("guildGrabWar/guildGrabWarReport", {map_id = apply_map, type = 2, pop = true})
        end
    end
    return status;
end

local function CanApply()
    local uninInfo = module.unionModule.Manage:GetSelfUnion();
    local memberInfo = module.unionModule.Manage:GetSelfInfo()
    if uninInfo and uninInfo.id and memberInfo and  memberInfo.title == 1 then
        local allInfo = GetAllSeaElectionInfo();
        if allInfo then
            for k,v in pairs(allInfo) do
                local flag = CheckAlreadyApply(v.map_id)
                if flag ~= 0 then
                    return flag;
                end
            end
            return 0
        end
    end
    return -1;
end

return{
    Get = GetGuildSeaElectionInfo,
    GetAll = GetAllSeaElectionInfo,
    CheckApply = CheckAlreadyApply,
    Apply = Apply,
    CheckApplyTime = CheckApplyTime,
    CanApply = CanApply,
    CheckGrabWarStatus = CheckGrabWarStatus,
    OpenGrabWarFrame = OpenGrabWarFrame,
    CheckFightTime = CheckFightTime,
}