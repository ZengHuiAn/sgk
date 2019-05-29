local View = {}

local expModule = require "module.expModule"
local battleCfg = require "config.battle"

local ItemHelper = require "utils.ItemHelper"

function View:Start(data)

	-- print(module.playerModule.Get().id)
	self.root = SGK.UIReference.Setup(self.gameObject);

	self.view = self.root.root.bg;
	self.monster = expModule.GetMonsters();
	-- print("=======血量========",sprinttb(self.monster))
	self.HPSlider = SGK.ResourcesManager.Load("prefabs/expOnline/HPSlider.prefab");

	self:FreshMonster();

	self:FreshHero();
	self:FreshReward();
	module.HeroModule.GetManager():GetFormation();
	self:SetOnClick();
end

local function getNpcHerosConfigByID(pid)
	local TempGuardCfg=battleCfg.load(pid)
	local herosCfg={}
	for k,v in pairs(TempGuardCfg.rounds) do
		for m,n in pairs(v.enemys) do
			table.insert(herosCfg,n)		
		end
	end
	return herosCfg;
end

function View:SetOnClick()

	self.root.mask[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.Pop();
	end

	self.view.closeBtn[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.Pop();
	end
	self.view.formation[CS.UGUIClickEventListener].onClick = function ()
		-- print("点击");
		-- trialModule.StartFight();
		DialogStack.PushPrefStact("FormationDialog",{cut = 1});
	end
	self.view.startFightBtn[CS.UGUIClickEventListener].onClick = function ()
		-- print("开战")

		if SceneStack.GetBattleStatus() then
			showDlgError(nil, "战斗内无法进行该操作")
			return;
		end
		if self.dead_status then
			-- body
			self.view.startFightBtn[CS.UGUIClickEventListener].interactable = false;
			expModule.StartFight();
		else
			showDlgError(nil,"当前阵容无可战斗人员");
		end


	end
	local info = expModule.GetBattle();
	local capacity,heros= expModule.GetCapacityByFormation(info);
	self.view.topinfo.capacity.Text[UI.Text].text = capacity;

	-- heros[k].property.capacity
	utils.IconFrameHelper.Create(self.view.topinfo.IconFrame, {pid = info.pid});
end


function View:FreshEnemyIcon(mode)
	-- self.view.topinfo.IconFrame[]
end

function View:FreshMonster()
	local list = self.view.top.itemList;
	self.monster = self.monster or {};

	local info = expModule.GetBattle();
	-- info
	local capacity,heros= expModule.GetCapacityByFormation(info)
	-- ERROR_LOG("战斗信息",capacity,sprinttb(heros));

	for i=1,5 do
		local item = list["icon"..i];

		-- print("战斗力",heros[i].property.capacity);
		self:FreshItemMonster(item,self.monster[i],heros[i] and heros[i].property.capacity or nil);
	end
end

function View:FreshItemMonster(item,data,capacity)
	if not data then
		item.gameObject:SetActive(false);
		return;
	end
	-- ERROR_LOG(sprinttb(data));

	local hero = module.HeroModule.GetConfig(data.id);
	hero.level = data.level;
	hero.star = data.star;
	local obj  = utils.IconFrameHelper.Create(item.IconFrame, {
		type = utils.ItemHelper.TYPE.HERO,customCfg = {
		level = hero.level,
        star = hero.star or 0,
        role_stage = hero.role_stage,
        icon = hero.icon,}})

	obj.gameObject.transform.localScale = UnityEngine.Vector3(0.8,0.8,0.8);
	local _view = SGK.UIReference.Setup(obj)
	local slider = SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(self.HPSlider,obj.gameObject.transform));
	slider.gameObject.transform:SetSiblingIndex(7);
	slider[UI.Slider].value = data.value/100;
	-- print("============",sprinttb(data))
	_view[CS.SGK.CommonIcon].colorGray =  data.value <= 0 ;
	-- item.Frame[UI.Image].material =  (data.value or 0) <= 0 and SGK.QualityConfig.GetInstance().grayMaterial or nil;
	item.capacity.Text[UI.Text].text = capacity;

end



function View:FreshHero()
	self.online = {};
	for k, v in ipairs(module.HeroModule.GetManager():GetFormation()) do
		self.online[k] = v or 0;
	end
	local format = self.view.format;
	-- print(sprinttb(self.online));

	self.cutlist = module.expModule.GetCutList();
	-- ERROR_LOG("血量",sprinttb(self.cutlist),sprinttb(self.online));

	self.dead_status = nil
	for i=1,#self.online do
		local item = format["icon"..i];

		local cfg = battleCfg.LoadNPC(self.online[i]);
		-- item.Icon.lock.gameObject:SetActive(cfg == nil);
		if cfg then

			item.Icon.content.gameObject:SetActive(true);
			-- item.Icon.content[UI.Image].enabled = true
			-- print(self.cutlist[self.online[i]]);
			if self.cutlist and self.cutlist[self.online[i]] then
				item.Icon.content.Slider[UI.Slider].value = self.cutlist[self.online[i]]/100;
				self:FreshAlpha(item,self.cutlist[self.online[i]]>0);
				if self.cutlist[self.online[i]] ~= 0 then
					self.dead_status = true;
				end
				
			else
				self:FreshAlpha(item,true);
				item.Icon.content.Slider[UI.Slider].value = 1;
				self.dead_status = true;
			end
			local info = module.HeroModule.GetManager():Get(self.online[i])
			utils.IconFrameHelper.Create(item.Icon.content.IconFrame, {
				type = utils.ItemHelper.TYPE.HERO,customCfg = {
				level = info.level,
		        star = 0,
		        role_stage = info.role_stage,
		        icon = info.icon}});
			item.Icon.content.Text:SetActive(true);
			item.Icon.content.Text[UI.Text].text = "";
			local cfg = utils.ItemHelper.Get(ItemHelper.TYPE.HERO, self.online[i])

			item.Icon.content.capacity.Text[UI.Text].text = cfg.capacity;
			CS.UGUIClickEventListener.Get(item.Icon.gameObject,true).onClick = nil
		else
			item.Icon.content.gameObject:SetActive(false);
			item.Icon.content.Text:SetActive(false);
			item.Icon[UI.Image].raycastTarget = true
			CS.UGUIClickEventListener.Get(item.Icon.gameObject,true).onClick = function (obj)

				print("===========>>>>");
				DialogStack.PushPrefStact("FormationDialog",{cut = 1});
			end
			-- item.Icon.content[UI.Image].enabled = false
		end
		
	end
end


function View:FreshReward()
	local reward = expModule.GetBattleReward();

	if not reward or #reward == 0 then return end
	-- ERROR_LOG(sprinttb(reward));

	local id = reward[1].id;


	local uiScroll = self.view.scroll.ScrollView[CS.UIMultiScroller];

	local itemCfg = module.ItemModule.GetGiftItem(id,function(_cfg)

			self:FreshScroll(uiScroll,_cfg);
		end);
end

function View:FreshScroll(scroll,_data)
	-- ERROR_LOG("刷新奖励",sprinttb(_data));
	scroll.RefreshIconCallback = function (obj, idx)
		obj.gameObject:SetActive(true);
		local item = SGK.UIReference.Setup(obj);
		local data = _data[idx+1];
		self:FreshItem(item,data);
	end
	scroll.DataCount = #_data or 0;
end

function View:FreshItem(item,data)
	-- ERROR_LOG("=========>>>",sprinttb(data));

	utils.IconFrameHelper.Create(item.IconFrame, {count = data[3],id = data[2], type = data[1],showDetail= true,func = function ( _obj)
				_obj.gameObject.transform.localScale = UnityEngine.Vector3(0.6,0.6,1);
			end});
end


function View:FreshAlpha(obj,alpha)
	local item = SGK.UIReference.Setup(obj);
	item.Icon.content[UI.Image].color = alpha and UnityEngine.Color.white or UnityEngine.Color.gray;
end

function View:listEvent()
	return{
		"LOCAL_PLACEHOLDER_CHANGE",
		"GET_READY_DATA",
	}
end

function View:onEvent(event,data)
	-- ERROR_LOG(event);
	if event == "LOCAL_PLACEHOLDER_CHANGE"then
		self:FreshHero();
		expModule.GetPrepare();
	elseif event == "GET_READY_DATA" then
		self:FreshMonster();
	end
end


return View;