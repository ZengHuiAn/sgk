local ShopModule = require "module.ShopModule";
local ItemHelper = require "utils.ItemHelper";
local ItemModule = require "module.ItemModule"
local easyBuyFrame = {}
function easyBuyFrame:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Info=self.view.BuyInfo
    self:initData(data)
    
    CS.UGUIClickEventListener.Get(self.Info.buyBtn.gameObject).onClick = function()
        self:InBuying(self.ItemBuyInfo,self.item)
    end
    CS.UGUIClickEventListener.Get(self.view.exitBtn.gameObject).onClick = function()
        CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject,true).onClick = function()
        CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
    end
end

function easyBuyFrame:initData(data)
	self.compose_shop_id=2
	self.item=ItemHelper.Get(data.type,data.id)
	self.ItemBuyInfo=self:IsInComposeShop(self.item)
	
	if next(ShopModule.GetManager(self.compose_shop_id))~=nil  then
		if self.ItemBuyInfo and next(self.ItemBuyInfo)~=nil then
			self:initUi()
		else
			showDlgError(nil,"商品已停售");
			CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
		end
	end
end

function easyBuyFrame:initUi()
	if self.ItemBuyInfo and next(self.ItemBuyInfo )~=nil then
		self.Info.gameObject:SetActive(true)
			self.Info.top.tip[UI.Text]:TextFormat("<color=#FE0000FF>{0}</color> 不足,你可以便捷购买",self.item.name)
		self.Info.top.name[UI.Text].text=self.item.name

		utils.IconFrameHelper.Item(self.item, self.Info.top.newItemIcon)

		self.Info.top.use[UI.Text]:TextFormat("用途:{0}",self.item.info)

		local product_item_id=self.ItemBuyInfo.consume_item_id1
		local product_item_type=self.ItemBuyInfo.consume_item_type1
		self.product_item_Cfg=ItemHelper.Get(product_item_type,product_item_id)

		self.Info.buyNum.title[UI.Text]:TextFormat("购买数量:")
		self.BuyNum=self.ItemBuyInfo.product_item_value
		self:refBuyNum()
		CS.UGUIClickEventListener.Get(self.Info.buyNum.Sub.gameObject).onClick = function()	
			self.BuyNum=self.BuyNum>=self.ItemBuyInfo.product_item_value and self.BuyNum-self.ItemBuyInfo.product_item_value or 0
			self:refBuyNum()
		end
		CS.UGUIClickEventListener.Get(self.Info.buyNum.Add.gameObject).onClick = function()
			self.BuyNum=self.BuyNum+self.ItemBuyInfo.product_item_value
			self:refBuyNum()
		end

		self.Info.sumConsume.title[UI.Text]:TextFormat("购买总价:")
		self.Info.sumConsume.Icon[UI.Image]:LoadSprite("icon/".. self.product_item_Cfg.icon)

		self.Info.myConsume.title[UI.Text]:TextFormat("我的金币:")
		self.Info.myConsume.Icon[UI.Image]:LoadSprite("icon/".. self.product_item_Cfg.icon)
		self.Info.myConsume.num[UI.Text].text=tostring(self.product_item_Cfg.count)
	end
end

function easyBuyFrame:IsInComposeShop(selectedItem)
	if self.compose_shop_items == nil then
		local shopList = ShopModule.GetManager(self.compose_shop_id).shoplist; -- 兑换商店
		
		if not shopList then
			return nil;
		end
		self.compose_shop_items = {}
		for k, v in pairs(shopList or {}) do
			self.compose_shop_items[v.product_item_type] = self.compose_shop_items[v.product_item_type] or {}
			self.compose_shop_items[v.product_item_type][v.product_item_id] = v;
		end
	end
	local ct = self.compose_shop_items[selectedItem.type];
	return ct and ct[selectedItem.id] or nil;
end

function easyBuyFrame:refBuyNum()
	self.Info.buyNum.num[UI.Text].text=tostring(self.ItemBuyInfo.product_item_value*self.BuyNum)
	local Sumvalue=self.product_item_Cfg.count
	local ConsumeValue=self.ItemBuyInfo.consume_item_value1*self.BuyNum
    self.Info.sumConsume.num[UI.Text].text=string.format("%s%s</color>",Sumvalue>=ConsumeValue and "<color=#FFFFFFFF>" or "<color=#FE0000FF>",ConsumeValue)
end

function easyBuyFrame:InBuying(ItemInfo,item)
	if self.operate_obj == nil then
		local case1=self.product_item_Cfg.count>=ItemInfo.consume_item_value1*self.BuyNum 
		if case1 then
			ShopModule.Buy(self.compose_shop_id, ItemInfo.gid,self.BuyNum);
			CS.UnityEngine.GameObject.Destroy(self.view.gameObject)	
		else
			showDlgError(nil,"货币不足");
		end
	end
end

function easyBuyFrame:listEvent()
	return{
		"SHOP_INFO_CHANGE",
	}
end

function easyBuyFrame:onEvent(event,data)
	if event == "SHOP_INFO_CHANGE" then
		self.ItemBuyInfo=self:IsInComposeShop(self.item)
		if self.ItemBuyInfo and next(self.ItemBuyInfo)~=nil then
			self:initUi()
		else
			showDlgError(nil,"商品已停售");
			CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
		end
	end
end

return easyBuyFrame