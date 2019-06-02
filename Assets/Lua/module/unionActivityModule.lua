local NetworkService = require "utils.NetworkService"
local EventManager = require 'utils.EventManager'
local timeModule = require "module.Time"
local unionModule = require "module.unionModule"

local activityManager = {}
local wishActivity = {}
local exploreActivity = {}

local function errorCode(cmd, err)
    local msg = ""
    if err == 812 then
        msg = "目标没有公会"
    elseif err == 1 then
        msg = ""
    elseif err == 10 then
        msg = ""
    elseif err == 813 then
        msg = "目标和玩家公会不一致"
    elseif err == 814 then
        msg = "今日协助次数用完"
    elseif err == 820 then
        msg = "已经求助"
    elseif err == 821 then
        msg = "不需要协助"
    elseif err == 817 then
        msg = "玩家已完成该项祈愿"
    elseif err == 818 then
        msg = ""
    elseif err == 819 then
        msg = "不能帮助自己"
    elseif err == 822 then
        msg = "进度已满"
        DispatchEvent("LOCAL_EXPLORE_OVERFLOW")
    else
        msg = cmd.." errorCode "..err
    end
    print("error", err)
    if msg ~= "" then
        showDlgError(nil, msg)
    end
end

---公会活动管理
function activityManager:init(pid)
    self.pid = pid.unionPid
    self.heroPid = pid.heroPid
    self.snTab = {}
    wishActivity:init()
    exploreActivity:init()
end

---获取公会活动数据
EventManager.getInstance():addListener("LOCAL_UP_UNIONACTIVITY", function(event, data)
    activityManager:init(data)
    module.unionScienceModule.QueryAll()
end)

function activityManager:lua_string_split(str, split_char)
    local sub_str_tab = {};
    while (true) do
        local pos = string.find(str, split_char);
        if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str;
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1);
        sub_str_tab[#sub_str_tab + 1] = sub_str;
        str = string.sub(str, pos + 1, #str);
    end

    return sub_str_tab;
end

------------------------------------------------------
---探索活动
function exploreActivity:init()
    self.mapInfo = {}
    self.playerTeamInfo = {} ---对内
    self.teamInfo = {}       ---对外
    self.exploreHeroTab = {} ---探索中的英雄列表
    self.exploreHeroTabByMapId = {} ---探索中的游戏用mapId和order索引
    self.nextTimUpList = {} ---下次有奖励时刷新数据
    self.tempSelectHeroTab = {} ---英雄缓存
    self.mapEventList = {}      ---地图事件
    self.mapEventLog = {}       ---事件日志
    self.next_reward_time = 0xffffffff;
    self:queryMapInfo()
    self:QueryMapLog()
    --self:upList()
end

function exploreActivity:test()
    --self:queryMapInfo()
    --self:queryPlayerTeamInfo()
    --self:reset(2)
    self:startExplore(1, {11005, 11006})
    self:startExplore(1, {11007, 11008})
    self:startExplore(1, {11009, 11010})
    --print("dsadsd", sprinttb(self:GetTeamInfo(1)))
    --self:stopExplore(1, 3)
    --self:reward(1, 2)
end

---拉取一次探险进度
function exploreActivity:upList(time)
    StartCoroutine(function()
        WaitForSeconds(time)
        self:queryMapInfo()
    end)
end

function exploreActivity:queryMapInfo()
    NetworkService.Send(3112, {nil})
end

function exploreActivity:queryPlayerTeamInfo()
    self.next_reward_time = 0xffffffff;
    NetworkService.Send(3114, {nil})
end

----------------------------------------------------
---查询地图事件
function exploreActivity:QueryTeamEvent(mapId, order)
    NetworkService.Send(3212, {nil, mapId, order})
end

---完成事件
function exploreActivity:FinishEvent(mapId, order, uuid)
    NetworkService.Send(3214, {nil, mapId, order, uuid})
end

---拉取日志
function exploreActivity:QueryMapLog()
    NetworkService.Send(3216, {nil})
end


function exploreActivity:startExplore(mapId, heroTab, index)
    local _heroTab = {}
    for k,v in pairs(heroTab) do
        if v ~= 0 then
            _heroTab[k] = module.HeroModule.GetManager():Get(v).uuid
        end
    end
    NetworkService.Send(3116, {nil, mapId, _heroTab[1] or 0, _heroTab[2] or 0, _heroTab[3] or 0, _heroTab[4] or 0, _heroTab[5] or 0, index})
end

function exploreActivity:stopExplore(mapId, order)
    local _sn = NetworkService.Send(3118, {nil, mapId, order})
    activityManager.snTab[_sn] = {_mapId = mapId, _order = order}
end

function exploreActivity:reset(mapId)
    local _sn = NetworkService.Send(3120, {nil, mapId})
    activityManager.snTab[_sn] = {_mapId = mapId}
end

function exploreActivity:reward(mapId, order, func)
    if func then
        coroutine.resume(coroutine.create(function()
            utils.NetworkService.SyncRequest(3122, {nil, mapId, order})
            func()
        end))
    else
        NetworkService.Send(3122, {nil, mapId, order})
    end
end

function exploreActivity:upMapInfo(data)
    if self.mapInfo[data[1]] == nil then
        self.mapInfo[data[1]] = {}
    end
    self.mapInfo[data[1]].mapId              = data[1]
    self.mapInfo[data[1]].property           = data[2]
    self.mapInfo[data[1]].progress           = data[3]
    self.mapInfo[data[1]].exploreTeamCount   = data[4]
    self.mapInfo[data[1]].giftBox            = data[5]
end

function exploreActivity:splitDepot(tab, data)
    local _depot = activityManager:lua_string_split(data, "|")
    for i = 1, #_depot - 1 do
        local _tempDepot = activityManager:lua_string_split(_depot[i], ",")
        local _temp = {}
        _temp.type  = tonumber(_tempDepot[1])
        _temp.id    = tonumber(_tempDepot[2])
        _temp.count = tonumber(_tempDepot[3])
        table.insert(tab, _temp)
    end
end

function exploreActivity:upExploreHeroTab(mapId, order, data)
    if self.exploreHeroTabByMapId[mapId] == nil then
        self.exploreHeroTabByMapId[mapId] = {}
    end
    if self.exploreHeroTabByMapId[mapId][order] == nil then
        self.exploreHeroTabByMapId[mapId][order] = {}
    end
    for i = 6, 10 do
        self.exploreHeroTab[data[i]]  = true
        table.insert(self.exploreHeroTabByMapId[mapId][order], data[i])
    end
end

function exploreActivity:removeExploreHero(mapId, order)
    if order == nil  and self.exploreHeroTabByMapId[mapId] then
        for k,v in pairs(self.exploreHeroTabByMapId[mapId]) do
            for i,p in pairs(v) do
                self.exploreHeroTab[p] = false
            end
        end
        return
    end

    if self.exploreHeroTabByMapId[mapId] == nil or self.exploreHeroTabByMapId[mapId][order] == nil then return end
    for k,v in pairs(self.exploreHeroTabByMapId[mapId][order]) do
        self.exploreHeroTab[v] = false
    end
    self.exploreHeroTabByMapId[mapId][order] = {}
end

function exploreActivity:upTeamInfo()
    self.teamInfo = {}
    for k,v in pairs(self.playerTeamInfo) do
        for j,p in pairs(v) do
            self.teamInfo[p.index] = p
        end
    end
end

function exploreActivity:upPlayerTeamInfo(data, isRemove)

    -- ERROR_LOG("查询地图数据--->>>>",sprinttb(data));
    local _temp = {}
    _temp.mapId            = data[1]
    _temp.order            = data[2]
    _temp.startExploreTime = data[3]  ---开始探索时间
    _temp.nextRewardTime   = data[4]  ---下次获得奖励的时间
    _temp.rewardDepot      = {}
    self:splitDepot(_temp.rewardDepot, data[5]) ---已经探索得到的奖励   41,90003,100|41,90004,10|
    self:QueryTeamEvent(_temp.mapId, _temp.order)   ---查询事件信息
    _temp.heroTab          = {}
    for i = 6, 10 do
        local _id = data[i]
        if module.HeroModule.GetManager():GetByUuid(data[i]) then
            _id = module.HeroModule.GetManager():GetByUuid(data[i]).id
        end
        self:SetTempHeroTab(_temp.mapId, i-5, _id)
        table.insert(_temp.heroTab, _id)
    end
    _temp.index = data[11]
    _temp.count = data[12]
    _temp.maxCount = data[13]
    if self.mapInfo[data[1]].progress ~= 100 then
        self:upExploreHeroTab(_temp.mapId, _temp.order, data)
    end
    if self.playerTeamInfo[data[1]] == nil then
        self.playerTeamInfo[data[1]] = {}
    end
    self.playerTeamInfo[data[1]][data[2]] = _temp
    if self.nextTimUpList[_temp.nextRewardTime] == nil then
        self.nextTimUpList[_temp.nextRewardTime] = true
    end

    if _temp.nextRewardTime < (self.next_reward_time or 0xffffffff) then
        self.next_reward_time = _temp.nextRewardTime
    end

    if self.next_reward_time < module.Time.now() + 5 then
        self.next_reward_time = module.Time.now() + 5;
    end
end

function exploreActivity:GetNextRewardTime()
    return self.next_reward_time or 0xffffffff;
end

---获取英雄状态，是否正在探索
function exploreActivity:GetHeroState(heroId)
    return self.exploreHeroTab[heroId] or false
end

---获取地图消息
function exploreActivity:GetMapInfo(mapId)
    if mapId == nil then
        return self.mapInfo
    else
        return self.mapInfo[mapId]
    end
end

function exploreActivity:GetTempHeroTab(index)
    if not index then
        return self.tempSelectHeroTab
    end
    return self.tempSelectHeroTab[index]
end

function exploreActivity:SetTempHeroTab(teamIndex, index, heroId)
    self.tempSelectHeroTab[teamIndex] = self.tempSelectHeroTab[teamIndex] or {}
    self.tempSelectHeroTab[teamIndex][index] = self.tempSelectHeroTab[teamIndex][index] or {}
    self.tempSelectHeroTab[teamIndex][index] = heroId
end

---获取队伍消息
function exploreActivity:GetTeamInfo(index)
    if module.Time.now() >= self.next_reward_time then
        self:queryPlayerTeamInfo();
    end

    if index == nil then
        return self.teamInfo
    else
        return self.teamInfo[index]
    end
end

function exploreActivity:GetTeamInfoNumber(index)
    local _counst = 0
    for k,v in pairs(self.teamInfo) do
        if v.mapId == index then
            _counst = _counst + 1
        end
    end
    return _counst
end

function exploreActivity:GetMapEventList(mapId, teamId)
    if not mapId then
        return self.mapEventList or {}
    end
    if not teamId then
        return self.mapEventList[mapId]
    end
    if self.mapEventList[mapId] then
        return self.mapEventList[mapId][teamId or 1]
    end
end

function exploreActivity:GetMapLog()
    return self.mapEventLog
end

EventManager.getInstance():addListener("LOCAL_UNION_GOTO_EXPLORE", function(event, data)
    exploreActivity.tempSelectHeroTab[data.index] = {}
    exploreActivity.tempSelectHeroTab[data.index] = data.tab
end)

EventManager.getInstance():addListener("server_respond_3113", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        exploreActivity.mapInfo = {}
        for i = 1, #data[3] do
            exploreActivity:upMapInfo(data[3][i])
        end
        ---获得map消息后再获取队伍消息
        exploreActivity:queryPlayerTeamInfo()
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3115", function(event, cmd, data)
    -- ERROR_LOG("server_respond_3115",sprinttb(data));
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        exploreActivity.playerTeamInfo = {}
        for i = 1, #data[3] do
            if #data[3][i] >= 1 then
                exploreActivity:upPlayerTeamInfo(data[3][i])
            end
        end
        exploreActivity:upTeamInfo()
        DispatchEvent("LOCAL_UNION_EXPLORE_TEAMCHANGE")
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3117", function(event, cmd, data)
    -- ERROR_LOG("server_respond_3117",sprinttb(data));
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        exploreActivity:queryMapInfo()
        --[[if #data[3] >= 1 then
            exploreActivity:upPlayerTeamInfo(data[3])
            exploreActivity:upTeamInfo()
            --DispatchEvent("LOCAL_UNION_EXPLORE_TEAMCHANGE")
        end
        --]]
        --exploreActivity:queryMapInfo()
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3119", function(event, cmd, data)
    -- ERROR_LOG("server_respond_3119",sprinttb(data));
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        local _tab = activityManager.snTab[sn] ---停止探索是改变本地英雄状态
        exploreActivity:removeExploreHero(_tab._mapId, _tab._order)
        exploreActivity.playerTeamInfo[_tab._mapId][_tab._mapId] = nil ---清空
        exploreActivity:queryMapInfo()
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3121", function(event, cmd, data)
    -- ERROR_LOG("server_respond_3121",sprinttb(data));
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        local _tab = activityManager.snTab[sn]
        exploreActivity:removeExploreHero(_tab._mapId)
        exploreActivity.playerTeamInfo[_tab._mapId] = {}
        exploreActivity:queryMapInfo()
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3123", function(event, cmd, data)

    -- ERROR_LOG("server_respond_3123",sprinttb(data));
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        exploreActivity:queryMapInfo()
    else
        errorCode(cmd, err)
    end
end)

local function upMapEventInfo(v)
    if not v then return end
    local _heroId = 0
    if module.HeroModule.GetManager():GetByUuid(v[4]) then
        _heroId = module.HeroModule.GetManager():GetByUuid(v[4]).id
    end
    local _event = {
        mapId       = v[1],
        teamId      = v[2],
        eventId     = v[3],
        heroId      = _heroId,
        uuid        = v[5],
        beginTime   = v[6],
        endTime     = v[7],
    }
    if not exploreActivity.mapEventList[v[1]] then exploreActivity.mapEventList[v[1]] = {} end
    if not exploreActivity.mapEventList[v[1]][v[2]] then exploreActivity.mapEventList[v[1]][v[2]] = {} end
    exploreActivity.mapEventList[v[1]][v[2]][_event.uuid] = _event
    DispatchEvent("LOCAL_EXPLORE_MAPEVENT_CHANGE")
end

---查询事件
EventManager.getInstance():addListener("server_respond_3213", function(event, cmd, data)
    ERROR_LOG("server_respond_3213",sprinttb(data));
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        exploreActivity.mapEventList = {}
        for i,v in ipairs(data[3]) do
            upMapEventInfo(v)
        end
    else
        errorCode(cmd, err)
    end
end)

---完成事件
EventManager.getInstance():addListener("server_respond_3215", function(event, cmd, data)

    ERROR_LOG("server_respond_3215",sprinttb(data));
    local sn = data[1];
    local err = data[2];
    if err == 0 then

    else
        errorCode(cmd, err)
    end
end)

local function insertLog(data)
    if not data then return end
    module.playerModule.Get(data[1], function ()
        local _player = module.playerModule.Get(data[1])
        local _tab = {
            pid     = data[1],
            name    = _player.name,
            mapId   = data[2],
            teamId  = data[3],
            eventId = data[4],
        }
        table.insert(exploreActivity.mapEventLog, _tab)
        DispatchEvent("LOCAL_UNION_EXPLORE_LOG_CHANGE")
    end)
end

---查询日志
EventManager.getInstance():addListener("server_respond_3217", function(event, cmd, data)

    ERROR_LOG("server_respond_3217",sprinttb(data));
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        for i,v in ipairs(data[3]) do
            local type, content = v[1], v[2]
            if type == 1 then
                insertLog(content)
            end
        end
    else
        errorCode(cmd, err)
    end
end)

---事件变化
EventManager.getInstance():addListener("server_notify_1134", function(event, cmd, data)

    ERROR_LOG("server_notify_1134",sprinttb(data));
    print("server_notify_1134", sprinttb(data))
    if data[1] == 0 then
        for i,_info in ipairs(data[2]) do
            if exploreActivity.mapEventList[_info[1]] and exploreActivity.mapEventList[_info[1]][_info[2]] then
                exploreActivity.mapEventList[_info[1]][_info[2]][_info[3]] = nil
                DispatchEvent("LOCAL_EXPLORE_MAPEVENT_CHANGE")
            end
        end
    elseif data[1] == 1 then
        upMapEventInfo(data[2])
    end
end)

---地图增加
EventManager.getInstance():addListener("server_notify_1135", function(event, cmd, data)
    print("server_notify_1135", sprinttb(data))
    ERROR_LOG("server_notify_1135",sprinttb(data));

end)

---日志改变
EventManager.getInstance():addListener("server_notify_1136", function(event, cmd, data)
    ERROR_LOG("server_notify_1136",sprinttb(data));
    local type, content = data[1], data[2]
    if type == 1 then
        insertLog(content)
    end
end)


------------------------------------------------------
---祈愿活动
function wishActivity:init()
    self:initTab()
    self:queryPlayerInfo()
    self:queryAssistInfo()
    self:queryLog()
    self:upList()
end

function wishActivity:initTab()
    self.wishInfo = {}
    self.assistInfo = {}
    self.logList = {}
end

function wishActivity:queryPlayerInfo()
    NetworkService.Send(3098, {nil})
end

function wishActivity:queryAssistInfo()
    NetworkService.Send(3108, {nil})
end

---获取日志
function wishActivity:queryLog()
    NetworkService.Send(3218, {nil})
end

function wishActivity:upList()
    StartCoroutine(function()
        if unionModule.Manage:GetUionId() ~= 0 then
            WaitForSeconds(60)
            if unionModule.Manage:GetUionId() ~= 0 then
                self:queryPlayerInfo()
                self:queryAssistInfo()
                self:upList()
            end
        end
    end)
end

---领取奖励
function wishActivity:reward(func)

    ERROR_LOG("领取奖励")
    if func then
        coroutine.resume(coroutine.create(function()
            utils.NetworkService.SyncRequest(3104, {nil, self.wishInfo.cfg_id})
            func()
        end))
    else
        NetworkService.Send(3104, {nil, self.wishInfo.cfg_id})
    end
end

---求助
function wishActivity:assist(index)
    local _sn = NetworkService.Send(3106, {nil, self.wishInfo.cfg_id, index})
    activityManager.snTab[_sn] = index
end

---帮助别人
function wishActivity:assistOther(useType, targetId, cfg_id, index, tableIndex)
    local _sn = NetworkService.Send(3110, {nil, useType, targetId, cfg_id, index})
    activityManager.snTab[_sn] = tableIndex
end

---更新进度
function wishActivity:upProgress(useType, index)
    local _sn = NetworkService.Send(3102, {nil, useType, self.wishInfo.cfg_id, index})
    activityManager.snTab[_sn] = index
end

---重置
function wishActivity:reset(useType)
    NetworkService.Send(3100, {nil, useType})
end

function wishActivity:GetLogList()
    return self.logList
end

function wishActivity:upWishData(_tab)
    self.wishInfo.cfg_id                 = _tab[1]
    self.wishInfo.progress               = _tab[2]
    self.wishInfo.progress_flag          = _tab[3]
    self.wishInfo.today_seek_help_count  = _tab[4]
    self.wishInfo.today_help_count       = _tab[5]
    self.wishInfo.has_draw_reward        = _tab[6]
    self.wishInfo.seek_help_flag         = _tab[7]
    self.wishInfo.lastTime               = _tab[8]
    self.wishInfo.product_type           = _tab[9]
    self.wishInfo.product_id             = _tab[10]
    self.wishInfo.product_value          = _tab[11]
    self.wishInfo.winshTab               = {}
    local _wishTab = _tab[12] or {}
    local _bitTab = BIT(_tab[3])
    local _seekHelpTab = BIT(_tab[7])
    for i = 1, #_wishTab do
        local _tempTab = {}
        _tempTab.consume_type  = _wishTab[i][1]
        _tempTab.consume_id    = _wishTab[i][2]
        _tempTab.consume_value = _wishTab[i][3]
        _tempTab.cost          = _wishTab[i][4]
        _tempTab.index         = i
        if _seekHelpTab[i] ~= nil and _seekHelpTab[i] == 1 then
            _tempTab.isHelp = true
        else
            _tempTab.isHelp = false
        end
        if _bitTab[i] ~= nil and _bitTab[i] == 1 then
            _tempTab.show = false
        else
            _tempTab.show = true
        end
        table.insert(self.wishInfo.winshTab, _tempTab)
    end
end

function wishActivity:upAssistData(data)
    for i = 1, #data do
        local _tab = data[i]
        local _tempTab = {}
        _tempTab.pid            = _tab[1]
        _tempTab.cfg_id         = _tab[2]
        _tempTab.index          = _tab[3]
        _tempTab.consume_type   = _tab[4][1]
        _tempTab.consume_id     = _tab[4][2]
        _tempTab.consume_value  = _tab[4][3]
        _tempTab.cost           = _tab[4][4]
        _tempTab.contribution   = _tab[4][5]
        table.insert(self.assistInfo, _tempTab)
    end
end

function wishActivity:GetWishInfo()
    if self.wishInfo == nil then
        self.wishInfo = {}
    end
    return self.wishInfo
end

function wishActivity:GetWishInfoItem(index)
    if self.wishInfo == nil then
        self.wishInfo = {}
    end
    if self.wishInfo.winshTab == nil then
        self.wishInfo.winshTab = {}
    end

    if index == nil then
        return self.wishInfo.winshTab
    else
        return self.wishInfo.winshTab[index]
    end
end

function wishActivity:GetAssisList(index)
    if self.assistInfo == nil then
        self.assistInfo = {}
    end
    if index == nil then
        return self.assistInfo
    else
        return self.assistInfo[index]
    end
end


EventManager.getInstance():addListener("server_respond_3099", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        if #data[3] > 0 then
            wishActivity:upWishData(data[3])
            DispatchEvent("LOCAL_WISHDATA_CHANGE")
        end
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3101", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        if #data[3] > 0 then
            wishActivity:upWishData(data[3])
            DispatchEvent("LOCAL_WISHDATA_CHANGE")
            DispatchEvent("LOCAL_ASSISTDATA_CHANGE")
        end
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3109", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        wishActivity.assistInfo = {}
        wishActivity:upAssistData(data[3])
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3105", function(event, cmd, data)

    ERROR_LOG("server_respond_3105",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        wishActivity.wishInfo.has_draw_reward = 1
        DispatchEvent("LOCAL_UNIONACTIVITY_GETOVER")
        showDlgError(nil, "领取成功")
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3107", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        -- local _index = activityManager.snTab[sn]
        -- local _tempTab = {}
        -- _tempTab.pid            = activityManager.pid
        -- _tempTab.cfg_id         = wishActivity.wishInfo.cfg_id
        -- _tempTab.index          = _index
        -- _tempTab.consume_type   = wishActivity.wishInfo.winshTab[_index].consume_type
        -- _tempTab.consume_id     = wishActivity.wishInfo.winshTab[_index].consume_id
        -- _tempTab.consume_value  = wishActivity.wishInfo.winshTab[_index].consume_value
        -- _tempTab.cost           = wishActivity.wishInfo.winshTab[_index].cost
        -- _tempTab.contribution   = 20
        -- table.insert(wishActivity.assistInfo, _tempTab)
        wishActivity:queryPlayerInfo()
        wishActivity:queryAssistInfo()
        showDlgError(nil, "求助成功")
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3103", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        wishActivity.wishInfo.winshTab[activityManager.snTab[sn]].show = false
        wishActivity.wishInfo.progress = wishActivity.wishInfo.progress + 1
        wishActivity:queryAssistInfo()
        DispatchEvent("LOCAL_WISHDATA_CHANGE")
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_3111", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        table.remove(wishActivity.assistInfo, activityManager.snTab[sn])
        wishActivity.wishInfo.today_help_count = wishActivity.wishInfo.today_help_count + 1
        DispatchEvent("LOCAL_ASSISTDATA_CHANGE")
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_notify_27", function(event, cmd, data)
    wishActivity.wishInfo.winshTab[data[2]].show = false
    wishActivity.wishInfo.progress = wishActivity.wishInfo.progress + 1
    DispatchEvent("LOCAL_WISHDATA_CHANGE")
end)

local function upWishLog(data)
    if not data then return end
    module.playerModule.Get(data[1], function ()
        module.playerModule.Get(data[2], function ()
            local _player = module.playerModule.Get(data[1])
            local _otherPlayer = module.playerModule.Get(data[2])
            local _tab = {
                name = _player.name,
                otherName = _otherPlayer.name,
            }
            table.insert(wishActivity.logList, _tab)
            DispatchEvent("LOCAL_WISHDATA_LOG_CHANGE")
        end)
    end)
end

EventManager.getInstance():addListener("server_respond_3219", function(event, cmd, data)
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        for i,v in ipairs(data[3]) do
            upWishLog(v)
        end
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_notify_1137", function(event, cmd, data)
    upWishLog(data)
end)

return {
    WishManage      = wishActivity,          ---祈愿
    ExploreManage   = exploreActivity,       ---探索
}
