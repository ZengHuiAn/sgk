local ItemModule=require "module.ItemModule";
local ShopModule = require "module.ShopModule"
local ItemHelper = require "utils.ItemHelper"
local View={}

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view

	self.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_shenmibaoxiang_01")
	self.view.mid.Text[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_xuanzejiangli_01")
	self.view.tip[UI.Text].text = "<color=#A1650FFF>"..SGK.Localize:getInstance():getValue("biaoti_changanchakan_01").."</color>"

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj) 	
		UnityEngine.Object.Destroy(self.gameObject)
	end

	CS.UGUIClickEventListener.Get(self.view.Close.gameObject).onClick = function (obj) 	
		UnityEngine.Object.Destroy(self.gameObject)
	end

	self:InitView(data)
end

local pressTime = 0
local startPressTimer = false
local SelectTargetItem = nil
local PressItem = nil
function View:InitView(data)
	local id = data and data.id or 10000
	local type = data and data.type or ItemHelper.TYPE.ITEM

	local item = ItemHelper.Get(type,id)
	self.view.top.Text[UI.Text].text = string.format(item.info and string.gsub(item.info,"\n","") or "");
	self.view.getBtn[CS.UGUIClickEventListener].interactable = false

	local exchangeTab = ShopModule.GetExchangeItemList(id)
	if exchangeTab and next(exchangeTab) then
		for i=1,#exchangeTab do
			local exchangeItem = utils.SGKTools.GetCopyUIItem(self.view.mid.content,self.view.mid.content.item,i)
			utils.IconFrameHelper.Create(exchangeItem.IconFrame, {id = exchangeTab[i].product_item_id,type = exchangeTab[i].product_item_type,count = exchangeTab[i].product_item_value,showName=true})
		
			CS.UGUIPointerEventListener.Get(exchangeItem.gameObject,true).onPointerDown = function(go, pos)
				pressTime = 0
				startPressTimer = true

				PressItem = exchangeTab[i]
			end

			CS.UGUIClickEventListener.Get(exchangeItem.gameObject).onClick = function (obj) 
				startPressTimer = false 
				if pressTime< 0.5 then
					if SelectTargetItem and SelectTargetItem.idx==i then
						exchangeItem.checkMark:SetActive(false)
						SelectTargetItem = nil
						self.view.getBtn[CS.UGUIClickEventListener].interactable = false
					else
						if SelectTargetItem and SelectTargetItem.idx~=i then
							local obj = self.view.mid.content.transform:GetChild(SelectTargetItem.idx-1).gameObject
							local lastSelectItem = CS.SGK.UIReference.Setup(obj)
							lastSelectItem.checkMark:SetActive(false)
						end
						exchangeItem.checkMark:SetActive(true)
						SelectTargetItem = {idx = i,product = exchangeTab[i]}	
						self.view.getBtn[CS.UGUIClickEventListener].interactable = true
					end
				end
			end
		end

		CS.UGUIClickEventListener.Get(self.view.getBtn.gameObject).onClick = function (obj) 	
			if SelectTargetItem and SelectTargetItem.product then
				self.view.getBtn[CS.UGUIClickEventListener].interactable = false
				self.currShop_id = SelectTargetItem.product.shop_id
				self.currGid = SelectTargetItem.product.gid
				ShopModule.Buy(SelectTargetItem.product.shop_id,SelectTargetItem.product.gid,SelectTargetItem.product.product_item_value)
			end
		end
	end
end

function View:Update()
	if startPressTimer then
		pressTime = pressTime + UnityEngine.Time.deltaTime
		if pressTime >= 0.5 and PressItem then
			startPressTimer = false
			DialogStack.PushPrefStact("ItemDetailFrame", {type = PressItem.product_item_type, id = PressItem.product_item_id})
			PressItem = nil
		end
	end
end

function View:listEvent()	
	return {
		"SHOP_BUY_SUCCEED",
		"SHOP_BUY_FAILED",
	}
end

function View:onEvent(event,data)
	if event == "SHOP_BUY_SUCCEED" or event == "SHOP_BUY_FAILED" then
		if self.currShop_id and data.shop_id and data.shop_id ==self.currShop_id and self.currGid and data.gid and data.gid == self.currGid then
			if utils.SGKTools.GameObject_null(self.gameObject) ~= true then
				UnityEngine.Object.Destroy(self.gameObject)
			end
		end
	end
end
return View