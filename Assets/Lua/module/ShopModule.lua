local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local PlayerModule = require "module.playerModule";
local Time = require "module.Time";

local ShopArr = {}
local SnArr = {}
local NpcSouvenirArr = {}
local shopConfig = nil;
local function loadShopConfig(id)
	if shopConfig == nil then
		shopConfig = LoadDatabaseWithKey("product_config", "Shop_id");
	end
	if id ~= nil then
		return shopConfig[id];
	end
	return shopConfig;
end

local function Set(shop_id,data,canRefresh,next_fresh_time,refreshCousume)
	if shop_id and data then
		local tempShop = {}
		--print("ShopData",shop_id,#data,sprinttb(data))
		for i = 1,#data do
			local gid = data[i][1];
			local product_item_list = {}
			for _, v in ipairs(data[i][18] or {}) do
				table.insert(product_item_list, {
					--idx = v[1], type = v[2], id = v[3], value = math.floor(v[4] * (data[i][4] / 10000) * (v[5] / 10000)), grow = v[5]
					idx = v[1], type = v[2], id = v[3], value = math.floor(v[4] * data[i][4] * v[5] /100000000), grow = v[5]
				})
				-- if v[3] == 1419041 and data[i][6] == 51005 then
				-- 	ERROR_LOG(math.floor(v[4] * data[i][4] * v[5] /100000000))
				-- end
				if not NpcSouvenirArr[v[3]] then
					NpcSouvenirArr[v[3]] = {}
				end
				local consume = {type = data[i][5],id = data[i][6],value = data[i][7]}
				local ShopName = loadShopConfig(shop_id) and loadShopConfig(shop_id).Name or "未知商店id"..shop_id
				NpcSouvenirArr[v[3]][data[i][6]] = {idx = v[1], type = v[2], id = v[3], value = math.floor(v[4] * data[i][4] * v[5] /100000000), grow = v[5],gid = gid,shop_id = shop_id,consume = consume,ShopName = ShopName}
			end

			if #product_item_list == 0 then
				product_item_list = nil;
			end
			tempShop[gid] = {
				gid = gid,
				shop_id = shop_id,
				product_item_type = data[i][2],
				product_item_id = data[i][3],
				product_item_value = data[i][4],
				consume_item_type1 = data[i][5],
				consume_item_id1 = data[i][6],
				consume_item_value1 = data[i][7],
				consume_item_type2 = data[i][8],
				consume_item_id2 = data[i][9],
				consume_item_value2 = data[i][10],
				storage = data[i][11],
				special_flag = data[i][12],
				origin_price = data[i][13],
				discount = data[i][14],
				buy_count = data[i][15],
				vip_extra = data[i][16],
				vip_min = data[i][17][1],
				vip_max = data[i][17][2],
				begin_time = data[i][17][3],
				end_time = data[i][17][4],
				product_count = data[i][11] - data[i][15],
				lv_min = data[i][17][5],--物品等级限制
				lv_max = data[i][17][6],
				drop = data[i][19],
				product_item_list = product_item_list,
				show_Idx = i,--用来控制工会商店的商品显示范围
			}
			--print(shop_id..">"..data[i][3])
		end
		ShopArr[shop_id] = {};
		ShopArr[shop_id].shoplist = tempShop;
		ShopArr[shop_id].refresh = canRefresh;
		ShopArr[shop_id].next_fresh_time = next_fresh_time
		ShopArr[shop_id].refreshCousume = refreshCousume
		DispatchEvent("SHOP_INFO_CHANGE",{id = shop_id, refresh = canRefresh,refreshCousume=refreshCousume});
	end
end

local function Get(shop_id, product_item_id)
	ShopArr = ShopArr or {}
	--过了刷新时间强制查询 商品列表
	if ShopArr[shop_id] == nil or ShopArr[shop_id].next_fresh_time and ShopArr[shop_id].next_fresh_time <= module.Time.now() then
		local sn = NetworkService.Send(15001,{nil, shop_id});
		if not sn then
			return;
		end
		ShopArr[shop_id] = {}
		SnArr[sn] = shop_id
	end

	local list = ShopArr[shop_id];
	if not product_item_id then
		return list
	end
	list = {}
	for _, v in pairs(ShopArr[shop_id].shoplist or {}) do
		if v.product_item_id == product_item_id then
			list[#list + 1] = v;
		end
	end

	return list;
end

local function BuyProduct(shop_id, gid,num, params,fun)
	--print("BuyProduct", shop_id, gid,num,sprinttb(uuids))
	local param_code = ProtobufEncode(params or {}, "com.agame.protocol.ShopBuyParam")
	local sn = NetworkService.Send(15005,{nil, gid, shop_id,num, param_code});
	local co = coroutine.isyieldable() and coroutine.running();
	SnArr[sn] = {gid = gid, shop_id = shop_id, num = num, co = co,fun = fun};
	if co then
		return coroutine.yield();
	end
end

-- 给特定角色兑换东西
-- 时装兑换
local function BuyProductTarget(shop_id,gid,num,hero_uuid)
	return BuyProduct(shop_id, gid, num, {hero_uuid = hero_uuid});
end

EventManager.getInstance():addListener("server_respond_15010", function(event, cmd, data)
	--ERROR_LOG("server_respond_15010",sprinttb(data))
	local sn = data[1];
	local err = data[2];
	local info = SnArr[sn];
	SnArr[sn] = nil;

	if err == 0 then
		-- print("购买成功");
		DispatchEvent("SHOP_BUY_SUCCEED");
	else
		DispatchEvent("SHOP_BUY_FAILED");
		-- print("购买失败",err);
	end
	if info and info.co then
		coroutine.resume(info.co, err == 0)
	end
end)

local function RefreshShopList(shop_id,consume_type,consume_item_id,consumeCount)--pid ，shopid，couseme type id num
	local sn = NetworkService.Send(15017,{nil, shop_id,consume_type,consume_item_id,consumeCount});
	SnArr[sn] = shop_id;
end

local function GetManager(shop_id, product_item_id)
	return Get(shop_id, product_item_id)
end

local function GetProductCfg(shop_id,product_gid)
	ShopArr = ShopArr or {}
	if ShopArr[shop_id] == nil then
		local sn = NetworkService.Send(15001,{nil, shop_id});
		if not sn then
			return;
		end
		ShopArr[shop_id] = {}
		SnArr[sn] = shop_id
	end

	if product_gid and ShopArr[shop_id] and ShopArr[shop_id].shoplist then
		return ShopArr[shop_id].shoplist[product_gid]
	end
	return ShopArr[shop_id]
end

--商品价格随着购买次数变化
local shoppingFloatPriceConfig = nil;
local function loadShoppingFloatPriceConfig(gid,num)
	if shoppingFloatPriceConfig == nil then
		shoppingFloatPriceConfig = {}
		DATABASE.ForEach("product_price", function(data)
			shoppingFloatPriceConfig[data.gid] = shoppingFloatPriceConfig[data.gid] or {}
			shoppingFloatPriceConfig[data.gid][data.number] = setmetatable({sellPrice=data.value1,origin_price=data.show_value1},{__index=data})
			if not shoppingFloatPriceConfig[data.gid].MaxNum or  (shoppingFloatPriceConfig[data.gid].MaxNum and shoppingFloatPriceConfig[data.gid].MaxNum <data.number) then
				shoppingFloatPriceConfig[data.gid].MaxNum = data.number
			end
		end)
	end
	if gid and num then
		if shoppingFloatPriceConfig[gid] then
			return shoppingFloatPriceConfig[gid][num] or shoppingFloatPriceConfig[gid][shoppingFloatPriceConfig[gid].MaxNum];
		end
	elseif gid and not num then
		return shoppingFloatPriceConfig[gid];
	else
		return shoppingFloatPriceConfig;
	end
end

local productByUnionScience = nil
local function CheckProductByUnionScienceLimit(shopId,product_gid)
	if productByUnionScience == nil then
		productByUnionScience = {}
		DATABASE.ForEach("guild_tech_shop", function(data)
			productByUnionScience[data.shop_type] = productByUnionScience[data.shop_type] or {}
			productByUnionScience[data.shop_type][data.product_gid] = data
		end)
	end

	if shopId and product_gid then
		if productByUnionScience[shopId] then
			return productByUnionScience[shopId][product_gid]
		end
	end
end

local specialShop = {};
local function addSpecialShop(id)
	specialShop[id] = id;
end

local function querySpecialShop(id)
	if specialShop[id] == nil then
		addSpecialShop(id);
	end
	local sn = NetworkService.Send(15003,{nil, 1, id});
	SnArr[sn] = id;
end

local openShop = {};
local function getOpenShop(shop_id)
	if shop_id then
		return openShop[shop_id] or false
	end
	return openShop;
end

local lastQuery_time = 0;
local lastShopID = 0;
local function queryShop(id)
	if id == nil then
		if Time.now() - lastQuery_time > 1800 then
			lastQuery_time = Time.now();
			openShop = {};
			for i,v in pairs(specialShop) do
				local sn = NetworkService.Send(15003,{nil, 1, v});
				SnArr[sn] = v;
			end

			local cfg = loadShopConfig();
			for k,v in pairs(cfg) do
				if v.is_show == 1 then
					local sn = NetworkService.Send(15003,{nil, 1, v.Shop_id});
					SnArr[sn] = v.Shop_id;
					lastShopID = k;
				end
			end
			return false;
		else
			return true;
		end
	else
		local sn = NetworkService.Send(15003,{nil, 1, id});
		SnArr[sn] = id;
	end
end
--商店获取(商品列表)
EventManager.getInstance():addListener("server_respond_15002", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	local canRefresh = data[4];
	local refreshCousume=data[6] and data[6][1]--重置消耗配置

	local shop_id = SnArr[sn]
	SnArr[sn] = nil;

	if err == 0 then
		--ERROR_LOG("商店获取Succeed",shop_id,sprinttb(data));
		if shop_id then
			Set(shop_id, data[5],canRefresh,data[3],refreshCousume);
			return;
		end
		DispatchEvent("SHOP_INFO_CHANGE",{id = shop_id, refresh = canRefresh,refreshCousume=refreshCousume});
	else
		ERROR_LOG("商店获取err shop_id:".. shop_id, err);
		ShopArr[shop_id] = nil
	end
end);
--商店购买
EventManager.getInstance():addListener("server_respond_15006", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	local info = SnArr[sn]
	SnArr[sn] = nil;
	if err == 0 then
		if info then
			if info.fun then
				info.fun()
			end
			info.dropList = data[3]
			if ShopArr[info.shop_id] and ShopArr[info.shop_id].shoplist and ShopArr[info.shop_id].shoplist[info.gid] then
				ShopArr[info.shop_id].shoplist[info.gid].product_count = ShopArr[info.shop_id].shoplist[info.gid].product_count - info.num;
				ShopArr[info.shop_id].shoplist[info.gid].buy_count = ShopArr[info.shop_id].shoplist[info.gid].buy_count + info.num;
			end
		end
		DispatchEvent("SHOP_BUY_SUCCEED",info);
	else
		DispatchEvent("SHOP_BUY_FAILED",info);
		print("购买失败",err);
	end

	if info and info.co then
		coroutine.resume(info.co, err == 0);
	end
end)
--商店查询(开放时间)
EventManager.getInstance():addListener("server_respond_15004", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	local shop_id = SnArr[sn]
	SnArr[sn] = nil;
	if err == 0 then
		if data[3] then
			for i=1,#data[3] do
				local _data=data[3][i]
				if Time.now() > _data[1] and Time.now() < _data[2] then
					local delta = Time.now() - _data[1];
					--delta%_data[3] < _data[4] and
					--刷新时间和 持续时间为0 商店一直开启并且不刷新
					if (loadShopConfig(shop_id) and loadShopConfig(shop_id).is_show == 1) then --and loadShopConfig(shop_id) ~= nil
						if shop_id == 32  then --or shop_id == 33
							--openShop[shop_id] = {Shop_id = shop_id, Name = "限时商店"}
							DispatchEvent("MANOR_SHOP_OPEN",{end_time = Time.now() + (_data[4] - delta%_data[3]), begin_time = (Time.now() - delta%_data[3])});
						end
						openShop[shop_id] = loadShopConfig(shop_id);
						--print(shop_id.."商店开启",sprinttb(openShop))
						openShop[shop_id].shopTime_left = data[3];
						DispatchEvent("OPEN_SHOP_INFO_RETURN",shop_id);
						break;
					end
				else--商店未开启
					DispatchEvent("OPEN_SHOP_INFO_RETURN");
				end
			end
			if not data[3][shop_id] then--返回列表中未包含该商店信息
				DispatchEvent("OPEN_SHOP_INFO_RETURN");
			end
		end

		if shop_id == lastShopID then
			DispatchEvent("QUERY_SHOP_COMPLETE");
		end
	else
		print("商店查询失败shop_id".. shop_id,err);
	end
end)
--商店刷新
EventManager.getInstance():addListener("server_respond_15018", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	local canRefresh = data[4];
	local refreshCousume=data[6][1]--重置消耗配置
	local shop_id = SnArr[sn]
	SnArr[sn] = nil;
	if err == 0 then
		--print("商店刷新Succeed",sprinttb(data));
		DispatchEvent("SHOP_REFRESH_SUCCEED");
		if shop_id then
			Set(shop_id, data[5],canRefresh,data[3],refreshCousume);
			return;
		end
		DispatchEvent("SHOP_INFO_CHANGE",{id = shop_id, refresh = canRefresh,refreshCousume=refreshCousume});
	else
		print("商店刷新err",err);
	end
end)

--限时商店刷新提示
local flashSaleShopId = 1
local localFlashSaleShopCheckTime = nil
local function SetlocalFlashSaleShopCheckTime()
	localFlashSaleShopCheckTime = GetManager(flashSaleShopId) and GetManager(flashSaleShopId).next_fresh_time
end

local function GetFlashSaleShopStatus()
	if localFlashSaleShopCheckTime then
		local next_fresh_time = GetManager(flashSaleShopId) and GetManager(flashSaleShopId).next_fresh_time or 0
		return localFlashSaleShopCheckTime<next_fresh_time
	else
		SetlocalFlashSaleShopCheckTime()
		return false
	end
end

local exchangeList = nil
local function GetExchangeItemList(consumt_id)
	if exchangeList == nil then
		exchangeList = {}
		local list = GetManager(17) and GetManager(17).shoplist or {}
		for k,v in pairs(list) do
			exchangeList[v.consume_item_id1] = exchangeList[v.consume_item_id1] or {}
			table.insert(exchangeList[v.consume_item_id1],v)
		end
	end
	if consumt_id then
		return exchangeList[consumt_id]
	end
end

utils.EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, cmd, data)
    GetManager(1)
    GetManager(2)
    GetManager(3)
    GetManager(4)
    GetManager(5)
    GetManager(6)
    --GetManager(7)
    GetManager(8)
    GetManager(9)
    GetManager(10)
    GetManager(12)
    GetManager(13)
    GetManager(14)
    GetManager(15)
    GetManager(17)
    GetManager(99)
end)

local function GetNpcSouvenirShopList()
	--npc好感度商店
	GetManager(1001)
	GetManager(1002)
	GetManager(1003)
	GetManager(1004)
	GetManager(1005)
	--军团商店
	GetManager(4001)
end
local function GetNpcSouvenirShop(hero_item_id)
	--跟英雄好感度绑定的物品
	--ERROR_LOG(sprinttb(NpcSouvenirArr))
	return NpcSouvenirArr[hero_item_id]
end




return {
	GetManager = GetManager,
	Buy = BuyProduct,
	BuyTarget=BuyProductTarget,--时装兑换
	Refresh = RefreshShopList,
	Load = loadShopConfig,
	Query = queryShop,
	GetOpenShop = getOpenShop,
	QuerySpecialShop = querySpecialShop,
	GetNpcSouvenirShopList = GetNpcSouvenirShopList,
	GetNpcSouvenirShop = GetNpcSouvenirShop,

	GetPriceByNum = loadShoppingFloatPriceConfig,

	GetProductCfg = GetProductCfg,--通过product Gid 查询商品 cfg
	CheckProductLimit = CheckProductByUnionScienceLimit,

	SetlocalFlashSaleShopCheckTime = SetlocalFlashSaleShopCheckTime,
	GetFlashSaleShopStatus = GetFlashSaleShopStatus,

	GetExchangeItemList = GetExchangeItemList,
};
