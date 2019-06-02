local ItemModule=require "module.ItemModule";
local EquipmentModule =require "module.equipmentModule"
local ItemHelper = require "utils.ItemHelper";
local RedDotModule = require "module.RedDotModule"
local CommonConfig = require "config.commonConfig"
local EquipmentConfig = require "config.equipmentConfig"
local Property = require "utils.Property"

local View={};
function View:Start()
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view.Content
	self.root.view.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_beibao_01")
	self:Init();
end

local qualityTextTab={"<color=#AEFFCEFF>绿色</color>","<color=#57D9FFFF>蓝色</color>","<color=#CAA7FFFF>紫色</color>","<color=#FFB821FF>橙色</color>","<color=#FF9A8BFF>红色</color>"}
function View:Init()

	CS.UGUIClickEventListener.Get(self.root.view.Close.gameObject).onClick = function (obj)
		DialogStack.Pop()
		-- local rects = self.root.view.gameObject:GetComponentsInChildren(typeof(UnityEngine.RectTransform))
		-- for i=1,100 do
		-- 	module.mazeModule.Interact(1,i);
		-- end
		local config = ItemModule.GetConfig(90003);
			
		print(sprinttb(ItemModule.GetItemType(41,config.type)),config.type)

		-- for i=0,rects.Length-1 do
		-- 	print(rects[i].name)
		-- end
		-- ERROR_LOG("========>>",sprinttb(module.playerModule.Get()));
		-- UnityEngine.Camera.main:DOShakeRotation(0.5, Vector3(5,6,7));
		-- SceneStack.EnterMap(602)
		-- utils.SGKTools.Map_Interact(2010100)
	end

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end

	self.UIDragIconScript = self.view.ScrollView.Viewport.Content[CS.ScrollViewContent]
	self.UIDragIconScript.pool = CS.GameObjectPool.GetPool("CommonIconPool");
	self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		self:refreshData(obj,idx)
	end)

	self.view.filter.Toggle[UI.Toggle].onValueChanged:AddListener(function ( b )
		self.State=(not not b)
		self:UpdateSelection();
	end)

	local item_x=self.view.pageContainer.Viewport.Content.tabPrefab[UnityEngine.RectTransform].rect.width
	local content_Width=self.view.pageContainer[UnityEngine.RectTransform].rect.width
	self.view.pageContainer[UI.ScrollRect].onValueChanged:AddListener(function (value)
		if #self.ItemBagOrder*item_x>content_Width then
			local off_x=self.view.pageContainer.Viewport.Content.transform.localPosition.x
			self.view.pageContainer.leftArrow.gameObject:SetActive(off_x<=-600 )
			self.view.pageContainer.rightArrow.gameObject:SetActive(off_x>=-800 )
		end
	end)
	self.ItemBagOrder=ItemModule.GetItemBagOrder()
	self:InitData();

	self.selected_tab = self.savedValues.Selected_tab or 1;
	self.selected_sub_tab = self.savedValues.Selected_sub_tab or {}
	self.State=false;
	self.SelectBreakStatus=false--切换页签时，默认为非选中状态

	self.DropdownListUI={}
	self.pageContentUI={}
	-- self.breakUpItemUI={}

	self:initRedDot()
	self:UpViewByBagOrder()
	

	self:UpdateSelection(self.selected_tab);

	self.icon_mark_new = self.view.ScrollView.MarkNew[UnityEngine.UI.Image].sprite;

	self:upRedDot()
end

function View:initRedDot()
	self.redDotTab = {}
	self.redDotTab[1] = RedDotModule.Type.Bag.Debris
	self.redDotTab[2] = RedDotModule.Type.Bag.Equip
	self.redDotTab[3] = RedDotModule.Type.Bag.Insc
	self.redDotTab[4] = RedDotModule.Type.Bag.Goods
	self.redDotTab[5] = RedDotModule.Type.Bag.Props
end

function View:InitData()
	local list=EquipmentModule.OneselfEquipMentTab()--玩家所有装备和铭文
	self.localEquipmentList={}
	for k,v in pairs(list) do
		self.localEquipmentList[k]=v
	end
end

function View:initScroll(itemList)
	self.item_list = self:SortTable(itemList)

	self.UIDragIconScript.DataCount = #self.item_list;
	self.UIDragIconScript:Refresh(true);

	self.view.NoItemPage.gameObject:SetActive(#self.item_list==0)
end

function  View:refreshData(Obj,idx)
	local Icon =CS.SGK.UIReference.Setup(Obj);
	local cfg   = self.item_list[idx+1]

	utils.IconFrameHelper.UpdateIcon(cfg, Icon, {
		showName   = true,
		showDetail = true,
		showOwner  = true,
		onClick = function ()
			DialogStack.PushPrefStact("ItemDetailFrame", {id = cfg.id,type = cfg.type,uuid=cfg.uuid,InItemBag=1},self.root.gameObject)
		end
	});
end

function View:SortTable(itemList)
	local ItemList={}
	--筛选分页签
	local idx=self.selected_sub_tab[self.selected_tab]
	if idx==1 then--全部显示
		for k,v in pairs(itemList) do
			table.insert(ItemList,v)
		end
	else--某一分页签
		local ItemBagOrder=self.ItemBagOrder[self.selected_tab]
		for k,v in pairs(itemList) do
			if v.type_Cfg.sub_pack==ItemBagOrder[idx-1] then
				table.insert(ItemList,v)
			end		
		end	
	end

	local _itemList={}
	local _pageCfg =self.ItemBagOrder[self.selected_tab]
	--筛选未装备 装备
	if self.State and (_pageCfg.type== ItemHelper.TYPE.EQUIPMENT or _pageCfg.type== ItemHelper.TYPE.INSCRIPTION) then
		for k,v in pairs(ItemList) do
			local equip=EquipmentModule.GetByUUID(v.uuid)
			if equip and equip.heroid== 0 or equip.isLock then
				table.insert(_itemList,v)
			end
		end
	else
		for i=#ItemList,1,-1 do
			if ItemList[i].count<=0 then
				table.remove(ItemList,i)
			end
		end
		_itemList=ItemList
	end

	table.sort(_itemList,function (a,b)	
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

	--新获取装备道具排序
	local tempList={}
	local _tempList={}

	for k,v in pairs(_itemList) do
		if self.GetNewItemList[v.id] or (v.uuid and self.GetNewItemList[v.uuid]) then
			table.insert(tempList,v)
		else
			table.insert(_tempList,v)
		end	
	end
	
	for i,v in ipairs(_tempList) do
		tempList[#tempList+1]=v
	end
	return tempList;
end

function View:UpdateSelection(main_tab,sub_tab)
	main_tab = main_tab or self.selected_tab or 1;
	sub_tab  = sub_tab or self.selected_sub_tab[main_tab]  or 1;

	local cfg =self.ItemBagOrder[main_tab]
	if not cfg then return end
	
	local itemList = ItemHelper.GetList(cfg.type, table.unpack(cfg.sub_type));

	for i=1,#self.ItemBagOrder do
		self.DropdownListUI[i].gameObject:SetActive(i==main_tab)
	
		local _pageTab =CS.SGK.UIReference.Setup(self.pageContentUI[i])
		_pageTab.arrow:SetActive(i==main_tab)
	end

	self.selected_tab=main_tab;
	self.selected_sub_tab[main_tab] = sub_tab;
	--新增物品列表
	self.GetNewItemList=self.GetNewItemList or {}
	if cfg.type== ItemHelper.TYPE.EQUIPMENT or cfg.type== ItemHelper.TYPE.INSCRIPTION then-- cfg.pack_order= -2- -装备--3  守护
		local _pack_order=cfg.type== ItemHelper.TYPE.EQUIPMENT and 0 or 1
		self.GetNewItemList=EquipmentModule.GetTempToBagList(_pack_order)
		--切换页签后，清空list
		EquipmentModule.ClearTempToBagList(_pack_order)
	else
		self.GetNewItemList=ItemModule.GetTempToBagList(cfg.pack_order)
		ItemModule.ClearTempToBagList(cfg.pack_order)
	end

	self:initScroll(itemList);
	self.UIDragIconScript:Refresh(true);
end

function View:UpViewByBagOrder()	
	self:UpDropDownList()
	self:UpPageContentList()

	local item_x=self.view.pageContainer.Viewport.Content.tabPrefab[UnityEngine.RectTransform].rect.width
	local content_Width=self.view.pageContainer[UnityEngine.RectTransform].rect.width
	if #self.ItemBagOrder*item_x>content_Width then
		self.view.pageContainer.leftArrow.gameObject:SetActive(false)
		self.view.pageContainer.rightArrow.gameObject:SetActive(true)
	end
end

local bagPageName = {["碎片"] = 0,["装备"] = 1,["水晶"] = 2,["道具"] = 3,}
function View:UpDropDownList()
	local prefab = self.view.filter.DropdownGroup.DropdownItem
	local parent = self.view.filter.DropdownGroup
	for i=1,#self.ItemBagOrder do
		local _DropDown = utils.SGKTools.GetCopyUIItem(parent,prefab,i)
		self.DropdownListUI[i] = _DropDown
		
		_DropDown[UnityEngine.UI.Dropdown]:ClearOptions();

		_DropDown.Label[UI.Text].text="全部"
		_DropDown[SGK.DropdownController]:AddOpotion("全部")
		for j=1,#self.ItemBagOrder[i] do
			_DropDown[SGK.DropdownController]:AddOpotion(self.ItemBagOrder[i][j])
		end
		_DropDown[UI.Dropdown].value=self.selected_sub_tab[i] and self.selected_sub_tab[i]-1 or 0
		_DropDown[UI.Dropdown].onValueChanged:AddListener(function (value)
			local sub_tab=value+1
			self:UpdateSelection(nil,sub_tab);
		end)
	end
end

function View:UpPageContentList()
	local prefab=self.view.pageContainer.Viewport.Content.tabPrefab
	local parent=self.view.pageContainer.Viewport.Content

	for i=1,#self.ItemBagOrder do
		local _pageTab = utils.SGKTools.GetCopyUIItem(parent,prefab,i+1)
		self.pageContentUI[i] = _pageTab

		local _pageName = self.ItemBagOrder[i].name
		local _pageIdx = bagPageName[_pageName] or 3
		_pageTab.Image[CS.UGUISpriteSelector].index = _pageIdx

		CS.UGUIClickEventListener.Get(_pageTab.gameObject,true).onClick = function (obj)
			RedDotModule.CloseRedDot(self.redDotTab[i])
			RedDotModule.CloseRedDot(self.redDotTab[self.selected_tab])		
	
			self:UpdateSelection(i);
				
			--每次切换Tab,刷新显示
			self.view.filter.Toggle.gameObject:SetActive(self.selected_tab==2)
		end
	end
	parent.Image[UI.Image].color = {r=1,g=1,b=1,a=0}
	self.selected_tab = self.selected_tab or 1 
	self.view.filter.Toggle.gameObject:SetActive(self.selected_tab==2)
	if self.pageContentUI[self.selected_tab] then
		parent.Image[UI.Image]:DOFade(1,0.05):OnComplete(function()
			parent.Image.transform.localPosition = self.pageContentUI[self.selected_tab].transform.localPosition
		end)
	end
end

function View:upRedDot()
	for i = 1, #self.ItemBagOrder do
		if self.redDotTab[i] then
			local _pageTab =CS.SGK.UIReference.Setup(self.pageContentUI[i].transform)
			_pageTab.tip.gameObject:SetActive(RedDotModule.GetStatus(self.redDotTab[i], nil, _pageTab.tip,true))
		end
	end
end

function View:deActive()
	self.UIDragIconScript:WillDestroy();
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:OnDestroy()
	self.savedValues.Selected_tab = self.selected_tab;
	self.savedValues.Selected_sub_tab = self.selected_sub_tab
	RedDotModule.CloseRedDot(self.redDotTab[self.selected_tab])
end

function View:listEvent()
	return{
		"ITEM_INFO_CHANGE",
		"EQUIPMENT_INFO_CHANGE",
		"GET_GIFT_ITEM",
		"LOCAL_REDDOT_BAG_CHANE",
		"LOCAL_REDDOT_CLOSE",
	}
end

function View:onEvent(event,data)
	if event == "ITEM_INFO_CHANGE" then
		if self.ItmeInfoStatus then return end
		self.ItmeInfoStatus = true
		SGK.Action.DelayTime.Create(0.5):OnComplete(function()
			self.ItmeInfoStatus=false
			self:UpdateSelection();
		end)
	elseif event == "EQUIPMENT_INFO_CHANGE"	 then
		if self.EquipInfoStatus then return end
		self.EquipInfoStatus = true
		SGK.Action.DelayTime.Create(0.2):OnComplete(function()
			self.EquipInfoStatus=false
			self:InitData()--装备信息变化  开宝箱获取装备刷新 拥有装备
			
			self:UpdateSelection();
		end)
	elseif event=="GET_GIFT_ITEM" then
		for i=1,#data do
			local cfg=ItemHelper.Get(data[i][1],data[i][2])
			if cfg.is_show ~=0 then
				showDlgError(nil,string.format("获取物品:%sx%d",cfg.name,data[i][3]))
			end
		end
	elseif event == "LOCAL_REDDOT_BAG_CHANE" or event == "LOCAL_REDDOT_CLOSE" then
		self:upRedDot()
	end
end


return View;
