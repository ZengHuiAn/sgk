local QuestModule = require "module.QuestModule"
local Time = require "module.Time"
local heroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local equipmentModule = require "module.equipmentModule"
local ShopModule = require "module.ShopModule"
local ItemModule = require "module.ItemModule"
local openLevel = require "config.openLevel"

local str_day = {"一","二","三","四","五","六","七","八","九","十"}
local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
	self.view = self.root.view;
	self.dialog = self.root.dialog;
	self:InitData();
	self:InitView();
	module.guideModule.PlayByType(129, 0.1)
end

function View:InitData()
	self.updateTime = 0;
	self.endTime = 0;
	self.allQuest = QuestModule.GetCfgByType(100);
	self.questListByShowType = {}
	self.questType = {};
	self.canSubmitQuest = {};
	for day,v in ipairs(self.allQuest) do
		if self.questType[day] == nil then
			self.questType[day] = {};
		end
		if self.questListByShowType[day] == nil then
			self.questListByShowType[day] = {};
		end
		for type,j in pairs(v) do
			table.insert(self.questType[day],type);
			if self.questListByShowType[day][type] == nil then
				self.questListByShowType[day][type] = {};
			end
			for _,k in ipairs(j) do
				if self.endTime == 0 then
					self.endTime = k.end_time;
				end
				if self.questListByShowType[day][type][k.day7_show_type] == nil then
					self.questListByShowType[day][type][k.day7_show_type] = {};
				end
				table.insert(self.questListByShowType[day][type][k.day7_show_type], k);
			end
			for show_type,_ in pairs(self.questListByShowType[day][type]) do
				table.sort(self.questListByShowType[day][type][show_type], function ( a,b )
					return a.id < b.id
				end);
			end
		end
	end
	self.endTime = module.playerModule.GetCreateTime() + ((self.endTime - 1)  * 86400) - 1;

	self.redPointState = QuestModule.GetRedPointState(true);	
	self.nowDay = math.ceil((Time.now() - module.playerModule.GetCreateTime()) / 86400);
	self.curDay = self.nowDay;
	self.curSelect = 1;
	self.curIndex = 0;
	self.buyItem = 0;
	self.sendCount = 0;
	self.button_state = true;
	self.TypeUI = {};
	self.questList = {};
end

function View:InitView()
	--8D8888FF 0F0B05FF 483719FF
	CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.chat.gameObject.transform)
	self.tableView = self.view.bottom.ScrollView[CS.UIMultiScroller];
	self.tableView.RefreshIconCallback = function ( obj,idx )
		self:UpdateItem(obj,idx)
	end

	for i=1,7 do
		local item = self.view.top.days["day"..i];
		item[UnityEngine.UI.Toggle].interactable = (i <= self.curDay);
		CS.UGUIClickEventListener.Get(item.gameObject).onClick = function()
			item[UnityEngine.UI.Toggle].isOn = true;
			self:SwtichDays(i);
		end
		if self.curDay == i then
			item[UnityEngine.UI.Toggle].isOn = true;
		end
	end

	if self.curDay > 7 then
		self.curDay = 1;
		self.view.top.days.day1[UnityEngine.UI.Toggle].isOn = true;
	end

	CS.UGUIClickEventListener.Get(self.root.BG.gameObject,true).onClick = function()
		DialogStack.Pop();
	end

	CS.UGUIClickEventListener.Get(self.view.bottom.get.reward.gameObject).onClick = function()
		if #self.canSubmitQuest ~= 0 then
			for i,v in ipairs(self.canSubmitQuest) do
				self:UpdateButtonState(true);
				QuestModule.Submit(v.id);
			end
			self.canSubmitQuest = {};
		else
			showDlgError(nil, "暂无可领取的奖励")
		end
	end
	
	self:SwtichDays(self.curDay);
	self:RefreshRedPoint();
end


function View:UpdateItem( obj,idx )
	local color_str = {"<color=#00FFCDFF>", "<color=#FF0000FF>"};
	local item = CS.SGK.UIReference.Setup(obj);
	local questInfo = self.questList[idx + 1];
	if questInfo == nil then
		item:SetActive(false);
		return
	end
	local quest = QuestModule.Get(questInfo.id)
	item.Text[UnityEngine.UI.Text]:TextFormat(questInfo.name);
	for i=1,3 do
		if questInfo.reward[i] and questInfo.reward[i].id ~= 0 then
			local itemCfg = ItemHelper.Get(questInfo.reward[i].type,questInfo.reward[i].id);
			-- item.reward["item"..i].newItemIcon[SGK.newItemIcon]:SetInfo(itemCfg);
			-- item.reward["item"..i].newItemIcon[SGK.newItemIcon].showDetail = true;
			-- item.reward["item"..i].newItemIcon[SGK.newItemIcon].Count = questInfo.reward[i].value;
			if questInfo.reward[i].type == 42 then
				utils.IconFrameHelper.Create(item.reward["item"..i].IconFrame,{type = questInfo.reward[i].type, id = questInfo.reward[i].id, count = questInfo.reward[i].value,showDetail=true, customCfg = {level = 0, star = 0}})
			else
				utils.IconFrameHelper.Create(item.reward["item"..i].IconFrame,{type = questInfo.reward[i].type, id = questInfo.reward[i].id, count = questInfo.reward[i].value,showDetail=true})
			end
			item.reward["item"..i].name[UnityEngine.UI.Text]:TextFormat(itemCfg.name);
			item.reward["item"..i]:SetActive(true);
		else
			item.reward["item"..i]:SetActive(false);
		end
	end

	CS.UGUIClickEventListener.Get(item.Text.gameObject, true).onClick = function()
		print("信息", questInfo.id, QuestModule.CanSubmit(questInfo.id), quest.status, sprinttb(quest.records), sprinttb(questInfo.reward), sprinttb(questInfo.condition));
	end

	CS.UGUIClickEventListener.Get(item.get.gameObject).onClick = function()
		print("完成", questInfo.id);
		self.curIndex = idx;
		self:UpdateButtonState(true);
		QuestModule.Submit(questInfo.id);
	end

	item.already:SetActive(false);
	if quest and quest.status == 0 and questInfo.begin_time <= self.nowDay and tonumber(questInfo.desc1) <= self.nowDay then
		local canSubmit, error, count, idx = QuestModule.CanSubmit(questInfo.id);
		local str = item.Text[UnityEngine.UI.Text].text;
		SetButtonStatus(true, item.go);
		if questInfo.condition[2] and questInfo.condition[2].count ~= 0 then
			local color_str1 = quest.records[1] >= questInfo.condition[1].count and color_str[1] or color_str[2];
			local color_str2 = quest.records[2] >= questInfo.condition[2].count and color_str[1] or color_str[2];
			item.Text[UnityEngine.UI.Text]:TextFormat(str.."\n".."已完成 "..color_str1.."{0}</color>/<color=#00FFCDFF>{1}</color>\n<color=#00FFCDFF>已完成</color> "..color_str2.."{2}</color>/<color=#00FFCDFF>{3}</color>",quest.records[1],questInfo.condition[1].count,quest.records[2],questInfo.condition[2].count);
			item.Text[UnityEngine.UI.Text].fontSize = 20;
		elseif questInfo.condition[1] and questInfo.condition[1].count ~= 0  then
			local color_str1 = canSubmit and color_str[1] or color_str[2];
			if canSubmit then
				item.Text[UnityEngine.UI.Text]:TextFormat(str.."\n".."已完成 "..color_str1.."{0}</color>/<color=#00FFCDFF>{1}</color>", questInfo.condition[1].count,questInfo.condition[1].count);
			else
				item.Text[UnityEngine.UI.Text]:TextFormat(str.."\n".."已完成 "..color_str1.."{0}</color>/<color=#00FFCDFF>{1}</color>", count or questInfo.condition[1].count, questInfo.condition[1].count);
			end
			item.Text[UnityEngine.UI.Text].fontSize = 24;
		else
			item.Text[UnityEngine.UI.Text]:TextFormat(item.Text[UnityEngine.UI.Text].text);
			item.Text[UnityEngine.UI.Text].fontSize = 24;
		end
		if canSubmit then
			item.get:SetActive(true);
			item.go:SetActive(false);
		else
			item.get:SetActive(false);
			item.go:SetActive(true);
		end

		if item.go.gameObject.activeSelf then
			if questInfo.go_where ~= 0 and questInfo.go_where < 10000 then
				item.go.Text[UnityEngine.UI.Text]:TextFormat("前往");
				SetButtonStatus(true, item.go);
				CS.UGUIClickEventListener.Get(item.go.gameObject).onClick = function()
					print("前往",questInfo.id, canSubmit, quest.records[1], quest.status)
					QuestModule.StartQuestGuideScript(quest, true);
					
					-- local gotoConfig = QuestModule.GetGoWhereConfig(questInfo.go_where);
					-- if gotoConfig then
					-- 	local teamInfo = module.TeamModule.GetTeamInfo();
					-- 	if gotoConfig.gototype ~= 2 and teamInfo.group ~= 0 then
					-- 		showDlgError(nil, "请先解散队伍");
					-- 		return;
					-- 	end
					-- 	if openLevel.GetStatus(gotoConfig.go_level) then
					-- 		DialogStack.Pop();
					-- 		if gotoConfig.goto_quest_type ~= 0 then
					-- 			local cfg = QuestModule.GetQuestConfigByGuideType(gotoConfig.goto_quest_type);
					-- 			assert(cfg, gotoConfig.goto_quest_type.."引导类型任务不存在")
					-- 			table.sort( cfg, function ( a,b )
					-- 				return a.id < b.id;
					-- 			end )
					-- 			for i,v in ipairs(cfg) do
					-- 				local quest = QuestModule.Get(v.id);
					-- 				if i == 1 and quest.status == nil then
					-- 					showDlgError(nil,"请先完成 "..v.name);
					-- 					ERROR_LOG(v.id.."未领取");
					-- 					return;
					-- 				end
					-- 				if quest.status and quest.status == 0 then
					-- 					QuestModule.StartQuestGuideScript(QuestModule.Get(v.id), true);
					-- 					return;
					-- 				end
					-- 			end
					-- 		end
					-- 		if gotoConfig.go_quest ~= 0 and (QuestModule.Get(gotoConfig.go_quest).status == nil or QuestModule.Get(gotoConfig.go_quest).status == 0 )then
					-- 			if QuestModule.Get(gotoConfig.go_quest).status then
					-- 				QuestModule.StartQuestGuideScript(QuestModule.Get(gotoConfig.go_quest), true);
					-- 			else
					-- 				local cfg = QuestModule.GetCfg(gotoConfig.go_quest);
					-- 				assert(cfg, gotoConfig.go_quest.."任务配置不存在")
					-- 				showDlgError(nil,"请先完成 "..cfg.name);
					-- 				ERROR_LOG(gotoConfig.go_quest.."未领取");
					-- 			end
					-- 			return;
					-- 		end

					-- 		if gotoConfig.gototype == 1 and gotoConfig.findnpcname ~= 0 then
					-- 			local _tab = {}
					-- 			_tab.npc_id = gotoConfig.findnpcname;
					-- 			_tab.map_id = tonumber(gotoConfig.gotowhere)
					-- 			_tab.script = "guide/bounty/activityQuest.lua"
					-- 			QuestModule.StartQuestGuideScript(_tab, true)
					-- 		elseif gotoConfig.gototype == 2 then
					-- 			local arg = {};
					-- 			local tag = "UGUIRoot";
					-- 			if questInfo.go_where == 9 then
					-- 				arg = {heroid = 11000, HeroUItoggleid = 6};
					-- 			elseif questInfo.go_where == 15 or questInfo.go_where == 16 then
					-- 				arg = {heroid = 11000, HeroUItoggleid = 5};
					-- 			elseif questInfo.go_where == 19 then
					-- 				arg = {heroid = 11000, HeroUItoggleid = 3};
					-- 			elseif  questInfo.go_where == 11 or questInfo.go_where == 13 then
					-- 				arg = {idx = 2};
					-- 				tag = "UGUIRoot";
					-- 			end
					-- 			DialogStack.Push(gotoConfig.gotowhere, arg, tag)
					-- 		elseif gotoConfig.gototype == 3 then
					-- 			if gotoConfig.scriptname ~= "0" then
					-- 				SceneStack.Push(gotoConfig.gotowhere, gotoConfig.scriptname);
					-- 			else
					-- 				SceneStack.Push(gotoConfig.gotowhere, "view/"..gotoConfig.gotowhere..".lua");
					-- 			end				
					-- 		elseif gotoConfig.gototype == 4 then
					-- 			SceneStack.EnterMap(tonumber(gotoConfig.gotowhere))
					-- 		elseif gotoConfig.gototype == 5 then
					-- 			local mainQuest = QuestModule.GetList(10,0);
					-- 			if #mainQuest == 0 then
					-- 				showDlgError(nil, "主线任务已完成");
					-- 			elseif #mainQuest == 1 then
					-- 				QuestModule.StartQuestGuideScript(mainQuest[1], true);
					-- 			else
					-- 				table.sort( mainQuest, function ( a,b )
					-- 					return a.id > b.id
					-- 				end )
					-- 				print("引导任务", mainQuest[1].id, mainQuest[1].name)
					-- 				QuestModule.StartQuestGuideScript(mainQuest[1], true);
					-- 			end
					-- 		end
					-- 	else
					-- 		showDlgError(nil, "等级达到"..gotoConfig.go_level.."级开启本功能")
					-- 	end
					-- end
				end
			else
				item.go.Text[UnityEngine.UI.Text]:TextFormat("领取");
				SetButtonStatus(false, item.go);
			end
		end
	else
		item.get:SetActive(false);
		if quest and questInfo.begin_time <= self.nowDay and tonumber(questInfo.desc1) <= self.nowDay then
			item.go:SetActive(false);
			item.already:SetActive(true);
		else
			item.go:SetActive(true);
			item.go.Text[UnityEngine.UI.Text]:TextFormat("领取");
			SetButtonStatus(false, item.go);
		end
	end
	item.gameObject:SetActive(true);
end

function View:SwtichDays(day)
	self.curDay = day;
	if self.curSelect > #self.questType[day] then
		self.curSelect = 1;
	end
	local questInfo = self.allQuest[day];
	if questInfo then
		self:RefreshView();
	end
		-- for i,v in ipairs(self.questType[day]) do
		-- 	local item = nil;
		-- 	if self.TypeUI[i] == nil then
		-- 		local obj = UnityEngine.Object.Instantiate(self.view.top.type.item_type.gameObject);
		-- 		obj.transform:SetParent(self.view.top.type.gameObject.transform,false);
		-- 		obj.name = "type"..i;
		-- 		item = CS.SGK.UIReference.Setup(obj);
		-- 		CS.UGUIClickEventListener.Get(item.gameObject).onClick = function()
		-- 			self.curSelect = i;
		-- 			self:RefreshView();
		-- 		end
		-- 		self.TypeUI[i] = item;
		-- 	else
		-- 		item = self.TypeUI[i];
		-- 	end
		-- 	table.sort( questInfo[v], function ( a,b )
		-- 		return a.id < b.id;
		-- 	end )
		-- 	if questInfo[v][1] then
		-- 		item.Label[UnityEngine.UI.Text]:TextFormat(questInfo[v][1].button_des);
		-- 	end
		-- 	if self.redPointState[day][v] then
		-- 		item.red:SetActive(true);
		-- 	else
		-- 		item.red:SetActive(false);
		-- 	end
		-- 	item:SetActive(true);
		-- end
		-- if self.curSelect > #self.questType[day] then
		-- 	self.TypeUI[1][UnityEngine.UI.Toggle].isOn = true;
		-- else
		-- 	self.TypeUI[self.curSelect][UnityEngine.UI.Toggle].isOn = true;
		-- end
		-- if #self.TypeUI > #self.questType[day] then
		-- 	for i=#self.questType[day] + 1,#self.TypeUI do
		-- 		self.TypeUI[i]:SetActive(false);
		-- 	end
		-- end
end

function View:RefreshRedPoint()
	for i,v in ipairs(self.redPointState) do
		local item = self.view.top.days["day"..i];
		local visiable = false;
		for _,k in pairs(v) do
			if k then
				visiable = true;
				break
			end
		end
		item.point:SetActive(visiable);
	end

	-- for i,v in ipairs(self.questType[self.curDay]) do
	-- 	if self.redPointState[self.curDay][v] then
	-- 		self.TypeUI[i].red:SetActive(true);
	-- 	else
	-- 		self.TypeUI[i].red:SetActive(false);
	-- 	end
	-- end

end

-- function View:ShowDialog(type,data)
-- 	if self.isRunning then
-- 		return;
-- 	end
	
-- 	if type == 1 then
-- 		self.dialog.content.shop:SetActive(true);
-- 		self.dialog.content.pack:SetActive(false);
-- 		self.dialog.content.shop.Text[UnityEngine.UI.Text]:TextFormat("确认花费<color=#FDC003FF>{0}</color>钻石，抢购该物品么？", data.consume[1].value);
-- 		CS.UGUIClickEventListener.Get(self.dialog.content.shop.buy.gameObject).onClick = function()
-- 			self.buyItem = data.id;
-- 			self:UpdateButtonState(true);
-- 			QuestModule.Submit(data.id);
-- 		end
-- 	else
-- 		self.dialog.content.shop:SetActive(false);
-- 		self.dialog.content.pack:SetActive(true);
-- 		for i=1,5 do
-- 			local item = self.dialog.content.pack.pack["product"..i];
-- 			if data[i] and ItemHelper.Get(data[i].type,data[i].id) then
-- 				local cfg = ItemHelper.Get(data[i].type,data[i].id);
-- 				item.newItemIcon[SGK.newItemIcon]:SetInfo(cfg);
-- 				item.newItemIcon[SGK.newItemIcon].Count = data[i].Count;
-- 				item.name[UnityEngine.UI.Text]:TextFormat(cfg.name);
-- 				item:SetActive(true);
-- 				CS.UGUIClickEventListener.Get(item.newItemIcon.gameObject).onClick = function (obj)
-- 					DialogStack.PushPrefStact("ItemDetailFrame", {id = cfg.id, type = cfg.type,InItemBag=2}, self.view.gameObject)
-- 				end
-- 			else
-- 				item:SetActive(false);
-- 			end
-- 		end
-- 	end
-- 	self.dialog:SetActive(true);
-- 	self.isRunning = true;
-- 	self.dialog.bg[CS.UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(750,315),0.15):OnComplete(function()
-- 		self.dialog.content[UnityEngine.CanvasGroup]:DOFade(1,0.1):OnComplete(function ()
-- 			self.isRunning = false;
-- 		end);
-- 	end)
-- end

-- function View:CloseDialog()
-- 	if self.isRunning then
-- 		return;
-- 	end
-- 	if self.dialog.gameObject.activeSelf then
-- 		self.isRunning = true;
-- 		self.dialog.content[UnityEngine.CanvasGroup]:DOFade(0,0.1);
-- 		self.dialog.bg[CS.UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(750,60),0.1):OnComplete(function()
-- 			self.isRunning = false;
-- 			self.dialog:SetActive(false);
-- 		end)
-- 	end
-- end

function View:UpdateButtonState(flag)
	if flag then
		self.sendCount = self.sendCount + 1;
	else
		self.sendCount = self.sendCount - 1;
	end
	if self.sendCount < 0 then
		self.sendCount = 0;
	end
	if self.sendCount > 0 and self.button_state then
		self.button_state = false;
		-- if self.dialog.content.shop.activeSelf then
		-- 	SetButtonStatus(false, self.dialog.content.shop.buy);
		-- end
		-- SetButtonStatus(false, self.view.bottom.get.reward)
		self.view.bottom.get:SetActive(false);
		for i=1,self.tableView.DataCount do
			local obj = self.tableView:GetItem(i - 1);
			if obj then
				local item = CS.SGK.UIReference.Setup(obj);
				SetButtonStatus(false, item.get)
			end
		end
	elseif self.sendCount == 0 and not self.button_state then
		self.button_state = true;
		-- if self.dialog.content.shop.activeSelf then
		-- 	SetButtonStatus(true, self.dialog.content.shop.buy);
		-- end
		-- SetButtonStatus(#self.canSubmitQuest ~= 0 , self.view.bottom.get.reward);
		self.view.bottom.get:SetActive(#self.canSubmitQuest ~= 0);
		for i=1,self.tableView.DataCount do
			local obj = self.tableView:GetItem(i - 1);
			if obj then
				local item = CS.SGK.UIReference.Setup(obj);
				SetButtonStatus(true, item.get)
			end
		end
	end
end

function View:RefreshView(idx)
	if idx then
		local obj = self.tableView:GetItem(idx);
		if obj then
			self:UpdateItem(obj,idx)
		end	
	else
		if self.allQuest[self.curDay][2] then
			local questInfo = self.allQuest[self.curDay][2][1];
			if questInfo then
				-- print("商品信息",sprinttb(questInfo));
				local itemCfg = ItemHelper.Get(questInfo.consume[1].type, questInfo.consume[1].id);
				self.view.bottom.shop.old_price.price[UnityEngine.UI.Text].text = tostring(questInfo.consume[1].value + 200);
				self.view.bottom.shop.new_price.price[UnityEngine.UI.Text].text = tostring(questInfo.consume[1].value);
				self.view.bottom.shop.old_price.Image[UI.Image]:LoadSprite("icon/"..itemCfg.icon.."_small");
				self.view.bottom.shop.new_price.Image[UI.Image]:LoadSprite("icon/"..itemCfg.icon.."_small");
				self.view.bottom.shop.old_price.Image.transform.localScale = Vector3.one * 0.9;
				self.view.bottom.shop.new_price.Image.transform.localScale = Vector3.one * 0.9;
				
				self.view.bottom.shop.day[UnityEngine.UI.Text]:TextFormat("第{0}天礼包", str_day[self.curDay])
				
				if QuestModule.Get(questInfo.id) == nil then
					print(questInfo.name.."不存在", questInfo.id);
				end
				if self.nowDay < self.curDay then
					self.view.bottom.shop.buy.Text[CS.UnityEngine.UI.Text]:TextFormat("尚未开始");
					SetButtonStatus(false, self.view.bottom.shop.buy);
				elseif (QuestModule.Get(questInfo.id) == nil or QuestModule.Get(questInfo.id).status == 1) then
					self.view.bottom.shop.buy.Text[CS.UnityEngine.UI.Text]:TextFormat("已购买");
					SetButtonStatus(false, self.view.bottom.shop.buy);
				else
					self.view.bottom.shop.buy.Text[CS.UnityEngine.UI.Text]:TextFormat("立即购买");
					SetButtonStatus(true, self.view.bottom.shop.buy);
				end

				if questInfo.reward_id1 ~= 0 then
					ItemModule.GetGiftItem(questInfo.reward_id1, function(data)
						for i=1,6 do
							local item = self.view.bottom.shop.gift_bag["item"..i];
							if data[i] and data[i][2] ~= questInfo.reward_id1 then
								if data[i][1] == 42 then
									utils.IconFrameHelper.Create(item,{type = data[i][1], id = data[i][2], count = data[i][3], showDetail = true, customCfg = {level = 0, star = 0}})
								else
									utils.IconFrameHelper.Create(item,{type = data[i][1], id = data[i][2], count = data[i][3], showDetail = true})
								end
								item:SetActive(true);
							else
								item:SetActive(false);
							end
						end
					end)
				end

				CS.UGUIClickEventListener.Get(self.view.bottom.shop.buy.gameObject).onClick = function()
					local itemCfg = ItemHelper.Get(questInfo.consume[1].type, questInfo.consume[1].id)
					if ItemModule.GetItemCount(questInfo.consume[1].id) >= questInfo.consume[1].value then
						-- self:ShowDialog(1,questInfo);
						local data = {};
						data.msg = "确认花费<color=#C79600FF>"..questInfo.consume[1].value.."</color>"..itemCfg.name.."，购买该礼包么？";
						data.confirm = function ()
							QuestModule.Submit(questInfo.id);
						end;
						data.title = "购买确认";
						DlgMsg(data)
					else
						showDlgError(nil,itemCfg.name.."不足");
					end
				end
				self.view.bottom.shop:SetActive(true);
			else
				self.view.bottom.shop:SetActive(false);
			end
		end

		local questType = self.questType[self.curDay][self.curSelect];
		local _questList = {};
		self.canSubmitQuest = {};
		if self.curDay <= self.nowDay then
			self.view.bottom.get:SetActive(true);
			local questList = self.questListByShowType[self.curDay][questType];
			local insert = true;
			for _,v in pairs(questList) do
				for i,k in ipairs(v) do
					local quest = QuestModule.Get(k.id);
					if quest then
						if quest.status == 0 then
							if QuestModule.CanSubmit(k.id) then
								table.insert(self.canSubmitQuest, k);
							end
							if insert then
								table.insert(_questList, k);
								insert = false;
							end
						elseif #v == i then
							if insert then
								table.insert(_questList, k);
								insert = false;
							end
						end
					else
						ERROR_LOG(k.name.."不存在", k.id);
						-- showDlgError(nil, k.name.."不存在")
					end
				end
				insert = true;
			end
			-- SetButtonStatus(#self.canSubmitQuest ~= 0 , self.view.bottom.get.reward);
			self.view.bottom.get:SetActive(#self.canSubmitQuest ~= 0)
		else
			self.view.bottom.get:SetActive(false);				
			local questList = self.questListByShowType[self.curDay][questType];
			for k,v in pairs(questList) do
				table.insert(_questList, v[1]);
			end
		end	
		table.sort(_questList,function ( a,b )
			return a.id < b.id;
		end)
		-- print("测试",sprinttb(_questList))
		self.questList = _questList;
		self.tableView.DataCount = 0;
		self.tableView.DataCount = #self.questList + 1;
		self.tableView:ItemRef();
		self.view.bottom.ScrollView:SetActive(true);
	end
end

function View:Update()
	if Time.now() - self.updateTime > 1 then
		self.updateTime = Time.now();
		local time = self.endTime - Time.now();
		if time > 0 then
		--print("时间"，time, GetTimeFormat(time))
			self.view.top.time[UnityEngine.UI.Text]:TextFormat(GetTimeFormat(time, 1));
		else
			self.view.top.time[UnityEngine.UI.Text]:TextFormat("活动已结束");
			showDlgError(nil, "活动已结束");
			DispatchEvent("7DaysActive",false);
			DialogStack.Pop();
		end
	end
end

function View:deActive()
	-- if self.dialog.gameObject.activeSelf then
	-- 	self:CloseDialog();
	-- 	return false;
	-- end
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
		"QUEST_INFO_CHANGE",
		"LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "QUEST_INFO_CHANGE"  then
		--self:RefreshView(self.curIndex);
		self:RefreshView();
		self.redPointState = QuestModule.GetRedPointState(true);
		self:RefreshRedPoint();
		self:UpdateButtonState(false);
		local quest = ...;
		if quest and quest.id == self.buyItem and quest.status == 1 then
			self:CloseDialog();
			showDlgError(nil,"购买成功");
			-- ItemModule.OpenGiftBag(quest.reward[1].id, 1);
			self.buyItem = 0;
		end
	elseif event == "LOCAL_GUIDE_CHANE" then
		module.guideModule.PlayByType(129, 0.1)
	end
end

return View;