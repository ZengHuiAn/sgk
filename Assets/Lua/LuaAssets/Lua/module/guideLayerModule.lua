local Type = {
    Story             = 95,
    Equip             = 96,
    Title             = 983001,
    FashionLayer      = 781006,
    GetHero           = 982001,
    OnlineRewardFirst = 971001,
    OnlineReward      = 971007,
    LevelUp           = 981001,
    ChangeIcon        = 102144,
    Trailer           = 96,
}

local function GetQuest(typeId)
    if Type.Story == typeId or Type.Equip == typeId then
        local _list = module.QuestModule.GetConfigType(typeId)
        table.sort(_list, function(a, b)
            return a.id < b.id
        end)
        for i,v in ipairs(_list) do
            local _quest = module.QuestModule.Get(v.id)
            if _quest and _quest.status == 0 then
                return _quest
            end
        end
    end
end

local function GetFashionCfg()
    for k,v in pairs(module.HeroHelper.GetFashionSuits()) do
        for i,p in ipairs(v) do
            if p.type_flag ~= 0 then
                return p
            end
        end
    end
end

local function CheckOnline()
    local _first = module.QuestModule.Get(module.guideLayerModule.Type.OnlineRewardFirst)
    local _end = module.QuestModule.Get(module.guideLayerModule.Type.OnlineReward)
    for i = module.guideLayerModule.Type.OnlineRewardFirst, module.guideLayerModule.Type.OnlineReward do
        local _quest = module.QuestModule.Get(i)
        if _quest and _quest.status == 0 then
            return true
        end
    end
    return false
end


return {
    CheckOnline = CheckOnline,
    GetFashionCfg = GetFashionCfg,
    GetQuest = GetQuest,
    Type = Type,
}
