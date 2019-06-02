local ShopModule = require "module.ShopModule"
local ItemModule = require "module.ItemModule"
local UserDefault = require "utils.UserDefault"
local ItemHelper = require "utils.ItemHelper"
local heroModule = require "module.HeroModule"
local equipmentModule = require "module.equipmentModule"
local playerModule = require "module.playerModule";
local TipConfig= require "config.TipConfig"
local CommonConfig = require "config.commonConfig"
local Time = require "module.Time";

local View = {};

local shop_data = UserDefault.Load("shop_data", true);
local UnionTechTypes ={AddProductType = 21,DisCountType = 22}
local UnionTechesLv = {}
local UnionShopId = 4

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view

	SGK.BackgroundMusicService.PlayMusic("sound/shangcheng.mp3");

	local resourcesBarObj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"),self.root.transform)
	--self:UpdateBetterScreenSize(resourcesBarObj)

	UnionTechesLv[UnionTechTypes.AddProductType] = module.unionScienceModule.GetScienceInfo(UnionTechTypes.AddProductType) and module.unionScienceModule.GetScienceInfo(UnionTechTypes.AddProductType).level or 0
	UnionTechesLv[UnionTechTypes.DisCountType]   = module.unionScienceModule.GetScienceInfo(UnionTechTypes.DisCountType) and module.unionScienceModule.GetScienceInfo(UnionTechTypes.DisCountType).level or 0
	
	self:setCallback();

	self.curID = data and data.index or self.savedValues.ShopId;
	self.SelectId = data and data.selectId--指定商品
	self.resetTopResourcesIcon = data and data.DoResetTopResourcesIcon--退出时不回复顶部资源

	self.Refreshing = false

	self.next_Refresh_time = {}

	if ShopModule.Query() then
		self:InitData();
	end
end

function View:InitData()
	self.shoplist = {};
	self.canRefresh = {};
	self.refreshCousume = {}

	self.operate_obj = nil;

	self.openShopList = {}
	local _tab = ShopModule.GetOpenShop()
	for k,v in pairs(_tab) do
		table.insert(self.openShopList,v)
	end
	table.sort(self.openShopList,function (a,b)
		return a.shop_oder < b.shop_oder;
	end)

	if shop_data.timeDay == nil or shop_data.timeDay ~= CS.System.DateTime.Now.Day then
		shop_data.timeDay = CS.System.DateTime.Now.Day
		shop_data.refreshTimes = shop_data.refreshTimes or {}
		for i=1,#self.openShopList do
			shop_data.refreshTimes[self.openShopList[i].Shop_id] = 0;
		end
	end

	self.curID = self.curID or self.openShopList[1].Shop_id ;--默认打开第一个商店

	self:SwitchType(self.curID,true);
	
	self:upShopTabView();
end

--special
function View:setCallback()
	self.UIPageViewScript = self.view.shopView.ScrollView[CS.UIPageView]

	self.ShopViewUIDragIconScript = self.view.shopView.ScrollView[CS.UIMultiScroller]
	self.ShopViewUIDragIconScript.RefreshIconCallback = (function (obj,idx)
		self.ItemUITab=self.ItemUITab or {}
		self:upShopView(obj,idx);
	end)

	-- self.SpecialShopViewUIDragIconScript = self.view.shopView.ScrollView_2.ScrollView[CS.UIMultiScroller]
	-- self.SpecialShopViewUIDragIconScript.RefreshIconCallback = (function (obj,idx)
	-- 	self:upShopView(obj,idx);
	-- end)

	self.UIPageViewScript.OnPageChanged =(function (index)
		if self.UIPageViewScript.dataCount>1 then
			self.nowPageIdx = index
			self.view.arrow.left.gameObject:SetActive(index ~= 0)
			self.view.arrow.right.gameObject:SetActive(index ~= (self.UIPageViewScript.dataCount-1))
			self:RefPageItem(index)
		end
	end)

	CS.UGUIClickEventListener.Get(self.view.arrow.right.gameObject).onClick = function()
		self.nowPageIdx=self.nowPageIdx or 0
		if self.nowPageIdx<=self.UIPageViewScript.dataCount-1 then
			self.UIPageViewScript:pageTo(self.nowPageIdx + 1)
		end
	end
	CS.UGUIClickEventListener.Get(self.view.arrow.left.gameObject).onClick = function()    
		if self.nowPageIdx>0 then
			self.UIPageViewScript:pageTo(self.nowPageIdx - 1)
		end
	end

	CS.UGUIClickEventListener.Get(self.view.midView.refresh.refreshBtn.gameObject).onClick = function (obj)
		self:OnClickRefreshBtn()		
	end
end

local flashSaleShopId = 1
--更新商店Tab页签
function View:upShopTabView()
	local _shopTabContent = self.view.tabContent.Viewport.Content
	for i=1,_shopTabContent.transform.childCount do
		_shopTabContent[i]:SetActive(false);
	end

	for i=1,#self.openShopList do
		local item = utils.SGKTools.GetCopyUIItem(_shopTabContent,_shopTabContent.Toggle,i)
		item.Label[UI.Text].text = self.openShopList[i].Name;
		item[UI.Toggle].isOn = self.openShopList[i].Shop_id == self.curID

		--更换 shopIcon
		item.Background.ShopIcon[UI.Image]:LoadSprite("shop/"..self.openShopList[i].Shop_icon)

		CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj)		
			if self.curID ~= self.openShopList[i].Shop_id then
				self:SwitchType(self.openShopList[i].Shop_id);
			end
		end

		if flashSaleShopId == self.openShopList[i].Shop_id then
			item.redDot:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.Shop.FlashSaleShopRefresh,nil,item.redDot))
		else
			item.redDot:SetActive(false)
		end
	end

	CS.UGUIClickEventListener.Get(self.view.tabContent.leftArrow.gameObject).onClick = function()
		_shopTabContent.transform:DOLocalMove(Vector3.zero,0.2)
	end
	CS.UGUIClickEventListener.Get(self.view.tabContent.rightArrow.gameObject).onClick = function()    
		local _width = _shopTabContent[UnityEngine.RectTransform].sizeDelta.x
		_shopTabContent.transform:DOLocalMove(Vector3(-_width,0,0),0.2)
	end
end

function View:SwitchType(id,showMove)--id
	self.ItemUITab = self.ItemUITab or {}--播放特效Tab
	self.ItemUITab[id]=self.ItemUITab[id] or {}
	self.ItemUITab[id].Showed=false--标记刷新特效播放过
	self.SelectItem=nil

	self.sellState = false
	self.nowPageIdx = 0
	self.curID = id;


	local function updateTopResources()
		local _shopCfg = ShopModule.Load(id)
		self.view.midView.Activity.Image[UI.Image]:LoadSprite("shop/".._shopCfg.show_image)
		--显示刷新道具
		for i=1,4 do
			DispatchEvent("CurrencyRef",{i,_shopCfg["top_resource_id"..i]})
		end
		--跳转商店时 下方滑动条以跟着移动
		if showMove then
			local off_x = self.view.tabContent.Viewport.Content.Toggle.transform.sizeDelta.x
			for i=1,#self.openShopList do
				if self.openShopList[i].Shop_id==id then
					self.view.tabContent.Viewport.Content.transform:DOLocalMove(-Vector3(off_x*(i-3),0,0),0.2)
					break
				end
			end
		end
	end

	if self.shoplist[id] == nil or #self.shoplist[id] == 0 then
		local shoplist = ShopModule.GetManager(id);
		if shoplist ~= nil and shoplist.shoplist ~= nil then-------159 
			self.shoplist[id] = self:sortList(shoplist.shoplist);
			self.canRefresh[id] = shoplist.refresh;	
			self.refreshCousume[id]=shoplist.refreshCousume
			self.next_Refresh_time[id]=shoplist.next_fresh_time
			self:refreshShopView(self.shoplist[id], id);
			updateTopResources()
		elseif id ~= 1 then
			self:SwitchType(1);
		end
		return;
	end

	updateTopResources()
	self:refreshShopView(self.shoplist[id],id);	
end

function View:refreshShopView(shoplist,id)
	self.refreshCanClick=false
	self:updateRefreshTimes(id);

	if id ==flashSaleShopId then
		ShopModule.SetlocalFlashSaleShopCheckTime()

		for i=1,#self.openShopList do
			if self.openShopList[i].Shop_id == id then
				local _obj = self.view.tabContent.Viewport.Content.transform:GetChild(i-1).gameObject
				if _obj then
					local shopTypeItem = CS.SGK.UIReference.Setup(_obj);
					shopTypeItem.redDot:SetActive(false);
				end
				break
			end
		end
	end

	if shoplist == nil or #shoplist == 0 then
		return;
	end

	self.view.arrow.gameObject:SetActive(id~=9)
	self.view.shopView.ScrollView.gameObject:SetActive(id~=9)
	self.view.shopView.ScrollView_2.gameObject:SetActive(id==9)

	if id~=9 then
		self.ShopViewUIDragIconScript.DataCount= math.ceil(#shoplist/8);
		self.UIPageViewScript.DataCount=math.ceil(#shoplist/8)
		
		self.view.arrow.gameObject:SetActive(self.ShopViewUIDragIconScript.DataCount>1)
		self.view.arrow.left.gameObject:SetActive(false)
		self.view.arrow.right.gameObject:SetActive(true)
	else
		--print("9号商店")
		-- self.SpecialShopViewUIDragIconScript.DataCount = math.ceil(#shoplist);

		-- --跳转至当前选中商品
		-- if self.SelectId then
		-- 	for i=1,#shoplist do
		-- 		if shoplist[i].product_item_id == self.SelectId then
		-- 			self.SpecialShopViewUIDragIconScript:ScrollMove(i-1)
		-- 			break
		-- 		end
		-- 	end
		-- end
	end
end

function View:updateRefreshTimes(Id)
	self.view.midView.refresh.refreshBtn:SetActive(self.canRefresh[Id]==1)
	self.view.midView.refresh.refreshBtn.Text[UI.Text].text="进货"

	if Id == 15 then
		self.view.midView.refresh.surplus[UI.Text].text = SGK.Localize:getInstance():getValue("shizhuangshangdian_01")
	else
		self.view.midView.refresh.surplus:SetActive(self.next_Refresh_time[Id])
		if self.next_Refresh_time[Id] then
			--能主动刷新
			if self.canRefresh[Id] and self.refreshCousume[Id] and next(self.refreshCousume[Id])~=nil then	
				local _consumeItem=ItemHelper.Get(self.refreshCousume[Id][1],self.refreshCousume[Id][2])
				self.view.midView.refresh.refreshBtn.Icon2[UI.Image]:LoadSprite("icon/" .._consumeItem.icon.."_small")

				--local itemCount = ItemModule.GetItemCount(self.refreshCousume[self.curID][2]);
				--self.view.midView.refresh.refreshBtn.counter2[UI.Text].text=string.format("%sx%s</color>",itemCount>=self.refreshCousume[Id][3] and "<color=#FFFFFFFF>" or "<color=#FF1A1AFF>",self.refreshCousume[Id][3])
			end

			local _t = self.next_Refresh_time[Id]-module.Time.now()
			local _time = string.format("%02d",math.floor(math.floor(math.floor(_t/60)/60)%24))..":"..string.format("%02d",math.floor(math.floor(_t/60)%60))..":"..string.format("%02d",math.floor(_t%60))
			if Id == 1 then
				self.view.midView.refresh.surplus[UI.Text]:TextFormat("<color=#3BFFBCFF>{0}</color>后进货",_time)
			elseif Id == 9 then
				self.view.midView.refresh.surplus[UI.Text]:TextFormat("每天<color=#3BFFBCFF>{0}</color>进货\n<color=#3BFFBCFF>{1}</color>后进货",os.date("%X",self.next_Refresh_time[self.curID]),_time)
			else
				self.view.midView.refresh.surplus[UI.Text]:TextFormat("每天<color=#3BFFBCFF>{0}</color>刷新\n<color=#3BFFBCFF>{1}</color>后刷新",os.date("%X",self.next_Refresh_time[self.curID]),_time)
			end
		end
	end
end

local function upProductBaseInfo(productCfg,item)

	return product_cfg,consume_cfg
end

local specialShopId = 9
local MaxPerPage = 8--每页的最大值
function View:upShopView(obj, idx)
	local shopItem = CS.SGK.UIReference.Setup(obj);
	shopItem:SetActive(true)
	if self.curID == specialShopId then
		local index = idx + 1;
		local productCfg = self.shoplist[self.curID][index]
		local item = shopItem
		if productCfg then
			--[[
			--道具信息显示
			local product_cfg = ItemHelper.Get(productCfg.product_item_type,productCfg.product_item_id,nil,productCfg.product_item_value);
			utils.IconFrameHelper.Create(item.IconFrame,{customCfg = product_cfg})
			--name
			item.top.name[UI.Text].text = product_cfg.name

			--消耗品信息显示
			local consume_cfg = ItemHelper.Get(productCfg.consume_item_type1,productCfg.consume_item_id1)
			item.bottom.Icon[UI.Image]:LoadSprite("icon/"..consume_cfg.icon.."_small")
			--消耗品Icon点击提示
			local off_y = item.buyBtn.Icon[UnityEngine.RectTransform].sizeDelta.y
			utils.SGKTools.ShowItemNameTip(item.bottom.Icon,consume_cfg.name,1,off_y)
			--拥有信息
			local own_nub = self:GetProductCount(productCfg.product_item_type,productCfg.product_item_id)--拥有数量
			item.bottom.Icon.gameObject:SetActive(own_nub < 1)
			item.bottom.type[UI.Text].text = ItemHelper.Get(ItemHelper.TYPE.ITEM,productCfg.product_item_id).type_Cfg.name
			item.bottom.price[UI.Text].text = tostring(own_nub < 1 and productCfg.origin_price or "")	
			item.bottom.haveText[UI.Text].text = tostring(own_nub < 1 and "" or  "<color=#3BFFBCFF>已拥有</color>")

			--商品售罄
			local _showMark = productCfg.product_count <= 0 and 0
			item.mark.gameObject:SetActive(_showMark)

			--打折信息
			if Time.now() >= productCfg.begin_time and  Time.now() <= productCfg.end_time and own_nub < 1 then
				item.discount.gameObject:SetActive(true)
				item.discount.Top.Text[UI.Text]:TextFormat("<color=#FFD800FF>{0}折</color>",tonumber(productCfg.discount)/10)
				item.discount.bottom.Text[UI.Text].text=string.format("<color=#FFD800FF>%s</color>",math.floor(productCfg.consume_item_value1))
			else
				item.discount.gameObject:SetActive(false)
			end

			if self.SelectId then
				item.Checkmark.gameObject:SetActive(self.SelectId == product_cfgid)
				if self.SelectId == product_cfg.id then
					self:refItemInfo(productCfg,item,index)
				end
			else
				self.SelectId = product_cfg.id
				item.Checkmark.gameObject:SetActive(true)
				self:refItemInfo(productCfg,item,index)
			end
		
			CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj)	
				if self.SelectId then
					for i=1,#self.shoplist[self.curID] do
						if self.shoplist[self.curID][i].product_item_id == self.SelectId then
							local _obj = self.SpecialShopViewUIDragIconScript:GetItem(i-1)
							local _selectItem = CS.SGK.UIReference.Setup(_obj)
							if _selectItem and _selectItem.Checkmark then
								_selectItem.Checkmark:SetActive(false)
							end
							break
						end
					end
				end
				self.SelectId = product_cfg.id

				item.Checkmark.gameObject:SetActive(true)
				self:refItemInfo(productCfg,item,index)
			end
			--]]
		end
	else
		for i = 1,MaxPerPage do
			local index = idx*MaxPerPage + i;
			local productCfg = self.shoplist[self.curID][index]
			local item = utils.SGKTools.GetCopyUIItem(shopItem,shopItem[1],i)
			if item then
				if productCfg then
					--道具信息显示
					local product_cfg = ItemHelper.Get(productCfg.product_item_type,productCfg.product_item_id,nil,productCfg.product_item_id ~= 10000 and productCfg.product_item_value or 0);
					utils.IconFrameHelper.UpdateIcon(product_cfg, item.CommonIcon)
					--name(公会未解锁物品特殊处理)
					item.name[UI.Text].text = product_cfg.id ~= 10000 and product_cfg.name or "尚未解锁"
					--消耗品信息显示
					local consume_cfg = ItemHelper.Get(productCfg.consume_item_type1,productCfg.consume_item_id1)
					item.buyBtn.Icon[UI.Image]:LoadSprite("icon/"..consume_cfg.icon.."_small")
					--消耗品Icon点击提示
					local off_y = item.buyBtn.Icon[UnityEngine.RectTransform].sizeDelta .y
					utils.SGKTools.ShowItemNameTip(item.buyBtn.Icon,consume_cfg.name,1,off_y)
					
					--设置碎片的数量和mark显示
					item.debrisMark:SetActive(product_cfg.sub_type == 21)
					item.debrisMark.Text:SetActive(false)
					if product_cfg.sub_type == 21 then
						local function upDebrisInfo(_cfg,_item)
							local _heroId = _cfg.id - 10000
							local _hero = module.HeroModule.GetManager():Get(_heroId)
							local _index = _hero and 0 or 1

							_item.debrisMark.Image[CS.UGUISpriteSelector].index = _index
							_item.debrisMark.Text:SetActive(_index== 1)
							if _index == 1 then
								local _product = ShopModule.GetManager(6, _heroId) and ShopModule.GetManager(6, _heroId)[1]
								if _product then
									if _product.consume_item_id1 and _product.consume_item_id1 == _cfg.id and _product.product_item_id and _product.product_item_id == _heroId then
										_item.debrisMark.Text:SetActive(true)
										local limit = _product.consume_item_value1
										local _count = ItemModule.GetItemCount(_cfg.id)

										_item.debrisMark.Text[UI.Text].text = string.format("%s%s</color>/%s",limit>_count and "<color=#FF0000FF>" or "<color=#FFFFFFFF>",_count,limit)
									else
										ERROR_LOG("info  is err",_product.consume_item_id1,_product.product_item_id)
									end
								end
							end
						end
						upDebrisInfo(product_cfg,item)
					end
					--价格VS折扣
					local function GetProductShowPrice(_shop_id,_cfg)
						local _discount,_showPrice,_origin_price = _cfg.discount,_cfg.consume_item_value1,_cfg.origin_price
						--公会商店
						if _shop_id == UnionShopId then
							--公会科技--讨价还价
							if UnionTechesLv[UnionTechTypes.DisCountType] > 0 then
								local _unionTechCfg = module.unionScienceModule.GetScienceCfg(nil,UnionTechTypes.DisCountType,UnionTechesLv[UnionTechTypes.DisCountType])
								if _unionTechCfg then
									_discount = 100-_unionTechCfg.param
									_showPrice = _cfg.consume_item_value1*_cfg.discount/100
								else
									ERROR_LOG("unionTechCfg is nil type level",UnionTechTypes.DisCountType,UnionTechesLv[UnionTechTypes.DisCountType])
								end
							end
						else--商品价格 和购买次数挂钩
							local floatPriceCfg = ShopModule.GetPriceByNum(_cfg.gid,_cfg.buy_count + 1)
							if floatPriceCfg and next(floatPriceCfg)~=nil then
								_showPrice = floatPriceCfg.sellPrice
								_origin_price = floatPriceCfg.origin_price
							end
						end
						return _discount,_showPrice,_origin_price
					end
					--设置商品的折扣出售价格和原价
					productCfg.discount,productCfg.sell_price,productCfg.origin_price = GetProductShowPrice(self.curID,productCfg)
					--价格
					local _price = math.floor(productCfg.discount < 100 and productCfg.origin_price or productCfg.sell_price)
					item.buyBtn.num[UI.Text].text = product_cfg.id ~= 10000 and _price or "???"
					--打折信息
					item.discount:SetActive(product_cfg.id ~= 10000 and productCfg.discount < 100)
					if productCfg.discount < 100 then
						item.discount.Top.Text[UI.Text]:TextFormat("<color=#FFD800FF>{0}折</color>",tonumber(productCfg.discount)/10)
						item.discount.bottom.Text[UI.Text].text = string.format("<color=#FFD800FF>%s</color>",math.floor(productCfg.sell_price))
					end
					--特殊标志
					local _showMark = nil
					if product_cfg.id == 10000 then--公会商店商品未解锁
						_showMark = 1
					elseif productCfg.product_count <= 0 then--商品售罄
						_showMark = 0
					end
					item.mark.gameObject:SetActive(not not _showMark)
					item.mark.Image[CS.UGUISpriteSelector].index = _showMark or 0

					item.buyBtn[CS.UGUISpriteSelector].index = _showMark and 1 or 0
					CS.UGUIClickEventListener.Get(item.buyBtn.gameObject).onClick = function (obj)
						if not _showMark then
							self:ShowBuyInfo(productCfg,item,index);
						elseif _showMark == 1 then
							showDlgError(nil,SGK.Localize:getInstance():getValue("guild_shop_info2"))
						end
					end

					CS.UGUIClickEventListener.Get(item.mark.gameObject,true).onClick = function (obj) 
						if _showMark and _showMark == 1 then
							showDlgError(nil,SGK.Localize:getInstance():getValue("guild_shop_info2"))
						end
					end

					CS.UGUIClickEventListener.Get(item.buy.gameObject).onClick = function (obj) 
						if not _showMark then
							self:ShowBuyInfo(productCfg,item,index);
						elseif _showMark == 1 then
							showDlgError(nil,SGK.Localize:getInstance():getValue("guild_shop_info2"))
						end
					end
				else
					item:SetActive(false)
				end
			end
		end
	end

	-- self.ItemUITab[self.curID][idx]={}

		
	-- 	--商店切换刷新
	-- 	if (self.curID~=9 and idx==0) or (self.curID==9 and idx<3) then
	-- 		table.insert(self.ItemUITab[self.curID][idx],item)
	-- 	end	
	-- end

	-- if not self.ItemUITab[self.curID].Showed then
	-- 	self:RefPageItem(idx)
	-- end	
end

local itemQualityTab={[0]="<color=#B6B6B6FF>","<color=#2CCE8FFF>","<color=#1295CCFF>","<color=#8547E3FF>","<color=#FEA211FF>","<color=#EF523BFF>","<color=#B6B6B6FF>",}
function View:ShowBuyInfo(productCfg,item,index)
	self.view.buyDetailPanel.bg[UnityEngine.CanvasGroup].alpha = 0 
	self.view.buyDetailPanel.view[UnityEngine.CanvasGroup].alpha = 0

	self.view.buyDetailPanel.gameObject:SetActive(true)
	self.view.arrow.gameObject:SetActive(false)

	self.view.buyDetailPanel.bg[UnityEngine.CanvasGroup]:DOFade(1,0.1):OnComplete(function ( ... )
		self.view.buyDetailPanel.view[UnityEngine.CanvasGroup]:DOFade(1,0.2)
	end)

	local _panel = self.view.buyDetailPanel.view

	local product_cfg = ItemHelper.Get(productCfg.product_item_type,productCfg.product_item_id,nil,productCfg.product_item_value);
	assert(product_cfg,"product_cfg is nil");

	utils.IconFrameHelper.Create(_panel.baseInfo.IconFrame,{customCfg = product_cfg,showDetail = true})
	_panel.baseInfo.name[UI.Text]:TextFormat("{0}{1}{2}",itemQualityTab[product_cfg.quality],product_cfg.name,"</color>")
	_panel.baseInfo.type[UI.Text].text = product_cfg.type_Cfg.pack_order ~= "0" and  product_cfg.type_Cfg.name or "其他"
	--描述
	_panel.baseInfo.desc:SetActive(product_cfg.sub_type ~= 21)
	_panel.baseInfo.skillView:SetActive(product_cfg.sub_type == 21)
	_panel.baseInfo.ownNum:SetActive(product_cfg.sub_type == 21)
	--碎片
	if product_cfg.sub_type == 21 then
		local _heroId = product_cfg.id - 10000
		_panel.baseInfo.skillView[SGK.LuaBehaviour]:Call("InitData", {heroId = _heroId,Anchors =1})
		_panel.baseInfo.skillView.title[UI.Text].text = SGK.Localize:getInstance():getValue("suipian_2")
		local _hero = module.HeroModule.GetManager():Get(_heroId)
		local _count = ItemModule.GetItemCount(product_cfg.id)
		if not _hero then
			local _product = ShopModule.GetManager(6, _heroId) and ShopModule.GetManager(6, _heroId)[1]
			if _product then
				if _product.consume_item_id1 and _product.consume_item_id1 == product_cfg.id and _product.product_item_id and _product.product_item_id == _heroId then
					local limit = _product.consume_item_value1
					_panel.baseInfo.ownNum[UI.Text].text = string.format("%s%s%s</color>/%s",SGK.Localize:getInstance():getValue("suipian_3"),limit>_count and "<color=#FF0000FF>" or "<color=#FFFFFFFF>",_count,limit)
				else
					ERROR_LOG("info  is err",_product.consume_item_id1,_product.product_item_id)
				end
			end
		else
			_panel.baseInfo.ownNum[UI.Text].text = string.format("%s%s",SGK.Localize:getInstance():getValue("suipian_3"),_count)
		end
	else
		_panel.baseInfo.desc[UI.Text].text = product_cfg.info;
	end

	--购买信息
	_panel.buyInfo.buyNum.title[UI.Text].text = SGK.Localize:getInstance():getValue("购买数量")
	_panel.buyInfo.buyNum.num[UI.Text].text = "1"
	_panel.buyInfo.sumConsume.title[UI.Text].text = SGK.Localize:getInstance():getValue("购买总价")
	_panel.buyInfo.sumConsume.num[UI.Text].text = math.floor(productCfg.sell_price)

	--消耗品信息显示
	local consume_cfg = ItemHelper.Get(productCfg.consume_item_type1,productCfg.consume_item_id1)
	_panel.buyInfo.sumConsume.Icon[UI.Image]:LoadSprite("icon/"..consume_cfg.icon.."_small")
	local off_y = _panel.buyInfo.sumConsume.Icon[UnityEngine.RectTransform].sizeDelta.y
	utils.SGKTools.ShowItemNameTip(_panel.buyInfo.sumConsume.Icon,consume_cfg.name,1,off_y)

	local surplus_Count = productCfg.product_count
	_panel.Btns.storeInfo[UI.Text]:TextFormat("今日还可购买{0}/{1}次",surplus_Count-1,productCfg.storage)
	self.BuyNum = 1
	CS.UGUIClickEventListener.Get(_panel.buyInfo.buyNum.Add.gameObject).onClick = function (obj) 
		if productCfg.product_count-1 >= self.BuyNum then
			self.BuyNum = self.BuyNum + 1	
			_panel.buyInfo.buyNum.num[UI.Text].text = tostring(self.BuyNum)
			_panel.Btns.storeInfo[UI.Text]:TextFormat("今日还可购买{0}/{1}次",surplus_Count-self.BuyNum,productCfg.storage)
			_panel.buyInfo.sumConsume.num[UI.Text].text = self:GetTotalConsume(productCfg,self.BuyNum)
		else
			showDlgError(nil,SGK.Localize:getInstance():getValue("库存不足"));
		end
	end

	CS.UGUIClickEventListener.Get(_panel.buyInfo.buyNum.Sub.gameObject).onClick = function (obj) 
		if self.BuyNum>=1 then
			self.BuyNum=self.BuyNum-1
			_panel.Btns.storeInfo[UI.Text]:TextFormat("今日还可购买{0}/{1}次",surplus_Count-self.BuyNum,productCfg.storage)
			_panel.buyInfo.buyNum.num[UI.Text].text=tostring(self.BuyNum)
			_panel.buyInfo.sumConsume.num[UI.Text].text=self:GetTotalConsume(productCfg,self.BuyNum)
		end
	end

	CS.UGUIClickEventListener.Get(_panel.buyInfo.buyNum.Max.gameObject).onClick = function (obj) 
		self.BuyNum = productCfg._product_count
		_panel.Btns.storeInfo[UI.Text]:TextFormat("今日还可购买{0}/{1}次",surplus_Count-self.BuyNum,productCfg.storage)
		_panel.buyInfo.buyNum.num[UI.Text].text = tostring(self.BuyNum)
		_panel.buyInfo.sumConsume.num[UI.Text].text = self:GetTotalConsume(productCfg,self.BuyNum)
	end

	_panel.Btns.buyBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("购买")
	CS.UGUIClickEventListener.Get(_panel.Btns.buyBtn.gameObject).onClick = function (obj)
		self:InBuying(productCfg,item,index)
		self.view.arrow.gameObject:SetActive(self.curID~=9)
		if self.curID ~= 9 then
			self.view.arrow.gameObject:SetActive(self.ShopViewUIDragIconScript.DataCount>1)
		end
	end
	CS.UGUIClickEventListener.Get(_panel.Btns.cancleBtn.gameObject).onClick = function (obj) 
		self.view.buyDetailPanel.gameObject:SetActive(false)
		self.view.arrow.gameObject:SetActive(self.curID ~= 9)
		if self.curID ~= 9 then
			self.view.arrow.gameObject:SetActive(self.ShopViewUIDragIconScript.DataCount > 1)
		end
	end

	CS.UGUIClickEventListener.Get(_panel.buyInfo.buyNum.InputBtn.gameObject).onClick = function (obj) 
		self.view.buyNumPanel.Dialog.Num[UI.InputField].text = ""
		self.view.buyNumPanel.gameObject:SetActive(true)
	end

	CS.UGUIClickEventListener.Get(self.view.buyNumPanel.Dialog.closeBtn.gameObject).onClick = function (obj) 
		self.view.buyNumPanel.gameObject:SetActive(false)
	end
	CS.UGUIClickEventListener.Get(self.view.buyDetailPanel.mask.gameObject).onClick = function (obj) 
		self.view.buyDetailPanel.gameObject:SetActive(false)
		self.view.arrow.gameObject:SetActive(self.curID~=9)
		if self.curID~=9 then
			self.view.arrow.gameObject:SetActive(self.ShopViewUIDragIconScript.DataCount>1)
		end
	end

	CS.UGUIClickEventListener.Get(self.view.buyNumPanel.Dialog.Btns.Save.gameObject).onClick = function (obj) 
		self.view.buyNumPanel.gameObject:SetActive(false)
		local _inputNum=tonumber(self.view.buyNumPanel.Dialog.Num[UI.InputField].text)
		self.BuyNum=surplus_Count>=_inputNum  and _inputNum or surplus_Count
		_panel.Btns.storeInfo[UI.Text]:TextFormat("今日还可购买{0}/{1}次",surplus_Count-self.BuyNum,productCfg.storage)
		_panel.buyInfo.buyNum.num[UI.Text].text=tostring(self.BuyNum)
		_panel.buyInfo.sumConsume.num[UI.Text].text=self:GetTotalConsume(productCfg,self.BuyNum)
	end

	CS.UGUIClickEventListener.Get(self.view.buyNumPanel.Dialog.Btns.Cancel.gameObject).onClick = function (obj) 
		self.view.buyNumPanel.gameObject:SetActive(false)
	end	
end

function View:InBuying(productCfg,item,index)
	if self.operate_obj == nil then
		if self:GetTotalConsume(productCfg,self.BuyNum)<= ItemModule.GetItemCount(productCfg.consume_item_id1) then
			SetItemTipsStateAndShowTips(false)

			self.view.ShoppingMask.gameObject:SetActive(true)
			self.view.buyDetailPanel.view.Btns.buyBtn[CS.UGUIClickEventListener].interactable=false

			ShopModule.Buy(self.curID,productCfg.gid,self.BuyNum);
			self.ShoppingTab = {productCfg,item,index,productCfg.product_count <= self.BuyNum}
		else
			local consume_cfg = ItemHelper.Get(productCfg.consume_item_type1,productCfg.consume_item_id1)
			showDlgError(nil,string.format("%s不足",consume_cfg.name));
		end
	end
end

function View:DoShopping(productCfg,item,index,case2)	
	local product_cfg = ItemHelper.Get(productCfg.product_item_type,productCfg.product_item_id,nil,productCfg.product_item_value*self.BuyNum);
	assert(product_cfg,"product_cfg is nil");

	local CommonIconPool = CS.GameObjectPool.GetPool("CommonIconPool");
	local shoppingItem = SGK.UIReference.Setup(CommonIconPool:Get(item.transform))
	utils.IconFrameHelper.UpdateIcon(product_cfg, shoppingItem)

	shoppingItem.transform.localPosition = self.curID==9 and Vector3(80,-60,0) or  Vector3(80,180,0)
	shoppingItem.transform.localScale = Vector3.one*0.9
	shoppingItem:SetActive(true)
	

	-- shoppingItem.gameObject.transform:SetParent(item.gameObject.transform)
	shoppingItem.gameObject.transform:DOShakeRotation(0.1,Vector3(0,0,30)):OnComplete(function ( ... )
		if case2 then
			item.mark.gameObject:SetActive(true)
		end
		shoppingItem.transform:DOScale(Vector3.one,0.5)
		shoppingItem.transform:DOLocalJump(self.curID==9 and Vector3(80,-55,0) or Vector3(80,190,0),15,1,0.5):OnComplete(function ( ... )
			shoppingItem.transform:DOLocalMove(self.curID==9 and Vector3(80,-100,0) or Vector3(80,75,0),0.2):OnComplete(function ( ... )
				utils.IconFrameHelper.Release(shoppingItem.gameObject)

				local exportItem = SGK.UIReference.Setup(CommonIconPool:Get(self.view.midView.export.node.transform))
				utils.IconFrameHelper.UpdateIcon(product_cfg, exportItem)
				exportItem.transform.localPosition = Vector3(0,140,0)
				exportItem.transform.localScale = Vector3.one*0.8
				exportItem:SetActive(true)

				exportItem.transform:DOScale(Vector3.one,0.1):SetDelay(0.5)
				exportItem.transform:DOLocalMove(Vector3(0,0,0),0.1):OnComplete(function ( ... )
					self.view.transform:DOScale(Vector3.one,1.2):OnComplete(function()
						SetItemTipsStateAndShowTips(true)
						self.view.ShoppingMask.gameObject:SetActive(false)
						utils.IconFrameHelper.Release(exportItem.gameObject)
						--购买动画播放完刷新显示
						if self.curID==9 then
							--self.SpecialShopViewUIDragIconScript:ItemRef()
						else
							self.ShopViewUIDragIconScript:ItemRef()
						end
					end)
				end):SetDelay(0.5)
			end)
		end)
	end):SetDelay(0.5)
end

function View:updateShopLeftTime()
	local data=nil
	for k,v in pairs(self.openShopList) do
		if v.Shop_id == self.curID  then
			data = v.shopTime_left
		end
	end
	if data then
		for i=1,#data do
			if data[i][1] and data[i][2] and  data[i][3] and data[i][4] and Time.now() > data[i][1] and Time.now() < data[i][2] then
				local delta = Time.now() - data[i][1];
				if (delta%data[i][3]) < data[i][4]  then 
					--if self.curID==1 or self.curID == 32 or self.curID == 33 then
						self._leftData = data[i]
						break
					--end	
				end
			end
		end
	end
end

function View:RefPageItem(idx)
	SGK.Action.DelayTime.Create(1):OnComplete(function()
		self.ItemUITab[self.curID].Showed=true
	end)
	
	if self.ItemUITab[self.curID][idx] then
		if self.curID~=9 then
			for k,v in pairs(self.ItemUITab[self.curID][idx]) do
				self.ItemUITab[self.curID][idx][k].ItemIcon.gameObject:SetActive(false)
				self.ItemUITab[self.curID][idx][k].name[UI.Text].color={r=0,g=0,b=0,a=0}--.gameObject:SetActive(false)
				self.ItemUITab[self.curID][idx][k].mark.Image[UI.Image].color={r=1,g=1,b=1,a=0}
			end
			for i=1,4 do
				if self.ItemUITab[self.curID][idx][i] then
					self:DoRefItemAnima(self.ItemUITab[self.curID][idx][i])
				end
			end
			if #self.ItemUITab[self.curID][idx]>4 then
				SGK.Action.DelayTime.Create(0.2):OnComplete(function()
					for i=5,#self.ItemUITab[self.curID][idx] do
						if self.ItemUITab[self.curID][idx][i] then
							self:DoRefItemAnima(self.ItemUITab[self.curID][idx][i])
						end
					end
				end)
			end	
		else
			for i=1,#self.ItemUITab[self.curID] do
				if self.ItemUITab[self.curID][idx] and self.ItemUITab[self.curID][idx][1] then
					self.ItemUITab[self.curID][idx][1].ItemIcon.gameObject:SetActive(false)
					self.ItemUITab[self.curID][idx][1].mark.Image[UI.Image].color={r=1,g=1,b=1,a=0}
					if self.ItemUITab[self.curID][idx][i] then
						self.ItemUITab[self.curID][idx][i].fx_root.transform:DOScale(Vector3.one,0.2*i):OnComplete(function()
							self:DoRefItemAnima(self.ItemUITab[self.curID][idx][i])
						end)
					end
				end
			end
		end
	end
end

function View:DoRefItemAnima(item)
	if not item then return  end
	if self.Refreshing then
		item.ItemIcon:GetComponent(typeof(UnityEngine.RectTransform)).anchoredPosition = CS.UnityEngine.Vector2(0,-15)
		item.ItemIcon:GetComponent(typeof(UnityEngine.RectTransform)).pivot = CS.UnityEngine.Vector2(0.5, 0)

		item.ItemIcon.transform:DOScale(Vector3.one,0.2):OnComplete(function()
			item.ItemIcon.gameObject:SetActive(true)
			item.mark.Image[UI.Image].color={r=1,g=1,b=1,a=1}
			item.ItemIcon.gameObject.transform:DOLocalRotate(Vector3(-90,0,0),0.2)
		end)
	end

	SGK.Action.DelayTime.Create(self.Refreshing and 0.4 or 0):OnComplete(function()
		if self.gameObject then
			item.ItemIcon:GetComponent(typeof(UnityEngine.RectTransform)).anchoredPosition = CS.UnityEngine.Vector2(self.curID==9 and -120 or 0,self.curID==9 and 60 or 105)		
			item.ItemIcon:GetComponent(typeof(UnityEngine.RectTransform)).pivot = CS.UnityEngine.Vector2(0.5, 1)
			item.ItemIcon.gameObject.transform.localEulerAngles = Vector3(90,0,0)

			item.ItemIcon.gameObject:SetActive(true)

			local _parent=nil
			local localPos=nil
			if self.curID~=9 then
				_parent=self.view.shopView.ScrollView
				localPos=_parent.Viewport.Content.Item.gameObject.transform:TransformPoint(item.gameObject.transform.localPosition+Vector3(80,175,0))
			else
				_parent=self.view.shopView.ScrollView_2.ScrollView
				localPos=_parent.Viewport.Content.gameObject.transform:TransformPoint(item.gameObject.transform.localPosition+Vector3(80,-100,0))
			end
 
            local createPos=_parent.fx_root.transform:InverseTransformPoint(localPos)
            
			local o=self:playEffect("fx_shop_strat",createPos,_parent.fx_root.gameObject)
			local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
			UnityEngine.Object.Destroy(o, _obj.main.duration)
			item.ItemIcon.gameObject.transform:DOLocalRotate(Vector3.zero,0.2):OnComplete(function()
				item.ItemIcon.gameObject.transform:DOScale(Vector3.one,0.1):OnComplete(function()
					if self.gameObject and item then
						item.name[UI.Text].color={r=0,g=0,b=0,a=1}
						item.mark.Image[UI.Image].color={r=1,g=1,b=1,a=1}					
					end
				end)
			end):SetDelay(0.2)
		end
	end)
end

function View:refItemInfo(info,item,index)
	--self.SelectItemInfo=info--设置功能
	local infoPanel = self.view.shopView.ScrollView_2.detailInfo
	infoPanel.name[UI.Text].text = info.cfg1.name
	local sub_type = info.cfg1.cfg.sub_type and info.cfg1.cfg.sub_type or info.cfg1.cfg.type
	local tipConfig = TipConfig.GetShowItemDescConfig(sub_type)
	infoPanel.desc:SetActive(not not tipConfig)
	if tipConfig then
		local useDesc = tipConfig.des
		infoPanel.desc[UI.Text].text=tostring(useDesc)
	else
		print("tipConfig is nil,sub_type",sub_type)
	end

	infoPanel.consume.num[UI.Text].text = math.floor(info._sell_price)
	infoPanel.consume.Icon[UI.Image]:LoadSprite("icon/"..info.cfg2.icon.."_small")

	local off_y=infoPanel.consume.Icon[UnityEngine.RectTransform].sizeDelta .y
	utils.SGKTools.ShowItemNameTip(infoPanel.consume.Icon,info.cfg2.name,1,off_y)

	local player=playerModule.Get()

	local showCfg=ItemModule.GetShowItemCfg(info.cfg1.id)
	--sub_type 72头像框   73 "心悦头衔"  74"心悦挂件" 75 "心悦足迹" 76气泡框 
	if sub_type==73 or sub_type==74  or sub_type==75 or sub_type==70 then	
		infoPanel.ItemRoot.Slot.gameObject:SetActive(true)
		infoPanel.ItemRoot.playerIcon.gameObject:SetActive(false)
		infoPanel.ItemRoot.talkFrame.gameObject:SetActive(false)

		local SlotItem=infoPanel.ItemRoot.Slot:GetComponent(typeof(CS.FormationSlotItem))
		utils.PlayerInfoHelper.GetPlayerAddData(0,nil,function (addData)
	        if self.gameObject then
				SlotItem:UpdateSkeleton(tostring(addData.ActorShow))
	        end
	    end)
		
		infoPanel.ItemRoot.Slot.honor.gameObject:SetActive(false)
		infoPanel.ItemRoot.Slot.showItem.gameObject:SetActive(false)	
		infoPanel.ItemRoot.Slot.Widget.gameObject:SetActive(false)
		infoPanel.ItemRoot.Slot.footPrint.gameObject:SetActive(false)

		if sub_type==73  then		
			local showIcon=nil
			if info.cfg1.sub_type==73 then
				showIcon=infoPanel.ItemRoot.Slot.honor
			else
				showIcon=infoPanel.ItemRoot.Slot.showItem
			end
			showIcon.gameObject:SetActive(true)
			showIcon[UI.Image]:LoadSprite("icon/"..showCfg.effect)
			infoPanel.ItemRoot.Slot.spine:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic)).AnimationState:SetAnimation(0,"idle1",true);			
		elseif sub_type==75 or sub_type==70  or sub_type==74 then
			local effectNode=nil
			if sub_type==74 then
				effectNode=infoPanel.ItemRoot.Slot.Widget
				infoPanel.ItemRoot.Slot.spine:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic)).AnimationState:SetAnimation(0,"idle1",true);
			else
				effectNode=infoPanel.ItemRoot.Slot.footPrint
				infoPanel.ItemRoot.Slot.spine:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic)).AnimationState:SetAnimation(0,"run2",true);
			end
			effectNode:SetActive(true)

			if self.effect then
				CS.UnityEngine.GameObject.Destroy(self.effect)
			end
			if showCfg.effect_type==2 then--effect
		        self.effect=self:playEffect(showCfg.effect,Vector3(20, -30, -10),effectNode.effect.transform,Vector3(90, 0, 0),150,"UI",30000)  
		    else
		    	local showIcon=infoPanel.ItemRoot.Slot.showItem
		    	showIcon.gameObject:SetActive(true)
				showIcon[UI.Image]:LoadSprite("icon/"..showCfg.effect)
		    end
		end
	elseif sub_type==72  then
		infoPanel.ItemRoot.Slot.gameObject:SetActive(false)
		infoPanel.ItemRoot.talkFrame.gameObject:SetActive(false)
		infoPanel.ItemRoot.playerIcon.gameObject:SetActive(true)
		infoPanel.ItemRoot.playerIcon.playerFrame[UI.Image]:LoadSprite("icon/" ..showCfg.effect)
		infoPanel.ItemRoot.playerIcon.CharacterIcon[SGK.CharacterIcon]:SetInfo(player,true)
		infoPanel.ItemRoot.playerIcon.CharacterIcon.Level.gameObject:SetActive(false)
	elseif sub_type==76 then
		infoPanel.ItemRoot.Slot.gameObject:SetActive(false)
		infoPanel.ItemRoot.playerIcon.gameObject:SetActive(false)
		infoPanel.ItemRoot.talkFrame.gameObject:SetActive(true)
		infoPanel.ItemRoot.talkFrame[UI.Image]:LoadSprite("icon/" ..showCfg.effect)
		infoPanel.ItemRoot.talkFrame.Text[UI.Text].text="你好啊！"
	end
	local haveNum=self:GetProductCount(info.cfg1.type,info.cfg1.id)--拥有数量
	infoPanel.buyBtn[CS.UGUIClickEventListener].interactable=info.product_count>=1 and haveNum<1

	CS.UGUIClickEventListener.Get(infoPanel.buyBtn.gameObject).onClick = function (obj)
		local sellPrice=info._sell_price
		local case1=ItemModule.GetItemCount(info.consume_item_id1)>=sellPrice 

		if case1  then
			self.BuyNum=1
			SetItemTipsStateAndShowTips(false)

			self.view.ShoppingMask.gameObject:SetActive(true)

			infoPanel.buyBtn[CS.UGUIClickEventListener].interactable=false
			ShopModule.Buy(self.curID,info.gid,self.BuyNum);

			self.ShoppingTab={info,item,index}

			if info.product_count -self.BuyNum<1 then
				item.mark.gameObject:SetActive(true)
			end
		else
			showDlgError(nil,"货币不足");
		end
	end
end

function View:OnClickRefreshBtn()
	if self.refreshCousume[self.curID] and next(self.refreshCousume[self.curID])~=nil then
		if self.curID~=32 and self.curID~=33 then
			--[[--可刷新 判断
			local canRefresh=false
			for k,v in pairs(self.shoplist[self.curID]) do
				-- ERROR_LOG(sprinttb(v))
				if  v.product_count<1 then--存量为0 才可刷新
					canRefresh=true
				end
			end

			if canRefresh then
				self:refRefreshPanel()
			else
				showDlgError(nil,"当前货架已满，不需要进货~");
			end
			--]]
			--6/22 brand 要求 移除刷新条件
			self:refRefreshPanel()

		else
			self:refRefreshPanel()
		end
	end
end

function View:refRefreshPanel()
	local _consumeItem = ItemHelper.Get(self.refreshCousume[self.curID][1],self.refreshCousume[self.curID][2])
	local itemCount = ItemModule.GetItemCount(self.refreshCousume[self.curID][2]);
	if itemCount>=self.refreshCousume[self.curID][3] then

		self.root.EnsureRefreshPanel.gameObject:SetActive(true)
		local _EnsurePanel=	self.root.EnsureRefreshPanel.Dialog.Content

		self.root.EnsureRefreshPanel.Dialog.Title[UI.Text].text=(self.curID==32 or self.curID==33) and "进货" or "补货"

		_EnsurePanel.tip[UI.Text].text = SGK.Localize:getInstance():getValue("shop_refresh_tips1")
		_EnsurePanel.Text_left[UI.Text].text = SGK.Localize:getInstance():getValue("shop_refresh_tips2")
		
		local _consumeItem=ItemHelper.Get(self.refreshCousume[self.curID][1],self.refreshCousume[self.curID][2])
		local itemCount = ItemModule.GetItemCount(self.refreshCousume[self.curID][2]);
		
		_EnsurePanel.Icon[UI.Image]:LoadSprite("icon/".._consumeItem.icon.."_small")
		_EnsurePanel.Text_right[UI.Text].text = SGK.Localize:getInstance():getValue("shop_refresh_tips3",itemCount)
		_EnsurePanel.confirmBtn.Text[UI.Text].text = (self.curID==32 or self.curID==33) and "进货" or "补货"

		CS.UGUIClickEventListener.Get(_EnsurePanel.confirmBtn.gameObject).onClick = function (obj)
			ShopModule.Refresh(self.curID,self.refreshCousume[self.curID][1],self.refreshCousume[self.curID][2],self.refreshCousume[self.curID][3]);
			self.root.EnsureRefreshPanel.gameObject:SetActive(false)
		end

		CS.UGUIClickEventListener.Get(_EnsurePanel.cancelBtn.gameObject).onClick = function (obj)
			self.root.EnsureRefreshPanel.gameObject:SetActive(false)
		end

		CS.UGUIClickEventListener.Get(self.root.EnsureRefreshPanel.Dialog.Close.gameObject).onClick = function (obj)
			self.root.EnsureRefreshPanel.gameObject:SetActive(false)
		end
		
		CS.UGUIClickEventListener.Get(self.root.EnsureRefreshPanel.mask.gameObject).onClick = function (obj)
			self.root.EnsureRefreshPanel.gameObject:SetActive(false)
		end
	else
		DialogStack.PushPrefStact("ItemDetailFrame", {id = self.refreshCousume[self.curID][2],type = self.refreshCousume[self.curID][1],InItemBag = 2})
	end
end

function View:UpdateInfo(type,id,count,storage)
	if self.operate_obj ~= nil then
		local item = self.operate_obj;
		local cfg = ItemHelper.Get(type,id)

		if self.curID==9 then
			self.view.shopView.ScrollView_2.detailInfo.buyBtn[CS.UGUIClickEventListener].interactable = count >= 1
			item.mark.gameObject:SetActive(count<1)
		end
		self.operate_obj = nil;
	end
end

local startShowCountCfgId = 601 
function View:sortList(shoplist)
	local list = {};
	local startCount,AddCount =999,999
	if self.curID == UnionShopId then
		local _unionTechCfg = module.unionScienceModule.GetScienceCfg(nil,UnionTechTypes.AddProductType,UnionTechesLv[UnionTechTypes.AddProductType])
		startCount = CommonConfig.Get(startShowCountCfgId) and CommonConfig.Get(startShowCountCfgId).para1 or 999
		AddCount = _unionTechCfg and _unionTechCfg.param or 0
	end
	--商店商品增加玩家等级限制
	local _playerLevel=module.playerModule.IsDataExist(module.playerModule.GetSelfID()).level
	for _,v in pairs(shoplist) do
		if v.lv_min<=_playerLevel and v.lv_max>=_playerLevel then
			if v.shop_id == UnionShopId then
				--商品显示数量增加科技等级限制
				-- if v.show_Idx <= startCount +AddCount  then
				-- 	table.insert(list, v);
				-- end
				if v.show_Idx > startCount +AddCount then
					v.product_item_id = 10000
				end
				table.insert(list, v)
			else
				table.insert(list, v);
			end
		end
	end
	--增加商品按gid排序
	table.sort(list,function (a, b)
		local a_real = a.product_item_id~= 10000
		local b_real = b.product_item_id~= 10000
		if a_real ~= b_real then
			return a_real
		end
		return a.gid < b.gid;
	end)
	return list;
end

function View:GetProductCount(type ,id)
	local itemCount = 0;
	if type ==ItemHelper.TYPE.HERO then
		if heroModule.GetManager():Get(id) ~= nil then
			itemCount = 1;
		else
			itemCount = 0;
		end
	elseif type ==ItemHelper.TYPE.EQUIPMENT or type == ItemHelper.TYPE.INSCRIPTION then
		itemCount =self:GetEquipmentCount(id)
	else
		itemCount = ItemModule.GetItemCount(id);
	end
	return itemCount;
end

function View:GetEquipmentCount(id)
	if not self.LocalEquipList then
		self.LocalEquipList={}
		local _equipList=equipmentModule.OneselfEquipMentTab()
		for k,v in pairs(_equipList) do
			self.LocalEquipList[v.id]=self.LocalEquipList[v.id] and self.LocalEquipList[v.id]+1 or 1
		end
	end
	return self.LocalEquipList[id] and 0
end

function View:GetTotalConsume(productCfg,num)
	local totalConsume=0
	local _floatPriceTab = ShopModule.GetPriceByNum(productCfg.gid)
	if _floatPriceTab then
		for i=1,num do
			local _price = _floatPriceTab[productCfg.buy_count+i].sellPrice
			totalConsume = totalConsume+_price
		end
	else
		totalConsume = productCfg.sell_price*num
	end
	return totalConsume
end

function View:playEffect(effectName,position,node,rotation,scale,layerName,sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName..".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        transform.localRotation =rotation and  Quaternion.Euler(rotation) or Quaternion.identity;
        transform.localScale = scale and scale*Vector3.one or Vector3.one
        if layerName then
            o.layer = UnityEngine.LayerMask.NameToLayer(layerName);
            for i = 0,transform.childCount-1 do
                transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer(layerName);
            end
        end
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
    end
    return o
end

function View:Update()
	if self.next_Refresh_time and self.next_Refresh_time[self.curID] then
		local _t = self.next_Refresh_time[self.curID]-Time.now();
		local _time = string.format("%02d",math.floor(math.floor(math.floor(_t/60)/60)%24))..":"..string.format("%02d",math.floor(math.floor(_t/60)%60))..":"..string.format("%02d",math.floor(_t%60))
		
		if self.curID~= 15 then
			if self.curID == 1 then
				self.view.midView.refresh.surplus[UI.Text]:TextFormat("<color=#3BFFBCFF>{0}</color>后进货",_time)
			elseif self.curID == 9 then
				self.view.midView.refresh.surplus[UI.Text]:TextFormat("每天<color=#3BFFBCFF>{0}</color>刷新\n<color=#3BFFBCFF>{1}</color>后刷新",os.date("%X",self.next_Refresh_time[self.curID]),_time)
			else
				self.view.midView.refresh.surplus[UI.Text]:TextFormat("每天<color=#3BFFBCFF>{0}</color>进货\n<color=#3BFFBCFF>{1}</color>后进货",os.date("%X",self.next_Refresh_time[self.curID]),_time)
			end
		end

		if _t<=0 then
			ShopModule.GetManager(self.curID)
		end
	end
end

--适应超长屏UI填充
function View:UpdateBetterScreenSize(resourcesBarObj)
	if resourcesBarObj then
		local resourcesBar = CS.SGK.UIReference.Setup(resourcesBarObj)
		if resourcesBar then
			local off_top = resourcesBar.UGUIResourceBar.TopBar[UnityEngine.RectTransform].rect.height
			local off_bottom = resourcesBar.UGUIResourceBar.BottomBar[UnityEngine.RectTransform].rect.height
			local off_H = (self.root[UnityEngine.RectTransform].rect.height-self.root.showView[UnityEngine.RectTransform].rect.height)/2

			if off_top and off_bottom then
				self.root.top[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical, off_H+ off_top)
				self.root.bottom[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical, off_H+off_bottom)
			end
		end
	end
end

function View:OnDestroy( ... )
	if not self.resetTopResourcesIcon then
		DispatchEvent("CurrencyRef")
	end
	
	self.savedValues.ShopId=self.curID;
	-- self.SelectItem=nil
	self.SelectId=nil
	
	SetItemTipsStateAndShowTips(true)
	SGK.BackgroundMusicService.SwitchMusic();
end

function View:listEvent()	
	return {
		"SHOP_INFO_CHANGE",
		"SHOP_BUY_SUCCEED",
		"SHOP_BUY_FAILED",
		"SHOP_REFRESH_SUCCEED",
		"QUERY_SHOP_COMPLETE",
		"EQUIPMENT_INFO_CHANGE"
	}
end

function View:onEvent(event, ...)
	if event == "SHOP_INFO_CHANGE" then
		local data  = ...;
		local shoplist = ShopModule.GetManager(data.id);
		--print(data.id.."~~~~shoplist",sprinttb(shoplist))
		if shoplist ~= nil then
			self.shoplist[data.id] = self:sortList(shoplist.shoplist);
			self.canRefresh[data.id] = shoplist.refresh;
			self.refreshCousume[data.id]=shoplist.refreshCousume
			self.next_Refresh_time[data.id]=shoplist.next_fresh_time
			self:refreshShopView(self.shoplist[data.id],data.id);
		else
			showDlgError(nil,"商店列表为空"..data.id)
		end
	elseif event == "SHOP_BUY_SUCCEED"  then
		local info = ...;
		if self.ShoppingTab and self.ShoppingTab[1] and self.ShoppingTab[1].gid == info.gid then
			self:DoShopping(self.ShoppingTab[1],self.ShoppingTab[2],self.ShoppingTab[3],self.ShoppingTab[4])
			self.operate_obj =self.ShoppingTab[2];
			self.curIndex =self.ShoppingTab[3];
		end
		--防止帧数过低的连续点击
		self.view.buyDetailPanel.view.Btns.buyBtn[CS.UGUIClickEventListener].interactable=true
		self.view.shopView.ScrollView_2.detailInfo.buyBtn[CS.UGUIClickEventListener].interactable=true
		self.view.buyDetailPanel.gameObject:SetActive(false)

		local shoplist = ShopModule.GetManager(info.shop_id).shoplist;
		local productInfo = shoplist[info.gid];
		-- showDlgError(nil,"交易成功")
		if productInfo.product_item_type==43 or productInfo.product_item_type==45 then
			local _id =productInfo.product_item_id
			if not self.LocalEquipList then
				local num = self:GetEquipmentCount(_id)
			end
			self.LocalEquipList[_id] = self.LocalEquipList[_id] and self.LocalEquipList[_id]+1 or 1
		end
		self.shoplist[info.shop_id][self.curIndex].product_count = productInfo.product_count;
		self:UpdateInfo(productInfo.product_item_type,productInfo.product_item_id,productInfo.product_count,productInfo.storage);	
		self:updateRefreshTimes(self.curID);
	elseif event == "SHOP_BUY_FAILED" then
		self.operate_obj = nil;
		--防止帧数过低的连续点击
		self.view.buyDetailPanel.view.Btns.buyBtn[CS.UGUIClickEventListener].interactable=true
		self.view.shopView.ScrollView_2.detailInfo.buyBtn[CS.UGUIClickEventListener].interactable=true
		self.view.ShoppingMask.gameObject:SetActive(false)

		showDlgError(nil,"交易失败")
	elseif event == "SHOP_REFRESH_SUCCEED" then
		showDlgError(nil,SGK.Localize:getInstance():getValue("shop_refresh_sucess"))
		shop_data.refreshTimes[self.curID] = shop_data.refreshTimes[self.curID] + 1;
		self:updateRefreshTimes(self.curID);
	elseif event == "QUERY_SHOP_COMPLETE" then
		self:InitData();
	end
end

function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return View