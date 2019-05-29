local ActivityModule = require "module.ActivityModule"
local ItemModule = require "module.ItemModule"
local Time = require "module.Time"
local ItemHelper = require "utils.ItemHelper"
local QuestModule = require "module.QuestModule"
local ShopModule = require "module.ShopModule"
local UserDefault = require "utils.UserDefault";

local View = {};
local draw_card_data = UserDefault.Load("draw_card_data", true);
draw_card_data.last_select = draw_card_data.last_select or {};

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
	self.view = self.root.view;
	self.dialog = self.root.dialog;
	self:InitData();
	self:InitView();
	self:initGuide()
end

function View:InitData()
	self.updateTime = 0;
	self.poolUI = {};
	self.preview_stage = {};
	self.preview_hero = {};
	self.initPoint = false;
	self.pointPage = self.savedValues.pointPage or 1;
	self.curSelect = self.savedValues.curSelect or 0;
	self.preview_id = self.savedValues.preview_id or 0;
	self.point_buy = false;
	self.pointShop = ShopModule.GetManager(3001);
	print("商店信息3001", sprinttb(self.pointShop))
	self.point_list = {};
	self.exchangeShop = ShopModule.GetManager(14);
	print("商店信息14", sprinttb(self.exchangeShop))
	self.exchang_list = {};
	self.pointQuest = QuestModule.GetConfigType(104);
	table.sort(self.pointQuest,function (a,b)
		return a.event_count1 < b.event_count1;
	end)
	self:CheckQuest();
	local poolData = self:GetPoolData();
	self.poolData = {};
	for k,v in pairs(poolData) do
		if ActivityModule.CheckPoolOpen(v.active_time) then
			table.insert(self.poolData, v);
		end
	end
	table.sort(self.poolData, function ( a,b )
		local poolCfg1 = ActivityModule.GetDrawCardShowConfig(a.id);
		local poolCfg2 = ActivityModule.GetDrawCardShowConfig(b.id);
		local sort1 = poolCfg1 and poolCfg1.sort_id or 99;
		local sort2 = poolCfg2 and poolCfg2.sort_id or 99;
		if sort1 ~= sort2 then
			return sort1 < sort2;
		end
		return a.id < b.id;
	end)
	print("奖池配置", sprinttb(self.poolData))
end

function View:InitView()
	SGK.BackgroundMusicService.PlayMusic("sound/zhanbu.mp3");
	DialogStack.PushPref("CurrencyChat", {itemid = {90002, 90003, 90221, 90222}}, self.view);

	CS.UGUIClickEventListener.Get(self.view.help.gameObject).onClick = function (obj)
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("zhaomu_shuoming_02"))
	end

	--初始化积分兑换
	for i,v in ipairs(self.pointQuest) do
		local item = self.view.point.Slider["stage"..i];
		if item then
			item.Text[UnityEngine.UI.Text].text = v.event_count1;
		end
	end
	self.view.point.Slider[UnityEngine.UI.Slider].maxValue = self.pointQuest[#self.pointQuest].event_count1;
	self:UpdatePointView();
	CS.UGUIClickEventListener.Get(self.view.point.icon.gameObject).onClick = function (obj)
		if not self.initPoint then
			self:InitPointDialog();
		end
		for i,v in ipairs(self.pointQuest) do
			local quest = QuestModule.Get(v.id);
			if quest and quest.status == 0 then
				self.pointPage = i;
				break;
			end
		end
		self:UpdatePointPage(true);
		self.dialog.pointReward:SetActive(true);
	end
	if self.savedValues.pointReward then
		self:InitPointDialog();
		self:UpdatePointPage(true);
		self.dialog.pointReward:SetActive(true);
	end
	if self.savedValues.preview and self.preview_id ~= 0 then
		self:ShowRewardPreview(self.preview_id);
	end
	
	--初始化兑换券兑换
	CS.UGUIClickEventListener.Get(self.view.exchange.gameObject).onClick = function (obj)
		self:UpdateExchange()
		self.dialog.exchange:SetActive(true);
	end
	self.dialog.exchange.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function ( obj,idx )
		local item = CS.SGK.UIReference.Setup(obj);
		local info = self.exchang_list[idx + 1];
		local cfg = ItemHelper.Get(info.product_item_type, info.product_item_id);
		item.name.Text[UnityEngine.UI.Text].text = cfg.name;
		utils.IconFrameHelper.Create(item.IconFrame,{type = info.product_item_type, id = info.product_item_id, count = info.product_item_value, showDetail = true});
		utils.IconFrameHelper.Create(item.cost,{type = info.consume_item_type1, id = info.consume_item_id1, count = 0, showDetail = true});
		item.count[UnityEngine.UI.Text].text = info.consume_item_value1;
		item.count[CS.UGUIColorSelector].index = (ItemModule.GetItemCount(info.consume_item_id1) >= info.consume_item_value1) and 0 or 1;
		item.Text[UnityEngine.UI.Text]:TextFormat("今日剩余{0}次", info.product_count);
		SetButtonStatus(info.product_count > 0, item.get);
		CS.UGUIClickEventListener.Get(item.get.gameObject).onClick = function (obj)
			if ItemModule.GetItemCount(info.consume_item_id1) < info.consume_item_value1 then
				local _cfg = ItemHelper.Get(info.consume_item_type1, info.consume_item_id1);
				showDlgError(nil, _cfg.name.."不足");
				return;
			end
			if info.product_count <= 0 then
				showDlgError(nil, "库存不足");
				return;
			end
			print("购买", info.gid);
			ShopModule.Buy(14, info.gid, 1);
		end
		item:SetActive(true);
	end
	--奖池初始化
	local width = {349, 349, 365, 385}
	local content = self.view.ScrollView.Viewport.Content;
	for i,v in ipairs(self.poolData) do
		local poolCfg = ActivityModule.GetDrawCardShowConfig(v.id);
		if poolCfg then
			local obj = CS.UnityEngine.GameObject.Instantiate(content.pool.gameObject, content.transform);
			local item = CS.SGK.UIReference.Setup(obj);
			obj.name = "pool_"..v.id;
			item[UnityEngine.UI.Image]:LoadSprite("DrawCard/"..poolCfg.banner_pic, function ()
				item[UnityEngine.CanvasGroup].alpha = 1;
			end);
			item.guarantee[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(width[poolCfg.guarantee_stage] or 385, 39)
			item.guarantee.class[CS.UGUISpriteSelector].index = poolCfg.guarantee_stage - 1;
			item.guarantee.class[UnityEngine.UI.Image]:SetNativeSize();
			if poolCfg.guide ~= 0 then
				item.ssr[UnityEngine.UI.Image]:LoadSprite("DrawCard/"..poolCfg.banner_pic.."b");
				item.ssr:SetActive(true);
				CS.UGUIClickEventListener.Get(item.ssr.gameObject).onClick = function (obj)
					DialogStack.Push("HeroComposeFrame",{roleID = poolCfg.guide})
				end
			else
				item.ssr:SetActive(false);
			end
			item.ten.off:SetActive(poolCfg.discount ~= 0);
			item.ten.icon:SetActive(true);
			item.ten.num:SetActive(true);
			item.openTime:SetActive(v.id ~= 1 and v.id ~= 2);
			if poolCfg.up_logo ~= "0" then
				item.up[UnityEngine.UI.Image]:LoadSprite("DrawCard/"..poolCfg.up_logo);
				item.up:SetActive(true);
			else
				item.up:SetActive(false);
			end
			for _,time in ipairs(v.active_time) do
				if time.begin_time <= Time.now() and time.end_time > Time.now() then
					local delta = Time.now() - time.begin_time;
					if time.duration == 0 or delta % time.period < time.duration then
						if time.duration == 0 then
							item.openTime[UnityEngine.UI.Text]:TextFormat("{0} ~ {1} 限时登场!", os.date("%m.%d",math.floor(time.begin_time)), os.date("%m.%d %H:%M",math.floor(time.end_time)))
						else
							local begin_time = math.floor(delta / time.period) * time.period + time.begin_time;
							local end_time = begin_time + time.duration;
							item.openTime[UnityEngine.UI.Text]:TextFormat("{0} ~ {1} 限时登场!", os.date("%m.%d",math.floor(begin_time)), os.date("%m.%d %H:%M",math.floor(end_time)))
						end
						break;
					end
				end	
			end
			if poolCfg.discount ~= 0 then
				item.ten.off[CS.UGUISpriteSelector].index = poolCfg.discount - 1;
			end
			item:SetActive(true);
			self.poolUI[v.id] = item;
			CS.UGUIClickEventListener.Get(item.view.gameObject).onClick = function (obj)
				self:ShowRewardPreview(poolCfg.reward_pool_id);
			end
			CS.UGUIClickEventListener.Get(item.one.gameObject).onClick = function (obj)
				self:DrawCard(v.id, 0);
			end
			CS.UGUIClickEventListener.Get(item.ten.gameObject).onClick = function (obj)
				self:DrawCard(v.id, 1);
			end
		end
	end
	self:UpdatePoolView();
end

function View:GetPoolData()
	local activity_type = {1, 4, 5};
	local allPool = {};
	for _,v in ipairs(activity_type) do
		local poolData = ActivityModule.GetManager(v);
		if poolData then
			for k,j in pairs(poolData) do
				allPool[k] = j
			end
		end
	end
	return allPool;
end

function View:CheckQuest()
	local needAccept = {};
	for i,v in ipairs(self.pointQuest) do
		local quest = QuestModule.Get(v.id);
		if quest then
			print("任务状态", quest.name, quest.status)
		else
			print("任务不存在", v.name)
		end
		if quest == nil then
			QuestModule.Accept(v.id);
		elseif quest.status ~= 0 and QuestModule.CanAccept(v.id) then
			table.insert(needAccept, v.id);
		end
	end
	if #needAccept == #self.pointQuest then
		for i,v in ipairs(needAccept) do
			QuestModule.Accept(v);
		end
	end
end

function View:DrawCard(id, combo)
	local poolData = self:GetPoolData();
	local data = poolData[id];
	if data then
		if combo == 0 then
			local time = math.floor(Time.now() - data.CardData.last_free_time);
			if time >= data.free_gap then
				if data.free_Item_id == 0 or ItemModule.GetItemCount(data.free_Item_id) >= data.free_Item_consume then
					local consume = {data.consume_type, data.consume_id, 0};
					local args = {id, 0, consume, combo, false};
					DialogStack.PushPrefStact("DrawCard/newDrawCardResult", {activity_id = id, args = args});
					return;
				end 
			end
			if data.consume_id2 ~= 0 and ItemModule.GetItemCount(data.consume_id2) >= data.price2 then
				local consume = {data.consume_type2, data.consume_id2, data.price2}
				local args = {id, 0, consume, combo, true};
				DialogStack.PushPrefStact("DrawCard/newDrawCardResult", {activity_id = id, args = args});
				return;
			end
			if data.consume_id ~= 0 and ItemModule.GetItemCount(data.consume_id) >= data.price then
				local consume = {data.consume_type, data.consume_id, data.price}
				local args = {id, 0, consume, combo, false};
				DialogStack.PushPrefStact("DrawCard/newDrawCardResult", {activity_id = id, args = args});
			else
				local cfg = ItemHelper.Get(data.consume_type, data.consume_id)
				showDlgError(nil, cfg.name.."不足");
			end
		else
			if data.consume_id2 ~= 0 and ItemModule.GetItemCount(data.consume_id2) >= data.combo_price2 * data.combo_count then
				local consume = {data.consume_type2, data.consume_id2, data.combo_price2 * data.combo_count}
				local args = {id, 0, consume, combo, true};
				DialogStack.PushPrefStact("DrawCard/newDrawCardResult", {activity_id = id, args = args});
				return;
			end
			local count = ItemModule.GetItemCount(data.consume_id);
			if count >= data.combo_price * data.combo_count then
				local consume = {data.consume_type, data.consume_id, data.combo_price * data.combo_count}
				local args = {id, 0, consume, combo, false};
				DialogStack.PushPrefStact("DrawCard/newDrawCardResult", {activity_id = id, args = args});
			else
				local cfg = ItemHelper.Get(data.consume_type, data.consume_id)
				showDlgError(nil, cfg.name.."不足");
			end
		end
	else
		ERROR_LOG("奖池不存在", id)
	end
end
--刷新积分进度条
function View:UpdatePointView()
	local quest = QuestModule.Get(1042001);
	print(quest.name, quest.status, ItemModule.GetItemCount(78951), ItemModule.GetItemCount(78901), ItemModule.GetItemCount(78902), ItemModule.GetItemCount(78903));
	local count = ItemModule.GetItemCount(self.pointQuest[1].event_id1);
	print("积分", self.pointQuest[1].event_id1, count);
	self.view.point.Slider[UnityEngine.UI.Slider].value = count;
	local canReward = false;
	for i,v in ipairs(self.pointQuest) do
		local item = self.view.point.Slider["stage"..i];
		if item then
			item[CS.UGUISelectorGroup].index = (count >= v.event_count1) and 1 or 0;
		end
		local quest = QuestModule.Get(v.id);
		if quest and quest.status == 0 and count >= v.event_count1 then
			canReward = true;
		end
	end
	self.view.point.icon.effect:SetActive(canReward);
end

function View:InitPointDialog()
	self.initPoint = true;
	for i,v in ipairs(self.pointQuest) do
		local page = self.dialog.pointReward.Toggle["page"..i];
		if page then
			page.effect:SetActive(false);
			page.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..v.icon);
			CS.UGUIClickEventListener.Get(page.gameObject).onClick = function (obj)
				self.pointPage = i;
				self.curSelect = 0;
				self:UpdatePointPage();
			end
		end
	end
	
	self.dialog.pointReward.ScrollView.Viewport.Content[CS.ScrollViewContent].RefreshIconCallback = function ( obj,idx )
		local item = CS.SGK.UIReference.Setup(obj);
		local info = self.point_list[idx + 1];
		if draw_card_data.last_select[self.pointPage] then
			item.select:SetActive(info.id == draw_card_data.last_select[self.pointPage])
		else
			item.select:SetActive(self.curSelect == idx + 1);
		end
		utils.IconFrameHelper.Create(item.IconFrame,{type = info.type, id = info.id, count = info.value, customCfg = {level = 0}});
		item.name[UnityEngine.UI.Text].text = ItemHelper.Get(info.type, info.id).name;
		CS.UGUIClickEventListener.Get(item.gameObject, true).onClick = function (obj)
			if draw_card_data.last_select[self.pointPage] == nil then
				if self.curSelect ~= 0 then
					local _obj = self.dialog.pointReward.ScrollView.Viewport.Content[CS.ScrollViewContent]:GetItem(self.curSelect - 1);
					local _item = CS.SGK.UIReference.Setup(_obj);
					_item.select:SetActive(false);
				end
				self.curSelect = idx + 1;
				item.select:SetActive(true);
			end
		end

		local listener = CS.UGUIPointerEventListener.Get(item.gameObject)
		if listener.isLongPress ~= nil then
			listener.isLongPress = true;
		end
		CS.UGUIPointerEventListener.Get(item.gameObject).onPointerDown = function()
			DialogStack.Push("HeroComposeFrame",{roleID = info.id})
		end
		item:SetActive(true);
	end
	CS.UGUIClickEventListener.Get(self.dialog.pointReward.get.gameObject).onClick = function (obj)
		if self.point_buy then
			return;
		end
		local count = ItemModule.GetItemCount(self.pointQuest[self.pointPage].event_id1)
		if count < self.pointQuest[self.pointPage].event_count1 then
			showDlgError(nil, "积分不足");
			return;
		end
		if self.curSelect == 0 then
			showDlgError(nil, "请选择一个奖品");
			return;
		end
		if QuestModule.CanSubmit(self.pointQuest[self.pointPage].id) then
			self.point_buy = true;
			self.root.mask:SetActive(true);
			QuestModule.Finish(self.pointQuest[self.pointPage].id);
		else
			ERROR_LOG("任务无法完成", self.pointQuest[self.pointPage].id)
		end
	end
end

function View:UpdatePointPage(check)
	if self.pointShop == nil or self.pointShop.shoplist == nil then
		return;
	end
	if check then
		for i,v in ipairs(self.pointQuest) do
			local item = self.dialog.pointReward.Toggle["page"..i];
			local count = ItemModule.GetItemCount(v.event_id1);
			item.num[UnityEngine.UI.Text]:TextFormat("{0}/{1}", count, v.event_count1);
			local quest = QuestModule.Get(v.id);
			if quest then
				print(quest.name, quest.status, v.event_count1)
				if quest.status == 1 then
					item.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..v.icon.."-2");
					item.get:SetActive(true);
				else
					item.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..v.icon);
					item.get:SetActive(false);
				end
				item.Text:SetActive(quest.status == 1);
				item.num:SetActive(quest.status == 0);
				local canSubmit = count >= v.event_count1 and quest.status == 0
				item.effect:SetActive(canSubmit);
				item.num[CS.UGUIColorSelector].index = canSubmit and 0 or 1;
				item[UI.Toggle].isOn = self.pointPage == i;
			end
		end
	end
	local quest = QuestModule.Get(self.pointQuest[self.pointPage].id);
	if quest then
		local count = ItemModule.GetItemCount(self.pointQuest[self.pointPage].event_id1)
		if quest.status ~= 1 then
			self.dialog.pointReward.get.Text[UnityEngine.UI.Text].text = "领取";
		else
			self.dialog.pointReward.get.Text[UnityEngine.UI.Text].text = "已领取";
		end
		local canGet = count >= self.pointQuest[self.pointPage].event_count1 and quest.status ~= 1;
		SetButtonStatus(canGet, self.dialog.pointReward.get);
	end
	self.point_list = {};
	for k,v in pairs(self.pointShop.shoplist) do
		if v.consume_item_id1 == self.pointQuest[self.pointPage].reward_id2 then
			self.point_list = v.product_item_list;
		end
	end
	if self.point_list then
		self.dialog.pointReward.ScrollView.Viewport.Content[CS.ScrollViewContent].DataCount = #self.point_list;
	end
end

function View:UpdateExchange()
	local count = ItemModule.GetItemCount(90231);
	self.dialog.exchange.cost.Text[UnityEngine.UI.Text].text = count;
	if self.exchangeShop ~= nil and self.exchangeShop.shoplist ~= nil then
		self.exchang_list = {};
		for k,v in pairs(self.exchangeShop.shoplist) do
			table.insert(self.exchang_list, v);
		end
		table.sort(self.exchang_list, function ( a,b )
			return a.gid < b.gid;
		end)
		self.dialog.exchange.ScrollView[CS.UIMultiScroller].DataCount = #self.exchang_list;
	end
end

--刷新奖池显示
function View:UpdatePoolView()
	for i,v in ipairs(self.poolData) do
		if self.poolUI[v.id] then
			local item = self.poolUI[v.id];
			local guarantee_count = v.combo_count - (v.CardData.total_count % v.combo_count) - 1;
			if guarantee_count > 0 then
				item.guarantee[CS.UGUISpriteSelector].index = 0;
				item.guarantee.count[UnityEngine.UI.Text].text = guarantee_count;
				item.guarantee.count:SetActive(true);
			else
				item.guarantee[CS.UGUISpriteSelector].index = 1;
				item.guarantee.count:SetActive(false);
			end
			local time = math.floor(Time.now() - v.CardData.last_free_time);
			item.one.icon:SetActive(time < v.free_gap);
			item.one.num:SetActive(time < v.free_gap);
			item.one.free:SetActive(time >= v.free_gap);
			if time < v.free_gap then
				if v.consume_id2 ~= 0 and ItemModule.GetItemCount(v.consume_id2) >= v.price2 then
					item.one.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..v.consume_id2.."_small");
					item.one.num[UnityEngine.UI.Text].text = v.price2;
				else 
					item.one.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..v.consume_id.."_small");
					item.one.num[UnityEngine.UI.Text].text = v.price;
				end
			else
				item.freeTime[UnityEngine.UI.Text].text = "";
			end
			if v.consume_id2 ~= 0 and ItemModule.GetItemCount(v.consume_id2) >= v.combo_count * v.combo_price2 then
				item.ten.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..v.consume_id2.."_small");
				item.ten.num[UnityEngine.UI.Text].text = v.combo_count * v.combo_price2;
			else
				item.ten.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..v.consume_id.."_small");
				item.ten.num[UnityEngine.UI.Text].text = v.combo_count * v.combo_price;
			end
		end
	end
end

function View:ShowRewardPreview(id)
	self.preview_id = id;
	for k,v in pairs(self.preview_stage) do
		v:SetActive(false);
	end
	for k,v in pairs(self.preview_hero) do
		v:SetActive(false);
	end
	local rewardCfg = ActivityModule.GetDrawCardRewardConfig(id);
	local hero_list = {};
	for i,v in ipairs(rewardCfg) do
		local heroCfg = module.HeroModule.GetConfig(v.role_id);
		if heroCfg then
			hero_list[heroCfg.role_stage] = hero_list[heroCfg.role_stage] or {};
			table.insert(hero_list[heroCfg.role_stage], v);
		end
	end
	local content = self.dialog.preview.ScrollView.Viewport.Content;
	content[UnityEngine.RectTransform].anchoredPosition =  CS.UnityEngine.Vector2(0, 0);
	for i=5,1,-1 do
		if hero_list[i] then
			local stageView = nil;
			if self.preview_stage[i] then
				stageView = self.preview_stage[i];
			else
				local obj = CS.UnityEngine.GameObject.Instantiate(content.type.gameObject, content.transform);
				obj.name = "stage"..i;
				stageView = CS.SGK.UIReference.Setup(obj);
				stageView.Image[CS.UGUISpriteSelector].index = i - 1;
				self.preview_stage[i] = stageView;
			end
			table.sort(hero_list[i], function (a, b)
				if a.rate_up ~= b.rate_up then
					return a.rate_up > b.rate_up;
				end
				return a.role_id < b.role_id;
			end)
			for j,v in ipairs(hero_list[i]) do
				if self.preview_hero[v.role_id] then
					self.preview_hero[v.role_id].transform:SetSiblingIndex(j);
					self.preview_hero[v.role_id]:SetActive(true);
				else
					local obj = CS.UnityEngine.GameObject.Instantiate(stageView.npcInfo.gameObject, stageView.transform);
					obj.name = "icon_"..v.role_id;
					local hero = CS.SGK.UIReference.Setup(obj);
					local heroCfg = module.HeroModule.GetConfig(v.role_id);
					if heroCfg then
						hero.name[UnityEngine.UI.Text].text = heroCfg.name;
						utils.IconFrameHelper.Create(hero.IconFrame, {customCfg={
							icon    = heroCfg.mode,
							quality = heroCfg.role_stage,
							star    = 0,
							level   = 0,
						}, type = 42})
						-- local listener = CS.UGUIPointerEventListener.Get(obj)
						-- if listener.isLongPress ~= nil then
						-- 	listener.isLongPress = true;
						-- end
						CS.UGUIClickEventListener.Get(obj).onClick = function()
							DialogStack.Push("HeroComposeFrame",{roleID = v.role_id})
						end
					end
					self.preview_hero[v.role_id] = hero;
					self.preview_hero[v.role_id]:SetActive(true);
				end
			end
			self.preview_stage[i].gameObject.transform:SetSiblingIndex(6-i)
			self.preview_stage[i]:SetActive(true);
		else
			if self.preview_stage[i] then
				self.preview_stage[i]:SetActive(false);
			end
		end
	end
	self.dialog.preview:SetActive(true);
end

function View:Update()
	if Time.now() - self.updateTime >= 1 then
		self.updateTime = Time.now();
		for i,v in ipairs(self.poolData) do
			if self.poolUI[v.id] then
				local item = self.poolUI[v.id];
				local time = math.floor(v.CardData.last_free_time + v.free_gap - Time.now());
				if time >= 0 then
					item.freeTime[UnityEngine.UI.Text]:TextFormat("{0}后免费", GetTimeFormat(time, 2))
				else
					item.freeTime[UnityEngine.UI.Text].text = "";
				end
			end
		end
	end	
end

function View:initGuide()
    module.guideModule.PlayByType(116,0.2)
end

function View:OnDestroy()
	-- SetItemTipsState(true)
	SGK.BackgroundMusicService.SwitchMusic();
	self.savedValues.pointReward = self.dialog.pointReward.gameObject.activeSelf;
	self.savedValues.preview = self.dialog.preview.gameObject.activeSelf;
	self.savedValues.preview_id = 	self.preview_id;
	self.savedValues.pointPage = self.pointPage;
	self.savedValues.curSelect = self.curSelect;
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
		"Activity_INFO_CHANGE",
		"Change_Pool_Succeed",
		"SHOP_INFO_CHANGE",
		"SHOP_BUY_SUCCEED",
		"QUEST_INFO_CHANGE",
		"SHOP_BUY_FAILED",
		"DrawCard_Succeed",
		"LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	local data = ...;
	if event == "Activity_INFO_CHANGE" or event == "Change_Pool_Succeed" then
		local poolData = self:GetPoolData();
		self.poolData = {};
		for k,v in pairs(poolData) do
			if ActivityModule.CheckPoolOpen(v.active_time) then
				table.insert(self.poolData, v);
			end
		end
		table.sort(self.poolData, function ( a,b )
			return a.id < b.id;
		end)
		print("奖池配置", sprinttb(self.poolData))
		self:UpdatePoolView();
	elseif event == "SHOP_INFO_CHANGE" then
		if data == nil then
			return;
		end
		if data.id == 3001 then
			self.pointShop = ShopModule.GetManager(3001);
			print("商店信息3001", sprinttb(self.pointShop))
			if self.dialog.pointReward.activeSelf then
				self:UpdatePointPage(true);
			end
		elseif data.id == 14 then
			self.exchangeShop = ShopModule.GetManager(14);
			print("商店信息14", sprinttb(self.exchangeShop))
			if self.dialog.exchange.activeSelf then
				self:UpdateExchange();
			end
		end
	elseif event == "SHOP_BUY_SUCCEED" then
		if data == nil then
			return;
		end
		if data.shop_id == 3001 then
			draw_card_data.last_select[self.pointPage] = self.point_list[self.curSelect].id;
			self.curSelect = 0;
			self.root.mask:SetActive(false);
			self.pointShop = ShopModule.GetManager(3001);
			if self.dialog.pointReward.activeSelf then
				self:UpdatePointPage(true);
			end
			self:UpdatePointView();
		elseif data.shop_id == 14 then
			self.exchangeShop = ShopModule.GetManager(14);
			if self.dialog.exchange.activeSelf then
				self:UpdateExchange();
			end
		end
	elseif event == "SHOP_BUY_FAILED" then
		if data == nil then
			return;
		end
		if data.shop_id == 3001 then
			self.root.mask:SetActive(false);
			showDlgError(nil, "兑换失败")
		end
	elseif event == "QUEST_INFO_CHANGE" then
		if self.point_buy then
			self.point_buy = false;
			for k,v in pairs(self.pointShop.shoplist) do
				if v.consume_item_id1 == self.pointQuest[self.pointPage].reward_id2 then
					ShopModule.Buy(3001, v.gid, 1, {product_index = self.point_list[self.curSelect].idx})
				end
			end
		end
		self:CheckQuest();
		for i,v in ipairs(self.pointQuest) do
			local quest = QuestModule.Get(v.id);
			if quest and quest.status == 0 then
				draw_card_data.last_select[i] = nil;
			end
		end
		if self.dialog.pointReward.activeSelf then
			self:UpdatePointPage(true);
		end
	elseif event == "DrawCard_Succeed" then
		self:UpdatePointView();
	elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
	end
end

return View;