--装备推荐
--返回一个装备列表
--typeId 装备 or 铭文
local skillCfg = require "config.skill"
local EquipModule = require "module.equipmentModule"
local equipCofig = require "config.equipmentConfig"
local heroModule = require "module.HeroModule"
local function getEquipList(hero, suitIdx)
    local _equipList = {}
    local _list = EquipModule.OneselfEquipMentTab()
    for k,v in pairs(_list) do
        if hero.level >= v.level then
            if ((v.heroid == hero.id and (v.suits > equipCofig.GetOtherSuitsCfg().EqSuits or v.suits == suitIdx)) or v.heroid == 0) and v.type == 0 then
                if v.cfg.suit_id then
                    if not _equipList[v.cfg.suit_id] then _equipList[v.cfg.suit_id] = {} end
                    if utils.EquipFormula.GetScore({heroId = hero.id, uuid = v.uuid}) > 0 then
                        table.insert(_equipList[v.cfg.suit_id], v)
                    end
                end
            end
        end
    end
    for k,v in pairs(_equipList) do
        table.sort(v, function(a, b)
            local _scoreA = utils.EquipFormula.GetScore({heroId = hero.id, uuid = a.uuid})
            local _scoreB = utils.EquipFormula.GetScore({heroId = hero.id, uuid = b.uuid})
            if _scoreA ~= _scoreB then
                return _scoreA > _scoreB
            end
            if a.quality ~= b.quality then
                return a.quality > b.quality
            end
            if a.level ~= b.level then
                return a.level > b.level
            end
            return a.uuid < b.uuid
        end)
    end
    return _equipList
end

local function sortSkill(hero, heroId)
    local _skillTab = {}
    local _skillCfgTab = {}
    if hero.id == 11000 then
        local _cfg = module.TalentModule.GetSkillSwitchConfig(hero.id)[hero.property_value == 0 and 1 or hero.property_value]
        _skillTab = module.TalentModule.GetSkillTreeData(hero.uuid, _cfg.skill_tree, _cfg.type)
    else
        _skillTab = module.TalentModule.GetSkillTreeData(hero.uuid, hero.weapon_id, 2)
    end
    local _skill = {}
    for k,v in pairs(_skillTab) do
        local _cfg = skillCfg.GetConfig(k)
        if _cfg and _cfg.recommend_suit_id ~= 0 then
            table.insert(_skill, {key = k, value = v, suitId = _cfg.recommend_suit_id})
        end
    end
    table.sort(_skill, function(a, b)
        if a.value == b.value then
            return a.key > b.key
        end
        return a.value > b.value
    end)
    --加入备选套装
    local _applicativeSuit = StringSplit(hero.applicative_suit, "|")
    for i,v in ipairs(_applicativeSuit) do
        table.insert(_skill, {suitId = tonumber(v)})
    end
    --去除重复套装
    local i = 1
    local _suitTab = {}
    while i <= #_skill do
        if _suitTab[_skill[i].suitId] then
            table.remove(_skill, i)
        else
            _suitTab[_skill[i].suitId] = true
            i = i + 1
        end
    end
    return _skill
end

--角色推荐套装的分组
local function getRoleRecommendClass(heroId)
    local _classTab = {}
    local cfg = heroModule.GetConfig(heroId)
    if cfg then
        local _applicativeSuit = StringSplit(cfg.applicative_suit, "|")
        for i,v in ipairs(_applicativeSuit) do
            table.insert(_classTab, {class = tonumber(v)})
        end
    end
    return _classTab
end

--取出每套最好的6件
local function getPlace(equipType)
    for i,v in ipairs(EquipModule.HashBinary) do
        if v == equipType then
            return i
        end
    end
end

local function getBestEquipList(equipList)
    local _bestList = {}
    for k,v in pairs(equipList) do
        if not _bestList[k] then _bestList[k] = {} end
        for j,p in ipairs(v) do
            local _place = getPlace(p.cfg.type)
            if not _bestList[k][_place] then
                _bestList[k][_place] = p
            end
        end
    end
    return _bestList
end

local function getTabSize(tab)
    local _count = 0
    for k,v in pairs(tab or {}) do
        _count = _count + 1
    end
    return _count
end

local function checkAndSort(list)
    local _list = {}
    for k,v in pairs(list or {}) do
        table.insert(_list, {place = k, cfg = v})
    end
    -- table.sort(_list, function(a, b)
    --     if a.cfg.quality == b.cfg.quality then
    --         return a.place < b.place
    --     end
    --     return a.cfg.quality > b.cfg.quality
    -- end)
    return _list
end

--保证一定出nowSuit效果 nextSuit可能出散件
local function checkFour(count, nowSuit, nextSuit, bestList)
    local _nowList = checkAndSort(bestList[nowSuit])
    local _nextList = checkAndSort(bestList[nextSuit])
    local _placeList = {}
    local _suitEquip = {}
    for i = 1, count do
        _placeList[_nowList[i].place] = bestList[nowSuit][_nowList[i].place].uuid
    end
    _suitEquip = _placeList
    for i = 7, 12 do
        if not _placeList[i] then
            if bestList[nextSuit] and bestList[nextSuit][i] then
                _placeList[i] = bestList[nextSuit][i].uuid
            end
        end
    end
    if getTabSize(_placeList) == 6 then
        return true, _placeList
    end
    return false, _suitEquip
end

local function checkTwo(nowSuit, nextSuit, threeSuit, bestList)
    local _nowList = checkAndSort(bestList[nowSuit])
    local _nextList = checkAndSort(bestList[nextSuit])
    local _placeList = {}
    local _otherEquip = {}
    for i = 1, 2 do
        _placeList[_nowList[i].place] = bestList[nowSuit][_nowList[i].place].uuid
    end
    _otherEquip = _placeList
    local _count = 0
    for i,v in ipairs(_nextList) do
        if _count < 2 then
            if not _placeList[v.place] then
                _placeList[v.place] = v.uuid
                _count = _count + 1
            end
        end
    end
    if getTabSize(_placeList) == 4 then
        _otherEquip = _placeList
    end
    for i = 7, 12 do
        if not _placeList[i] then
            if bestList[threeSuit] then
                if bestList[threeSuit][i] then
                    _placeList[i] = bestList[threeSuit][i].uuid
                end
            end
        end
    end
    if getTabSize(_placeList) == 6 then
        return true, _placeList
    end
    return false, _otherEquip
end

local function addOtherEquip(list, otherList)
    for i = 7, 12 do
        if not list[i] then
            if otherList[i] then
                if otherList[i][1] then
                    list[i] = otherList[i][1].uuid
                end
            end
        end
    end
end

local function check(idx, bestList, suitList, otherList)
    local _suitId = suitList[idx].suitId
    if getTabSize(bestList[_suitId]) >= 4 then
        local _list = {}
        for i = idx + 1, #suitList do
            local _status, _eqList  = checkFour(4, _suitId, suitList[i].suitId, bestList)
            _list = _eqList
            if _status then
                return true, _eqList
            end
        end
        addOtherEquip(_list, otherList)
        return _list
    end

    local _equipList = {}
    if getTabSize(bestList[_suitId]) >= 2 then
        for i = idx + 1, #suitList do
            if getTabSize(bestList[i]) >= 4 then
                local _status, _eqList  = checkFour(2, _suitId, suitList[i].suitId, bestList)
                _equipList = _eqList
                if _status then
                    return true, _eqList
                end
            end
        end
    end
    if getTabSize(_equipList) == 4 then
        addOtherEquip(_equipList, otherList)
        return _equipList
    end
    if getTabSize(bestList[_suitId]) >= 2 then
        for i = idx + 1, #suitList do
            if getTabSize(bestList[i]) >= 2 then
                if suitList[i + 1] and suitList[i + 1].suitId then
                    local _status, _eqList  = checkTwo(_suitId, suitList[i].suitId, suitList[i + 1].suitId, bestList)
                    if _status then
                        return true, _eqList
                    end
                end
            end
        end
        addOtherEquip(_equipList, otherList)
        return _equipList
    end
    return false
end

local function sortByQuality(equipList)
    for k,v in pairs(equipList) do
        table.sort(v, function(a, b)
            if a.quality ~= b.quality then
                return a.quality > b.quality
            end
            if a.level ~= b.level then
                return a.level > b.level
            end
            return a.uuid < b.uuid
        end)
    end
    return equipList
end

local function sortByScore(heroId, equipList)
    for k,v in pairs(equipList) do
        table.sort(v, function(a, b)
            local _scoreA = utils.EquipFormula.GetScore({heroId = heroId, uuid = a.uuid})
            local _scoreB = utils.EquipFormula.GetScore({heroId = heroId, uuid = b.uuid})
            if _scoreA ~= _scoreB then
                return _scoreA > _scoreB
            end
            if a.quality ~= b.quality then
                return a.quality > b.quality
            end
            if a.level ~= b.level then
                return a.level > b.level
            end
            return a.uuid < b.uuid
        end)
    end
    return equipList
end

local equipSuitScoreList = {}
local function getOtherList(hero, suitIdx)
    local _list = EquipModule.OneselfEquipMentTab()
    local _equipList = {}
    equipSuitScoreList = {}
    for k,v in pairs(_list) do
        if hero.level >= v.level then
            if ((v.heroid == hero.id and (v.suits > equipCofig.GetOtherSuitsCfg().EqSuits or v.suits == suitIdx)) or v.heroid == 0) then
                if v.cfg.type then
                    local _place = getPlace(v.cfg.type)
                    if _place then
                        if not _equipList[_place] then _equipList[_place] = {} end
                        local _score = utils.EquipFormula.GetScore({heroId = hero.id, uuid = v.uuid})
                        if _score > 0 then
                            table.insert(_equipList[_place], v)
                            if v.type == 0 then
                                if not equipSuitScoreList[v.cfg.suit_id] then equipSuitScoreList[v.cfg.suit_id] = {} end
                                table.insert(equipSuitScoreList[v.cfg.suit_id], {score = _score})
                            end
                        end
                    end
                end
            end
        end
    end
    return _equipList
end

local function getApplicativeList(suitList, bestList, hero, _otherList)
    local _equipList = {}
    for i,v in ipairs(suitList) do
        local _status, _list = check(i, bestList, suitList, _otherList)
        if _status == true then
            _equipList = _list
            return _equipList
        end
    end
    addOtherEquip(_equipList, _otherList)
    return _equipList
end

local function newSortSkill(hero, skillList)
    local _skillScoreList = {}
    for i,v in pairs(equipSuitScoreList) do
        for j,p in ipairs(v) do
            if not _skillScoreList[i] then _skillScoreList[i] = 0 end
            _skillScoreList[i] = p.score + _skillScoreList[i]
        end
    end
    local _scoreList = {}
    for k,v in pairs(_skillScoreList) do
        _scoreList[k] = v / #equipSuitScoreList[k]
    end
    for i,v in ipairs(skillList) do
        v.idx = i
    end
    local _applicativeList = StringSplit(hero.applicative_suit_xishu, "|")
    table.sort(skillList, function(a, b)
        local _sortA = ((a.value or 0) + (_scoreList[a.suitId] or 0)) * (_applicativeList[a.suitId] or 1)
        local _sortB = ((b.value or 0) + (_scoreList[b.suitId] or 0)) * (_applicativeList[b.suitId] or 1)
        if _sortA == _sortB then
            return a.idx > b.idx
        end
        return _sortA > _sortB
    end)
    return skillList
end

local function Get(heroId, typeId, suitIdx)
    local _equipTab = {}
    local _hero = module.HeroModule.GetManager():Get(heroId)
    if not _hero then
        ERROR_LOG(heroId, "hero error")
        return _equipTab
    end
    local _otherList = getOtherList(_hero, suitIdx)
    if typeId == 0 then
        local _skillList = sortSkill(_hero)
        local _equipList = getEquipList(_hero, suitIdx)
        _otherList = sortByScore(heroId, _otherList)
        _skillList = newSortSkill(_hero, _skillList)
        return getApplicativeList(_skillList, getBestEquipList(_equipList), _hero, _otherList)
    elseif typeId == 1 then
        local _list = {}
        local k = 1
        _otherList = sortByScore(heroId, _otherList)
        for i = 6, 1, -1 do
            if i > 3 then
                k = i - 3
            else
                k = i
            end
            if not _list[i] then
                if _otherList[k] then
                    if _otherList[k][1] then
                        _list[i] = _otherList[k][1].uuid
                        table.remove(_otherList[k], 1)
                    end
                end
            end
        end
        return _list
    else
        ERROR_LOG("typeId error")
        return _equipTab
    end
    return _equipTab 
end

return {
    Get = Get,
    SortSkill = sortSkill,
    GetClass = getRoleRecommendClass,
}
