local heroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local PVPArenaModule = require "module.PVPArenaModule"
local playerModule = require "module.playerModule"
local UserDefault = require "utils.UserDefault"
local Time = require "module.Time"
local HeroEvo = require "hero.HeroEvo"
local Property = require "utils.Property"
local npc_move = require "guide.npc.pvparena_npc_move"
local unionModule = require "module.unionModule"
local TipConfig = require "config.TipConfig"
local battleConfig = require "config.battle"

local View = {};
local Number = {"Ⅰ","Ⅱ","Ⅲ","Ⅳ","Ⅴ","Ⅵ","Ⅶ","Ⅷ","Ⅸ"}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self.dialog = self.view.dialog;
	self.rank = self.dialog.arenaRank;
	self.tableview = self.rank.ScrollView.Viewport.Content[CS.ScrollViewContent];
	self:InitData();
	self:InitView();
	PVPArenaModule.CheckRankChange();
	module.guideModule.PlayByType(31, 0.2);
end

function View:InitData()
	-- CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"), self.view.chat.transform)
	self.found = false;
	self.found_pvp = false;
	self.manager = heroModule.GetManager();
	self.lineup = PVPArenaModule.GetPlayerFormation(1) and PVPArenaModule.GetPlayerFormation(1).formation or {};
	PVPArenaModule.GetPlayerFormation(2);
	PVPArenaModule.GetPlayerInfoFromServer();
	self.arena_property = PVPArenaModule.GetArenaProperty();
	-- self.matching = PVPArenaModule.GetMatchingState();
	self.initRank = false;
	self.matching = false;
	self.pvp_matching = false;
	self.tiktok = false;
	self.change_value = 0;
	self.refresh = false;
	self.time = 0;
	self.action_queue = {};
	PVPArenaModule.GetBattleLog();
	self.update_time = 0;
    self.content = self.view.center.bg;
    self.controller = self.content[SGK.DialogPlayerMoveController];
    self.lineup_character = {};
	print("lineup",sprinttb(self.lineup));
	PVPArenaModule.SetViewData(self.content);
end

function View:InitView()
	local _shopCfg = module.ShopModule.Load(4002);
	--显示刷新道具
	local itemid = {};
	for i=1,4 do
		table.insert(itemid, _shopCfg["top_resource_id"..i])
	end
	DialogStack.PushPref("CurrencyChat",{itemid = itemid}, self.view.chat);

	CS.UGUIClickEventListener.Get(self.view.bottom.PVE.gameObject,true).onClick = function ( object )
		if not self.view.bottom.PVE[UnityEngine.UI.Button].interactable then
			return;
		end
		
		if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗内无法进行该操作")
            return;
        end
        if utils.SGKTools.GetTeamState() then
            showDlgError(nil, "队伍内无法进行该操作")
            return;
		end

		if not self:CheckOpen(1) then
			showDlgError(nil, "未到开启时间")
			return;
		end

		local info = PVPArenaModule.GetPlayerInfo();
		if self.arena_property[1].pvparena_times - info.matching_count > 0 then
			self.matching = not self.matching;
			if self.matching then
				self.view.bottom.PVE.Text[UnityEngine.UI.Text]:TextFormat("停止匹配");
				self:UpdateButtonState(false, self.view.bottom.PVP, 2);
				self:UpdateButtonState(false, self.view.bottom.lineup);
				self:UpdateButtonState(false, self.view.bottom.refresh);
				-- self.view.bottom.PVP[UnityEngine.UI.Button].interactable = false;
				-- self.view.bottom.lineup[UnityEngine.UI.Button].interactable = false;
			else
				self.view.bottom.PVE.Text[UnityEngine.UI.Text]:TextFormat("突袭");
				self:UpdateButtonState(true, self.view.bottom.PVP, 2);
				self:UpdateButtonState(true, self.view.bottom.lineup);
				self:UpdateButtonState(true, self.view.bottom.refresh);
				-- self.view.bottom.PVP[UnityEngine.UI.Button].interactable = true;
				-- self.view.bottom.lineup[UnityEngine.UI.Button].interactable = true;
			end
			PVPArenaModule.StartPVEMatching(self.matching);
			self:SetMatchingStatus(self.matching);
			self.tiktok = self.matching;
			if not self.matching then
				self.time = 0;
			end
		else
			showDlgError(nil, "今日匹配次数已用完")
		end
		
	end
	

	CS.UGUIClickEventListener.Get(self.view.bottom.PVP.gameObject,true).onClick = function ( object )
		-- self:PrepareStartFight();
		if not self.view.bottom.PVP[UnityEngine.UI.Button].interactable then
			return;
		end

		if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗内无法进行该操作")
            return;
        end
        if utils.SGKTools.GetTeamState() then
            showDlgError(nil, "队伍内无法进行该操作")
            return;
		end
		
		if not self:CheckOpen(2) then
			showDlgError(nil, "未到开启时间")
			return;
		end
		
		-- local info = PVPArenaModule.GetPlayerInfo();
		-- if info.pvp_matching_count >= self.arena_property[2].pvparena_times then
		-- 	showDlgError(nil, "今日匹配次数已用完")
		-- 	return;
		-- end

		if self.pvp_matching then
			PVPArenaModule.CancelPVPMatching();
		else
			PVPArenaModule.StartPVPMatching();
		end
	end

	CS.UGUIClickEventListener.Get(self.view.top.rank_btn.gameObject).onClick = function ( object )
		self:InitRank();
		self.rank:SetActive(true);
	end
	
	-- self.view.top.reward_btn[UnityEngine.UI.Toggle].onValueChanged:AddListener(function (value)
	-- 	self.view.top.reward:SetActive(value);
	-- end)

    -- CS.UGUIPointerEventListener.Get(self.view.top.reward_btn.gameObject).onPointerDown = function(go, pos)
    --     self.view.top.reward:SetActive(true);
    -- end
    -- CS.UGUIPointerEventListener.Get(self.view.top.reward_btn.gameObject).onPointerUp = function(go, pos)
    --    self.view.top.reward:SetActive(false);
    -- end

	CS.UGUIClickEventListener.Get(self.view.top.reward_btn.gameObject).onClick = function (obj)
		DialogStack.PushPref("rankList/rankGiftFrame", {type = 3, notPop = 1}, self.view.dialog)
	end
	
	CS.UGUIClickEventListener.Get(self.view.center.npc.gameObject, true).onClick = function (obj)
		self:SwitchLog();
		-- npc_move.arena_npc_waiting()
		-- local log = PVPArenaModule.GetBattleLog();
		-- print("日志",sprinttb(log))
	end
	CS.UGUIClickEventListener.Get(self.view.top.help_btn.gameObject).onClick = function (obj)
		utils.SGKTools.ShowDlgHelp(TipConfig.GetAssistDescConfig(84001).info, nil, self.dialog)
	end

	CS.UGUIClickEventListener.Get(self.dialog.log.BG.gameObject, true).onClick = function (obj)
		self:SwitchLog();
	end
	
	CS.UGUIClickEventListener.Get(self.dialog.log.textarea.title.close.gameObject, true).onClick = function (obj)
		self:SwitchLog();
	end

	CS.UGUIClickEventListener.Get(self.dialog.eixt.bg.ok.gameObject).onClick = function (obj)
		if self.matching then
			PVPArenaModule.StartPVEMatching(false);
			self.matching = false;
		end
		if self.pvp_matching then
			PVPArenaModule.CancelPVPMatching();
			self.pvp_matching = false;
		end
		DialogStack.Pop();
	end

	self:UpdateRedPoint();

	CS.UGUIClickEventListener.Get(self.view.bottom.lineup.gameObject).onClick = function ( object )
		if not self.view.bottom.lineup[UnityEngine.UI.Button].interactable then
			return;
		end

		if self.lineup and #self.lineup ~= 0 then
			local online = {0,0,0,0,0};
			for i,v in ipairs(self.lineup) do
				local hero = self.manager:GetByUuid(v);
				if hero then
					online[i] = hero.id;
				end
			end
			--DialogStack.Push('Arena_Lineup',{online = online});
			DialogStack.PushPrefStact('FormationDialog', {online = online, type = 2}, UnityEngine.GameObject.FindWithTag("UGUIRootTop"));
		else
			--DialogStack.Push('Arena_Lineup');
			DialogStack.PushPrefStact('FormationDialog', {type = 2}, UnityEngine.GameObject.FindWithTag("UGUIRootTop"));
		end
	end

	CS.UGUIClickEventListener.Get(self.view.bottom.refresh.gameObject).onClick = function ( object )
		PVPArenaModule.GetPlayerFormation(2,nil,function (info)
			self.refresh = true;
			PVPArenaModule.SetFormation(info.formation, 2);
		end)
	end

	-- local info = PVPArenaModule.GetPlayerInfo();
	-- if info then
	-- 	self:UpdatePlayerInfo(info)
	-- end

	if self.lineup then
		self:UpdateFormation(self.lineup);
	end

	-- if self.matching then
	-- 	self.view.matching.start.Text[UnityEngine.UI.Text]:TextFormat("停止匹配");
	-- else
	-- 	self.view.matching.start.Text[UnityEngine.UI.Text]:TextFormat("开始匹配");
	-- end
    -- self.view.matching.time:SetActive(self.matching);
	self.view.center.state2.name[UnityEngine.UI.Text].text = playerModule.Get().name;
end

function View:UpdateRedPoint()
	local visiable,change_value = PVPArenaModule.CheckCapacity();
	self.change_value = change_value;
	self.view.bottom.refresh.tip:SetActive(visiable);

	-- self.view.bottom.lineup.tip:SetActive(visiable);
	-- self.view.bottom.lineup.Image:SetActive(visiable);
	-- self.view.bottom.lineup[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Horizontal, 180);
end


function View:InitRank()
	self.rankList = {};
	local rankList = PVPArenaModule.GetRankList(true);
	local info = PVPArenaModule.GetPlayerInfo();
	if rankList then
		self.rankList = rankList;
	end
	
	if not self.initRank then
		print("初始化", sprinttb(self.rankList))
		self.initRank = true;
		CS.UGUIClickEventListener.Get(self.rank.title.close.gameObject, true).onClick = function ( object )
			self.rank:SetActive(false);
		end
		
		self.tableview.RefreshIconCallback = function (obj,index)	
			local item = CS.SGK.UIReference.Setup(obj);
			if self.rankList[index + 1] then
				local rank = index + 1;
				local info = self.rankList[index + 1];
				if rank <= 3 then
					item.top:SetActive(true);
					item.rank:SetActive(false);
					item.top.Text[UnityEngine.UI.Text].text = tostring(rank);
					item.top[UnityEngine.UI.Image]:LoadSprite("icon/rank_"..rank)
				else
					item.top:SetActive(false);
					item.rank:SetActive(true);
					item.rank[UnityEngine.UI.Text].text = tostring(rank);
				end
	
				local str,stage,num = PVPArenaModule.GetRankName(info.score);
				
				item.rank_name[UnityEngine.UI.Text]:TextFormat(str..Number[num]);
				item.rich[UnityEngine.UI.Text].text =  self:GetWealthString(info.score);
				item.bg1:SetActive(playerModule.GetSelfID() ~= info.pid);
				item.bg2:SetActive(playerModule.GetSelfID() == info.pid);
		
				if info.pid > 110000 or info.pid < 100000 then
					local union = unionModule.GetPlayerUnioInfo(info.pid);
					if union.haveUnion then
						local unionName = union.haveUnion == 1 and union.unionName or "无"
						item.guild[UnityEngine.UI.Text]:TextFormat(unionName);
					else
						unionModule.queryPlayerUnioInfo(info.pid,(function ( ... )
							local unionName = unionModule.GetPlayerUnioInfo(info.pid).unionName or "无"
							item.guild[UnityEngine.UI.Text]:TextFormat(unionName);
						end))
					end
					
					playerModule.Get(info.pid,function ( ... )
						local player = playerModule.Get(info.pid);
						-- item.newCharacterIcon[SGK.newCharacterIcon]:SetInfo(player, true);
						-- utils.PlayerInfoHelper.GetPlayerAddData(info.pid, 99,function (addData)
						-- 	item.newCharacterIcon[SGK.newCharacterIcon].sex = addData.Sex;
						-- 	item.newCharacterIcon[SGK.newCharacterIcon].headFrame = addData.HeadFrame;
						-- end)
						utils.IconFrameHelper.Create(item.IconFrame, {pid = player.id});
						item.name[UnityEngine.UI.Text].text = player.name; 
					end)
				else
					local npc_config = PVPArenaModule.GetNPCStatus(info.pid);
					if npc_config then
						-- item.newCharacterIcon[SGK.newCharacterIcon]:SetInfo({head = npc_config.cfg.icon, level = npc_config.heros[1].level, vip = npc_config.cfg.vip_lv}, true);
						-- item.newCharacterIcon[SGK.newCharacterIcon].sex = npc_config.cfg.Sex;
						-- item.newCharacterIcon[SGK.newCharacterIcon].headFrame = npc_config.cfg.HeadFrameId;
						local headIconCfg = module.ItemModule.GetShowItemCfg(npc_config.cfg.HeadFrameId)
						local headFrame = headIconCfg and headIconCfg.effect or ""

						utils.IconFrameHelper.Create(item.IconFrame,{customCfg = {head = npc_config.cfg.icon, level = npc_config.heros[1].level, vip = npc_config.cfg.vip_lv , pid = info.pid, HeadFrame = headFrame}})
						item.name[UnityEngine.UI.Text].text = npc_config.cfg.name; 
					end
					item.guild[UnityEngine.UI.Text]:TextFormat("无");
				end
				item:SetActive(true);
			end
		end
		
		if info and info.rank <= 50 then
			self.rank.ScrollView[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(720,-252)
		end
	end
	
	self.tableview.DataCount = #self.rankList;
	-- self.rank.ScrollView[UnityEngine.RectTransform]:SetInsetAndSizeFromParentEdge(UnityEngine.RectTransform.Edge.Top, 0, 152)
	-- self.rank.ScrollView[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical, 1083);
	if info and info.rank <= 50 then
		local move_height = info.rank * 117 - self.rank.ScrollView[UnityEngine.RectTransform].rect.height;
		if move_height > 0 then
			local num = math.ceil(move_height / 117);
			self.rank.ScrollView.Viewport.Content.transform:DOLocalMove(Vector3(0, move_height, 0), num * 0.05):SetDelay(0.1):SetEase(CS.DG.Tweening.Ease.InOutQuad);
		end
	end
end

function View:CheckOpen(idx)
	local cfg = self.arena_property[idx]
	return CheckActiveTime(cfg);
end

function View:UpdateFormation(lineup)
	local isUUid = true;
	if #lineup == 0 then
		isUUid = false;
		lineup = self.manager:GetFormation();
	end

	local capacity = 0;
	local count = 0;
	for i=1,5 do
		if self.lineup_character[i] then
			count = count + 1;
		end
	end

	local addNew = function ()
		if count == 0 then
			for i=1,5 do
				if lineup[i] ~= 0 then
					local hero = nil;
					if isUUid then
						hero = self.manager:GetByUuid(lineup[i]);
					else
						hero = self.manager:Get(lineup[i]);
					end
					if hero then
						capacity = capacity + hero.capacity;
						self:AddNewCharacter(hero,i);
						self.view.center.state2.capacity[UnityEngine.UI.Text].text = tostring(math.floor(capacity));
					end
				end
			end
		end
	end

	if count == 0 then
		addNew();
	else
		for i=1,5 do
			if self.lineup_character[i] then
				local _id = self.lineup_character[i].id * 10 + 1;
				self.controller:MoveCharacter(_id, "start",function ()
					self.controller:Remove(_id);
					self.lineup_character[i] = nil;
					count = count - 1;
					addNew();
				end)
			end
		end
	end

	-- for i=1,5 do
	-- 	if lineup[i] and lineup[i] ~= 0 then
	-- 		local hero_id = 0;
	-- 		if isUUid then
	-- 			hero_id = self.manager:GetByUuid(lineup[i]).id;
	-- 		else
	-- 			hero_id = lineup[i];
	-- 		end
	-- 		local heroCfg = ItemHelper.Get(ItemHelper.TYPE.HERO,hero_id); 
	-- 		if heroCfg then
	-- 			capacity = capacity + heroCfg.capacity;
    --             if self.lineup_character[i] then
	-- 				if heroCfg.id ~= self.lineup_character[i].id then
	-- 					local _id = self.lineup_character[i].id * 10 + 1;
	-- 					self.controller:MoveCharacter(_id, "start",function ()
	-- 						self.controller:Remove(_id);
	-- 						self:AddNewCharacter(heroCfg,i);
	-- 					end)
	-- 				end
    --             else
	-- 				self:AddNewCharacter(heroCfg,i);
    --             end		
    --         elseif self.lineup_character[i] then
    --             --self.lineup_character[i]:SetActive(false);
	-- 			local _id = self.lineup_character[i].id * 10 + 1;
	-- 			self.controller:MoveCharacter(_id, "start",function ()
	-- 				self.controller:Remove(_id);
	-- 				self.lineup_character[i] = nil;
	-- 			end)
	-- 		end
    --     elseif self.lineup_character[i] then
    --         --self.lineup_character[i]:SetActive(false);
	-- 		local _id = self.lineup_character[i].id * 10 + 1;
	-- 		self.controller:MoveCharacter(_id, "start",function ()
	-- 			self.controller:Remove(_id);
	-- 			self.lineup_character[i] = nil;
	-- 		end)
	-- 	end
	-- end

end

function View:LoadSkeleton(animation, id, mode)
	local resource = nil;
	if id then
		resource = utils.SGKTools.loadExistSkeletonDataAsset("roles_small/", id, mode,"_SkeletonData.asset");
	else
		resource = SGK.ResourcesManager.Load("roles_small/"..mode.."/"..mode.."_SkeletonData.asset") or SGK.ResourcesManager.Load("roles_small/11000/11000_SkeletonData.asset");
	end
	if resource then
		animation.skeletonDataAsset = resource;
		animation:Initialize(true);	
	end
end

function View:AddNewCharacter(hero,index)
	local obj = UnityEngine.Object.Instantiate(self.content.dialog_character.gameObject, self.content.gameObject.transform);
	obj.name = tostring(hero.id);
	local character = CS.SGK.UIReference.Setup(obj);
	character.gameObject.transform.localPosition = self.controller:GetPoint("start");
	-- self.lineup_character[index] = character;
	local player = self.controller:Add(hero.id * 10 + 1, obj);
	player:SetSpeed(7);
	--character[SGK.DialogPlayer]:UpdateSkeleton(tostring(hero.mode));
	self:LoadSkeleton(character.spine[CS.Spine.Unity.SkeletonGraphic], hero.id, hero.mode);
	character:SetActive(true);
	character.spine[SGK.DialogSprite].direction = 6;
	self.controller:MoveCharacter(hero.id * 10 + 1, "atk"..index)
	local info = {};
	info.id = hero.id;
	info.character = character;
	self.lineup_character[index] = info;
end

function View:GetWealthString(wealth)
	local yi = math.floor(wealth/100000000);
	local wan = math.floor((wealth - yi * 100000000)/10000);
	return (yi > 0 and yi.."亿" or "")..( wan > 0 and wan.."万" or "");
end

function View:GetWealthClass(wealth)
	local class = 1;
	if wealth < 2000000 then
		class = 1;
	elseif wealth < 10000000 then
		class = math.floor(wealth/1000000);
	elseif wealth < 100000000 then
		class = 9 + math.floor(wealth/10000000);
	else
		class = 19;
	end
	return class;
end

function View:UpdateButtonState(state, button, type)
	local gray_material = self.view.bottom.lineup[CS.UnityEngine.MeshRenderer].materials[0];
	local info = PVPArenaModule.GetPlayerInfo();
	if state then
		if type then
			local count = type == 1 and info.matching_count or info.pvp_matching_count;
			if self:CheckOpen(type) and self.arena_property[type].pvparena_times - count > 0 then
				SetButtonStatus(true, button, gray_material);
			else
				SetButtonStatus(false, button, gray_material);
			end
		else
			SetButtonStatus(state, button, gray_material);
		end
	else
		SetButtonStatus(state, button, gray_material);
	end
end

function View:UpdatePlayerInfo(info)
	self.view.center.state2.financial[UnityEngine.UI.Text]:TextFormat(self:GetWealthString(info.wealth));
	
	if self.arena_property[1].pvparena_times - info.matching_count > 0 then
		self.view.bottom.PVE.count[UnityEngine.UI.Text]:TextFormat("<color=#00C32CFF>{0}/{1}</color>",self.arena_property[1].pvparena_times - info.matching_count,self.arena_property[1].pvparena_times)
	else
		self.view.bottom.PVE.count[UnityEngine.UI.Text]:TextFormat("<color=#C60000FF>{0}/{1}</color>",self.arena_property[1].pvparena_times - info.matching_count,self.arena_property[1].pvparena_times)
	end
	if self:CheckOpen(2) then
		self.view.bottom.PVP.count[UnityEngine.UI.Text]:TextFormat("<color=#00C32CFF>活动进行中</color>",self.arena_property[2].pvparena_times - info.pvp_matching_count,self.arena_property[2].pvparena_times)
		self:UpdateButtonState(true, self.view.bottom.PVP, 2);
	else
		self.view.bottom.PVP.count[UnityEngine.UI.Text]:TextFormat("<color=#C60000FF>活动未开始</color>",self.arena_property[2].pvparena_times - info.pvp_matching_count,self.arena_property[2].pvparena_times)
		self:UpdateButtonState(false, self.view.bottom.PVP, 2);
	end

	self:UpdateButtonState(self.arena_property[1].pvparena_times - info.matching_count > 0, self.view.bottom.PVE, 1);
	

	local str,stage,num = PVPArenaModule.GetRankName(info.wealth);

	self.view.top.rank[CS.UnityEngine.UI.Image]:LoadSprite("icon/cl_"..stage, true);
	if stage == 1 then
		self.view.top.rank.class.gameObject.transform.localPosition = Vector3(0,-76.5,0);
	else
		self.view.top.rank.class.gameObject.transform.localPosition = Vector3(0,-68.5,0);
	end
	
	self.view.top.rank.class[UnityEngine.UI.Text].text = Number[num];
	self.view.top.rank.name[UnityEngine.UI.Text]:TextFormat(str);
	self.view.top.rank.num[UnityEngine.UI.Text].text = tostring(info.rank);
	local class = self:GetWealthClass(info.wealth);
	local day_reward = PVPArenaModule.GetRankReward(1, class);
	if day_reward then
		self.view.top.reward.day:SetActive(true);
		for i=1,2 do
			if day_reward["Item_id"..i] ~= 0 then
				local cfg = ItemHelper.Get(day_reward["Item_type"..i],day_reward["Item_id"..i]);
				self.view.top.reward.day["item"..i].icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..cfg.icon.."_small");
				self.view.top.reward.day["item"..i].count[CS.UnityEngine.UI.Text].text = tostring(day_reward["Item_value"..i]);
				self.view.top.reward.day["item"..i]:SetActive(true);
				CS.UGUIClickEventListener.Get(self.view.top.reward.day["item"..i].icon.gameObject).onClick = function (obj)
					DialogStack.PushPrefStact("ItemDetailFrame", {id = cfg.id, type = cfg.type}, self.view.gameObject)
				end
			else
				self.view.top.reward.day["item"..i]:SetActive(false);
			end
		end
	else
		self.view.top.reward.day:SetActive(false);
	end

	local week_reward = PVPArenaModule.GetRankReward(2, class);
	if week_reward then
		self.view.top.reward.week:SetActive(true);
		for i=1,2 do
			if week_reward["Item_id"..i] ~= 0 then
				local cfg = ItemHelper.Get(week_reward["Item_type"..i],week_reward["Item_id"..i]);
				self.view.top.reward.week["item"..i].icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..cfg.icon.."_small");
				self.view.top.reward.week["item"..i].count[CS.UnityEngine.UI.Text].text = tostring(week_reward["Item_value"..i]);
				self.view.top.reward.week["item"..i]:SetActive(true);
				CS.UGUIClickEventListener.Get(self.view.top.reward.week["item"..i].icon.gameObject).onClick = function (obj)
					DialogStack.PushPrefStact("ItemDetailFrame", {id = cfg.id, type = cfg.type}, self.view.gameObject)
				end
			else
				self.view.top.reward.week["item"..i]:SetActive(false);
			end
		end
	else
		self.view.top.reward.week:SetActive(false);
	end

	if info.rank > 50 then
		self.rank.playerInfo:SetActive(true);
		if info.rank <= 3 then
			self.rank.playerInfo.top:SetActive(true);
			self.rank.playerInfo.rank:SetActive(false);
			self.rank.playerInfo.top.Text[UnityEngine.UI.Text].text = tostring(info.rank);
			self.rank.playerInfo.top[UnityEngine.UI.Image]:LoadSprite("icon/rank_"..info.rank)
		else
			self.rank.playerInfo.top:SetActive(false);
			self.rank.playerInfo.rank:SetActive(true);
			self.rank.playerInfo.rank[UnityEngine.UI.Text].text = tostring(info.rank);
		end
		
		self.rank.playerInfo.rank_name[UnityEngine.UI.Text]:TextFormat(str..Number[num]);
		self.rank.playerInfo.rich[UnityEngine.UI.Text].text = self:GetWealthString(info.wealth);
		local player = playerModule.Get();
		-- self.rank.playerInfo.newCharacterIcon[SGK.newCharacterIcon]:SetInfo(player, true);
		-- utils.PlayerInfoHelper.GetPlayerAddData(0, nil,function (addData)
		-- 	self.rank.playerInfo.newCharacterIcon[SGK.newCharacterIcon].sex = addData.Sex
		-- 	self.rank.playerInfo.newCharacterIcon[SGK.newCharacterIcon].headFrame = addData.HeadFrame
		-- end)
		utils.IconFrameHelper.Create(self.rank.playerInfo.IconFrame, {pid = player.id})
		self.rank.playerInfo.name[UnityEngine.UI.Text].text = player.name; 
		unionModule.queryPlayerUnioInfo(player.id,(function ( ... )
			local unionName = unionModule.GetPlayerUnioInfo(player.id).unionName or "无"
			self.rank.playerInfo.guild[UnityEngine.UI.Text]:TextFormat(unionName);
		end))
	else
		self.rank.playerInfo:SetActive(false);
	end

end

function View:SwitchLog()
	if self.isRunning then
		return false;
	end
	
	if self.dialog.log.textarea.ScrollView[UnityEngine.CanvasGroup].alpha == 0 then
		local log = PVPArenaModule.GetBattleLog();
		
		local str = ""
		for i=#log,1,-1 do
			str = str..log[i].."\n";
		end
		self.dialog.log.textarea.ScrollView.Viewport.Content.Text[CS.UnityEngine.UI.Text].text = str;

		self.dialog.log:SetActive(true);
		self.isRunning = true;
		self.dialog.log.textarea[CS.UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(700,365),0.15)--:OnComplete(function ()	end)
		if #log == 0 then
			self.dialog.log.textarea.Text[UnityEngine.UI.Text]:DOFade(1,0.15);
		end
		self.dialog.log.textarea.ScrollView[UnityEngine.CanvasGroup]:DOFade(1,0.15):OnComplete(function()
			self.isRunning = false;
		end)
	else
		self.isRunning = true;
		self.dialog.log.textarea.Text[UnityEngine.UI.Text]:DOFade(0,0.15);
		self.dialog.log.textarea.ScrollView[UnityEngine.CanvasGroup]:DOFade(0,0.1)--:OnComplete(function ()	end)
		self.dialog.log.textarea[CS.UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(700,90),0.1):OnComplete(function()
			self.isRunning = false;
			self.dialog.log:SetActive(false);
		end)
	end
end

function View:PrepareStartFight()
	
	-- for i,v in ipairs(fight_info.defender.roles) do
	-- 	PVPArenaModule.AddCharacter(v.id);
	-- 	if i == 1 then
	-- 		PVPArenaModule.MoveCharacter(v.id,"def"..i,function ()		
	-- 			PVPArenaModule.CharacterTalk(v.id,"来战", 2,function ()				
	-- 				self:ShowStartFight(fight_info);
	-- 			end)
	-- 		end)
	-- 	else
	-- 		PVPArenaModule.MoveCharacter(v.id,"def"..i)
	-- 	end
	-- end
	local func = nil;
	if self.matching then
		if self.found then
			func = npc_move.arena_npc_tuxi;
		else
			func = npc_move.arena_npc_waiting;
		end
	elseif self.pvp_matching then
		if self.found_pvp then
			func = npc_move.arena_npc_juedou;
		else
			func = npc_move.arena_npc_waiting;
		end
	end

	if func and (#self.action_queue <= 0 or self.found or self.found_pvp) then
		table.insert( self.action_queue, func)
		--print("当前队列长度", #self.action_queue)
		if #self.action_queue == 1 then
			self.action_queue[1]();
		end
	end
end

function View:ShowStartFight(fight_info, start)
	self.view.center.time[UnityEngine.CanvasGroup]:DOFade(0, 0.5);
	if self.view.center.state2.streak[UnityEngine.CanvasGroup].alpha > 0 then
		self.view.center.state2.streak[UnityEngine.CanvasGroup]:DOFade(0, 0.3);
	end
	self.view.mask:SetActive(true);
	self.rank:SetActive(false);
	
	self.tiktok = false;

	local content = self.view.center;
	for i=1,5 do
		content.lineup1["hero"..i]:SetActive(false);
		content.lineup2["hero"..i]:SetActive(false);
	end	

	local atk_capacity = 0;
	for i,v in ipairs(fight_info.attacker.roles) do		--攻击方（玩家）
		local t = {};
 		for _, vv in ipairs(v.propertys) do
            t[vv.type] = vv.value
        end
        local prop = Property(t);
 		atk_capacity = atk_capacity + prop.capacity;

 		local hero = {};
 		hero.level = v.level;
 		local evoConfig = HeroEvo.GetConfig(v.id);
		hero.star = v.grow_star;
	 	hero.quality = evoConfig[v.grow_stage].quality;
		hero.icon = v.mode;	
		content.lineup2["hero"..i]:SetActive(true);
		utils.IconFrameHelper.Create(content.lineup2["hero"..i],{customCfg = hero, type = 42})
		-- content.lineup2["hero"..i][SGK.newCharacterIcon]:SetInfo(hero);
	end
	--self.view.bottom.state.capacity[UnityEngine.UI.Text].text = tostring(math.floor(atk_capacity));


	local def_capacity = 0;
	for i,v in ipairs(fight_info.defender.roles) do	--防守方
		if v.wave == 1 then
			local t = {};
			for _, vv in ipairs(v.propertys) do
				t[vv.type] = vv.value
			end
			local prop = Property(t);
			def_capacity = def_capacity + prop.capacity;
			print("防守方", i, fight_info.defender.pid, prop.capacity, sprinttb(t));
			
			local hero = {};
			
			local evoConfig = HeroEvo.GetConfig(v.id);
			if fight_info.defender.npc then
				local npc_config = PVPArenaModule.GetNPCStatus(fight_info.defender.pid);
				hero.star = npc_config.heros[i].star;
				hero.quality = math.ceil((npc_config.heros[i].evolution + 1)/4);
				hero.level = npc_config.heros[i].level;
				content.state1.name[UnityEngine.UI.Text]:TextFormat(npc_config.cfg.name);
			else
				hero.level = v.level;
				hero.star = v.grow_star;
				hero.quality = evoConfig[v.grow_stage].quality;
				content.state1.name[UnityEngine.UI.Text]:TextFormat(fight_info.defender.name); 
			end
			hero.icon = v.mode;
			content.lineup1["hero"..i]:SetActive(true);
			utils.IconFrameHelper.Create(content.lineup1["hero"..i],{customCfg = hero, type = 42})
			-- content.lineup1["hero"..i][SGK.newCharacterIcon]:SetInfo(hero);
		end
	end
	-- content.lineup1[UnityEngine.UI.ContentSizeFitter].enabled = true;
	-- content.lineup2[UnityEngine.UI.ContentSizeFitter].enabled = true;
	
	content.state1.capacity[UnityEngine.UI.Text].text = tostring(math.floor(def_capacity));
	content.state1.financial[UnityEngine.UI.Text]:TextFormat(self:GetWealthString(fight_info.opponent_wealth));

	content.red[UnityEngine.UI.Image]:DOFade(1,0.5);
	content.zhan[UnityEngine.UI.Image]:DOFillAmount(1,0.4):OnComplete(function ( ... )
		content.vs1:SetActive(true);
		content.zhan[UnityEngine.UI.Image]:DOFade(0,0.3):SetDelay(0.3);
		content.vs1.gameObject.transform:DOScale(0.33, 0.3):OnComplete(function ( ... )
			content.vs1[UnityEngine.UI.Image]:DOFade(0,0.1);
			content.vs2[UnityEngine.UI.Image]:DOFade(1,0.1):OnComplete(function ( ... )
				content.lineup1[CS.DG.Tweening.DOTweenAnimation]:DOPlayForward();
				content.lineup2[CS.DG.Tweening.DOTweenAnimation]:DOPlayForward();
				content.state1[CS.DG.Tweening.DOTweenAnimation]:DOPlayForward();
				content.vs2[UnityEngine.UI.Image]:DOFade(1,2):OnComplete(function ( ... )
					if start then
						PVPArenaModule.StartFight();
					else
						PVPArenaModule.StartPVPFight();
					end	
				end);
			end);
		end)
	end)
end

function View:SetMatchingStatus(status)
	if status then
		self.view.center.time[UnityEngine.CanvasGroup]:DOFade(1, 0.5);
		local info = PVPArenaModule.GetPlayerInfo();
		if info.today_win_streak_count > 1 or info.pvp_win_streak_count > 1 then
			if self.matching then
				self.view.center.state2.streak.Text[UnityEngine.UI.Text].text = info.today_win_streak_count;
			elseif self.pvp_matching then
				self.view.center.state2.streak.Text[UnityEngine.UI.Text].text = info.pvp_win_streak_count;
			end
			self.view.center.state2.streak[UnityEngine.CanvasGroup]:DOFade(1, 0.5);
		end
		self.view.center.state2[CS.DG.Tweening.DOTweenAnimation]:DOPlayForward();
	else
		self.view.center.time[UnityEngine.CanvasGroup]:DOFade(0, 0.5);
		local info = PVPArenaModule.GetPlayerInfo();
		if info.today_win_streak_count > 1 or info.pvp_win_streak_count > 1 then
			self.view.center.state2.streak[UnityEngine.CanvasGroup]:DOFade(0, 0.5);
		end
		self.view.center.state2[CS.DG.Tweening.DOTweenAnimation]:DOPlayBackwards();
	end
end

function View:AddCharacter(id , pos, type)
	type = type or 2;
	local _id = id * 10 + type;
	print("添加", id, type);
	pos = pos or "prepare"
	local obj = self.controller:Get(_id);
	-- local heroCfg = ItemHelper.Get(ItemHelper.TYPE.HERO, id % 100000); 
	local heroCfg = nil;
	local atk_info,def_info = PVPArenaModule.GetPVEFormation();
	if type == 2 and def_info then
		for i,v in ipairs(def_info) do
			if v.id == id then
				heroCfg = v;
			end
		end
	end
	if heroCfg == nil then
		heroCfg = battleConfig.LoadNPC(id % 100000); 
	end
	assert(heroCfg,"hero "..id.." not found");
	local character = nil;
	if obj then
		print(id.."已存在");
		character = CS.SGK.UIReference.Setup(obj);
	else
		obj = UnityEngine.Object.Instantiate(self.content.dialog_character.gameObject, self.content.gameObject.transform);
		obj.name = tostring(_id);
		character = CS.SGK.UIReference.Setup(obj);
		self.controller:Add(_id, obj);
	end
	self:LoadSkeleton(character.spine[CS.Spine.Unity.SkeletonGraphic], nil, heroCfg.mode);
	character.gameObject.transform.localPosition = self.controller:GetPoint(pos);
	character:SetActive(true);

end

function View:AddCharacterByPosition(id , pos, type)
	type = type or 2;
	local _id = id * 10 + type;
	print("添加pos", id, type);
	pos = pos or Vector3.zero;
	local obj = self.controller:Get(_id);
	-- local heroCfg = ItemHelper.Get(ItemHelper.TYPE.HERO, id % 100000); 
	local heroCfg = nil;
	local atk_info,def_info = PVPArenaModule.GetPVEFormation();
	if type == 2 and def_info then
		for i,v in ipairs(def_info) do
			if v.id == id then
				heroCfg = v;
			end
		end
	end
	if heroCfg == nil then
		heroCfg = battleConfig.LoadNPC(id % 100000); 
	end
	assert(heroCfg,"hero "..id.." not found");
	local character = nil;
	if obj then
		print(id.."已存在");
		character = CS.SGK.UIReference.Setup(obj);
	else
		obj = UnityEngine.Object.Instantiate(self.content.dialog_character.gameObject, self.content.gameObject.transform);
		obj.name = tostring(_id);
		character = CS.SGK.UIReference.Setup(obj);
		self.controller:Add(_id, obj);
	end
	self:LoadSkeleton(character.spine[CS.Spine.Unity.SkeletonGraphic], nil, heroCfg.mode);
	character.gameObject.transform.localPosition = pos;
	character:SetActive(true);
end

function View:RemoveCharacter(id,type)
	type = type or 2;
	local _id = id * 10 + type;
	local obj = self.controller:Get(_id);
	assert(obj,"hero "..id.." not exist");
	if obj then
		self.controller:Remove(_id);
	end
end

function View:ShowNpcDesc(npc_view,desc,fun,type)
	npc_view.bg1:SetActive(type == 1)
	npc_view.bg2:SetActive(type == 2)
	npc_view.bg3:SetActive(type == 3)

    npc_view.desc[UnityEngine.UI.Text].text = desc
    npc_view:SetActive(true)
    npc_view[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function( ... )
        npc_view[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function( ... )
            if fun then
                fun()
            end
        end):SetDelay(1)
    end)
end

function View:CharacterTalk(id, str, talk_type, callback, type)
	type = type or 2;
	local _id = id * 10 + type;
	local obj = self.controller:Get(_id);
	assert(obj,"hero "..id.." not exist");
	if obj then
		local character = CS.SGK.UIReference.Setup(obj);
		self:ShowNpcDesc(character.Label.dialogue, str, callback, talk_type);
	end
end

function View:MoveCharacter(id, pos_name, callback, type)
	type = type or 2;
	local _id = id * 10 + type;
	-- print("移动", _id, type);
	local obj = self.controller:Get(_id);
	assert(obj,"hero "..id.." not exist");
	if obj then
		self.controller:MoveCharacter(_id, pos_name, callback);
	end
end

function View:MoveCharacterByPosition(id, pos, callback, type)
	type = type or 2;
	local _id = id * 10 + type;
	-- print("移动pos", _id, type);
	local obj = self.controller:Get(_id);
	assert(obj,"hero "..id.." not exist");
	if obj then
		self.controller:MoveTo(_id, pos, callback);
	end
end

function View:Update()
	if Time.now() - self.update_time >= 1 then
		self.update_time = Time.now();
		if self.tiktok then
			self.time = self.time + 1;
			self.view.center.time.time[UnityEngine.UI.Text].text = GetTimeFormat(self.time,2,2);
		end
	end
end

function View:deActive()
	if self.rank.gameObject.activeSelf then
		self.rank:SetActive(false);
		return false;
	end
	if self.found or self.found_pvp then
		return false;
	end
	if (self.matching or self.pvp_matching) then
		self.dialog.eixt:SetActive(true);
		return false;
	end
	PVPArenaModule.CleanData();
	return true;
end

function View:listEvent()
	return {
		"ARENA_GET_PLAYER_INFO_SUCCESS",
		"ARENA_FORMATION_CHANGE",
		"ARENA_FOUND_OPPONENT",
		"ARENA_START_FOUND_PVP_OPPONENT",
		"ARENA_CANCEL_FOUND_PVP_OPPONENT",
		"ARENA_FOUND_PVP_OPPONENT",
		"ARENA_ADD_CHARACTER",
		"ARENA_REMOVE_CHARACTER",
		"ARENA_MOVE_CHARACTER",
		"ARENA_MOVE_CHARACTER_BY_POS",
		"ARENA_CHARACTER_TALK",
		"ARENA_ADD_CHARACTER_BY_POS",
		"ARENA_NPC_MOVE_END",
		"ARENA_NOT_FOUND_OPPONENT",
		"ARENA_GET_RANKLIST_SUCCESS",
		"ARENA_SET_FORMATION_FAILED",
		"LOCAL_GUIDE_CHANE"
	}
end

function View:onEvent(event, ...)
	--print("onEvent", event, ...);
	local data = ...;
	if event == "ARENA_GET_PLAYER_INFO_SUCCESS" then
		local info = PVPArenaModule.GetPlayerInfo();
		if info then
			self:UpdatePlayerInfo(info)
		end
	elseif event == "ARENA_FORMATION_CHANGE" then
		if data.type == 1 or data.type == 3 then
			self.lineup = PVPArenaModule.GetPlayerFormation(1).formation;
			self:UpdateFormation(self.lineup);
		else
			if self.refresh then
				self.refresh = false;
				local text = "";
				if self.change_value > 0 then
					text = "数据已刷新，战斗力+"..self.change_value;
				elseif self.change_value < 0 then
					text = "数据已刷新，战斗力"..self.change_value;
				else
					text = "已经是最新数据了"
				end
				showDlgError(nil, text)
			end
			self:UpdateRedPoint();
		end
	elseif event == "ARENA_SET_FORMATION_FAILED" then
		if self.refresh then
			self.refresh = false;
			showDlgError(nil, "数据刷新失败")
		end
	elseif event == "ARENA_FOUND_OPPONENT" then
		self.found = true;		
		self:PrepareStartFight();
		self.matching = false;
		self:UpdateButtonState(false, self.view.bottom.PVE, 1);
		-- self.view.bottom.PVE[UnityEngine.UI.Button].interactable = false;
	elseif event == "ARENA_FOUND_PVP_OPPONENT" then
		self.found_pvp = true;		
		self:PrepareStartFight();
		self.pvp_matching = false;
		self:UpdateButtonState(false, self.view.bottom.PVP, 2);
		-- self.view.bottom.PVP[UnityEngine.UI.Button].interactable = false;
	elseif event == "ARENA_START_FOUND_PVP_OPPONENT" then
		self.pvp_matching = true;
		self:SetMatchingStatus(self.pvp_matching);
		self.tiktok = self.pvp_matching;
		self.view.bottom.PVP.Text[UnityEngine.UI.Text]:TextFormat("停止匹配");
		self:UpdateButtonState(false, self.view.bottom.PVE, 1);
		self:UpdateButtonState(false, self.view.bottom.lineup);
		self:UpdateButtonState(false, self.view.bottom.refresh);
		-- self.view.bottom.PVE[UnityEngine.UI.Button].interactable = false;
		-- self.view.bottom.lineup[UnityEngine.UI.Button].interactable = false;
	elseif event == "ARENA_CANCEL_FOUND_PVP_OPPONENT" then
		self.pvp_matching = false;
		self:SetMatchingStatus(self.pvp_matching);
		self.tiktok = self.pvp_matching;
		self.time = 0;
		self.view.bottom.PVP.Text[UnityEngine.UI.Text]:TextFormat("决斗");
		self:UpdateButtonState(true, self.view.bottom.PVE, 1);
		self:UpdateButtonState(true, self.view.bottom.lineup);
		self:UpdateButtonState(true, self.view.bottom.refresh);
		-- self.view.bottom.PVE[UnityEngine.UI.Button].interactable = true;
		-- self.view.bottom.lineup[UnityEngine.UI.Button].interactable = true;	
	elseif event == "ARENA_FOUND_OPPONENT_FAILED" then
		showDlgError(nil,"匹配失败");
		self.matching = false;
		self:SetMatchingStatus(self.matching);
		self.tiktok = self.matching;
		self.time = 0;
		self.view.bottom.PVE.Text[UnityEngine.UI.Text]:TextFormat("突袭");
		self:UpdateButtonState(true, self.view.bottom.PVP, 2);
		self:UpdateButtonState(true, self.view.bottom.lineup);
		self:UpdateButtonState(true, self.view.bottom.refresh);
		-- self.view.bottom.PVP[UnityEngine.UI.Button].interactable = true;
		-- self.view.bottom.lineup[UnityEngine.UI.Button].interactable = true;	
	elseif event == "ARENA_ADD_CHARACTER" then
		self:AddCharacter(...);
	elseif event == "ARENA_REMOVE_CHARACTER" then
		self:RemoveCharacter(...);
	elseif event == "ARENA_MOVE_CHARACTER" then
		self:MoveCharacter(...);
	elseif event == "ARENA_MOVE_CHARACTER_BY_POS" then
		self:MoveCharacterByPosition(...);
	elseif event == "ARENA_CHARACTER_TALK" then
		self:CharacterTalk(...);
	elseif event == "ARENA_ADD_CHARACTER_BY_POS" then
		self:AddCharacterByPosition(...);
	elseif event == "ARENA_NPC_MOVE_END" then
		if #self.action_queue > 0 then
			table.remove(self.action_queue, 1)
			if #self.action_queue > 0 then
				self.action_queue[1]();
				return;
			end
		end
		
		if self.found then
			local fight_info = PVPArenaModule.GetFightInfo();
			self:ShowStartFight(fight_info,true);
		elseif self.found_pvp then
			local fight_info = PVPArenaModule.GetPVPFightInfo();
			self:ShowStartFight(fight_info);
		end
	elseif event == "ARENA_NOT_FOUND_OPPONENT" then
		print("未找到对手，继续播放动画");
		self:PrepareStartFight();
	elseif event == "ARENA_GET_RANKLIST_SUCCESS" then
		local rankList = PVPArenaModule.GetRankList();
		if rankList then
			self.rankList = rankList;
			self.tableview.DataCount = #self.rankList;
		end
	elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(31, 0.2);
	end
end

return View;
