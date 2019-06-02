local traditionalArenaModule = require "module.traditionalArenaModule"
local ShopModule = require "module.ShopModule"
local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view =  self.root.view.Content;
	self:InitView();
end

local function GetTotalConsume(cfg,num)
	local totalConsume = 0
	local _floatPriceTab = ShopModule.GetPriceByNum(cfg.gid)
	if _floatPriceTab then
		for i=1,num do
			local _price = _floatPriceTab[cfg.buy_count+i].sellPrice
			totalConsume = totalConsume+_price
		end
	else
		totalConsume = cfg.consume_item_value1*num
	end
	return totalConsume
end

local challengeItemId = 90169
local shopId = 8
function View:InitView()
	self.root.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue("chuantongjjc_12")

	self.view.static_Tip_Text[UI.Text].text = SGK.Localize:getInstance():getValue("chuantongjjc_14")
	
	self.view.btns.addOneBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("chuantongjjc_13",1)
	
	
	CS.UGUIClickEventListener.Get(self.root.view.closeBtn.gameObject).onClick = function()
		DialogStack.Pop();
	end

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function()
		DialogStack.Pop();
	end

	local product = ShopModule.GetManager(shopId,challengeItemId) and ShopModule.GetManager(shopId,challengeItemId)[1];
	if product then
		local consumeType = product.consume_item_type1
		local consumeId = product.consume_item_id1
		local consumePrice = product.consume_item_value1
		local targetGid = product.gid

		local productType = product.product_item_type
		local ownCount = module.ItemModule.GetItemCount(consumeId)
		local productCfg = utils.ItemHelper.Get(productType,challengeItemId)
		local consumeCfg = utils.ItemHelper.Get(consumeType,consumeId)
		if consumeCfg then
			self.view.btns.addOneBtn.consume_Icon[UI.Image]:LoadSprite("icon/" ..consumeCfg.icon.."_small")
			self.view.btns.addFiveBtn.consume_Icon[UI.Image]:LoadSprite("icon/" ..consumeCfg.icon.."_small")
		end
		local leaveCount = product.storage-product.buy_count
		local priceOne = GetTotalConsume(product,1)
		local priceFive = GetTotalConsume(product,leaveCount)

		
		self.view.leaveText[UI.Text].text = SGK.Localize:getInstance():getValue("chuantongjjc_15",leaveCount)

		self.view.btns.addOneBtn.consume_Value[UI.Text].text = priceOne
		self.view.btns.addOneBtn[CS.UGUIClickEventListener].interactable = ownCount>=priceOne and leaveCount>0
		CS.UGUIClickEventListener.Get(self.view.btns.addOneBtn.gameObject).onClick = function()
			self.view.btns.addOneBtn[CS.UGUIClickEventListener].interactable = false
			ShopModule.Buy(shopId,targetGid,1)
			self.product_item_gid = targetGid
		end

		self.view.btns.addFiveBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("chuantongjjc_13",leaveCount)
		self.view.btns.addFiveBtn.consume_Value[UI.Text].text = priceFive
		self.view.btns.addFiveBtn:SetActive(leaveCount>0)
		self.view.btns.addFiveBtn[CS.UGUIClickEventListener].interactable = ownCount>=priceFive
		CS.UGUIClickEventListener.Get(self.view.btns.addFiveBtn.gameObject).onClick = function()
			self.view.btns.addFiveBtn[CS.UGUIClickEventListener].interactable = false
			ShopModule.Buy(shopId,targetGid,leaveCount)
			self.product_item_gid = targetGid
		end
	else
		ERROR_LOG("product is nil")
	end
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
	"SHOP_BUY_SUCCEED",
	"SHOP_BUY_FAILED",
	}
end

function View:onEvent(event,data)
	if event == "SHOP_BUY_SUCCEED"  then
		if data.gid == self.product_item_gid then
			showDlgError(nil,"购买成功")
			DialogStack.Pop();
		end
	elseif event == "SHOP_BUY_FAILED" then
		ERROR_LOG("购买失败") 
		DialogStack.Pop();
	end
end

return View;