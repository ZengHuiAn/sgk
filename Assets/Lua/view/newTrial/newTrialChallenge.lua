local trialModule = require "module.trialModule"
local trialTowerConfig = require "config.trialTowerConfig"
local ItemHelper = require "utils.ItemHelper"
local openLevel = require "config.openLevel"
local battle = require "config.battle"
local fightModule = require "module.fightModule"
local skill = require "config.skill"

local View = {}

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self:initData(data)
	self:initClick()
	self:initView()
end

local openLevelList = {
    [1] = 1701,
    [2] = 1702,
    [3] = 1703,
    [4] = 1704,
    [5] = 1705,
}
function View:initData(data)
	if data and data.cfg then
		self.cfg = data.cfg
	else 
		local _,cfg = trialModule.GetBattleConfig();
		self.cfg = cfg
	end
	self.gid = self.cfg._data.gid
end

function View:initView()
	self:initTop()
	self:FreshReward(self.gid)
	self:FreshHeroList()
end

function View:getEnemyList()
    local _enemy = fightModule.GetWaveConfig(self.gid) or {}
    local _list = {}
    for k,v in pairs(_enemy) do
        for j,p in pairs(v) do
            _list[p.role_id] = p
        end
    end
    return _list
end

function View:initTop()
    local enemyList = {}
    local index = 0
    for k,v in pairs(self:getEnemyList()) do
        index = index + 1
        enemyList[index]=v
    end
    for i,v in pairs(enemyList) do
        if i > 5 then
            --print(#enemyList)
            return
        end
        local _cfg = battle.LoadNPC(v.role_id,v.role_lev)
        local _obj = self.view.root.middle.top.emptyList["item"..i]
        local _view = CS.SGK.UIReference.Setup(_obj)
        -- CS.UGUIClickEventListener.Get(_view.mask.newCharacterIcon.gameObject).onClick = function ()
        -- end
        utils.IconFrameHelper.Create(_view.mask.newCharacterIcon, {customCfg = {
            level = 0, --v.role_lev,
            star = 0,
            quality = 0,
            icon = _cfg.icon
        }, type = 42})

        _view.lev[UI.Text].text = "^"..v.role_lev

        self.tips = self.tips or {};

        for k=1,4 do
            local skill_id = _cfg["skill"..k];
            if skill_id ~= 0 then
                local cfg = skill.GetConfig(skill_id);

                self.tips[i] = self.tips[i] or {};
                if cfg then
                    table.insert(self.tips[i],{ name = cfg.name,desc = cfg.desc });
                end
            end
        end

        _view[UI.Toggle].onValueChanged:AddListener(function (value)
            if value == true then
                self:FreshTips(self.tips[i],{name = _cfg.name,lev = v.role_lev},nil,i,_cfg);
            else
                if self.view.root.middle.top.emptyList[UI.ToggleGroup].allowSwitchOff == true then
                    self:FreshTips(nil,nil,true);
                end
            end
        end)
        _obj:SetActive(true)
    end
end

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

function View:FreshTips(data,info,flag,idx,_cfg)
    if flag then 
        self.view.root.bg_desc.gameObject:SetActive(false);
        self.view.root.middle.top.descMask.gameObject:SetActive(false) 
        return 
    end
    -- print(sprinttb(_cfg));
    self.view.root.middle.top.descMask.gameObject:SetActive(true);
    self.view.root.middle.top.descMask[UnityEngine.RectTransform].sizeDelta =self.view.mask[UnityEngine.RectTransform].rect.size
    self.view.root.bg_desc.gameObject:SetActive(true);
    local tips = self.view.root.bg_desc
    CS.UGUIClickEventListener.Get(self.view.root.middle.top.descMask.gameObject,true).onClick = function ()
        --tips.gameObject:SetActive
        self.view.root.middle.top.emptyList["item"..idx][UI.Toggle].isOn = false
    end
    for i=1,5 do
        tips["Image"..i].gameObject:SetActive(false)
        if i == idx then
            tips["Image"..i].gameObject:SetActive(true)
        end
    end
    tips.title.flag[CS.UGUISpriteSelector].index = GetMasterIcon(_cfg.property_list)

    self:FreshContent(data);
    if info then
        tips.title.name[UI.Text].text = info.name
        tips.title.lev[UI.Text].text = "^"..info.lev
    end
end

function View:FreshContent(data)
    local tips = self.view.root.bg_desc
    for i=1,4 do
        local item = tips["desc"..i];

        local item_data = data[i]
        if item_data then
            item.gameObject:SetActive(true);
            item[UI.Text].text = item_data.desc;
            item.item.Text[UI.Text].text = item_data.name;
            local height = item[UI.Text].preferredHeight;
            -- print(item.desc[UI.Text].preferredHeight);
            item[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(585.5,height)
        else
            item.gameObject:SetActive(false);
        end
    end
end

function View:FreshReward(fight_id)
	self.drag = self.view.root.middle.bottom.scroll.ScrollView[CS.UIMultiScroller];
	--local rewardCfg = trialTowerConfig.GetConfig(fight_id);
	local rewardCfg = trialModule.GetReward(fight_id)
	local reward = rewardCfg.firstReward;
	--local x = trialModule.GetReward(fight_id)
	--print("+++++++++++",sprinttb(rewardCfg));
	self:FreshScroll(self.drag,reward);

	self.drag2 = self.view.root.middle.bottom.scroll2.ScrollView[CS.UIMultiScroller];

	self:FreshScroll(self.drag2,rewardCfg.accumulate);
end

function View:FreshScroll(scroll,_data)
	scroll.RefreshIconCallback = function (obj, idx)
		obj.gameObject:SetActive(true);
		local item = SGK.UIReference.Setup(obj);
		local data = _data[idx+1];
		local itemCfg = ItemHelper.Get(data.type,data.id);
		itemCfg.count = data.count;
		utils.IconFrameHelper.Create(item.IconFrame, {customCfg = itemCfg, type = data.type,showDetail= true,func = function ( _obj)
				_obj.gameObject.transform.localScale = UnityEngine.Vector3(0.7,0.7,1);
			end});
		-- item.root.Text[UI.Text].text = "x"..data.count;
	end
	scroll.DataCount = #_data or 0;
end

function View:FreshHeroList()
    local _list = module.HeroModule.GetManager():GetFormation()
    local _heroList = {}
    for i,v in ipairs(_list) do
        if v ~= 0 then
            table.insert(_heroList, v)
        end
    end
    for i = 1, #self.view.root.bottom.heroList do
        local _view = self.view.root.bottom.heroList[i].root
        _view.IconFrame:SetActive(_heroList[i] ~= nil)
        if _view.IconFrame.activeSelf then
            local _hero = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, _heroList[i])
            utils.IconFrameHelper.Create(_view.IconFrame, {uuid = _hero.uuid, type = 42})
        end
        _view.lock:SetActive(not openLevel.GetStatus(openLevelList[i]))
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if _view.lock.activeSelf then
                showDlgError(nil, openLevel.GetCloseInfo(openLevelList[i]))
                return
            end
            local _hero = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, _heroList[i])
            if _view.IconFrame.activeSelf then
                DialogStack.PushPrefStact("newRole/roleFramework", {heroid = _hero.id})
                self.view.gameObject:SetActive(true)
            else
                DialogStack.PushPrefStact("FormationDialog")
            end
        end
    end
end

function View:initClick()
	CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick = function (obj)
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function (obj)
		DialogStack.Pop()
	end
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function (obj)
        DialogStack.Pop()
    end
	CS.UGUIClickEventListener.Get(self.view.root.bottom.mySquad.gameObject).onClick = function()
        DialogStack.PushPrefStact("FormationDialog")
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.challenge.gameObject).onClick = function()
        if SceneStack.GetBattleStatus() then
			showDlgError(nil, "战斗内无法进行该操作")
			return;
		end
		DialogStack.Pop()
		trialModule.SaveLayarGid(self.gid)
		trialModule.StartFight();
    end
end

function View:listEvent()
    return {
    "LOCAL_PLACEHOLDER_CHANGE",
    "HERO_INFO_CHANGE",
    }
end

function View:onEvent(event,data)
	if event == "LOCAL_PLACEHOLDER_CHANGE" then
        self:FreshHeroList()
    elseif event == "HERO_INFO_CHANGE" then
        self:FreshHeroList()
    end
end


return View;