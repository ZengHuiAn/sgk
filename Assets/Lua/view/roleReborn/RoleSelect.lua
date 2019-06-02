local HeroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local RoleRebornModule=require "module.RoleRebornModule";

local View = {}

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self:InitClick()
	self.order_list = {}
	if data.idx and data.idx == 2 then
		self.selectIdx = data.selectIdx
		self.view.root.tips[UI.Text].text = "选择要进行转化的碎片"
		self:UpFlagmentList()
	elseif data.idx and data.idx == 1 then
		self.view.root.tips[UI.Text].text = "选择要进行重生的角色"
		self:UpdateHeroList();
	end
end

function View:InitClick()
	CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick = function ()
		CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
	end
	CS.UGUIClickEventListener.Get(self.view.root.close.gameObject).onClick = function ()
		CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
	end
	self.view.root.middle.filter.DropdownItem[UnityEngine.UI.Dropdown].onValueChanged:AddListener(function (i)
        if i == 0 then
            self.filter = 0xffffffff;
        else
            self.filter = (1 << (i-1))
        end
        self:UpdateHeroList()
    end)
end

function View:UpFlagmentList()
	-- self.view.root.middle.ScrollView.Viewport.Content:SetActive(false)
	-- self.view.root.middle.ScrollView.Viewport.ContentFragment:SetActive(true)
	self.view.root.middle.filter:SetActive(false)

	self.checkImage = self.view.root.middle.Checked

	self.TotalTable = RoleRebornModule.GetTotal()
	self.viewTable = RoleRebornModule.ViewTableGet()

	ERROR_LOG("总表",sprinttb(self.TotalTable))
	ERROR_LOG("分表",sprinttb(self.viewTable))

	self.UIDragIconScript = self.view.root.middle.ScrollView.Viewport.Content[CS.ScrollViewContent]
	self.UIDragIconScript.pool = CS.GameObjectPool.GetPool("CommonIconPool");
	self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		self:refreshData(obj,idx)
	end)
	self:initScroll()
end

function View:initScroll()
	local itemList = ItemHelper.GetList(41, table.unpack({[1]=21}));
	self.item_list = self:SortTable(itemList)

	local selectCount = 0
	local selectid = 0
	if self.viewTable[self.selectIdx] then
		selectCount = self.viewTable[self.selectIdx].count
		selectid = self.viewTable[self.selectIdx].id
	end

	local Usedtab = {}
	for k,v in pairs(self.item_list) do
		local haveCount = module.ItemModule.GetItemCount(v.id)
		if haveCount == 0 then
			Usedtab[#Usedtab+1] = k
		else
			for j,l in pairs(self.TotalTable) do
				local num = l
				if v.id == selectid then
					num = num - selectCount
				end
				if v.id == j and num == haveCount then
					Usedtab[#Usedtab+1] = k
				end
			end
		end
	end
	for i=#Usedtab,1,-1 do
	 	table.remove(self.item_list,Usedtab[i])
	end 
	print("suipian",sprinttb(self.item_list))
	self.UIDragIconScript.DataCount = #self.item_list;
	self.UIDragIconScript:Refresh(true);

	-- self.view.NoItemPage.gameObject:SetActive(#self.item_list==0)
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

function  View:refreshData(Obj,idx)
	local Icon =CS.SGK.UIReference.Setup(Obj);
	local cfg   = self.item_list[idx+1]

	local haveCount = module.ItemModule.GetItemCount(cfg.id)

	local UsedNum = 0
	for k,v in pairs(self.viewTable) do
		if v.id == cfg.id and k ~= self.selectIdx then
			UsedNum = v.count + UsedNum
		end
	end
	
	local iconCount = haveCount - UsedNum
	if iconCount > 0 then
		utils.IconFrameHelper.UpdateIcon(cfg, Icon, {
			showName   = true,
			showDetail = false,
			showOwner  = true,

			count = iconCount,

			onClick = function ()
			--print("dianji",cfg.id)
				self:ClearSaveCheck()
				self.saveCheck = GetUIParent(self.checkImage.gameObject, Icon.transform)
				self.saveCheck.transform.localPosition =UnityEngine.Vector3.zero;
				self.saveCheck:SetActive(true)
				DialogStack.PushPref("roleReborn/FragmentAddCount", {id = cfg.id,max = iconCount},self.view.gameObject)
			end
		});
	else
		Icon:SetActive(false)
	end
	Icon[UnityEngine.RectTransform].localScale = UnityEngine.Vector3(0.8,0.8,1)
end

function View:ClearSaveCheck()
	if self.saveCheck then
		CS.UnityEngine.GameObject.Destroy(self.saveCheck.gameObject)
	end
end

function View:UpdateHeroList()
	if not self.online then
      --   if self.unionExplore then
      --       self.online = args.online or {0, 0, 0, 0, 0}
      --   else
    		-- if args and args.online and args.online[1] ~= 0 then
    		-- 	self.online = args.online;
    		-- else
    		-- 	print("111111111111")
    			self.online = {0, 0, 0, 0, 0};
    			for k, v in ipairs(HeroModule.GetManager():GetFormation()) do
    				self.online[k] = v or 0;
    			end
    		-- end
      --   end
	end
	self.view.root.middle.filter:SetActive(true)
	-- if not self.view.FormationPanel.gameObject.activeSelf then
	-- 	return;
	-- end

	local list = HeroModule.GetManager():GetAll()

	local order_list = {};

    local _otherList = {}
 --    if self.unionExplore then
 --        _otherList = self:getTempHeroList()
	-- end

	self.filter = self.filter or 0xffffff;
	for k, v in pairs(list) do
		if (_otherList[v.id] ~= 1) then
			local hero_element = v.type;
			if hero_element == 0 then hero_element = 64 end;
			if self.unionExplore then
				local cfg = module.ManorModule.GetManorNpcTable(v.id)

				if cfg then
					if (self.filter == nil) or ((hero_element & self.filter) ~= 0) then
						table.insert(order_list, {id = v.id, capacity = v.capacity, online = self:isHeroOnline(v.id)});
					end	
				end
			else
				if (self.filter == nil) or ((hero_element & self.filter) ~= 0) then
					table.insert(order_list, {id = v.id, capacity = v.capacity, online = self:isHeroOnline(v.id)});
				end
			end
        end
	end

	table.sort(order_list, function(a, b)
		if a.id == self.master then
			return true;
		end

		if b.id == self.master then
			return false;
		end

		if a.capacity ~= b.capacity then
			return a.capacity > b.capacity;
		end

		return a.id < b.id;
	end)
	local deletetab = {}
	for k,v in pairs(order_list) do
		if not self:isHeroOnline(v.id) then
			if self:notStageandStar(v.id) then
				deletetab[#deletetab+1] = k
			end
		end
	end
	for i=#deletetab,1,-1 do
	 	table.remove(order_list,deletetab[i])
	end
	local diff = true;
	if #self.order_list == #order_list then
		diff = false;
		for k, v in ipairs(order_list) do
			if self.order_list[k] ~= v.id then
				diff = true;
				break;
			end
		end
	end

	if diff then
		self.order_list = {}
		for _, v in ipairs(order_list) do
			if v.id ~=11000 then
				table.insert(self.order_list, v.id);
			end
		end

		local UIMultiScroller = self.view.root.middle.ScrollView.Viewport.Content[CS.ScrollViewContent];

		UIMultiScroller.RefreshIconCallback = function(obj, idx)
			obj:SetActive(true);
			local slot = SGK.UIReference.Setup(obj);
			local id = self.order_list[idx+1];
			self:UpdateIcon(slot, id)

			CS.UGUIClickEventListener.Get(slot.gameObject).onClick = function()

				if self:checkClick(id) then
					showDlgError(nil,SGK.Localize:getInstance():getValue("huoban_chongsheng_02"))
				else
					if not self.is_assists_view then
						utils.EventManager.getInstance():dispatch("OPEN_ROLE_REBORN",{RoleId = id})
						CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
					end
				end
			end
		end

		UIMultiScroller.DataCount = #self.order_list;
	else
		local UIMultiScroller = self.view.root.middle.ScrollView.Viewport.Content[CS.ScrollViewContent];
		for k, v in ipairs(self.order_list) do
			local obj = UIMultiScroller:GetItem(k-1);
			if obj then
				self:UpdateIcon(SGK.UIReference.Setup(obj), v)
			end
		end
	end
end

function View:checkClick(id)
	if self:isHeroOnline(id) then--or self:notStageandStar(id) then
		return true
	end
	return false
end

function View:UpdateIcon(view, id)
	--print("角色",id)
	local hero = ItemHelper.Get(ItemHelper.TYPE.HERO, id)
	if not hero then
		view.RoleItem.gameObject:SetActive(false);
		view[UnityEngine.UI.Image].color = UnityEngine.Color.white;
		return view;
	end

	view.RoleItem:SetActive(true);
	if view[UnityEngine.UI.Image] then
		view[UnityEngine.UI.Image].color = UnityEngine.Color.clear;
	end

	if view.RoleItem.IconFrame then
		--ERROR_LOG("type------>>", utils.ItemHelper.TYPE.HERO)
		utils.IconFrameHelper.Create(view.RoleItem.IconFrame, {
			uuid = hero.uuid, type = utils.ItemHelper.TYPE.HERO,  func = function ( obj )
				if self.unionExplore then
					local map_info = unionConfig.GetAllExploremapMessage(self.unionExplore)
					if map_info and (map_info.property == hero.cfg.type) then
					    view.RoleItem.bg:SetActive(true)
					else
						view.RoleItem.bg:SetActive(false)
					end
				elseif self.huntingElement ~= nil then
					if hero.element & self.huntingElement ~= 0 then
						obj[CS.SGK.CommonIcon].Owner = "manor/bg_jian";
					else
						obj[CS.SGK.CommonIcon].Owner = nil;
					end
				else
					if view.RoleItem.bg then
						view.RoleItem.bg:SetActive(false)
					end
				end
				
			end})
	end

	local flagIndex = 0;
	local isOnline = false;
	for _, v in ipairs(self.online) do
		if id == v then
			flagIndex = 1;
			break;
		end
	end

	if view.RoleItem and view.RoleItem.OnlineFlag then
		view.RoleItem.OnlineFlag:SetActive(flagIndex > 0);
		view.RoleItem.OnlineFlag[CS.UGUISpriteSelector].index = flagIndex;
	end

	if view.RoleItem and view.RoleItem.AssistInfo then
		view.RoleItem.AssistInfo:SetActive(self.is_assists_view)
		if self.is_assists_view then
			local weaponCfg = HeroWeaponLevelup.LoadWeapon(hero.weapon)[hero.weapon]
			view.RoleItem.AssistInfo.Text[UnityEngine.UI.Text].text = tostring(weaponCfg and weaponCfg.cfg.assistCd or "-");
		end
	end

	if view.RoleItem.PowerValue then
		view.RoleItem.PowerValue[UnityEngine.UI.Text].text = tostring(math.floor(hero.capacity));
	end

	if view.RoleItem.Name then
		view.RoleItem.Name[UnityEngine.UI.Text].text = hero.name;
	end

	if view.RoleItem.Type then
		local _profession = hero.profession;
		if hero.profession == 0 then
			local _cfg = module.TalentModule.GetSkillSwitchConfig(hero.id)
			local _idx = hero.property_value
			if _idx == 0 then
				_idx = 2
			end
			if _cfg[_idx] then
				_profession = _cfg[_idx].profession
			end
		end
		view.RoleItem.Type[UI.Image]:LoadSprite(string.format("propertyIcon/jiaobiao_%s", _profession))
	end
	return view;
end

function View:isHeroOnline(id)
	for _, v in ipairs(self.online) do
		if v == id then
			return true;
		end
	end
end

function View:notStageandStar(id)
	local heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, id)
	if heroCfg.level == 1 and heroCfg.stage == 0 and heroCfg.star == 0 then
		return true
	end
	return false 
end

function View:OnDestroy()
	print("清除check")
	self:ClearSaveCheck()
end

function View:listEvent()
    return {
    "CLOSE_ADD_COUNT",
    "SET_ADD_COUNT",
    }
end

function View:onEvent(event,data)
	if event == "CLOSE_ADD_COUNT" then
		self:ClearSaveCheck()
	elseif event == "SET_ADD_COUNT" then
		CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
	end
end


return View;