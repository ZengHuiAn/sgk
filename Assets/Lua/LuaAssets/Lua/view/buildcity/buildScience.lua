local QuestModule = require "module.QuestModule"
local BuildScienceModule = require "module.BuildScienceModule"
local View = {};
local ItemHelper = require "utils.ItemHelper"
local activityConfig = require "config.activityConfig"
local buildScienceConfig = require "config.buildScienceConfig"

local ScieneceCFG = {
	["gq_xiehui_01"] = 1;
	["gq_xiehui_02"] = 2;
	["gq_xiehui_03"] = 3;
	["gq_xiehui_04"] = 4;
	["gq_xiehui_05"] = 5;
	["gq_xiehui_06"] = 6;
	["gq_xiehui_07"] = 7;
}

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.bg;
	self.mapid = data; 

	local info = BuildScienceModule.QueryScience(self.mapid);

	-- print("====================","info")
	if info then
		self.science = info;
		self.title = info.title;
		self:FreshAll();
	end
end

function View:FreshAll(  )
	self:FreshTop();
	self:FreshScrollView();
	self:FreshUnion();
	self:FreshQuiaty();
	self:FreshResources()
end

local function GetCopyUIItem(parent,prefab,i)
    local obj = nil
    if i <= parent.transform.childCount then
        obj = parent.transform:GetChild(i-1).gameObject
    else
        obj = CS.UnityEngine.GameObject.Instantiate(prefab.gameObject,parent.transform)
        obj.transform.localPosition = Vector3.zero
    end
    obj:SetActive(true)
    local item = CS.SGK.UIReference.Setup(obj)
    return item
end

function View:FreshResources( status )
	local cityDepotResource = module.BuildShopModule.GetMapDepot(self.mapid)
	-- ERROR_LOG("=======查询资源",sprinttb(cityDepotResource));
	if cityDepotResource and not status then
		self:InResourcesShow(cityDepotResource)
	else
		module.BuildShopModule.QueryMapDepot(self.mapid,true)
	end
end

function View:InResourcesShow(cityDepotResource)
	if cityDepotResource then
		local resourcesTab = buildScienceConfig.GetResourceConfig();
		for i=1,self.view.resources.content.transform.childCount do
			self.view.resources.content.transform:GetChild(i-1).gameObject:SetActive(false)
		end
		for i=1,#resourcesTab do
			local item = GetCopyUIItem(self.view.resources.content,self.view.resources.content[1],i)
			local id = resourcesTab[i].item_id
			local cfg = ItemHelper.Get(ItemHelper.TYPE.ITEM,id)
		
			item.Image[UI.Image]:LoadSprite("icon/"..cfg.icon.."_small")

			item.Text[UI.Text].text = cityDepotResource[id] and cityDepotResource[id].value or 0

			CS.UGUIClickEventListener.Get(item.Image.gameObject,true).onClick = function (obj)	
				DialogStack.PushPrefStact("ItemDetailFrame", {id = resourcesTab[i].item_id,type = ItemHelper.TYPE.ITEM})
			end

			CS.UGUIClickEventListener.Get(self.view.resources.TipBtn.gameObject).onClick = function (obj)
				utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guanqiazhengduo40"),nil,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject)
			end
		end

		self.view.resources.btn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guild_techDonate_btn")
		CS.UGUIClickEventListener.Get(self.view.resources.btn.gameObject,true).onClick = function (obj)	
			DialogStack.PushPrefStact("buildCity/donateResources",{self.mapid,cityDepotResource});
		end
	end
end

function View:FreshUnion()
	coroutine.resume( coroutine.create( function ( ... )
		ERROR_LOG(self.title);
		if self.title == 0 then
			self.view.topinfo.baseInfo.unionName.Text[UI.Text].text = SGK.Localize:getInstance():getValue("chengshitongzhi_"..self.cfg.type)
			return;
		end
		-- GetSelfUnion
		local unionInfo = module.unionModule.Manage:GetUnion(self.title)

		-- print("刷新公会",sprinttb(unionInfo))
		if unionInfo and next(unionInfo) then
			self.view.topinfo.baseInfo.unionName.Text[UI.Text].text = unionInfo.unionName or ""
		else
			BuildScienceModule.QueryScience(self.mapid,nil,true)
			self.view.topinfo.baseInfo.unionName.Text[UI.Text].text = SGK.Localize:getInstance():getValue("chengshitongzhi_"..self.cfg.type)
			-- ERROR_LOG("union is nil,id")
		end
	end ) )
end


function View:FreshQuiaty()
	self.view.topinfo.changePoint[CS.UGUISpriteSelector].index = self.cfg.city_quality - 1;

	self.view.topinfo.changePoint.ClickTip.Text[UI.Text].text = SGK.Localize:getInstance():getValue("daditu_0"..self.cfg.city_quality);
	local listener = CS.UGUIPointerEventListener.Get(self.view.topinfo.changePoint.gameObject);
	if listener.isLongPress ~= nil then
		listener.isLongPress = true;
	end
	listener.onPointerDown = function(go, pos)
		if not self.view.topinfo.changePoint.ClickTip.activeSelf then
			self.view.topinfo.changePoint.ClickTip:SetActive(true)
			self.view.topinfo.changePoint.transform:DOScale(Vector3.one,0.1):OnComplete(function ( ... )
				self.view.topinfo.changePoint.ClickTip[UnityEngine.CanvasGroup].alpha = 1;
    		end)
		end
	end

	listener.onPointerUp = function(go, pos)
		self.view.topinfo.changePoint.ClickTip[UnityEngine.CanvasGroup].alpha = 0;
		self.view.topinfo.changePoint.ClickTip:SetActive(false)
	end
end

function View:FreshTop()
	self.info = QuestModule.CityContuctInfo()
	
	self.cfg = activityConfig.GetCityConfig(self.mapid)
	
	if not self.info or not self.info.boss or not next(self.info.boss)  then

		-- print("信息不足",sprinttb(self.info));
		return;
	end

	-- print("=====刷新繁荣度======",sprinttb(self.info),sprinttb(self.cfg));
	local lastLv,exp,_value = activityConfig.GetCityLvAndExp(self.info,self.cfg.type);

	-- GetCityLvAndExp
	-- print("城市等级",lastLv,exp,_value);

	self.lastLv = lastLv;
	if self.lastLv then
		--todo
		self.view.topinfo.baseInfo.Slider.Text[UI.Text].text =exp.."/".._value;
		self.view.topinfo.baseInfo.lv[UI.Text].text = self.lastLv;

		self.view.topinfo.baseInfo.Slider[UI.Slider].value = exp/_value;
	end
	
end


function View:Reload( ... )
	self.scroll:ItemRef();
end



function View:FreshScrollView()
	self.scroll = self.view.Center.ScrollView[CS.UIMultiScroller];

	local cfg = buildScienceConfig.GetConfig(self.mapid);

	self.scroll.RefreshIconCallback = function (obj, idx)
		obj.gameObject:SetActive(true);
		if self.science and self.science.data then
			local item = CS.SGK.UIReference.Setup(obj)
			self:FreshItemScience(item,cfg[idx+1]);
		end

	end

	self.scroll.DataCount = #cfg;
end

function View:ItemGray( item )
	
end


function View:FreshItemScience(item,data)
	item.Image.flag.Text[UI.Text].text = data.name
	item.Image.Text[UI.Text].text = data.describe
	-- ERROR_LOG("======",sprinttb(data));
	local guild_cfg = buildScienceConfig.GetScienceConfig(data.map_id,data.technology_type);
	-- print("======",sprinttb(guild_cfg));

	item.Image.bg.icon[CS.UGUISpriteSelector].index = ScieneceCFG[data.picture];
	-- print("++++",data.technology_type,sprinttb(self.science.data))
	local science = self.science.data[data.technology_type];
	--解锁等级 
	local lockLev = guild_cfg[1].city_level;

	item.Image.level.Text[UI.Text].text = "^"..science;

	
	if not self.lastLv or science ==0 then
		item.Image.bg.icon[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
		item.Image.Text[UI.Text].text =SGK.Localize:getInstance():getValue( "guanqiazhengduo37",lockLev )
		item.Image.level:SetActive(false);
		item.Image[CS.UGUIClickEventListener].onClick = function ()
			DialogStack.PushPrefStact("buildcity/buildScienceInfo",{level = self.lastLv,map_id = self.mapid,type = data.technology_type});
		end
		
	else
		item.Image.level:SetActive(true);
		item.Image.bg.icon[UI.Image].material = nil
		
		item.Image[CS.UGUIClickEventListener].onClick = function ()

			DialogStack.PushPrefStact("buildcity/buildScienceInfo",{level = self.lastLv,map_id = self.mapid,type = data.technology_type});
		end
	end
	
	
end


function View:onEvent( event,data )
	if event == "LOCAL_SLESET_MAPID_CHANGE" then
		self.mapid = data; 
		self:FreshResources()
		local _data = BuildScienceModule.QueryScience(self.mapid,function ( _value )
			local info = BuildScienceModule.GetScience(self.mapid);

			self.science = info;
			self.title = info.title;
			self:FreshAll();
		end);
	elseif event == "CITY_CONTRUCT_INFO_CHANGE" then
		self:FreshTop();
		self:FreshScrollView();
	elseif event == "RELOAD_SCIENCE" then
		self:Reload();
	elseif event == "QUERY_SCIENCE_SUCCESS" then
		-- print("查到科技信息","=================")
		if data == self.mapid then
			local info = BuildScienceModule.GetScience(self.mapid);

			self.science = info;
			self.title = info.title;
			self:FreshAll();
		end
	elseif event == "UPGRADE_SUCCESS" then
		if data == self.mapid then
			local info = BuildScienceModule.GetScience(self.mapid);

			self.science = info;
			--公会
			self.title = info.title;
			self:FreshAll();
			self:FreshResources(true)
		end
	elseif event == "QUERY_MAP_DEPOT" then
		self:FreshResources()
	end
end


function View:listEvent()
	return{
		"LOCAL_SLESET_MAPID_CHANGE",

		"CITY_CONTRUCT_INFO_CHANGE",
		"QUERY_MAP_DEPOT",
		"RELOAD_SCIENCE",
		"QUERY_SCIENCE_SUCCESS",
		"UPGRADE_SUCCESS",
		-- GetScience
	}
end


return View;