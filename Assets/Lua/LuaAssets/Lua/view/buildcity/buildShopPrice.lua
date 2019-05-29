local TAG = "城市争夺战 修改价格======snake"
local activityConfig = require "config.activityConfig"

local buildScienceConfig = require "config.buildScienceConfig"
local ShopModule = require "module.ShopModule"
local Time = require "module.Time"

local View = {};
local BuildShopModule = require "module.BuildShopModule"


local function getTimeHMS(time)
    local H = math.floor(time /3600);
    time = math.fmod(time ,3600)
    local M = math.floor(time/60);
    time = math.fmod(time ,60)
    local S = time
    return H,M,S
end


function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)

	self.view = self.root.bg;
	self.scroll = self.view.Center.ScrollView[CS.UIMultiScroller];

	self.scroll.RefreshIconCallback = function (obj, idx)
		obj.gameObject:SetActive(true);
		local item = SGK.UIReference.Setup(obj);
		local item_data = self.scrolldata[idx+1];

		self:FreshItem(item_data,item);
	end
-- guanqiazhengduo34

	self.view.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo34");

	self.mapid = data;
	self:FrehData();


	self.view.recover[CS.UGUIClickEventListener].onClick = function ()
		 showDlgMsg("是否恢复所有商品的价格？", function ()
				local temp = {};
                for k,v in pairs(self.resetData) do
					print(k,sprinttb(v))
					local current = v.consume[3];

					local default = v.default_price;

					if math.floor( current ) ~= math.floor( default ) then
						table.insert( temp, {v.gid,default} )
					end
				end
				BuildShopModule.SetMapPrice(temp,self.mapid);
            end, function ()
            end, "确定", "取消", nil, nil)
		

		-- self:FrehData();
	end
	self.root.bg.closeBtn[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.Pop();
	end


	self.view.confirm[CS.UGUIClickEventListener].onClick = function ()

		-- self.data

		print(sprinttb(self.resetData))
		
		if not self.data or not next(self.data) then
			return;
		end

		print(sprinttb(self.data))

		local temp = {};
		for k,v in pairs(self.data) do
			-- print(k,v)
			if self.resetData[k] and math.floor( self.resetData[k].consume[3] ) ~= math.floor( v ) then
				table.insert( temp, {k ,math.floor( v )} )
			end
		end
		BuildShopModule.SetMapPrice(temp,self.mapid);

		self.data = {};
	end

	local scienceinfo = module.BuildScienceModule.GetScience(self.mapid);
	local info = module.unionModule.Manage:GetSelfUnion();
	if not scienceinfo then

		module.BuildScienceModule.QueryScience(self.mapid);
		return;
	end
	print(scienceinfo)
	print("++++++++++++p",scienceinfo.title,info.unionId)
	if info.unionId ~= scienceinfo.title then
		--自己公会不是所占领的公会
		print("-自己公会不是所占领的公会")
		self.view.recover[CS.UGUIClickEventListener].interactable = false;
		self.view.confirm[CS.UGUIClickEventListener].interactable = false;

		return;
	else
		--自己不是工会长	
		if info.leaderId ~= module.playerModule.Get().id then
			print("自己不是工会长")	
			self.view.recover[CS.UGUIClickEventListener].interactable = false;
			self.view.confirm[CS.UGUIClickEventListener].interactable = false;
			return;
		end
		
	end
	
	
end


function View:Update( ... )

	if self.next_fresh_time then
		--todo
		local time = self.next_fresh_time - Time.now();

		if time >=0 then
			self.view.topinfo.tips[UI.Text].text = "<color=green>"..string.format("%02d:%02d:%02d",getTimeHMS(time )).."</color>后\n".."可进行下一次调整" ;
		else
			self.next_fresh_time = nil;
			self.view.confirm[CS.UGUIClickEventListener].interactable = true;
			self.view.recover[CS.UGUIClickEventListener].interactable = true;
			self.view.topinfo.tips[UI.Text].text = "<color=green>"..string.format("%02d:%02d:%02d",0,0,0).."</color>后\n".."可进行下一次调整" ;
		end
	end
	

	
end

function View:FrehData( ... )
	local cfg = activityConfig.GetCityConfig(self.mapid);

	if not cfg then
		return;
	end
	self.shop = cfg.city_shop;
	local info = BuildShopModule.QueryMapShopInfo(self.mapid);

	-- self.next_fresh_time = info.next_fresh_time;
	print("===========",sprinttb(info));

	local time = BuildShopModule.GetFreshTime(self.mapid);

	if time == 0 or  Time.now() - time >3600*2 then
		print("当前可以调整",time);
		self.next_fresh_time = nil;
		self.view.topinfo.tips[UI.Text].text = "<color=green>"..string.format("%02d:%02d:%02d",0,0,0).."</color>后\n".."可进行下一次调整" ;
	else
		self.next_fresh_time = time + 3600*2;
	end

	if self.next_fresh_time then
		self.view.confirm[CS.UGUIClickEventListener].interactable = false;

		self.view.recover[CS.UGUIClickEventListener].interactable = false;
	else
		self.view.recover[CS.UGUIClickEventListener].interactable = true;
		self.view.confirm[CS.UGUIClickEventListener].interactable = true;
	end
	self.scrolldata = info or {};

	self.resetData = {};
	self.reward = {};
	for k,v in pairs(info) do

		self.reward[v.reward[2]] = { specialty = v.specialty };
		self.resetData[v.gid] = v;
	end
	-- self.resetData = self.scrolldata;
	table.sort(self.scrolldata,function (a, b)
		return a.gid < b.gid;
	end);
	-- print("#self.scrolldata",#self.scrolldata)
	self.scroll.DataCount = #self.scrolldata;

	self.depot = BuildShopModule.GetMapDepot(self.mapid);


	print("+++++++",sprinttb(self.reward))
	self:InitTitle();
end


function View:InitTitle(  )
	for k,v in pairs(self.reward) do
		if v.specialty == 1 then

			print(sprinttb(self.depot[k]))
			self.view.topinfo.content.content1.num[UI.Text].text = self.depot[k].value;
			local reward = module.ItemModule.GetConfig(k);
			self.view.topinfo.content.content1.icon[UI.Image]:LoadSprite("icon/" .. reward.icon.."_small");
		else
			self.view.topinfo.content.content2.num[UI.Text].text = self.depot[k].value;
			local reward = module.ItemModule.GetConfig(k);
			self.view.topinfo.content.content2.icon[UI.Image]:LoadSprite("icon/" .. reward.icon.."_small");
		end
	end
end
function View:FreshItem(data,item)
	utils.IconFrameHelper.Create(item.bg.consoume,{count = data.consume[3],id = data.consume[2],type = data.consume[1],showDetail = true});

	utils.IconFrameHelper.Create(item.bg.reward,{count = data.reward[3],id = data.reward[2],type = data.reward[1],showDetail = true,func = function (obj )
		if data.specialty == 1 then
			item.bg.reward.flag.gameObject.transform:SetAsLastSibling();
			item.bg[CS.UGUISpriteSelector].index = 0
		else
			item.bg[CS.UGUISpriteSelector].index = 1
		end
	end});
	item.bg.reward.flag:SetActive(data.specialty == 1);
	item.bg.reward.flag[UI.Image]:SetNativeSize();
	local dropdown = item.filter.Dropdown;
	local _data = buildScienceConfig.GetShopPriceConfig();

	self:FreshDropDown(dropdown,_data,data);
end

function View:FreshDropDown( dropdown,data,info )

	local _dropdown = dropdown[UI.Dropdown];

	local _dropdownController = dropdown[SGK.DropdownController];
	_dropdown:ClearOptions();
	-- self.dropdown:
	-- print("item=============",sprinttb(data))

	-- print("信息=============",sprinttb(info))
	local flag = 0;

	for i,v in ipairs(data) do

		-- print("倍率",v,math.floor( info.default_price))
		if info.consume[3] == math.floor( info.default_price * v ) then
			flag = i;
		end
		_dropdownController:AddOpotion(math.floor( info.default_price * v ) .."兑1");
	end
	-- print("当前价格",info.consume[3])
	_dropdown.value = flag - 1;
	_dropdown:RefreshShownValue();


	_dropdown.onValueChanged:AddListener(function ( num )

		self.data = self.data or {};
		self.data[info.gid] =  ( data[num + 1] *info.default_price );
		-- print("===========",sprinttb(self.data));
	end);
	-- dropdown.value = data.gid;
end

function View:FreshEvent()

end

function View:onEvent( event,data )
	
	if event == "MAP_SHOP_PRICE_INFOCHANGE" then
		if data == self.mapid then
			self:FrehData();
		end
	elseif event == "MAP_SET_SHOPINFO_SUCCESS" then
		showDlgError(nil,"修改成功");
		self:FrehData();
		-- self.data = {};
	end
end


function View:listEvent()
	return{
		"MAP_SHOP_PRICE_INFOCHANGE",
		"MAP_SET_SHOPINFO_SUCCESS",
	}
end


return View;