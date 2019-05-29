local activityConfig = require "config.activityConfig"
local battleCfg = require "config.battle"
local openLevel = require "config.openLevel"

local activityMonster = {}

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

function activityMonster:initData(data)
    self.monsterId = 2048421
    self.startFunc = nil
    if data then
        self.startFunc = data.func
        self.monsterId = data.monsterId
    else
        if self.savedValues.monsterId then
            self.monsterId = self.savedValues.monsterId
            self.startFunc = self.savedValues.startFunc
        end
    end
    self.monsterCfg = activityConfig.GetActivityMonsterCfg(self.monsterId) or {}
    self.savedValues.monsterId = self.monsterId
    self.savedValues.startFunc = self.startFunc
end

function activityMonster:Start(data)
    self:initData(data)
    self:initUi()
end

function activityMonster:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initBtn()
    self:initInfo()
    self:upHeroList()
end

function activityMonster:getLevel()
    if utils.SGKTools.GetTeamState() then
        return module.TeamModule.GetTeamInfo().leader.level
    else
        return module.HeroModule.GetManager():Get(11000).level
    end
end

function activityMonster:upMiddleInfo(cfg)
    local _level = self:getLevel() or 1
    local _roleCfg = battleCfg.LoadNPC(cfg.roleId, _level)
    local _info = ""
    if _roleCfg then
        for i = 1, #self.view.root.middle.ScrollView.Viewport.Content do
            local _view = self.view.root.middle.ScrollView.Viewport.Content[i]
            _view:SetActive(_roleCfg.skills[i] and true)
            if _view.activeSelf then
                _view.name[UI.Text].text = _roleCfg.skills[i].name
                _view.desc[UI.Text].text = _roleCfg.skills[i].desc
            end
        end
        self.view.root.middle.name[UI.Text].text = _roleCfg.name
        self.view.root.middle.icon[CS.UGUISpriteSelector].index = GetMasterIcon(_roleCfg.property_list)
    end
    if self.monsterCfg and self.monsterCfg.squad[1] and self.monsterCfg.squad[1].level then
        self.view.root.middle.level[UI.Text].text = "^"..self.monsterCfg.squad[1].level
    else
        self.view.root.middle.level[UI.Text].text = "^".._level
    end
end

function activityMonster:initInfo()
    self.view.root.middle.desc[UI.Text].text = self.monsterCfg.des
    -- for i = 1, #self.view.root.middle.iconList do
    --     self.view.root.middle.iconList:SetActive((self.monsterCfg.lineup & (1 << (i - 1))) ~= 0)
    -- end
    for i = 1, #self.view.root.top.itemList do
        local _view = self.view.root.top.itemList[i]
        _view:SetActive(self.monsterCfg.squad[i] and true)
        _view.transform.localScale = Vector3(0.7, 0.7, 1)
        _view[UI.Toggle].onValueChanged:AddListener(function (value)
            if value then
                _view.transform.localScale = Vector3(0.9, 0.9, 1)
            else
                _view.transform.localScale = Vector3(0.7, 0.7, 1)
            end
        end)
        CS.UGUIClickEventListener.Get(_view.gameObject, true).onClick = function()
            self:upMiddleInfo(self.monsterCfg.squad[i])
        end
        if _view.activeSelf then
            local _cfg = battleCfg.LoadNPC(self.monsterCfg.squad[i].roleId)
            if _cfg then
                utils.IconFrameHelper.Create(_view.IconFrame, {customCfg = {
                        icon    = _cfg.icon,
                        quality = 0,
                        star    = 0,
                        level   = 0,
                }, type = 42})
            end
        end
    end
    self:upMiddleInfo(self.monsterCfg.squad[1])
    self.view.root.top.itemList[1][UI.Toggle].isOn = true
end

function activityMonster:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.startFightBtn.gameObject).onClick = function()
        if self.startFunc then
            DialogStack.Pop()
            coroutine.resume(coroutine.create(function()
                self.startFunc()
            end))
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.teamBtn.gameObject).onClick = function()
        DialogStack.Push("TeamFrame", {idx = 2, viewDatas = {[2] = {id = 2101}}})
    end
    CS.UGUIClickEventListener.Get(self.view.root.mySquad.gameObject).onClick = function()
        DialogStack.Push("FormationDialog")
    end
end

local openLevelList = {
    [1] = 1701,
    [2] = 1702,
    [3] = 1703,
    [4] = 1704,
    [5] = 1705,
}

function activityMonster:upHeroList()
    local _list = module.HeroModule.GetManager():GetFormation()
    local _heroList = {}
    for i,v in ipairs(_list) do
        if v ~= 0 then
            table.insert(_heroList, v)
        end
    end
    for i = 1, #self.view.root.heroList do
        local _view = self.view.root.heroList[i].root
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
                DialogStack.Push("newRole/roleFramework", {heroid = _hero.id})
                --self.view.gameObject:SetActive(true)
            else
                DialogStack.Push("FormationDialog")
            end
        end
    end
end

function activityMonster:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return activityMonster
