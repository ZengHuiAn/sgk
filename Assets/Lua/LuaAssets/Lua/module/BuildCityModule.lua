local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local ActivityConfig = require "config.activityConfig"
local Time = require "module.Time"


local function SetCityDrawCardInfo(data)
    local mapId = data[1]
    local equip_uuid = data[2]
    local item_id = data[3]
    local item_count = data[4]
    local JackpotFunds = data[5]

    local _tab = {
                    mapId = mapId,
                    equip_uuid =equip_uuid,
                    item_id = item_id,
                    item_count = item_count,
                    JackpotFunds = JackpotFunds
                }
    return _tab
end

-- C_QUERY_MAP_CASH_FLOW_REQUEST  3469
-- req[1] =  sn
-- req[2] = mapid
-- C_QUERY_MAP_CASH_FLOW_RESPOND  3470
-- ret[1] = sn
-- ret[2] = result
-- ret[3] = [type, num, value]  type 1 扭蛋  2 建设任务  3 特产商店 
local businessInfo = nil
local CityArr = {}
local function GetCityBusinessInfo(mapId)
	businessInfo = businessInfo or {}
	if not businessInfo[mapId] or businessInfo[mapId].lastQueryTime and module.Time.now()-businessInfo[mapId].lastQueryTime>15 then
		local sn = NetworkService.Send(3469,{nil,mapId})
		CityArr[sn] = mapId
	else
		return businessInfo[mapId]
	end
end

local function ClearCityBusinessInfo(mapId)
	businessInfo = businessInfo or {}
	businessInfo[mapId] = nil
end

EventManager.getInstance():addListener("CITY_BUSINESSINFO_CHANGE", function(event,data)
	ClearCityBusinessInfo(data)
end)

EventManager.getInstance():addListener("server_respond_3470", function(event, cmd, data)
	-- ERROR_LOG("城市经济_3470====>",sprinttb(data))
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		if CityArr[sn] then
			local mapId = CityArr[sn]
			businessInfo[mapId] = {}
			businessInfo[mapId].lastQueryTime = module.Time.now()
			if data[3] then
				for i=1,#data[3] do
					local type = data[3][i][1]
					businessInfo[mapId][type] = {}
					businessInfo[mapId][type].num = data[3][i][2] or 0
					businessInfo[mapId][type].value = data[3][i][3] or 0
				end
			end
			DispatchEvent("CITY_BUSINESS_INFO_CHANGE",mapId);
		end
	end
end)

-- C_GUILD_GAMBLE_QUERY_REQUEST = 3433  --查询
-- req[1] = sn
-- req[2] = mapId
local SnArr = {}
local cityDrawCardGroup = nil
local lastQuaryTime = Time.now()
local resetDelay = 20
local function QuaryCityDrawCard(mapId)
    --ERROR_LOG("查询mapId",mapId)
    if cityDrawCardGroup == nil or Time.now()-lastQuaryTime > resetDelay then
        NetworkService.Send(3433,{nil,mapId})
    end
    return cityDrawCardGroup and cityDrawCardGroup[mapId]
end
-- C_GUILD_GAMBLE_QUERY_RESPOND = 3434
-- ret[1] = sn
-- ret[2] = result
-- ret[3] = {mapId, extra_equip_reward, extra_item_id, extra_item_value, jackpot}
EventManager.getInstance():addListener("server_respond_3434", function(event, cmd, data)
    --ERROR_LOG("查询_3434",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        cityDrawCardGroup = cityDrawCardGroup or {}
        if data[3] and next(data[3]) then
            local mapId = data[3][1]
            cityDrawCardGroup[mapId] = SetCityDrawCardInfo(data[3])

            DispatchEvent("CITY_DRAW_CARD_INFO_CHANGE",{mapId,cityDrawCardGroup[mapId]});
        end
    end
end)

-- C_GUILD_GAMBLE_LUCKY_DRAW_REQUEST = 3435   --抽奖
-- req[1] = sn
-- req[2] = mapId
local function CityDrawCard(mapId,usePrior)
    --ERROR_LOG("抽奖mapId",mapId)
    local sn = NetworkService.Send(3435,{nil,mapId,usePrior})
    SnArr[sn] = mapId
end

-- C_GUILD_GAMBLE_LUCKY_DRAW_RESPOND = 3436
-- ret[1] = sn
-- ret[2] = result
-- ret[3] = extra_equip_uuid,
-- ret[4] = extra_reward,
EventManager.getInstance():addListener("server_respond_3436", function(event, cmd, data)
    -- ERROR_LOG("抽奖_3436",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if SnArr[sn] then
        local mapId = SnArr[sn]
        if err == 0 then
            cityDrawCardGroup = cityDrawCardGroup or {}
            cityDrawCardGroup[mapId] = cityDrawCardGroup[mapId] or {}
            cityDrawCardGroup[mapId].JackpotFunds = data[6]
        end
        ClearCityBusinessInfo(mapId)
        DispatchEvent("CITY_DRAW_CARD_INFO_CHANGE",{mapId,cityDrawCardGroup and cityDrawCardGroup[mapId]});
    end
end)

-- C_GUILD_GAMBLE_SET_EXTRA_PRICE_REQUEST = 3437   --设置额外奖励
-- req[1] = sn
-- req[2] = mapId
-- req[3] = equip_uuid  (-1, 保持原来的装备)
-- req[4] = item_id
-- req[5] = item_value
local function SetPoolExtraAward(mapId,uuid,id,count)
    --ERROR_LOG("设置额外奖励",mapId,uuid,id,count)
    uuid = uuid or -1
    id = id or -1
    count = count or -1
    NetworkService.Send(3437,{nil,mapId,uuid,id,count})
end


-- C_GUILD_GAMBLE_SET_EXTRA_PRICE_RESPOND = 3438
-- ret[1] = sn
-- ret[2] = result
EventManager.getInstance():addListener("server_respond_3438", function(event, cmd, data)
    --ERROR_LOG("设置额外奖励_3438",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then

    end
end)

-- C_GUILD_GAMBLE_DRAW_JACKPOT_REQUEST = 3439    --领取军团资金
-- req[1] = sn
-- req[2] = mapId
local function GetCityJackpotFunds(mapId)
    --ERROR_LOG("领取累计基金mapId",mapId)
    local sn = NetworkService.Send(3439,{nil,mapId})
    SnArr[sn] = mapId
end

-- C_GUILD_GAMBLE_DRAW_JACKPOT_RESPOND = 3440
-- ret[1] = sn
-- ret[2] = mapId
EventManager.getInstance():addListener("server_respond_3440", function(event, cmd, data)
    --ERROR_LOG("领取累计基金_3440",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        if SnArr[sn] then
        	local mapId = SnArr[sn]
            cityDrawCardGroup = nil
            ClearCityBusinessInfo(mapId)
            --领取成功以后重新查询抽奖相关信息
            DispatchEvent("GET_CITY_JACKPOTFUNDS_SUCCEED",mapId);
            QuaryCityDrawCard(mapId)
            SnArr[sn] = nil
        end
    end
end)
-- C_GUILD_MAP_SET_QUEST_REQUEST = 3445
-- C_GUILD_MAP_SET_QUEST_RESPOND = 3446  mapid  group
local function SetCityQuest(mapId,questGroup)
    -- ERROR_LOG("更换建设城市 任务",mapId,questGroup)
    local sn = NetworkService.Send(3445,{nil,mapId,questGroup})
    SnArr[sn] = {mapId,questGroup}
end

-- C_GUILD_GAMBLE_DRAW_JACKPOT_RESPOND = 3440
-- ret[1] = sn
-- ret[2] = mapId
EventManager.getInstance():addListener("server_respond_3446", function(event, cmd, data)
    --ERROR_LOG("更换建设城市 任务——3446",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        if SnArr[sn] then    
            DispatchEvent("SET_CITY_QUEST_SUCCEED",SnArr[sn]);
            SnArr[sn] = nil
            --更换建设任务 成功后 重新获取城市信息
            module.QuestModule.CityContuctInfo(true)
        end
    end
end)

local defaultMapId = 30
local function UpdateDefaultMapId(uninInfoId)
    local cityCfg = ActivityConfig.GetSortCityCfg()
    coroutine.resume(coroutine.create(function ()
        local allInfo = module.GuildSeaElectionModule.GetAll(true);
        for i=1,#cityCfg do
            local mapId = cityCfg[i].map_id
            local status = 2--status--2不显示 0已报名 1-占领者
            if allInfo[mapId] and allInfo[mapId].apply_begin_time ~= -1 then
                for i,v in ipairs(allInfo[mapId].apply_list) do
                    if v == uninInfoId then
                        status = 0
                        --报名城市
                        defaultMapId = mapId
                    end
                end
                if status == 2 then
                    --防守方
                    module.BuildScienceModule.QueryScience(mapId,function (cityInfo)
                        local ownerId = cityInfo and cityInfo.title or 0;
                        if ownerId == uninInfoId then
                            status = 1
                            --占领城市
                            defaultMapId = mapId
                        end
                    end)
                end
            end    
            --没有争夺战信息
            if status == 2 then
                --城市拥有者
                module.BuildScienceModule.QueryScience(mapId,function (cityInfo)
                    local ownerId = cityInfo and cityInfo.title or 0;
                    if ownerId == uninInfoId then
                        defaultMapId = mapId
                    end
                end)
            end
        end
    end))
end
--离开工会
EventManager.getInstance():addListener("LOCAL_UNION_LEAVEUNION",function(event,data)  
    if data and data == module.playerModule.GetSelfID() then
        defaultMapId = 30
    end
end)
--加入工会
EventManager.getInstance():addListener("LOCAL_UP_UNIONACTIVITY",function(event,data)
    if defaultMapId ~= 30 then
        local uninInfo = module.unionModule.Manage:GetSelfUnion();
        if uninInfo and uninInfo.id then
            local uninInfoId = uninInfo.id
            UpdateDefaultMapId(uninInfoId)
        end
    end
end)

EventManager.getInstance():addListener("QUERY_SELFUNION_SUCCEND", function(event,data)
    if data and data[6] then--有工会
        local uninInfoId = data[6]
        UpdateDefaultMapId(uninInfoId)
    end
end)

local function GetDefaultMapId()
    return defaultMapId
end

return {
    QuaryCityDrawCard = QuaryCityDrawCard,
    CityDrawCard = CityDrawCard,

    GetCityJackpotFunds = GetCityJackpotFunds,

    SetCityQuest = SetCityQuest,
    GetDefaultMapId = GetDefaultMapId,
    GetCityBusinessInfo = GetCityBusinessInfo,
}