local EventManager = require 'utils.EventManager'
local NetworkService = require "utils.NetworkService"

local function errorCode(cmd, err)
    print("error cmd", cmd, err)
end

local function redCfg(v, tab)
    local _temp = {}
    _temp.dec = v.quest
    _temp.count = v.type
    _temp.answer = {}
    _temp.rightAnswer = {}
    for j = 1, 3 do
        for i = 1, 3 do
            local _tempAnswer = {}
            local _k = ((j - 1)*3 + i)
            _tempAnswer.answer = v["answer".._k]
            _tempAnswer.icon = v["answer_icon".._k]
            _tempAnswer.id = _k
            if _tempAnswer.answer and _tempAnswer.answer ~= 0 then
                if not _temp.answer[j] then _temp.answer[j] = {} end
                table.insert(_temp.answer[j], _tempAnswer)
            end
        end
    end
    for i = 1, 3 do
        local _value = v["right_answer"..i]
        if _value and _value ~= 0 then
            local _valueTab = {}
            _valueTab.icon = v["answer_icon".._value]
            _valueTab.answer = v["answer".._value]
            _valueTab.id = _value
            table.insert(_temp.rightAnswer, _valueTab)
        end
    end
    tab[v.id] = _temp
end

local answerCfgTab = nil
local function getCfg(index)
    if answerCfgTab == nil then
        answerCfgTab = {}
        DATABASE.ForEach("meiridati", function(v)
            redCfg(v, answerCfgTab)
        end)
    end
    return answerCfgTab[index]
end

local weekAnswerCfgTab = nil
local function getWeekCfg(index)
    if weekAnswerCfgTab == nil then
        weekAnswerCfgTab = {}
        DATABASE.ForEach("datijingsai", function(v)
            redCfg(v, weekAnswerCfgTab)
        end)
    end
    return weekAnswerCfgTab[index]
end

local weekReward = nil
local function loadWeekReward(index)
    if not weekReward then
        weekReward = {}
        DATABASE.ForEach("reward_zhoudati", function(v, i)
            weekReward[i] = {}
            for j = 1, 3 do
                local _temp = {}
                _temp.type = v["reward_type"..j]
                _temp.value = v["reward_value"..j]
                _temp.id = v["reward_id"..j]
                table.insert(weekReward[i], _temp)
            end
        end)
    end
    return weekReward[index]
end

local function getWeekReward(score)
    local _score = score or 1
    local _tempTab = loadWeekReward(1)
    local _tab = {}
    for i,v in ipairs(_tempTab) do
        local _tb = {}
        if v.type ~= 0 and v.value ~= 0 then
            _tb.type = v.type
            _tb.value = v.value * _score
            _tb.id = v.id
            table.insert(_tab, _tb)
        end
    end
    return _tab
end

local function upWeekCount()
    NetworkService.Send(17037, {nil})
end

local weekCount = nil
local function getWeekCount()
    if weekCount then
        return weekCount
    end
    upWeekCount()
end

EventManager.getInstance():addListener("server_respond_17038", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        weekCount = data[3]
    else
        errorCode(cmd, err)
    end
    DispatchEvent("LOCAL_ANSWER_STATUS_CHANGE")
end)

local answerInfo = {}
local function queryInfo()
    if answerInfo.questionId then
        DispatchEvent("LOCAL_ANSWER_INFO_CHANGE")
        return true
    else
        if coroutine.isyieldable() then
            return utils.NetworkService.SyncRequest(17014, {nil})
        else
            NetworkService.Send(17014, {nil})
        end
    end
end

local function answer(id, index)
    NetworkService.Send(17016, {nil, id, index})
end

local function reward()
    NetworkService.Send(17018, {nil})
end

local function help()
    NetworkService.Send(17020, {nil})
end

local function initAnswerInfo(data)
    answerInfo.questionId   = data[1]
    answerInfo.round        = data[2]
    answerInfo.correctCount = data[3]
    answerInfo.finishCount  = data[4]
    answerInfo.reward       = data[5]
    answerInfo.rewardFlag   = data[6]
    answerInfo.helpCount    = data[7]
    answerInfo.deadline     = data[8]
    answerInfo.correct      = data[9]
    DispatchEvent("LOCAL_ANSWER_INFO_CHANGE")
end

local function getInfo()
    return answerInfo
end

EventManager.getInstance():addListener("server_respond_17015", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        initAnswerInfo(data[3])
    else
        errorCode(cmd, err)
        DispatchEvent("LOCAL_ANSWER_NOTINTIME")
    end
end)

EventManager.getInstance():addListener("server_respond_17017", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        initAnswerInfo(data[3])
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_17019", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        answerInfo.rewardFlag = 1
        DispatchEvent("LOCAL_ANSWER_REWARD_OK")
    else
        errorCode(cmd, err)
    end
end)

EventManager.getInstance():addListener("server_respond_17021", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        answerInfo.helpCount = answerInfo.helpCount + 1
        DispatchEvent("LOCAL_ANSWER_HELP_OK")
    else
        errorCode(cmd, err)
    end
end)


----周答题
local weekAnswerInfo = {}
local nowLocalInfo = {}
local playerStatusTab = {}

local function matching(typeId)
    NetworkService.Send(17023, {nil, typeId})
end

EventManager.getInstance():addListener("server_respond_17024", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        -- print("17024", sprinttb(data))
    else
        errorCode(cmd, err)
    end
end)

local function cancelMatch()
    NetworkService.Send(17025, {nil})
end

EventManager.getInstance():addListener("server_respond_17026", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        -- print("17026", sprinttb(data))
    else
        errorCode(cmd, err)
    end
end)

local function selectTeamInfo()
    NetworkService.Send(17027, {nil})
end

local function upTeamInfo(data)
    if not weekAnswerInfo.teamInfo then weekAnswerInfo.teamInfo = {} end
    for i,v in ipairs(data) do
        local _temp = {}
        _temp.id = v[1]
        _temp.score = v[2]
        _temp.name = v[3]
        _temp.icon = v[4]
        if weekAnswerInfo.teamInfo and weekAnswerInfo.teamInfo[i] then
            _temp.addScore = v[2] - weekAnswerInfo.teamInfo[i].score
        else
            _temp.addScore = v[2]
        end
        weekAnswerInfo.teamInfo[i] = _temp
    end
    DispatchEvent("LOCAL_WEEKANSWER_TEAMINFO_CHANGE")
end

local function nextQueryType(typeId)
    NetworkService.Send(17029, {nil, typeId})
end

EventManager.getInstance():addListener("server_respond_17030", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        -- print("17030", sprinttb(data))
    else
        errorCode(cmd, err)
    end
end)

local function weekAnswer(answer)
    NetworkService.Send(17031, {nil, answer})
end

EventManager.getInstance():addListener("server_respond_17032", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        DispatchEvent("LOCAL_WEEKANSWER_ANSWER_OVER")
    else
        errorCode(cmd, err)
    end
end)

local function upWeekQueryInfo(queryId, round, nextTime, queryType, selectId, selectName)
    weekAnswerInfo.queryInfo = {}
    weekAnswerInfo.queryInfo.queryId = queryId
    weekAnswerInfo.queryInfo.round = 1
    weekAnswerInfo.queryInfo.queryRound = round
    weekAnswerInfo.queryInfo.nextTime = nextTime
    weekAnswerInfo.queryInfo.queryType = queryType
    weekAnswerInfo.queryInfo.selectId = selectId
    weekAnswerInfo.queryInfo.selectName = selectName
    DispatchEvent("LOCAL_WEEKANSWER_QUERYINFO_CHANGE")
end

local function upRankingInfo(data)
    weekAnswerInfo.rankingInfo = {}
    for i,v in ipairs(data) do
        local _temp = {}
        _temp.id = v[1]
        _temp.score = v[2]
        _temp.name = v[3]
        _temp.icon = v[4]
        table.insert(weekAnswerInfo.rankingInfo, _temp)
    end
    table.sort(weekAnswerInfo.rankingInfo, function(a, b)
        return a.score > b.score
    end)
end

local function upRankingItem(data)
    weekAnswerInfo.rankingItemInfo = {}
    for k,v in pairs(data) do
        local _tabTemp = {}
        for j,p in pairs(v[2]) do
            local _temp = {}
            _temp.type = p[1]
            _temp.id = p[2]
            _temp.value = p[3]
            if _temp.type ~= 0 and _temp.id ~= 0 then
                table.insert(_tabTemp, _temp)
            end
        end
        weekAnswerInfo.rankingItemInfo[v[1]] = _tabTemp
    end
end

EventManager.getInstance():addListener("server_respond_17028", function(event, cmd, data)
    local sn = data[1]
    local err = data[2]
    if err == 0 then
        upTeamInfo(data[3])
        upWeekQueryInfo(data[4], data[5], data[6], data[7], data[8], data[9])
        weekAnswerInfo.status = true
    else
        weekAnswerInfo.status = false
        errorCode(cmd, err)
    end
    upWeekCount()
end)

---发题
EventManager.getInstance():addListener("server_notify_17033", function(event, cmd, data)
    -- print("server_notify_17033", sprinttb(data))
    playerStatusTab = {}
    upTeamInfo(data[5])
    upWeekQueryInfo(data[3], data[4], data[6], data[7], data[8], data[9])
    DispatchEvent("LOCAL_WEEKANSWER_SENDQUERY")
end)

---答题结束
EventManager.getInstance():addListener("server_notify_17034", function(event, cmd, data)
    -- print("server_notify_17034", sprinttb(data))
    nowLocalInfo = {}
    playerStatusTab = {}
    weekAnswerInfo.status = false
    upRankingInfo(data[3])
    upRankingItem(data[4])
    upWeekCount()
    DispatchEvent("LOCAL_WEEKANSWER_OVER")
end)

---匹配成功
EventManager.getInstance():addListener("server_notify_17035", function(event, cmd, data)
    -- print("server_notify_17035", sprinttb(data))
    upWeekQueryInfo(data[3], data[4], data[5], data[6], data[7], data[8])
    weekAnswerInfo.status = true
    DispatchEvent("LOCAL_WEEKANSWER_MATCHING_OK")
end)


EventManager.getInstance():addListener("server_notify_17036", function(event, cmd, data)
    -- print("server_notify_17036", sprinttb(data))
    playerStatusTab[data[3]] = data[4]
    DispatchEvent("LOCAL_WEEKANSWER_PLAYER_ANSWER_STATUS", {id = data[3], status = data[4]})
end)

local function getWeekQueryInfo()
    return weekAnswerInfo.queryInfo or {}
end

local function getTeamInfo()
    if not weekAnswerInfo.teamInfo then
        selectTeamInfo()
    end
    return weekAnswerInfo.teamInfo or {}
end

local function getTeamStatus()
    return weekAnswerInfo.status or false
end

local function getRankingInfo()
    return weekAnswerInfo.rankingInfo or {}
end

local function getRankingItem(pid)
    return weekAnswerInfo.rankingItemInfo[pid] or {}
end

local function getPlayerStatus()
    return playerStatusTab
end

local function getNowLocalInfo()
    return nowLocalInfo
end


local questTypeTab = {
    "守墓人题",
    "历史题",
    "体育题",
    "数学题",
    "常识题",
}

return {
    GetCfg = getCfg,
    GetInfo = getInfo,
    QueryInfo = queryInfo,
    Answer = answer,
    Reward = reward,
    Help = help,

    ----周答题
    GetWeekCfg     = getWeekCfg,        ---周答题题库
    GetWeekReward  = getWeekReward,
    Matching       = matching,          ---匹配
    CancelMatch    = cancelMatch,       ---取消匹配
    SelectTeamInfo = selectTeamInfo,    ---查找队伍信息
    NextQueryType  = nextQueryType,     ---下题类型
    WeekAnswer     = weekAnswer,        ---答题

    GetTeamInfo    = getTeamInfo,
    GetTeamStatus  = getTeamStatus,

    GetWeekQueryInfo = getWeekQueryInfo,
    GetRankingInfo   = getRankingInfo,
    GetRankingItem   = getRankingItem,
    QuestTypeTab     = questTypeTab,

    GetNowLocalInfo = getNowLocalInfo,  ---当前本地的状态
    GetPlayerStatus = getPlayerStatus,
    GetWeekCount    = getWeekCount, ---获取当前周答题次数
}
