local TAG = "城市争夺战 商店======snake"
local activityConfig = require "config.activityConfig"
local ShopModule = require "module.ShopModule"
local buildScienceConfig = require "config.buildScienceConfig"
local Time = require "module.Time"
local BuildShopModule = require "module.BuildShopModule"
local MapConfig = require "config.MapConfig"


local begin_time = 1531229400;
local function getTimeHMS(time)
    local H = math.floor(time /3600);
    time = math.fmod(time ,3600)
    local M = math.floor(time/60);
    time = math.fmod(time ,60)
    local S = time
    return H,M,S
end

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

local View = {};

function View:OnDestroy()
	DispatchEvent("CurrencyRef");
end

function View:Start(data)
	local _shopCfg=module.ShopModule.Load(21)

	for i=1,4 do
		DispatchEvent("CurrencyRef",{i,_shopCfg["top_resource_id"..i]})
	end
	-- ERROR_LOG(module.playerModule.Get().id)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)

	self.view = self.root.bg;
	self.top = self.view.topinfo;
	self.dropdown = self.view.bottom.bg.filter.Dropdown[UI.Dropdown];
	self.dropdownController = self.view.bottom.bg.filter.Dropdown[SGK.DropdownController];
	
	self.view.Center.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.currentTips then
			--todo
			self.currentTips:SetActive(false);
			self.currentTips = nil;
		end
		self.view.Center.mask:SetActive(false);
	end
	self.mapid = data;
	self.scroll = self.view.Center.ScrollView[CS.UIMultiScroller];
	self.scroll.enabled = false;

	self.scroll.RefreshIconCallback = function (obj, idx)
		obj.gameObject:SetActive(true);

		local item = SGK.UIReference.Setup(obj);
		local item_data = self.scrolldata[idx+1];
		self:FreshItem(item_data,item,idx);
	end
	self:FreshUI(self.mapid);
	-- self.next_fresh_time = Time.now();
	local time_t = date(Time.now())
	-- print("时间================",sprinttb(date(Time.now())))

	self.next_fresh_time = getTimeByDate(time_t.year,time_t.month,time_t.day+1,0,0,0);
	-- print("结束时间",Time.now(),end_time)
	-- self.next_fresh_time = Time.now() + ;
end

function View:Update( ... )

	if self.next_fresh_time then
		--todo
		local time = self.next_fresh_time - Time.now();

		if time >=0 then
			self.view.bottom.bg.time.timer[UI.Text].text = string.format("%02d:%02d:%02d",getTimeHMS(time ));

		else
			self.next_fresh_time = nil;
			local time_t = date(Time.now())
			-- print("时间================",sprinttb(date(Time.now())))

			self.next_fresh_time = getTimeByDate(time_t.year,time_t.month,time_t.day+1,0,0,0)

			BuildShopModule.QueryMapShopInfo(self.mapid,true);
		end
	end

	if self.next_query_time then
		local time = self.next_query_time - Time.now();	
		-- print(time);
		if time < 0 then
			-- print("重新查询数据");
			-- self.next_query_time = nil;
			BuildShopModule.QueryMapDepot(self.mapid,true);
			self.next_query_time = Time.now() + 60;
		end
	end
end

-- 1, 2, 3, 4, nil  _type
function View:PerkItemID( _type )

	local info = BuildShopModule.QueryMapShopInfo(self.mapid);
	if not info then
		return true ;
	end
	-- print("self.resource",sprinttb(self.resource))

	local itemid = _type and self.resource[_type].item_id or nil;
	self.scrolldata = {};
	-- -- print(sprinttb(info))
	-- print(sprinttb(itemid));
	
	for k,v in pairs(info) do

		if itemid and itemid == v.consume[2] then
			table.insert(self.scrolldata,v);
		end

		if not itemid then
			--特产
			table.insert(self.scrolldata,v);
		end
	end
	-- module.ItemModule.GetItemCount(v.limt_consume[2]);
	-- print("===========",specialty_max,noSpecialty_max);
	-- print("=================",sprinttb(self.scrolldata))
	self:FreshSpecialty();
	table.sort(self.scrolldata,function (a, b)
		return a.gid < b.gid;
	end);
	self.scroll.DataCount = #self.scrolldata;
	-- self.scroll:ItemRef();
	self.type = _type;
end

local product = {
	{ flag = 1,id = 3005,limit = 20 },
	{ flag = 0,id = 3006,limit = 20 },
}

function View:FreshSpecialty()

	local _count_t = module.ItemModule.GetItemCount(product[1].id);
	self.top.bg.exchangeContent_t.Text[UI.Text].text =   (_count_t ==0 and "<color=#ff0000>" or  "<color=#1a7d0f>").._count_t .."/"..product[1].limit.."</color>";
	local _count = module.ItemModule.GetItemCount(product[2].id);
	self.top.bg.exchangeContent_t.desc[UI.Text].text = "今日兑换特产商品"
	self.top.bg.exchangeContent.desc[UI.Text].text = "今日兑换普通商品"
	self.top.bg.exchangeContent.Text[UI.Text].text =  (_count ==0 and "<color=#ff0000>" or  "<color=#1a7d0f>").._count .."/"..product[2].limit.."</color>";
end

function View:FreshUI(mapid)
	local cfg = activityConfig.GetCityConfig(self.mapid);
	
	if not cfg then
		return;
	end
	self.depot = BuildShopModule.GetMapDepot(self.mapid);

	if not self.depot then
		BuildShopModule.QueryMapDepot(self.mapid,true);
	end
	self.resource =  buildScienceConfig.GetResourceConfig();
	-- ERROR_LOG(sprinttb(self.depot or {}))
	-- local info = BuildShopModule.QueryMapShopInfo(self.mapid);
	local info = BuildShopModule.QueryMapShopInfo(self.mapid);
	if not info then
		return;
	end
	
	-- print("===========",sprinttb(info))
	local ret = self:PerkItemID(self.type);
	if ret then
		return;
	end
	
	self.scroll.enabled = true;


	self:FreshEvent();
end

function View:FreshItem(data,item,idx)
	
	-- print(sprinttb(data));
	local consume = data.consume;
	utils.IconFrameHelper.Create(item.bg.consoume,{count = consume[3],id = consume[2],type = consume[1],showDetail = true});

	print("=========>>>",sprinttb(data))
	local reward = data.reward
	utils.IconFrameHelper.Create(item.bg.reward,{count = reward[3],id = reward[2],type = reward[1],showDetail = true});

	item.bg.flag:SetActive(data.specialty == 1);
	item.bg.flag[UI.Image]:SetNativeSize();
	item.bg[CS.UGUISpriteSelector].index = data.specialty == 1 and 0 or 1;
	if not self.depot then
		return
	end

	print(sprinttb(self.depot),reward[2])
	local lave = self.depot[reward[2]].value;

	-- print("剩余",reward[2],sprinttb(self.depot))
	if self.depot then
		item.bg.bg.Text[UI.Text].text = "剩余:"..lave;

		if lave <=0 then

			item.bg.convert[CS.UGUIClickEventListener].interactable = false;
		else
			item.bg.convert[CS.UGUIClickEventListener].interactable = true;
		end
	end


	-- print("道具数量",lave);
	local _count_t = module.ItemModule.GetItemCount(product[data.specialty == 1 and 1 or 2].id);

	local cfg = module.ItemModule.GetConfig(consume[2]);
	item.bg.convert[CS.UGUIClickEventListener].onClick = function ( ... )
			local self_consume_count = module.ItemModule.GetItemCount(consume[2]);
			if self_consume_count < consume[3] then
				showDlgError(nil,"兑换所需"..cfg.name.."不足!");
				return;
			end
			if lave <=0 then
				showDlgError(nil,"该物品已经卖光了");
				return;
			end
			if _count_t <=0 then
				showDlgError(nil,"今日限购次数已用尽");
				return;
			end

			BuildShopModule.BuyMapProduct(data.gid,nil,self.mapid,function ( err )
				if err == 0 then
					showDlgError(nil,"购买成功");
				end
			end);
		end

	item.bg.parity[CS.UGUIClickEventListener].onClick = function ( ... )
		item.bg.parity.tips:SetActive(not item.bg.parity.tips.gameObject.activeInHierarchy);

		print(not item.bg.parity.tips.gameObject.activeInHierarchy)
		if item.bg.parity.tips.gameObject.activeInHierarchy then
			self:FreshTips(data,item.bg.parity.tips,idx);
			self.view.Center.mask:SetActive(true);
			self.currentTips = item.bg.parity.tips.gameObject;
		else
			self.view.Center.mask:SetActive(false);
		end
	end

	
end

function View:FreshTips(data,view,_idx)
	self.isfrush = self.isfrush or {};
	if self.isfrush[_idx] then
		return;
	end
	local item = view.bg;

	local consume = module.ItemModule.GetConfig(data.consume[2]);
	local reward = module.ItemModule.GetConfig(data.reward[2]);


	item.title[UI.Text].text = consume.name.."  兑换  "..reward.name
	local allmap = activityConfig.GetCityConfig().map_id;
	local temp_data = {}
	local index = 0;

	-- print("道具信息",sprinttb(data))

	local min_all = {};

	local min = nil; 
	for k,v in pairs(allmap) do
		index = index + 1;
		local content = item["content"..index];
		-- content.flag:SetActive(Shop_Product[data.gid] == i);
		local product = BuildShopModule.QueryMapProducInfo(v.map_id)

		-- print(data.reward[2])
		-- print(sprinttb(product),sprinttb(product[data.consume[2]],sprinttb(product[data.consume[2]])))
		if product and product[data.consume[2]] and product[data.consume[2]][data.reward[2]]  then
			content:SetActive(true);
			-- content.flag:SetActive(true);
			min = {idx = index,value = product[data.consume[2]][data.reward[2]].value};

			table.insert( min_all, min )
			-- print("==============",sprinttb(data))

			if v.map_id == self.mapid then
				-- print("地图ID相同")
				content.Text[UI.Text].color = UnityEngine.Color.yellow;
			else
				content.Text[UI.Text].color = UnityEngine.Color.white;
			end
			content.flag:SetActive(false);

			local info = MapConfig.GetMapConf(v.map_id);
			content.Text[UI.Text].text = "   "..info.map_name.."\t"..product[data.consume[2]][data.reward[2]].value.."兑1";
		else
			content:SetActive(false);
			content.flag:SetActive(false);
		end
	end
	table.sort( min_all, function ( a,b )
		return a.value < b.value;
	end )

	for k,v in pairs(min_all) do
		local content = item["content"..v.idx];
		
		if min_all[1].value == v.value then
			
			content.flag:SetActive(true);
		end
	end

	for k,v in pairs(min_all) do
		
	end
	self.isfrush[_idx] = true;

end

function View:FreshEvent()

	if not self.resource then
		return;
	end
	self.dropdown:ClearOptions();
	for i,v in ipairs(self.resource) do
		self.dropdownController:AddOpotion(v.name);
	end
	self.dropdownController:AddOpotion("全部");

	self.dropdown.value = self.num and self.num - 1  or #self.resource;
	self.dropdown:RefreshShownValue();
	self.dropdown.onValueChanged:AddListener(function ( num )
		self:FreshFilter(num+1,#self.resource);
	end);
	self.top.bg.helpBtn[CS.UGUIClickEventListener].onClick = function ()
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guanqiazhengduoshuoming01"))
	end
	local info = module.unionModule.Manage:GetSelfUnion();
	if not info then
		-- ERROR_LOG("你没有公会");
		return;
	end

	local scienceinfo = module.BuildScienceModule.GetScience(self.mapid);

	if not scienceinfo then
		return;
	end
	-- print(scienceinfo)
	-- print("++++++++++++p",scienceinfo.title,info.unionId)
	if info.unionId ~= scienceinfo.title then
		--自己公会不是所占领的公会
		print("-自己公会不是所占领的公会")
		self.top.bg.changePrice[UI.Button].interactable = false;
		self.top.bg.changePrice[CS.UGUIClickEventListener].onClick = function ()
			showDlgError(nil,SGK.Localize:getInstance():getValue("guanqiazhengduo38"))
		end

		return;
	else
		--自己不是工会长	
		if info.leaderId ~= module.playerModule.Get().id then
			print("自己不是工会长")	
			self.top.bg.changePrice[UI.Button].interactable = false;
			self.top.bg.changePrice[CS.UGUIClickEventListener].onClick = function ()
				showDlgError(nil,SGK.Localize:getInstance():getValue("guanqiazhengduo38"))
			end
			return;
		end
		
	end
	self.top.bg.changePrice[UI.Button].interactable = false;

	self.top.bg.changePrice[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.PushPrefStact("buildcity/buildShopPrice",self.mapid);
	end
end

--筛选
function View:FreshFilter( num,max )
	if num == max+1 then
		self:PerkItemID();
	else
		self:PerkItemID(num);
		self.num = num
	end
	self.isfrush = nil;
end
-- GetCityLvAndExp

function View:onEvent( event ,data )
	-- print("+++++++++++",event)
	if event == "MAP_SET_SHOPINFO_SUCCESS" then
		-- self.isfrush = nil;
		self:FreshUI(self.mapid);
	elseif event == "QUERY_MAP_SHOPINFO_SUCCESS" then
		if data == self.mapid then
			self.isfrush = nil;
			self:FreshUI(self.mapid);
		end
	elseif event == "LOCAL_SLESET_MAPID_CHANGE" then
		if data ~=self.mapid then
			self.mapid = data
			module.BuildScienceModule.QueryScience(self.mapid);
		else
			return;
		end
		self.isfrush = nil;
		self.type = nil
		self.num = nil;
		if self.currentTips then
			--todo
			self.currentTips:SetActive(false);
			self.currentTips = nil;
		end
		self.view.Center.mask:SetActive(false);
		self:FreshUI(data);
	elseif event == "MAP_SHOP_COUNT_INFOCHANGE" then
		if data == self.mapid then
			self.isfrush = nil;
			self:FreshUI(data);
		end
	elseif event == "MAP_SHOP_PRICE_INFOCHANGE" then
		if data == self.mapid then
			self.isfrush = nil;
			self:FreshUI(data);
		end
	elseif event =="QUERY_MAP_DEPOT" then
		if data == self.mapid then

			self.next_query_time = Time.now()+60;
			self:FreshUI(data);
		end
	end
end


function View:listEvent()
	return{
		-- "SHOP_INFO_CHANGE",
		-- "SHOP_BUY_SUCCEED",
		-- "BUILD_SHOP_PRICE",
		"MAP_SET_SHOPINFO_SUCCESS",
		"QUERY_MAP_SHOPINFO_SUCCESS",
		"LOCAL_SLESET_MAPID_CHANGE",
		"QUERY_MAP_DEPOT",
		--数量变更通知
		"MAP_SHOP_COUNT_INFOCHANGE",
		"MAP_SHOP_PRICE_INFOCHANGE",
	}
end


return View;