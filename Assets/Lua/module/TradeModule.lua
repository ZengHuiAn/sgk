local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Time = require "module.Time"
local UserDefault = require "utils.UserDefault"

local C_TRADE_QUERY_PLAYER_ORDERS_REQUEST = 15101  --查询玩家上架货物订单
--[sn]
local C_TRADE_QUERY_PLAYER_ORDERS_RESPOND = 15102
--[sn, result, [gid:订单号 {commodity_type:商品类型， commodity_id:商品id， commodity_value:商品数量, uuid},{cost_type:价格类型, cost_id:价格id, cost_value:价格数量}, putaway_time:上架时间]]  上架订单24小时候过期

local C_TRADE_SELL_REQUEST = 15103  --商品上架到交易行请求
--[sn, {type, id, value, uuid}, price, gid]
local C_TRADE_SELL_RESPOND = 15104
--[sn, result]

local C_TRADE_TAKE_BACK_REQUEST = 15105  --下架商品请求
--[sn, gid]
local C_TRADE_TAKE_BACK_RESPOND = 15106
--[sn, result]
local C_TRADE_BUY_REQUEST = 15107 --购买商品
--[sn, gid]
local C_TRADE_BUY_RESPOND = 15108
--[sn, result]
local C_TRADE_QUERY_ORDERS_RANK_REQUEST = 15109     --查询物品价格排行榜请求
--[sn, target_type, target_id, beg, len]
local C_TRADE_QUERY_ORDERS_RANK_RESPOND = 15110
--[sn, result, [gid:订单号 {commodity_type:商品类型， commodity_id:商品id， commodity_value:商品数量, uuid},{cost_type:价格类型, cost_id:价格id, cost_value:价格数量}, putaway_time:上架时间, concern_count：关注人数,concern：是否被本人关注（1：自己已关注，0：自己没关注）]]

local C_TRADE_QUERY_COMMODITY_CONFIG_REQUEST = 15111  --查询商品配置请求
--[sn]
local C_TRADE_QUERY_COMMODITY_CONFIG_RESPOND = 15112
--[sn, result, [commodity_type:商品类型, commodity_id:商品id，sale_value:商品出售量, cost_type:价格类型, cost_id:价格id， assess_value:评估价格, fee_type:手续费类型， fee_id:手续费id， fee_rate:手续费收取百分比], tax_rate:税率]

local C_TRADE_QUERY_TRADEORDERS_REQUEST = 15113	 --查询交易记录
--[sn, record_type, type]
local C_TRADE_QUERY_TRADEORDERS_RESPOND = 15114
--[sn, result, record_list]
local C_TRADE_SET_COMMODITY_CONCERN_REQUEST = 15115     --设置或取消关注
--[sn, type 1:关注  0:取消关注, gid 订单号]
local C_TRADE_SET_COMMODITY_CONCERN_RESPOND = 15116
--[sn, result]
local C_TRADE_QUERY_COMMODITY_CONCERN_REQUEST = 15117	 --查询我的关注
--[sn]
local C_TRADE_QUERY_COMMODITY_CONCERN_RESPOND = 15118
--[sn, result, [gid:订单号 {commodity_type:商品类型， commodity_id:商品id， commodity_value:商品数量, uuid},{cost_type:价格类型, cost_id:价格id, cost_value:价格数量}, putaway_time:上架时间, concern_count：关注人数]]


local C_TRADE_QUERY_EQUIP_INFO_REQUEST = 110;   --查询装备属性
local C_TRADE_QUERY_EQUIP_INFO_RESPOND = 111;

local TradeInfo = {};
local Sn2Data = {};

local function ON_SERVER_RESPOND(id, callback)
    EventManager.getInstance():addListener("server_respond_" .. id, callback);
end

local function ON_SERVER_NOTIFY(id, callback)
    EventManager.getInstance():addListener("server_notify_" .. id, callback);
end

local tradeConfig = nil;
local tradeConfigByGid = nil;
local tradeConfigById = nil;
local tradeConfigByType = nil;
local function LoadConfig()
    tradeConfigById = {};
    tradeConfigByGid = {};
    tradeConfigByType = {};

    DATABASE.ForEach("trading_firm", function(row)
        if row.is_trading == 1 then
            tradeConfigByGid[row.gid] = row;
            if tradeConfigById[row.item_type] == nil then
                tradeConfigById[row.item_type] = {};
            end
            tradeConfigById[row.item_type][row.item_id] = row;
            if tradeConfigByType[row.pack_type] == nil then
                tradeConfigByType[row.pack_type] = {};
                tradeConfigByType[row.pack_type].name = row.pack_name;
                tradeConfigByType[row.pack_type].list = {};
            end
            if tradeConfigByType[row.pack_type].list[row.sub_type] == nil then
                tradeConfigByType[row.pack_type].list[row.sub_type] = {};
                tradeConfigByType[row.pack_type].list[row.sub_type].name = row.sub_name;
                tradeConfigByType[row.pack_type].list[row.sub_type].list = {};
            end
            table.insert(tradeConfigByType[row.pack_type].list[row.sub_type].list, row);
        end
    end)
end

local tradeSortConfig = nil;
local function LoadSortConfig()
    tradeSortConfig = {};
    DATABASE.ForEach("trading_sort", function(row)
        if tradeSortConfig[row.pack_type] == nil then
            tradeSortConfig[row.pack_type] = {};
        end
        table.insert(tradeSortConfig[row.pack_type], row);
    end)
end

local trading_transform = nil;
local function GetTradingTransform(id1, id2)
    if trading_transform == nil then
        trading_transform = {};
        DATABASE.ForEach("trading_transform", function(row)
            if trading_transform[row.item_id_1] == nil then
                trading_transform[row.item_id_1] = {};
            end
            trading_transform[row.item_id_1][row.item_id_2] = row;
        end)
    end
    if trading_transform[id1] then
        return trading_transform[id1][id2];
    end
end

local function GetSortConfig(type)
    if tradeSortConfig == nil then
        LoadSortConfig();
    end
    return tradeSortConfig[type]
end

local function GetConfigByGid(gid)
    if tradeConfigByGid == nil then
        LoadConfig();
    end    
    return tradeConfigByGid[gid]
end 

local function GetConfigById(type, id)
    if tradeConfigById == nil then
        LoadConfig();
    end    
    if tradeConfigById[type] then
        return tradeConfigById[type][id]
    else
        ERROR_LOG("配置未找到", type, id)
    end
end 

local function GetConfigByType(type)
    if tradeConfigByType == nil then
        LoadConfig();
    end    
    if type then
        return tradeConfigByType[type]
    end
    return tradeConfigByType;
end 

local qualityFilter = nil
local function GetItemFilter(_pack_type, _sub_type)
    if qualityFilter == nil then
        qualityFilter = {};
        local _tradeConfigByType = GetConfigByType();
        for pack_type,v in pairs(_tradeConfigByType) do
            if qualityFilter[pack_type] == nil then
                qualityFilter[pack_type] = {};
            end
            for sub_type,j in pairs(v.list) do
                if qualityFilter[pack_type][sub_type] == nil then
                    qualityFilter[pack_type][sub_type] = {};
                end
                for _,k in ipairs(j.list) do
                    local cfg = utils.ItemHelper.Get(k.item_type, k.item_id);
                    if qualityFilter[pack_type][sub_type][cfg.quality] == nil then
                        qualityFilter[pack_type][sub_type][cfg.quality] = 1;
                    end
                end
            end
        end
    end
    if _sub_type then
        return qualityFilter[_pack_type][_sub_type]
    elseif _pack_type then
        return qualityFilter[_pack_type]
    end
    return qualityFilter
end

local function GetPlayerOrders(func)
    print("请求玩家上架订单")
    local sn = NetworkService.Send(C_TRADE_QUERY_PLAYER_ORDERS_REQUEST);
    Sn2Data[sn] = {func = func}
end

ON_SERVER_RESPOND(C_TRADE_QUERY_PLAYER_ORDERS_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    local list = data[3]
    if result ~= 0 then
        print("查询玩家上架货物失败", result)
        return;
    end
    if Sn2Data[sn].func ~= nil then
        Sn2Data[sn].func(list);
    end
    print("查询玩家上架订单", sprinttb(list))
end)

local function Sell(type, id, value, price, uuid, gid)
    uuid = uuid or 0;
    local sn = NetworkService.Send(C_TRADE_SELL_REQUEST, {nil, {type, id, value, uuid}, price, gid});
    print("出售", type, id, value, uuid, price, gid)
end

ON_SERVER_RESPOND(C_TRADE_SELL_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("上架货物失败", result)
        return;
    end
    print("上架货物成功", sprinttb(data))
    DispatchEvent("TRADE_SELL_SUCCESS")
end)

local function TakeBack(gid)
    print("下架", gid)
    NetworkService.Send(C_TRADE_TAKE_BACK_REQUEST, {nil, gid})
end

ON_SERVER_RESPOND(C_TRADE_TAKE_BACK_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("下架货物失败", result)
        if result == 3 then
            DispatchEvent("TRADE_TAKEBACK_FAILD")
        end
        return;
    end
    DispatchEvent("TRADE_TAKEBACK_SUCCESS")
end)

local tradeRecord = {};
local ref_buy = false;
local function Buy(gid, order_info)
    print("购买", gid);
    local sn = NetworkService.Send(C_TRADE_BUY_REQUEST, {nil, gid})
    Sn2Data[sn] = {order_info = order_info};
end

-- 0：购买成功
-- 1：常规问题(服务器的问题)
-- 2：订单不存在
-- 3：订单过期
-- 4：参数问题
-- 5：交易失败(金币不足等问题)

ON_SERVER_RESPOND(C_TRADE_BUY_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("购买货物失败", result)
        if result == 2 or result == 3 then
            DispatchEvent("TRADE_ORDER_NOT_EXIST")
        end
        return;
    end
    if Sn2Data[sn] and Sn2Data[sn].order_info then
        local record = {};
        record[1] = Sn2Data[sn].order_info[2];
        record[2] = Sn2Data[sn].order_info[3];
        -- if tradeRecord[2] then
        --     table.insert(tradeRecord[2], record);
        -- end
    end
    ref_buy = true;
    print("购买货物成功", sprinttb(data));
    DispatchEvent("TRADE_BUY_SUCCESS")
end)

local function QueryOrdersRank(gid, func, min_lev, max_lev, quality, beg, len)
    beg = beg or 1;
    len  = len or 50;
    local cfg = GetConfigByGid(gid)
    print("查询", cfg.item_type, cfg.item_id, beg, len, min_lev, max_lev, quality)
    local sn = NetworkService.Send(C_TRADE_QUERY_ORDERS_RANK_REQUEST , {nil, cfg.item_type, cfg.item_id, beg, len, min_lev, max_lev, quality})
    Sn2Data[sn] = {func = func};
end

ON_SERVER_RESPOND(C_TRADE_QUERY_ORDERS_RANK_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    local ranklist = data[3];
    if result ~= 0 then
        print("查询商品排行失败", result)
        return;
    end
    if Sn2Data[sn].func ~= nil then
        Sn2Data[sn].func(ranklist)
    end
    print("查询商品排行",sprinttb(ranklist))
end)

local commodityConfig = {};
local lastQueryTime = 0;
local function QueryCommodityConfig(func)
    print("请求商品配置")
    local sn = NetworkService.Send(C_TRADE_QUERY_COMMODITY_CONFIG_REQUEST)
    Sn2Data[sn] = {func = func};
end

local function GetCommodityConfig(func)
    if Time.now() >= lastQueryTime + 86400 then
        QueryCommodityConfig(func)
    else
        if func then
            func(commodityConfig);
        end
    end
    return commodityConfig;
end

ON_SERVER_RESPOND(C_TRADE_QUERY_COMMODITY_CONFIG_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    local list = data[3];
    local tax = data[4];
    if result ~= 0 then
        print("查询商品配置失败", result)
        return;
    end

    local _now = os.date("*t", Time.now());
    lastQueryTime = Time.now() - _now.sec - (_now.min * 60) - (_now.hour * 3600);
    local info = {};
    info.tax = tax;
    for i,v in ipairs(list) do
        local cfg = {};
        cfg.commodity_type = v[1];
        cfg.commodity_id = v[2];
        cfg.sale_value = v[3];
        cfg.cost_type = v[4];
        cfg.cost_id = v[5];
        cfg.assess_value = v[6];
        cfg.fee_type = v[7];
        cfg.fee_id = v[8];
        cfg.fee_rate =v[9];
        info[v[2]] = cfg;
    end
    commodityConfig = info;
    if Sn2Data[sn].func ~= nil then
        Sn2Data[sn].func(commodityConfig)
    end
    -- print("查询商品配置", tax, sprinttb(info))
end)


local function QueryTradeRecord(record_type, type, func)
    print("查询记录", record_type, type)
    local sn = NetworkService.Send(C_TRADE_QUERY_TRADEORDERS_REQUEST, {nil, record_type, type});
    Sn2Data[sn] = {func = func, record_type = record_type, type = type};
end

local function GetTradeRecord(type, func)
    if type == 1 then
        QueryTradeRecord(type, 1, func);
    elseif type == 2 then
        if tradeRecord[type] and not ref_buy then
            if func then
                func(tradeRecord[type]);
            end
        else
            QueryTradeRecord(type, 1, func);
        end
    end
    return tradeRecord[type]
end

local function CleanTradeRecord(type)
    QueryTradeRecord(type, 2);
end

ON_SERVER_RESPOND(C_TRADE_QUERY_TRADEORDERS_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    local record_list = data[3];
    print("交易记录", sprinttb(record_list))
    tradeRecord[Sn2Data[sn].record_type] = record_list;
    if Sn2Data[sn].record_type == 2 then
        ref_buy = false
    end
    if Sn2Data[sn].func ~= nil then
        Sn2Data[sn].func(record_list)
    end
    if Sn2Data[sn].type == 2 then
        DispatchEvent("TRADE_RECORD_CHANGE")
    end
end)

local function CareAboutOrder(gid, type)
    print("关注", gid, type)
    local sn = NetworkService.Send(C_TRADE_SET_COMMODITY_CONCERN_REQUEST, {nil, type, gid});
    Sn2Data[sn] = {gid = gid, type = type};
end

ON_SERVER_RESPOND(C_TRADE_SET_COMMODITY_CONCERN_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("关注商品失败", result);
        return;
    end
    if Sn2Data[sn] then
        DispatchEvent("TRADE_ORDER_CRAE_SUCCESS", Sn2Data[sn].type)
    end
end)

local function QueryCareAboutList(func)
    print("查询关注")
    local sn = NetworkService.Send(C_TRADE_QUERY_COMMODITY_CONCERN_REQUEST);
    Sn2Data[sn] = {func = func};
end

ON_SERVER_RESPOND(C_TRADE_QUERY_COMMODITY_CONCERN_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    if result ~= 0 then
        print("查询关注商品失败", result);
        return;
    end
    print("关注商品列表", sprinttb(data[3]))
    if Sn2Data[sn] and Sn2Data[sn].func then
        Sn2Data[sn].func(data[3])
    end
end)

return {
    GetConfigByGid = GetConfigByGid,
    GetConfigById = GetConfigById,
    GetConfigByType = GetConfigByType,
    GetSortConfig = GetSortConfig,
    GetPlayerOrders = GetPlayerOrders,
    Sell = Sell,
    TakeBack = TakeBack,
    Buy = Buy,
    QueryOrdersRank = QueryOrdersRank,
    QueryCommodityConfig = QueryCommodityConfig,
    GetCommodityConfig = GetCommodityConfig,
    GetTradeRecord = GetTradeRecord,
    CleanTradeRecord = CleanTradeRecord,
    CareAboutOrder = CareAboutOrder,
    QueryCareAboutList = QueryCareAboutList,
    GetTradingTransform = GetTradingTransform,
    GetItemFilter = GetItemFilter,
}