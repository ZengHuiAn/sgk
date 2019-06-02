local NetworkService = require "utils.NetworkService";
local EventManager = require 'utils.EventManager';
local Shop_Data = nil;
local Time = require "module.Time"
local activityConfig = require "config.activityConfig"
--查询公会仓库的时间
local next_fresh_time = nil;

local query_time = nil;
local Shop_Data_Two = nil;


local mapSnAar = nil


local function get_timezone()
    local now = os.time()
    return os.difftime(now, os.time(os.date("!*t", now)))/3600
end

local function date(now)
    local now = now or Time.now();
    return os.date ("!*t", now + 8 * 3600);
end

local function getTimeByDate(year,month,day,hour,min,sec)

   local east8 = os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec})+ (get_timezone()-8) * 3600
   return east8
end

-- 3427
--查询地图商店
local function QueryMapShopInfo( mapid,status )
	if query_time then
			--将上次的时间转换成年月日
		local time_t = date(query_time)
			--求到第二天的时间戳
		local querytime = getTimeByDate(time_t.year,time_t.month,time_t.day+1,0,0,0);
		-- ERROR_LOG("上次查询时间",querytime,Time.now());
		if Time.now() > querytime then

		else
			if not status and Shop_Data then
				if not Shop_Data or not Shop_Data[mapid] or not next(Shop_Data[mapid]) then
					return nil;
				end

				return (not next(Shop_Data[mapid])) and nil or  Shop_Data[mapid].mainData;
			end
		end
	else

	end


	mapSnAar = {};
	local allmap = activityConfig.GetCityConfig().map_id;
	for k,v in pairs(allmap) do
		local ret = NetworkService.Send(3427,{nil,v.map_id});
		mapSnAar[ret] = v.map_id;
	end
	query_time = Time.now();
	-- ERROR_LOG("QueryMapShopInfo",sprinttb(mapSnAar));
end

local function GetFreshTime(mapid)
	return Shop_Data[mapid].fresh_time;
end

local function updateShopInfo( data,fresh_time,mapid )
	if not data then
		-- ERROR_LOG("data is nil");
		return;
	end

	for k,v in pairs(data) do
			
		local map_id = v[2];

		local gid = v[1];
		
		local consume = v[3][1];
		
		local limt_consume = v[4][1];
		
		local reward = v[5][1];
		--地图仓库获得的物品
		local map_wareRoom = v[6];
		
		--军团获得的物品
		
		local guild_rewardid = v[7];
		
		local guild_rewardvalue = v[8];
		
		local guildReward = {id = guild_rewardid,value = guild_rewardvalue};
		
		local storage = v[9];
		
		local sell_count = v[10];
		
		local specialty = v[11];
		
		local default_price = v[12];
		
		local buy_limit = v[13];
		local buy_type  = v[16];
		local temp = {map_id = map_id,gid = gid,consume = consume,
				limt_consume = limt_consume,reward = reward,map_wareRoom = map_wareRoom,
				guildReward = guildReward,storage = storage,
				sell_count = sell_count,
				specialty = specialty,
				default_price = default_price,
				buy_limit = buy_limit,

				buy_type = buy_type,
			};	

			Shop_Data[map_id].custom[consume[2]] = Shop_Data[map_id].custom[consume[2]] or {};

			Shop_Data[map_id].custom[consume[2]] [reward[2]] = { gid = gid,mapid = map_id, value = consume[3] };
		-- [consume[2]] [[reward[2]] = {value = consume[3]}
		if buy_type == 1 then
			table.insert( Shop_Data[map_id].mainData, temp );
		else
			Shop_Data_Two = Shop_Data_Two or {};
			Shop_Data_Two[map_id] = Shop_Data_Two[map_id] or {};
			table.insert( Shop_Data_Two[map_id], temp );
		end
	end
	
	if Shop_Data then	
		Shop_Data[mapid].fresh_time = fresh_time;
		for k,v in pairs(Shop_Data) do
			table.sort( v, function ( a,b )
				return a.mainData.gid < b.mainData.gid;
			end )
		end
	end

end

local function GetMapShopInfo( mapid )
	return Shop_Data_Two and Shop_Data_Two[mapid] or Shop_Data_Two
end

local Snaar = nil;
local Depot = nil;
local function GetMapDepot( map_id )
	return Depot and Depot[map_id] or nil;
end
--查询地图仓库
local function QueryMapDepot(map_id,isreset)
	if not isreset then
		-- GetMapDepot(map_id);
		if next_fresh_time then
			if next_fresh_time - Time.now() < 60 then
				return ;
			end
		else
			next_fresh_time = Time.now();
		end
	end
	next_fresh_time = Time.now();

	local sn = NetworkService.Send(3441,{nil,map_id});
	Snaar = Snaar or {};

	Snaar[sn] = map_id;

end
-- 1531238400

EventManager.getInstance():addListener("server_respond_3428",function ( event,cmd,data )
	-- ERROR_LOG("查询地图商店","server_respond_3428",sprinttb(data));
	local sn = data[1];

	-- print("sn---------",sn)
	Shop_Data = Shop_Data or {};
	-- ERROR_LOG(mapSnAar[sn])
	if mapSnAar[sn] then
		Shop_Data[mapSnAar[sn]] = {}; 

		Shop_Data[mapSnAar[sn]].mainData = {};

		Shop_Data[mapSnAar[sn]].custom = {};

		if data[2] == 0 then
			if next(data[3]) then
				updateShopInfo(data[3],data[4],mapSnAar[sn]);
				DispatchEvent("QUERY_MAP_SHOPINFO_SUCCESS",mapSnAar[sn]);
			end
		else

		end
	end
	
end)

local function QueryMapProducInfo(mapid)
	return Shop_Data[mapid].custom;
end

local buyAAr = nil;

--购买地图商店商品
local function BuyMapProduct( gid,num ,mapid,callback)
	-- ERROR_LOG("购买商品"..gid);
	local ret = NetworkService.Send(3429,{nil,gid,num or 1});
	buyAAr = buyAAr or {};
	buyAAr[ret] = {gid = gid,mapid = mapid,func = callback }
end

EventManager.getInstance():addListener("server_respond_3430",function ( event,cmd,data )
	-- ERROR_LOG("购买商品","server_respond_3430",sprinttb(data));
	
	local _data = buyAAr[data[1]];

	if _data.func then
		_data.func();
	end
	if data[2] == 0 then

		-- Shop_Data[mapID][current] = data[2][1];

		-- print("重新查询数量",sprinttb(_data))
		QueryMapDepot(_data.mapid,true);
		DispatchEvent("CITY_BUSINESSINFO_CHANGE",_data.mapid);
		-- DispatchEvent("QUERY_MAP_SHOPINFO_SUCCESS",{[data[2][2]] = Shop_Data[data[2][2]]});
	elseif data[2] == 108 then
		showDlgError(nil,"商品已售完!");
		QueryMapDepot(_data.mapid,true);
	end
end)


local SnPrice = nil
local function SetMapPrice( price_tb ,mapid)
	SnPrice = SnPrice or {};
	local ret = NetworkService.Send(3431,{nil,price_tb});
	SnPrice[ret] = { mapid = mapid }

	-- print("设置价格",sprinttb(price_tb))
end

EventManager.getInstance():addListener("server_respond_3432",function ( event,cmd,data )
	-- ERROR_LOG("设置价格返回","server_respond_3432",sprinttb(data));
	
	if data[2] == 0 then
		local mapid = SnPrice[data[1]].mapid
		-- Shop_Data[mapid][current] = data[2][1];
		if Shop_Data[mapid] and Shop_Data[mapid].fresh_time then
			Shop_Data[mapid].fresh_time = Time.now();
		end
		DispatchEvent("MAP_SET_SHOPINFO_SUCCESS");
	else

	end
end)


local function updateShopPrice(data)
	if Shop_Data then

		if not Shop_Data[data.mapid] then
			return;
		end
		for k,v in pairs(Shop_Data[data.mapid].mainData) do 

			if v.gid == data.gid  then
				v.consume[3] = data.price;

				Shop_Data[data.mapid].custom[v.consume[2]] [v.reward[2]].value = v.consume[3] ;
				-- v.consume[]
			end
		end
	end
end

local nex_fresh_price = nil;

EventManager.getInstance():addListener("server_notify_3425",function ( event,cmd,data)
	-- ERROR_LOG("商品价格通知","server_notify_3425",sprinttb(data))
	
	for k,v in pairs(data) do
		local temp = { mapid = v[2] ,gid = v[1],price = v[3] }
		updateShopPrice(temp);
	end

	if nex_fresh_price and nex_fresh_price - Time.now() > 60 then
		DispatchEvent("MAP_SHOP_PRICE_INFOCHANGE",data[2]);
	else
		nex_fresh_price = Time.now();
	end
end)

local function updateSellCout( data )
	if Shop_Data then
		if not Shop_Data[data.mapid] then
			return;
		end
		for k,v in pairs(Shop_Data[data.mapid].mainData) do
			if v.gid == data.gid  then
				v.sell_count = data.sell_count;
			end
		end
	end
end

-- 3425



EventManager.getInstance():addListener("server_notify_3426",function ( event,cmd,data)
	-- ERROR_LOG("出售数量变化通知","server_notify_3426",sprinttb(data))
	
	local temp = { mapid = data[2],gid = data[1],sell_count = data[3] };
	updateSellCout(temp);
	
	-- DispatchEvent("MAP_SHOP_COUNT_INFOCHANGE",data[2]);
end)


local function updateMapDepot(mapid,data)
	Depot = Depot or {};
	Depot[mapid] = {};
	for k,v in pairs(data) do
		-- print("------------",v[1])
		Depot[mapid][v[1]] = {value = v[2]};
	end
end

EventManager.getInstance():addListener("server_respond_3442",function ( event,cmd,data )
	-- ERROR_LOG("查询地图仓库","server_respond_3442",sprinttb(data));

	local sn = data[1];
	local mapid = Snaar[sn];
	if data[2] == 0 then

		updateMapDepot(mapid,data[3]);
		DispatchEvent("QUERY_MAP_DEPOT",mapid);
	end
end)

return {

	QueryMapShopInfo = QueryMapShopInfo,  --查询地图商店信息

	SetMapPrice = SetMapPrice,  --设置商品价格

	BuyMapProduct = BuyMapProduct, -- 购买商品

	QueryMapProducInfo = QueryMapProducInfo,

	QueryMapDepot = QueryMapDepot ,  --查询地图仓库

	GetMapDepot = GetMapDepot,

	GetMapShopInfo = GetMapShopInfo,

	GetFreshTime = GetFreshTime,
}