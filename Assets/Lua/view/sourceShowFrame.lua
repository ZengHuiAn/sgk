local ManorManufactureModule = require "module.ManorManufactureModule"
local ItemModule=require "module.ItemModule";
local MapHelper = require"utils.MapHelper"
local MapConfig = require "config.MapConfig"
local FightModule = require "module.fightModule"
local ShopModule = require "module.ShopModule"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local OpenLevel = require "config.openLevel"
local View={}

function View:Start()
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.viewY = self.view[UnityEngine.RectTransform].sizeDelta.y
end

function View:ShowSourceTitle(id,func,status)
	self.IsClose = status	
	self.func = func
	self.sourceCfg = ItemModule.GetItemSource(id)
	self.view.sourceTip.name[UI.Text]:TextFormat(self.sourceCfg and "获取途径" or string.format("获取途径%s(暂无)%s","<color=#FF1A1AFF>","</color>"))
	self.view.sourceTip.arrow.gameObject:SetActive(not not self.sourceCfg)
	
	self:ShowSourceItem()
end
---[[获取来源
local shopGoToFunction={}
function View:ShowSourceItem()
	for i=1,self.view.Viewport.Content.transform.childCount do
		self.view.Viewport.Content.transform:GetChild(i-1).gameObject:SetActive(false)
	end
	if not self.sourceCfg then return end
	if self.IsClose then
		self.view.sourceTip.arrow.gameObject.transform:DOLocalRotate(Vector3(0,0,-180),0.25)

		local _itemsizeY = self.view.sourceTipPrefab[UnityEngine.RectTransform].sizeDelta.y
		local _sizeY = _itemsizeY*#self.sourceCfg--(#self.sourceCfg<=2 and #self.sourceCfg or 2.5)
		local _hight = #self.sourceCfg<=3 and _sizeY or _itemsizeY*2.5
		local sizeY = self.viewY + _hight
		self.view[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,sizeY)
		self.IsClose=false

		self:updateSoureCfg()
	else
		self.view[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,42)
		self.view.sourceTip.arrow.gameObject.transform:DOLocalRotate(Vector3.zero,0.25)
		self.IsClose = true
	end
end

function View:updateSoureCfg()
	for i=1,self.view.Viewport.Content.transform.childCount do
		self.view.Viewport.Content.transform:GetChild(i-1).gameObject:SetActive(false)
	end
	for i=1,#self.sourceCfg do
		local item = utils.SGKTools.GetCopyUIItem(self.view.Viewport.Content,self.view.sourceTipPrefab,i)
		item.gameObject.name = tostring(self.sourceCfg[i].gid)

		item.go.gameObject:SetActive(self.sourceCfg[i].GetType~=2 and self.sourceCfg[i].GetType ~= 3)
		item.buyBtn:SetActive(false)

		if self.sourceCfg[i].GetType == 3 or utils.GuideHelper.Check(self.sourceCfg[i].from,self.sourceCfg[i].sub_from) then
			item.name[UI.Text].text = self.sourceCfg[i].name
		else
			local function GetNameDesc()
				local playerLevel = module.playerModule.Get().level;
				local _cfg = OpenLevel.GetCfg(self.sourceCfg[i].openlevel)
				local _desc = ""
				if _cfg then
					if playerLevel >= _cfg.open_lev then
						_desc = string.format("%s",self.sourceCfg[i].name)

						for j=1,1 do						
							if _cfg["event_type"..j] == 1 then
								if _cfg["event_id"..j] ~= 0 then
									local _quest = module.QuestModule.Get(_cfg["event_id"..j])
									if not _quest or _quest.status ~=1 then
										local _questCfg = module.QuestModule.GetCfg(_cfg["event_id"..j])
										if _questCfg then
											_desc = string.format("%s  <color=#FF1A1AFF>(需完成任务%s)</color>",self.sourceCfg[i].name,_questCfg.name)
										else
											ERROR_LOG("任务",_cfg["event_id"..j],"不存在")
										end
									end
								end
							end
						end
					else
						_desc = string.format("%s<color=#FF1A1AFF>(%s级)</color>",self.sourceCfg[i].name,_cfg.open_lev)
					end
				else
					_desc = v.name
					ERROR_LOG("openLevel cfg is nil",cfg.openlevel)
				end
				return _desc
			end

			local nameDesc = GetNameDesc()
			item.name[UI.Text].text = nameDesc
			if item.unOpen and self.sourceCfg.GetType ~= 3 then
				item.unOpen:SetActive(true)
				item.go:SetActive(false)
				item.buy:SetActive(false)
			end

		end
		self:InSourceShowItem(self.sourceCfg[i],item,i)

		local showTip = function ()
			if self.sourceCfg[i].from == 51 or self.sourceCfg[i].from == 52 or self.sourceCfg[i].from == 53 then
				local _fight_id = self.sourceCfg[i].sub_from
				if _fight_id and _fight_id ~= 0 then	
					local fightInfo = FightModule.GetFightInfo(tonumber(_fight_id))
					if fightInfo then
						if utils.GuideHelper.Check(self.sourceCfg[i].from,self.sourceCfg[i].sub_from) then
							local pveCfg = FightModule.GetConfig(nil, nil,tonumber(_fight_id))
							if pveCfg then--
								if pveCfg.count_per_day > fightInfo.today_count then--可挑战
									return string.format("剩余次数<color=#09852CFF>%s/%s</color>",pveCfg.count_per_day-fightInfo.today_count,pveCfg.count_per_day)
								else
									local product = ShopModule.GetManager(99, pveCfg.reset_consume_id) and ShopModule.GetManager(99, pveCfg.reset_consume_id)[1]
									if product then
										if product.product_count > 0 then--可重置
											return string.format("重置次数<color=#09852CFF>%s/%s</color>",product.product_count,product.storage)
										else
											return string.format("重置次数<color=#BC0000FF>0/%s</color>",product.storage)
										end
									else
										return string.format("剩余次数<color=#BC0000FF>0/%s</color>",0,pveCfg.count_per_day)
									end
								end
							end
						end
					else
						ERROR_LOG("fightInfo is nil,gid",tonumber(Cfg.sub_from))
					end
				end
			end
			return ""
		end

		if item.showTip then
			if self.sourceCfg[i].GetType ~= 3 and utils.GuideHelper.Check(self.sourceCfg[i].from,self.sourceCfg[i].sub_from) then
				item.showTip[UI.Text].text = showTip
			else
				item.showTip[UI.Text].text = showTip ~= "" and showTip or SGK.Localize:getInstance():getValue("renwuzhuanji_10")
			end
		end
	end
end

local shopItemGid = nil
function View:InSourceShowItem(cfg,item,Idx,status)
	if cfg.GetType == 3 then 
		return 
	end--类型3  不显示跳转

	if cfg.GetType ==2 then
		local _shopId = cfg.sub_from
		local _id = cfg.id
		local product = module.ShopModule.GetManager(_shopId,_id) and module.ShopModule.GetManager(_shopId,_id)[1];
		item.tip:SetActive(product)
		item.buyBtn:SetActive(product)

        if product then
     		local consumeType = product.consume_item_type1
			local consumeId = product.consume_item_id1
			local consumePrice = product.consume_item_value1
			local targetGid = product.gid

			local productType = product.product_item_type
			local ownCount = module.ItemModule.GetItemCount(consumeId)
			local productCfg = utils.ItemHelper.Get(productType,_id)
			local consumeCfg = utils.ItemHelper.Get(consumeType,consumeId)
			if consumeCfg then
				item.buyBtn.Image[UI.Image]:LoadSprite("icon/" ..consumeCfg.icon.."_small")
			end
			local function GetTotalPrice(num)
				local totalConsume = 0
				local _floatPriceTab = ShopModule.GetPriceByNum(product.gid)
				if _floatPriceTab then
					for i=1,num do
						local _price = _floatPriceTab[product.buy_count+i] and _floatPriceTab[product.buy_count+i].sellPrice or _floatPriceTab[product.buy_count+i-1].sellPrice
						totalConsume = totalConsume+_price
					end
				else
					totalConsume = product.consume_item_value1*num
				end
				return totalConsume
			end

			local price = GetTotalPrice(1)

			local leaveCount = product.storage-product.buy_count

			item.name[UI.Text]:TextFormat(cfg.name,product.product_item_value)
			item.tip[UI.Text].text = SGK.Localize:getInstance():getValue("chuantongjjc_15",leaveCount)
			item.buyBtn.Text[UI.Text].text = price

			CS.UGUIClickEventListener.Get(item.gameObject).onClick = function()
				if utils.GuideHelper.Check(cfg.from,cfg.sub_from) then
					if self.SelectIdx then
						local _obj = self.view.Viewport.Content.transform:GetChild(self.SelectIdx-1).gameObject
						local _item = CS.SGK.UIReference.Setup(_obj.gameObject)
						_item.mark.gameObject:SetActive(false)
					end
					self.SelectIdx = Idx
					item.mark.gameObject:SetActive(true)
					if leaveCount>=1 then
						if price<= ItemModule.GetItemCount(consumeId) then
							shopItemGid = targetGid
							item[CS.UGUIClickEventListener].interactable = false
							ShopModule.Buy(_shopId,targetGid,1)
						else
							showDlgError(nil,consumeCfg.name.."不足")
						end
					else
						showDlgError(nil, "商品今日已售罄")
					end
				else
					local condition = OpenLevel.GetCloseInfo(cfg.openlevel)
					showDlgError(nil,condition)
				end
			end

			local btnStatus = utils.GuideHelper.Check(cfg.from,cfg.sub_from)
			if leaveCount < 1 or  price > ItemModule.GetItemCount(consumeId) then
				btnStatus = false
			end

			item.buyBtn[CS.UGUISpriteSelector].index = btnStatus and 0 or 1;
    	else
    		ERROR_LOG("====product is nil")
        end
	else
		--item[CS.UGUIClickEventListener].interactable = true
		CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj) 
			if utils.GuideHelper.Check(cfg.from,cfg.sub_from) then
				if self.SelectIdx then
					local _obj = self.view.Viewport.Content.transform:GetChild(self.SelectIdx-1).gameObject
					local _item = CS.SGK.UIReference.Setup(_obj.gameObject)
					_item.mark.gameObject:SetActive(false)
				end
				self.SelectIdx = Idx
				item.mark.gameObject:SetActive(true)
				DialogStack.Pop()
				utils.GuideHelper.Go(cfg.from,cfg.sub_from)
			else
				utils.GuideHelper.Show(cfg.from,cfg.sub_from)
			end
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
	if event == "SHOP_BUY_SUCCEED"  then
		if shopItemGid and data and data.gid == shopItemGid then
			if self.SelectIdx then
				local _obj = self.view.Viewport.Content.transform:GetChild(self.SelectIdx-1).gameObject
				local _item = CS.SGK.UIReference.Setup(_obj.gameObject)
				_item[CS.UGUIClickEventListener].interactable = true
			end
			
			self:updateSoureCfg()
			shopItemGid = nil
		end
	elseif event == "SHOP_BUY_FAILED" then
		if shopItemGid and data and data.gid == shopItemGid then
			if self.SelectIdx then
				local _obj = self.view.Viewport.Content.transform:GetChild(self.SelectIdx-1).gameObject
				local _item = CS.SGK.UIReference.Setup(_obj.gameObject)
				_item[CS.UGUIClickEventListener].interactable = true
			end
			
			showDlgError(nil,"购买失败");
			shopItemGid = nil
		end
	end
end
return View