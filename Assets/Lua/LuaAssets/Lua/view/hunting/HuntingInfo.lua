local HuntingModule = require "module.HuntingModule"
local MapConfig = require "config.MapConfig"
local openLevel = require "config.openLevel"
local battle = require "config.battle"
local skill = require "config.skill"

local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
    self.dialog = self.root.dialog;
	self:InitData(data);
    self:InitView(data);
    self:initGuide();
end

function View:InitData(data)
    self.initBuyPoint = false;
    local map_id = data and data.map_id or self.savedValues.map_id or 10;
    self.map = HuntingModule.GetMapList()[map_id];
    module.ShopModule.GetManager(8);
end

function View:initGuide()
    module.guideModule.PlayByType(130,0.2)
end

function View:InitView(data)
	CS.UGUIClickEventListener.Get(self.root.BG.gameObject).onClick = function ( object )
        DialogStack.Pop()
   	end
    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function ( object )
  	    DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.back.gameObject).onClick = function ( object )
        DialogStack.Replace("hunting/HuntingFrame")
  end
    self.view.back:SetActive(data and data.showBack);
    self.view.top.Image[UnityEngine.UI.Image]:LoadSprite("guanqia/gq_icon/" .. self.map.map_icon1);
    self.view.top.pos[UI.Text].text = self.map.map_name;
    self.view.top.pos.Limit.Text:TextFormat("推荐等级 Lv{0}+", self.map.depend_level_id);
    if self.map.depend_level_id > module.playerModule.Get().level then
        self.view.top.pos.Limit.Text:TextFormat("<color=red>推荐等级 Lv{0}+</color>", self.map.depend_level_id);
    else
        self.view.top.pos.Limit.Text:TextFormat("推荐等级 Lv{0}+", self.map.depend_level_id);
    end
    self.view.top.Drop1[UI.Image]:LoadSprite("propertyIcon/"..self.map.equipment_icon)
    local mapCfg = MapConfig.GetMapConf(self.map.map_id);
    self.view.top.Lock:SetActive(mapCfg.depend_level > module.playerModule.Get().level);
    self.view.top.Flag:SetActive(self.map.duration ~= 0);
    local elements = self.map.monster_property1 | self.map.monster_property2 | self.map.monster_property3;
    local n = 1;
    for i = 0, 5 do
        if (elements & (1<<i)) ~= 0 then
            self.view.top['Element' .. n]:SetActive(true);
            self.view.top['Element' .. n][CS.UGUISpriteSelector].index = i;
            n = n + 1;
        end
    end
    for i = n, 3 do
        self.view.top['Element' .. i]:SetActive(false);
    end

    self.view.info.des[UI.Text].text = self.map.des;
    for i=1,3 do
        if self.map["monster_icon"..i] ~= 0 then
            local obj = UnityEngine.Object.Instantiate(self.view.info.monster.icon.gameObject, self.view.info.monster.gameObject.transform);
            local item = CS.SGK.UIReference.Setup(obj);
            -- item[UnityEngine.UI.Image]:LoadSprite("icon/"..self.map["monster_icon"..i]);
            utils.IconFrameHelper.Create(item.IconFrame, {customCfg = {
                level = self.map.depend_level_id,
                star = 0,
                quality = 0,
                icon = self.map["monster_icon"..i]
            }, type = 42})
            item.tip:SetActive(self.map["monster_rarity"..i] == 1);
            item:SetActive(true);
            CS.UGUIClickEventListener.Get(item.gameObject).onClick = function ( object )
                self:ShowMonsterInfo(self.map["monster_id"..i], self.map["monster_property"..i]);
            end
        end
    end
    for i=1,6 do
        if self.map["reward_id"..i] ~= 0 then
            local obj = UnityEngine.Object.Instantiate(self.view.info.reward.item.gameObject, self.view.info.reward.gameObject.transform);
            local item = CS.SGK.UIReference.Setup(obj);
            utils.IconFrameHelper.Create(item.IconFrame,{type = self.map["reward_type"..i], id = self.map["reward_id"..i], count = 0, showDetail = true})
            item.tip:SetActive(self.map["reward_rarity"..i] == 1);
            item:SetActive(true);
        end
    end
    CS.UGUIClickEventListener.Get(self.view.formation.btn.gameObject).onClick = function ( object )
        if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗内无法进行该操作")
        else
            DialogStack.PushPrefStact("FormationDialog", {huntingElement = self.map.monster_property4})
        end
    end
    CS.UGUIClickEventListener.Get(self.view.bottom.have.btn.gameObject).onClick = function ( object )
        self:ShowGetAndLock(2);
    end
    CS.UGUIClickEventListener.Get(self.view.bottom.all.btn.gameObject).onClick = function ( object )
        local one, have_ten, all_ten = HuntingModule.GetCount();
        if all_ten > 0 then
            self:ShowGetAndLock(1);
        else
            self:ShowBuyPoint();
        end
    end
    CS.UGUIClickEventListener.Get(self.view.bottom.go.gameObject).onClick = function ( object )
        if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗内无法进行该操作")
        else
            local teamInfo = module.TeamModule.GetTeamInfo();
            -- if teamInfo.id <= 0 then
            --     showDlgError(nil, "请先组建队伍")
            -- else
            -- end
            local one, have_ten, all_ten = HuntingModule.GetCount();
            if one == 0 then
                showDlgError(nil, "今日狩猎点数已用完")
            else
                if teamInfo.id == 0 or module.playerModule.GetSelfID() == teamInfo.leader.pid then
                    HuntingModule.Start(self.map.map_id)
                    -- DialogStack.Pop()
                    DialogStack.CleanAllStack()
                    CS.UnityEngine.GameObject.Destroy(self.gameObject)
                else
                    showDlgError(nil, "只有队长可以带领队伍前往")
                end
            end
        end
    end
    CS.UGUIClickEventListener.Get(self.view.bottom.team.gameObject).onClick = function ( object )
        if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗内无法进行该操作")
        else
            local one, have_ten, all_ten = HuntingModule.GetCount();
            if one == 0 then
                showDlgError(nil, "今日狩猎点数已用完")
            else
                local teamInfo = module.TeamModule.GetTeamInfo();
                if teamInfo.id > 0 then
                    DialogStack.PushPrefStact('TeamFrame',{idx = 1});
                else
                    local list = {}
                    list[2] = {id = self.map.id}
                    DialogStack.PushPrefStact('TeamFrame',{idx = 2,viewDatas = list});
                end
            end
        end
    end
    self:UpdateOnline();
    self:UpdatePoint();
end

function View:UpdateOnline()
    --刷新阵容
    local _list = module.HeroModule.GetManager():GetFormation()
    local _heroList = {}
    for i,v in ipairs(_list) do
        if v ~= 0 then
            table.insert(_heroList, v)
        end
    end

    local openLevelList = {
        [1] = 1701,
        [2] = 1702,
        [3] = 1703,
        [4] = 1704,
        [5] = 1705,
    }

    for i = 1, 5 do
        local _view = self.view.formation.heroList[i]
        _view.IconFrame:SetActive(_heroList[i] ~= nil)
        if _view.IconFrame.activeSelf then
            local _hero = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, _heroList[i])
            utils.IconFrameHelper.Create(_view.IconFrame, {uuid = _hero.uuid, type = 42, func = function (item)
                if _hero.element & self.map.monster_property4 ~= 0 then
                    item[CS.SGK.CommonIcon].Owner = "manor/bg_jian";
                else
                    item[CS.SGK.CommonIcon].Owner = nil;
                end
            end})
        end
        _view.lock:SetActive(not openLevel.GetStatus(openLevelList[i]))
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if _view.lock.activeSelf then
                showDlgError(nil, openLevel.GetCloseInfo(openLevelList[i]))
                return
            end
            if SceneStack.GetBattleStatus() then
                showDlgError(nil, "战斗内无法进行该操作")
            else
                local _hero = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, _heroList[i])
                if _view.IconFrame.activeSelf then
                    self.savedValues.map_id = self.map.map_id;
                    DialogStack.Push("newRole/roleFramework", {heroid = _hero.id})
                else
                    DialogStack.PushPrefStact("FormationDialog", {huntingElement = self.map.monster_property4})
                end
            end
        end
    end
end

function View:UpdatePoint()
    local one, have_ten, all_ten = HuntingModule.GetCount();
    self.view.bottom.have.num[UI.Text].text = have_ten;
    self.view.bottom.all.num[UI.Text].text = all_ten;
    if all_ten > 0 then
        self.view.bottom.all.btn.Text[UI.Text].text = "领取"
    else
        self.view.bottom.all.btn.Text[UI.Text].text = "购买"
    end
end

function View:GetElement(type)
    for i=1,6 do
        if (type & (1 << (i - 1))) ~= 0 then
            return i;
        end
    end
    return 1;
end

function View:ShowMonsterInfo(id, type)
    print("id  ", id)
    local _cfg = battle.LoadNPC(id, self.map.depend_level_id)
    for i=1,4 do
        local item = self.view.tip.desc["item"..i];
        local skill_id = _cfg["skill"..i];
        if skill_id ~= 0 then
            local cfg = skill.GetConfig(skill_id);
            if cfg then
                item.gameObject:SetActive(true);
                item.Text[UI.Text].text = cfg.name;
                item.desc[UI.Text].text = cfg.desc;
                local height = item.desc[UI.Text].preferredHeight;
                item[UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(585.5,height)
            else
                item.gameObject:SetActive(false);
            end
        else
            item.gameObject:SetActive(false);
        end
    end
    self.view.tip.desc.title.flag[CS.UGUISpriteSelector].index = self:GetElement(type) - 1;
    self.view.tip.desc.title.name[UI.Text].text = _cfg.name
    self.view.tip.desc.title.lev[UI.Text].text = "^"..self.map.depend_level_id
    self.view.tip:SetActive(true);
end

function View:ShowGetAndLock(type)
    local one, have_ten, all_ten = HuntingModule.GetCount();
    local count = type == 1 and all_ten or have_ten;
    local view = self.dialog.lock;
    if type == 1 then
        if have_ten >= 100 then
            showDlgError(nil, "最多只能领取100点")
            return;
        elseif all_ten == 0 then
            showDlgError(nil, "没有可以领取的点数")
            return;
        end
        view.title.name[UI.Text].text = "<size=44>领</size>取"
        view.Text1[UI.Text].text = "领取数量";
        view.confirm.Text[UI.Text].text = "领取"
        view.confirm[CS.UGUISelectorGroup].index = 1;
        view.count.InputField[UnityEngine.UI.InputField].text = math.min(all_ten, 100 - have_ten);
    else
        if all_ten >= 100 then
            showDlgError(nil, "最多只能冻结100点")
            return;
        elseif have_ten == 0 then
            showDlgError(nil, "没有可以冻结的点数")
            return;
        end

        view.title.name[UI.Text].text = "<size=44>冻</size>结"
        view.Text1[UI.Text].text = "冻结数量";
        view.confirm.Text[UI.Text].text = "冻结"
        view.confirm[CS.UGUISelectorGroup].index = 2;
        view.count.InputField[UnityEngine.UI.InputField].text = math.min(have_ten, 100 - all_ten);
    end

    CS.UGUIClickEventListener.Get(view.reduce.gameObject).onClick = function ( object )
        local _count = tonumber(view.count.InputField[UnityEngine.UI.InputField].text);
        if _count <= 0 then
            view.count.InputField[UnityEngine.UI.InputField].text = 0;
        else
            _count = _count - 1;
            view.count.InputField[UnityEngine.UI.InputField].text = _count;
        end
    end
    CS.UGUIClickEventListener.Get(view.plus.gameObject).onClick = function ( object )
        local _count = tonumber(view.count.InputField[UnityEngine.UI.InputField].text);
        local max = 0;
        if type == 1 then
            max = math.min(all_ten, 100 - have_ten);
        else
            max = math.min(have_ten, 100 - all_ten);
        end
        _count = _count + 1;
        if _count > max then
            view.count.InputField[UnityEngine.UI.InputField].text = max;
            if type == 1 then
                showDlgError(nil, "最多只能领取100点")
            else
                showDlgError(nil, "最多只能冻结100点")
            end
        else
            view.count.InputField[UnityEngine.UI.InputField].text = _count;
        end
    end
    CS.UGUIClickEventListener.Get(view.max.gameObject).onClick = function ( object )
        local max = 0;
        if type == 1 then
            max = math.min(all_ten, 100 - have_ten);
        else
            max = ath.min(have_ten, 100 - all_ten);
        end
        view.count.InputField[UnityEngine.UI.InputField].text = max;
    end

    CS.UGUIClickEventListener.Get(view.confirm.gameObject).onClick = function ( object )
        local _count = tonumber(view.count.InputField[UnityEngine.UI.InputField].text);
        if _count > 0 then
            if type == 1 then
                if _count > all_ten then
                    showDlgError(nil, "剩余点数不足")
                    return;
                elseif have_ten + _count > 100 then
                    showDlgError(nil, "最多只能领取100点")
                    return;
                else
                    print("领取", _count)
                    HuntingModule.UnlockPoint(_count);
                    self:UpdateButtonState(false);
                end
            else
                if _count > have_ten then
                    showDlgError(nil, "点数不足")
                    return;
                elseif all_ten + _count > 100 then
                    showDlgError(nil, "最多只能冻结100点")
                    return;
                else
                    print("冻结", _count)
                    HuntingModule.LockPoint(_count);
                    self:UpdateButtonState(false);
                end
            end
        end
        view:SetActive(false);
    end
    view:SetActive(true);
end

function View:ShowBuyPoint()
    local view = self.dialog.buy;
    local product = module.ShopModule.GetManager(8).shoplist[1080003];
    local max = product.product_count;
    if max == 0 then
        showDlgError(nil, "今日购买点数已用完")
        return;
    end
    local pirce = product.consume_item_value1;
    local default = 1;
    view.count.InputField[UnityEngine.UI.InputField].text = default;
    view.price.Text[UI.Text].text = default * pirce;
    view.Text3[UI.Text]:TextFormat("今日还可购买{0}点", max);
    if not self.initBuyPoint then
        self.initBuyPoint = true;
        view.count.InputField[UnityEngine.UI.InputField].onValueChanged:AddListener(function (value)
            view.price.Text[UI.Text].text = math.floor(value * pirce);
        end)
    end
    
    CS.UGUIClickEventListener.Get(view.reduce.gameObject).onClick = function ( object )
        local _count = tonumber(view.count.InputField[UnityEngine.UI.InputField].text);
        if _count <= 1 then
            _count = 1;
        else
            _count = _count - 1;
        end
        view.count.InputField[UnityEngine.UI.InputField].text = _count;
        view.price.Text[UI.Text].text = math.floor(_count * pirce);
    end
    CS.UGUIClickEventListener.Get(view.plus.gameObject).onClick = function ( object )
        local _count = tonumber(view.count.InputField[UnityEngine.UI.InputField].text);
        if _count >= max then
            _count = max;
        else
            _count = _count + 1;
        end
        view.count.InputField[UnityEngine.UI.InputField].text = _count;
        view.price.Text[UI.Text].text = math.floor(_count * pirce);
    end
    CS.UGUIClickEventListener.Get(view.max.gameObject).onClick = function ( object )
        view.count.InputField[UnityEngine.UI.InputField].text = max;
        view.price.Text[UI.Text].text = max * pirce;
    end
    CS.UGUIClickEventListener.Get(view.confirm.gameObject).onClick = function ( object )
        local _count = tonumber(view.count.InputField[UnityEngine.UI.InputField].text);
        if _count > 0 then
            if module.ItemModule.GetItemCount(product.consume_item_id1) < (_count * pirce) then
                showDlgError(nil, "货币不足")
                return;
            elseif _count > max then
                showDlgError(nil, "今日最多只能再购买"..max.."点");
                return;
            else
                HuntingModule.BuyPoint(_count);
                self:UpdateButtonState(false);
            end
        end
        view:SetActive(false);
    end
    view:SetActive(true);
end

function View:UpdateButtonState(status)
    SetButtonStatus(status, self.view.bottom.have.btn)
    SetButtonStatus(status, self.view.bottom.all.btn)
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
        "SHOP_BUY_SUCCEED",
        "LOCAL_PLACEHOLDER_CHANGE",
        "SHOP_BUY_FAILED",
        "LOCAL_GUIDE_CHANE"
	}
end

function View:onEvent(event, ...)
    if event == "SHOP_BUY_SUCCEED"  then
        self:UpdateButtonState(true);
        self:UpdatePoint();
    elseif event == "LOCAL_PLACEHOLDER_CHANGE" then
        self:UpdateOnline();
    elseif event == "SHOP_BUY_FAILED" then
        self:UpdateButtonState(true);
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide();
	end
end

return View;