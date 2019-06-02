local fightModule = require "module.fightModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local battle = require "config.battle"
local skill = require "config.skill"
local MapConfig = require "config.MapConfig"
local ShopModule = require "module.ShopModule"
local openLevel = require "config.openLevel"

local newGoCheckpoint = {}

function newGoCheckpoint:Start(data)
    self:initData(data)
    self:initUi()
end

function newGoCheckpoint:initData(data)
    if data == nil or data.gid == nil then
        data = {}
        data.gid = self.savedValues.checkPoint or 10010101
        data.npcId = self.savedValues.checkPointNpcId or 11001
    end
    self.gid = data.gid
    self.npcId = data.npcId
    self.savedValues.checkPoint = self.gid
    self.savedValues.checkPointNpcId = self.npcId

    self.npcCfg = MapConfig.GetMapMonsterConf(self.npcId)

    self:upData()
end

function newGoCheckpoint:upData()
    self.pveCfg = fightModule.GetConfig(nil, nil, self.gid)
    --print(sprinttb(self.pveCfg))
    self.fightInfo = fightModule.GetFightInfo(self.gid)
    self.battleCfg = fightModule.GetConfig(nil, self.pveCfg.battle_id, nil)
    self.chapterCfg = fightModule.GetConfig(self.battleCfg.chapter_id)
    self.product = ShopModule.GetManager(99, self.pveCfg.reset_consume_id) and ShopModule.GetManager(99, self.pveCfg.reset_consume_id)[1]
end

function newGoCheckpoint:initCloseBtn()
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.goCheckpointRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
end

function newGoCheckpoint:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initCloseBtn()
    self:initBottom()
    self:initMiddle()
    self:initTop()
    self.view.goCheckpointRoot.middle.top.descMask.gameObject:SetActive(false);
    module.guideModule.PlayByType(103,0.1)
end

function newGoCheckpoint:getEnemyList()
    local _enemy = fightModule.GetWaveConfig(self.gid) or {}
    local _list = {}
    for k,v in pairs(_enemy) do
        for j,p in pairs(v) do
            _list[p.role_id] = p
        end
    end
    return _list
end

local openLevelList = {
    [1] = 1701,
    [2] = 1702,
    [3] = 1703,
    [4] = 1704,
    [5] = 1705,
}

function newGoCheckpoint:upHeroList()
    local _list = module.HeroModule.GetManager():GetFormation()
    local _heroList = {}
    for i,v in ipairs(_list) do
        if v ~= 0 then
            table.insert(_heroList, v)
        end
    end
    for i = 1, #self.view.goCheckpointRoot.bottom.heroList do
        local _view = self.view.goCheckpointRoot.bottom.heroList[i].root
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

function newGoCheckpoint:initBoss()
    self.bossNodeBase = self.view.goCheckpointRoot.top.boss
    local _boss = self.bossNodeBase:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic))
    self.bossNodeBase.transform.localScale = Vector3(self.npcCfg.battle_bg_scale, math.abs(self.npcCfg.battle_bg_scale), math.abs(self.npcCfg.battle_bg_scale))
    self.bossNodeBase.transform.localPosition = Vector3(self.npcCfg.battle_bg_x, self.npcCfg.battle_bg_y, 0)
    SGK.ResourcesManager.LoadAsync(_boss, "roles/"..self.npcCfg.mode.."/"..self.npcCfg.mode.."_SkeletonData.asset", function(o)
        _boss.skeletonDataAsset = o;
        _boss:Initialize(true)
        _boss.AnimationState:SetAnimation(0, "idle", true)
    end)
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

function newGoCheckpoint:initTop()
    --local _item = self.view.goCheckpointRoot.top.emptyList.item.gameObject
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
        local _obj = self.view.goCheckpointRoot.middle.top.emptyList["item"..i]
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
                if self.view.goCheckpointRoot.middle.top.emptyList[UI.ToggleGroup].allowSwitchOff == true then
                    self:FreshTips(nil,nil,true);
                end
            end
        end)
        -- _view.newCharacterIcon[SGK.newCharacterIcon].icon = battle.LoadNPC(v.role_id).icon
        -- _view.newCharacterIcon[SGK.newCharacterIcon].level = v.role_lev
        _obj:SetActive(true)
    end
    --self:initBoss()
    self.view.goCheckpointRoot.top.name[UI.Text].text = self.pveCfg.scene_name
    self.view.goCheckpointRoot.top.desc[UI.Text].text = self.pveCfg.desc
    self:upHeroList()
end

function newGoCheckpoint:FreshTips(data,info,flag,idx,_cfg)
    if flag then 
        self.view.goCheckpointRoot.bg_desc.gameObject:SetActive(false);
        self.view.goCheckpointRoot.middle.top.descMask.gameObject:SetActive(false);  
        return 
    end;
    -- print(sprinttb(_cfg));
    self.view.goCheckpointRoot.middle.top.descMask.gameObject:SetActive(true);
    self.view.goCheckpointRoot.middle.top.descMask[UnityEngine.RectTransform].sizeDelta =self.view.mask[UnityEngine.RectTransform].rect.size
    self.view.goCheckpointRoot.bg_desc.gameObject:SetActive(true);
    local tips = self.view.goCheckpointRoot.bg_desc
    CS.UGUIClickEventListener.Get(self.view.goCheckpointRoot.middle.top.descMask.gameObject,true).onClick = function ()
        --tips.gameObject:SetActive
        self.view.goCheckpointRoot.middle.top.emptyList["item"..idx][UI.Toggle].isOn = false
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

function newGoCheckpoint:FreshContent(data)
    local tips = self.view.goCheckpointRoot.bg_desc
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

function newGoCheckpoint:initBottom()
    self.todayCount = self.view.goCheckpointRoot.bottom.count.value[UI.Text]
    self.todayCountInfo = self.view.goCheckpointRoot.bottom.count.key[UI.Text]
    if self.pveCfg.cost_item_value > ItemModule.GetItemCount(90010) then
        self.view.goCheckpointRoot.bottom.challenge.numb[UI.Text].color = {r = 1, g = 0, b = 0, a = 1}
    else
        self.view.goCheckpointRoot.bottom.challenge.numb[UI.Text].color = {r = 0, g = 0, b = 0, a = 1}
    end
    self.view.goCheckpointRoot.bottom.challenge.numb[UI.Text].text = tostring(self.pveCfg.cost_item_value)
    local _cfg = ItemHelper.Get(41, 90010)
    self.view.goCheckpointRoot.bottom.challenge.icon[UI.Image]:LoadSprite("icon/".._cfg.icon.."_small")
    CS.UGUIClickEventListener.Get(self.view.goCheckpointRoot.bottom.mySquad.gameObject).onClick = function()
        DialogStack.PushPrefStact("FormationDialog")
    end
    local _material = nil--[CS.UnityEngine.MeshRenderer].materials[0]
    if fightModule.GetOpenStar(self.fightInfo.star, 1) == 0 then
        _material = self.view.goCheckpointRoot.bottom.sweeping[CS.UnityEngine.MeshRenderer].materials[0]
    end
    self.view.goCheckpointRoot.bottom.sweeping[UI.Image].material = _material
    CS.UGUIClickEventListener.Get(self.view.goCheckpointRoot.bottom.sweeping.gameObject).onClick = function()
        if not openLevel.GetStatus(6001) then
            return
        end
        if fightModule.GetOpenStar(self.fightInfo.star, 1) ~= 0 then
            DialogStack.PushPrefStact("selectMap/sweeping", {gid = self.gid})
        else
            showDlgError(nil, "挑战成功后才可使用扫荡功能")
        end
    end
    CS.UGUIClickEventListener.Get(self.view.goCheckpointRoot.bottom.challenge.gameObject).onClick = function()
        -- if not utils.SGKTools.CheckDialog() then
        --     return
        -- end
        local function GoBattle( ... )
            if self.pveCfg.count_per_day - self.fightInfo.today_count <= 0 then
                showDlgError(nil, "挑战次数不足")
                return
            end
            if self.pveCfg.cost_item_value > ItemModule.GetItemCount(90010) then
                --showDlgError(nil, "时之力不足")
                showDlgError(nil, "体力不足")
                DialogStack.PushPrefStact("ItemDetailFrame", {id = 90010,type = utils.ItemHelper.TYPE.ITEM,InItemBag=2},UnityEngine.GameObject.FindWithTag("UGUITopRoot").gameObject)
                return
            end
            --暂离状态下可以进入副本战斗
            if (fightModule.GetOpenStar(self.fightInfo.star, 1) == 0) and (self.pveCfg.story_id ~= 0) then
                local _startFight = function()
                    LoadStory(self.pveCfg.story_id, function()
                        fightModule.StartFight(self.gid)
                        DialogStack.Pop()
                    end)
                end
                if self.pveCfg.fight_cg ~= "0" then
                    utils.SGKTools.loadSceneEffect(self.pveCfg.fight_cg, Vector3.zero, self.pveCfg.time, true)
                    utils.SGKTools.DestroySceneEffect(self.pveCfg.fight_cg, self.pveCfg.time, function()
                        _startFight()
                    end)
                else
                    _startFight()
                end
            else
                fightModule.StartFight(self.gid)
                DialogStack.Pop()
            end
        end

        if utils.SGKTools.CheckPlayerAfkStatus() then
            DlgMsg({msg = "跟随状态下无法操作,是否进入暂离并开启战斗", confirm = function ( ... )
                module.TeamModule.TEAM_AFK_REQUEST(function ( ... )
                    GoBattle();
                end)
			end,cancel = function ( ... )
				
            end, txtConfirm = "确定",txtCancel = "取消",title = "单人副本"})
            return
        end
        GoBattle();
        
    end
    CS.UGUIClickEventListener.Get(self.view.goCheckpointRoot.bottom.resetBtn.gameObject).onClick = function()
        if self.product then
            local _itemCfg = ItemHelper.Get(self.product.consume_item_type1, self.product.consume_item_id1)
            showDlgMsg(string.format("是否花费%s%d重置挑战次数",_itemCfg.name, self.product.consume_item_value1), function()
                if ItemModule.GetItemCount(self.pveCfg.reset_consume_id) > 0 then
                    fightModule.ResetFightCount(self.gid)
                else
                    if self.product.product_count > 0 then
                        if ItemModule.GetItemCount(self.product.consume_item_id1) >= self.product.consume_item_value1 then
                            ShopModule.Buy(99, self.product.gid, 1)
                        else
                            
                            showDlgError(nil, _itemCfg.name.."不足")
                        end
                    else
                        showDlgError(nil, "重置次数不足")
                    end
                end
            end,function()end)
        else
            ERROR_LOG("self.product is nil")
        end
    end
    self:upBottom()
end

function newGoCheckpoint:initMiddle()
    self:initMiddleTop()
    self:initMiddleBottom()
    self:initBgIcon()
end

function newGoCheckpoint:initBgIcon()
    self.view.goCheckpointRoot.top.bg.bgIcon[UI.Image]:LoadSprite("guanqia/selectMap/"..self.battleCfg.bg_ready)
end

function newGoCheckpoint:initMiddleBottom()
    local _list = fightModule.GetDropConfig(self.gid)
    if _list then
        local _rewardItem = SGK.ResourcesManager.Load("prefabs/base/IconFrame.prefab")
        for i = 1, 6 do
            if _list["drop"..i.."_id"] ~= nil and _list["drop"..i.."_id"] ~= 0 then
                local obj = SGK.UIReference.Instantiate(_rewardItem, self.view.goCheckpointRoot.middle.bottom.itemList.gameObject.transform)
                obj.gameObject.transform.localScale = Vector3(0.7, 0.7, 1)
                local _item = ItemHelper.Get(_list["drop"..i.."_type"], _list["drop"..i.."_id"], nil, 0)
                utils.IconFrameHelper.Create(obj, {id = _list["drop"..i.."_id"], type = _list["drop"..i.."_type"], count = 0, showDetail = true})
                obj.gameObject:SetActive(true)
            end
        end
    end
end

function newGoCheckpoint:initStarTab()
    self.starTab = {}
    table.insert(self.starTab, {key = 1, value = {0, 0}}) --第一条固定key为1
    for i = 1, 2 do
        local _key = self.pveCfg["star"..i.."_type"]
        local _value = {}
        for j = 1, 2 do
            table.insert(_value, self.pveCfg["star"..i.."_para"..j])
        end
        table.insert(self.starTab, {key = _key, value = _value})
    end
end

function newGoCheckpoint:getDecText(key, value1, value2)
    local _value1 = value1
    local _value2 = value2
    if key == 6 then    ---技能
        if value1 ~= 0 then
            _value1 = fightModule.GetDecCfgType(tonumber(value1))
        end
    elseif key == 7 or key == 8 then ---怪物
        if value1 ~= 0 then
            _value1 = battle.LoadNPC(_value1).name
        end
        if key ~= 8 then
            if value2 ~= 0 then
                _value2 = battle.LoadNPC(value2).name
            end
        end
    end
    return string.format(fightModule.GetStarDec(key), _value1, _value2)
end

function newGoCheckpoint:initMiddleTop()
    self:initStarTab()
    if self.pveCfg.star1_type ~= 0 then
        for i = 1, 3 do
            local _view = self.view.goCheckpointRoot.middle.top.itemList[i]
            _view.Text[UI.Text].text = self:getDecText(self.starTab[i].key, self.starTab[i].value[1], self.starTab[i].value[2])
            if fightModule.GetOpenStar(self.fightInfo.star, i) == 0 then
                _view.Text[UI.Text].color = {r = 0, g = 0, b = 0, a = 0.5}
                --_view.pass:SetActive(false)
                --_view.close:SetActive(true)
                _view.icon[UI.Image]:LoadSprite("icon/fuben_05")
            else
                _view.Text[UI.Text].color = {r = 0, g = 0, b = 0, a = 1}
               --_view.pass:SetActive(true)
                --_view.close:SetActive(false)
                _view.icon[UI.Image]:LoadSprite("icon/fuben_06")
            end
        end
    else
        self.view.goCheckpointRoot.middle.top.itemList:SetActive(false)
    end
end

function newGoCheckpoint:upBottom()
    self.todayCount.text = (self.pveCfg.count_per_day - self.fightInfo.today_count).."/"..self.pveCfg.count_per_day
    --self.todayCountInfo:TextFormat("今日剩余挑战次数：")
    if self.pveCfg.cost_item_value > ItemModule.GetItemCount(90010) then
        self.view.goCheckpointRoot.bottom.challenge.numb[UI.Text].color = {r = 1, g = 0, b = 0, a = 1}
    else
        self.view.goCheckpointRoot.bottom.challenge.numb[UI.Text].color = {r = 0, g = 0, b = 0, a = 1}
    end
    local _material = nil
    if (self.pveCfg.count_per_day - self.fightInfo.today_count) <= 0 or fightModule.GetOpenStar(self.fightInfo.star, 1) == 0 then
        _material = self.view.goCheckpointRoot.bottom.sweeping[CS.UnityEngine.MeshRenderer].materials[0]
    end
    if not openLevel.GetStatus(6001) then
        _material = self.view.goCheckpointRoot.bottom.sweeping[CS.UnityEngine.MeshRenderer].materials[0]
    end
    self.view.goCheckpointRoot.bottom.sweeping.close:SetActive(not openLevel.GetStatus(6001))
    self.view.goCheckpointRoot.bottom.sweeping.Text:SetActive(openLevel.GetStatus(6001))
    self.view.goCheckpointRoot.bottom.sweeping.close.Text[UI.Text].text = SGK.Localize:getInstance():getValue("tips_lv_02", openLevel.GetCfg(6001).open_lev)
    self.view.goCheckpointRoot.bottom.sweeping[UI.Image].material = _material
    self.view.goCheckpointRoot.bottom.resetBtn:SetActive((self.pveCfg.count_per_day - self.fightInfo.today_count) == 0 and self.pveCfg.reset_consume_id~=0)

    if self.view.goCheckpointRoot.bottom.resetBtn.activeSelf then
        self.view.goCheckpointRoot.bottom.resetBtn.unHave:SetActive(ItemModule.GetItemCount(self.pveCfg.reset_consume_id) <= 0)
        self.view.goCheckpointRoot.bottom.resetBtn.have:SetActive(ItemModule.GetItemCount(self.pveCfg.reset_consume_id) > 0)
        -- self.todayCountInfo:TextFormat("今日剩余重置次数：")
        self.todayCountInfo.text = SGK.Localize:getInstance():getValue("huiyilu_tiaozhan_03")
        if self.product then
            self.todayCount.text = self.product.product_count.."/"..self.product.storage
            local _consumeCfg = ItemHelper.Get(41, self.product.consume_item_id1)
            self.view.goCheckpointRoot.bottom.resetBtn.unHave.icon[UI.Image]:LoadSprite("icon/".._consumeCfg.icon)
            self.view.goCheckpointRoot.bottom.resetBtn.unHave.numb[UI.Text].text = tostring(self.product.consume_item_value1)
        end
    end
    self.view.goCheckpointRoot.bottom.challenge:SetActive(not self.view.goCheckpointRoot.bottom.resetBtn.activeSelf)
    self.view.goCheckpointRoot.bottom.challenge.Image:SetActive(self.pveCfg.cost_item_value ~= 0)
    self.view.goCheckpointRoot.bottom.challenge.icon:SetActive(self.pveCfg.cost_item_value ~= 0)
    self.view.goCheckpointRoot.bottom.challenge.numb:SetActive(self.pveCfg.cost_item_value ~= 0)
    if self.pveCfg.cost_item_value == 0 then
        self.view.goCheckpointRoot.bottom.challenge.Text.transform.localPosition = Vector3(2.7, 0, 0)
    else
        self.view.goCheckpointRoot.bottom.challenge.Text.transform.localPosition = Vector3(2.7, 16, 0)
    end

    self.todayCountInfo.text = SGK.Localize:getInstance():getValue("huiyilu_tiaozhan_05")
    self.view.goCheckpointRoot.bottom.sweeping:SetActive(self.pveCfg.can_yjdq ~= 0)
end

function newGoCheckpoint:listEvent()
    return {
        "FIGHT_INFO_CHANGE",
        "SHOP_INFO_CHANGE",
        "SHOP_BUY_SUCCEED",
        "LOCAL_FIGHT_COUNT_CHANGE",
        "LOCAL_GUIDE_CHANE",
        "LOCAL_PLACEHOLDER_CHANGE",
        "HERO_INFO_CHANGE",
    }
end

function newGoCheckpoint:onEvent(event, data)
    if event == "FIGHT_INFO_CHANGE" or event == "SHOP_INFO_CHANGE" or event == "LOCAL_FIGHT_COUNT_CHANGE" then
        self:upData()
        self:upBottom()
    elseif event == "SHOP_BUY_SUCCEED" then
        if data and data.gid == self.product.gid then
            fightModule.ResetFightCount(self.gid)
        end
        ERROR_LOG("购买体力")
        self:upBottom()
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(103,0.1)
    elseif event == "LOCAL_PLACEHOLDER_CHANGE" then
        self:upHeroList()
    elseif event == "HERO_INFO_CHANGE" then
        self:upHeroList()
    end
end

return newGoCheckpoint
