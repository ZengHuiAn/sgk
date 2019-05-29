local npcConfig = require "config.npcConfig"
local heroModule = require "module.HeroModule"
local DataBoxModule = require "module.DataBoxModule"
local HeroBuffModule = require "hero.HeroBuffModule"
local ParameterConf = require "config.ParameterShowInfo";

local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view =  self.root.view;
    self.content = self.view.ScrollView.Viewport.Content;
    self.element = 0;
	self:InitData();
    self:InitView();
    module.guideModule.PlayByType(132, 0.2)
end

function View:InitData()
    self.typeUI = {};
    self.npcUI = {};
    self.prop_list = {};
    self.friendList = npcConfig.GetNpcFriendList();
    self.biographyCfg = DataBoxModule.GetBiographyConfig();
    self.herolist = {};
    local cfg = heroModule.GetConfig();
    local info = {};
    for k,v in pairs(cfg) do
        if self.biographyCfg[v.id] then
            info[v.role_stage] = info[v.role_stage] or {};
            table.insert(info[v.role_stage], v);
        end
    end
    for k,v in pairs(info) do
        table.sort(info[k], function (a, b)
            return a.id < b.id;
        end)
    end
    self.herolist[0] = info;
    for k,j in pairs(self.herolist[0]) do
        for _,v in ipairs(j) do
            local type = v.type
            for i=1,6 do
                if (type & (1 << (i - 1))) ~= 0 then
                    self.herolist[i] = self.herolist[i] or {};
                    self.herolist[i][k] = self.herolist[i][k] or {};
                    table.insert(self.herolist[i][k], v);
                end
            end

            local biographyCfg = DataBoxModule.GetBiographyConfig(v.id);
            if biographyCfg then
                local quest_cfg = module.QuestModule.GetCfg(biographyCfg.attribute_quest);
                if quest_cfg and quest_cfg.reward[1] then
                    local buffCfg = HeroBuffModule.GetBuffConfig(quest_cfg.reward[1].id)
                    if buffCfg then
                        local quest = module.QuestModule.Get(quest_cfg.id);
                        if quest and quest.status == 1 then
                            self.prop_list[buffCfg.type] = (self.prop_list[buffCfg.type] or 0) + quest_cfg.reward[1].value * buffCfg.value;
                        end
                    end
                end
            end
        end
    end

    print("数据", sprinttb(self.herolist))
end

function View:GetElement(type)
    for i=1,6 do
        if (type & (1 << (i - 1))) ~= 0 then
            return i;
        end
    end
    return 1;
end

function View:InitView()
    DialogStack.PushPref("CurrencyChat", nil, self.root.dialog);
    -- CS.UGUIClickEventListener.Get(self.root.BG.gameObject).onClick = function ( object )
    --     DialogStack.Pop()
    -- end
    -- CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function ( object )
    --     DialogStack.Pop()
    -- end
    for i=0,6 do
        local toggle = self.view.toggle["Toggle"..i];
        if self.herolist[i] then
            toggle:SetActive(true);
            CS.UGUIClickEventListener.Get(toggle.gameObject, true).onClick = function ( object )
                if self.element ~= i then
                    for k,v in pairs(self.typeUI) do
                        v:SetActive(false);
                    end
                    for k,v in pairs(self.npcUI) do
                        v:SetActive(false);
                    end
                    self.element = i;
                    -- self.view.ScrollView.Viewport.Content[UnityEngine.UI.ContentSizeFitter].enabled = false;
                    -- self.view.ScrollView.Viewport.Content[UnityEngine.UI.ContentSizeFitter].enabled = true;
                    self:RefreshView();
                    self.view.ScrollView.Viewport.Content[UnityEngine.UI.VerticalLayoutGroup].enabled = false;
                    SGK.Action.DelayTime.Create(0.1):OnComplete(function() 
                        self.view.ScrollView.Viewport.Content[UnityEngine.UI.VerticalLayoutGroup].enabled = true;
                    end)
                end
            end
            toggle[UnityEngine.UI.Toggle].onValueChanged:AddListener(function (value)
                -- print("toogle", i, value)
                if value then
                    -- toggle[UnityEngine.CanvasGroup].alpha = 1;
                    if i == 0 then
                        toggle.all[UnityEngine.UI.Image].color = {r = 1, g = 1, b = 1, a = 1};
                    else
                        toggle.element[UnityEngine.UI.Image].color = {r = 1, g = 1, b = 1, a = 1};
                    end
                    toggle.transform.localPosition = Vector3(-10, toggle.transform.localPosition.y, 0);
                else
                    -- toggle[UnityEngine.CanvasGroup].alpha = 0.5;
                    if i == 0 then
                        toggle.all[UnityEngine.UI.Image].color = {r = 1, g = 1, b = 1, a = 0.5};
                    else
                        toggle.element[UnityEngine.UI.Image].color = {r = 1, g = 1, b = 1, a = 0.5};
                    end
                    toggle.transform.localPosition = Vector3(1, toggle.transform.localPosition.y, 0);
                end
            end)
            toggle[UnityEngine.UI.Toggle].isOn = (self.element == i);
        else
            toggle:SetActive(false);
        end
    end
    self.view.toggle["Toggle"..self.element].transform.localPosition = Vector3(-10, self.view.toggle["Toggle"..self.element].transform.localPosition.y, 0);

    self:RefreshView();
    if self.savedValues.scrollPos then
        self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].anchoredPosition = self.savedValues.scrollPos;
        self.view.ScrollView.Viewport.Content.transform:DOLocalMove(Vector3(0, 1, 0), 0):SetRelative(true);
    end
    local prop_list = {};
    for k,v in pairs(self.prop_list) do
        local info = {};
        local prop_cfg = ParameterConf.Get(k);
        info.key = k;
        info.rate = prop_cfg.rate;
        info.name = prop_cfg.name;
        info.value = prop_cfg.rate == 1 and v or math.floor(v / 100).."%"
        table.insert(prop_list, info)
    end
    table.sort(prop_list, function (a, b)
        if a.rate and b.rate and a.rate ~= b.rate then
            return a.rate < b.rate;
        end
        return a.key < b.key;
    end)
    for i,v in ipairs(prop_list) do
        local obj = CS.UnityEngine.GameObject.Instantiate(self.view.prop_list.content.Text.gameObject, self.view.prop_list.content.transform);
        local item = CS.SGK.UIReference.Setup(obj);
        item[UnityEngine.UI.Text]:TextFormat("{0}+<color=#FFD61FFF>{1}</color>", v.name, v.value);
        item:SetActive(true);
    end
    CS.UGUIClickEventListener.Get(self.view.nowProp.gameObject).onClick = function ( object )
        self:SwitchPropList()
    end
    CS.UGUIClickEventListener.Get(self.view.prop_list.mask.gameObject, true).onClick = function ( object )
        self:SwitchPropList()
    end
    for i=1,4 do
        self.view.ScrollView.Viewport.Content["type"..i][CS.ScrollViewContent].RefreshIconCallback = function (obj,index)
            local npcUI = CS.SGK.UIReference.Setup(obj);
            self:UpdateNpcInfo(npcUI, self.herolist[self.element][i][index + 1], true);
        end
    end
end

function View:SwitchPropList()
    if self.view.prop_list.bg.activeSelf then
        self.view.prop_list.content[UnityEngine.CanvasGroup]:DOFade(0,0.2):OnComplete(function ()
        end)
        self.view.prop_list.bg[CS.UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(544,50),0.1):OnComplete(function ()
            self.view.prop_list.bg:SetActive(false);
            self.view.prop_list.mask:SetActive(false);
        end)
    else
        self.view.prop_list.mask:SetActive(true);
        self.view.prop_list.bg:SetActive(true);
        self.view.prop_list.bg[CS.UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(544,self.view.prop_list.content[CS.UnityEngine.RectTransform].sizeDelta.y),0.1):OnComplete(function ()
            self.view.prop_list.content[UnityEngine.CanvasGroup]:DOFade(1,0.2);
        end)
    end
end
function View:RefreshView()
    local herolist = self.herolist[self.element];
    -- for i=5,1,-1 do
    --     if herolist[i] then
    --         local typeUI = nil;
    --         if self.typeUI[i] then
    --             typeUI = self.typeUI[i];
    --         else
    --             local obj = CS.UnityEngine.GameObject.Instantiate(self.content.type.gameObject, self.content.transform);
    --             typeUI = CS.SGK.UIReference.Setup(obj);
    --             self.typeUI[i] = typeUI;
    --         end
    --         typeUI.Image[CS.UGUISpriteSelector].index = i - 1;
    --         for _,v in ipairs(herolist[i]) do
    --             local npcUI = nil;
    --             if self.npcUI[v.id] then
    --                 npcUI = self.npcUI[v.id];
    --                 self:UpdateNpcInfo(npcUI, v);
    --             else
    --                 local obj = CS.UnityEngine.GameObject.Instantiate(typeUI.npcInfo.gameObject, typeUI.transform);
    --                 npcUI = CS.SGK.UIReference.Setup(obj);
    --                 self.npcUI[v.id] = npcUI;
    --                 self:UpdateNpcInfo(npcUI, v, true);
    --             end
    --             npcUI:SetActive(true);
    --         end
    --         typeUI:SetActive(true);
    --     end
    -- end
    for i=1,4 do
        if herolist[i] then
            self.view.ScrollView.Viewport.Content["type"..i]:SetActive(true);
            self.view.ScrollView.Viewport.Content["type"..i][CS.ScrollViewContent].DataCount = #herolist[i];
        else
            self.view.ScrollView.Viewport.Content["type"..i]:SetActive(false);
        end
    end
end

function View:UpdateNpcInfo(item, cfg, init)
    local hero_id = cfg.id;
    if init then
        item.icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..cfg.mode);
        item.name[UnityEngine.UI.Text].text = cfg.name;
        item.element[CS.UGUISpriteSelector].index = self:GetElement(cfg.type) - 1;
        local biographyCfg = DataBoxModule.GetBiographyConfig(cfg.id);
        if biographyCfg then
            local quest_cfg = module.QuestModule.GetCfg(biographyCfg.attribute_quest);
            if quest_cfg and quest_cfg.reward[1] then
                local buffCfg = HeroBuffModule.GetBuffConfig(quest_cfg.reward[1].id)
                if buffCfg then
                    local prop_cfg = ParameterConf.Get(buffCfg.type);
                    local value = prop_cfg.rate == 1 and (quest_cfg.reward[1].value * buffCfg.value) or math.floor(quest_cfg.reward[1].value * buffCfg.value / 100).."%"
                    item.prop[UnityEngine.UI.Text]:TextFormat("{0}+{1}", prop_cfg.name, value);
                    local quest = module.QuestModule.Get(quest_cfg.id);
                    if quest and quest.status == 1 then
                        self.prop_list[buffCfg.type] = (self.prop_list[buffCfg.type] or 0) + quest_cfg.reward[1].value * buffCfg.value;
                    end
                else
                    item.prop[UnityEngine.UI.Text]:TextFormat("buff找不到")
                end
            else
                item.prop[UnityEngine.UI.Text].text = "";
            end
        end
        local hero = heroModule.GetManager():Get(cfg.id);
        if hero == nil then
            item.icon[UnityEngine.UI.Image].material = item.icon[CS.UnityEngine.MeshRenderer].materials[0];
            item.element[UnityEngine.UI.Image].material = item.icon[CS.UnityEngine.MeshRenderer].materials[0];
            item.prop[CS.UGUIColorSelector].index = 1;
        end
    end

    local npcFriend = self.friendList[cfg.id];
    if npcFriend and npcFriend.arguments_item_id ~= 0 then
        local point = module.ItemModule.GetItemCount(npcFriend.arguments_item_id);
        local relation = StringSplit(npcFriend.qinmi_max,"|")
        local relation_index = #relation;
        for i,v in ipairs(relation) do
            if point < tonumber(v) then
                relation_index = i - 1;
                break;
            end
        end
        item.Slider.FillArea.Fill[CS.UGUISpriteSelector].index = relation_index - 1;
        if relation_index < #relation then
            item.Slider[UnityEngine.UI.Slider].maxValue = tonumber(relation[relation_index + 1]) - tonumber(relation[relation_index]);
            item.Slider[UnityEngine.UI.Slider].value = point - tonumber(relation[relation_index]);
        else
            item.Slider[UnityEngine.UI.Slider].maxValue = 1;
            item.Slider[UnityEngine.UI.Slider].value = 1;
        end
        if relation_index > 1 then
            item.Slider.FillArea.bg:SetActive(true);
            item.Slider.FillArea.bg[CS.UGUISpriteSelector].index = relation_index - 2;
        else
            item.Slider.FillArea.bg:SetActive(false);
        end
    else
        item.Slider:SetActive(false);
    end

    item.red:SetActive(module.RedDotModule.CheckModlue:checkNpcData(hero_id, true))

   
    CS.UGUIClickEventListener.Get(item.gameObject).onClick = function ( object )
        self.savedValues.scrollPos = self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].anchoredPosition;
        print("资料", hero_id)
        local npcFriendData = {};
        local pos = 1;
        local herolist = self.herolist[self.element];
        for i=5,1,-1 do
            if herolist[i] then
                for _,j in ipairs(herolist[i]) do
                    table.insert(npcFriendData, {npc_id = j.id});
                    if hero_id == j.id then
                        pos = #npcFriendData;
                    end
                end
            end
        end
        DialogStack.PushPrefStact("dataBox/NpcData", {pos = pos, npcFriendData = npcFriendData});
    end
    item:SetActive(true);
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
        "QUEST_INFO_CHANGE",
        "PrefStact_POP",
        "SHOP_BUY_SUCCEED",
        "LOCAL_GUIDE_OPT_BIOGRAPHY"
	}
end

function View:onEvent(event, ...)
    print("onEvent", event, ...);
    local data = ...
	if event == "QUEST_INFO_CHANGE" or event == "PrefStact_POP" then
        self:RefreshView();
    elseif event == "SHOP_BUY_SUCCEED" then
        self:RefreshView();
    elseif event == "LOCAL_GUIDE_OPT_BIOGRAPHY" then
        local role_id = tonumber(data[1])
        for stage,v in pairs(self.herolist[0]) do
            for idx,j in ipairs(v) do
                if j.id == role_id then
                    local obj = self.view.ScrollView.Viewport.Content["type"..stage][CS.ScrollViewContent]:GetItem(idx -1)
                    if obj then
                        local pos = self.view.ScrollView.Viewport.Content.transform:InverseTransformPoint(obj.transform.position)
                        local y = math.abs(pos.y);
                        local move_y = 0;
                        if y > (self.view.ScrollView[UnityEngine.RectTransform].rect.height/2) then
                            move_y = math.min(y - self.view.ScrollView[UnityEngine.RectTransform].rect.height/2, self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].rect.height)
                        end
                        SGK.Action.DelayTime.Create(0.1):OnComplete(function() 
                            self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0, move_y);
			                self.view.ScrollView.Viewport.Content.transform:DOLocalMove(Vector3(0, 1, 0), 0):SetRelative(true);
                        end)
                    end
                    break;
                end
            end
        end
	end
end

return View;