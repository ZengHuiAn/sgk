local heroLevelup = require "hero.HeroLevelup"
local heroModule = require "module.HeroModule"
local ItemModule = require "module.ItemModule"
local NetworkService = require "utils.NetworkService";
local CommonConfig = require "config.commonConfig"
local ItemHelper = require "utils.ItemHelper"
local ParameterConf = require "config.ParameterShowInfo";

local book_gid = {1030001, 1030002, 1030003, 1030004}
local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
	self.view = self.root.view
	self.levelup = self.root.dialog.levelup;
	self.tip = self.root.dialog.tip;
	self:InitData();
	self:InitView();
end

function View:InitData(data)
    self.heroManager = heroModule.GetManager();
    self.lvlupConfig = heroLevelup.Load();
	self.cost = {0, 0, 0, 0};
	self.property = {};
	self.levelLimit = CommonConfig.Get(6).para1 or 200;
	self.doing = false;
	self.quick = false;
	self.visible = true;
	self.dialog = nil;
	self:UpdateBookInfo();
end

function View:InitView()
	CS.UGUIClickEventListener.Get(self.view.up.gameObject, true).onClick = function (obj)
		local master = self.heroManager:Get(11000);
		local hero = self.heroManager:Get(self.roleID);
		
		if hero.level == self.levelLimit then
			showDlgError(nil, "等级已达到上限");
			return;
		end	

		if hero.level >= master.level then
			showDlgError(nil, "英雄等级不能超过主角等级");
			return;
		end	

		if self.doing then
			return;
		end

		local count = {0,0,0,0};
		local levelup_exp = self.expConfig[master.level] - hero.exp;
		local need_exp = levelup_exp - ItemModule.GetItemCount(90001);
		local have_exp = 0;
		local book_exp = {};
		--print("需要经验",need_exp, hero.exp, self.expConfig[master.level], ItemModule.GetItemCount(90001))
		for i=1,4 do
			book_exp[i] = ItemModule.GetItemCount(self.BookInfo[i].id) * self.BookInfo[i].exp_value;
			have_exp = have_exp + book_exp[i];
		end
		if have_exp == 0 then
			showDlgError(nil, "经验卡不足")
			return;
		end
		if need_exp <= 0 then --不需要消耗经验卡
			self:ShowLevelUpMax(count, master.level, levelup_exp);
		elseif have_exp > need_exp then
			for i=4,1,-1 do
				if book_exp[i] > need_exp then
					local _count = math.floor(need_exp/self.BookInfo[i].exp_value);
					local next_exp = 0;
					for j=i-1,1,-1 do
						next_exp = next_exp + book_exp[j];
					end
					if need_exp - self.BookInfo[i].exp_value * _count == 0 then
						count[i] = _count;
						break;
					elseif next_exp >= (need_exp - self.BookInfo[i].exp_value * _count) then
						count[i] = _count;
					else
						count[i] = math.ceil(need_exp/self.BookInfo[i].exp_value)
					end
				else
					count[i] = ItemModule.GetItemCount(self.BookInfo[i].id);
				end
				need_exp = need_exp - self.BookInfo[i].exp_value * count[i];
				if need_exp <= 0 then
					break;
				end
			end
			self:ShowLevelUpMax(count, master.level, levelup_exp);
		else --消耗所有的经验卡
			local _have = hero.exp + ItemModule.GetItemCount(90001)
			for i=1,4 do
				count[i] = ItemModule.GetItemCount(self.BookInfo[i].id);
				_have = _have + count[i] * self.BookInfo[i].exp_value;
			end
			local level = 1;
			for i,v in ipairs(self.expConfig) do
				if v > _have then
					level = i - 1;
					break;
				else
					level = i;
				end
			end
			self:ShowLevelUpMax(count, level, _have - hero.exp);
		end
	end

	for i=1,4 do
		CS.UGUIClickEventListener.Get(self.view.costView["cost"..i].IconFrame.gameObject).onClick = function (obj)
			if not self.BookInfo or self.doing then
				return;
			end
			if ItemModule.GetItemCount(self.BookInfo[i].id) > 0 then
				local hero = self.heroManager:Get(self.roleID);
				local master = self.heroManager:Get(11000);
				if hero.level == self.levelLimit then
					showDlgError(self.view, "等级已达到上限");
					return;
				end	

				if self.roleID ~= 11000 and hero.exp + self.BookInfo[i].exp_value >= self.expConfig[(master.level + 1 > self.levelLimit and self.levelLimit or master.level + 1)] then
					showDlgError(nil, "英雄等级不能超过主角等级");
					return;
				end
				self:UpdateButtonState(false);
				self:Upgrade(2, i);
			else
				DialogStack.PushPrefStact("ItemDetailFrame", {id = self.BookInfo[i].id,type = self.BookInfo[i].type,InItemBag=2},UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
			end
			
		end
	end
	self.view[SGK.DialogAnim].destroyCallBack = function (  )
		self.view:SetActive(false);
		self.root.mask:SetActive(false);
	end
	CS.UGUIClickEventListener.Get(self.root.up.gameObject).onClick = function (obj)
		if self.view.gameObject.activeSelf then
			self.view[SGK.DialogAnim]:PlayDestroyAnim();
		else
			self.view.gameObject.transform.localScale = Vector3(1, 1, 1);
			self.view:SetActive(true);
			self.view[SGK.DialogAnim]:PlayStartAnim();
			self.root.mask:SetActive(true);
			self:SetupView();
		end
	end
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject, true).onClick = function (obj)
		self.view[SGK.DialogAnim]:PlayDestroyAnim();
	end
	CS.UGUIClickEventListener.Get(self.tip.confirm.gameObject).onClick = function (obj)
		self:UpdateLevelUpInfo(1);
		self:SwitchDialog(false, self.tip);
	end
	CS.UGUIClickEventListener.Get(self.tip.BG.gameObject).onClick = function (obj)
		self:UpdateLevelUpInfo(1);
		self:SwitchDialog(false, self.tip);
	end
end

function View:Init(data, init_view)
	self.roleID = data and data.heroId or 11001;
	if self.roleID == 11000 then
		self.root.up:SetActive(false);
	else
		self.root.up:SetActive(true);
	end
end

function View:SetupView()
	if self.view.gameObject.activeSelf then
		self:UpdateData();
		self:UpdateInfo();
		self:UpdateLevelUpInfo(1);
	end
end

function View:UpdateData()
	self.expConfig = heroLevelup.GetExpConfig(1, self.heroManager:Get(self.roleID));
end

function View:ShowLevelUpMax(count, level, exp)
	local notuse = true;
	for i,v in ipairs(count) do
		local item = self.levelup.cost["item"..i];
		if v > 0 then
			utils.IconFrameHelper.Create(item,{type = self.BookInfo[i].type, id = self.BookInfo[i].id, count = v})
			item:SetActive(true);
			notuse = false;
		else
			item:SetActive(false);
		end
	end

	self.levelup.Text2:SetActive(notuse);
	if notuse then
		self.levelup.Text2[UnityEngine.UI.Text]:TextFormat("上次升级的溢出经验 <color=#00A32AFF>{0}</color> 点", exp)
	end
	print("消耗经验", exp);
	self.levelup.Text[UnityEngine.UI.Text]:TextFormat("将角色升级到Lv{0}，需要消耗：", level)
	CS.UGUIClickEventListener.Get(self.levelup.confirm.gameObject).onClick = function (obj)
		self:Upgrade(3,count, exp);
	end
	CS.UGUIClickEventListener.Get(self.levelup.BG.gameObject, true).onClick = function (obj)
		if self.doing then
			return;
		end
		self:SwitchDialog(false, self.levelup);
	end
	CS.UGUIClickEventListener.Get(self.levelup.title.close.gameObject).onClick = function (obj)
		if self.doing then
			return;
		end
		self:SwitchDialog(false, self.levelup);
	end
	CS.UGUIClickEventListener.Get(self.levelup.cancel.gameObject).onClick = function (obj)
		if self.doing then
			return;
		end
		self:SwitchDialog(false, self.levelup);
	end
	self:SwitchDialog(true, self.levelup);
	module.guideModule.PlayByType(107,0.2)
end

function View:SwitchDialog(status, view)
	if status then
		view.gameObject.transform:SetParent(UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform, false);
	else
		view.gameObject.transform:SetParent(self.root.dialog.gameObject.transform, false);
	end
	view:SetActive(status);
end

function View:UpdateButtonState(value)
	self.doing = not value;
	SetButtonStatus(value, self.view.up);
	SetButtonStatus(value, self.levelup.confirm);
end

function View:Upgrade(type,num, add_exp)
	local hero = self.heroManager:Get(self.roleID);
	add_exp = add_exp or 0; 
	self:UpdateButtonState(false);
	local count = {0,0,0,0};
	if type == 1  then -- 升一级
		local exp = self.expConfig[hero.level + num] - hero.exp - ItemModule.GetItemCount(90001);
		if exp <= 0 then
			self.cost = count;
			print("直接升级",self.expConfig[hero.level + num] - hero.exp)
			self.heroManager:AddExp(self.roleID, (self.expConfig[hero.level + num] - hero.exp));
			return
		end
		for i=1,4 do
			local need_exp = exp;
			exp = exp - ItemModule.GetItemCount(self.BookInfo[i].id) * self.BookInfo[i].exp_value;
			if exp <= 0 then
				count[i] = math.ceil(need_exp/self.BookInfo[i].exp_value);
				break;
			elseif ItemModule.GetItemCount(self.BookInfo[i].id) == 0 then
				count[i] = 0;
			else
				count[i] = ItemModule.GetItemCount(self.BookInfo[i].id);
			end
			if i == 4 and exp > 0 then
				showDlgError(self.view, "经验书不足");
				return;
			end
		end
	elseif type == 2 then
		count[num] = 1;
	elseif type == 3 then
		count = num;
	end

	local all_exp = 0;
	for i=1,4 do
		all_exp = all_exp + count[i] * self.BookInfo[i].exp_value;
	end

	if type == 1 then
		all_exp = all_exp + ItemModule.GetItemCount(90001);
	elseif type == 3 then
		all_exp = add_exp;
		self.quick = true;
	end

	self.cost = count;
	coroutine.resume(coroutine.create( function() 
		for i,v in ipairs(count) do
			if v > 0 then
				if not module.ShopModule.Buy(3, self.BookInfo[i].exp_gid, v) then
					self:UpdateButtonState(true);
					print("兑换经验值err", self.BookInfo[i].exp_gid)
					return;
				end
			end
			if i == 4 then
				if hero.exp + all_exp > self.expConfig[self.levelLimit] then
					all_exp = self.expConfig[self.levelLimit] - hero.exp;
				end
				self.heroManager:AddExp(self.roleID, all_exp);
			end
		end
	end));
	
	print("经验书消耗",sprinttb(count))
end

function View:UpdateInfo(changed)
	local hero = self.heroManager:Get(self.roleID);
	self.view.up:SetActive(hero.level < self.levelLimit);
	if changed then
		local delta_level = hero.level - self.property.level
		local delta_exp = hero.exp - self.property.exp
		self:playEffect("fx_jues_up1", nil, (delta_level > 0), delta_exp > 0)
		if delta_level > 0 then
			self.tip.info.icon[UnityEngine.UI.Image].color = {r = 0, g = 0, b = 0, a = 0}
			self.tip.info.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..hero.mode, function ()
				self.tip.info.icon[UnityEngine.UI.Image].color = UnityEngine.Color.white;
			end);
			self.tip.info.name[UnityEngine.UI.Text].text = hero.name;
			self:UpdateLevelUpInfo(2);
			self:SwitchDialog(true, self.tip);
			module.guideModule.PlayByType(107,0.2)
		end
		-- local _rewardFlag = module.rewardModule.Check(1007)
		-- if _rewardFlag and _rewardFlag == module.rewardModule.STATUS.DONE then
		-- 	if ItemModule.GetItemCount(90001) > 0 and self.quick then
		-- 		self.quick = false;
		-- 		local data = {};
		-- 		data.msg = string.format(TipCfg.GetAssistDescConfig(31001).info, ItemModule.GetItemCount(90001));
		-- 		data.confirm = function () end;
		-- 		data.title = TipCfg.GetAssistDescConfig(31001).tittle;
		-- 		DlgMsg(data)
		-- 	end
		-- end
	end
	self.property = hero.props;
	self.property.level = hero.level;

	self.view.level.levelNumber[CS.UnityEngine.UI.Text]:TextFormat("^ {0}",math.floor(hero.level));
	if hero.level == self.levelLimit then
		self.view.level.exp:SetActive(false);
	else
		local value = (hero.exp - self.expConfig[hero.level])/(self.expConfig[hero.level + 1] - self.expConfig[hero.level]);	
		self.view.level.exp[UnityEngine.UI.Text]:TextFormat("({0}%)",math.floor(value * 100))
		self.view.level.exp:SetActive(true);
	end
end

function View:UpdateLevelUpInfo(_type)
	local hero = self.heroManager:Get(self.roleID);
	local lvlupValue = self.lvlupConfig[self.roleID];
	self.tip.info["level".._type][UnityEngine.UI.Text].text = "Lv"..hero.level;
	for i,v in ipairs(lvlupValue) do
		local cfg = ParameterConf.Get(v.key);
		if v.key ~= 0 and v.key ~= 99900 and cfg then
			if _type == 1 then
				self.tip.prop["item"..i].icon[UnityEngine.UI.Image]:LoadSprite("propertyIcon/"..cfg.icon);
				self.tip.prop["item"..i].name[UnityEngine.UI.Text].text = cfg.name;
			end
			print("cfg.showType", v.key, cfg.showType, hero[tonumber(cfg.showType) or cfg.showType])
			self.tip.prop["item"..i]["num".._type][UnityEngine.UI.Text].text = math.floor(hero[tonumber(cfg.showType) or cfg.showType])
			self.tip.prop["item"..i]:SetActive(true);
		else
			self.tip.prop["item"..i]:SetActive(false);
		end
	end
end

function View:UpdateBookInfo()
	local shopInfo = module.ShopModule.GetManager(3);
	if shopInfo and shopInfo.shoplist then
		self.BookInfo = {};
		for i,v in ipairs(book_gid) do
			local book = {};
			book.exp_value = shopInfo.shoplist[v].product_item_value;
			book.exp_gid = shopInfo.shoplist[v].gid;
			book.id = shopInfo.shoplist[v].consume_item_id1;
			book.type = shopInfo.shoplist[v].consume_item_type1;
			table.insert(self.BookInfo, book);
		end
		table.sort(self.BookInfo,function ( a,b )
			return a.exp_value < b.exp_value;
		end)
	end	

	if self.BookInfo then
		for i=1,4 do
			local cfg = ItemHelper.Get(self.BookInfo[i].type,self.BookInfo[i].id)
			utils.IconFrameHelper.Create(self.view.costView["cost"..i].IconFrame,{type = self.BookInfo[i].type, id = self.BookInfo[i].id})
			self.view.costView["cost"..i].icon[UnityEngine.UI.Image]:LoadSprite("icon/"..cfg.icon.."_small");
			-- self.view.costView["cost"..i].count:SetActive(cfg.count == 0);
			self.view.costView["cost"..i].value[CS.UnityEngine.UI.Text]:TextFormat("<color=#7D7D7DFF>EXP</color>+{0}",self.BookInfo[i].exp_value);
		end
	end
end

function View:playEffect(effectName, sortOrder, levelChange, expChange)
	if expChange then
		for i,v in ipairs(self.cost) do
			if v ~= 0 then
				local icon = self.view.costView["cost"..i].icon;
				utils.IconFrameHelper.Create(self.view.costView["cost"..i].IconFrame,{type = self.BookInfo[i].type, id = self.BookInfo[i].id})
				SGK.Action.DelayTime.Create(0.1):OnComplete(function()
					icon:SetActive(true);
					icon.gameObject.transform:DOLocalMove(Vector3(0,80,0),0.4);
					icon:GetComponent(typeof(CS.UnityEngine.UI.Image)):DOFade(0, 0.3):SetDelay(0.1):OnComplete(function ( ... )
						icon:SetActive(false);
						icon[UnityEngine.UI.Image].color = UnityEngine.Color.white;
						icon.gameObject.transform.localPosition = Vector3(0, 13, 0);
					end)
				end)
			end
		end
	end
	if levelChange then
		SGK.ResourcesManager.LoadAsync("sound/shengji.mp3",typeof(UnityEngine.AudioClip),function (Audio)
			SGK.BackgroundMusicService.PlayUIClickSound(Audio)
		end)
	elseif expChange then
		SGK.ResourcesManager.LoadAsync("sound/jingyanka.mp3",typeof(UnityEngine.AudioClip),function (Audio)
			SGK.BackgroundMusicService.PlayUIClickSound(Audio)
		end)
	end
	-- if levelChange or expChange then
	-- 	local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName);
	-- 	local obj = prefab and UnityEngine.GameObject.Instantiate(prefab, self.root.gameObject.transform);
	-- 	if obj then
	-- 		obj.transform.localPosition = Vector3.zero;
	-- 		obj.transform.localRotation = Quaternion.identity;

	-- 		if sortOrder then
	-- 			SGK.ParticleSystemSortingLayer.Set(obj, sortOrder);
	-- 		end

	-- 		local _obj = obj:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
	-- 		_obj:Play()
	-- 		UnityEngine.Object.Destroy(obj, _obj.main.duration)
	-- 	end
	-- end
end

function View:OnDestroy()
	if self.levelup.gameObject.activeSelf then
		UnityEngine.GameObject.Destroy(self.levelup.gameObject);
	end
	if self.tip.gameObject.activeSelf then
		UnityEngine.GameObject.Destroy(self.tip.gameObject);
	end
end

function View:listEvent()
	return {
		"HERO_INFO_CHANGE",
		"SHOP_INFO_CHANGE",
		"LOCAL_NEWROLE_HEROIDX_CHANGE",
		"ROLE_FRAME_CHANGE",
		"LOCAL_GUIDE_CHANE",
		"HERO_LEVEL_UP",
	}
end

function View:onEvent(event, ...)
	--print("onEvent", event, ...);
	local data = ...
	if event == "HERO_INFO_CHANGE"  then
		local pid = select(1, ...)
		if pid == nil or pid == module.playerModule.GetSelfID() then
			self:UpdateInfo(true);
			self:UpdateButtonState(true);
		end
	elseif event == "SHOP_INFO_CHANGE" then
		if data.id == 3 then
			self:UpdateBookInfo();
		end
	elseif event == "LOCAL_NEWROLE_HEROIDX_CHANGE" then
		self:Init(data);
		self:SetupView();
	elseif event == "ROLE_FRAME_CHANGE" then
		self.view:SetActive(false);
	elseif event == "LOCAL_GUIDE_CHANE" then
		module.guideModule.PlayByType(107,0.2)
	elseif event == "HERO_LEVEL_UP" then
		if self.levelup.gameObject.activeSelf then
			self:SwitchDialog(false, self.levelup);
			self.view[SGK.DialogAnim]:PlayDestroyAnim();
		end
	end
end

return View;
