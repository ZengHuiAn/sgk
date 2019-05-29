local cfgType = {
    Build = 1,
}

local titleType = {
    Activity = 1,
    Task = 2,
    Team = 3,
}

local activityActiveTab = nil
local function activeCfg(gid)
    activityActiveTab = activityActiveTab or LoadDatabaseWithKey("huoyuedu", "gid") or {}
    return activityActiveTab[gid]
end

local activityCfgTab = nil
local activityCfgByCategory=nil
local activityCfgByQuest = nil;
local activityGroup = nil
local function activityCfg(id)
    if not activityCfgTab then
        activityCfgTab ={}
        activityCfgByCategory={}
        activityCfgByQuest = {}
        activityGroup = {}
        DATABASE.ForEach("all_activity", function(data)
            activityCfgTab[data.id]=data
            activityCfgByCategory[data.category]=activityCfgByCategory[data.category] or {}
            table.insert(activityCfgByCategory[data.category],data)
            if data.related_quest_id and data.related_quest_id ~= 0 then
                activityCfgByQuest[data.related_quest_id] = data;
            end
            if data.activity_group and data.activity_group ~= 0 then
                activityGroup[data.activity_group] = activityGroup[data.activity_group] or {}
                table.insert(activityGroup[data.activity_group], data)
            end
        end);
    end
    if not id then return activityCfgTab end
    return activityCfgTab[id]
end

local function GetCfgByGroup(groupId)
    if not activityGroup then
        activityCfg()
    end
    return activityGroup[groupId]
end

local function GetActivityCfgByCategory(Category)
    if not activityCfgByCategory then
        activityCfg()
    end
    return activityCfgByCategory[Category]
end

local function GetActivityCfgByQuest(quest_id)
    local t = activityCfgByQuest[quest_id] or {}
    return t.id;
end

local activityTitleTab = nil
local function getActivityTitle(type, titileId, id)
    if not activityCfgTab then
        activityCfg()
    end
    if not activityTitleTab then
        activityTitleTab = {}

        for k,v in pairs(activityCfgTab) do
            for i = 1, 4 do
                if v["up_tittle"..i] > -1 then
                    if not activityTitleTab[i] then activityTitleTab[i] = {} end
                    if not activityTitleTab[i][v["up_tittle"..i]] then activityTitleTab[i][v["up_tittle"..i]] = {} end
                    table.insert(activityTitleTab[i][v["up_tittle"..i]], v)

                    table.sort(activityTitleTab[i][v["up_tittle"..i]] , function ( a,b )
                        return a.activity_order < b.activity_order;
                    end )
                end
            end
        
        end
    end
    if not titileId then
        return activityTitleTab[type]
    end
    if not id then
        return activityTitleTab[type][titileId]
    end
    return activityTitleTab[type][titileId][id]
end

local activityRewardTab = nil
local function getActivityReward(id)
    if not activityCfgTab then
        activityCfg()
    end
    if not activityRewardTab then
        activityRewardTab = {}
        for k,v in pairs(activityCfgTab) do
            for i = 1, 3 do
                local _temp = {}
                _temp.type = v["reward_type"..i]
                _temp.id = v["reward_id"..i]
                if _temp.id ~= 0 and _temp.type ~= 0 then
                    if not activityRewardTab[k] then activityRewardTab[k] = {} end
                    table.insert(activityRewardTab[k], _temp)
                end
            end
        end
    end
    if not id then return {} end
    return activityRewardTab[id]
end

local allTitle = nil
local function getBaseTittleByType(showType)
    if allTitle == nil then
        allTitle = {}
        DATABASE.ForEach("all_tittle", function(row)
            if row.up_tittle == 0 then
                if not allTitle[row.show] then allTitle[row.show] = {} end
                if not allTitle[row.show][row.id] then allTitle[row.show][row.id] = {} end
                allTitle[row.show][row.id] = row
            else
                print(row.show, row.up_tittle, allTitle[row.show][row.up_tittle])
            end
        end)
    end
    return allTitle[showType]
end

local activitylist = nil
local function GetActivitylist()
    if activitylist == nil then
        activitylist = {}
        DATABASE.ForEach("all_tittle", function(row)
            if row.show == 3 then
                activitylist[row.id] = {id = row.id,TitleData = row,IsTittle = true,ChildNode = {}}
            end
        end);

        DATABASE.ForEach("all_activity", function(row)
            if row.up_tittle3 > -1 then
                if row.up_tittle3 == 0 then
                    activitylist[row.id] = {id = row.id,TitleData = row,IsTittle = false,ChildNode = {}}
                else
                    activitylist[row.up_tittle3].ChildNode[#activitylist[row.up_tittle3].ChildNode + 1] = row
                end
            end
        end)
    end
    return activitylist
end

local activityNpcList = nil
local function GetActivityNpcList()
    if activityNpcList == nil then
        activityNpcList = {}
        DATABASE.ForEach("all_activity", function(row)
            if row.findnpcname ~= 0 then
                activityNpcList[row.findnpcname] = activityNpcList[row.findnpcname] or {}
                table.insert(activityNpcList[row.findnpcname],{id = row.id,name = row.name,des = row.des,lv = row.lv_limit})
            end
        end)
    end
    return activityNpcList
end

local all_activity = nil
local function Get_all_activity(id)
    all_activity = all_activity or LoadDatabaseWithKey("all_activity", "id") or {}
    return all_activity[id]
end

local function getFinishCount(_tab, _quest)
    local _finishCount = 0
    if _tab.id == 4 then
        local _list = module.CemeteryModule.GetTeamPveFightList(1)
        if _list and _list.count then
            _finishCount = _list.count
        end
    elseif _tab.id == 5 then
        local _list = module.CemeteryModule.GetTeamPveFightList(2)
        if _list and _list.count then
            _finishCount = _list.count
        end
    elseif _tab.id == 7 then
        if module.answerModule.GetWeekCount() then
            _finishCount = module.answerModule.GetWeekCount()
        end
    elseif _tab.id == 6 then
        _finishCount = math.floor((module.answerModule.GetInfo().finishCount or 0)/10);
    else
        if _tab.huoyuedu ~= 0 and _quest then
            _finishCount = _quest.finishCount
        end
    end
    return _finishCount
end

local function getActiveCount(_tab, _quest, _finishCount)
    local _active = 0
    if _quest then
        if _tab.id then
            if _quest.reward_value1 then
                _active = _finishCount * _quest.reward_value1
            else
                ERROR_LOG("reward_value1 nil")
            end
        end
    end
    return _active
end

local CemeteryConf = require "config.cemeteryConfig"
local function GetActiveCountById(id)
    local _tab = activityCfg(id)
    if not _tab then
        return 0, 0
    end
    local _finishCount = 0
    local _active = 0
    local _countTen = 0
    local a_count =0
    local b_count =0
    local _activeCouunt=0
    if _tab.vatality == 1 then
        local _quest = module.QuestModule.Get(_tab.huoyuedu)
        _finishCount = getFinishCount(_tab, _quest)
        _activeCouunt=_finishCount
        _active = getActiveCount(_tab, _quest, _finishCount)
    elseif _tab.vatality == 2 then
        local _teamBattle = CemeteryConf.Getteam_battle_activity(id,0)[1]
    --    ERROR_LOG("_tab------------->>>",_tab.name)
    --    ERROR_LOG("countTen----->>>",module.ItemModule.GetItemCount(_teamBattle.rewrad_count_ten))
    --    ERROR_LOG("countOne----->>>", module.ItemModule.GetItemCount(_teamBattle.rewrad_count_one))

        a_count,b_count = module.ItemModule.GetItemCount(_teamBattle.rewrad_count_one),module.ItemModule.GetItemCount(_teamBattle.rewrad_count_ten)
        _finishCount = _tab.join_limit - a_count - b_count
        _active = _finishCount
        _countTen = b_count
    elseif _tab.vatality == 3 then
         a_count,b_count = module.ItemModule.GetItemCount(2041),module.ItemModule.GetItemCount(1041)
        _finishCount = _tab.join_limit - a_count - b_count
        _active = _finishCount
        _countTen = b_count
    end
    return {count = _active,
            maxCount = _tab.join_limit,
            finishCount = _finishCount,
            joinLimit = _tab.join_limit,
            countTen = _countTen,
            countOne = a_count,
            activeCouunt=_activeCouunt,
            }
end

local function CheckActivityOpen(id)
    local _cfg = activityCfg(id)
    if not _cfg then
        return false
    end
    local _year = os.date("%Y", module.Time.now())
    local _month=os.date("%m", module.Time.now())
    local _day=os.date("%d", module.Time.now())
    local today = os.time({year=_year,month=_month,day=_day,hour=23,min=59,sec=59})--当天23:59:59
    local week = os.date("%w", module.Time.now())
    if (_cfg.week >> week) & 1 == 1 then
        if _cfg.begin_time >= 0 and _cfg.end_time >= 0 and _cfg.period >= 0 then
            local total_pass = module.Time.now() - _cfg.begin_time
            local period_pass = total_pass - math.floor(total_pass / _cfg.period) * _cfg.period
            local period_begin = module.Time.now() - period_pass
            -- print("============================",os.date("%Y-%m-%d%H:%M:%S",period_begin))
            if (module.Time.now() > period_begin and module.Time.now() < (period_begin + _cfg.loop_duration)) then
                return true --活动开启
            elseif period_begin + _cfg.period > today then
                return nil --不在活动日
            end
        end
    else
        return nil
    end
    return false--活动未开启
end

local _smallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local _battle = require "config.battle"
local function loadFightCfg(cfg)
    if cfg then
        local _fightCfg = _smallTeamDungeonConf.GetTeamPveMonsterList(cfg.fight_id) or {}
        cfg.squad = {}
        for k,v in pairs(_fightCfg) do
            table.insert(cfg.squad, {roleId = v.role_id, level = v.role_lev,pos=v.role_pos})
        end
	end
	return cfg
end

local activityMonsterCfg = nil
local function GetActivityMonsterCfg(monsterId)
    if not activityMonsterCfg then
        activityMonsterCfg = {raw = LoadDatabaseWithKey("activity_monster", "npc")}

        setmetatable(activityMonsterCfg, {__index = function(t, k)
            local _cfg = t.raw[k]
            if _cfg then
                rawset(t, k, loadFightCfg(_cfg))
            end
            return _cfg
        end})
    end
    if monsterId then
        return activityMonsterCfg[monsterId]
    else
        return activityMonsterCfg
    end
end

local cityCfg = nil;
local function freshRow(name,row)
    if row[name] ~= 0 then
        cityCfg[name][row[name]] = row; 
    end
end

local MapConfig = require "config.MapConfig"
local function GetCityConfig(mapid,_type,npcid,monsterNpc)
    if not cityCfg then
        cityCfg = {};
        DATABASE.ForEach("city", function(row)    
            cityCfg.type = cityCfg.type or {};
            cityCfg.npc_id = cityCfg.npc_id or {};
            cityCfg.map_id = cityCfg.map_id or {};
            cityCfg.monster_npc = cityCfg.monster_npc or {};
            freshRow("monster_npc",row);
            freshRow("type",row);

            freshRow("npc_id",row);

            freshRow("map_id",row);
            cityCfg.map_id[row.map_id].chat = MapConfig.GetMapConf(row.map_id).chat
        end)
    end

   if mapid then
      return cityCfg.map_id[mapid];
   end

   if npcid then
      return cityCfg.npc_id[npcid];
   end

   if _type then
      return cityCfg.type[_type];
   end

   if monsterNpc then
       return cityCfg.monster_npc[monsterNpc];
   end

   return cityCfg;
end

local cityFightCfg = nil 
local buildCityCfg = nil;
local function GetBuildCityConfig(type,lev)
    if not buildCityCfg then
        buildCityCfg = {};
        cityFightCfg = {}
        DATABASE.ForEach("activity_buildcity", function(row) 
            buildCityCfg[row.type] = buildCityCfg[row.type] or {};
            cityFightCfg[row.type] =cityFightCfg[row.type] or {}
            local temp_fight = {squad = loadFightCfg(row).squad,fight_id = row.fight_id,dcity_lv = row.dcity_lv}
            row.fight_data = temp_fight;

            cityFightCfg[row.type][row.dcity_lv] = row;
            table.insert(buildCityCfg[row.type],row);  
        end)

        for k,v in pairs(buildCityCfg) do
            table.sort( v, function ( a  , b )
                return a.dcity_lv <b.dcity_lv;
            end )
        end
    end

    if type and lev then
        return cityFightCfg[type][lev];
    elseif type then
        return buildCityCfg[type];
    end
    return buildCityCfg;
end

local cityTaskGroupCfg = nil
local function GetCityTaskGroupConfig(type)
    if not cityTaskGroupCfg then
        cityTaskGroupCfg = LoadDatabaseWithKey("city_quest", "quest_type")
    end
    if type then
        return cityTaskGroupCfg[type]
    else
        return cityTaskGroupCfg
    end
end

--计算城市繁荣度 和当前经验
local function GetCityLvAndExp(info,cityType,mapid)
    if not cityType and mapid then
       cityType =  GetCityConfig(mapid) and GetCityConfig(mapid).type
    end

    if not cityType then return end

    local exp = 0
    if info.boss and next(info.boss)~=nil then
        exp = info.boss[cityType] and info.boss[cityType].exp or 0
    else
        return
    end
    local cityCfgGroup = GetBuildCityConfig(cityType)
    
    local nextLvIdx = 0--下一级的Idx
    local lastLv = 0

    for i=1,#cityCfgGroup do
        if cityCfgGroup[i].dcity_exp <= exp then
            lastLv = cityCfgGroup[i].dcity_lv
        end
        if cityCfgGroup[i].dcity_exp > exp then
            nextLvIdx = i
            break
        end
        nextLvIdx = i
    end

    local _Lv = cityCfgGroup[nextLvIdx].dcity_lv
    local _value = cityCfgGroup[nextLvIdx].dcity_exp

    if exp >_value then--超过最大值
        exp = _value
        lastLv = _lv
    end
    return lastLv,exp,_value
end

local sortCityCfg = nil
local function GetSortCityCfg()
    if not sortCityCfg then
        local cityConfig = GetCityConfig() and GetCityConfig().map_id or {}
        sortCityCfg = {}
        for k,v in pairs(cityConfig) do
            table.insert(sortCityCfg,v)
        end
        table.sort(sortCityCfg,function (a,b)
            if a.city_quality ~= b.city_quality then
                return a.city_quality > b.city_quality
            end
            return a.id< b.id
        end)
    end
    return sortCityCfg
end

return {
        TitleType = titleType,
        GetActivity = activityCfg,
        GetReward = getActivityReward,
        ActiveCfg = activeCfg,                      --活跃度配置
        GetBaseTittleByType = getBaseTittleByType,
        GetAllActivityTitle = getActivityTitle,
        GetCfgByGroup = GetCfgByGroup,
        GetActivityMonsterCfg = GetActivityMonsterCfg,
        GetActivityNpcList = GetActivityNpcList, --活动npc对应活动id
        GetActivitylist = GetActivitylist,
        GetActivityCfgByCategory=GetActivityCfgByCategory,
        GetActivityCfgByQuest=GetActivityCfgByQuest,
        Get_all_activity = Get_all_activity,
        GetActiveCountById = GetActiveCountById,
        CheckActivityOpen = CheckActivityOpen,

        GetCityLvAndExp = GetCityLvAndExp,

        GetCityConfig = GetCityConfig,   --读取city表
        GetBuildCityConfig = GetBuildCityConfig,  ----读取buildcity表

        GetCityTaskGroupConfig = GetCityTaskGroupConfig,

        GetSortCityCfg = GetSortCityCfg,
}
