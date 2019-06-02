local NetworkService = require "utils.NetworkService"
local EventManager = require "utils.EventManager"
local Time = require "module.Time"
local playerModule = require "module.playerModule"
local Property = require "utils.Property"
local UserDefault = require "utils.UserDefault";
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local MapConfig = require "config.MapConfig"


-- prepare
local C_TEAM_INPLACE_CHECK_REQUEST = 18130  -- {sn}
local C_TEAM_INPLACE_CHECK_RESPOND = 18131  -- {sn, result}

local C_TEAM_INPLACE_READY_REQUEST = 18132  -- {sn}
local C_TEAM_INPLACE_READY_RESPOND = 18133  -- {sn, result}

local NOTIFY_TEAM_INPLACE_CHECK = 16005  -- {}
local NOTIFY_TEAM_INPLACE_READY = 16006  -- {pid}

-- in fight
local NOTIFY_TEAM_ADD_MONSTER = 16007  -- {data}
local NOTIFY_TEAM_MONSTER_SYNC = 16008  -- {data}

local C_TEAM_SYNC_REQUEST = 18140  -- {sn, type, data}
local C_TEAM_SYNC_RESPOND = 18141  -- {sn, result}

local teamInfo = nil;
local Sn2Data = {};
local waiting_thread = {}

local function getTeamInfo()
    if teamInfo == nil then
        teamInfo = { id = -1, group = 0, members = {}, waiting = {}, chat = {}, leader = {}, afk_list = {},invite = nil}
        NetworkService.Send(16064, {})
        NetworkService.Send(18110, {});
    end

    if teamInfo.id < 0 and coroutine.isyieldable() and waiting_thread then
        waiting_thread[#waiting_thread+1] = coroutine.running();
        coroutine.yield();
    end

    return teamInfo;
end

local function getTeamMembers(type)
    if type then
        local members = getTeamInfo().members
        local list = {}
        if type == 1 then--剔除afk玩家
            for i = 1,#members do
                if module.TeamModule.getAFKMembers(members[i].pid) ~= true and module.MapModule.GetPlayerStatus(members[i].pid) == 0 then
                    list[#list+1] = members[i]
                end
            end
            return list
        end
    end
    return getTeamInfo().members;
end

local function getAFKMembers(pid)
    if pid then
        local list = getTeamInfo().afk_list
        if list[pid] then
            return true
        end
        return false
    end
    return getTeamInfo().afk_list
end


local function getTeamWaitingList()
    return getTeamInfo().waiting;
end

local function getTeamChatLog()
    return getTeamInfo().chat;
end

local function getTeamApply()--申请列表
    local list = {}
    for k,v in pairs(getTeamInfo().waiting)do
        list[#list + 1] = v
    end
    return list;
end

local function getTeamInvite()--邀请列表
    if not getTeamInfo() or getTeamInfo().invite == nil then
        NetworkService.Send(18154);
        return {}
    end
    local list = {}
    if getTeamInfo() and getTeamInfo().invite then
        for k,v in pairs(getTeamInfo().invite)do
            list[#list + 1] = v
        end
    end
    return list;
end

local teamGroup = {}
local function updateTeamGroup(id, group, member_count, leader_pid, leader_name, joinRequest,lower_limit,upper_limit,member_id)
    teamGroup[group] = teamGroup[group] or {time = 0, teams = {}};

    if member_count == 0 then
        teamGroup[group].teams[id] = nil;
    else
        teamGroup[group].teams[id] = {
                id = id, member_count = member_count,member_id = member_id,
                leader = { pid = leader_pid, name = leader_name},
                joinRequest = joinRequest or false,
                lower_limit = lower_limit,
                upper_limit = upper_limit,
        };
    end
end

local function HeroData(code)
    if code then
        local info = ProtobufDecode(code, "com.agame.protocol.FightPlayer")
        local heros = {}
        -- ERROR_LOG(sprinttb(info.roles))
        for k, v in ipairs(info.roles) do
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
                --combat = capacity,
            }

            local t = {}
            for _, vv in ipairs(v.propertys) do
                t[vv.type] = vv.value
            end
            heros[k].property = Property(t);
        end
        return heros
    else
        -- print("玩家编队信息数据为空！")
        return nil;
    end
end

local Is_NewMember = false
local function updateTeamInfo(data)
    if data[1] == 0 then
        -- print("player have no team");

        if teamInfo and teamInfo.id > 0 and teamGroup[teamInfo.group] then
            teamGroup[teamInfo.group][teamInfo.id] = nil;
        end

        teamInfo = {id = 0, group = 0, members = {}, waiting = {}, chat = {},afk_list = {}}
        EventManager.getInstance():dispatch("TEAM_INFO_CHANGE", teamInfo);
        EventManager.getInstance():dispatch("TEAM_MEMBER_CHANGE");
        return;
    end
    if Is_NewMember then
        Is_NewMember = false
        DispatchEvent("Add_team_succeed",{pid = module.playerModule.GetSelfID()})--加入小队
        module.CemeteryModule.RestTEAMRecord()
    end

    teamInfo = {
        id = data[1],
        group = data[2],
        -- leader = nil,
        auto_confirm = data[4],
        members = {},
        waiting = {},
        chat = {},
         auto_match = data[7],
         team_status = data[8],
        lower_limit = data[9],
        upper_limit = data[10],
        is_checking_ready = data[11],
        afk_list = {},
    }
    -- ERROR_LOG("teamInfo->>>"..sprinttb(data))
    for i, v in ipairs(data[5]) do
        local player = {
            pid = v[1],
            pos = v[2],
            level = v[3],
            name = v[4],
            heros = {},
            is_ready = v[6],
        };
        player.heros = HeroData(v[5])
        -----------------------------
        -- local info = {roles = {}} -- ProtobufDecode(v[5], "com.agame.protocol.FightPlayer")
        -- --local heros = {}
        -- for k, v in ipairs(info.roles) do
        --     player.heros[k] = {
        --         id = v.id,
        --         level = v.level,
        --         mode = v.mode,
        --         skills = v.skills,
        --         equips = v.equips,
        --         uuid = v.uuid,
        --     }

        --     local t = {}
        --     for _, vv in ipairs(v.propertys) do
        --         t[vv.type] = vv.value
        --     end
        --     player.heros[k].property = Property(t);
        -- end
        -----------------------------

        if module.playerModule.IsDataExist(player.pid) then
            player.level = module.playerModule.IsDataExist(player.pid).level
            --ERROR_LOG(">"..player.level)
        else
            module.playerModule.Get(player.pid,(function( ... )
                player.level =  module.playerModule.IsDataExist(player.pid).level
                teamInfo.members[i] = player;
            end))
        end
        teamInfo.members[i] = player;
        teamInfo.afk_list[player.pid] = false
        if player.pid == data[3] then
            teamInfo.leader = player;
        end
        -- ERROR_LOG("========>>>查询到队友PID",player.pid);
    end
    -- ERROR_LOG(sprinttb(data[12]))
    if data[12] then
        for i = 1,#data[12] do
            teamInfo.afk_list[data[12][i]] = true
        end
    end
    for i, v in ipairs(data[6]) do
        local player = { pid = v[1], level = v[2], name = v[3]};
        teamInfo.waiting[player.pid] = player;
        module.playerModule.GetFightData(v[1])--获取申请人数据
        local _player = module.playerModule.IsDataExist(v[1])
        if _player then
            if _player.honor == 9999 then
                module.TeamModule.ConfiremTeamJoinRequest(v[1]);
            end
        else
            module.playerModule.Get(v[1],function( ... )
                if module.playerModule.IsDataExist(v[1]).honor == 9999 then
                    module.TeamModule.ConfiremTeamJoinRequest(v[1]);
                end
            end)
        end
    end

    for _, group in pairs(teamGroup) do
        for _, v in pairs(group.teams) do
            v.joinRequest = false
        end
    end

    local vote_info = {
        inplace = {}, -- 就位确认投票
        leader  = {},  -- 申请队长投票
    }

    if type(data[11]) == "table" then
        if data[11][1] then
            vote_info.inplace.end_time = data[11][1][1];
            vote_info.inplace.type     = data[11][1][2];
            vote_info.inplace.members  = data[11][1][3] or {};

            teamInfo.is_checking_ready = vote_info.inplace.end_time;

            for k, v in ipairs(vote_info.inplace.members or {}) do
                teamInfo.members[k].is_ready = v;
            end
        end

        if data[11][2] then
            vote_info.leader.end_time = data[11][2][1];
            vote_info.leader.pid      = data[11][2][2];
            vote_info.leader.members  = data[11][2][3] or {};
        end
    end
    teamInfo.vote_info = vote_info;
    if #data > 0 and module.playerModule.GetSelfID() ~= teamInfo.leader.pid then

        -- ERROR_LOG("查询队长位置 ----战斗");
        module.TeamModule.QueryLeaderInfo(); --查询队长位置
    end
    EventManager.getInstance():dispatch("TEAM_INFO_CHANGE", teamInfo);
    EventManager.getInstance():dispatch("TEAM_MEMBER_CHANGE");
    EventManager.getInstance():dispatch("TEAM_LIST_CHANGE");
    EventManager.getInstance():dispatch("TEAM_JOIN_REQUEST_CHANGE");
end

local function updateTeamMemberLevel(pid,lv)
    for k,v in pairs (teamInfo.members) do
        if v.pid == pid then
            teamInfo.members[k].level = lv
            break
        end
    end

    -- ERROR_LOG("更新玩家",pid);
    EventManager.getInstance():dispatch("updateTeamMember");
end

local function getTeamList(group, refresh)
    if teamGroup[group] == nil then
        teamGroup[group] = {time = 0, teams = {} }
    end

    local diff = refresh and 10 or (60 * 5);
    if teamGroup[group].time + diff < Time.now() then
        teamGroup[group].time = Time.now();
        NetworkService.Send(18112, {nil, group});
    end
    return teamGroup[group].teams;
end


local Invites = nil;
local function SendReQuestInvite(team_id,status,func)
    local sn = NetworkService.Send(18156,{nil,team_id,status});
    Invites = Invites or {};
    Invites[sn] = func;
end


EventManager.getInstance():addListener("server_respond_18113", function(event, cmd, data)

    -- ERROR_LOG("server_respond_18113",sprinttb(data));

    if data[2] ~= 0 then
        -- print("load team list failed")
        return;
    end
    -- ERROR_LOG("server_respond_18113",sprinttb(data))
    local group = data[3];

    teamGroup[group] = {time = Time.now(), teams = {} };

    for _, v in ipairs(data[4]) do
        updateTeamGroup(v[1], group, v[2], v[3], v[4], v[5],v[6],v[7],v[8]);
    end

    EventManager.getInstance():dispatch("TEAM_LIST_CHANGE", group);
end)

local createTeamSN = {}
local function createTeam(group,Fun,level1,level2)
    if not teamInfo then
        -- print("loading team info")
        return;
    end

    if teamInfo.id ~= 0 then
        -- print("already in a team");
        return false;
    end
    local StackList = SceneStack.GetStack()
    StackList = StackList[#StackList]
    level1 = level1 or 1
    level2 = level2 or 80
    if StackList.savedValues.mapType and (StackList.savedValues.mapType == 1 or StackList.savedValues.mapType == 4) then
        --showDlg(nil,"创建队伍后将离开当前场景",function()
            local sn = NetworkService.Send(18114, {nil, group})--创建队伍
            createTeamSN[sn] = Fun
            NetworkService.Send(18184, {nil,level1,level2})
        --end,function()end)
    else
        local sn = NetworkService.Send(18114, {nil, group})--创建队伍
        createTeamSN[sn] = Fun
        NetworkService.Send(18184, {nil,level1,level2})
    end
end

local TeamChangeDlgTime = 0
local function TeamChangeDlg(type)
    local Time = require "module.Time"
    if TeamChangeDlgTime + 2 < Time.now() then
        TeamChangeDlgTime = Time.now()
        if type == 1 then
            showDlgError(nil,SGK.Localize:getInstance():getValue("team_1"))
        elseif type == 2 then
            showDlgError(nil,SGK.Localize:getInstance():getValue("team_2"))
        end
    end
end

EventManager.getInstance():addListener("server_respond_18115", function(event, cmd, data)
    -- ERROR_LOG("server_respond_18115",sprinttb(data));
    if data[2] ~= 0 then
        -- print("create team failed")
        return;
    end
    if createTeamSN[data[1]] then
        createTeamSN[data[1]]()
        createTeamSN[data[1]] = nil
    end
    --创建队伍成功
    TeamChangeDlg(1)
    --[[
    local StackList = SceneStack.GetStack()
    StackList = StackList[#StackList]
    --ERROR_LOG(StackList.savedValues.mapType)
    if StackList.savedValues.mapType and (StackList.savedValues.mapType == 1 or StackList.savedValues.mapType == 4) then
        SceneStack.EnterMap(10)
    end
    --]]
    DispatchEvent("create_team_succeed")
    -- updateTeamInfo(data[3]);
end)

local sn2teamid = {}
local function joinTeam(teamid)
    if not teamInfo then
        -- print("loading team info")
        return;
    end

    if teamInfo.id ~= 0 then
        -- print("already in a team")
        return;
    end
    if SceneStack.GetBattleStatus() then
        showDlgError(nil,"正在战斗中，无法进行该操作")
        return
    end
    local sn = NetworkService.Send(18116, {nil, teamid})
    sn2teamid[sn] = teamid;
end

EventManager.getInstance():addListener("server_respond_18117", function(event, cmd, data)
    -- ERROR_LOG("server_respond_18117",sprinttb(data));
    local sn = data[1];
    local teamid = sn2teamid[sn];
    sn2teamid[sn] = nil;

    if data[2] == 0 then
        for _, group in pairs(teamGroup) do
            for _, v in pairs(group.teams) do
                -- print("--", v.id)
                if v.id == teamid then
                    v.joinRequest = true;
                    --EventManager.getInstance():dispatch("TEAM_LIST_CHANGE");
                end
            end
        end
        showDlgError(nil,"申请成功")
    elseif data[2] == 52 then
        showDlgError(nil,"不符合队伍所需等级")
    else
        showDlgError(nil,"加入队伍失败")
    end
    EventManager.getInstance():dispatch("LOCAL_TEAM_JOIN_CHANGE")
end);

local confiremTeamJoinRequest_sn = {}
local function confiremTeamJoinRequest(pid)
    if not teamInfo then
        -- print("loading team info")
        return;
    end

    if teamInfo.id <= 0 then
        -- print("not in a team")
        return;
    end

    if not teamInfo.waiting[pid] then
        -- print("player not waiting")
        return;
    end

    if teamInfo.leader.pid ~= playerModule.GetSelfID() then
        -- print("not leader")
        return;
    end
    local sn = NetworkService.Send(18118, {nil, pid})
    confiremTeamJoinRequest_sn[sn] = pid
    return sn
end

EventManager.getInstance():addListener("server_respond_18119", function(event, cmd, data)
    -- ERROR_LOG("server_respond_18119",sprinttb(data));
    --审批玩家申请
    -- ERROR_LOG("18119",sprinttb(data))
    local sn = data[1]
    if data[2] == 0 then
        DispatchEvent("JOIN_CONFIRM_REQUEST")
    elseif data[2] == 11 then--权限不足
        showDlgError(nil,"权限不足")
    elseif data[2] == 3 then--不在申请类表
        showDlgError(nil,"不在申请类表")
    elseif data[2] == 824 then--已经有队伍
        showDlgError(nil,"该玩家已经有队伍了")
    elseif data[2] == 1 then--加入队伍失败
        showDlgError(nil,"加入队伍失败")
    elseif data[2] == 9 then
        showDlgError(nil,"队伍人数已满")
    elseif data[2] == 1007 then
        showDlgError(nil,"该玩家不在线")
    end
    if data[2] ~= 1 then
        local pid = confiremTeamJoinRequest_sn[sn]
        module.TeamModule.delApply(pid)
    end
end);

local function findTeamMember(pid)
    if not teamInfo then
        -- print("loading team info")
        return;
    end

    for k, v in ipairs(teamInfo.members) do
        if v.pid == pid then
            return k, v;
        end
    end
end

local kickTeamMember_Tips = true
local function kickTeamMember(pid)
    if not teamInfo then
        -- print("loading team info")
        return;
    end

    pid = pid or playerModule.GetSelfID();

    if teamInfo.id <= 0 then
        -- print("not in a team")
        return;
    end

    if pid ~= playerModule.GetSelfID() and teamInfo.leader.pid ~= playerModule.GetSelfID() then
        -- print("not leader")
        return;
    end

    if  not findTeamMember(pid) then
        -- print('player not in you team')
        return;
    end
    if pid == playerModule.GetSelfID() then
        kickTeamMember_Tips = false
    else
        kickTeamMember_Tips = true
    end
    local sn = NetworkService.Send(18120, {nil, pid})
    Sn2Data[sn] = pid;
    return;
end

EventManager.getInstance():addListener("server_respond_18121", function(event, cmd, data)

    -- ERROR_LOG("server_respond_18121",sprinttb(data));
    local sn = data[1];
    if data[2] == 0 then
        DispatchEvent("kICKTEAMSUCCESS", Sn2Data[sn]);
    end
end);

local function chatToTeam(msg, type)
    if not teamInfo then
        -- print("loading team info")
        return;
    end

    type = type or 0;
    if teamInfo.id <= 0 then
        -- print("not in a team")
        return;
    end
    return NetworkService.Send(18122, {nil, type, msg})
end

EventManager.getInstance():addListener("server_respond_18123", function(event, cmd, data)

    ERROR_LOG("server_respond_18123",sprinttb(data));
    if data[2] ~= 0 then
        showDlgError(nil,"发送失败")
    end
end)

local function setTeamAutoConfirm(b)
    if not teamInfo then
        -- print("loading team info")
        return;
    end

    if teamInfo.id <= 0 then
        -- print("not in a team")
        return;
    end

    if teamInfo.leader.pid ~= playerModule.GetSelfID() then
        -- print("not leader")
        return;
    end

    teamInfo.auto_confirm = b;
    NetworkService.Send(18124, {nil, b})
end

--[[
EventManager.getInstance():addListener("server_respond_18125", function(event, cmd, data)
end);
--]]
local delApplySN = {}
local function delApply( pid )
    --删除申请
    --ERROR_LOG(pid)
    local sn = NetworkService.Send(18150,{nil,pid})
    delApplySN[sn] = pid
end

EventManager.getInstance():addListener("server_respond_18151", function(event, cmd, data)
    print("18151->"..sprinttb(data))
    if data[2] ~= 0 then
        showDlgError(nil,"删除申请人失败")
        return
    end
    if delApplySN[data[1]] then
        if delApplySN[data[1]] == 0 then
            --全部删除
            teamInfo.waiting = {}
        else
            teamInfo.waiting[delApplySN[data[1]]] = nil
        end
        delApplySN[data[1]] = nil
    end
    DispatchEvent("delApply_succeed")
end)

local playerMatchingType = 0--是否匹配中
local function GetplayerMatchingType()
    return playerMatchingType
end

local playerMatchingSN = {}
local function playerMatching(groupId)
    --玩家匹配
    local sn = NetworkService.Send(18158,{nil,groupId})
    playerMatchingSN[sn] = groupId
end

EventManager.getInstance():addListener("server_respond_18159", function(event, cmd, data)
    print("玩家开启(关闭)自动匹配18159->"..sprinttb(data))
    if data[2] ~= 0 then
        showDlgError(nil,"匹配失败")
        return
    end
    if playerMatchingSN[data[1]] then
        playerMatchingType = playerMatchingSN[data[1]]
        playerMatchingSN[data[1]] = nil
    end
    DispatchEvent("playerMatching_succeed",{auto_match_success = data[3]})
end)

--local TeamMatchingSN = {}
local function TeamMatching(open)
    --队伍匹配
    NetworkService.Send(18160,{nil,open})
    --local sn = NetworkService.Send(18160,{nil,open})
    --TeamMatchingSN[sn] = open
end

EventManager.getInstance():addListener("server_respond_18161", function(event, cmd, data)
    ERROR_LOG("18161->",sprinttb(data))
    -- if data[2] ~= 0 then
    --     showDlgError(nil,"队伍匹配失败")
    --     return
    -- end
    -- if TeamMatchingSN[data[1]] ~= nil then
    --     teamInfo.auto_match = TeamMatchingSN[data[1]]
    --     TeamMatchingSN[data[1]] = nil
    -- end
    -- DispatchEvent("TeamMatching_succeed")
end)

EventManager.getInstance():addListener("server_notify_18160", function(event, cmd, data)
    --队伍匹配通知
    ERROR_LOG("server_notify_18160",sprinttb(data))
    teamInfo.auto_match = data[1]
    DispatchEvent("TeamMatching_succeed")
end)

local Invite_List = {}
local function GetInvite_List(id)
    if id then
        return Invite_List[id]
    end
    return Invite_List
end

local function invitePlayer(pid)
    Invite_List[pid] = true
    NetworkService.Send(18152, {nil, pid});
end

EventManager.getInstance():addListener("server_respond_18153", function(event, cmd, data)
    if data[2] == 0 then
        showDlgError(nil,"邀请已发送")
    elseif data[2] == 824 then
        showDlgError(nil,"该玩家已在队伍中")
    else
        showDlgError(nil,"对方已有队伍")
        --showDlgError(nil,"邀请失败"..data[2])
    end
end)

local function watchTeamGroup(group)
    NetworkService.Send(18126, {nil, group})
end
local sync_flag = nil;
local function syncTeamData(type, msg)
    if not teamInfo and type >= 300 then
        -- print("loading team info")
        return;
    end

    if teamInfo.id <= 0 then
        -- print("not in a team")
        return;
    end

    if type == 201 then
        if msg[1] == 1 then
            sync_flag = true;
        else
            if not sync_flag then
                return ;
            end
            sync_flag = nil;
        end
    end
    -- ERROR_LOG();
    NetworkService.Send(18140, {nil, type, msg})
end

local function syncFightData(type, msg)
    NetworkService.Send(16040, {nil, type, msg})
end

local function memberIsReady(pid)
    pid = pid or playerModule.GetSelfID();
    local _, player = findTeamMember(pid);
    return player and player.is_ready;
end

local function memberSetReady(pid, ready)
    pid = pid or playerModule.GetSelfID();
    local _, player = findTeamMember(pid);
    if player and player.is_ready ~= ready then
        player.is_ready = ready;
        return true;
    end
end

local function readyToFight(ready)
    if not teamInfo then
        -- print("loading team info")
        return;
    end

    if teamInfo.id <= 0 then
        -- print("not in a team")
        return;
    end

    if teamInfo.leader.pid == playerModule.GetSelfID() and not teamInfo.is_checking_ready then
        if teamInfo.is_checking_ready then
            -- print("checking");
            return
        end
        teamInfo.is_checking_ready = true;
        NetworkService.Send(18130, {});
    else
        if not teamInfo.is_checking_ready then
            -- print("not checking");
            return
        else
            if memberIsReady() == ready then
                -- print("ready status not change")
                return;
            end
            NetworkService.Send(18132, {nil, ready});
        end
    end
end
local FightCallback = nil


local function getCallBack()
   return FightCallback;
end

local function GetAfkStatus(pid)
    if not pid then
        pid = module.playerModule.GetSelfID();
    end
    if teamInfo.afk_list then
        return teamInfo.afk_list[math.floor(pid)]
    end

end

local function GetFirstMember()
    local _members = getTeamMembers(1);

    local selfPid = module.playerModule.GetSelfID();

    for i=1,#_members do
        if _members[i].pid ~= selfPid then
            return _members[i];
        end
    end
end

local function MoveHeaderToMember(pid)
    --如果当前队员状态为暂离
    if GetAfkStatus( pid ) == true then
        return 1;
    end

    -- print("send  18180  and "..pid);
    NetworkService.Send(18180, {nil,pid})
end

local function NewReadyToFight(Type,callback)
    FightCallback = callback;
    --Type0就位确认1战前确认
    NetworkService.Send(18130, {nil,Type});
end

local is_first_query_team = nil;


local function ResumeTeamFight()

    if is_first_query_team then
        syncFightData(10);
        is_first_query_team = nil
    end
end

EventManager.getInstance():addListener("server_respond_18111", function(event, cmd, data)
    if data[2] ~= 0 then
        -- print("query team info failed")
        teamInfo = nil;

        local _last_waiting_thread = waiting_thread;
        waiting_thread = {};

        for _, co in ipairs(_last_waiting_thread) do
            coroutine.resume(co);
        end

        return;
    end

    updateTeamInfo(data[3]);
    module.CemeteryModule.RestTEAMRecord()
    utils.SGKTools.SynchronousPlayStatus({6,module.playerModule.GetSelfID(),0})--0无自由，1自由
    if teamInfo and teamInfo.id >= 0 then
        -- if is_first_query_team then
        --     syncFightData(10); -- 恢复团队/PVP战斗
        -- end
        is_first_query_team = true
    end
    -- is_first_query_team = false;

    local _last_waiting_thread = waiting_thread;
    waiting_thread = {};

    for _, co in ipairs(_last_waiting_thread) do
        coroutine.resume(co);
    end
end);

local _AFK_callback = nil;
local function TEAM_AFK_REQUEST(AFK_callback,pid)--AFK
    _AFK_callback = AFK_callback;
    -- ERROR_LOG("暂离=====================", debug.traceback());
    NetworkService.Send(18292, {nil,pid});
end

EventManager.getInstance():addListener("server_respond_18293", function(event, cmd, data)
    -- ERROR_LOG("暂离回调","server_respond_18293",sprinttb(data))
    local sn = data[1]
    local err = data[2]
    if _AFK_callback then
        -- print("暂离回调错误号",err);
        _AFK_callback(err);
    end

    if err == 0 then
        print("队伍信息",sprinttb(getTeamInfo()));
    else
        showDlgError(nil,"暂离进入失败")
    end
end)

local AFK_TEAM_CALL = nil
local function TEAM_AFK_RESPOND(func)--AFK回归
    local sn = NetworkService.Send(18294);

    AFK_TEAM_CALL = func;
end

EventManager.getInstance():addListener("server_respond_18295", function(event, cmd, data)

    -- ERROR_LOG("回归队伍","server_respond_18295",sprinttb(data))

    if AFK_TEAM_CALL then
        AFK_TEAM_CALL(data[2]);
        AFK_TEAM_CALL = nil;
    end
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        ERROR_LOG("回归后，查询队长位置");
        -- module.TeamModule.QueryLeaderInfo();

    else
        showDlgError(nil,"暂离解除失败")
    end
    -- ERROR_LOG("18295",sprinttb(data))
end)

EventManager.getInstance():addListener("server_notify_18289", function(event, cmd, data)

    -- ERROR_LOG("server_notify_18289",sprinttb(data))
    for i = 1,#data do
        teamInfo.afk_list[data[i]] = true
        DispatchEvent("TEAM_INFO_CHANGE")
        DispatchEvent("NOTIFY_TEAM_PLAYER_AFK_CHANGE",{pid = data[i],type = true})
    end
    -- ERROR_LOG("AFK_18289",sprinttb(data))
end)

EventManager.getInstance():addListener("server_notify_18290", function(event, cmd, data)
    -- ERROR_LOG("server_notify_18290",sprinttb(data))
    for i = 1,#data do
        teamInfo.afk_list[data[i]] = false;
        DispatchEvent("TEAM_INFO_CHANGE")
        DispatchEvent("NOTIFY_TEAM_PLAYER_AFK_CHANGE",{pid = data[i],type = false})
    end
    -- ERROR_LOG("AFK_BACK_18290",sprinttb(data))
end)
-- local C_TEAM_INPLACE_CHECK_RESPOND = 18131  -- {sn, result}
EventManager.getInstance():addListener("server_respond_18131", function(event, cmd, data)
    -- print("就位确认------------------------->>>>>>>>>>");
    if not teamInfo then
        -- print("loading team info")
        return;
    end

    if teamInfo.id <= 0 then
        -- print("not in a team")
        return;
    end

    if data[2] ~= 0 then
        teamInfo.is_checking_ready = false;
        -- print("start check ready failed")
        return;
    end

    -- print("就位确认------------------------->>>>>>>>>>");
    teamInfo.is_checking_ready = true;


end);

local function PlayerReady(ready,Type)
    --0待确认1已确认2已拒绝 Type0就位确认1战前确认2队长申请确认
    -- print("PlayerReady>"..ready)
    NetworkService.Send(18132, {nil, ready,Type})
end
-- local C_TEAM_INPLACE_READY_RESPOND = 18133 -- {sn, result}
EventManager.getInstance():addListener("server_respond_18133", function(event, cmd, data)
    if not teamInfo then
        -- print("loading team info")
        return;
    end

    if teamInfo.id <= 0 then
        -- print("not in a team")
        return;
    end

    if data[2] ~= 0 then
        -- print("ready failed")
    end
end);

local ExtraSpoilsCount = nil
local function ExtraSpoils()
    if ExtraSpoilsCount == nil then
        NetworkService.Send(16064, {nil});
        return {0,0}--1小怪，2boss
    end
    return ExtraSpoilsCount
end

EventManager.getInstance():addListener("server_respond_16065", function(event, cmd, data)
    --查询小怪R点次数
    -- ERROR_LOG("!"..sprinttb(data))
    if data[2] == 0 then
        ExtraSpoilsCount = {}
        ExtraSpoilsCount[1] = data[3]
        ExtraSpoilsCount[2] = data[4]
        DispatchEvent("TEAM_QUERY_NPC_ROLL_COUNT_REQUEST")
    end
end)

EventManager.getInstance():addListener("server_respond_16073", function(event, cmd, data)
    -- ERROR_LOG("查询小怪掉落奖励16073->",sprinttb(data))
    if data[2] == 0 then
        DispatchEvent("TEAM_QUERY_NPC_REWARD_REQUEST",{reward_content = data[3]})
    end
end)
--[=[
EventManager.getInstance():addListener("server_respond_16041", function(event, cmd, data)
    if data[2] == 50 then
        if utils.SceneStack.CurrentSceneName() == "battle" then
            --[[
            showDlg(nil,"战斗已经结束",function()
                utils.SceneStack.Pop();
            end,nil,'退出')
            --]]
        end
    end
end);
--]=]

EventManager.getInstance():addListener("server_respond_16071", function(event, cmd, data)
    -- print("开始战斗16071->"..sprinttb(data))
    if data[2] == 0 then
        SetTipsState(false)--暂时关闭物品获取提示和升级提示
    else
        DispatchEvent("TEAM_BATTLE_START_ERROR")
    end
end)

EventManager.getInstance():addListener("server_respond_18157", function(event, cmd, data)
   -- ERROR_LOG("回复小队邀请18157->"..sprinttb(data))
   Invites = Invites or {};
    if Invites[data[1]] then   
        Invites[data[1]](data[2]);
        Invites[data[1]] = nil;
   end
    if data[2] == 0 then
        DispatchEvent("TEAM_PLAYER_REPLY_INVITATION_REQUEST")

        ERROR_LOG("回复小队邀请查询队伍");
        module.TeamModule.QueryLeaderInfo();

    else
        DispatchEvent("TEAM_PLAYER_REPLY_INVITATION_REQUEST_ERROR")
        showDlgError(nil,"队伍已解散")
        NetworkService.Send(18154);
    end
end)

EventManager.getInstance():addListener("server_respond_18181", function(event, cmd, data)
   -- print("改变小队队长请求->18181"..sprinttb(data))
end)

EventManager.getInstance():addListener("server_notify_16008", function(event, cmd, data)
    --小怪奖励掉落通知
    -- print("小怪奖励掉落通知->"..sprinttb(data))
    --if ExtraSpoilsCount and ExtraSpoilsCount > 0 then
    --    ExtraSpoilsTips(nil,data[1],data[2],data[3])
    --end
    --DialogStack.PushPrefStact("ExtraSpoils")--暂时关闭，不由怪物死亡触发
end)

local RollSetGidSn = {}
local function RollSetGid(gid,k,k1,k2)
    local sn = NetworkService.Send(16062,{nil,gid});
    RollSetGidSn[sn] = {k,k1,k2}
end

EventManager.getInstance():addListener("server_respond_16063", function(event, cmd, data)
    --roll小怪奖励
    -- ERROR_LOG("roll小怪奖励",sprinttb(data))
    if data[2] == 0 then
        --showDlgError(nil,"获得"..data[3][1][2].."->"..data[3][1][3].."个")
        if data[3] and next(data[3])~=nil then
            DispatchEvent("TEAM_DRAW_NPC_REWARD_REQUEST",{Itemid = data[3][1][2],ItemCount = data[3][1][3],Ks = RollSetGidSn[data[1]]})
            NetworkService.Send(16064, {nil});
            NetworkService.Send(16072);--R完奖励后重新查询奖励，用来关闭大厅按钮
        end
    else
        showDlgError(nil,"货币不足")
    end
end)

EventManager.getInstance():addListener("server_respond_16077", function(event, cmd, data)
    -- ERROR_LOG("公共奖励roll请求16077",sprinttb(data))
    if data[2] == 0 then
        DispatchEvent("TEAM_ROLL_GAME_ROLL_REQUEST",{sn = data[1]})
    end
end)

local Fight_Reward = {}
local function GetFightReward()
    local rewards = Fight_Reward
    Fight_Reward = {}
    return rewards
end

EventManager.getInstance():addListener("server_notify_16009", function(event, cmd, data)
    --小队副本战斗奖励活动通知
    --ERROR_LOG("小队副本战斗奖励活动通知",sprinttb(data))
    Fight_Reward = data[1]
end)
-- NOTIFY_TEAM_INPLACE_CHECK = 18130  -- {}

local fightIndex = 1
local function GetFightIndex()
    return fightIndex
end

EventManager.getInstance():addListener("server_respond_16067", function(event, cmd, data)
    --查询小队副本战斗胜利次数
    -- ERROR_LOG("查询个人副本战斗胜利次数"..sprinttb(data))
    -- fightIndex = 3
    -- for i =1 ,#data[3] do
    --     if data[3][i][2] == 0 then
    --         fightIndex = i
    --         break
    --     end
    -- end
    if data[2] == 0 then
        module.CemeteryModule.SetPlayerRecord(data[3])
        -- if #data[3] == 1 then
        --     module.CemeteryModule.SetPlayerRecord(data[3])
        -- else
        --     module.CemeteryModule.SetPveStateUid(data[3],data[1])
        --     module.CemeteryModule.SetTeamPveFight(data)
        -- end
    end
    --DispatchEvent("QUERY_PLAYER_FIGHT_WIN_COUNT_REQUEST",{win_count = data[3],sn = data[1]})
end)

EventManager.getInstance():addListener("server_respond_16069", function(event, cmd, data)
    --查询小队副本队伍副本进度
    -- ERROR_LOG("查询小队副本队伍副本进度"..sprinttb(data))
    -- fightIndex = 3
    -- for i =1 ,#data[3] do
    --     if data[3][i][2] == 0 then
    --         fightIndex = i
    --         break
    --     end
    -- end
    if data[2] == 0 then
        module.CemeteryModule.SetTEAMRecord(data[3])
        DispatchEvent("QUERY_PLAYER_FIGHT_WIN_COUNT_REQUEST")
        -- if #data[3] == 1 then
        --     module.CemeteryModule.SetTEAMRecord(data[3])
        -- else
        --     module.CemeteryModule.SetTEAM_PveStateUid(data[3],data[1])
        --     DispatchEvent("QUERY_TEAM_PROGRESS_REQUEST",{win_count = data[3]})
        -- end
    end
end)

EventManager.getInstance():addListener("server_respond_16087", function(event, cmd, data)
    -- ERROR_LOG("怪物NPC进度16087->"..sprinttb(data))
    if data[2] == 0 then
        --DispatchEvent("update_monster_schedule")
    end
end)

EventManager.getInstance():addListener("server_respond_18185", function(event, cmd, data)
    --设置队伍等级限制
    if data[2] == 0 then
       TeamChangeDlg(2)
    else
        showDlgError(nil,"设置队伍等级限制 错误",data[2])
    end
end)

EventManager.getInstance():addListener("server_notify_18111", function(event, cmd, data)
    --队伍等级限制改变通知
    if teamInfo then
        --ERROR_LOG("server_notify_18111",data[1],data[2])
        if teamInfo.lower_limit and teamInfo.upper_limit then
            if teamInfo.lower_limit ~= data[1] or teamInfo.upper_limit ~= data[2] then
                if data[1] > 0 and data[2] > 0 then
                    --showDlgError(nil,"队长调整队伍等级限制 "..data[1].." - "..data[2].." 级")
                else
                    --showDlgError(nil,"队长调整队伍等级无限制")
                end
            end
        end
        teamInfo.lower_limit = data[1]
        teamInfo.upper_limit = data[2]
        EventManager.getInstance():dispatch("TEAM_INFO_CHANGE");
    end
end)

EventManager.getInstance():addListener("server_notify_16041", function(event, cmd, data)
    -- ERROR_LOG("怪物NPC进度16041->"..sprinttb(data))
    module.CemeteryModule.SetPlayerRecord({{data[1],1}})
    module.CemeteryModule.SetTEAMRecord({{data[1],1}})
    DispatchEvent("update_monster_schedule",{gid = data[1]})--通知队伍中的其他玩家，队长对话击败怪物
end)

EventManager.getInstance():addListener("server_notify_16011", function(event, cmd, data)
    -- print("小队状态变化通知18111->"..sprinttb(data))
end)

EventManager.getInstance():addListener("server_notify_18104", function(event, cmd, data)
    --队伍聊天通知
    -- print("队伍聊天通知"..sprinttb(data))
    local ChatManager = require 'module.ChatModule'
    local name = ""
    for i = 1, #getTeamInfo().members do
        if getTeamInfo().members[i].pid == data[1] then
            name = getTeamInfo().members[i].name
            break
        end
    end
    if data[2] == 1 then
        ShowChatWarning(data[3])
    end
    ChatManager.SetTeamChat(data[1],name,data[3])
end)

-- local NOTIFY_TEAM_PLAYER_CHAT = 18104  -- {pid, type, msg}
EventManager.getInstance():addListener("server_notify_18104", function(event, cmd, data)
    -- print("server_notify_18104",sprinttb(data));
    if not teamInfo then
        -- print("loading team info, ignore 16004")
        return;
    end

    if teamInfo.id <= 0 then
        return;
    end

    local chatInfo = {
        pid = data[1],
        type = data[2],
        msg = data[3]
    };
    table.insert(teamInfo.chat, chatInfo)
    if #teamInfo.chat > 50 then
        table.remove(teamInfo.chat);
    end
    EventManager.getInstance():dispatch("TEAM_CHAT", chatInfo);
end);

local Roll_Query_sn = {}
local function Roll_Query(type)--0push1PushPrefStact
    local sn = NetworkService.Send(16074)
    Roll_Query_sn[sn] = type
end

local GetPubReward = {}
local function GetPubRewardData()
    return GetPubReward
end

local function SetPubRewardData(data)--用作重置清空数据
    GetPubReward = data
end

local function GetPubRewardStatus()
    -- ERROR_LOG(sprinttb(GetPubReward))
    for k,v in pairs(GetPubReward)do
        for i = 1,#v.list do
            for j = 1,#v.pids do
                if not v.RollPids or not v.RollPids[i][v.pids[j]] then
                    return true--尚未分配完成
                end
            end
            -- ERROR_LOG(sprinttb(RollPids),pids[j])
            -- if v.pids[j] == module.playerModule.GetSelfID() then
            --     local time = math.floor(v.EndTime - Time.now())
            --     if v.RollPids and v.RollPids[i] and v.RollPids[i][pids[j]] then
            --     elseif time <= 0 then
            --     else
            --         return true
            --     end
            -- end
        end
    end
    return false
end

EventManager.getInstance():addListener("server_notify_16033", function(event, cmd, data)
    --小队副本公共奖励roll点开始通知
    Roll_Query(1)
end)

local function SetPubRewardList(data)--用作存入玩家操作数据
    if not GetPubReward[data[1]] then return end
    if not GetPubReward[data[1]].desc then
        GetPubReward[data[1]].Roll = {}
        GetPubReward[data[1]].desc = {}
        GetPubReward[data[1]].RollPids = {}--roll过的人
    end
    if not GetPubReward[data[1]].desc[data[3]] then
        GetPubReward[data[1]].Roll[data[3]] = {}
        GetPubReward[data[1]].desc[data[3]] = {}
        GetPubReward[data[1]].RollPids[data[3]] = {}
    end

    if not GetPubReward[data[1]].RollPids[data[3]][data[2]] then
        local idx = #GetPubReward[data[1]].desc[data[3]]
        GetPubReward[data[1]].Roll[data[3]][idx + 1] = {gid = data[1],pid = data[2],index = data[3],point = data[4],status = data[5]}
        GetPubReward[data[1]].RollPids[data[3]][data[2]] = true
        if data[2]>0 then
            if playerModule.IsDataExist(data[2]) then
                if data[5] == 1 then
                    -- GetPubReward[data[1]].desc[data[3]][idx + 1] = playerModule.IsDataExist(data[2]).name.."投掷 <color=#FFD700FF>需求</color> "..data[4].."点"
                    GetPubReward[data[1]].desc[data[3]][idx + 1] = SGK.Localize:getInstance():getValue("fuben_touzhi_5",playerModule.IsDataExist(data[2]).name,data[4])
                elseif data[5] == 2 then
                    --GetPubReward[data[1]].desc[data[3]][idx + 1] = playerModule.IsDataExist(data[2]).name.."投掷 <color=#00FF00FF>贪婪</color> "..data[4].."点"
                    GetPubReward[data[1]].desc[data[3]][idx + 1] = SGK.Localize:getInstance():getValue("fuben_touzhi_7",playerModule.IsDataExist(data[2]).name,data[4])
                elseif data[5] == 0 then
                    --GetPubReward[data[1]].desc[data[3]][idx + 1] = playerModule.IsDataExist(data[2]).name.."选择了 <color=#F05025FF>放弃</color>"
                    GetPubReward[data[1]].desc[data[3]][idx + 1] = SGK.Localize:getInstance():getValue("fuben_touzhi_9",playerModule.IsDataExist(data[2]).name,data[4])
                else
                    --GetPubReward[data[1]].desc[data[3]][idx + 1] = playerModule.IsDataExist(data[2]).name.."无法对该道具掷点"
                    GetPubReward[data[1]].desc[data[3]][idx + 1] = SGK.Localize:getInstance():getValue("fuben_touzhi_1",playerModule.IsDataExist(data[2]).name)
                end
            else
                playerModule.Get(data[2],(function( ... )
                    if data[5] == 1 then
                        GetPubReward[data[1]].desc[data[3]][idx + 1] = SGK.Localize:getInstance():getValue("fuben_touzhi_5",playerModule.IsDataExist(data[2]).name,data[4])
                    elseif data[5] == 2 then
                        GetPubReward[data[1]].desc[data[3]][idx + 1] = SGK.Localize:getInstance():getValue("fuben_touzhi_7",playerModule.IsDataExist(data[2]).name,data[4])
                    elseif data[5] == 0 then
                        GetPubReward[data[1]].desc[data[3]][idx + 1] = SGK.Localize:getInstance():getValue("fuben_touzhi_9",playerModule.IsDataExist(data[2]).name,data[4])
                    else
                        GetPubReward[data[1]].desc[data[3]][idx + 1] = SGK.Localize:getInstance():getValue("fuben_touzhi_1",playerModule.IsDataExist(data[2]).name)
                    end
                end))
            end
        else
            local guideResultModule = require "module.GuidePubRewardAndLuckyDraw"
            local AIData = guideResultModule.GetLocalPubRewardAIData(data[2])
            if AIData then
                local name = AIData.name
                if data[5] == 1 then
                    GetPubReward[data[1]].desc[data[3]][idx + 1] = SGK.Localize:getInstance():getValue("fuben_touzhi_5",name,data[4])
                elseif data[5] == 2 then
                    GetPubReward[data[1]].desc[data[3]][idx + 1] = SGK.Localize:getInstance():getValue("fuben_touzhi_7",name,data[4])
                elseif data[5] == 0 then
                    GetPubReward[data[1]].desc[data[3]][idx + 1] = SGK.Localize:getInstance():getValue("fuben_touzhi_9",name,data[4])
                else
                    GetPubReward[data[1]].desc[data[3]][idx + 1] = SGK.Localize:getInstance():getValue("fuben_touzhi_1",name)
                end
            else
                ERROR_LOG("playerData is nil,pid",data[2])

            end
        end
        DispatchEvent("TEAM_ROLL_Notify")
    end
end

EventManager.getInstance():addListener("server_notify_16034", function(event, cmd, data)
    -- ERROR_LOG("小队副本有玩家roll公共奖励通知",sprinttb(data))
    SetPubRewardList(data)
end)

EventManager.getInstance():addListener("server_notify_16035", function(event, cmd, data)
    -- ERROR_LOG("server_notify_16035小队副本有玩家获得公共奖励通知",sprinttb(data))
    local ItemHelper = require "utils.ItemHelper"
    if data[2] ~= 0 then
        local name = ""
        for i = 1, #getTeamInfo().members do
            if getTeamInfo().members[i].pid == data[2] then
                name = getTeamInfo().members[i].name
                break
            end
        end
        local rewardInfo = GetPubReward[data[1]].list[data[3]];
        if rewardInfo then
            local ItemData = ItemHelper.Get(rewardInfo[1],rewardInfo[2])
            local ItemCount = GetPubReward[data[1]].list[data[3]][3]
            local color = "<color="..ItemHelper.QualityTextColor(ItemData.quality)..">"

            showDlgError(nil, SGK.Localize:getInstance():getValue("fuben_touzhi_11",name,ItemData.name.."x"..ItemCount))
            module.ChatModule.SetData({nil,nil,{data[2],name},0,"<color=#FFDE21>"..name.."</color>获得"..color..ItemData.name.."x"..ItemCount.."</color>",0})
        else
            ERROR_LOG("rewardInfo is nil","data[3]",data[3],"data[1]",data[1],sprinttb(GetPubReward),sprinttb(data))
        end
    else
        local rewardInfo = GetPubReward[data[1]].list[data[3]];
        local ItemData = ItemHelper.Get(rewardInfo[1],rewardInfo[2])
        local ItemCount = GetPubReward[data[1]].list[data[3]][3]
        local color = "<color="..ItemHelper.QualityTextColor(ItemData.quality)..">"
        module.ChatModule.SetData({nil,nil,{data[2],""},0,color..ItemData.name.."x"..ItemCount.."</color>已流拍",0})
    end
end)


local PubReward_fight_id = nil
local function GetTeamPveFightId(id)
    if id then
       PubReward_fight_id = id
    else
       return PubReward_fight_id
    end
end
--查询某场组队战斗玩家是否有权限Roll公共掉落
local function GetSelfCanRollPubRewardStatus()
    local status = true
    local LimitRollConsumtId = 0
    if PubReward_fight_id then
        local pve_battle_cfg = SmallTeamDungeonConf.GetTeam_pve_fight_gid(PubReward_fight_id)
        if pve_battle_cfg and pve_battle_cfg.pubilc_drop_consume_item then

            local LimitRollConsumtId = pve_battle_cfg.pubilc_drop_consume_item
            if LimitRollConsumtId then
                if module.ItemModule.GetItemCount(LimitRollConsumtId)<=0 then
                    status = false
                end
            end
        else
            ERROR_LOG("pve_battle_cfg is nil,fight_id,",PubReward_fight_id)
        end
    end
    return status
end
--data[4]0 放弃 1 需求 2贪婪 3 放弃
EventManager.getInstance():addListener("server_respond_16075", function(event, cmd, data)
    -- ERROR_LOG("16075",'fight_id',sprinttb(data))
    if data[2] == 0 then
        GetPubReward = data[3]
        if #data[3] > 0 then
            local arr = {}
            local list = {}
            for i = 1,#data[3] do
                arr[data[3][i][1]] = {list = data[3][i][3],EndTime = data[3][i][2],gid = data[3][i][1],pids = data[3][i][6],offRollPids = data[3][i][7]}
                local Roll = data[3][i][7]--不能roll的名单

                local containSelf = false
                if Roll then
                    for j = 1,#Roll do
                        for l = 1,#data[3][i][3] do
                            local gid,pid,index,point,status,uuid = data[3][i][1],Roll[j],l,-1,4,data[3][i][5]
                            list[#list+1] = {gid,pid,index,point,status,uuid}
                            if Roll[j] == module.playerModule.GetSelfID() then
                                containSelf = true
                            end
                        end
                    end
                end
                if not containSelf and not GetSelfCanRollPubRewardStatus() then
                    for l = 1,#data[3][i][3] do
                        local gid,pid,index,point,status,uuid = data[3][i][1],module.playerModule.GetSelfID(),l,-1,4,data[3][i][5]
                        list[#list+1] = {gid,pid,index,point,status,uuid}
                    end
                end
            end            

            GetPubReward = arr
            for i = 1,#list do
                SetPubRewardList(list[i])
            end
        end
        DispatchEvent("Roll_Query_Respond",data[3])
    else
        ERROR_LOG("server_respond_16075_ERROR -> "..data[2])
    end
end)

local Team_Ready_list = {}
local function GetTeam_Ready_list()
   return Team_Ready_list
end

EventManager.getInstance():addListener("server_notify_18130", function(event, cmd, data)
    if not teamInfo then
        -- print("loading team info")
        return;
    end

    if teamInfo.id <= 0 then
        -- print("not in a team")
        return;
    end

    if data == 0 then
        teamInfo.is_checking_ready = true;
    else
        teamInfo.is_checking_ready = false;
        for k, v in ipairs(teamInfo.members) do
            v.is_ready = 0;
            EventManager.getInstance():dispatch("TEAM_MEMBER_READY", false)
        end
    end
    -- print("team start check ready")
    EventManager.getInstance():dispatch("TEAM_MEMBER_READY_CHECK")
    -- print("队长发启点名通知-18130->"..sprinttb(data))
    Team_Ready_list = {}
    DialogStack.PushPref("ReadyToFight",{EndTime = data[1],gid = data[2]},UnityEngine.GameObject.FindWithTag("UITopRoot"))
end);

-- NOTIFY_TEAM_INPLACE_READY = 18132  -- {pid}
EventManager.getInstance():addListener("server_notify_18132", function(event, cmd, data)
    --玩家准备状态变化通知
    -- print("玩家准备状态变化通知-18132->"..sprinttb(data))
    if memberSetReady(data[1], data[2]) then
        EventManager.getInstance():dispatch("TEAM_MEMBER_READY", data[1])
    end
    Team_Ready_list[#Team_Ready_list+1] = {pid = data[1],ready = data[2],Type = data[3]}
    DispatchEvent("ready_Player_succeed",{pid = data[1],ready = data[2],Type = data[3]})
end)

EventManager.getInstance():addListener("server_respond_18179", function(event, cmd, data)
    -- ERROR_LOG("改变小队group请求-18179->"..sprinttb(data))
    if data[2] == 0 then
       TeamChangeDlg(2)
    else
        showDlgError(nil,SGK.Localize:getInstance():getValue("common_duiyuanpipei"))
    end
end)

EventManager.getInstance():addListener("server_notify_18110", function(event, cmd, data)
    --小队group变化通知
    ERROR_LOG("小队group变化通知-18110->"..sprinttb(data))
    teamInfo.group = data[1]
    DispatchEvent("GROUP_CHANGE")
    --local ActivityTeamlist = require "config.activityConfig"
    --showDlgError(nil,"队伍目标切换至"..ActivityTeamlist.GetActivity(teamInfo.group).name)
end)

-- local NOTIFY_TEAM_PLAYER_JOIN_REQUEST = 16001  -- {pid, level, name}
EventManager.getInstance():addListener("server_notify_18101", function(event, cmd, data)

    ERROR_LOG("server_notify_18101",sprinttb(data))

    if not teamInfo then
        -- print("loading team info, ignore 16001")
        return;
    end

    local pid, level, name = data[1], data[2], data[3];
    if data[2] == 0 then
        teamInfo.waiting[pid] = nil;
    else
        teamInfo.waiting[pid] = {
            pid = pid,
            level = level,
            name = name,
        }
    end
    module.playerModule.GetFightData(pid)--获取申请人数据
    local _player = module.playerModule.IsDataExist(pid)
    if _player then
        if _player.honor == 9999 then
            module.TeamModule.ConfiremTeamJoinRequest(pid);
        end
    else
        module.playerModule.Get(pid,function( ... )
            if module.playerModule.IsDataExist(pid).honor == 9999 then
                module.TeamModule.ConfiremTeamJoinRequest(pid);
            end
        end)
    end
    EventManager.getInstance():dispatch("TEAM_JOIN_REQUEST_CHANGE", pid);
end);

EventManager.getInstance():addListener("server_notify_18107", function(event, cmd, data)
    if not teamInfo then
        -- print("loading team info, ignore 16007")
        return;
    end
    -- print("玩家邀请通知18107->",sprinttb(data))
    --玩家邀请列表[team_id, group, leader_id, leader_name, leader_level]
    if teamInfo.invite == nil then
        teamInfo.invite = {}
    end
    local showInvite = true;
    for i = 1,#data[2] do
        if data[1] == 1 then
            teamInfo.invite[data[2][i][1]] = {
                team_id = data[2][i][1],
                group = data[2][i][2],
                leader_id = data[2][i][3],
                leader_name = data[2][i][4],
                leader_level = data[2][i][5],
                }
            module.playerModule.GetFightData(data[2][i][3])--获取邀请人数据
            local pid = data[2][i][3]
            local team_id = data[2][i][1]
            local _player = module.playerModule.IsDataExist(pid)
            if _player then
                if _player.honor == 9999 then
                    NetworkService.Send(18156,{nil,team_id,true});
                end
            else
                module.playerModule.Get(pid,function( ... )
                    if module.playerModule.IsDataExist(pid).honor == 9999 then
                        NetworkService.Send(18156,{nil,team_id,true});
                    end
                end)
            end
            if i == #data[2] then   --只给最后邀请你的玩家回复
                if SceneStack.GetBattleStatus() then    --如果收到组队邀请的时候你正在战斗中则回复对方，你在战斗中
                    showInvite = false;
                    NetworkService.Send(5009,{nil,pid,10, module.playerModule.Get().name.."正在战斗中",""})
                elseif module.guideModule.IsGuiding() then
                    showInvite = false;
                    NetworkService.Send(5009,{nil,pid,10, module.playerModule.Get().name.."正忙",""})
                end
            end
        else
            teamInfo.invite[data[2][i][1]] = nil;
        end
    end
    if data[1] == 1 and showInvite then
        -- print("邀请列表更新通知");
        DispatchEvent("TEAM_PLAYER_INVITE_LIST_CHANGE")
    end
end)

EventManager.getInstance():addListener("server_respond_18155", function(event, cmd, data)
    -- ERROR_LOG("查询玩家邀请列表18155->",sprinttb(data))
    if getTeamInfo().invite == nil then
        getTeamInfo().invite = {}
    end
    if data[2] == 0 then
        for i =1,#data[3] do
            getTeamInfo().invite[data[3][i][1]] = {
                team_id = data[3][i][1],
                group = data[3][i][2],
                leader_id = data[3][i][3],
                leader_name = data[3][i][4],
                leader_level = data[3][i][5],
            }
            module.playerModule.GetFightData(data[3][i][3])--获取邀请人数据
            local pid = data[3][i][3]
            local team_id = data[3][i][1]
            local _player = module.playerModule.IsDataExist(pid)
            if _player then
                if _player.honor == 9999 then
                    NetworkService.Send(18156,{nil,team_id,true});
                end
            else
                module.playerModule.Get(pid,function( ... )
                    if module.playerModule.IsDataExist(pid).honor == 9999 then
                        NetworkService.Send(18156,{nil,team_id,true});
                    end
                end)
            end
        end
        DispatchEvent("TEAM_PLAYER_QUERY_INVITE_REQUEST")
    end
end)

-- local NOTIFY_TEAM_PLAYER_JOIN = 16002  -- {pid, pos, level, name, {h1,h2,h3,h4,h5}}
EventManager.getInstance():addListener("server_notify_18102", function(event, cmd, data)
    ERROR_LOG("server_notify_18102->"..sprinttb(data))
    if not teamInfo then
        -- print("loading team info, ignore 16002")
        return;
    end

    local pid = data[1];

    

    if pid == playerModule.GetSelfID() then
        -- reload team info
        playerMatching(0)
        teamInfo = nil;
        getTeamInfo();
        Is_NewMember = true
        return;
    end
    local player = {
        pid = data[1],
        pos = data[2],
        level = data[3],
        name = data[4],
        heros = nil,
    };
    player.heros = HeroData(data[5])

    table.insert(teamInfo.members, player)
    EventManager.getInstance():dispatch("TEAM_MEMBER_CHANGE",player.pid);

    if teamInfo.waiting[player.pid] then
        teamInfo.waiting[player.pid] = nil;
        EventManager.getInstance():dispatch("TEAM_JOIN_REQUEST_CHANGE", player.pid);
    end
    DispatchEvent("Add_team_succeed",{pid = pid})--加入小队
    module.TeamModule.mapSetPosition(pid,nil)
    local teamInfo = module.TeamModule.GetTeamInfo()
    if teamInfo.leader.pid == playerModule.Get().id then
        if teamInfo.members and #teamInfo.members == 5 then
            --队伍满员
            if module.TeamModule.GetTeamInfo().auto_match then
                module.TeamModule.TeamMatching(false)
            end
        end
    end
    if module.playerModule.IsDataExist(pid) then
        module.ChatModule.SetTeamChat(teamInfo.leader.pid,teamInfo.leader.name,module.playerModule.IsDataExist(pid).name.."加入小队")--显示加入小队消息
    else
        module.playerModule.Get(pid,(function( ... )
            module.ChatModule.SetTeamChat(teamInfo.leader.pid,teamInfo.leader.name,module.playerModule.IsDataExist(pid).name.."加入小队")--显示加入小队消息
        end))
    end
end);

local function GetMembers(data)
    local list = {data[3],{},data[1]}
    for i, v in ipairs(data[5]) do
        local set = true
        for j = 1,#data[12] do
            if data[12][j] == v[1] then
                set = false
                break
            end
        end
        if set then
            local player = {
                pid = v[1],
                pos = v[2],
                level = v[3],
                name = v[4],
                heros = {},
                is_ready = v[6],
            };
            list[2][#list[2]+1] = player.pid
        end
    end
    return list
end

local PlayerTeamList = {}
local GetPlayerTeam_query_sn = {}
local function GetPlayerTeam(pid,status,fun)
    -- ERROR_LOG(debug.traceback())
    local Time = require "module.Time"
    if not PlayerTeamList[pid] or (PlayerTeamList[pid] and (Time.now() - PlayerTeamList[pid].time) >= 60) or status then
        local sn = NetworkService.Send(18182, {nil,pid})--查询玩家队伍信息
        -- print("查询玩家队伍信息");
        GetPlayerTeam_query_sn[sn] = {pid = pid,fun = fun}
    else
        DispatchEvent("Team_members_Request",PlayerTeamList[pid])
    end
end

EventManager.getInstance():addListener("server_respond_18183", function(event, cmd, data)
    -- 查询玩家队伍信息{leader_id, [pid],teamid}
    -- ERROR_LOG("查询玩家队伍信息 server_respond_18183->"..sprinttb(data))
    local sn = data[1]
    if data[2] == 0 and #data[3] > 0 then
        local Time = require "module.Time"
        PlayerTeamList[GetPlayerTeam_query_sn[sn].pid] = {members = GetMembers(data[3]),lower_limit = data[3][9],upper_limit = data[3][10]}
        PlayerTeamList[GetPlayerTeam_query_sn[sn].pid].time = Time.now()
        if GetPlayerTeam_query_sn[sn] == nil or GetPlayerTeam_query_sn[sn].fun == nil then
            DispatchEvent("Team_members_Request",PlayerTeamList[GetPlayerTeam_query_sn[sn].pid])
        end
    elseif #data[3] == 0 then
        PlayerTeamList[GetPlayerTeam_query_sn[sn].pid] = {members = {}}
        PlayerTeamList[GetPlayerTeam_query_sn[sn].pid].time = Time.now()
        
        if not GetPlayerTeam_query_sn[sn] or not GetPlayerTeam_query_sn[sn].func then
            DispatchEvent("Team_members_Request",PlayerTeamList[GetPlayerTeam_query_sn[sn].pid])
        end
    end
    if GetPlayerTeam_query_sn[sn].fun then
        GetPlayerTeam_query_sn[sn].fun()
        GetPlayerTeam_query_sn[sn] = nil
    end
end)

local clickTeamInfoTab = {}
local function getClickTeamInfo(pid)
    if pid then
        return PlayerTeamList[pid]
    end
    return {}
end

local MapTeamData = {}
local function GetMapTeam(Team_id)
    if Team_id then
        return MapTeamData[Team_id]
    end
    return MapTeamData
end

local function GetMapPlayerTeam(Player_pid)
    for k,v in pairs(MapTeamData) do
        for i = 1,#v[2] do
            if v[2][i] == Player_pid then
                return v[3]
            end
        end
    end
    return nil
end

local function SetMapTeam(Team_id,data)
    if Team_id then
        MapTeamData[Team_id] = data
    else
        MapTeamData = {}
    end
end

local function GetMapLeaveTeam(Team_id,leave_id)--剔除某人后的队伍数据
    local list = nil
    if Team_id and leave_id and MapTeamData[Team_id] then
        list = {MapTeamData[Team_id][1],{},MapTeamData[Team_id][3]}
        for i = 1,#MapTeamData[Team_id][2] do
            if MapTeamData[Team_id][2][i] ~= leave_id then
                list[2][#list[2]+1] = MapTeamData[Team_id][2][i]
            end
        end
    end
    return list
end

local function GetLeavePids(New_TeamList)
    local Team_id = New_TeamList[3]
    local list = {}
    if MapTeamData[Team_id] then
        for i = 1,#MapTeamData[Team_id][2] do
            list[MapTeamData[Team_id][2][i]] = true
        end
        for i = 1,#New_TeamList[2] do
            list[New_TeamList[2][i]] = false
        end
    end
    return list
end


local Query_CALL = nil;
local function QueryLeaderInfo(func,pid)
    local teamInfo = getTeamInfo();
    if not teamInfo.leader then
       return;
    end

    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(18044, {nil, pid or teamInfo.leader.pid})
    else
        local sn = NetworkService.Send(18044, {nil,pid or teamInfo.leader.pid})
        if func then
            Query_CALL = Query_CALL or {};
            Query_CALL[sn] = func;
        end
    end

end

EventManager.getInstance():addListener("server_respond_18045", function(event, cmd, data)
    --查询队长位置
    -- ERROR_LOG("查询队长位置","server_respond_18045->",sprinttb(data))
    if Query_CALL and Query_CALL[data[1]] then
        Query_CALL[data[1]](data);
        Query_CALL[data[1]] = nil;
    end


    if data[2] == 0 then
        local mapid, x, z, y, mapType, room = data[3][1], data[3][2], data[3][3], data[3][4], data[3][5], data[3][6];
        DispatchEvent("MAP_QUERY_PLAYER_INFO_REQUEST",{mapid = mapid, x = x, y = y, z = z, mapType = mapType, room = room})
    else
        ERROR_LOG("18045队伍位置错误 ",data[2])
        -- TEAM_AFK_REQUEST();
        DispatchEvent("MAP_QUERY_PLAYER_INFO_REQUEST_NULL")
    end
end)

EventManager.getInstance():addListener("server_respond_18047", function(event, cmd, data)
    --发送地图通知回调
    -- ERROR_LOG("server_respond_18047->"..sprinttb(data))
    if data[2] == 0 then
        -- print("地图炮发送完毕")
    end
end)

EventManager.getInstance():addListener("server_notify_16043", function(event, cmd, data)
    --地图通知
    ERROR_LOG("server_notify_16043->",sprinttb(data))
    local Type,_pid = data[1],data[2]
    if Type then
        if Type == 3 then--通知地图其他人有人的装扮变化
            PlayerInfoHelper.GetPlayerAddData(_pid,99,nil,true)
            DispatchEvent("LOCAL_TEAM_PLAYERADDDATE_CHANGE", _pid)
        elseif Type == 4 then
            module.playerModule.Get(_pid,nil,true)
        elseif Type == 5 then
            module.TeamModule.SetmapPlayStatus(data[2][2],data[2])
            DispatchEvent("UpdataPlayteStatus",{pid = data[2][2]})
        elseif Type == 6 then
            module.MapModule.SetPlayerStatus(_pid,data[3])
        elseif Type == 7 then--升级通知地图其他人
            module.TeamModule.SetmapPlayStatus(_pid,{Type})
            DispatchEvent("UpdataPlayteStatus",{pid = _pid})
        end
    end
    DispatchEvent("NOTIFY_MAP_SYNC",{TeamMap = data})


    local event, pid, msg = data[1], data[2], data[3];
    if event then
        DispatchEvent("MAP_CLIENT_EVENT_" .. event, pid, msg);
    end
end)

-- local NOTIFY_TEAM_CHANGE_LEADER = 18105  -- {pid, auto_confirm}
EventManager.getInstance():addListener("server_notify_18105", function(event, cmd, data)
    if not teamInfo then
        -- print("loading team info, ignore 18105")
        return;
    end
    -- if teamInfo.id ~= 0 then
    --     return;
    -- end
    -- print("队伍队长变化通知->18105"..sprinttb(data))
    local pid, auto_confirm = data[1], data[2];
    local k, player = findTeamMember(pid)
    if k then
        if kickTeamMember_Tips then
            showDlgError(nil,"<color=#FEBA01>"..player.name.."</color> 成为了新队长")
        else
            kickTeamMember_Tips = true
        end
        teamInfo.leader = player;
        teamInfo.auto_confirm = auto_confirm;
        EventManager.getInstance():dispatch("TEAM_LEADER_CHANGE");
        for i = 1,#teamInfo.members do
            if teamInfo.members[i].pid then
                module.TeamModule.mapSetPosition(teamInfo.members[i].pid,nil)
            end
        end

        if teamInfo.leader.pid ~= playerModule.GetSelfID() then
            DispatchEvent("MOVEHEADERSUCCESS");
        end
    end
end);

-- local NOTIFY_TEAM_CHANGE = 18106  -- {id,group,member_count,leader_pid,leader_name}
EventManager.getInstance():addListener("server_notify_18106", function(event, cmd, data)
    -- ERROR_LOG("server_notify_18106",sprinttb(data))
    local group = data[2];
    updateTeamGroup(data[1], data[2], data[3], data[4], data[5],nil , data[6], data[7],data[8])
    EventManager.getInstance():dispatch("TEAM_LIST_CHANGE", group);
end);

local _TeamLeaderStatus = true
local function TeamLeaderStatus(status)
    if status then
        _TeamLeaderStatus = status
    end
    return _TeamLeaderStatus
end
-- local NOTIFY_TEAM_SYNC = 18140  -- {tye, data}
EventManager.getInstance():addListener("server_notify_18140", function(event, cmd, data)
    if not teamInfo then
        -- print("loading team info, ignore 18140")
        return;
    end
    -- ERROR_LOG('TEAM_DATA_SYNC'..sprinttb(data));
    if data[2] == 100 then
        _TeamLeaderStatus = false
    elseif data[2] == 101 then
        --队员更换名字
        module.playerModule.Get(data[1]).name = data[3][1]
        for k,v in ipairs( getTeamInfo().members) do
            if v.pid == data[1] then
                v.name = data[3][1]
            end
        end
        EventManager.getInstance():dispatch("TEAM_MEMBER_CHANGE");
    elseif data[2] == 102 then
        --队员更换头像
        module.playerModule.Get(data[1]).head = data[3][1]
        EventManager.getInstance():dispatch("TEAM_MEMBER_CHANGE");
    elseif data[2] == 106 then
        DispatchEvent("Team_Emoji_receive",data[3])
    elseif data[2] == 110 then--同步队员更换阵容
        module.playerModule.SetPlayerFightDataRefresh(data[1])
        DispatchEvent("TeamMemberFormationChange",data[1])--队员阵容改变消息
    elseif data[2] == 111 then--队伍集结

        module.unionModule.queryPlayerUnioInfo(getTeamInfo().leader.pid);
        DispatchEvent("NOTIFY_TEAM_ALL_CHANGE");
    elseif data[2] == 201 then
        -- ERROR_LOG("server_notify_18140",sprinttb(data));
        data[3] = data[3] or {}; 

        if data[3][1] == 2 then
           module.guideModule.QuestGuideTipStatus = nil
        else

            module.guideModule.QuestGuideTipStatus = {id = data[3][1],npcid = data[3][2]}
        end
        DispatchEvent("NOTIFY_TEAM_GUIDE_CHANGE",module.guideModule.QuestGuideTipStatus);
    end
    DispatchEvent("TEAM_DATA_SYNC", table.unpack(data));
end)


local team_fight_notify_cache = {};
local function GetTeamFightNotifyCache()
    local t = team_fight_notify_cache;
    team_fight_notify_cache = nil;
    return t;
end

local SyncFightFlag = 0--同步战斗类型,用来标记特殊的同步战斗(Albert)
local function GetSyncFightFlag()
    local _SyncFightFlag = SyncFightFlag
    SyncFightFlag = 0
    return _SyncFightFlag
end

EventManager.getInstance():addListener("server_notify_16040", function(event, cmd, data)
    EventManager.getInstance():dispatch("FIGHT_DATA_SYNC", table.unpack(data));
    if data[1] == 1 then
        -- print("<color=red>", "Start Team Fight", "</color>");
        module.EncounterFightModule.SetCombatTYPE(0)
        module.EncounterFightModule.StartCombat(data)
        team_fight_notify_cache = {};
        SyncFightFlag = data[2] and data[2][6] or 0
        if data[3] then
            --储存多人战斗战斗Id
            PubReward_fight_id = data[3]
        end
    elseif data[1] == 7 then
        --战斗结束
        module.EncounterFightModule.CombatDataPersistence(nil)
        DispatchEvent("TeamCombatFinish")
    end

    if data[1] ~= 1 and team_fight_notify_cache then
        table.insert(team_fight_notify_cache, data);
    end
end);

--玩家移动 移动后的通知是16043
local C_MAP_MOVE_REQUEST = 18042 -- {sn, x, y, mid}
local C_MAP_MOVE_RESPOND = 18043 -- {sn, result, {{pid,x,y}, ...}};

local mapInfo = { players = {} }
local mapPlayStatus = {}
local mapMoveToData = nil
local function GetmapMoveTo()
    return mapMoveToData
end
local function GetmapPlayStatus(pid)
    return mapPlayStatus[pid]
end

local function SetmapPlayStatus(pid,value)
    mapPlayStatus[pid] = value
end

local function mapMoveTo(x, y, z, mid, mapType, room, move_style)

    -- ERROR_LOG("====",debug.traceback());
    if not mapMoveToData then
        mapMoveToData = {}
    end

    -- print("移动到对应地图",mid);

    if x and y and z then
        mapMoveToData[1] = x
        mapMoveToData[2] = y
        mapMoveToData[3] = z
        if mid and mapType then--and room then
            if mid ~= mapMoveToData[4] then
                mapPlayStatus = {}--清空当前地图玩家状态
            end
            mapMoveToData[4] = mid
            mapMoveToData[5] = mapType
            mapMoveToData[6] = room
            mapMoveToData[7] = move_style
        end
    end
    local sn = NetworkService.Send(C_MAP_MOVE_REQUEST, {nil, {x, z, y}, 0, mid, mapType, room, move_style})

end

local recover_map_id_sn = {}
EventManager.getInstance():addListener("server_respond_18043", function(event, cmd, data)

-- ERROR_LOG("server_respond_18043",sprinttb(data));
    local sn = data[1];
    local is_recovery_repspond = recover_map_id_sn[sn];
    recover_map_id_sn[sn] = nil;
    if data[2] ~= 0 then
        --showDlgError(nil,"enter map failed "..data[2])
        if data[2] == 51 and not is_recovery_repspond then
            if mapMoveToData then

                
                mapMoveTo(mapMoveToData[1], mapMoveToData[3], mapMoveToData[2],mapMoveToData[4], mapMoveToData[5], mapMoveToData[6], mapMoveToData[7]);
                recover_map_id_sn[sn] = true;
            end
        end
        return;
    end

    local players  = data[3];
    if players then
        mapInfo.players = {};
        for _, v in ipairs(players) do
            local pid, x, z, y = v[1], v[2], v[3], v[4];
            mapInfo.players[pid] = {x = x , y = y, z = z};
        end
        local oldPlayerPids = {}
        for pid,v in pairs(mapInfo.players) do
            if playerModule.GetSelfID() ~= pid then
                oldPlayerPids[#oldPlayerPids+1] = pid
            end
        end
        -- ERROR_LOG("oldPlayerPids",sprinttb(oldPlayerPids),sprinttb(mapInfo.players))

        EventManager.getInstance():dispatch("MAP_CHARACTER_REFRESH",oldPlayerPids);
    end
end);

EventManager.getInstance():addListener('server_notify_16042', function(event, cmd, data)

    -- ERROR_LOG("server_notify_16042",sprinttb(data));
    local pid, x, z, y = data[1], data[2], data[3], data[4];
    if x then
        -- ERROR_LOG("MAP_CHARACTER_MOVE",pid);
        mapInfo.players[pid] = {x = x , y = y, z = z};
        EventManager.getInstance():dispatch("MAP_CHARACTER_MOVE", pid, x, y, z);
    else

        -- ERROR_LOG("MAP_CHARACTER_DISAPPEAR",pid);
        mapInfo.players[pid] = nil;
        EventManager.getInstance():dispatch("MAP_CHARACTER_DISAPPEAR", pid);
    end
end)

local function TeamDatePro(pid,leader_id)--获取除了pid之外人的队伍列表
    if teamInfo.group ~= 0 then
        local tempArr = {}
        tempArr[1] = leader_id
        tempArr[2] = {}
        for k,v in ipairs(teamInfo.members) do
            if v.pid ~= pid then
                tempArr[2][#tempArr[2] + 1] = v.pid
            end
        end
        tempArr[3] = teamInfo.id--队伍id
        return tempArr
    end
    return {}
end
-- local NOTIFY_TEAM_PLAYER_LEAVE = 16003  -- {pid}
EventManager.getInstance():addListener("server_notify_18103", function(event, cmd, data)
    -- ERROR_LOG("server_notify_18103->"..sprinttb(data))
    if not teamInfo then
        -- print("loading team info, ignore 16003")
        return;
    end
   local pid = data[1];
    if pid == playerModule.GetSelfID() then
        --local TeamData = TeamDatePro(data[1],data[2])
        if mapMoveToData then
            mapMoveTo(mapMoveToData[1], mapMoveToData[3], mapMoveToData[2],mapMoveToData[4], mapMoveToData[5], mapMoveToData[6]);
            -- NetworkService.Send(C_MAP_MOVE_REQUEST, {nil, {mapMoveToData[1], mapMoveToData[3], mapMoveToData[2]}, 0, mapMoveToData[4], mapMoveToData[5], mapMoveToData[6]})
        end
        updateTeamInfo({0})
        DispatchEvent("Leave_team_succeed",{pid = data[1]})--自己离队
        module.CemeteryModule.Setactivityid(0)--队伍解散后重置当前队伍副本id
        return;
    end

    local k = findTeamMember(pid)
    if k then
        table.remove(teamInfo.members, k)
        teamInfo.afk_list[pid] = nil
        EventManager.getInstance():dispatch("TEAM_MEMBER_CHANGE");
        DispatchEvent("Leave_team_succeed",{pid = data[1]})--队员离队
         local teamInfo = module.TeamModule.GetTeamInfo()
        if module.playerModule.IsDataExist(data[1]) then
            module.ChatModule.SetTeamChat(teamInfo.leader.pid,teamInfo.leader.name,module.playerModule.IsDataExist(data[1]).name.."离开小队")--显示加入小队消息
        else
            module.playerModule.Get(pid,(function( ... )
                module.ChatModule.SetTeamChat(teamInfo.leader.pid,teamInfo.leader.name,module.playerModule.IsDataExist(data[1]).name.."离开小队")--显示加入小队消息
            end))
        end
    end
end);
local LeaderApply_list = {}
local LeaderApply_pid = nil
local LeaderApply_EndTime = 0
local TeamLeaderApply_Pref = nil
local function RestTeamLeaderApply_Pref()
    RestTeamLeaderApply_Pref = nil
end
local function LeaderApplySend()
    if Time.now() > LeaderApply_EndTime then
        NetworkService.Send(18272)
    else
        showDlgError(nil,math.floor(LeaderApply_EndTime - Time.now()).."秒后可再次发起投票")
    end
end
EventManager.getInstance():addListener("server_respond_18273", function(event, cmd, data)
    if data[2] == 0 then
        showDlgError(nil,"您已发出申请，等待其他人同意")
    else
        --tower11
        showDlgError(nil,"暂离成员无法申请队长")
    end
end)
local function GetLeaderApply_pid()
    return LeaderApply_pid,LeaderApply_EndTime
end

EventManager.getInstance():addListener("server_notify_18276", function(event, cmd, data)
    --有人发起投票通知
    LeaderApply_list = {}
    LeaderApply_pid = data[1]
    LeaderApply_EndTime = data[2]
    local list = {candidate = LeaderApply_pid,pid = LeaderApply_pid,agree = 1}
    LeaderApply_list[#LeaderApply_list+1] = list
    local pid = playerModule.GetSelfID();
    if teamInfo.afk_list[pid] then
        return
    end
    TeamLeaderApply_Pref = DialogStack.PushPref("TeamLeaderApply",{EndTime = LeaderApply_EndTime,pid = LeaderApply_pid},UnityEngine.GameObject.FindWithTag("UITopRoot"))
    --DispatchEvent("TEAM_APPLY_TO_BE_LEADER")
end)
local function TEAM_Leader_vote(agree)
    NetworkService.Send(18274,{nil,LeaderApply_pid,agree})
end
EventManager.getInstance():addListener("server_respond_18275", function(event, cmd, data)
    if data[2] == 0 then
        --showDlgError(nil,"投票成功")
    else
        --showDlgError(nil,"投票失败")
    end
end)
local function GetLeaderApply_list()
    return LeaderApply_list
end
EventManager.getInstance():addListener("server_notify_18278", function(event, cmd, data)
    --有人投票通知
    -- ERROR_LOG("server_notify_18278",sprinttb(data))
    local list = {candidate = data[1],pid = data[2],agree = data[3]}
    LeaderApply_list[#LeaderApply_list+1] = list
    DispatchEvent("NOTIFY_TEAM_VOTE")
end)
EventManager.getInstance():addListener("server_notify_18280", function(event, cmd, data)
    --投票结束通知
    --ERROR_LOG(data[1])
    DispatchEvent("NOTIFY_TEAM_VOTE_FINISH",{candidate = data[1]})
    LeaderApply_EndTime = 0
end)

local function ExamineTeamReady()
    --inplace = {}, -- 就位确认投票
    --leader  = {},  -- 申请队长投票
    local Time = require "module.Time"
    -- ERROR_LOG(Time.now(),sprinttb(teamInfo.vote_info))
    if teamInfo and teamInfo.vote_info then
        if teamInfo.vote_info.inplace.end_time and teamInfo.vote_info.inplace.end_time > Time.now() then
            for i=1,#teamInfo.vote_info.inplace.members do
                if teamInfo.vote_info.inplace.members[i] > 0 then
                    Team_Ready_list[#Team_Ready_list+1] = {pid = teamInfo.members[i].pid,ready = teamInfo.vote_info.inplace.members[i],Type =  teamInfo.vote_info.inplace.type}
                end
            end
            DialogStack.PushPref("ReadyToFight",{EndTime = teamInfo.vote_info.inplace.end_time,gid = teamInfo.vote_info.inplace.type},UnityEngine.GameObject.FindWithTag("UITopRoot"))
        elseif teamInfo.vote_info.leader.end_time and teamInfo.vote_info.leader.end_time > Time.now() then
            for i=1,#teamInfo.vote_info.leader.members do
                if teamInfo.vote_info.leader.members[i] >= 0 then
                    LeaderApply_list[#LeaderApply_list+1] = {candidate = teamInfo.vote_info.leader.pid,pid = teamInfo.members[i].pid,agree = teamInfo.vote_info.leader.members[i]}
                end
            end
            local pid = playerModule.GetSelfID();
            if teamInfo.afk_list[pid] then
                return
            end
            TeamLeaderApply_Pref = DialogStack.PushPref("TeamLeaderApply",{EndTime = teamInfo.vote_info.leader.end_time,pid = teamInfo.vote_info.leader.pid},UnityEngine.GameObject.FindWithTag("UITopRoot"))
        end
    end
end
local TeamPveTime = {}
local function GetTeamPveTime(gid)
    if gid then
        return TeamPveTime[gid]
    end
    return TeamPveTime
end
local function SetTeamPveTime(gid,start_time,end_time)
    TeamPveTime[gid] = {start_time = start_time,end_time = end_time}
end
local QUERY_BATTLE_TIME_REQUEST_sn = {}
local function QUERY_BATTLE_TIME_REQUEST(battle_id,fun)--查询副本是否结束
    local sn = NetworkService.Send(16281,{nil,battle_id})
    QUERY_BATTLE_TIME_REQUEST_sn[sn] = {battle_id = battle_id,fun = fun}
end
EventManager.getInstance():addListener("server_respond_16282", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        -- ERROR_LOG("16282",sprinttb(data))
        if QUERY_BATTLE_TIME_REQUEST_sn[sn] then
            TeamPveTime[QUERY_BATTLE_TIME_REQUEST_sn[sn].battle_id] = {start_time = data[3],end_time = data[4]}
            if QUERY_BATTLE_TIME_REQUEST_sn[sn].fun then
                QUERY_BATTLE_TIME_REQUEST_sn[sn].fun()
            end
            DispatchEvent("QUERY_BATTLE_TIME_REQUEST")
        end
    end
end)
local ENTER_BATTLE_REQUEST_sn = {}
local function ENTER_BATTLE_REQUEST(battle_id,mapid,pos)--开启副本进入
    local Time = require "module.Time"
    local fun = function ( ... )
        local sn = NetworkService.Send(16283,{nil,battle_id})
        ENTER_BATTLE_REQUEST_sn[sn] = {battle_id = battle_id,mapid = mapid,pos = pos}
    end
    if TeamPveTime[battle_id] then
        if TeamPveTime[battle_id].end_time == 0 or math.floor(TeamPveTime[battle_id].end_time - Time.now()) > 0 then
            fun()
        else
            module.CemeteryModule.RestCemetery(function ()
            --重置副本
                fun()
            end,battle_id)
        end
    else
        QUERY_BATTLE_TIME_REQUEST(battle_id,function ()
            ENTER_BATTLE_REQUEST(battle_id,mapid,pos)
        end)
    end

end
EventManager.getInstance():addListener("server_respond_16284", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        -- ERROR_LOG("18284",sprinttb(data))
        if ENTER_BATTLE_REQUEST_sn[sn] then
            TeamPveTime[ENTER_BATTLE_REQUEST_sn[sn].battle_id] = {start_time = data[3],end_time = data[4]}
            module.CemeteryModule.Setactivityid(ENTER_BATTLE_REQUEST_sn[sn].battle_id)

            local _battleCfg = SmallTeamDungeonConf.GetTeam_pve_fight(ENTER_BATTLE_REQUEST_sn[sn].battle_id)
            for i,v in pairs(_battleCfg.idx or {}) do
                for j,p in ipairs(v) do
                    if i == 0 then
                        coroutine.resume( coroutine.create( function ( ... )
                            SceneStack.TeamEnterMap(ENTER_BATTLE_REQUEST_sn[sn].mapid)--, {mapid = ENTER_BATTLE_REQUEST_sn[sn].mapid,pos = ENTER_BATTLE_REQUEST_sn[sn].pos})
                        end ) )
                    else
                        utils.NetworkService.Send(16070, {nil, p.gid})
                    end
                    break
                end
            end
        end
    end
end)

local function mapSetPosition(pid,data)
    mapInfo.players[pid] = data
end

local function mapGetPosition(pid)
    return mapInfo.players[pid];
end

local function mapGetPlayers()--获取地图玩家数据pid
    return mapInfo.players;
end

local function mapResetPlayers()
    mapInfo.players = {}
end

local flag =  nil

--true  可以进   nil不能进
local function CheckEnterMap(mapid,status)

    if SceneStack.GetBattleStatus() then
        return true
    end
    local info = getTeamInfo();
    --有队伍信息
    local playerinfo = playerModule.Get();
    if info.id ~= 0 then
        -- 如果自己是队长

        if info.leader.pid == playerModule.Get().id then
            local map_info = MapConfig.GetMapConf(mapid);
            if map_info.map_type == 4 then
            
                local teamInfo = getTeamInfo();
                local leader_id = teamInfo.leader.pid;

                local leaderInfo =module.unionModule.queryPlayerUnioInfo(teamInfo.leader.pid)
                local playerUnionInfo = module.unionModule.queryPlayerUnioInfo(playerModule.Get().id)
                for k,v in pairs(info.afk_list) do
                    
                    if v.pid ~= pid then
                        local memberInfo =module.unionModule.queryPlayerUnioInfo(v.pid)
                        
                        if memberInfo.haveUnion == 0 or memberInfo.unionId ~= playerUnionInfo.unionId then
                            module.playerModule.Get(v.pid,function ( _data )
                                showDlgError(nil,_data.name.."无法进地图");
                            end);
                            utils.NetworkService.SyncRequest(18292, {nil, math.floor(v.pid)});
                        end
                    end
                end

                
                return true;
            elseif playerinfo.level < (map_info.depend_level or 0) then
                for k,v in pairs(getTeamMembers()) do
                    if math.floor(v.pid) ~= math.floor(playerinfo.id) then        
                        if module.playerModule.Get(math.floor(v.pid)).level < map_info.depend_level or 0 then
                            -- ERROR_LOG("暂离玩家------------>>>>",v.pid);
                            
                            module.playerModule.Get(v.pid,function ( _data )
                                showDlgError(nil,_data.name.."无法进地图++++>>>>TeamModule");
                            end);
                            utils.NetworkService.SyncRequest(18292, {nil, math.floor(v.pid)});
                        end
                    end
                end
                -- ERROR_LOG("=======================>>>>",sprinttb(getTeamMembers()));
                return  true;
                    
            end


            return true;
        end

        -- local playerinfo = playerModule.Get();
        --自己跟随
        -- print("队伍x",info.afk_list[math.floor(playerModule.Get().id)]);

        if status or info.afk_list[math.floor(playerModule.Get().id)] == false then
            -- print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
            local map_info = MapConfig.GetMapConf(mapid);
            -- print("目标地图信息",sprinttb(map_info));

            if map_info.map_type == 1 then
                -- print("============这个地图 %s 没有等级显示",map_info.map_type);
                return true;
            end

            --公会地图
            if map_info.map_type == 4 then
            
                local teamInfo = getTeamInfo();
                -- teamInfo.leader_id
                -- ERROR_LOG("===============队伍信息",sprinttb(teamInfo));
                local leader_id = teamInfo.leader.pid;

                local leaderInfo =module.unionModule.queryPlayerUnioInfo(teamInfo.leader.pid)
                local playerInfo = module.unionModule.queryPlayerUnioInfo(playerinfo.id)

                -- ERROR_LOG("==========",sprinttb(playerInfo));
                if playerInfo and playerInfo.haveUnion ~= 0 and leaderInfo.unionId == playerInfo.unionId then
                    return true;
                else
                    -- TEAM_AFK_REQUEST()    
                    return;

                end
                return true;
            elseif playerinfo.level >= (map_info.depend_level or 0) then
                -- print("等级不足");
                -- TEAM_AFK_REQUEST();
                return  true;
                    
            end

        else
            -- print(status,"+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
        end
    elseif info.id < 1 then
    -- TEAM_AFK_REQUEST();
        -- print("当前没有队伍");
        return true;
    end
end

--记录 activityInfo界面 的 gid
local activityInfoGid = nil

local function GetActivityInfoGid(gid)
    if gid then
        activityInfoGid = gid
    else
        local _gid = activityInfoGid
        activityInfoGid = nil
        return _gid
    end
end

--外部调用的检测是否能进地图的接口




-- local function TeamEnterMap( ... )
--     -- body
-- end = 1

return {
    GetTeamInfo = getTeamInfo,
    GetTeamList = getTeamList,
    CreateTeam = createTeam,
    JoinTeam = joinTeam,
    ConfiremTeamJoinRequest = confiremTeamJoinRequest,
    KickTeamMember = kickTeamMember,
    ChatToTeam = chatToTeam,
    SetTeamAutoConfirm = setTeamAutoConfirm,
    Invite = invitePlayer,

    GetTeamMembers = getTeamMembers,
    GetTeamWaitingList = getTeamWaitingList,
    GetTeamChatLog = getTeamChatLog,

    WatchTeamGroup = watchTeamGroup,

    ReadyToFight = readyToFight,
    MemberIsReady = memberIsReady,
    SyncTeamData = syncTeamData,

    SyncFightData = syncFightData,
    GetTeamFightNotifyCache = GetTeamFightNotifyCache,

    MapMoveTo = mapMoveTo,
    mapSetPosition = mapSetPosition,
    MapGetPosition = mapGetPosition,
    MapGetPlayers = mapGetPlayers,
    mapResetPlayers = mapResetPlayers,

    delApply = delApply,
    playerMatching = playerMatching,
    GetplayerMatchingType = GetplayerMatchingType,
    TeamMatching = TeamMatching,
    NewReadyToFight = NewReadyToFight,
    PlayerReady = PlayerReady,
    ExtraSpoils = ExtraSpoils,
    RollSetGid = RollSetGid,
    GetFightReward = GetFightReward,
    GetFightIndex = GetFightIndex,

    getTeamApply = getTeamApply,
    getTeamInvite = getTeamInvite,
    GetClickTeamInfo = getClickTeamInfo,
    GetPubRewardData = GetPubRewardData,
    Roll_Query = Roll_Query,
    SetPubRewardData = SetPubRewardData,
    GetInvite_List = GetInvite_List,
    SetPubRewardList = SetPubRewardList,
    GetPubRewardStatus = GetPubRewardStatus,
    GetMapTeam = GetMapTeam,
    GetMapPlayerTeam = GetMapPlayerTeam,
    SetMapTeam = SetMapTeam,
    GetSelfCanRollPubRewardStatus = GetSelfCanRollPubRewardStatus,
    GetPlayerTeam = GetPlayerTeam,
    updateTeamMemberLevel = updateTeamMemberLevel,
    GetLeavePids = GetLeavePids,
    LeaderApplySend = LeaderApplySend,
    GetLeaderApply_list = GetLeaderApply_list,
    TEAM_Leader_vote = TEAM_Leader_vote,
    GetTeam_Ready_list = GetTeam_Ready_list,
    TeamLeaderStatus = TeamLeaderStatus,
    GetMapLeaveTeam = GetMapLeaveTeam,
    ExamineTeamReady = ExamineTeamReady,

    ENTER_BATTLE_REQUEST = ENTER_BATTLE_REQUEST,
    QUERY_BATTLE_TIME_REQUEST = QUERY_BATTLE_TIME_REQUEST,
    GetTeamPveTime = GetTeamPveTime,
    SetTeamPveTime = SetTeamPveTime,

    GetmapMoveTo = GetmapMoveTo,
    GetmapPlayStatus = GetmapPlayStatus,
    SetmapPlayStatus = SetmapPlayStatus,

    TEAM_AFK_REQUEST = TEAM_AFK_REQUEST,
    TEAM_AFK_RESPOND = TEAM_AFK_RESPOND,
    getAFKMembers = getAFKMembers,

    GetCallBack = getCallBack,
    MoveHeader = MoveHeaderToMember,
    GetAfkStatus = GetAfkStatus,
    GetFirstMember = GetFirstMember,
    CheckEnterMap = CheckEnterMap,

    --回复邀请协议回调
    SendReQuestInvite = SendReQuestInvite,
    --查询队长信息回调

    QueryLeaderInfo  = QueryLeaderInfo,
    -- CheckSelfEnterMap = CheckSelfEnterMap,

    GetSyncFightFlag = GetSyncFightFlag,
    GetTeamPveFightId = GetTeamPveFightId,

    GetActivityInfoGid = GetActivityInfoGid,

    ResumeTeamFight = ResumeTeamFight,
}
