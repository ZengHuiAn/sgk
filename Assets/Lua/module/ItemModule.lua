local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local PlayerModule = require "module.playerModule";

local item_config = nil
local function GetItemConfig (id)
	if item_config == nil then
		item_config = LoadDatabaseWithKey("item", "id");
	end
	if not item_config[id] then
		--ERROR_LOG("item config " .. id .. " not exists");
	end

	return item_config[id];
end

local item_source = nil
local function loadSourceConfig()
	if item_source == nil then
		item_source={}
		DATABASE.ForEach("item_from", function(data)
			if item_source[data.item_id] == nil then
				item_source[data.item_id] = {};
			end

			local _tab=setmetatable({
										sub_from = tonumber(data.sub_from),
										GetType = tonumber(data.type),
										openlevel = tonumber(data.openlevel),
										name = data.from_name,
										id = data.item_id,
									},{__index=data}
									)
			table.insert(item_source[data.item_id],_tab);
		end)
	end
end

local function GetItemSource(id)
	loadSourceConfig()
	return item_source[id];
end

local item_Type = nil

local itemBag_orderGroup=nil
local function loadTypeConfig()
	if item_Type == nil then
		item_Type={}
		local _itemBag_orderGroup={}
		itemBag_orderGroup={}

		local data_list = {};

		DATABASE.ForEach("item_type", function(data)
			table.insert(data_list, data);

			item_Type[data.type] =item_Type[data.type] or {};
			item_Type[data.type][data.sub_type] =item_Type[data.type][data.sub_type] or {};
			
			item_Type[data.type][data.sub_type] = data
			if data.pack_order~=0 then
				if _itemBag_orderGroup[data.pack_order]==nil then
					_itemBag_orderGroup[data.pack_order]={}
					itemBag_orderGroup[data.pack_order]={}
					itemBag_orderGroup[data.pack_order].sub_type={}
				end
				if _itemBag_orderGroup[data.pack_order][data.sub_pack]==nil then
					_itemBag_orderGroup[data.pack_order][data.sub_pack]=true
					table.insert(itemBag_orderGroup[data.pack_order],data.sub_pack)
					itemBag_orderGroup[data.pack_order].name=data.pack_name
					itemBag_orderGroup[data.pack_order].pack_order=data.pack_order
				end
				table.insert(itemBag_orderGroup[data.pack_order].sub_type,data.sub_type)
				itemBag_orderGroup[data.pack_order].type=data.type
			end
		end)
		return data_list;
	end
end

local typeConfig=nil
local function GetItemTypeCfg()
	if typeConfig ==nil then
		typeConfig=loadTypeConfig()
	end
	return typeConfig
end

local function GetItemType(type,sub_type)
	if typeConfig == nil then
		GetItemTypeCfg()
	end
	--local _subType=sub_type and sub_type or 0
	if sub_type then
		return item_Type[type] and item_Type[type][sub_type]
	else
		return item_Type[type]
	end	
end

local function GetItemBagOrder(orderIdx)
	if typeConfig == nil then
		GetItemTypeCfg()
	end
	return itemBag_orderGroup[orderIdx] or itemBag_orderGroup
end

local giftBagConfig = nil
local function loadGiftBagConfig()
	if giftBagConfig == nil then
		giftBagConfig={}
		local data_list = {};
		
		DATABASE.ForEach("gift_bag", function(data)
			table.insert(data_list, data);
            giftBagConfig[data.gid] =giftBagConfig[data.gid] or {};
            giftBagConfig[data.gid].consume= giftBagConfig[data.gid].consume or {}
            giftBagConfig[data.gid].giftItem= giftBagConfig[data.gid].giftItem or {}
			
            local _tab={}
			_tab.id=data.item_id
			_tab.Count=data.item_value
			_tab.type = data.item_type

			if data.is_consume~=0 then
				table.insert(giftBagConfig[data.gid].consume,_tab)
			else
				table.insert(giftBagConfig[data.gid].giftItem,_tab)
			end
		end)
		return data_list;
	end
end

local function GetGiftBagConfig(gid)
	if giftBagConfig == nil then
		loadGiftBagConfig()
	end
	return giftBagConfig[gid] or {};
end

local showItemCfg=nil
local showItemsList=nil
local function GetShowItemConfig(id,sub_type)
	if showItemCfg == nil then
		showItemCfg={}
		showItemsList={}
		DATABASE.ForEach("touxiangkuang_effect", function(data)
										--配置表里 type为subType
			local _tab=setmetatable({sub_type=data.type,type=41},{__index=data})
			showItemCfg[data.id]=_tab

			showItemsList[_tab.sub_type]=showItemsList[_tab.sub_type] or {}
			table.insert(showItemsList[_tab.sub_type],_tab)
		end)
    end
	if id then
		return showItemCfg[id]
	end
	if sub_type then
		return showItemsList[sub_type]
	end
end

local ItemBag = {};
function ItemBag:_init_(pid)
	local t = {};
	t.pid = pid;
	t.items = nil;
	return setmetatable(t, {__index=ItemBag});
end

function ItemBag:Set(gid, count, questUUId)
	gid = tonumber(gid);
	count = tonumber(count);
	if self.items then
		if not self.items[gid] then
			self.items[gid] = {gid = gid, id = gid, count = count, questUUId = questUUId};
		else
			self.items[gid].count = count;
		end
	end
end

-- 查询items
local sn2pid = {};
function ItemBag:queryItemList(pid)
	if self.items == nil then
		-- 向服务器请求items
		self.items = {};
		local sn = NetworkService.Send(165);
		sn2pid[sn] = pid;
	end
end

function ItemBag:Get(gid)
	if not gid then return end
	gid = tonumber(gid);
	self:queryItemList(self.pid);
	if self.items and self.items[gid] then
		return math.floor(self.items[gid].count);
	end
	return 0;
end

function ItemBag:GetQuestUUId(gid)
	if not gid then return end
	gid = tonumber(gid);
	self:queryItemList(self.pid);
	if self.items and self.items[gid] then
		return self.items[gid].questUUId;
	end
	return 0;
end

function ItemBag:RemoveQuest(gid)
    if not gid then return end
    gid = tonumber(gid);
    self:queryItemList(self.pid);
    if self.items and self.items[gid] then
        self.items[gid] = nil
    end
end

function ItemBag:List()
	self:queryItemList(self.pid);
	return self.items;
end

local managers = {};
local function getPlayerItems(pid)
	if not pid or pid == 0 then
		pid = PlayerModule.GetSelfID();
	end
	if not managers[pid] then
		managers[pid] = ItemBag:_init_(pid);
	end
	return managers[pid];
end

local function getItemList(pid)
	pid = pid or 0;
	local items = getPlayerItems(pid);
	return items:List();
end

local function getItemCount(gid, pid)
	pid = pid or 0;
	local items = getPlayerItems(pid);
	return items:Get(gid);
end

local function getQuestItemUUId(gid, pid)
    pid = pid or 0
    local items = getPlayerItems(pid)
    return items:GetQuestUUId(gid)
end

local function removeQuestItem(gid, pid)
    pid = pid or 0
    local items = getPlayerItems(pid)
    items:RemoveQuest(gid)
    DispatchEvent("ITEM_INFO_CHANGE")
end

-- 道具信息返回
EventManager.getInstance():addListener("server_respond_166", function(event, cmd, data)
	--ERROR_LOG("道具信息返回-----server_respond_166:",sprinttb(data),#data);
	local pid = sn2pid[data[1]] or 0;
	local items = getPlayerItems(pid);
	items.items = {};
	local n = #data;
	for idx = 3, n do
		local gid   = data[idx][1];
		local count = data[idx][2];
		items:Set(gid, count);
	end
	DispatchEvent("ITEM_INFO_CHANGE");
end);

--获取新道具
local tempToBagList={}

local item_grow_event = {};
local function upItemData(data, tip)
    -- print("道具信息推送-----server_notify_39:",sprinttb(data));
	local pid = nil or 0;
	local gid   = data[1];
	local count = data[2];
    local questUUId = data[3]
	local items = getPlayerItems(pid);
		
	if tip then
		if count > items:Get(gid) then
			--获取道具Tip
			table.insert(item_grow_event,{gid,count- items:Get(gid),utils.ItemHelper.TYPE.ITEM})
			DispatchEvent("ITEM_INFO_CHANGE", {gid = gid, count = count - items:Get(gid)});
		else
			if gid==100000 then--获取道具Tip只要有 100000这个道具就加入列表，忽略数量
				table.insert(item_grow_event,{gid,count- items:Get(gid),utils.ItemHelper.TYPE.ITEM})
			end
			DispatchEvent("ITEM_INFO_CHANGE");
		end
		--获取道具背包变化提示
		local _item=utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM,gid)
		if _item and _item.type_Cfg.pack_order then
			tempToBagList[_item.type_Cfg.pack_order]=tempToBagList[_item.type_Cfg.pack_order] or {}
			if count > items:Get(gid) then
				tempToBagList[_item.type_Cfg.pack_order][gid]=gid
			else
				tempToBagList[_item.type_Cfg.pack_order][gid]=nil
			end
			DispatchEvent("ITEM_INFO_CHANGE_BEFORE", _item.type_Cfg.pack_order);
		end
	end
	items:Set(gid, count, questUUId);
end

-- 新道具推送
EventManager.getInstance():addListener("server_notify_39", function(event, cmd, data)
    upItemData(data, true)
end);

EventManager.getInstance():addListener("server_notify_end", function( ... )
	if #item_grow_event > 0 then
		local _showGetItemTip=true
		-- if exist 100000
		for i=1,#item_grow_event do
			if item_grow_event[i][1]==100000 then
				_showGetItemTip=false
			end	
		end
		if _showGetItemTip then
			local npcConfig = require "config.npcConfig"

			for i=1,#item_grow_event do
				GetItemTips(item_grow_event[i][1],item_grow_event[i][2],item_grow_event[i][3])
				--获取道具聊天通知
				local itemconf = GetItemConfig(item_grow_event[i][1])
				if itemconf and itemconf.is_show == 1 then
					module.ChatModule.SystemChat(module.playerModule.Get().id,utils.ItemHelper.TYPE.ITEM,item_grow_event[i][1],math.floor(item_grow_event[i][2]))
				end

				local npc_cfg = npcConfig.GetItemRelyNpc(item_grow_event[i][1])
				if itemconf and itemconf.type == 90 and npc_cfg then
					local npc_List = module.HeroModule.GetConfig();
					showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_npc_tips_01",npc_List[npc_cfg.npc_id].name,"+"..math.floor(item_grow_event[i][2])),1)
				end
			end
		end
	end
	--引导用
	DispatchEvent("AFTER_ITEM_INFO_CHANGE",item_grow_event);
	
	item_grow_event = {};
end)

EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, pid)
	NetworkService.Send(165);
end);

local function sendOpenGiftBag(id,num)
	NetworkService.Send(15015, {nil,id,num})
end

EventManager.getInstance():addListener("server_respond_15016", function(event, cmd, data)
	local sn = data[1];
	local err = data[2];
	if err == 0 then
		DispatchEvent("GET_GIFT_ITEM",data[3]);
	else
		print("获取GIFT奖励err", err);
	end
end);


local giftItemList = {}
local giftItemSNTab = {}
---查询礼包中的道具
local function getGiftItem(id, func)
	local _tab = giftItemList[id]
	if _tab then
		func(_tab)
	else
		local _sn = NetworkService.Send(428, {nil, id})
		if not giftItemSNTab[_sn] then giftItemSNTab[_sn] = {} end
		giftItemSNTab[_sn].func = func
		giftItemSNTab[_sn].id = id
	end
end

EventManager.getInstance():addListener("server_respond_429", function(event, cmd, data)
	local sn = data[1]
	local err = data[2]
	if err == 0 then
		---类型 id 数量
		-- print("server_respond_429", sprinttb(data))
		if giftItemSNTab[sn] and giftItemSNTab[sn].id then
			giftItemList[giftItemSNTab[sn].id] = data[3]
			giftItemSNTab[sn].func(data[3])
			giftItemSNTab[sn] = nil
		end
	else
		print("server_respond_429 error", err)
	end
end)

local function GetTempToBagList(pack_order)
	return pack_order and tempToBagList[pack_order] or {} 
end

local function ClearTempToBagList(pack_order)
	tempToBagList[pack_order]={}
end


return {
	GetItemList = getItemList,
	GetItemCount = getItemCount,
	GetConfig = GetItemConfig,
	OpenGiftBag=sendOpenGiftBag,			--打开礼包
	GetGiftItem = getGiftItem,			--查询礼包
	GetItemSource = GetItemSource,			--查询物品来源
	GetItemType=GetItemType,
	GetGiftBagConfig=GetGiftBagConfig,
	GetItemBagOrder=GetItemBagOrder,
    UpItemData = upItemData,
    GetQuestItemUUId = getQuestItemUUId,
    RemoveQuestItem = removeQuestItem,
    GetItemTypeCfg = GetItemTypeCfg,

    GetShowItemCfg = GetShowItemConfig,--获取展示道具Cfg(头像框,对话框)

    GetTempToBagList = GetTempToBagList,	--新获得装备临时list
    ClearTempToBagList = ClearTempToBagList,
};
