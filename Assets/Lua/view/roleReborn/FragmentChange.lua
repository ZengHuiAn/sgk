local RoleRebornModule=require "module.RoleRebornModule";
local ItemHelper = require "utils.ItemHelper"

local View = {}

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self:initView()
end

function View:initView()
	self:initData()
	self:InitClick()
	self:UpView()
	self.view.bottom.get.Text[UI.Text].text = 0
end

function View:initData()
	self.shop = module.ShopModule.GetManager(3).shoplist
	--ERROR_LOG("3号商店",sprinttb(self.shop))
	self.buyList = {}
	self.allEffect = {}
	--RoleRebornModule.ClearViewTable()
end

function View:initBuy()
	self.viewTable = RoleRebornModule.ViewTableGet()
	self.TotalTable = RoleRebornModule.GetTotal()
	self.buyList = {}
	for i,j in pairs(self.TotalTable) do
		for k,v in pairs(self.shop) do
			if v.consume_item_id1 == i then
				self.buyList[#self.buyList+1] = {gid = v.gid , time = j,itemId = v.consume_item_id1}
			end
		end
	end
	--ERROR_LOG("购买列表",sprinttb(self.buyList))
	self:UpText()
end

function View:UpText()
	local rewardCount = 0
	for k,v in pairs(self.buyList) do
		--ERROR_LOG(self.shop[v.gid].product_item_value)
		rewardCount = rewardCount + self.shop[v.gid].product_item_value*v.time 
	end
	self.view.bottom.get.Text[UI.Text].text = rewardCount
end

function View:InitClick()
	for i=1,10 do
		CS.UGUIClickEventListener.Get(self.view.middle.root.itemList["item"..i].gameObject).onClick = function ()
			local itemList = self:GetList()
			if #itemList == 0 then
				showDlgError(nil,"背包内已无碎片")
			else
				self.SelectIdx = i
				local flag = self:checkIsAdd(i)
				if not flag then
					DialogStack.PushPref("roleReborn/RoleSelect",{idx = 2,selectIdx = i})
				else
					self:ClearIcon(i)
				end
			end
		end	
	end
	CS.UGUIClickEventListener.Get(self.view.bottom.change.gameObject).onClick = function ()

		if #self.buyList ~= 0 then
			if not self:checkQuality() then
				self:Buy()
			else
				DialogStack.PushPref("roleReborn/FragmentChangeTip")
			end
		else
			showDlgError(nil,"尚未放入碎片")
		end
	end
	CS.UGUIClickEventListener.Get(self.view.bottom.mutiChange.gameObject).onClick = function ()
		self.view.bottom.mutiChange[CS.UGUIClickEventListener].interactable = false
		self.view.bottom.change[CS.UGUIClickEventListener].interactable = false
		self:mutiAdd() 
	end
	CS.UGUIClickEventListener.Get(self.view.shop.gameObject).onClick = function ()
		DialogStack.PushPrefStact("ShopFrame") 
	end
	CS.UGUIClickEventListener.Get(self.view.help.gameObject).onClick = function ()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("huoban_zhuanhua_01"))
    end
	--module.ShopModule.Buy(3,self.selecttb[1].gid,1)
	--utils.IconFrameHelper.Create(item.IconFrame,{type = 41, id = info.id + 10000, count = _cfg.compose_num, showDetail = true})
end

function View:checkIsAdd(index)
	if self.viewTable and self.viewTable[index] then
		return true
	else
		return false
	end
end

function View:checkQuality()
	for k,v in pairs(self.buyList) do
		local cfg = module.ItemModule.GetConfig(v.itemId)
		if cfg.quality > 2 then
			return true
		end
	end
	return false
end

function View:Buy()
	for k,v in pairs(self.buyList) do
		module.ShopModule.Buy(3,v.gid,v.time) 
	end
	self.buyList = {}
end

function View:UpView()
	self.view.bottom.have.Text[UI.Text].text = module.ItemModule.GetItemCount(90008)
end

function View:ClearIcon(idx)
	local obj = self.view.middle.root.itemList["item"..idx].Image.IconFrame
	if obj.transform.childCount > 0 then
		CS.UnityEngine.GameObject.Destroy(obj.transform:GetChild(0).gameObject)
	end
	UnityEngine.GameObject.Destroy(self.allEffect[idx]);
	self.allEffect[idx] = nil
	RoleRebornModule.ViewTableAdd(idx,nil)
	self:initBuy()
end

function View:ClearAllIcon()
	for i=1,10 do
		self:ClearIcon(i)
	end
	-- for i,v in ipairs(self.allEffect) do
 --        UnityEngine.GameObject.Destroy(v);
 --    end
    self.allEffect = {};
end

function View:mutiAdd()
	self:ClearAllIcon()
	local itemList = self:GetList()
	local checkNum = 0
	--ERROR_LOG("一键列表",sprinttb(itemList))
	for i=1,10 > #itemList and #itemList or 10 do
		local cfg = itemList[#itemList+1-i-checkNum]
		local flag = true
		-- if module.ItemModule.GetItemCount(cfg.id) == 0 then
		-- 	checkNum = checkNum + 1 
		-- 	flag = false
		-- 	i = i - 1
		-- end
		if flag then
			--ERROR_LOG("一键item"..i,sprinttb(cfg))
			SGK.Action.DelayTime.Create(0.1*i):OnComplete(function()
				self:addIcon(i,{id = cfg.id,count = module.ItemModule.GetItemCount(cfg.id)})
				self:initBuy()
				self:UpText()
				if i == (10 > #itemList and #itemList or 10) then
					self.view.bottom.mutiChange[CS.UGUIClickEventListener].interactable = true
					self.view.bottom.change[CS.UGUIClickEventListener].interactable = true
				end
			end)
		end
	end
	if #itemList == 0 then
		showDlgError(nil,"背包内已无碎片")
		self.view.bottom.mutiChange[CS.UGUIClickEventListener].interactable = true
		self.view.bottom.change[CS.UGUIClickEventListener].interactable = true
	end
end

function View:GetList()
	local itemList = ItemHelper.GetList(41, table.unpack({[1]=21}));
	self.item_list = self:SortTable(itemList)
	local Usedtab = {}
	for k,v in pairs(self.item_list) do
		local haveCount = module.ItemModule.GetItemCount(v.id)
		if haveCount == 0 then
			Usedtab[#Usedtab+1] = k
		end
	end
	for i=#Usedtab,1,-1 do
	 	table.remove(self.item_list,Usedtab[i])
	end
	return itemList
end

function View:SortTable(itemList)
	table.sort(itemList,function (a,b)	
		if a.quality ~= b.quality then
			return a.quality > b.quality
		end		
		if a.uuid and b.uuid then
			local a_equip=EquipmentModule.GetByUUID(a.uuid)
			local b_equip=EquipmentModule.GetByUUID(b.uuid)

			if a_equip and b_equip then						
				if a_equip.level ~= b_equip.level then
					return a_equip.level > b_equip.level
				end

				local a_heroid_bool =not  not  (a_equip.heroid~=0)
				local b_heroid_bool =not  not  (b_equip.heroid~=0)
				
				if a_heroid_bool ~= b_heroid_bool then
					return a_heroid_bool
				end
				if a_equip.isLock ~= b_equip.isLock then
					return a_equip.isLock
				end	
			end
		else
			
		end
		if a.id ~=b.id then
			return a.id<b.id
		end	
	end);
	return itemList;
end

function View:OnDestroy()
	RoleRebornModule.ClearViewTable()
end

function View:addIcon(idx,data)
	utils.IconFrameHelper.Create(self.view.middle.root.itemList["item"..idx].Image.IconFrame,{type = 41, id = data.id, count = data.count,showDetail = false})	
	RoleRebornModule.ViewTableAdd(idx,{id = data.id, count = data.count})
	SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_box_gold_run.prefab",function (obj)
        local effect = GetUIParent(obj, self.view.middle.root.itemList["item"..idx].Image.transform)
        self.allEffect[idx] = effect;
        effect.transform.localPosition = Vector3.zero;
    end)
end

function View:listEvent()
    return {
    "SET_ADD_COUNT",
    "SHOP_BUY_SUCCEED",
    "Confirm_Change",
    }
end

function View:onEvent(event,data)
	if event == "SET_ADD_COUNT" then
		self:addIcon(self.SelectIdx,data)
		self:initBuy()
	elseif event == "SHOP_BUY_SUCCEED" then
		RoleRebornModule.ClearViewTable()
		self:ClearAllIcon()
		self:initView()
	elseif event == "Confirm_Change" then
		self:Buy()
	end
end


return View;