local NetworkService = require "utils.NetworkService"
local EventManager = require 'utils.EventManager'
local heroModule = require "module.HeroModule"
local UserDefault = require "utils.UserDefault"
local playerModule = require "module.playerModule"
local openLevel = require "config.openLevel"
local GuildPVPGroupModule = require "guild.pvp.module.group"
local UserDefault = require "utils.UserDefault"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local unionConfig = require "config.unionConfig"

local unionManager = {}
local SnFunction = {}
local function errorCode(cmd, err)
    local msg = ""
    if err == 801 then
        msg = "玩家已经有公会"
    elseif err == 1 then
        msg = "资源不足"
    elseif err == 12 then
        msg = "对方申请冷却中"
    elseif err == 802 then
        msg = "您还是公会长"
    elseif err == 803 then
        msg = "公会内有其他成员时无法解散"
    elseif err == 804 then
        msg = "公会名称已存在"
    elseif err == 805 then
        msg = "未找到公会"
    elseif err == 807 then
        msg = "权限不足"
    elseif err == 808 then
        msg = "已经申请"
    elseif err == 809 then
        msg = "该请求已失效"
    elseif err == 3 then
        msg = "玩家不存在"
    elseif err == 50 then
        msg = "目标不在公会"
    elseif err == 814 then
        msg = "退出公会2小时内不能再加入公会"
    elseif err == 1006 then
        msg = "邀请过期"
    elseif err == 9 then
        msg = "公会人数已达上限"
    elseif err == 281 then
        msg = "无法使用该名称";
    else
        msg = cmd.." errorCode "..err
        ERROR_LOG(msg)
        return
    end
    showDlgError(nil, msg)
end


local container_union = utils.Container("UNION");
function container_union:Query(id)
    local data = utils.NetworkService.SyncRequest(3000, {nil, id})
    -- ERROR_LOG("公会信息", id, sprinttb(data))
    if not data or data[2] ~= 0 then
        return
    end
    local id = data[4]
    return {{
        unionId         = id,
        id              = id,
        unionName       = data[5],
        leaderId        = data[6],
        leaderName      = data[7],
        rank            = data[8],
        mcount          = data[9],
        unionExp        = data[10],
        unionLevel      = data[11],
        leaderLevel     = data[12],
        notice          = data[13],
        desc            = data[14],
        bossOpenTime    = data[15],
        memberBuyCount  = data[16],
        todayAddExp     = data[17], --今日经验
        joining         = data[3],
        yester_capital  = data[21],
    }}
end

function container_union:QueryAll()
    local respond = utils.NetworkService.SyncRequest(3008)
    if not respond or respond[2] ~= 0 then
        return
    end

    local data = respond[3]
    local list = {}
    for i = 1, #data do
        local _v = data[i];
        local _pid = _v[1]
        if _pid ~= 10000000  and _pid ~= unionManager.__unionId then
            table.insert(list, {
                unionId         = _pid,
                id              = _pid,
                unionName       = _v[2],
                leaderId        = _v[3],
                leaderName      = _v[4],
                rank            = _v[5],
                mcount          = _v[6],
                unionExp        = _v[7],
                unionLevel      = _v[8],
                leaderLevel     = _v[9],
                notice          = _v[10],
                desc            = _v[11],
                bossOpenTime    = _v[12],
                memberBuyCount  = _v[13],
                joining         = _v[14],
            });
        end
    end
    return list;
end

local container_union_member = utils.Container("UNION_MEMBER");
function container_union_member:Query(pid)
    local respond = utils.NetworkService.SyncRequest(3061, {nil, pid});
    if not respond or respond[2] ~= 0 then
        return;
    end
    local data = respond[3];
    return {{
        id                = data[1],
        pid               = data[1],
        name              = data[2],
        level             = data[3],
        title             = data[4],   --0普通成员 1公会长 2-10
        contributionToday = data[5],   --今日贡献
        contirbutionTotal = data[6],   --总贡献
        online            = data[7],   --是否在线
        login             = data[8],   --登录时间
        arenaOrder        = data[9],   --竞技场排名(保留字段)
        awardFlag         = BIT(data[10] or 0),  --今日是否领取
        todayDonateCount  = data[11],
        achieve           = data[12],  --功绩
        history_achieve   = data[13],  --历史功绩
        is_receive        = data[14],  --今日是否领取资金
        receive_capital   = data[15],  --今日可领取资金
    }}
end

function container_union_member:QueryAll()
    local respond = utils.NetworkService.SyncRequest(3010);
    if not respond or respond[2] ~= 0 then
        return;
    end

    local data = respond[3];
    -- ERROR_LOG("成员信息", sprinttb(data))
    local list = {}
    for i = 1, #data do
        local _v = data[i]
        local _pid = _v[1]

        table.insert(list, {
            id                = _pid,
            pid               = _pid,
            name              = _v[2],
            level             = _v[3],
            title             = _v[4],   --0普通成员 1公会长 2-10
            contributionToday = _v[5],   --今日贡献
            contirbutionTotal = _v[6],   --总贡献
            online            = _v[7],   --是否在线
            login             = _v[8],   --登录时间
            arenaOrder        = _v[9],   --竞技场排名(保留字段)
            awardFlag         = BIT(_v[10] or 0),  --今日是否领取
            todayDonateCount  = _v[11],
            achieve           = _v[12],
            history_achieve   = _v[13],
            is_receive        = _v[14],
            receive_capital   = _v[15],
        })
    end
    return list;
end

local openType = {
    Info = 1,
    Member = 2,
    Join = 3,
    Activity = 4,
}

---加入公会
local function joinUnion(unionId)
    NetworkService.Send(3004, {nil, unionId})
end

---邀请入帮
local inviteSnTab = {}
local inviteCdTime = {}
local function inviteUnion(pid, level)
    if (module.Time.now() - (inviteCdTime[pid] or 0)) < 15 then
        showDlgError(nil, "已经邀请过该玩家，请稍后再试")
        return
    end
    inviteCdTime[pid] = module.Time.now()
    if level >= openLevel.GetCfg(2101).open_lev then
        local _cfg = require "config.unionConfig"
        if unionManager:GetSelfUnion().mcount >= _cfg.GetNumber(unionManager:GetSelfUnion().unionLevel).MaxNumber + unionManager:GetSelfUnion().memberBuyCount then
            showDlgError(nil, "公会人数已满，无法邀请")
            return
        end
        if not utils.SGKTools.UnionPvpState() then
            return
        end
        if unionManager:GetSelfTitle() == 1 or unionManager:GetSelfTitle() == 2 then
            local _sn = NetworkService.Send(3032, {nil, pid})
            inviteSnTab[_sn] = pid
        else
            NetworkService.Send(5009,{nil, pid, 9, tostring(unionManager.__unionId), ""})
        end
    else
        showDlgError(nil, "对方等级不足，无法邀请加入公会")
    end
end
local function invite(pid)
    if playerModule.IsDataExist(pid) then
        inviteUnion(pid, playerModule.IsDataExist(pid).level)
    else
        playerModule.Get(pid,(function( ... )
            inviteUnion(pid, playerModule.IsDataExist(pid).level)
        end))
    end

end

local function upSelfUnion()
    coroutine.resume(coroutine.create(function()
        local _data = container_union:Query(unionManager.__unionId)
        if _data[1] then
            container_union:Update(_data[1])
        end
        DispatchEvent("LOCAL_UNION_INFO_CHANGE")
    end))
end

local queryDay = 0;
local function upSelfMember(checkDay)
    if checkDay then
        local curday = tonumber(os.date("%j",math.floor(module.Time.now())));
        if curday == queryDay then
            return;
        end
    end
    coroutine.resume(coroutine.create(function()
        local _data = container_union_member:Query(playerModule.GetSelfID());
        if _data and _data[1] then
            queryDay = tonumber(os.date("%j",math.floor(module.Time.now())));
            container_union_member:Update(_data[1])
        end
    end))
end


local function acceptInvite(inviteId, gid)
    --if utils.SGKTools.UnionPvpState() then
        NetworkService.Send(3146, {nil, inviteId, gid})
    --end
end

EventManager.getInstance():addListener("server_respond_3033", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        showDlgError(nil, "已发送邀请")
    else
        if err == 12 then
            local _cfg = require "config.unionConfig"
            local _tiem = _cfg.GetAward().apply_time / 3600
            local _pid = inviteSnTab[sn]
            if playerModule.IsDataExist(_pid) then
                showDlgError(nil, playerModule.IsDataExist(_pid).name.."退出公会不足"..math.ceil(_tiem).."小时，无法加入新的公会")
            else
                playerModule.Get(_pid,(function( ... )
                    showDlgError(nil, playerModule.IsDataExist(_pid).name.."退出公会不足"..math.ceil(_tiem).."小时，无法加入新的公会")
                end))
            end
            inviteSnTab[sn] = nil
        else
            errorCode(cmd, err)
        end
    end
end)

local inviteList = {}
local function getInviteList()
    return inviteList
end

local function removeInviteList(index)
    table.remove(inviteList, index)
    DispatchEvent("LOCAL_UNION_INVITE_CHANGE")
end

local function clearInviteList()
    inviteList = {}
    DispatchEvent("LOCAL_UNION_INVITE_CHANGE")
end

EventManager.getInstance():addListener("server_respond_3147", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        -- queryUnionList()
        unionManager.firstJoin = true
        showDlgError(nil, "加入成功")
        clearInviteList()
        DispatchEvent("LOCAL_UNION_ACCEPTINVITE_OK")
    else
        errorCode(cmd, err)
    end
end)

---查询玩家所属公会
local queryTime = {}
local Sncoroutine = {};
local function queryPlayerUnioInfo(pid, Funciton)
    if pid then
        if queryTime[pid] and module.Time.now() - queryTime[pid] < 1 then
            if unionManager._allPlayerUnioInfo[pid] then
                if Funciton then
                    Funciton();
                end
                return unionManager._allPlayerUnioInfo[pid];
            end
        end
        local sn = NetworkService.Send(3028, {nil, pid})
        queryTime[pid] = module.Time.now();
        SnFunction[sn] = Funciton;
        if coroutine.isyieldable() then
            Sncoroutine[sn] = {co = coroutine.running()};
            coroutine.yield()
            return unionManager._allPlayerUnioInfo[pid] or {}
        end
        return nil;
    end
end

local function GetPlayerUnioInfo(pid)
    if pid then
        return unionManager._allPlayerUnioInfo[pid] or {}
    end
    return {}
end

local function showGeneralInvitation(pid, unionId)
    local _data = module.playerModule.IsDataExist(pid)
    queryPlayerUnioInfo(pid, function()
            local _text = "玩家<color=#82C077>".._data.name.."</color>邀请你加入\n公会<color=#F8CBAD>["..GetPlayerUnioInfo(pid).unionName.."]</color>\n是否同意邀请"
            showDlgMsg(_text, function()
                joinUnion(tonumber(unionId))
            end, function()end, nil, nil, 15)
    end)
end

local function GeneralInvitation(data)
    if module.playerModule.IsDataExist(data.pid) then
        showGeneralInvitation(data.pid, data.unionId)
    else
        module.playerModule.Get(data.pid,(function()
            showGeneralInvitation(data.pid, data.unionId)
        end))
    end
end

---收到被邀请的通知
EventManager.getInstance():addListener("server_notify_1126", function(event, cmd, data)
    if not openLevel.GetStatus(2101) then
        return
    end
    PlayerInfoHelper.GetPlayerAddData(0,PlayerInfoHelper.ServerAddDataType.UNIONANDTEAMSTATUS,function (playerAddData)
        if playerAddData.UnionAndTeamInviteStatus then
            return
        end
        if module.playerModule.IsDataExist(data[1]) then
            local _data = module.playerModule.IsDataExist(data[1])
            queryPlayerUnioInfo(data[1], function()
                    local _text = "玩家<color=#82C077>".._data.name.."</color>邀请你加入\n公会<color=#F8CBAD>["..GetPlayerUnioInfo(data[1]).unionName.."]</color>\n是否同意邀请"
                    showDlgMsg(_text, function()
                        acceptInvite(data[3], data[2])
                    end, function()end, nil, nil, 15)
            end)
        else
            module.playerModule.Get(data[1],(function( ... )
                local _data = module.playerModule.IsDataExist(data[1])
                queryPlayerUnioInfo(data[1], function()
                    local _text = "玩家<color=#82C077>".._data.name.."</color>邀请你加入\n公会<color=#F8CBAD>["..GetPlayerUnioInfo(data[1]).unionName.."]</color>\n是否同意邀请"
                    showDlgMsg(_text, function()
                        acceptInvite(data[3], data[2])
                    end, function()end, nil, nil, 15)
                end)
            end))
        end
    end)


    --table.insert(inviteList, {hostId = data[1], inviteId = data[3], gid = data[2]})
    --DispatchEvent("LOCAL_UNION_INVITE_CHANGE")
end)


---创建公会
local function createUnion(unionName, coinFlag)
    local name,hit = WordFilter.check(unionName)
    if hit then
        showDlgError(nil, "无法使用该公会名")
        return
    end
    NetworkService.Send(3002, {nil, unionName, coinFlag})
end

---加好友
local function addFriend(pid)
    local FriendData = module.FriendModule.GetManager(1,pid)
    if FriendData then
        showDlgError(nil,"对方已经是你的好友")
    else
        NetworkService.Send(5013,{nil, 1, pid})
    end
end


local function queryExpLog()
    NetworkService.Send(3046,{nil})
end

local unionDesc = ""
local function setUnionDesc(desc)
    if desc then
        unionDesc = desc
    end
end

---设置公告 宣言
local function setNotice(data)
    local name,hit = WordFilter.check(data)
    if hit then
        showDlgError(nil, "无法设置该公告内容")
        return
    end
    NetworkService.Send(3020, {nil, 1, data, nil})
end
local function setDesc(data)
    local name,hit = WordFilter.check(data)
    if hit then
        showDlgError(nil, "无法设置该宣言内容")
        return
    end
    NetworkService.Send(3020, {nil, 2, data, nil})
end

EventManager.getInstance():addListener("server_respond_3003", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        unionManager.__unionId = data[3]
        if unionDesc ~= "" then
            setNotice(unionDesc)
            unionDesc = ""
        end
        queryExpLog()

        container_union:Clean()
        container_union_member:Clean()

        coroutine.resume(coroutine.create(function()
            local _data = container_union:Query(unionManager.__unionId)
            if _data[1] then
                container_union:Update(_data[1])
            end
            if utils.SGKTools.GetTeamState() then
                DialogStack.Pop()
                DialogStack.Push("newUnion/newUnionFrame", 1)
            else
                DialogStack.Pop()

                DialogStack.Push("newUnion/newUnionFrame", 1)
                -- SceneStack.EnterMap(25)
            end
        end))

        container_union:GetList()
        container_union_member:GetList()
        DispatchEvent("LOCAL_UP_UNIONACTIVITY", {unionPid = unionManager.__pid, heroPid = unionManager.__pid})   --请求公会活动数据
        DispatchEvent("LOCAL_CREATE_UOION")
        print("3003",sprinttb(data))
    else
        errorCode(cmd, err)
    end
end)


---领取建设奖励
local rewardSnTab = {}
local function constructionReward(index, func)
    if func then
        coroutine.resume(coroutine.create(function()
            local _data = utils.NetworkService.SyncRequest(3124, {nil, index})
            rewardSnTab[_data[1]] = index
            func()
        end))
    else
        local _sn = NetworkService.Send(3124, {nil, index})
        rewardSnTab[_sn] = index
    end
end

EventManager.getInstance():addListener("server_respond_3125", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        print("server_respond_3125", sprinttb(data))
        local _index = rewardSnTab[sn]
        local info = container_union_member:Get(unionManager.__pid)
        if info then
            info.awardFlag[_index] = 1
            container_union_member:Update(info);
        end

        DispatchEvent("LOCAL_UNION_INFO_CHANGE")
        DispatchEvent("LOCAL_UNION_REWARD_OK")
    else
        errorCode(cmd, err)
    end
end)

local function upExpLog(data)
    unionManager.expLogTab = {}
    local _countTab = {}
    for k,v in pairs(data) do
        local _temp = {}
        _temp.time   = v[1]
        _temp.pid    = v[2]
        _temp.name   = v[3]
        _temp.number = v[4]
        _temp.type   = v[5] or 0
        table.insert(unionManager.expLogTab, _temp)
    end
    for i = #unionManager.expLogTab, 1, -1 do
        local _temp = unionManager.expLogTab[i]
        if _countTab[_temp.name] then
            _countTab[_temp.name] = _countTab[_temp.name] + 1
        else
            _countTab[_temp.name] = 1
        end
        _temp.count = _countTab[_temp.name]
    end
end

EventManager.getInstance():addListener("server_respond_3047", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        upExpLog(data[3])
    else
        errorCode(cmd, err)
    end
end)

function unionManager:upUnionList(data, isFind)
    for i = 1, #data do
        local _v = data[i]
        local _pid = _v[1]
        if _pid == 10000000 then return end --剔除10000000

        container_union:Update({
            unionId         = _pid,
            id              = _pid,
            unionName       = _v[2],
            leaderId        = _v[3],
            leaderName      = _v[4],
            rank            = _v[5],
            mcount          = _v[6],
            unionExp        = _v[7],
            unionLevel      = _v[8],
            leaderLevel     = _v[9],
            notice          = _v[10],
            desc            = _v[11],
            bossOpenTime    = _v[12],
            memberBuyCount  = _v[13],
            joining         = _v[14],
        });

        table.insert(self.findUnionList, container_union:Get(_pid))
    end
end

---请求公会信息
local function queryUnionInfo(unionId, unionName)
    NetworkService.Send(3000, {nil, unionId, unionName})
end

local function findUnion(name)
    NetworkService.Send(3144, {nil, name})
end

---任免
local function setTitle(pid, title)
    if utils.SGKTools.UnionPvpState() then
        NetworkService.Send(3030, {nil, pid, title})
    end
end

---转让团长
local function transferUnion(pid)
    if utils.SGKTools.UnionPvpState() then
        NetworkService.Send(3036, {nil, pid})
    end
end

EventManager.getInstance():addListener("server_respond_3037", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        print("3037",sprinttb(data))
        showDlgError(nil, "转让成功")
    else
        errorCode(cmd, err)
    end
end)


EventManager.getInstance():addListener("server_respond_3031", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        print("3031",sprinttb(data))
        showDlgError(nil, "修改成功")
    else
        errorCode(cmd, err)
    end
end)

---查询公会请求列表
local function queryApplyList()
    NetworkService.Send(3016, {nil})
end

function unionManager:upApplyList(v)
    local _pid = v[1]
    if self._applyList[_pid] == nil then self._applyList[_pid] = {} end
    self._applyList[_pid].pid        = _pid
    self._applyList[_pid].name       = v[2]
    self._applyList[_pid].level      = v[3]
    self._applyList[_pid].applyTime  = v[4]
    self._applyList[_pid].arenaOrder = v[5]
    self._applyList[_pid].online     = v[6]
    --heroModule.GetManager(_pid)
end

EventManager.getInstance():addListener("server_respond_3017", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        unionManager._applyList = {}
        for i = 1, #data[3] do
            unionManager:upApplyList(data[3][i])
        end
        DispatchEvent("LOCAL_CHANGE_APPLYLIST")
    else
        errorCode(cmd, err)
    end
end)

function unionManager:upPlayerUnioInfo(pid, title, unfreezeTime, unionId, unionName)
    if not pid and type(pid) == "table" then
        return
    end
    if self._allPlayerUnioInfo[pid] == nil then self._allPlayerUnioInfo[pid] = {} end
    if title ~= nil then
        if pid == unionManager.__pid and unionId ~= 0 then  --如果查询到的是玩家自己的公会则查询其他相关的公会信息
            self.__unionId = unionId
            self.selfTitle = title
            container_union:Get(self.__unionId)                   --查玩家自己的公会信息
            if title == 1 or title == 2 then
                queryApplyList()                            --查自己公会的请求成员列表
            end
            queryExpLog()                                   --查询贡献日志
            DispatchEvent("LOCAL_UP_UNIONACTIVITY", {unionPid = unionManager.__pid, heroPid = unionManager.__pid})   --请求公会活动数据
        end
        self._allPlayerUnioInfo[pid].haveUnion = 1
        self._allPlayerUnioInfo[pid].title = title
        self._allPlayerUnioInfo[pid].unfreezeTime = unfreezeTime
        self._allPlayerUnioInfo[pid].unionId = unionId
        self._allPlayerUnioInfo[pid].unionName = unionName
        self._allPlayerUnioInfo[pid].online = true
        if pid == unionManager.__pid then
            DispatchEvent("PLAYER_INFO_CHANGE", pid)
        end
    else
        self._allPlayerUnioInfo[pid].haveUnion = 0
    end
    --print("dsd",sprinttb(self._allPlayerUnioInfo))
end

EventManager.getInstance():addListener("server_respond_3029", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        --print("3029",sprinttb(data))
        unionManager:upPlayerUnioInfo(data[3], data[4], data[5], data[6], data[7])
        if Sncoroutine[sn] and Sncoroutine[sn].co then
            coroutine.resume(Sncoroutine[sn].co);
            Sncoroutine[sn] = nil;
        end
        if SnFunction[sn] then
            SnFunction[sn] = SnFunction[sn](data)
            SnFunction[sn] = nil
        end
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3005", function(event, cmd, data)
    print(sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        print("3005",sprinttb(data))
        local info = container_union:Get(data[3], true)
        if info then
            info.joining = 1;
        end
        DispatchEvent("LOCAL_UNION_JOINOVER")
        showDlgError(nil, "申请成功")
    else
        errorCode(cmd, err)
    end
end)


---踢出公会
local function kickUnion(targetPid)
    if utils.SGKTools.UnionPvpState() then
        NetworkService.Send(3040, {nil, targetPid})
    end
end
EventManager.getInstance():addListener("server_respond_3041", function(event, cmd, data)
    print(sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        showDlgError(nil, "请出公会成功")
        container_union_member:Remove(data[3]);
        DispatchEvent("LOCAL_CHANGE_MEMBERLIST")
        print("3041",sprinttb(data))
    else
        errorCode(cmd, err)
    end
end)


---解散公会
local function dissolveUnion()
    NetworkService.Send(3026, {nil})
end
EventManager.getInstance():addListener("server_respond_3027", function(event, cmd, data)
    print(sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        print("3027",sprinttb(data))
    else
        errorCode(cmd, err)
    end
end)


---退出公会
local function leaveUnion()
    NetworkService.Send(3006, {nil})
end
EventManager.getInstance():addListener("server_respond_3007", function(event, cmd, data)
    print(sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        unionManager.__unionId = 0
        unionManager._allPlayerUnioInfo[unionManager.__pid] = nil
        DispatchEvent("LOCAL_UNION_LEAVEUNION", unionManager.__pid)
        DispatchEvent("PLAYER_INFO_CHANGE", unionManager.__pid)
        unionManager.firstJoin = true
        print("3007",sprinttb(data))
    else
        errorCode(cmd, err)
    end
end)


---同意加入申请
local function agreedApply(pid)
    NetworkService.Send(3018, {nil, pid, 1})
end
---拒绝加入申请
local function refusedApply(pid)
    NetworkService.Send(3018, {nil, pid, 0})
end
EventManager.getInstance():addListener("server_respond_3019", function(event, cmd, data)
    print(sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        if unionManager._applyList[data[3]] ~= nil then
            unionManager._applyList[data[3]] = nil
            DispatchEvent("LOCAL_CHANGE_APPLYLIST")
        end
        print("server_respond_3019",sprinttb(data))
    else
        if unionManager:GetSelfTitle() == 1 or unionManager:GetSelfTitle() == 2 then
            queryApplyList()
            showDlgError(nil, "该请求已失效")
        end
    end
end)

---职位变更
EventManager.getInstance():addListener("server_notify_24", function(event, cmd, data)
    --print(sprinttb(data))
    local info = container_union_member:Get(data[2])
    if info then
        if data[7] == 1 then
            module.ChatModule.SystemChatMessage(SGK.Localize:getInstance():getValue("juntuan_renming_huizhang_01", data[3]))
        else
            module.ChatModule.SystemChatMessage(SGK.Localize:getInstance():getValue("juntuan_renming_01", unionConfig.GetCompetence(info.title).Name, data[3], unionConfig.GetCompetence(data[7]).Name))
        end
        info.title = data[7];
        container_union_member:Update(info);
    end
    DispatchEvent("LOCAL_UNION_UPDATE_TITLE", {pid = data[2]})
end)

---团长变更
EventManager.getInstance():addListener("server_notify_23", function(event, cmd, data)
    print(sprinttb(data))
end)

---同意加入的通知
EventManager.getInstance():addListener("server_notify_25", function(event, cmd, data)
    if unionManager._applyList[data[6]] ~= nil then
        unionManager._applyList[data[6]] = nil
        DispatchEvent("LOCAL_CHANGE_APPLYLIST")
    end
    print("server_notify_25",sprinttb(data))
end)
---有人加入的通知
EventManager.getInstance():addListener("server_notify_20", function(event, cmd, data)
    ERROR_LOG("server_notify_20",sprinttb(data))
    if data[1] == unionManager.__unionId then
        local _pid = data[2]
        container_union_member:Update({
            id = _pid,
            pid = _pid,
            name = data[3],
            level = data[4],
            arenaOrder = data[5],
            online = data[6],
            login = module.Time.now(),
            todayDonateCount = data[7],
            title = 0,
            contributionToday = 0,
            contirbutionTotal = 0,
            achieve = 0,
            history_achieve = 0,
            is_receive = 0,
            receive_capital = 0,
        });
        upSelfUnion()
        module.ChatModule.SystemChatMessage(SGK.Localize:getInstance():getValue("juntuan_jairugonghui_01", data[3]))
        DispatchEvent("LOCAL_CHANGE_APPLYLIST")
    elseif unionManager.__unionId == 0 then
        unionManager.__unionId = data[1]
        -- queryUnionList()
        -- container_union:Get(unionManager.__unionId);
        coroutine.resume(coroutine.create(function()
            local _data = container_union:Query(unionManager.__unionId)
            if _data[1] then
                container_union:Update(_data[1])
            end
            DispatchEvent("LOCAL_UNION_INFO_CHANGE")
        end))
        container_union_member:Clean()
        container_union_member:GetList()
        DispatchEvent("LOCAL_UP_UNIONACTIVITY", {unionPid = unionManager.__pid, heroPid = unionManager.__pid})
        showDlgError(nil, "加入公会成功")
    end
    unionManager:upOnlineList()
end)

---清空请求列表
local function cleanAllApply()
     NetworkService.Send(3042, {nil})
end

EventManager.getInstance():addListener("server_respond_3043", function(event, cmd, data)
    print(sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        unionManager._applyList = {}
        print("3043",sprinttb(data))
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3021", function(event, cmd, data)
    print(sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        print("设置成功")
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_notify_22", function(event, cmd, data)
    print("server_notify_22",sprinttb(data))

    local info = container_union:Get(data[1]);
    if info then
        info.notice = data[2];
        info.desc = data[3];
        container_union:Update(info);
        DispatchEvent("LOCAL_UNION_NOTICE_CHANGE")
    end
end)


---捐献
local function donate(typeId, func)
    if func then
        coroutine.resume(coroutine.create(function()
            utils.NetworkService.SyncRequest(3094, {nil, typeId})
            func()
        end))
    else
        NetworkService.Send(3094, {nil, typeId})
    end
end
EventManager.getInstance():addListener("server_respond_3095", function(event, cmd, data)
    print("3095",sprinttb(data))
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        if unionManager:GetUnion(unionManager.__unionId) ~= nil then
            print("dasdid",unionManager.__unionId)
        end
        showDlgError(nil, "投资成功")
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3145", function(event, cmd, data)
    print(sprinttb(data))
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        unionManager.findUnionList = {}
        unionManager:upUnionList(data[3], true)
        DispatchEvent("LOCAL_UNION_FINDUNION")
    else
        errorCode(cmd, err)
    end
end)


EventManager.getInstance():addListener("server_notify_1106", function(event, cmd, data)
    ERROR_LOG("server_notify_1106",sprinttb(data))
    unionManager:GetSelfUnion().unionExp = data[4]
    unionManager:GetSelfUnion().todayAddExp = unionManager:GetSelfUnion().todayAddExp + data[5]

    local info = container_union_member:Get(data[3]);
    if info then
        info.contributionToday = data[5]
        info.contirbutionTotal = data[5] + info.contirbutionTotal
        info.todayDonateCount = data[6]
        container_union_member:Update(info);
    end
    coroutine.resume(coroutine.create(function()
        local _data = container_union:Query(unionManager.__unionId)
        if _data[1] then
            container_union:Update(_data[1])
        end
        DispatchEvent("LOCAL_UNION_INFO_CHANGE")
    end))
    queryExpLog()
    DispatchEvent("LOCAL_UNION_EXP_CHANGE")
end)


--有玩家申请加入
EventManager.getInstance():addListener("server_notify_19", function(event, cmd, data)
    print("server_notify_19",sprinttb(data))
    local _pid = data[2]
    if unionManager._applyList[_pid] == nil then unionManager._applyList[_pid] = {} end
    unionManager._applyList[_pid].pid        = _pid
    unionManager._applyList[_pid].name       = data[3]
    unionManager._applyList[_pid].level      = data[4]
    unionManager._applyList[_pid].applyTime  = data[5]
    unionManager._applyList[_pid].arenaOrder = data[6]
    unionManager._applyList[_pid].online     = data[7]
    --heroModule.GetManager(_pid)
    showDlgError(nil, "有玩家申请加入公会")
    DispatchEvent("LOCAL_CHANGE_APPLYLIST")
end)

---有玩家离开公会通知
EventManager.getInstance():addListener("server_notify_21", function(event, cmd, data)
    print("server_notify_21",sprinttb(data))
    local _id = data[2]
    if _id == unionManager.__pid then
        unionManager.__unionId = 0
        unionManager.firstJoin = true
        unionManager._allPlayerUnioInfo[unionManager.__pid] = nil
        DispatchEvent("PLAYER_INFO_CHANGE", unionManager.__pid)
        DispatchEvent("LOCAL_UNION_LEAVEUNION", data[2])
        return
    end

    container_union_member:Remove(_id);
    upSelfUnion()

    DispatchEvent("LOCAL_CHANGE_MEMBERLIST")
    unionManager:upOnlineList()
end)

EventManager.getInstance():addListener("LOCAL_UNION_LEAVEUNION", function(event, data)
    if unionManager.__pid == data then
        container_union:Clean()
        container_union_member:Clean()
    end
end)

--领取公会资金
local function GetUnionCapital()
    NetworkService.Send(3459)
end

EventManager.getInstance():addListener("server_respond_3460", function(event, cmd, data)
    local result = data[2];
    if result ~= 0 then
        print("领取公会资金失败", result)
        return;
    end
    upSelfUnion();
    upSelfMember();
end)

--添加公会资金(临时)
local function AddUnionCapital(num)
    print("添加公会资金", num)
    NetworkService.Send(3457, {nil, num})
end
EventManager.getInstance():addListener("server_respond_3458", function(event, cmd, data)
    local result = data[2];
    if result ~= 0 then
        print("添加公会资金失败", result)
        return;
    end
    upSelfUnion()
    print("添加公会资金成功")
end)
--添加功绩(临时)
local function AddAchieve(num)
    print("添加功绩", num)
    NetworkService.Send(3463, {nil, num})
end
EventManager.getInstance():addListener("server_respond_3464", function(event, cmd, data)
    local result = data[2];
    if result ~= 0 then
        print("添加功绩失败", result)
        return;
    end
    upSelfMember();
    print("添加成功")
end)

-----测试------
local function unionTest()
    -- queryUnionList()
    --setDesc("ffbdsdsdsdsdbbbasdsdkkkkkkasdasd")
    --joinUnion(10000005)
    --donate(1)
    --createUnion("abc123", 0)
    --queryAllUnionPlayerInfo()
    --queryApplyList()
    --queryUnionInfo(10000005,"")
end


------------------------------------------------------------------------------


function unionManager:init()
    self.__pid = 0
    self.selfTitle = 0 --自己的职位
    self:cleanAllTab()
end

function unionManager:cleanAllTab()
    self.__unionId = 0
    self.findUnionList = {}
    self._applyList = {}
    self.onlineList = {}
    self._allPlayerUnioInfo = {}
end

---获取全部公会
function unionManager:GetUnionList()
    return container_union:GetList(true)
end

function unionManager:GetTopUnion()
    local list = container_union:GetList();
    table.sort(list, function(a, b)
        return a.rank < b.rank
    end)
    local _list = {}
    for i = 1, 30 do
        table.insert(_list, list[i])
    end
    return _list;
end

---获取自己的公会id
function unionManager:GetUionId()
    return self.__unionId
end

---获取查找的公会
function unionManager:GetFindUnion()
    return self.findUnionList
end

---获取自己职位
function unionManager:GetSelfTitle()
    if self.__unionId == nil or self.__unionId == 0 then
        return 0
    end
    local _self = container_union_member:Get(self.__pid) or {}
    return _self.title or 0
end

---获取自己公会的成员列表
function unionManager:GetMember(pid)
    if pid then
        local _self = container_union_member:Get(pid)
        if module.playerModule.Get(pid) then
            _self.name=module.playerModule.Get(pid).name
        end
        return _self ;  --container_union_member:Get(pid);
    else
        local _self = container_union_member:GetList()
        if module.playerModule.Get() then
            _self.name=module.playerModule.Get().name
        end
        return  _self;    --container_union_member:GetList();
    end
end

---获取自己的公会成员信息
function unionManager:GetSelfInfo()
    return container_union_member:Get(self.__pid) or {};
end

function unionManager:GetExpLog(index)
    if index then
        return self.expLogTab[index]
    else
        return self.expLogTab
    end
end

function unionManager:upOnlineList()
    self.onlineList = {}
    for k,v in pairs(container_union_member:GetList()) do
        if v.online then
            table.insert(self.onlineList, v)
        end
    end
end

---获取自己公会在线成员
function unionManager:GetOnline()
    return self.onlineList
end

---获取请求的列表
function unionManager:GetApply(pid)
    if pid ~= nil then
        return self._applyList[pid]
    else
        return self._applyList
    end
end

function unionManager:GetUnion(unionId)
    return container_union:Get(unionId);
end

function unionManager:GetSelfUnion()
    if self.__unionId == nil or self.__unionId == 0 then
        return nil;
    end
    local _self = container_union:Get(self.__unionId) or{}
    if module.playerModule.Get(_self.leaderId) then
        _self.leaderName=module.playerModule.Get(_self.leaderId).name
    end
    return  _self;      --container_union:Get(self.__unionId);
end

---获取自己公会总人数
function unionManager:GetTotalNumber()
    if self.__unionId == nil or self.__unionId == 0 then
        return 0;
    end

    local union = container_union:Get(self.__unionId);
    return union and union.mcount or 0;
end

local  timingShowFlag = true
local function timingShowDesc()
    if timingShowFlag then
        timingShowFlag = false
        local _showFunc = function()
            if module.unionModule.Manage:GetUionId() ~= 0 then
                if module.unionModule.Manage:GetSelfUnion().desc ~= "" then
                    module.ChatModule.SystemChatMessage(module.unionModule.Manage:GetSelfUnion().desc)
                else
                    module.ChatModule.SystemChatMessage(SGK.Localize:getInstance():getValue("juntuan_gonggao_03"))
                end
            end
        end
        StartCoroutine(function()
            while true do
                WaitForSeconds(3000)
                _showFunc()
            end
        end)
    end
end

EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, pid)
    unionManager:init()
    unionManager.__pid = pid
    -- queryUnionList()
    queryPlayerUnioInfo(pid, function(data)
        timingShowDesc()
        DispatchEvent("QUERY_SELFUNION_SUCCEND",data);
    end)
end);


local function JoinUnionByPid(targetId, selfId)
    local _selfId = selfId or playerModule.Get().id
    queryPlayerUnioInfo(targetId, function()
        local _targetInfo = GetPlayerUnioInfo(targetId)
        if _targetInfo.haveUnion ~= 0 then
            joinUnion(_targetInfo.unionId)
        end
    end)
end




return {
    Manage = unionManager,

    Create = createUnion,                  --创建公会
    Join = joinUnion,                      --加入公会
    DissolveUnion = dissolveUnion,         --解散公会
    Leave = leaveUnion,                    --离开公会
    Kick = kickUnion,                      --踢出公会
    CleanApply = cleanAllApply,            --清空申请列表
    AgreedApply = agreedApply,             --同意加入请求
    RefusedApply = refusedApply,           --拒绝加入请求
    Donate = donate,                       --捐献
    FindUnion = findUnion,                 --根据名字查找公会
    SetNotice = setNotice,                 --设置公告
    SetDesc = setDesc,                     --设置宣言
    AddFriend = addFriend,                 --加好友
    QueryExpLog = queryExpLog,             --查询捐献日志
    SetTitle = setTitle,                   --任免
    TransferUnion = transferUnion,         --转让团长
    ConstructionReward = constructionReward, --公会建设度奖励
    GetPlayerUnioInfo = GetPlayerUnioInfo,
    queryPlayerUnioInfo = queryPlayerUnioInfo,
    Invite = invite,                       --邀请加入公会
    AcceptInvite = acceptInvite,           --同意加入公会
    ClearInviteList = clearInviteList,     --清除邀请列表
    RemoveInviteList = removeInviteList,   --移除某一个邀请
    GetInviteList = getInviteList,         --公会邀请列表
    OpenType = openType,                   --快速打开类型
    JoinUnionByPid = JoinUnionByPid,       --根据玩家id加入公会
    SetUnionDesc = setUnionDesc,
    GeneralInvitation = GeneralInvitation, --普通成员邀请
    GetUnionCapital = GetUnionCapital,     --领取公会资金
    UpSelfMember = upSelfMember,           --刷新自己的公会成员信息
    AddUnionCapital = AddUnionCapital,
    AddAchieve = AddAchieve,
}
