local zeroPlanCfg = nil
local zeroQuestList = nil

local openLevel = require "config.openLevel"
local heroBuff = require "hero.HeroBuffModule"

local function GetZeroQuestList(type)
    if not zeroQuestList then
        zeroQuestList = {}
        DATABASE.ForEach("zeroplan", function(row)
            zeroQuestList[row.type] = zeroQuestList[row.type] or {}
            table.insert(zeroQuestList[row.type], row)
        end)
    end
    if not type then
        return zeroQuestList
    end
    return zeroQuestList[type]
end

local function getBuff(questId)
    local _quest = module.QuestModule.GetCfg(questId)
    local _buff = {}
    if _quest then
        for i = 1, 3 do
            if _quest["reward_type"..i] == 93 then
                local _cfg = heroBuff.GetBuffConfig(_quest["reward_id"..i])
                if _cfg then
                    table.insert(_buff, {key = _cfg.type, value = _cfg.value * _quest["reward_value"..i]})
                end
            end
        end
    end
    return _buff
end

local function getOpenLevelCfg(openLevelId)
    if openLevelId ~= 0 then
        local _open = openLevel.GetCfg(openLevelId)
        if _open then
            return _open.functional_name
        end
    end
end

local function getHonor(honor)
    if honor ~= 0 then
        local _honor = module.honorModule.GetCfg(honor)
        if _honor then
            return _honor
        end
    end
end

local function Get(type)
    if not zeroPlanCfg then
        zeroPlanCfg = {}
        DATABASE.ForEach("zeroplan_reward", function(row)
            zeroPlanCfg[row.type] = zeroPlanCfg[row.type] or {}
            local _tab = row
            _tab.buff = getBuff(row.quest_id)
            _tab.openLevel = getOpenLevelCfg(row.openlev_id)
            _tab.honor = getHonor(row.title_id)
            table.insert(zeroPlanCfg[row.type], _tab)
        end)
    end
    if type then
        return zeroPlanCfg[type]
    else
        return zeroPlanCfg
    end
end


return {
    Get = Get,
    GetQuestList = GetZeroQuestList,
}
