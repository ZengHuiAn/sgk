local achievementFirstTitileCfg = nil
local achievementFirstSecondTitileCfg = nil
local achievementReward_questCfg = nil
local achievementAllFirstTitileCfg = nil
local achievementAllSecondTitileCfg = nil
local achievementFirstQuestId = nil
local achievementCfg = nil
local achievementCount = 0

local function GetCfg(id, first, second,reward)
    if not achievementCfg or not achievementFirstTitileCfg or not achievementFirstSecondTitileCfg or
       not achievementAllFirstTitileCfg or not achievementAllSecondTitileCfg or not achievementFirstQuestId then
        achievementFirstTitileCfg = {}
        achievementFirstSecondTitileCfg = {}
        achievementAllFirstTitileCfg = {}
        achievementAllSecondTitileCfg = {}
        achievementFirstQuestId = {}
        achievementCfg = {}
        achievementReward_questCfg = {}
        DATABASE.ForEach("achievement", function(row)
            achievementCfg[row.Third_quest_id] = row
            if not achievementFirstTitileCfg[row.First_id] then
                achievementFirstTitileCfg[row.First_id] = {}
            end
            if not achievementFirstQuestId[row.First_id] then
                achievementFirstQuestId[row.First_id] = {}
            end
            if not achievementFirstQuestId[row.First_id][row.Second_quest_id] then
                achievementFirstQuestId[row.First_id][row.Second_quest_id] = {}
            end
            table.insert(achievementFirstQuestId[row.First_id][row.Second_quest_id], row)
            table.insert(achievementFirstTitileCfg[row.First_id], row)
            if not achievementFirstSecondTitileCfg[row.Second_quest_id] then
                achievementFirstSecondTitileCfg[row.Second_quest_id] = {}
            end
            table.insert(achievementFirstSecondTitileCfg[row.Second_quest_id], row)
            achievementCount = achievementCount + 1

            achievementReward_questCfg[row.reward_quest_id] = achievementReward_questCfg[row.reward_quest_id] or {}

            table.insert( achievementReward_questCfg[row.reward_quest_id], row )
        end)

        for k,v in pairs(achievementFirstTitileCfg) do
            table.insert(achievementAllFirstTitileCfg, {name = v[1].First_name, des = v[1].Firse_des, id = v[1].First_id})
        end
        for k,v in pairs(achievementFirstSecondTitileCfg) do
            if v[1] and v[1].Second_quest_id then
                local _quest = module.QuestModule.GetCfg(v[1].Second_quest_id)
                if _quest then
                    table.insert(achievementAllSecondTitileCfg, {name = _quest.name, des = _quest.desc1, id = _quest.id})
                end
            end
        end
    end
    if id then
        return achievementCfg[id]
    end
    if first then
        return achievementFirstTitileCfg[first]
    end
    if second then
        return achievementFirstSecondTitileCfg[second]
    end

    if reward then
        return achievementReward_questCfg[reward]
    end
end

local function GetAllCfg()
    GetCfg()
    return achievementCfg
end

local function GetFistCfg(index)
    GetCfg()
    if index then
        return achievementAllFirstTitileCfg[index]
    else
        return achievementAllFirstTitileCfg
    end
end

local function GetSecondCfg(index)
    GetCfg()
    if index then
        return achievementAllSecondTitileCfg[index]
    else
        return achievementAllSecondTitileCfg
    end
end

local function GetFirstQuest(index)
    GetCfg()
    if index then
        return achievementFirstQuestId[index]
    else
        return achievementFirstQuestId
    end
end

local function GetCount()
    GetCfg()
    return achievementCount
end

local function GetFinishCount(first, second)
    GetCfg()
    local _count = 0
    if first then
        for i,v in ipairs(GetCfg(nil, first)) do
            if module.QuestModule.Get(v.reward_quest_id) and (module.QuestModule.CanSubmit(v.reward_quest_id) or module.QuestModule.Get(v.Third_quest_id).status == 1) then
                _count = _count + 1
            end
        end
    elseif second then
        for i,v in ipairs(GetCfg(nil, nil, second)) do
            if module.QuestModule.Get(v.reward_quest_id) and (module.QuestModule.CanSubmit(v.reward_quest_id) or module.QuestModule.Get(v.Third_quest_id).status == 1) then
                _count = _count + 1
            end
        end
    else
        for k,v in pairs(achievementCfg) do
            if module.QuestModule.Get(v.reward_quest_id) and (module.QuestModule.CanSubmit(v.reward_quest_id) or module.QuestModule.Get(v.Third_quest_id).status == 1) then
                _count = _count + 1
            end
        end
    end
    return _count
end

return {
    GetCfg = GetCfg,
    GetAllCfg = GetAllCfg,
    GetCount = GetCount,
    GetFinishCount = GetFinishCount,
    GetFistCfg = GetFistCfg,
    GetSecondCfg = GetSecondCfg,
    GetFirstQuest = GetFirstQuest,
}
