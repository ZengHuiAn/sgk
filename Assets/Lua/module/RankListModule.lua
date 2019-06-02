local NetworkService = require "utils.NetworkService";
local EventManager = require 'utils.EventManager';
local OpenLevel = require "config.openLevel"
-- #define C_QUERY_RANK_REQUEST 1034
-- request[1] = sn
-- request[2] = rank_type   1等级排行榜  2副本星星排行榜
-- #define C_QUERY_RANK_RESPOND 1035
-- ret[1] = sn
-- ret[2] = result
-- ret[3] = open_flag   0未开放 1开放
-- ret[4] = first_begin_time
-- ret[5] = period
-- ret[6] = [pid, value]

local Type = {
    Level = 1,
    Star = 2,
    Wealth = 3,--财力值
    TrialTower = 4,--爬塔
}

local rangeIdx={
    Server=1,--全服
    Friend=2,--好友
}

local rankListTimeTab = {}

local refreshPeriod = 60
local rankInfo={}
local rankRewardCfgList = nil
local rankCfgList = nil
local rankCfgByType=nil
local notifyOpenId = 5009 --好友通知开启等级
local function GetRankCfg(type)
    if not rankCfgList then
        rankCfgList={}
        rankCfgByType={} 
        DATABASE.ForEach("rank_info", function(data)
            rankCfgByType[data.rank_type]=data
            rankCfgList[data.rank_type]=rankCfgList[data.rank_type] or {name=data.rank_name,icon=data.icon}
            
            rankCfgList[data.rank_type][1]=rankCfgList[data.rank_type][1] or {}
            if data.lable1~=0 then
                rankCfgList[data.rank_type][1][data.lable1]=rankCfgList[data.rank_type][1][data.lable1] or  data.lable_name1
            end
            rankCfgList[data.rank_type][2]=rankCfgList[data.rank_type][2] or {}
            if data.lable2~=0 then
                rankCfgList[data.rank_type][2][data.lable2]=rankCfgList[data.rank_type][2][data.lable2] or data.lable_name2
            end      
        end)
    end
    if type then
        return rankCfgList[type]  
    else 
        return rankCfgByType
    end  
end

local function GetRankRewardCfg(type,IsWeek,firstWeek)
    if  not rankRewardCfgList then
        rankRewardCfgList = {}
        DATABASE.ForEach("rank_reward", function(data)
            --排行榜类型
            rankRewardCfgList[data.rank_type] = rankRewardCfgList[data.rank_type] or {}
            rankRewardCfgList[data.rank_type].weekTypeList=rankRewardCfgList[data.rank_type].weekTypeList or {}
            if not rankRewardCfgList[data.rank_type][data.week_reward] then
                table.insert(rankRewardCfgList[data.rank_type].weekTypeList, {type=data.week_reward,name=data.week_reward_name})
            end
            --奖励类型是周/日week_reward 
            rankRewardCfgList[data.rank_type][data.week_reward]=rankRewardCfgList[data.rank_type][data.week_reward] or {} 
            rankRewardCfgList[data.rank_type][data.week_reward].rewardTypeList=rankRewardCfgList[data.rank_type][data.week_reward].rewardTypeList or {}
            if not rankRewardCfgList[data.rank_type][data.week_reward][data.first_week_reward] then
                table.insert(rankRewardCfgList[data.rank_type][data.week_reward].rewardTypeList, {type=data.first_week_reward})
            end
            --是否是首周
            rankRewardCfgList[data.rank_type][data.week_reward][data.first_week_reward]=rankRewardCfgList[data.rank_type][data.week_reward][data.first_week_reward] or {}
            rankRewardCfgList[data.rank_type][data.week_reward][data.first_week_reward].list=rankRewardCfgList[data.rank_type][data.week_reward][data.first_week_reward].list or {}
            table.insert(rankRewardCfgList[data.rank_type][data.week_reward][data.first_week_reward].list, data)
        end)
    end

    if firstWeek then
        return  rankRewardCfgList[type] and rankRewardCfgList[type][IsWeek] and rankRewardCfgList[type][IsWeek][firstWeek]
    elseif IsWeek then
        return  rankRewardCfgList[type] and rankRewardCfgList[type][IsWeek]
    elseif type then
        return  rankRewardCfgList[type]
    else
        return rankRewardCfgList
    end
end

local players = {}
local function GetPlayerData(pid,refresh)
    if refresh or not players[pid] or players[pid].lastQueryTime and module.Time.now()-players[pid].lastQueryTime>=refreshPeriod then
        local data = NetworkService.SyncRequest(5, {nil,pid})
        players[pid] = data
        players[pid].lastQueryTime = module.Time.now()
        return players[pid]
    else
        return players[pid]
    end
end

local playerAddDatas = {}
local function GetPlayerAddData(pid,refresh)
    if refresh or not playerAddDatas[pid] or playerAddDatas[pid].lastQueryTime and module.Time.now()-playerAddDatas[pid].lastQueryTime>=refreshPeriod then
        local addData = NetworkService.SyncRequest(17081, {nil,pid,{10}})
        playerAddDatas[pid] = addData
        playerAddDatas[pid].lastQueryTime = module.Time.now()
        return playerAddDatas[pid]
    else
        return playerAddDatas[pid]
    end
end

local playerWealthData = {}
local function GetPlayerWealthData(pid,refresh)
    if refresh or not playerWealthData[pid] or playerWealthData[pid].lastQueryTime and module.Time.now()-playerWealthData[pid].lastQueryTime>=refreshPeriod then
        local data = NetworkService.SyncRequest(529, {nil, pid})
        playerWealthData[pid] = data
        playerWealthData[pid].lastQueryTime = module.Time.now()
        return playerWealthData[pid]
    else
        return playerWealthData[pid]
    end
end

local FriendList = {}
local function GetPlayerAddData(refresh)
    if refresh or not FriendList.list or FriendList.lastQueryTime and module.Time.now()-FriendList.lastQueryTime>=refreshPeriod then
        local data = NetworkService.SyncRequest(5011,{nil})
        FriendList.list = data
        FriendList.lastQueryTime = module.Time.now()
        return FriendList.list
    else
        return FriendList.list
    end
end

local function checkRankListLimit(name,level)
    if name and level and utils.SGKTools.matchingName(name) ~= "陆水银" and OpenLevel.GetCfg(2204) and level>=OpenLevel.GetCfg(2204).open_lev then
        return true
    end
    return false
end

local selfPid = module.playerModule.GetSelfID()
local friendRankList = {}
local friendPassList = {}
local function QueryFriendLevelList(friendList,SetPasser)
    local type = Type.Level
    friendRankList[type] = {type=type,queryTime=module.Time.now(),list = {}}
    local levelList = {}
    for i=1,#friendList do
        local _pid = friendList[i].pid
        local _data = GetPlayerData(_pid)
        if _data and _data[2] ==0 then
            local _level = _data[7] or 1
            if checkRankListLimit(_data[4],_level) then
                table.insert(levelList,{pid = _pid,level = _level})
            end
        end
    end

    table.sort(levelList,function(a,b) 
        if a.level ~= b.level then
            return a.level > b.level   
        end
        return a.pid<b.pid
    end)

    for i=1,#levelList do
        if levelList[i].pid == selfPid then
            friendRankList[type].selfRank = i
        end
        local _tab={pid = levelList[i].pid,value  = levelList[i].level,rank   = i}
        table.insert(friendRankList[type].list,_tab)
    end
    if not friendRankList[type].selfRank then return end
    if SetPasser or friendPassList[type] and friendPassList[type].lastQueryTime and module.Time.now()-friendPassList[type].lastQueryTime> refreshPeriod then
        friendPassList[type] = {list={},lastQueryTime=module.Time.now()}
        --领先者
        if OpenLevel.GetStatus(notifyOpenId) then
            for i=1,#friendRankList[type].list do
                local _passerRank = friendRankList[type].list[i].rank
                local _passerPid = friendRankList[type].list[i].pid
                if _passerRank<= friendRankList[type].selfRank and _passerPid ~= selfPid then
                    table.insert(friendPassList[type].list,_passerPid)
                end
            end
        end
    end
end

local function QueryFriendStarList(friendList,SetPasser)
    local type = Type.Star
    friendRankList[type] = {type=type,queryTime=module.Time.now(),list = {}}
    local starList = {}
    for i=1,#friendList do
        -- local _data=NetworkService.SyncRequest(5, {nil, friendList[i].pid})
        local _pid = friendList[i].pid
        local _data = GetPlayerData(_pid)
        if _data and _data[2]==0 then
            local _star = _data[11] or 0
            if checkRankListLimit(_data[4],_data[7]) then
                table.insert(starList,{pid=friendList[i].pid,star=_star})
            end
        end
    end
    table.sort(starList,function(a,b) 
        if a.star ~= b.star then
            return a.star > b.star
        end
        return a.pid<b.pid
    end)

    for i=1,#starList do
        if starList[i].pid==selfPid then
            friendRankList[type].selfRank=i
        end
        local _tab={pid = starList[i].pid,value  = starList[i].star,rank   = i}
        table.insert(friendRankList[type].list,_tab)
    end
    if not friendRankList[type].selfRank then return end
    if SetPasser or friendPassList[type] and friendPassList[type].lastQueryTime and module.Time.now()-friendPassList[type].lastQueryTime> refreshPeriod then
        friendPassList[type] = {list={},lastQueryTime=module.Time.now()}
        --领先者
        if OpenLevel.GetStatus(notifyOpenId) then
            for i=1,#friendRankList[type].list do
                local _passerRank = friendRankList[type].list[i].rank
                local _passerPid = friendRankList[type].list[i].pid
                if _passerRank<= friendRankList[type].selfRank and _passerPid ~= selfPid then
                    table.insert(friendPassList[type].list,_passerPid)
                end
            end
        end
    end
end

local function QueryFriendWealthList(friendList,SetPasser)
    local type = Type.Wealth
    friendRankList[type]={type=type,list = {}}
    local wealthList = {}
    for i=1,#friendList do
        -- local addData = NetworkService.SyncRequest(17081, {nil,friendList[i].pid,{10}})
        local _pid = friendList[i].pid
        local addData = GetPlayerAddData(_pid)
        local _pvpOpened = false
        if addData[2]==0 and addData[3]==friendList[i].pid and addData[4] and next(addData[4])~=nil then
            for i=1,#addData[4] do
                if addData[4][i][1]==10 and addData[4][i][2]==1 then
                    _pvpOpened=true
                    break
                end
            end
        end
        if _pvpOpened then 
            local _pid = friendList[i].pid
            local _data = GetPlayerWealthData(_pid)
            if _data and _data[2]==0 then
                table.insert(wealthList,{pid=friendList[i].pid,queryTime=module.Time.now(),wealth=_data[3] and _data[3][1] or 0})
            end
            table.sort(wealthList,function(a,b) 
                if a.wealth ~= b.wealth then
                    return a.wealth > b.wealth
                end
                return a.pid<b.pid
            end)
            for i=1,#wealthList do
                if wealthList[i].pid==selfPid then
                    friendRankList[type].selfRank=i
                end
                local _tab={pid = wealthList[i].pid,value  = wealthList[i].wealth,rank   = i}
                table.insert(friendRankList[type].list,_tab)
            end
        end
    end
    if not friendRankList[type].selfRank then return end
    if SetPasser or friendPassList[type] and friendPassList[type].lastQueryTime and module.Time.now()-friendPassList[type].lastQueryTime> refreshPeriod then
        friendPassList[type] = {list={},lastQueryTime=module.Time.now()}
        --领先者
        if OpenLevel.GetStatus(notifyOpenId) then
            for i=1,#friendRankList[type].list do
                local _passerRank = friendRankList[type].list[i].rank
                local _passerPid = friendRankList[type].list[i].pid
                if _passerRank<= friendRankList[type].selfRank and _passerPid ~= selfPid then
                    table.insert(friendPassList[type].list,_passerPid)
                end
            end
        end
    end
end

local function QueryFriendTowerFloorList(friendList,SetPasser)
    local type = Type.TrialTower
    friendRankList[type] = {type=type,queryTime=module.Time.now(),list = {}}
    local floorList = {}
    for i=1,#friendList do
        local _pid = friendList[i].pid
        local _data = GetPlayerData(_pid)
        if _data and _data[2]==0 then
            local _level = _data[7] or 1
            local _floor = _data[12] or 0
            if checkRankListLimit(_data[4],_data[7]) and _floor>0 and _level>=OpenLevel.GetCfg(3101).open_lev  then
                table.insert(floorList,{pid = friendList[i].pid,floor = _floor})
            end
        end
    end

    table.sort(floorList,function(a,b)
        if a.floor ~= b.floor then 
            return a.floor > b.floor
        end
        return a.pid<b.pid
    end)  
    for i=1,#floorList do
        if floorList[i].pid==selfPid then
            friendRankList[type].selfRank=i
        end
        local _tab={pid = floorList[i].pid,value  = floorList[i].floor,rank   = i}
        table.insert(friendRankList[type].list,_tab)
    end
    if not friendRankList[type].selfRank then return end
    if SetPasser or friendPassList[type] and friendPassList[type].lastQueryTime and module.Time.now()-friendPassList[type].lastQueryTime> refreshPeriod then
        friendPassList[type] = {list={},lastQueryTime=module.Time.now()}
        --领先者
        if OpenLevel.GetStatus(notifyOpenId) then
            for i=1,#friendRankList[type].list do
                local _passerRank = friendRankList[type].list[i].rank
                local _passerPid = friendRankList[type].list[i].pid
                if _passerRank<= friendRankList[type].selfRank and _passerPid ~= selfPid then
                    table.insert(friendPassList[type].list,_passerPid)
                end
            end
            -- ERROR_LOG(sprinttb(friendPassList[type]))
        end
    end
end

EventManager.getInstance():addListener("PLAYER_ADDDATA_CHANGE_SUCCED", function(event,value,type)
    if type ==10 and value then
        local acceptSideQuestCo = coroutine.create(function()
                    local friendList = {}
                    -- local data = NetworkService.SyncRequest(5011,{nil})
                    local data = GetPlayerAddData()
                    if data and data[2]==0 and data[3] then
                        for i=1,#data[3] do
                            table.insert(friendList,{pid=data[3][i][1],level=data[3][i][5]})
                        end
                    end
                    if selfPid and  module.playerModule.IsDataExist(selfPid) then
                        table.insert(friendList,{pid=selfPid,level=module.playerModule.IsDataExist(selfPid).level}) 
                    else
                        local plyerData = GetPlayerData(selfPid,true)
                        if plyerData and plyerData[2]==0 then
                            table.insert(friendList,{pid=selfPid,level=plyerData[7] or 0}) 
                        else
                            table.insert(friendList,{pid=selfPid,level=0})
                        end
                    end         
                    QueryFriendWealthList(friendList)
                end)
        assert(coroutine.resume(acceptSideQuestCo));
    end
end)

EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event,_SelfData)
    selfPid = _SelfData
    local acceptSideQuestCo = coroutine.create(function()
            local friendList = {}
            local data = GetPlayerAddData()
            if data and data[2]==0 and data[3] then
                for i=1,#data[3] do
                    if data[3][i][1] and data[3][i][5] then
                        table.insert(friendList,{pid=data[3][i][1],level=data[3][i][5]})
                    else
                        ERROR_LOG("friend data is part,pid",data[3][i][1],sprinttb(data[3][i]))
                    end
                end
            end
            local plyerData = GetPlayerData(selfPid)
            local _selfLv = 0
            if plyerData and plyerData[2]==0 then
                _selfLv = plyerData[7] or 0
            end
            table.insert(friendList,{pid=selfPid,level=_selfLv})

            QueryFriendLevelList(friendList,true)
            QueryFriendStarList(friendList,true)
            QueryFriendTowerFloorList(friendList,true)
        end)
    assert(coroutine.resume(acceptSideQuestCo));
end)

local SnArr={}
--获取服务器排行榜
local function GetServerRankList(type)
    if type == Type.Level or  type == Type.Star or type == Type.Wealth or type == Type.TrialTower then   
        if not rankInfo[type] or  rankInfo[type] and rankInfo[type].queryTime and module.Time.now()-rankInfo[type].queryTime>refreshPeriod then
            if type == Type.Wealth then
                NetworkService.Send(521, {nil})
            else
                local sn=NetworkService.Send(1034, {nil, type})
                SnArr[sn]=type
            end
        end
    else
        showDlgError(nil,"活动未开启")
    end
end

--获取好友排行榜
local function GetFriendRankList(type)
    local friendList = module.FriendModule.GetManager()
    table.insert(friendList,{pid=selfPid,level=module.playerModule.Get().level})
    
    if type == Type.Level then
        --0.5分钟刷新
        if not friendRankList[type] or (friendRankList[type] and friendRankList[type].queryTime and module.Time.now()-friendRankList[type].queryTime>refreshPeriod) then
            local acceptSideQuestCo = coroutine.create(function()
                        QueryFriendLevelList(friendList,true)
                        DispatchEvent("RANK_FRIENDLIST_CHANGE")
                    end)
            assert(coroutine.resume(acceptSideQuestCo));   
        end
    elseif type == Type.Star or type == Type.TrialTower then
        if type == Type.TrialTower and module.playerModule.Get().level <OpenLevel.GetCfg(3101).open_lev then
            showDlgError(nil,"活动未开启")
            return
        end
        if  not friendRankList[type] or (friendRankList[type] and friendRankList[type].queryTime and module.Time.now()-friendRankList[type].queryTime>refreshPeriod) then
            local acceptSideQuestCo = coroutine.create(function()
                        if type == Type.Star then
                            QueryFriendStarList(friendList,true)
                        elseif type == Type.TrialTower then
                            QueryFriendTowerFloorList(friendList,true)
                        end
                        DispatchEvent("RANK_FRIENDLIST_CHANGE")
                    end)
            assert(coroutine.resume(acceptSideQuestCo)); 
        end
    elseif type == Type.Wealth then
        if OpenLevel.GetStatus(1901) and module.ItemModule.GetItemCount(90033) > 0 then
            if  not friendRankList[type] or (friendRankList[type] and friendRankList[type].queryTime and module.Time.now()-friendRankList[type].queryTime>refreshPeriod) then
                local acceptSideQuestCo = coroutine.create(function()
                        QueryFriendWealthList(friendList,true)
                        DispatchEvent("RANK_FRIENDLIST_CHANGE")
                    end)
                assert(coroutine.resume(acceptSideQuestCo));
            end
        else
            showDlgError(nil,"活动未开启")
        end  
    else
        showDlgError(nil,"活动未开启")
    end
end

local function GetRankList(type,Idx)
    if Idx ==rangeIdx.Server then
        GetServerRankList(type)
        return rankInfo[type] or {}
    elseif Idx ==rangeIdx.Friend then
        GetFriendRankList(type)
        return friendRankList[type] or {}
    end 
end
--查询Server等级星星榜
EventManager.getInstance():addListener("server_respond_1035", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    local type = SnArr[sn]
    SnArr[sn] = nil

    if not type then return end

    rankInfo[type] = rankInfo[type] or {}

    if data[2] == 0 then
        rankListTimeTab[type] = {starTime = data[4],duration = data[5]}
        if data[3]==1  then
            rankInfo[type].type = type
            rankInfo[type].queryTime  = module.Time.now()
            rankInfo[type].list = {}

            for i,v in ipairs(data[6] or {}) do
                if tonumber(v[1])~=0 and tonumber(v[2])~=0 then
                    if v[1]== module.playerModule.GetSelfID() then
                        rankInfo[type].selfRank=i
                    end
                    local limitValue = type == Type.Level and OpenLevel.GetCfg(2204) and OpenLevel.GetCfg(2204).open_lev or 1
                    if v[2]>= limitValue then
                        local _tab = {pid = v[1],value = v[2],rank = i}
                        table.insert(rankInfo[type].list,_tab)
                    end
                end
            end
        else
            ERROR_LOG("未开放")
        end
        DispatchEvent("RANK_LIST_CHANGE",type)
    else
        print("查询排行榜失败",err);
    end 
end)
--查询Server财力排行榜
EventManager.getInstance():addListener("server_respond_522", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    rankInfo[Type.Wealth] = rankInfo[Type.Wealth] or {}
    if data[2]==0 then
        rankInfo[Type.Wealth].type = Type.Wealth
        rankInfo[Type.Wealth].queryTime  = module.Time.now()
        rankInfo[Type.Wealth].list = {}
        for i,v in ipairs(data[3]) do
            if v[1]== module.playerModule.GetSelfID() then
                rankInfo[Type.Wealth].selfRank=i
            end
            --upRank(Type.Wealth, v,i,rankInfo[Type.Wealth].list)
            local _tab={pid = v[1],value  = v[2],rank = i}
            table.insert(rankInfo[Type.Wealth].list,_tab)
        end
        DispatchEvent("RANK_LIST_CHANGE",Type.Wealth)
    elseif data[2]==10 then
        showDlgError(nil,"排行榜未开启")
    else
        ERROR_LOG("query WealthRanklist failed",err)
    end   
end)

local nowWealth = 0
--财力值变化
EventManager.getInstance():addListener("ARENA_WEALTH_CHANGE", function(event,oldWealth,newWealth)
    if oldWealth ~= newWealth then
        print("财力值变化")
    end
    if oldWealth < newWealth then
        print("财力值提升")
        nowWealth = newWealth    
    end
end)

--好友等级排行榜变换通知
local actorLvChange=false
local function OnPlayerLevelChange() 
    -- ERROR_LOG("--好友等级排行榜变换通知")
    actorLvChange = false

    --好友通知开放等级
    if not OpenLevel.GetStatus(notifyOpenId) then return end
    local acceptSideQuestCo = coroutine.create(function()
                local friendList = module.FriendModule.GetManager()
                table.insert(friendList,{pid=selfPid,level=module.playerModule.Get().level})
                if friendPassList[Type.Level] and friendPassList[Type.Level].list and #friendPassList[Type.Level].list>0 then
                    local passList={}
                    local selfLv = module.playerModule.Get().level
                    for i=1,#friendPassList[Type.Level].list do
                        local _passerPid = friendPassList[Type.Level].list[i]
                        local _data = GetPlayerData(_passerPid)
                        if _data and _data[2]==0 then
                            local _loserLevel = _data[7] or 0
                            if _loserLevel<selfLv then
                                table.insert(passList,_passerPid)
                            end
                        end
                    end
                    if next(passList)~=nil then
                        PopUpTipsQueue(7,{type=Type.Level,pids=passList})
                        QueryFriendLevelList(friendList,true)
                    else
                        QueryFriendLevelList(friendList) 
                    end
                else
                    --等级变化后,如果没有更高者
                    QueryFriendLevelList(friendList,true) 
                end
            end)
    assert(coroutine.resume(acceptSideQuestCo));
end

local actorStarChange = false
local function OnPlayerStarChange()
    -- ERROR_LOG("xxxxxOnPlayerStarChangexxxxxx")
    actorStarChange=false
    --好友通知开放等级
    if not OpenLevel.GetStatus(notifyOpenId) then return end
    --查询好友星星排行榜
    local acceptSideQuestCo = coroutine.create(function()
                local friendList = module.FriendModule.GetManager()
                table.insert(friendList,{pid=selfPid,level=module.playerModule.Get().level})
                if friendPassList[Type.Star] and friendPassList[Type.Star].list and #friendPassList[Type.Star].list>0 then
                    local passList={}
                    local data = GetPlayerData(selfPid,true)
                    if data and data[2]==0 then
                        local nowStar = data[11] or 0
                        for i=1,#friendPassList[Type.Star].list do
                            local _passerPid = friendPassList[Type.Star].list[i]
                            local _data = GetPlayerData(_passerPid)
                            if _data and _data[2]==0 then
                                local _loserStar = _data[11] or 0
                                if  _loserStar < nowStar then
                                    table.insert(passList,_passerPid)
                                end
                            end
                        end
                        if next(passList)~=nil then
                            PopUpTipsQueue(7,{type=Type.Star,pids=passList})
                            QueryFriendStarList(friendList,true)
                        else
                            QueryFriendStarList(friendList) 
                        end
                    end
                else
                    --等级变化后,如果没有更高者
                    QueryFriendStarList(friendList,true) 
                end
            end)
    assert(coroutine.resume(acceptSideQuestCo));
end

local actorFloorChange = false
local function OnPlayerFloorChange()
    -- ERROR_LOG("好友爬塔排行榜变化",sprinttb(friendRankList[Type.TrialTower]))
    actorFloorChange = false
    --好友通知开放等级
    if not OpenLevel.GetStatus(notifyOpenId) then return end
    --查询好友爬塔排行榜
    local acceptSideQuestCo = coroutine.create(function()
            local friendList = module.FriendModule.GetManager()
            table.insert(friendList,{pid=selfPid,level=module.playerModule.Get().level})
            if friendPassList[Type.TrialTower] and friendPassList[Type.TrialTower].list and #friendPassList[Type.TrialTower]>0 then
                local passList={}
                local data = GetPlayerData(selfPid,true)
                if data and data[2]==0 then
                    local nowFloor = data[12] or 0
                    for i=1,#friendPassList[Type.TrialTower].list do
                        local _passerPid = friendPassList[Type.TrialTower].list[i]
                        local _data = GetPlayerData(_passerPid)
                        if _data and _data[2]==0 then
                            local _loserFloor = _data[12] or 0
                            if  _loserFloor < nowFloor then
                                table.insert(passList,_passerPid)
                            end
                        end
                    end
                    if next(passList)~=nil then
                        PopUpTipsQueue(7,{type=Type.TrialTower,pids=passList})
                        QueryFriendTowerFloorList(friendList,true)
                    else
                        QueryFriendTowerFloorList(friendList) 
                    end
                end
            else
                --等级变化后,如果没有更高者
                QueryFriendTowerFloorList(friendList,true) 
            end
        end)
    assert(coroutine.resume(acceptSideQuestCo));
end

local function OnPlayerWealthChange()
    --好友通知开放等级
    if not OpenLevel.GetStatus(notifyOpenId) then return end

    if friendRankList[Type.Wealth] and friendRankList[Type.Wealth].list and friendRankList[Type.Wealth].selfRank then 
        local _wealth = friendRankList[Type.Wealth].list[friendRankList[Type.Wealth].selfRank].value
        if nowWealth > _wealth then
            local acceptSideQuestCo = coroutine.create(function()
                local friendList = module.FriendModule.GetManager()
                table.insert(friendList,{pid=selfPid,level=module.playerModule.Get().level})
                if friendPassList[Type.Wealth] and friendPassList[Type.Wealth].list and #friendPassList[Type.Wealth].list>0 then
                    local passList={}
                    for i=1,#friendPassList[Type.Wealth].list do
                        local _passerPid = friendPassList[Type.Wealth].list[i]
                        local _data = GetPlayerData(_passerPid)
                        if _data and _data[2]==0 then
                            local _loserWealth = _data[3] and _data[3][1] or 0
                            if  _loserWealth < nowWealth then
                                table.insert(passList,_passerPid)
                            end
                        end
                    end
                    if next(passList)~=nil then
                        PopUpTipsQueue(7,{type=Type.Wealth,pids=passList})
                        QueryFriendWealthList(friendList,true)
                    else
                        QueryFriendWealthList(friendList) 
                    end 
                else
                    --变化后,如果没有更高者
                    QueryFriendWealthList(friendList,true) 
                end
            end)
            assert(coroutine.resume(acceptSideQuestCo));
        end
    end
end
local function GetRankListSentRewardTime(type)
    if rankListTimeTab[type] then
        return rankListTimeTab[type]
    end
end

local selfPlayerStar = nil
local function GetSelfStarRankLitInfo()
    local selfStar = selfPlayerStar

    local selfRank = rankInfo[Type.Star] and rankInfo[Type.Star].selfRank
    return {selfStar,selfRank}
end

local not_show_tips_scene = {
    ['battle'] = true,
}

EventManager.getInstance():addListener("PLAYER_LEVEL_UP", function(event,data)
    --ERROR_LOG("playerLevelChange")
    if data then
        if not_show_tips_scene[utils.SceneStack.CurrentSceneName()] then
            actorLvChange = true
        else
            OnPlayerLevelChange()
        end
    end
end)

utils.EventManager.getInstance():addListener("SCENE_LOADED", function(event, name)
    if not_show_tips_scene[name] then
        return;
    end
    if not selfPid then return end

    if actorLvChange then
        OnPlayerLevelChange()
    end

    if actorStarChange then
    	OnPlayerStarChange()
    end

    if actorFloorChange then
        OnPlayerFloorChange()
    end

    OnPlayerWealthChange()
end)

--更新自身星星和爬塔 value 和全服 星星爬塔榜
utils.EventManager.getInstance():addListener("PLAYER_INFO_CHANGE", function(event, pid)
    --ERROR_LOG("xxxxPLAYER_INFO_CHANGExxxxx")
	if selfPid == pid then
		--自身星星数变化则刷新全服星星榜单
		if module.playerModule.Get() and module.playerModule.Get().starPoint then
			if not selfPlayerStar then
				selfPlayerStar=module.playerModule.Get().starPoint
			end
			if selfPlayerStar and selfPlayerStar ~= module.playerModule.Get().starPoint then
				selfPlayerStar=module.playerModule.Get().starPoint
				--更新全服星星榜
				-- ERROR_LOG("更新全服星星榜")
				if rankInfo[Type.Star] and rankInfo[Type.Star].queryTime then
					rankInfo[Type.Star].queryTime=0
				end
				GetServerRankList(Type.Star)
				actorStarChange = true
			end
		end
    end
end)

utils.EventManager.getInstance():addListener("TOWER_FLOOR_CHANGE", function(event, data)
    --自身爬塔层数变化则刷新全服爬塔层数榜单
    -- ERROR_LOG("TOWER_FLOOR_CHANGE+++++++++++++")
    --更新全服爬塔层数榜
    if rankInfo[Type.TrialTower] and rankInfo[Type.TrialTower].queryTime then
        rankInfo[Type.TrialTower].queryTime=0
    end
    GetServerRankList(Type.TrialTower)
    actorFloorChange = true
end)

return {
    GetRankCfg          = GetRankCfg,
    GetRankList         = GetRankList,
    GetRankRewardCfg    = GetRankRewardCfg,

    GetSelfStarInfo    = GetSelfStarRankLitInfo,
    GetRankListSentRewardTime = GetRankListSentRewardTime,
}
