local heroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local ShopModule = require "module.ShopModule"
local RedDotModule = require "module.RedDotModule"
local MapHelper = require "utils.MapHelper"
local UserDefault = require "utils.UserDefault"

local View = {};

local profession_icon = {
	[1] = 0,
	[3] = 1,
	[4] = 2,
	[5] = 3,
	[10] = 4
}
local STATE = {
    NULL = 0,
    PIECE = 1,
    COMPOSE = 2,
    FREE = 3,
    WORKING = 4,
    ONLINE = 10,
    MASTER = 20,
};

local function SetVisiable(node, visiable)
	if visiable then
		node.color = UnityEngine.Color.white;
	else
		node.color = {r = 0, g = 0, b = 0, a = 0}
	end
end

function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self:InitData();
	self:InitView();
end

function View:InitData()
	local role_view_type = UserDefault.Load("role_view_type", true);
	self.viewType = role_view_type.type or 1;
	self.type = self.savedValues.type or 0;
	self.cfg = heroModule.GetConfig();
	self.manager = heroModule.GetManager();
	self.hero_data = {};
	self.heroInfo = {};
	self.sprites = {};
	self.heroInfo[0] = {};
	ShopModule.GetManager(6);

	local herolist = self.manager:GetAll();
	local infolist = {};
	for k,v in pairs(self.cfg) do
		local info = {};
		info.cfg = v;
		local product = ShopModule.GetManager(6, v.id) and ShopModule.GetManager(6, v.id)[1];

		if product then
			info.piece_id = product.consume_item_id1;
			info.piece_type = product.consume_item_type1;
			info.piece_count = ItemModule.GetItemCount(product.consume_item_id1);
			info.compose_count =product.consume_item_value1;
			info.product_gid = product.gid;
		else
			-- print(v.name.." 不存在合成商店中")
			info.piece_id = 0;
			info.piece_type = 0;
			info.piece_count = 0;
			info.compose_count = 0;
			info.product_gid = 0;
		end

		-- info.piece_count = ItemModule.GetItemCount(v.id + 10000);
		-- info.compose_count = ItemModule.GetConfig(v.id + 10000).compose_num;
		local hero = herolist[v.id];
		if hero ~= nil then
			info.hero = hero;
			info.state = STATE.FREE;
		else
			if info.piece_count > 0 then
				if info.piece_count >= info.compose_count then
					info.state = STATE.COMPOSE;
				else
					info.state = STATE.PIECE;
				end
			else
				info.state = STATE.NULL;
			end
		end
		infolist[v.id] = info;
	end

	for i,v in ipairs(self.manager:GetFormation()) do
		if infolist[v] ~= nil then
			infolist[v].state = STATE.ONLINE;
		end
	end
	infolist[11000].state = STATE.MASTER

	for k,v in pairs(infolist) do
		table.insert(self.heroInfo[0], v);
	end

	table.sort(self.heroInfo[0],function (a, b)
		if a.state ~= b.state then
			return a.state > b.state;
		end
		if a.hero ~= nil and b.hero ~= nil then
			if a.hero.capacity ~= b.hero.capacity then
				return a.hero.capacity > b.hero.capacity
			end
		else
			if a.cfg.role_stage ~= b.cfg.role_stage then
				return a.cfg.role_stage > b.cfg.role_stage
			end
			if a.piece_count ~= b.piece_count then
				return a.piece_count > b.piece_count
			end
		end
		return a.cfg.id < b.cfg.id
	end)

	for _,v in ipairs(self.heroInfo[0]) do
		local type = v.cfg.type;
		for i=1,8 do
			if (type & (1 << (i - 1))) ~= 0 then
				if self.heroInfo[i] == nil then
					self.heroInfo[i] = {};
				end
				table.insert(self.heroInfo[i], v);
			end
		end
		self:GetHeroData(v);
	end
	--print("@@self.heroInfo", sprinttb(self.heroInfo));

	local sprites = self.view.sprites[CS.UGUISpriteSelector].sprites
	for i=0,sprites.Length - 1 do
		self.sprites[sprites[i].name] = sprites[i];
	end
end

function View:InitView()
	CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform)
	for i=1,2 do
		local toggle = self.view.Toggles["Toggle"..i];
		CS.UGUIClickEventListener.Get(toggle.gameObject, true).onClick = function ( object )
			self.viewType = i;
			local role_view_type = UserDefault.Load("role_view_type", true);
			role_view_type.type = i;
			UserDefault.Save();
			self:UpdateScrollView();
		end
		toggle[UI.Toggle].isOn = self.viewType == i;
	end
	for i=0,6 do
		local toggle = self.view.Dropdown.Template.Viewport.Content["Item"..i];
		CS.UGUIClickEventListener.Get(toggle.gameObject, true).onClick = function ( object )
			self.type = i;
			self.savedValues.type = i;
			self.view.Dropdown.Template:SetActive(false);
			self.view.Dropdown.name[CS.UGUISpriteSelector].index = i;
			self.view.Dropdown.icon[CS.UGUISpriteSelector].index = i;
			self.tableview[CS.ScrollViewContent].DataCount = #self.heroInfo[self.type];
		end
		toggle[UI.Toggle].isOn = self.type == i;
	end
	self.view.Dropdown.name[CS.UGUISpriteSelector].index = self.type;
	self.view.Dropdown.icon[CS.UGUISpriteSelector].index = self.type;
	CS.UGUIClickEventListener.Get(self.view.Dropdown.click.gameObject, true).onClick = function ( object )
		self.view.Dropdown.Template:SetActive(not self.view.Dropdown.Template.activeSelf);
	end

	local main_character_icon = nil;
	local compose_character_icon = nil;
	self.view.smallView.Viewport.Content[CS.ScrollViewContent].RefreshIconCallback = function (obj,index)
		local item = CS.SGK.UIReference.Setup(obj);
		local heroInfo = self.heroInfo[self.type][index + 1];
		if heroInfo.state >= STATE.FREE then
			utils.IconFrameHelper.Create(item.IconFrame,{type = 42, uuid = heroInfo.hero.uuid})
		else
			utils.IconFrameHelper.Create(item.IconFrame,{type = 41, id = heroInfo.piece_id, func = function (_item)
				if heroInfo.state <= STATE.COMPOSE then
					_item[CS.SGK.CommonIcon]:SetMark("Mark1", item.lock[UnityEngine.UI.Image].sprite)
				else
					_item[CS.SGK.CommonIcon]:SetMark("Mark1", nil);
				end
			end})
		end

		item.tip.gameObject:SetActive(RedDotModule.GetStatus(RedDotModule.Type.Hero.Hero, heroInfo.cfg.id, item.tip))

		if heroInfo.state >= STATE.FREE then
			item.capacity.num[CS.UnityEngine.UI.Text].text = tostring(math.floor(heroInfo.hero.capacity));
			-- item.capacity.name[CS.UnityEngine.UI.Text]:TextFormat("<size=24>{0}</size>{1}",string.sub(heroInfo.cfg.name,1,3), string.sub(heroInfo.cfg.name,4));
			-- item.capacity.num[CS.UnityEngine.UI.Text].text = "+"..heroInfo.hero.stage
		end

		item.state:SetActive(heroInfo.state == STATE.ONLINE);
		item.capacity:SetActive(heroInfo.state >= STATE.FREE);
		item.Slider:SetActive(heroInfo.state < STATE.FREE);
		item.Slider[UnityEngine.UI.Slider].maxValue = heroInfo.compose_count;
		item.Slider[UnityEngine.UI.Slider].value = heroInfo.piece_count;
		item.Slider.price[CS.UnityEngine.UI.Text].text = heroInfo.piece_count.."/"..heroInfo.compose_count
		item.Slider.price[CS.UGUIColorSelector].index = (heroInfo.piece_count >= heroInfo.compose_count) and 1 or 0;
		-- item.lock:SetActive(heroInfo.state < STATE.COMPOSE)
		if heroInfo.state >= STATE.FREE then
			local _profession = heroInfo.cfg.profession;
			if heroInfo.cfg.profession == 0 then
				local _cfg = module.TalentModule.GetSkillSwitchConfig(heroInfo.cfg.id)
				local _idx = heroInfo.hero.property_value
				if _idx == 0 then
					_idx = 2
				end
				if _cfg[_idx] then
					_profession = _cfg[_idx].profession
				end
			end
			item.capacity.type[UnityEngine.UI.Image]:LoadSprite(string.format("propertyIcon/jiaobiao_%s", _profession));
		end
		if heroInfo.cfg.id == 11000 then
			main_character_icon = item;
		end

		if heroInfo.state == STATE.COMPOSE then
			compose_character_icon = item;
			item.Slider.compose:SetActive(true);
		else
			item.Slider.compose:SetActive(false);
		end
		obj:SetActive(true);

		CS.UGUIClickEventListener.Get(item.click.gameObject).onClick = function ( object )
			self:EnterRoleDetail(heroInfo)
		end
	end
	self.view.bigView.Viewport.Content[CS.ScrollViewContent].RefreshIconCallback = function (obj,index)
		local item = CS.SGK.UIReference.Setup(obj);
		local heroInfo = self.heroInfo[self.type][index + 1];
		-- item.icon[UnityEngine.UI.Image]:LoadSprite("icon/bigRole/"..heroInfo.cfg.mode, UnityEngine.Color.white)
		-- item.icon:SetActive(true);

		-- item.icon[UnityEngine.UI.Image]:LoadSprite("icon/bigRole/"..heroInfo.cfg.mode, function ()
		-- 	item.icon[UnityEngine.UI.Image].color = UnityEngine.Color.white;
		-- 	item.quality[UnityEngine.UI.Image].color = UnityEngine.Color.white;
		-- end)
		if self.sprites[tostring(heroInfo.cfg.mode)] then
			item.icon[UnityEngine.UI.Image].sprite = self.sprites[tostring(heroInfo.cfg.mode)];
		else
			item.icon[UnityEngine.UI.Image]:LoadSprite("icon/bigRole/"..heroInfo.cfg.mode)
		end

		item.quality[CS.UGUISpriteSelector].index = heroInfo.cfg.role_stage;

		local element, profession = self:GetHeroData(heroInfo)

		item.element[CS.UGUISpriteSelector].index = element;
		item.type[CS.UGUISpriteSelector].index = profession;

		if heroInfo.cfg.id == 11000 then
			main_character_icon = item;
		end
		SetVisiable(item.tip[UI.Image], RedDotModule.GetStatus(RedDotModule.Type.Hero.Hero, heroInfo.cfg.id, item.tip))
		if heroInfo.state >= STATE.FREE then
			item.level[UI.Text].text = "^"..heroInfo.hero.level;
			item.info.name[CS.UnityEngine.UI.Text]:TextFormat("<size=24>{0}</size>{1}",string.sub(heroInfo.cfg.name,1,3), string.sub(heroInfo.cfg.name,4));
			item.info.stage[UI.Text].text = "+"..heroInfo.hero.stage;
			item.info.capacity[UI.Text].text = heroInfo.hero.capacity;
			item.info[UnityEngine.CanvasGroup].alpha = 1;
			item.compose[UnityEngine.CanvasGroup].alpha = 0;
		else
			item.level[UI.Text].text = "x"..heroInfo.piece_count;
			item.compose.name[CS.UnityEngine.UI.Text]:TextFormat("<size=24>{0}</size>{1}",string.sub(heroInfo.cfg.name,1,3), string.sub(heroInfo.cfg.name,4));
			item.compose.Slider[UnityEngine.UI.Slider].maxValue = heroInfo.compose_count;
			item.compose.Slider[UnityEngine.UI.Slider].value = heroInfo.piece_count;
			item.compose.Slider.price[CS.UnityEngine.UI.Text].text = heroInfo.piece_count.."/"..heroInfo.compose_count
			item.info[UnityEngine.CanvasGroup].alpha = 0;
			item.compose[UnityEngine.CanvasGroup].alpha = 1;
		end

		local star = math.floor((heroInfo.state >= STATE.FREE and heroInfo.hero.star or 0) / 6);
		for i=1,6 do
			SetVisiable(item.star["Image"..i][UI.Image], star >= i)
		end
		item.lock[UnityEngine.CanvasGroup].alpha = heroInfo.state < STATE.FREE and 1 or 0;
		item.lock.Text[UI.Text].text = heroInfo.state == STATE.COMPOSE and "可解锁" or "";
		CS.UGUIClickEventListener.Get(item.click.gameObject).onClick = function ( object )
			self:EnterRoleDetail(heroInfo)
		end
		obj:SetActive(true);
	end
	self:UpdateScrollView(true)

	utils.SGKTools.LockMapClick(true)
	SGK.Action.DelayTime.Create(0.5):OnComplete(function()
		utils.SGKTools.LockMapClick(false)
		if main_character_icon then
			module.guideModule.PlayByType(106)
		end
	end)
end

function View:GetHeroData(heroInfo)
	if self.hero_data[heroInfo.cfg.id] == nil then
		local element = 0;
		if heroInfo.cfg.type ~= 0 then
			for i=1,8 do
				if (heroInfo.cfg.type & (1 << (i - 1))) ~= 0 then
					element = i;
					break;
				end
			end
		end
	
		local _profession = heroInfo.cfg.profession;
		if heroInfo.cfg.profession == 0 then
			if heroInfo.state >= STATE.FREE then
				local _cfg = module.TalentModule.GetSkillSwitchConfig(heroInfo.cfg.id)
				local _idx = heroInfo.hero.property_value
				if _idx == 0 then
					_idx = 2
				end
				if _cfg[_idx] then
					_profession = _cfg[_idx].profession
				end
			else
				_profession = 1;
			end
		end
		self.hero_data[heroInfo.cfg.id] = {element, profession_icon[_profession] or 1}
	end
	return self.hero_data[heroInfo.cfg.id][1],self.hero_data[heroInfo.cfg.id][2]
end

function View:UpdateScrollView(init)
	if self.viewType == 1 then
		self.view.smallView.Viewport.Content[CS.ScrollViewContent].DataCount = 0;
		self.view.smallView:SetActive(false);
		self.view.bigView:SetActive(true);
		self.tableview = self.view.bigView.Viewport.Content;
	else
		self.view.bigView.Viewport.Content[CS.ScrollViewContent].DataCount = 0;
		self.view.bigView:SetActive(false);
		self.view.smallView:SetActive(true);
		self.tableview = self.view.smallView.Viewport.Content;
	end	
	self.tableview[CS.ScrollViewContent].DataCount = #self.heroInfo[self.type];
	if init and self.savedValues and self.savedValues.scrollPos then
		SGK.Action.DelayTime.Create(0.2):OnComplete(function() 
			self.tableview[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0, self.savedValues.scrollPos);
			self.tableview.transform:DOLocalMove(Vector3(0, 1, 0), 0):SetRelative(true);
		end)
	end
end

function View:EnterRoleDetail(heroInfo)
	if heroInfo.state >= STATE.FREE then
		self.select_hero = heroInfo.hero.id;
		self.savedValues.scrollPos = self.tableview[UnityEngine.RectTransform].anchoredPosition.y;
		DialogStack.Push("newRole/roleFramework", {heroid = heroInfo.hero.id})
	else
		local lockrole = {};
		local index,count = 0,0;
		for i,v in ipairs(self.heroInfo[0]) do
			if v.state < STATE.FREE then
				count = count + 1;
				table.insert(lockrole, v)
				if v.cfg.id == heroInfo.cfg.id then
					index = count;
				end
			end
		end
		self.savedValues.scrollPos = self.tableview[UnityEngine.RectTransform].anchoredPosition.y;
		DialogStack.Push("HeroComposeFrame",{heroInfo = heroInfo, lockrole = lockrole, index = index, source = 1})
	end
end

function View:listEvent()
	return {
		"HERO_INFO_CHANGE",
		"SHOP_INFO_CHANGE",
		"LOCAL_GUIDE_OPT_ROLE"
	}
end

function View:onEvent(event, ...)
	-- print("onEvent", event, ...);
	local data = ...
	if event == "SHOP_INFO_CHANGE" or event == "HERO_INFO_CHANGE" then
		self:InitData();
		self:UpdateScrollView();
	elseif event == "LOCAL_GUIDE_OPT_ROLE" then
		local type = tonumber(data[1])
		self.viewType = type;
		self:UpdateScrollView();
	end
end

function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return View;
