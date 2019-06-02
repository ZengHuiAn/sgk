local openLevel = require "config.openLevel"
local UserDefault = require "utils.UserDefault"
local activityConfig = require "config.activityConfig"

local recommendActivityTab = nil

local function GetCfg(id)
    if not recommendActivityTab then
        recommendActivityTab = LoadDatabaseWithKey("recommend_activity", "id")
    end
    if not id then
        return recommendActivityTab
    end
    return recommendActivityTab[id]
end

local function check(cfg)
    if not cfg then
        return false, 1
    end
    if not openLevel.GetStatus(cfg.openlev) then
        return false, 2
    end
    if cfg.openlev2 ~= 0 then
        if not openLevel.GetStatus(cfg.openlev2) then
            return false, 3
        end
    end
    for i = 1, 3 do
        if cfg["event_type"..i] == 1 then
            if cfg["event_id"..i] ~= 0 then
                if cfg["event_count"..i] >= module.ItemModule.GetItemCount(cfg["event_id"..i]) then
                    return false, 4
                end
            end
        elseif cfg["event_type"..i] == 2 then
            local _,canGather = module.RedDotModule.Type.Manor.Manufacture.check()
            if not canGather then
                return false, 5
            end
        elseif cfg["event_type"..i] == 3 then
            if cfg["event_id"..i] ~= 0 then
                local _quest = module.QuestModule.Get(cfg["event_id"..i])
                if _quest then
                    if _quest.finishCount >= cfg["event_count"..i] then
                        return false, 6
                    end
                else
                    return false, 7
                end
            end
        elseif cfg["event_type"..i] == 4 then
            if cfg["event_count"..i] ~= 0 then
                local _count = module.answerModule.GetInfo().finishCount or 0
                if _count >= cfg["event_count"..i] then
                    return false, 12
                end
            end
        elseif cfg["event_type"..i] == 5 then
            if not module.RedDotModule.GetStatus(module.RedDotModule.Type.DrawCard.DrawCardFree) then
                return false, 8
            end
        elseif cfg["event_type"..i] == 6 then
            local _info = module.QuestModule.CityContuctInfo()
            if cfg["event_count"..i] <= _info.today_count then
                return false, 9
            end
        elseif cfg["event_type"..i] == 7 then
            if cfg["event_count"..i] ~= 0 then
                local _list = module.QuestModule.GetList(cfg["event_count"..i], 0)
                if #_list == 0 then
                    return false, 10
                end
            end
        elseif cfg["event_type"..i] == 8 then
            local _boss = module.worldBossModule.GetBossInfo(1)
            if not (_boss and _boss.type == 1) then
                return false, 11
            end
        end
    end
    return true
end

local function checkActivity(cfg, offset)
    if not cfg then
        return false
    end
    -- if not openLevel.GetStatus(cfg.openlev) then
    --     return false
    -- end
    -- if cfg.openlev2 ~= 0 then
    --     if not openLevel.GetStatus(cfg.openlev2) then
    --         return false
    --     end
    -- end
    local _flag, _status = check(cfg)
    if not _flag then
        return _flag, _status
    end

    local _actCf = activityConfig.GetActivity(cfg.quest_type)
    if not _actCf then
        return false
    end

    local _beginTime = _actCf.begin_time
    local _loop_duration = _actCf.loop_duration
    if offset then
        _beginTime = _beginTime + cfg.delay_begin_time
        _loop_duration = _loop_duration + cfg.delay_end_time
    end

    local _week = tonumber(os.date("%w",math.floor(module.Time.now())))
    if _actCf.week & (1 << _week) == 0 then
        return false
    end

    if _beginTime > 0 and _actCf.end_time > 0 and _actCf.period > 0 then
        local total_pass = module.Time.now() - _beginTime
        local period_pass = total_pass - math.floor(total_pass / _actCf.period) * _actCf.period
        local period_begin = module.Time.now() - period_pass
        if not (module.Time.now() > period_begin and module.Time.now() < (period_begin + _loop_duration)) then
            return false
        end
    end

    local _count = activityConfig.GetActiveCountById(_actCf.id)
    if _count.finishCount >= _count.joinLimit then
        return false
    end

    if cfg.event_type1 == 8 then
        local _boss = module.worldBossModule.GetBossInfo(1)
        if not (_boss and _boss.type == 1) then
            return false
        else
            _actCf.gototype = 1
            _actCf.findnpcname = _boss.id
        end
    end
    return cfg
end

local CityContuctId = {41, 42, 43, 44}
local function GetQuest(recommendId)
    local _cfg = GetCfg(recommendId)
    if not _cfg then
        return
    end
    if _cfg.display_type == 1 then       ---建设关卡
        local _list = module.QuestModule.GetList(nil, 0)
        for k,v in pairs(_list) do
            for i,k in ipairs(CityContuctId) do
                if v.type == k then
                    return v
                end
            end
        end
    elseif _cfg.display_type == 2 then   ---试炼
        local _list = module.QuestModule.GetList(nil, 0)
        for k,v in pairs(_list) do
            if v.bountyType == _cfg.quest_type then
                return v
            end
        end
    elseif _cfg.display_type == 3 then ---副本
        local _list = module.QuestModule.GetList(nil, 0)
        for k,v in pairs(_list) do
            if v.battleGid and v.battleGid == _cfg.quest_type then
                return v
            end
        end
    elseif _cfg.display_type == 4 then ---引导任务
        local _list = module.QuestModule.GetList(_cfg.quest_type, 0)
        return _list[1]
    elseif _cfg.display_type == 5 then ---领主降临
        local _boss = module.worldBossModule.GetBossInfo(1)
        if _boss and _boss.type == 1 then
            local _data = {
                relation_type = 15,
                relation_value = _boss.id,
                name = _cfg.name,
                des = _cfg.des,
                openlev = _cfg.openlev,
                script = "guide/bounty/eventHandle.lua",
            }
            return _data
        end
        return
    end
end

local function GetRecommend(typeId)
    if typeId == 2 then
        local _recommendList = {}
        for i,v in ipairs(GetCfg()) do
            if v.type == typeId then
                local _checkActivity = checkActivity(v, true)
                if _checkActivity then
                    table.insert(_recommendList, v)
                end
            end
        end
        if #_recommendList > 0 then
            return _recommendList
        end
    else
        for i,v in ipairs(GetCfg()) do
            if typeId == 1 and v.type == typeId then
                if check(v) then
                    local _old = UserDefault.Load("QuestRecommend", true).old
                    if _old then
                        if GetQuest(_old) then
                            return GetCfg(_old)
                        end
                    end
                    UserDefault.Load("QuestRecommend", true).old = v.id
                    return v
                end
            end
        end
    end

end


local showGuideState = false
local function ShowGuide(show)
    if not show then
        return showGuideState
    end
    showGuideState = show
    return show
end
utils.EventManager.getInstance():addListener("LOCAL_TASKLIST_GUIDE", function(event, data)
    showGuideState = data
end)

return {
    GetRecommend = GetRecommend,
    GetCfg = GetCfg,
    GetQuest = GetQuest,
    ShowGuide = ShowGuide,
    CheckActivity = checkActivity,
}
