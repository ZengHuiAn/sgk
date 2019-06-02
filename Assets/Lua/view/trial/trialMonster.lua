local View = {}
local trialModule = require "module.trialModule"
local battleCfg = require "config.battle"
local skill = require "config.skill"
local trialTowerConfig = require "config.trialTowerConfig"
local ItemHelper = require "utils.ItemHelper";

local role_master_list = {
    {master = 1801,   index = 3, desc = "风系", colorindex = 0},
    {master = 1802,  index = 2, desc = "土系", colorindex = 1},
    {master = 1803, index = 0, desc = "水系", colorindex = 2},
    {master = 1804,  index = 1, desc = "火系", colorindex = 3},
    {master = 1805, index = 4, desc = "光系", colorindex = 4},
    {master = 1806,  index = 5, desc = "暗系", colorindex = 5},
}

local function GetMasterIcon(role, other_info)
    table.sort(role_master_list, function (a, b)
        local _a = role[a.master] or 0
        local _b = role[b.master] or 0
        if _a ~= _b then
            return _a > _b
        end
		return a.master > b.master
    end)

    if other_info and role[role_master_list[1].master] == role[role_master_list[2].master] then
        return {desc = "全系",  colorindex = 6}
    elseif other_info then
        return {desc = role_master_list[1].desc,  colorindex = role_master_list[1].colorindex}
    end

    if role[role_master_list[1].master] == role[role_master_list[2].master] then
        return 6
    else
        return role_master_list[1].index
    end
end


function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);


	self.callback = data.callback;
	self.cfg = data.cfg;
	self.fight_id = self.cfg._data.battle_id;

	self.gid = self.cfg._data.gid
	-- print(sprinttb(self.cfg));
	self.view.root.bg.closeBtn[CS.UGUIClickEventListener].onClick = function ()
		-- print("点击");
		-- trialModule.StartFight();
		DialogStack.Pop();
	end
	self.view.root.bg.formation[CS.UGUIClickEventListener].onClick = function ()
		-- print("点击");
		-- trialModule.StartFight();
		DialogStack.PushPrefStact("FormationDialog");
	end

	self.view.root.bg.startFightBtn[CS.UGUIClickEventListener].onClick = function ()
		if SceneStack.GetBattleStatus() then
			showDlgError(nil, "战斗内无法进行该操作")
			return;
		end
		trialModule.StartFight();
	end

	self:FreshMonster();
	self:FreshHero();
	self:FreshReward(self.gid);
end

function View:FreshReward(fight_id)
	self.drag = self.view.root.bg.scroll.ScrollView[CS.UIMultiScroller];
	local rewardCfg = trialTowerConfig.GetConfig(fight_id);
	
	local reward = rewardCfg.firstReward;
	-- print("=============",sprinttb(rewardCfg));
	self:FreshScroll(self.drag,reward);

	self.drag2 = self.view.root.bg.scroll2.ScrollView[CS.UIMultiScroller];

	self:FreshScroll(self.drag2,rewardCfg.accumulate);
end

function View:FreshScroll(scroll,_data)
	scroll.RefreshIconCallback = function (obj, idx)
		obj.gameObject:SetActive(true);
		local item = SGK.UIReference.Setup(obj);
		local data = _data[idx+1];
		local itemCfg = ItemHelper.Get(data.type,data.id);
		itemCfg.count = data.count;
		utils.IconFrameHelper.Create(item.IconFrame, {customCfg = itemCfg, type = 41,showDetail= true,func = function ( _obj)
				_obj.gameObject.transform.localScale = UnityEngine.Vector3(0.6,0.6,1);
			end});
		-- item.root.Text[UI.Text].text = "x"..data.count;
	end
	scroll.DataCount = #_data or 0;
end

function View:FreshHero()
	self.online = {};
	for k, v in ipairs(module.HeroModule.GetManager():GetFormation()) do
		self.online[k] = v or 0;
	end
	local format = self.view.root.bg.format;
	-- print(sprinttb(self.online));
	for i=1,#self.online do
		local item = format["icon"..i];
		local cfg = module.HeroModule.GetConfig(self.online[i]);
		if cfg then
			local _hero = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, self.online[i])
			utils.IconFrameHelper.Create(item.Icon.content, {uuid = _hero.uuid, type = 42})
			item.Icon.content:SetActive(true);
			-- item.Icon.content[UI.Image].enabled = true
			-- item.Icon.content[UI.Image]:LoadSprite("icon/"..cfg.icon)
			item.Icon.content[CS.UGUIClickEventListener].interactable = true
			item.Icon.content[CS.UGUIClickEventListener].onClick = function (obj)
				DialogStack.PushPrefStact("newRole/roleFramework", {heroid = self.online[i]})
			end
		else
			item.Icon.content:SetActive(false);
			item.Icon.content[CS.UGUIClickEventListener].interactable = false
			item.Icon.content[UI.Image].enabled = false
		end
	end
	
end


function View:FreshMonster()
	local battle_id = self.fight_id

	local parent = self.view.root.bg.top.itemList;
	-- print("self.cfg._data.gid",self.cfg._data.gid)
	local battle_cfg = module.fightModule.GetWaveConfig(self.cfg._data.gid);
	-- print("战斗配置",sprinttb(battle_cfg))
	self:FreshItemMonster(parent,battle_cfg);
end

function View:FreshItemMonster(parent,battle_cfg)

	self.tips = {};

	for i=1,5 do
		local item = parent["icon"..i];
		if battle_cfg and battle_cfg[1][i] then
			local role_info = battle_cfg[1][i]

			local role_id = role_info.role_id;
			local _cfg = battleCfg.LoadNPC(role_id,role_info.role_lev)
			
			-- ERROR_LOG(sprinttb(role_info));

			utils.IconFrameHelper.Create(item.IconFrame, {customCfg = {
                        icon    = _cfg.icon,
                        role_stage = 0,
                        star    = 0,
                        level   = role_info.role_lev,
                }, type = 42})

			self.tips = self.tips or {};

			for k=1,4 do
				local skill_id = _cfg["skill"..k];
				if skill_id ~= 0 then
					local cfg = skill.GetConfig(skill_id);

					self.tips[i] = self.tips[i] or {};

					table.insert(self.tips[i],{ name = cfg.name,desc = cfg.desc });
				end
			end
			-- self:FreshContent(self.tips[i]);
			item[UI.Toggle].onValueChanged:AddListener(function (value)

				if value == true then
					self:FreshTips(self.tips[i],{name = _cfg.name,lev = role_info.role_lev},nil,_cfg);

				else
					if parent[UI.ToggleGroup].allowSwitchOff == true then
						self:FreshTips(nil,nil,true);
					end
				end

			end)
		else
			item.gameObject:SetActive(false);
		end 
	end
	-- parent[]
end



function View:FreshTips(data,info,flag,_cfg)
	if flag then self.view.root.bg.top.bg_desc.gameObject:SetActive(false); return end;
	-- print(sprinttb(_cfg));
	self.view.root.bg.top.bg_desc.gameObject:SetActive(true);
	local tips = self.view.root.bg.top.bg_desc

	tips.title.flag[CS.UGUISpriteSelector].index = GetMasterIcon(_cfg.property_list)

	self:FreshContent(data);
	if info then
		tips.title.name[UI.Text].text = info.name
		tips.title.lev[UI.Text].text = "^"..info.lev
	end
end


function View:FreshContent(data)
	local tips = self.view.root.bg.top.bg_desc

	for i=1,4 do
		local item = tips["item"..i];

		local item_data = data[i]
		if item_data then
			item.gameObject:SetActive(true);
			item.Text[UI.Text].text = item_data.name;
			item.desc[UI.Text].text = item_data.desc;
			local height = item.desc[UI.Text].preferredHeight;
			-- print(item.desc[UI.Text].preferredHeight);
			item[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(585.5,height)
		else
			item.gameObject:SetActive(false);
		end
	end
end

function View:OnDestroy( ... )
	-- print("关闭界面");
	if self.callback then
		self.callback();
	end
end

function View:listEvent()
	return{
		"LOCAL_PLACEHOLDER_CHANGE",
	}
end

function View:onEvent(event,data)
	-- print(event);
	if event == "LOCAL_PLACEHOLDER_CHANGE" then
		self:FreshHero();
	end
end

-- LOCAL_PLACEHOLDER_CHANGE

return View;