local HeroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local UserDefault = require "utils.UserDefault"
local talentModule = require "module.TalentModule"
local skillConfig = require "config.skill"
local OpenLevelConfig = require "config.openLevel"
local HeroWeaponLevelup = require "hero.HeroWeaponLevelup"
local TipCfg = require "config.TipConfig"
local ManorManufactureModule = require "module.ManorManufactureModule"
local PVPArenaModule = require "module.PVPArenaModule"
local TraditionalArenaModule = require "module.traditionalArenaModule"
local unionConfig = require "config.unionConfig"
local View = {}

function View:Start(args)
	--ERROR_LOG("argas====>>>",sprinttb(args))
	self.rootView = SGK.UIReference.Setup(self.gameObject);
    self.view = self.rootView.root

    self.rootView.root.BG.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_shangzhen_01")

	self.history_opt = "save";

	if (args and args.fromSelectMap) or self.savedValues.fromSelectMap then
		if self.view.DialogBG then
			self.view.DialogBG.gameObject:SetActive(false)
			self.savedValues.fromSelectMap = true
		end
	end
	self.HPSlider = SGK.ResourcesManager.Load("prefabs/expOnline/HPSlider.prefab");
	self.cutlist = module.expModule.GetCutList();
	
	if args and args.type then --type1 为正常战斗阵容 2为财富竞技场阵容 3为庄园评定战斗阵容 4为排位JJc
		self.type = args.type
	else
		self.type = 1;
	end

	self.role_num = args and args.role_num or 5;
	self.master = args and args.master or 11000;
    self.args = args

    if args then
		self.unionExplore = args.unionExplore
		self.huntingElement = args.huntingElement
		self.args_cut = args.cut;
    end
	if not self.online then
        if self.unionExplore then
            self.online = args.online or {0, 0, 0, 0, 0}
        else
    		if args and args.online and args.online[1] ~= 0 then
    			self.online = args.online;
    		else
    			self.online = {0, 0, 0, 0, 0};
    			for k, v in ipairs(HeroModule.GetManager():GetFormation()) do
    				self.online[k] = v or 0;
    			end
    		end
        end
	end
	self.order_list = {}
	self.attack_formation = {};
	self.defence_formation = {};
	for i=1,5 do
		self.attack_formation[i] = self.online[i];
		self.defence_formation[i] = self.online[i];
	end

	self.is_assists_view = false;
	self.is_defence_view = false;
	self.change_value = 0;
	self.refresh = false;
--[[
	if not self.select_index then
		for i = 1, #self.online do
			if self.online[i] == 0 then
				self.select_index = i;
				break;
			end
		end
	end

	self.select_index = self.select_index or 1;
--]]

	self.guide_obj = self.view.FormationPanel.OnlinePanel.Left.Slots.guide.gameObject;
	self.talk_obj = self.view.FormationPanel.OnlinePanel.Left.Slots.dialogue;
	self.talk_pos = 0;

	local FormationSlots = self.view.FormationPanel.OnlinePanel.Left.Slots.Heros[SGK.FormationSlots];
	FormationSlots.onOrderChange = function()
		for i = 1, 5 do
			self.online[i] = FormationSlots:Get(i-1);
		end
		self.assist_list = nil;
	end

	self.view.FormationPanel.OnlinePanel.Left.Buttons.Load:SetActive(self.type ~= 3);
	self.view.FormationPanel.OnlinePanel.Left.Buttons.Save:SetActive(self.type ~= 3);
    self.view.FormationPanel.OnlinePanel.Left.info:SetActive(self.type ~= 3);

	self.view.Toggles:SetActive(self.type == 2 or self.type == 4);
	self.view.FormationPanel.OnlinePanel.filter:SetActive(self.type ~= 3);
	self.view.FormationPanel.OnlinePanel.Fight:SetActive(self.type == 3);
	self.view.FormationPanel.OnlinePanel.Left.currentReward:SetActive(self.type==3)

	if self.type == 2 then
		local defence_formation = PVPArenaModule.GetPlayerFormation(2) and PVPArenaModule.GetPlayerFormation(2).formation;
		if defence_formation then
			for i=1,5 do
				self.defence_formation[i] = 0;
				if defence_formation[i] and defence_formation[i] ~= 0 then
					local hero = HeroModule.GetManager():GetByUuid(defence_formation[i]);
					if hero then
						self.defence_formation[i] = hero.id;
					end
				end
			end
		end
		self.view.Toggles.Online.Text[CS.UGUISpriteSelector].index = 1
		self.view.Toggles.Assist.Text[CS.UGUISpriteSelector].index = 1
	elseif self.type == 3 then
		self.view.FormationPanel.OnlinePanel.gameObject.transform.localPosition = Vector3(0, 120, 0);
		self.view.BG[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,970);
	elseif self.type == 4 then
		local defence_formation = TraditionalArenaModule.GetDefenceFormation()
		if defence_formation then
			for i=1,5 do
				self.defence_formation[i] = 0;
				if defence_formation[i] and defence_formation[i] ~= 0 then
					local hero = HeroModule.GetManager():GetByUuid(defence_formation[i]);
					if hero then
						self.defence_formation[i] = hero.id;
					end
				end
			end
		end
		self.view.Toggles.Online.Text[CS.UGUISpriteSelector].index = 1
		self.view.Toggles.Assist.Text[CS.UGUISpriteSelector].index = 1
	else
		self.view.Toggles.Online.Text[CS.UGUISpriteSelector].index = 0
		self.view.Toggles.Assist.Text[CS.UGUISpriteSelector].index = 0
	end

	CS.UGUIClickEventListener.Get(self.view.FormationPanel.OnlinePanel.Left.Buttons.Load.gameObject).onClick = function()
		self.rootView.root.BG.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_duquzhenrong_01")
		self:OpenLoadPanel();
	end

	CS.UGUIClickEventListener.Get(self.view.FormationPanel.OnlinePanel.Left.Buttons.Save.gameObject).onClick = function()
		self.rootView.root.BG.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_baocunzhenrong_01")
		self:OpenSavePanel();
	end


	CS.UGUIClickEventListener.Get(self.view.FormationPanel.OnlinePanel.Fight.gameObject).onClick = function()
		
		local heros = {};
		for i,v in ipairs(self.online) do
			if v ~= 0 then
				local hero = HeroModule.GetManager():Get(v);
				if hero then
                    if self.unionExplore then
                        table.insert(heros, hero.id)
                    else
                        table.insert(heros, hero.uuid)
                    end
				end
			end
		end
        if self.unionExplore then
            if self.args and self.args.unionExploreFunc then
                self.args.unionExploreFunc(heros)
            end
        else
    		DialogStack.Pop();
    		ManorManufactureModule.Get():StartFight(args.prop_type, heros[1], heros, args.condition);
        end
	end

	CS.UGUIClickEventListener.Get(self.view.FormationPanel.OnlinePanel.Left.Buttons.Refresh.gameObject).onClick = function()
		local heros = {};
		for i,v in ipairs(self.online) do
			if v ~= 0 then
				local hero = HeroModule.GetManager():Get(v);
				if hero then
					table.insert(heros, hero.uuid)
				end
			else
				table.insert(heros, 0)
			end
		end
		self.refresh = true;
		if self.type == 2 then
			PVPArenaModule.SetFormation(heros, 2);
		elseif self.type == 4 then
			TraditionalArenaModule.ChangeFormation(heros);
		end
	end

	CS.UGUIClickEventListener.Get(self.view.Toggles.Online.gameObject).onClick = function()
		
		if self.type == 2 or self.type == 4 then
			self.is_defence_view = false;
			for i=1,5 do
				self.defence_formation[i] = self.online[i];
				self.online[i] = self.attack_formation[i];
			end
			self:OpenFormationPanel();
		end
	end

	CS.UGUIClickEventListener.Get(self.view.Toggles.Assist.gameObject).onClick = function()
		if self.type == 2 or self.type == 4 then
			self.is_defence_view = true;
			for i=1,5 do
				self.attack_formation[i] = self.online[i];
				self.online[i] = self.defence_formation[i];
			end
			self:OpenFormationPanel();
		end
	end

	CS.UGUIClickEventListener.Get(self.view.BG.Close.gameObject).onClick = function()
		self.rootView.root.BG.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_shangzhen_01")
		if self.type == 4 or self.type == 2 then--排位JJc在保存阵容界面不直接关闭整个UI
			if not self.view.FormationPanel.gameObject.activeSelf then
				self.view.FormationPanel.gameObject:SetActive(true);
				self.view.FormationHistoryPanel.gameObject:SetActive(false);
				self.view.Toggles:SetActive(true);
				self:UpdateAllViews();
			else
				DialogStack.Pop();
			end
		else
			DialogStack.Pop();
		end
	end

	CS.UGUIClickEventListener.Get(self.rootView.CloseBG.gameObject).onClick = function()
		self.rootView.root.BG.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_shangzhen_01")
		if self.type == 4 or self.type == 2 then--排位JJc在保存阵容界面不直接关闭整个UI
			if not self.view.FormationPanel.gameObject.activeSelf then
				self.view.FormationPanel.gameObject:SetActive(true);
				self.view.FormationHistoryPanel.gameObject:SetActive(false);
				self.view.Toggles:SetActive(true);
				self:UpdateAllViews();
			else
				DialogStack.Pop();
			end
		else
			DialogStack.Pop();
		end
	end


	CS.UGUIClickEventListener.Get(self.view.FormationPanel.OnlinePanel.Left.Info2.Help.gameObject).onClick = function()
		local AssistDescCfg=TipCfg.GetAssistDescConfig(11001)--援助说明 function_id=11001
		if AssistDescCfg then
			self.view.DescPanel.Dialog.Content[UnityEngine.UI.Text].text = AssistDescCfg.info;
			self.view.DescPanel:SetActive(true)
		end
	end

	local filters = {
		{filter=64,name="无属性"}, -- 无
		{filter=4,name="火系",icon="sx_huo"}, -- 火
		{filter=2,name="水系",icon="sx_shui"}, -- 水
		{filter=1,name="风系",icon="sx_feng"}, -- 风
		{filter=8,name="土系",icon="sx_tu"}, -- 土
		{filter=32,name="暗系",icon="sx_an"}, -- 暗
		{filter=16,name="光系",icon="sx_guang"}, -- 光
	};

    self.view.FormationPanel.OnlinePanel.filter.DropdownItem[UnityEngine.UI.Dropdown].onValueChanged:AddListener(function (i)
        if i == 0 then
            self.filter = 0xffffffff;
        else
            self.filter = (1 << (i-1))
        end
        self:UpdateHeroList()
    end)

    local lastPage=SceneStack.savedValues.FormationLastPage and SceneStack.savedValues.FormationLastPage or 0
	if lastPage==1 then
		self.view.Toggles.Assist[UI.Toggle].isOn=true
	else
		self.view.Toggles.Online[UI.Toggle].isOn=true
		-- self:OpenAssistPanel()
	end

	self:UpdateAllViews();
	self:initGuide()
end

function View:OnEnable()
	self:UpdateAllViews();
end

function View:playOffLineHeroGuide()
	local _node = nil
	local _content = self.view.FormationPanel.OnlinePanel.Right.ScrollView.Viewport.Content
	for i = 1, _content.transform.childCount - 1 do
		local _obj = _content.transform:GetChild(i)
		local _view = CS.SGK.UIReference.Setup(_obj)
		if not _view.RoleItem.Checked.gameObject.activeInHierarchy then
			_node = _view.RoleItem.IconFrame.gameObject
			break
		end
	end

	if _node then
		module.guideModule.PlayByType(104,0.2,_node)
	end
end

function View:initGuide()
	utils.SGKTools.LockMapClick(true)
	SGK.Action.DelayTime.Create(0.3):OnComplete(function()
		utils.SGKTools.LockMapClick(false)
        module.guideModule.PlayByType(104,0.2)
        --self:playOffLineHeroGuide()
    end)
end

function View:UpdateIcon(view, id)
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
				elseif self.args_cut ~= nil then

					local iconframe = CS.SGK.UIReference.Setup(obj);
					local slider = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(self.HPSlider,obj.gameObject.transform));
					self:FreshItemColor(id,slider,obj);

					-- view.RoleItem.bg:SetActive(false)
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

	-- if self.type ~= 3 then	--庄园副本不显示援助标签
	-- 	local assist_list = self:GetAssistList(true);
	-- 	for _, v in ipairs(assist_list) do
	-- 		if id == v then
	-- 			flagIndex = 2;
	-- 		end
	-- 	end
	-- end

	if view.RoleItem.Checked then
		view.RoleItem.Checked:SetActive(flagIndex == (self.is_assists_view and 2 or 1));
		local selector = view.RoleItem[CS.UGUICanvasRendererColorSelector];
		if selector then
			selector.index = isOnline and 1 or 0;
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

function View:UpdateHeroStatus(id)
	if not self.view.FormationPanel.gameObject.activeSelf then
		return;
	end

	local online = false;
	for _, v in ipairs(self.online) do
		if v == id then
			online = true;
		end
	end

	for k, v in ipairs(self.order_list) do
		if v == id then
			local UIMultiScroller = self.view.FormationPanel.OnlinePanel.Right.ScrollView.Viewport.Content[CS.ScrollViewContent];
			local obj = UIMultiScroller:GetItem(k-1);
			if obj then
				local xx = SGK.UIReference.Setup(obj);
				xx.RoleItem.Checked:SetActive( online );
				if xx.RoleItem.OnlineFlag then
					local selector = xx.RoleItem.OnlineFlag[CS.UGUISpriteSelector];
					if selector then
						xx.RoleItem.OnlineFlag:SetActive(online);
						selector.index = online and 1 or 0;
					end
				end
			end
			break;
		end
	end
end

function View:UpdateSelect(idx)
	self.select_index = idx;
--[[
	self.view.FormationPanel.OnlinePanel.Left.Content[self.select_index][UnityEngine.UI.Toggle].isOn = true;

	self.view.FormationPanel.OnlinePanel.Left.Mark.buttons.gameObject:SetActive(self.online[self.select_index] ~= 0)

	self.view.FormationPanel.OnlinePanel.Left.Mark.buttons.TakeOff.gameObject:SetActive(false);
	self.view.FormationPanel.OnlinePanel.Left.Mark.buttons.View.gameObject:SetActive(false);

	if self.select_index == 1 then
		self.view.FormationPanel.OnlinePanel.Left.Mark.buttons.TakeOff.Text[UnityEngine.UI.Text]:TextFormat("选择钻石");
		self.view.FormationPanel.OnlinePanel.Left.Mark.buttons.TakeOff.Text[UnityEngine.UI.Text].color = UnityEngine.Color.white;
	else
		self.view.FormationPanel.OnlinePanel.Left.Mark.buttons.TakeOff.Text[UnityEngine.UI.Text]:TextFormat("卸下");
		self.view.FormationPanel.OnlinePanel.Left.Mark.buttons.TakeOff.Text[UnityEngine.UI.Text].color = UnityEngine.Color.red;
	end
	self.view.FormationPanel.OnlinePanel.Left.Mark.buttons.TakeOff.gameObject:SetActive(true);
	self.view.FormationPanel.OnlinePanel.Left.Mark.buttons.View.gameObject:SetActive(true);
--]]
end

function View:UpdateOnline(slot)
	
	if self.type==3 then

		local j=0
		local k =0
		local map_info = unionConfig.GetAllExploremapMessage(self.unionExplore)
		for i,v in ipairs(self.args.online) do
			if v ~=0 then
				local hero = ItemHelper.Get(ItemHelper.TYPE.HERO, v)
				j=j+1
				if map_info.property == hero.cfg.type then
					k=k+1
				end
			end
			
		end
		self.view.FormationPanel.OnlinePanel.Left.currentReward.additionValue[UI.Text].text="+" .. (k+j)*10 .."%" 
	end


	if not self.view.FormationPanel.gameObject.activeSelf then
		return;
	end
	local this = self;

	local capacity = 0

	local slotsView = self.view.FormationPanel.OnlinePanel.Left.Slots;
	local FormationSlots = slotsView.Heros[SGK.FormationSlots];

	local player = module.playerModule.Get();

	local list = self.online;
	if self.is_assists_view then
		list = self:GetAssistList(true)
	end

	if self.is_assists_view then
		self.view.FormationPanel.OnlinePanel.Left.Title1:SetActive(false);
		self.view.FormationPanel.OnlinePanel.Left.Title2:SetActive(false);
		self.view.FormationPanel.OnlinePanel.Left.CDTips:SetActive(true);
		self.view.FormationPanel.OnlinePanel.Left.Buttons.Save:SetActive(false);
        self.view.FormationPanel.OnlinePanel.Left.info:SetActive(false);
		self.view.FormationPanel.OnlinePanel.Left.Buttons.Load:SetActive(false);
		self.view.FormationPanel.OnlinePanel.Left.Lock:SetActive(false)

		local AssistDescCfg = TipCfg.GetAssistDescConfig(11001)--援助说明 function_id=11001
		self.view.FormationPanel.OnlinePanel.Left.Info2.Help:SetActive(true);
		self.view.FormationPanel.OnlinePanel.Left.Info2.Title[UnityEngine.UI.Text].text =
			"         " .. (AssistDescCfg and AssistDescCfg.tittle or "援助");
	else
		self.view.FormationPanel.OnlinePanel.Left.Title1:SetActive(true);
		self.view.FormationPanel.OnlinePanel.Left.Title2:SetActive(true);
		self.view.FormationPanel.OnlinePanel.Left.CDTips:SetActive(false);
		self.view.FormationPanel.OnlinePanel.Left.Buttons.Load:SetActive(self.type ~= 3);
		self.view.FormationPanel.OnlinePanel.Left.Buttons.Save:SetActive(self.type ~= 3);
        self.view.FormationPanel.OnlinePanel.Left.info:SetActive(self.type ~= 3);
		self.view.FormationPanel.OnlinePanel.Left.Buttons.Refresh:SetActive(self.is_defence_view and (self.type == 4));

		self.view.FormationPanel.OnlinePanel.Left.Lock:SetActive(true)
		self.view.FormationPanel.OnlinePanel.Left.Info2.Help:SetActive(false);

		self.view.FormationPanel.OnlinePanel.Left.Info2.Title[UnityEngine.UI.Text].text = "当前队伍";
	end

	local UP_Hero = {};
	for k = 1, 5 do
		local hero = HeroModule.GetManager():Get(list[k] or 0)
		local cfg, lockMove = nil, false;
		if self.is_assists_view then
			lockMove = true;
			cfg = OpenLevelConfig.GetCfg(1705+k);
			self.view.FormationPanel.OnlinePanel.Left.CDTips[k]:SetActive(hero ~= nil);
			if hero then
				local weaponCfg = HeroWeaponLevelup.LoadWeapon(hero.weapon)[hero.weapon]
				self.view.FormationPanel.OnlinePanel.Left.CDTips[k].Text[UnityEngine.UI.Text].text = tostring(weaponCfg and weaponCfg.cfg.assistCd or "-");
			end
		else
			lockMove = false
			cfg = k > 1 and OpenLevelConfig.GetCfg(1700+k);
		end

		if cfg and player.level < cfg.open_lev then
			lockMove = true
			slotsView.BG[k].Lock:SetActive(true);
			slotsView.LockTips[k]:SetActive(true);
			slotsView.LockTips[k]:TextFormat(string.format("%d级\n解锁", cfg.open_lev));
			hero = nil;
		else
			if k > self.role_num then
				lockMove = true
				slotsView.BG[k].Lock:SetActive(true);
				slotsView.LockTips[k]:SetActive(true);
				slotsView.LockTips[k]:TextFormat(string.format("限制%d人", self.role_num));
			else
				slotsView.BG[k].Lock:SetActive(false);
				slotsView.LockTips[k]:SetActive(false);
			end
		end

		FormationSlots:SetLock(k - 1, lockMove);

		local show_up_button = false;
		local hero = HeroModule.GetManager():Get(list[k])

		local _updateSkeletonFunc = function()	
			local _obj = FormationSlots:GetItem(k - 1)
			-- ERROR_LOG("_obj====>>>",_obj)
            local _view = SGK.UIReference.Setup(_obj)
            if hero and hero.capacity then
				utils.IconFrameHelper.Create(_view.item.IconFrame, {uuid = hero.uuid, type = 42, func = function (item)
					if self.huntingElement ~= nil then
						if hero.type & self.huntingElement ~= 0 then
							item[CS.SGK.CommonIcon].Owner = "manor/bg_jian";
						else
							item[CS.SGK.CommonIcon].Owner = nil;
						end
					end
				end})
            end
			_view.item.lock.lock:SetActive(lockMove)
			if lockMove then
				CS.UGUIClickEventListener.Get(_view.item.lock.gameObject).onClick = function()
					showDlgError(nil, string.format("%d级解锁", cfg.open_lev))
				end
			end
            _view.item.IconFrame:SetActive(hero and hero.capacity)
            _view.item.lock:SetActive(not _view.item.IconFrame.activeSelf)
            _view.spine:SetActive(false)
        end

		if hero and hero.capacity then
			capacity = capacity + hero.capacity;
			FormationSlots:Set(k - 1, hero.id, "", _updateSkeletonFunc);

			local gameObject = FormationSlots:GetItem(k - 1)
			local hero_id = hero.id;
			CS.UGUIClickEventListener.Get(gameObject, true).onClick = function()
				if self.type ~= 3 then
					self:onHeroSelected(hero_id)
					-- DialogStack.Push("HeroShowFrame",{heroid = hero_id}, "MapSceneUIRootMid")
				end
			end
		else
			FormationSlots:Set(k - 1, 0, "", _updateSkeletonFunc);
			local gameObject = FormationSlots:GetItem(k - 1)
			CS.UGUIClickEventListener.Get(gameObject, true).onClick = function()
				
			end
		end
	end

	if slot then
		self:UpdateTalk(slot)
	end
	FormationSlots:SetLock(0);
	self:UpdateGuideTip(UP_Hero);

	if self.type == 2 and self.is_defence_view then
		local visiable,change_value = PVPArenaModule.CheckCapacity();
		capacity = capacity - change_value;
	end
	self.view.FormationPanel.OnlinePanel.Left.Info2.PowerValue[UnityEngine.UI.Text].text = tostring(math.floor(capacity));
end

function View:UpdateGuideTip(data)
	if #data == 0 or HeroModule.GetManager():Get(11000).level >= 30 then
		self.guide_obj:SetActive(false);
		return;
	end
	local heros = HeroModule.GetManager():Get();
	local count = 0;
	for k,v in pairs(heros) do
		count = count + 1;
		if count > 2 then
			break;
		end
	end
	if count > 2 then
		local sorttb = data;
		table.sort(sorttb, function ( a,b )
			if a.hero.level ~= b.hero.level then
				return a.hero.level < b.hero.level
			end
			return a.pos < b.pos
		end)
		self.guide_obj.transform:SetParent(sorttb[1].obj.transform, false);
		self.guide_obj.transform.localPosition = Vector3(0,138,0);
		self.guide_obj:SetActive(true);
	end
end

function View:UpdateTalk(slot)
	if self.online[slot] == nil then
		return;
	end
	if self.online[slot] == 0 then
		if slot == self.talk_pos then
			if self.talk_obj[UnityEngine.CanvasGroup].alpha > 0 then
				CS.DG.Tweening.DOTween.Kill("show");
				CS.DG.Tweening.DOTween.Kill("hide");
				self.talk_obj[UnityEngine.CanvasGroup].alpha = 0;
			end
		end
		return;
	else
		if self.talk_obj[UnityEngine.CanvasGroup].alpha > 0 then
			CS.DG.Tweening.DOTween.Kill("show");
			CS.DG.Tweening.DOTween.Kill("hide");
			self.talk_obj[UnityEngine.CanvasGroup].alpha = 0;
		end
	end
	local talk_cfg = HeroModule.GetLineupTalk(self.online[slot]);
	if talk_cfg then
		local _talk_cfg = talk_cfg[math.random(1,#talk_cfg)];
		self.talk_obj.bg1:SetActive(_talk_cfg.type == 1)
		self.talk_obj.bg2:SetActive(_talk_cfg.type == 2)
		self.talk_obj.bg3:SetActive(_talk_cfg.type == 3)
		self.talk_obj.desc[UnityEngine.UI.Text]:TextFormat(_talk_cfg.des);

		local slot_obj = self.view.FormationPanel.OnlinePanel.Left.Slots.Heros[SGK.FormationSlots]:GetItem(slot - 1);
		self.talk_obj.gameObject.transform:SetParent(slot_obj.transform, false);
		self.talk_obj.gameObject.transform.localPosition = Vector3(0,68,0);
		self.talk_pos = slot;

		self.talk_obj[UnityEngine.CanvasGroup]:DOFade(1,0.5):OnComplete(function()
			self.talk_obj[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function()
				self.talk_obj.desc[UnityEngine.UI.Text].text = "";
			end):SetDelay(1.5):SetId("hide");
		end):SetId("show");
	end
end

function View:UpdateRedPoint()
	-- if self.type == 2 then
	-- 	local visiable,change_value = PVPArenaModule.CheckCapacity();
	-- 	self.change_value = change_value;
	-- 	self.view.FormationPanel.OnlinePanel.Left.Buttons.Refresh.tip:SetActive(visiable);
	-- 	self.view.Toggles.Assist.tip:SetActive(visiable);
	-- else
	if self.type == 4 then
		local visiable,change_value = TraditionalArenaModule.CheckCapacity()
		self.change_value = change_value;
		self.view.FormationPanel.OnlinePanel.Left.Buttons.Refresh.tip:SetActive(visiable);
		self.view.Toggles.Assist.tip:SetActive(visiable);
	end
end

function View:isHeroOnline(id)
	for _, v in ipairs(self.online) do
		if v == id then
			return true;
		end
	end
end

function View:getTempHeroList()
    local _tab = {}
    for k,v in pairs(module.unionActivityModule.ExploreManage:GetTempHeroTab()) do
        if k ~= self.unionExplore then
            for j,p in pairs(v) do
                _tab[p] = 1
            end
        end
    end
    return _tab
end

function View:UpdateHeroList()
	if not self.view.FormationPanel.gameObject.activeSelf then
		return;
	end

	local list = HeroModule.GetManager():GetAll()

	local order_list = {};

    local _otherList = {}
    if self.unionExplore then
        _otherList = self:getTempHeroList()
	end

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

		if self.args_cut then
			if self.args_cut then
				if self.cutlist[a.id] == 0 then
					return false
				end
				if self.cutlist[b.id] == 0 then
					return true
				end
			end
		end
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
			table.insert(self.order_list, v.id);
		end

		local this = self;

		local UIMultiScroller = self.view.FormationPanel.OnlinePanel.Right.ScrollView.Viewport.Content[CS.ScrollViewContent];

		UIMultiScroller.RefreshIconCallback = function(obj, idx)
			obj:SetActive(true);
			local slot = SGK.UIReference.Setup(obj);
			local id = self.order_list[idx+1];
			self:UpdateIcon(slot, id)

			CS.UGUIClickEventListener.Get(slot.gameObject).onClick = function()
				if self.args_cut and self.cutlist[id] == 0 then
					return showDlgError(nil,"人物已死亡");
				end

				if not self.is_assists_view then
					this:onHeroSelected(id);
				end
			end
		end

		UIMultiScroller.DataCount = #self.order_list;
	else
		local UIMultiScroller = self.view.FormationPanel.OnlinePanel.Right.ScrollView.Viewport.Content[CS.ScrollViewContent];
		for k, v in ipairs(self.order_list) do
			local obj = UIMultiScroller:GetItem(k-1);
			if obj then
				self:UpdateIcon(SGK.UIReference.Setup(obj), v)
			end
		end
	end
end

function View:ShowSkillInfo(index,id)
	local skill_cfg = skillConfig.GetConfig(id);
	if skill_cfg then
		self.UI_select_diam[index].info.Text[UnityEngine.UI.Text].text = skill_cfg.desc;
	else
		self.UI_select_diam[index].info.Text[UnityEngine.UI.Text]:TextFormat("{0}没有配置",id);
	end
	self.UI_select_diam[index].info:SetActive(true);
end

function View:UpdateSelectState(index)
	for i,v in ipairs(self.UI_select_diam) do
		if i == index then
			self.UI_select_diam[i].select:SetActive(true);
			self.UI_select_diam[i].Button[UnityEngine.UI.Button].interactable = false;
			self.UI_select_diam[i].Button.Text[UnityEngine.UI.Text]:TextFormat("使用中");
			local _, color =UnityEngine.ColorUtility.TryParseHtmlString('#00FFAFFF');
			self.UI_select_diam[i].Button.Text[UnityEngine.UI.Text].color = color;
		else
			self.UI_select_diam[i].select:SetActive(false);
			self.UI_select_diam[i].Button[UnityEngine.UI.Button].interactable = true;
			self.UI_select_diam[i].Button.Text[UnityEngine.UI.Text]:TextFormat("使用");
			self.UI_select_diam[i].Button.Text[UnityEngine.UI.Text].color = UnityEngine.Color.white;
		end
	end
end

function View:listEvent()
	return {
		"HERO_INFO_CHANGE",
		"server_respond_32",
		"HERO_DIAMOND_CHANGE",
        "LOCAL_GUIDE_CHANE",
		"ARENA_FORMATION_CHANGE",
		"ARENA_SET_FORMATION_FAILED",

		"TRADITIONAL_ARENA_FORMATION_CHANGE",
		"TRADITIONAL_ARENA_FORMATION_CHANGE_FAILD",
	}
end


function View:OnDestroy()
	self:SaveData();
	-- SceneStack.savedValues.FormationDropdownValue=self.dropdown.value;
	-- SceneStack.savedValues.FormationLastPage=self.view.AssistPanel.activeSelf and 1 or 0
end

function View:onEvent(event, ...)
	local data = ...;
	if event == "HERO_INFO_CHANGE" then
		self:UpdateOnline();
		self:UpdateHeroList();
	elseif event == "server_respond_32" then
		local data = select(2, ...);
		local err = data[2];
	elseif event == "HERO_DIAMOND_CHANGE" then
		showDlgError(nil, "切换成功")
		self:UpdateSelectState(data);
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
	elseif event == "ARENA_FORMATION_CHANGE" then
		if self.type == 2 then
			local lineup = data.lineup[1];
			if data.type == 1 then
				for i=1,5 do
					self.attack_formation[i] = 0;
					if lineup[i] then
						local hero = HeroModule.GetManager():GetByUuid(lineup[i]);
						if hero then
							self.attack_formation[i] = hero.id;
						end
					end
				end
				if not self.is_defence_view then
					for i=1,5 do
						self.online[i] = self.attack_formation[i];
					end
					self:UpdateAllViews();
				end
			elseif data.type == 2 then
				for i=1,5 do
					self.defence_formation[i] = 0;
					if lineup[i] then
						local hero = HeroModule.GetManager():GetByUuid(lineup[i]);
						if hero then
							self.defence_formation[i] = hero.id;
						end
					end
				end
				if self.is_defence_view then
					for i=1,5 do
						self.online[i] = self.defence_formation[i];
					end
					if self.refresh then
						self.refresh = false;
						local text = "";
						if self.change_value > 0 then
							text = "数据已刷新，战斗力+"..self.change_value;
						elseif self.change_value < 0 then
							text = "数据已刷新，战斗力"..self.change_value;
						else
							text = "已经是最新数据了";
						end
						showDlgError(nil, text)
					end
					self:UpdateAllViews();
				end
			end
		end
	elseif event == "ARENA_SET_FORMATION_FAILED" then
		if self.refresh then
			self.refresh = false;
			showDlgError(nil, "数据刷新失败")
		end
	elseif event == "TRADITIONAL_ARENA_FORMATION_CHANGE" then
		if self.is_defence_view then
			if self.refresh then
				self.refresh = false;
				local text = "";
				if self.change_value > 0 then
					text = "数据已刷新，战斗力+"..self.change_value;
				elseif self.change_value < 0 then
					text = "数据已刷新，战斗力"..self.change_value;
				else
					text = "已经是最新数据了";
				end
				showDlgError(nil, text)
			end
			self:UpdateAllViews();
		end
	elseif event == "TRADITIONAL_ARENA_FORMATION_CHANGE_FAILD" then
		if self.refresh then
			self.refresh = false;
			showDlgError(nil, "数据刷新失败")
		end
	end
end

function View:onHeroSelected(id)
	if id == self.master then
		return;
	end

	local player = module.playerModule.Get();

	local slot = nil;
	for k, v in ipairs(self.online) do
		local cfg = (k > 1 and OpenLevelConfig.GetCfg(1700+k)) or {open_lev = 0}
		if v == id then
			self.online[k] = 0;
			self.assist_list = nil;
			self:UpdateOnline(k);
			self:UpdateHeroList();
			-- self:UpdateHeroStatus(id);
			return;
		elseif v == 0 and not slot and player.level >= cfg.open_lev and k <= self.role_num then
			slot = k;
		end
	end

	if slot then
		self.online[slot] = id;
		self.assist_list = nil;
		self:UpdateOnline(slot);
		self:UpdateHeroList();
		-- self:UpdateHeroStatus(id);
	else
		self.last_full_tips = self.last_full_tips or 0;
		if os.time() - self.last_full_tips >= 3 then
			self.last_full_tips = os.time();
			showDlgError(nil, "没有空位了");
		end
	end


--[[
	if not self.online[self.select_index] then
		return;
	end

	local old_pos;
	for k, v in ipairs(self.online) do
		if v == id then
			if k == self.select_index then
				-- self:UpdateHeroStatus(id, 0);
				return;
			else
				old_pos = k;
				break;
			end
		end
	end

	if old_pos == 1 or self.select_index == 1 and self.online[1] ~= 0 then
		return;
	end

	local old_id = self.online[self.select_index];
	self:UpdateHeroStatus(old_id, old_pos or 0)
	self:UpdateHeroStatus(id, self.select_index);

	if old_id == 0 and id ~= 0 then
		for i = 1, 5 do
			local idx = (self.select_index + i - 1) % 5 + 1;
			if self.online[idx] == 0 then
				self:UpdateSelect(idx);
				break;
			end
		end
	end
--]]
	return true;
end

function View:CheckDiff(old,new)
	for i=1,5 do
		if (old[i] or 0) ~= (new[i] or 0) then
			return true;
		end
	end
	return false;
end

function View:SaveData( ... )
	if self.type == 1 then
		HeroModule.GetManager():SetFormation(self.online);
	elseif self.type == 2 then
		local atk,def = {0,0,0,0,0},{0,0,0,0,0};
		local atk_old = PVPArenaModule.GetPlayerFormation(1) and PVPArenaModule.GetPlayerFormation(1).formation or {0,0,0,0,0};
		local def_old = PVPArenaModule.GetPlayerFormation(2) and PVPArenaModule.GetPlayerFormation(2).formation or {0,0,0,0,0};
		if self.is_defence_view then
			for i=1,5 do
				self.defence_formation[i] = self.online[i]
			end
		else
			for i=1,5 do
				self.attack_formation[i] = self.online[i]
			end
		end
		for i,v in ipairs(self.attack_formation) do
			if v ~= 0 then
				local hero = HeroModule.GetManager():Get(v);
				if hero then
					atk[i] = hero.uuid;
				end
			else
				atk[i] = 0;
			end
		end
		for i,v in ipairs(self.defence_formation) do
			if v ~= 0 then
				local hero = HeroModule.GetManager():Get(v);
				if hero then
					def[i] = hero.uuid;
				end
			else
				def[i] = 0;
			end
		end
		if self:CheckDiff(atk_old, atk) then
			PVPArenaModule.SetFormation(atk, 1);
		end
		PVPArenaModule.SetFormation(def, 2);
		-- DispatchEvent("ARENA_DIALOG_CLOSE");
	elseif self.type == 4 then
		local atk,def = {0,0,0,0,0},{0,0,0,0,0};
		if self.is_defence_view then
			for i=1,5 do
				self.defence_formation[i] = self.online[i]
			end
		else
			for i=1,5 do
				self.attack_formation[i] = self.online[i]
			end
		end
		for i,v in ipairs(self.attack_formation) do
			atk[i] = v;
		end

		for i,v in ipairs(self.defence_formation) do
			if v ~= 0 then
				local hero = HeroModule.GetManager():Get(v);
				if hero then
					def[i] = hero.uuid;
				end
			else
				def[i] = 0;
			end
		end
		local atk_old = {0,0,0,0,0}
		for k, v in ipairs(HeroModule.GetManager():GetFormation()) do
			atk_old[k] = v or 0;
		end

		local def_old = TraditionalArenaModule.GetDefenceFormation()
		if self:CheckDiff(atk_old, atk) then
			HeroModule.GetManager():SetFormation(atk);
		end
		if self:CheckDiff(def_old, def) then
			TraditionalArenaModule.ChangeFormation(def);
		end
	end
end


function View:HistoryTitleSlash()
	for k, v in ipairs(self.view.FormationHistoryPanel.Head.Characters) do
		local slot = self.view.FormationHistoryPanel.Head.Characters[k];
		if slot then
			slot.mask[UnityEngine.UI.Image].color = {r= 1,g=1,b=1,a=1}
			slot.mask[UnityEngine.UI.Image]:DOFade(0,0.5):SetDelay(0.1*k)
			slot.mask.gameObject.transform.localScale = Vector3(1,1,1)
			slot.mask.gameObject.transform:DOScale(Vector3(1.2,1.2,1.2),0.5):SetDelay(0.1*k)
		end
	end
end

function View:OpenSavePanel()
	self.history_opt = "save";
	self.view.FormationPanel.gameObject:SetActive(false);
	self.view.FormationHistoryPanel.gameObject:SetActive(true);
	self.view.Toggles:SetActive(false);

	self:UpdateAllViews();
	-- self:HistoryTitleSlash();

    self:initGuide()
end

function View:OpenLoadPanel()

	-- if self.history_opt
	local saved_formations = UserDefault.Load("saved_formations", true);
	if #saved_formations == 0 then
		return showDlgError(nil, "还没有保存的队伍配置");
	end

	self.history_opt = "load";
	self.view.FormationPanel.gameObject:SetActive(false);
	self.view.FormationHistoryPanel.gameObject:SetActive(true);
	self.view.Toggles:SetActive(false);
	self:UpdateAllViews();

	-- self:HistoryTitleSlash();
end

function View:UpdateAllViews()
	self:UpdateOnline();
	self:UpdateHeroList();
	self:UpdateHistoryPanelOnline();
	self:UpdateHistoryPanelList();
	self:UpdateRedPoint();
end

function View:UpdateHistoryPanelOnline()
	if not self.view.FormationHistoryPanel.gameObject.activeSelf then
		return;
	end

	if self.history_opt == "save" then
		self.view.FormationHistoryPanel.Title.Text:TextFormat("<size=44>保</size>存阵容");
	else
		self.view.FormationHistoryPanel.Title.Text:TextFormat("<size=44>读</size>取阵容");
	end

	local this = self;

	local capacity = 0;
	local UIMultiScroller = self.view.FormationHistoryPanel.ScrollView.Viewport.Content[CS.ScrollViewContent];
	for k, v in ipairs(self.view.FormationHistoryPanel.Head.Characters) do
		local slot = self.view.FormationHistoryPanel.Head.Characters[k];
		if slot then
			local hero = HeroModule.GetManager():Get(self.online[k])
			if hero then
				capacity = capacity + hero.capacity;
			end
			self:UpdateIcon(slot, self.online[k], self.online).onClick = function() end
		end
	end
	self.view.FormationHistoryPanel.TotalPowerValue[UnityEngine.UI.Text].text = tostring(math.floor(capacity));
end

function View:UpdateHistoryPanelList()
	if not self.view.FormationHistoryPanel.gameObject.activeSelf then
		return;
	end

	local saved_formations = UserDefault.Load("saved_formations", true);

	if saved_formations[1] and saved_formations[1].name == nil then
		print("reset saved_formations");
		while #saved_formations > 0 do
			table.remove(saved_formations);
		end
	end

	local list = {}

	while self.history_opt == "save" and #saved_formations < 5 do
		table.insert(saved_formations, {name=string.format("阵容%d", #saved_formations+1), online= {0,0,0,0,0}});
	end

	for k, v in ipairs(saved_formations) do
		if self.history_opt == "save" then
			table.insert(list, k);
		else
			local xx = 0;
			for _, gid in ipairs(v.online) do
				xx = xx + gid;
			end
			if xx > 0 then
				table.insert(list, k);
			end
		end
	end

	local this = self;
	local UIMultiScroller = self.view.FormationHistoryPanel.ScrollView.Viewport.Content[CS.ScrollViewContent];
	UIMultiScroller.RefreshIconCallback = function(obj, idx)
		obj:SetActive(true);

		idx = list[idx+1];

		local online = saved_formations[idx].online;
		local view = SGK.UIReference.Setup(obj);
		local capacity = 0;

		for i, gid in ipairs(online) do
			local hero = HeroModule.GetManager():Get(gid);
			local slot = view.Characters[i];
			self:UpdateIcon(slot, gid);
			capacity = capacity + (hero and hero.capacity or 0)
		end

		view.TotalPowerValue[UnityEngine.UI.Text].text = tostring(math.floor(capacity));
		view.Order[UnityEngine.UI.Text].text = tostring(idx);
		view.Name[UnityEngine.UI.Text].text =  saved_formations[idx].name;
		if this.history_opt == "save" then
			view.Button[CS.UGUISpriteSelector].index = 0;
			view.Button.Text[UnityEngine.UI.Text]:TextFormat("保存");
		else
			view.Button[CS.UGUISpriteSelector].index = 1;
			view.Button.Text[UnityEngine.UI.Text]:TextFormat("读取");
		end

		CS.UGUIClickEventListener.Get(view.Button.gameObject).onClick = function()
			if this.history_opt == "save" then
				this.view.FormationHistoryPanel.NamePanel.gameObject:SetActive(true)

				local name = saved_formations[idx].name;

				this.view.FormationHistoryPanel.NamePanel.Dialog.Name[UnityEngine.UI.InputField].text = name;
				this.view.FormationHistoryPanel.NamePanel.Dialog.Name.Placeholder[UnityEngine.UI.Text].text = string.format("阵容%d", idx);

				CS.UGUIClickEventListener.Get(this.view.FormationHistoryPanel.NamePanel.Dialog.buttons.Save.gameObject).onClick = function()
					local text = this.view.FormationHistoryPanel.NamePanel.Dialog.Name[UnityEngine.UI.InputField].text;

  					text = string.gsub(text, "^%s*(.-)%s*$", "%1");

					if text == "" then
						text = string.format("阵容%d", idx);
					else
						local _, hit = WordFilter.check(text);
						if hit then
							showDlgError(nil,"无法使用该名称")
							return;
						end
					end

					saved_formations[idx].name = text;
					for k, v in pairs(this.online) do
						saved_formations[idx].online[k] = v
					end
					UIMultiScroller.DataCount = #saved_formations; -- reload
					this.view.FormationHistoryPanel.NamePanel.gameObject:SetActive(false);
				end
			else
				for k, v in pairs(saved_formations[idx].online) do
					this.online[k] = v
					this:UpdateHistoryPanelOnline();
				end
			end
		end
	end
	UIMultiScroller.DataCount = #list;
end

function View:Save()

end

function View:Load()

end

function View:GetAssistList(onlyHeroID)
	if self.assist_list == nil then
		local list = module.HeroModule.GetManager():GetAll()
		local assist_list = {};
		for k, v in pairs(list) do
			local placeholder = 0;
			for pos, id in ipairs(self.online) do
				if id == v.id then
					placeholder = pos;
					break;
				end
			end

			if placeholder == 0 then
				table.insert(assist_list, v)
			end
		end

		table.sort(assist_list, function(a, b)
			if a.capacity ~= b.capacity then
				return a.capacity > b.capacity;
			end

			if a.id ~= b.id then
				return a.id < b.id;
			end

			return a.uuid < b.uuid;
		end)

		local player = module.playerModule.Get();
		self.assist_list = {}
		for k = 1, 5 do
			if not assist_list[k] then
				break;
			end

			local cfg = OpenLevelConfig.GetCfg(1705+k);
			if cfg and player.level >= cfg.open_lev then
				table.insert(self.assist_list, assist_list[k])
			end
		end
	end

	local t = {}
	if onlyHeroID then
		for _, v in ipairs(self.assist_list) do
			table.insert(t, v.id);
		end
		return t;
	end

	return self.assist_list
	--return table.move (assist_list, 1, 5, 1, {});
end

function View:OpenFormationPanel()
	if not self.view.FormationPanel.activeSelf then
		self.is_assists_view = false;
		self.view.FormationHistoryPanel.gameObject:SetActive(false);
		self.view.FormationPanel.gameObject:SetActive(true);
		self.view.Toggles:SetActive(self.type == 2 or self.type == 4);
		self:UpdateAllViews();
	else
		self.is_assists_view = false;
		self:UpdateAllViews();
	end
end

-- function View:OpenAssistPanel()
-- 	if not self.view.FormationPanel.activeSelf then
-- 		self.is_assists_view = true;
-- 		self.view.FormationHistoryPanel.gameObject:SetActive(false);
-- 		self.view.FormationPanel.gameObject:SetActive(true);
-- 		self.view.Toggles:SetActive(true);
-- 		self:UpdateAllViews();
-- 	else
-- 		self.is_assists_view = true;
-- 		self:UpdateAllViews();
-- 	end
-- end

function View:FreshItemColor(id,slider,_item)
	-- self.cutlist
	local item = SGK.UIReference.Setup(_item);
	

	if self.cutlist and self.cutlist[id] then
		slider[UI.Slider].value = self.cutlist[id]/100;
	end

	item[CS.SGK.CommonIcon].colorGray = self.cutlist[id] == 0 ;
	-- item.Frame[UI.Image].material = self.cutlist[id] == 0 ;
end

function View:deActive()
	if self.view.FormationPanel.gameObject.activeSelf then
        utils.SGKTools.PlayDestroyAnim(self.gameObject)
		return true;
	end

--[[
	local UIMultiScroller = self.view.FormationPanel.OnlinePanel.Right.ScrollView[CS.UIMultiScroller];
	UIMultiScroller.IsTween = true
	local delay = 0.1

	for i = 1,#self.view.FormationPanel.OnlinePanel.Left.Content do
		local y = 64.5 - (i*145)
		self.view.FormationPanel.OnlinePanel.Left.Content[i].gameObject.transform.localPosition = Vector3(-159,y,0)
		self.view.FormationPanel.OnlinePanel.Left.Content[i].gameObject.transform:DOLocalMove(Vector3(159,y,0),0.3):SetDelay(delay*(i-1))
	end
--]]

	self.view.FormationHistoryPanel.gameObject:SetActive(false);
	self.view.FormationPanel.gameObject:SetActive(true);
	self.view.Toggles:SetActive(self.type == 2 or self.type == 4);
	self.order_list = {};
	self.assist_list = nil;
	self:UpdateAllViews();
    --utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return false;
end

return View;
