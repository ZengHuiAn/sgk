local TAG = "GuildFishShop"

local ShopModule = require "module.ShopModule"
local ItemHelper = require 'utils.ItemHelper'
local ItemModule = require "module.ItemModule"

local view = {}

local shopCfg = {
	[2344001] = 4006,
	[2344002] = 4007,
	[2344003] = 4008,
}

function view:Start(data)

	self.view = CS.SGK.UIReference.Setup(self.gameObject)

	self.shopType = shopCfg[tonumber(data)];
	CS.UGUIClickEventListener.Get(self.view.Dialog.Close.gameObject).onClick = function (obj)
		DialogStack.Destroy("GuildFishShop");
	end

	self.UIDragIconScript = self.view.Dialog.bg.ScrollView[CS.UIMultiScroller]
	self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		local data = self.m_data[idx+1];
		if not data then return end

		obj:SetActive(true);

		local item = SGK.UIReference.Setup(obj);
		local info = ItemHelper.Get(41, data.product_item_id);

		-- print("道具",sprinttb(info));
		item.title.Text[UI.Text].text = tostring(info.name);
		print(data.product_item_value);
		local cfg = {
			id 			= data.product_item_id,
			count 		= data.product_item_value,
		}

		utils.IconFrameHelper.Create(item.bg.item, {customCfg = info,showDetail = true,count = data.product_item_value,});

		local flag = true;
		local v1 = ItemModule.GetItemCount(data.consume_item_id1);
		local cache1 = {
			id 			= data.consume_item_id1,
			count 		= v1,
			limitCount  = data.consume_item_value1,
		}

		if v1 < data.consume_item_value1 then
			flag = false;
		end

		local cfg1 =ItemHelper.Get(41, cache1.id);


		utils.IconFrameHelper.Create(item.bg.cost.item1, {type = cfg1.type, id = cfg1.id,showDetail = true,count = 0,func = function ( prefab )
			 local _item = SGK.UIReference.Setup(prefab);
			-- _item.LowerRightText[UI.Text].color = flag == true and UnityEngine.Color.green or UnityEngine.Color.red;
			if v1<cache1.limitCount then
				item.bg.cost.count1[UI.Text].text="<color=#FFC300FF>"..v1.."/"..cache1.limitCount.."</color>"
			else
				item.bg.cost.count1[UI.Text].text="<color=#FFFFFFFF>"..v1.."/"..cache1.limitCount.."</color>"
			end
		end});

		if data.consume_item_id2 and data.consume_item_id2 ~= 0 then
			item.bg.cost.item2.gameObject:SetActive(true);
			local v2 = ItemModule.GetItemCount(data.consume_item_id2);
			local cache2 = {
				id 			= data.consume_item_id2,
				count 		= v2,
				limitCount  = data.consume_item_value2,
			}
			if v2 < data.consume_item_value2 then
				flag = false;
			end
			local cfg1 =ItemHelper.Get(41, cache2.id);
			utils.IconFrameHelper.Create(item.bg.cost.item2, {type = cfg1.type, id = cfg1.id,showDetail = true,count = 0,func = function ( prefab )
				-- local _item = SGK.UIReference.Setup(prefab);
				-- _item.LowerRightText[UI.Text].color = flag == true and UnityEngine.Color.green or UnityEngine.Color.red;
				if v2<cache2.limitCount then
					item.bg.cost.count2[UI.Text].text="<color=#FFC300FF>"..v2.."/"..cache2.limitCount.."</color>"
				else
					item.bg.cost.count2[UI.Text].text="<color=#FFFFFFFF>"..v2.."/"..cache2.limitCount.."</color>"
				end
			end});
		else
			item.bg.cost.item2.gameObject:SetActive(false);
		end

		if flag then
			CS.UGUIClickEventListener.Get(item.btn.gameObject).interactable = true
			-- item.btn[UI.Button].interactable = true
			item.btn[CS.UGUISpriteSelector].index = 0;
		else
			CS.UGUIClickEventListener.Get(item.btn.gameObject).interactable = false
			-- item.btn[UI.Button].interactable = false

			item.btn[CS.UGUISpriteSelector].index = 1
		end

		CS.UGUIClickEventListener.Get(item.btn.gameObject).onClick = function (obj)
			if flag then
				ShopModule.Buy(self.shopType, data.gid, 1);
			end
		end
	end)

	self:getScrollData();
end

function view:Update()
end

function view:OnDestroy()
end

function view:listEvent()
	return {"SHOP_BUY_SUCCEED", "SHOP_INFO_CHANGE",}
end

function view:onEvent(event, ...)
	if event == "SHOP_BUY_SUCCEED" then
		DispatchEvent("showDlgError", {nil, "兑换成功"})
		self:getScrollData()
	end
	if event == "SHOP_INFO_CHANGE" then
		self:getScrollData();
	end
end

function view:getScrollData()

	local list = ShopModule.GetManager(self.shopType)
	-- print(sprinttb(list))
	if not list.shoplist then
		return;
	end
	-- print(sprinttb(list.shoplist))
	self.m_data = {};
	local cacheList = {}
	for k,v in pairs(list.shoplist) do
		local flag = true
		local v1 = ItemModule.GetItemCount(v.consume_item_id1);
		if v1 < v.consume_item_value1 then
			flag = false;
		end

		if v.consume_item_id2 and v.consume_item_id2 ~= 0 then
			local v2 = ItemModule.GetItemCount(v.consume_item_id2);
			if v2 < v.consume_item_value2 then
				flag = false;
			end
		end
		if flag then
			table.insert(self.m_data, v)
		else
			table.insert(cacheList, v)
		end
	end
	
	for k,v in pairs(cacheList) do
		table.insert(self.m_data, v)
	end

	table.sort( self.m_data, function (a,b)
		if a.gid < b.gid then
			return true;
		end
	end )
	-- print("道具信息",sprinttb(self.m_data));
	self.UIDragIconScript.DataCount=#self.m_data
	self.UIDragIconScript:ItemRef()	
end

return view