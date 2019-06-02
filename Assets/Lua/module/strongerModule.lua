local strongerCfg = nil
local strongerTitleCfg = nil
local classifyList = nil
local titleList = nil

local openLevel = require "config.openLevel"

local resourceCfg = nil
local resourceTitleCfg = nil
local function loadResourceCfg()
    if resourceCfg then
        return
    end
    resourceCfg = {}
    resourceTitleCfg = {}
    DATABASE.ForEach("promote_resource", function(row)
        if row.is_root == 0 then
            resourceCfg[row.title] = resourceCfg[row.title] or {}
            table.insert(resourceCfg[row.title], row)
        else
            table.insert(resourceTitleCfg, row)
        end
    end)
end

local expectationCfg = nil
local function loadExpectation()
    if expectationCfg then
        return
    end
    expectationCfg = {}
    DATABASE.ForEach("promote_expectation", function(row)
        expectationCfg[row.type] = expectationCfg[row.type] or {}
        table.insert(expectationCfg[row.type], row)
    end)
end

local function GetExpectation(typeId)
    loadExpectation()
    if typeId then
        return expectationCfg[typeId]
    end
    return expectationCfg
end

local function GetResource(title)
    loadResourceCfg()
    if not title then
        return resourceCfg
    end
    return resourceCfg[title]
end

local function GetResourceTitle()
    loadResourceCfg()
    return resourceTitleCfg
end

local function loadCfg()
    if strongerCfg then
        return strongerCfg
    end
    strongerCfg = {}
    classifyList = {}
    titleList = {}
    local _titleTab = {}
    DATABASE.ForEach("promote_strength", function(row)
        strongerCfg[row.title] = strongerCfg[row.title] or {}
        strongerCfg[row.title][row.classify] = strongerCfg[row.title][row.classify] or {}
        if row.is_root ~= 0 then
            classifyList[row.title] = classifyList[row.title] or {}
            table.insert(classifyList[row.title], row)
            -- if row.is_root == 1 then
            --     table.insert(titleList, row)
            -- end
            if not _titleTab[row.title] then
                _titleTab[row.title] = true
                table.insert(titleList, row)
            end 
        else
            table.insert(strongerCfg[row.title][row.classify], row)
        end
    end)
end

local function GetTitleList()
    loadCfg()
    return titleList
end

local function GetCfg(titleId, classifyId)
    loadCfg()
    if titleId and classifyId then
        local _list = {}
        for i,v in ipairs(strongerCfg[titleId][classifyId]) do
            -- ERROR_LOG(openLevel.GetStatus(v.openlev_id),v.openlev_id)
            -- if openLevel.GetStatus(v.openlev_id) then
                table.insert(_list, v)
            -- end
        end
        return _list
    end
    return strongerCfg
end

local function GetClassifyList(titleId)
    loadCfg()
    if titleId then
        return classifyList[titleId]
    end
    return classifyList
end

local function GetHeroExp(heroId, id)
    local hero = module.HeroModule.GetManager():Get(heroId)
    if not hero then
        return 0
    end
    local _value = 0
    local _expCfgList = GetExpectation(id)
    if not _expCfgList then
        return 0
    end
    for i,v in ipairs(_expCfgList) do
        if v.lv_min <= module.HeroModule.GetManager():Get(11000).level and v.lv_max >= module.HeroModule.GetManager():Get(11000).level then
            if v.strength_id == 1 then
                _value = 1
            elseif v.strength_id == 2 then
                _value = hero.stage
            elseif v.strength_id == 3 then
                _value = hero.star
            elseif v.strength_id == 4 then
                for i = 7, 12 do
                    local _equip = module.equipmentModule.GetHeroEquip(heroId, i)
                    if _equip then
                        _value = _value + _equip.quality
                    end
                end
                _value = _value / 6
            elseif v.strength_id == 5 then
                _value = module.titleModule.GetHeroTitleQuality(hero) or 0
            elseif v.strength_id == 6 then
                _value = hero.level
            elseif v.strength_id == 7 then
                -- _value = module.DataBoxModule.GetUnlockPropertyCount(heroId)
                local type = 24
                local _questList = module.QuestModule.GetList(type,1)
                _value = #_questList
            elseif v.strength_id == 8 then
                local type = 17
                local _questList = module.QuestModule.GetList(type,1)
                _value = #_questList
            elseif v.strength_id == 9 then--装备等级
                for i = 7, 12 do
                    local _equip = module.equipmentModule.GetHeroEquip(heroId, i)
                    if _equip then
                        _value = _value + _equip.level
                    end
                end
                _value = _value / 6
            elseif v.strength_id == 10 then--角色品质
                _value = hero.role_stage
            end
            local _exp = 0
            if _value ~= 0 then
                local _size = _value / v.expectation
                if _size > 1 then
                    _size = 1
                end
                _exp = _size * 100
            end
            return _exp
        end
    end
    return 0
end

local strongerUpArg = {}

return {
    GetCfg           = GetCfg,
    GetClassify      = GetClassifyList,
    GetTitleList     = GetTitleList,
    GetResource      = GetResource,
    GetResourceTitle = GetResourceTitle,
    GetExpectation   = GetExpectation,
    GetHeroExp       = GetHeroExp,
    StrongerUpArg    = strongerUpArg,
}
