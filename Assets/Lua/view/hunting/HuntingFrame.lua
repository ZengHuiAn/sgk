local HuntingModule = require "module.HuntingModule"
local MapConfig = require "config.MapConfig"

local View = {}

function View:Start()
    self.view = SGK.UIReference.Setup(self.gameObject);

    CS.UGUIClickEventListener.Get(self.view.Dialog.Close.gameObject).onClick = function()
        DialogStack.Pop();
    end

    self.ele_filter = 0xffffffff;
    self.drop_filter = 0;
    self.ScrollView = self.view.Dialog.Content.ScrollView[CS.UIMultiScroller];
    self.Tip = self.view.Dialog.Content.Tip;
    self:InitBottom();
    self:InitMaps();
    self:initGuide();
end

function View:initGuide()
    module.guideModule.PlayByType(130,0.2)
end

function View:listEvent()
    return {
        -- "ITEM_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
    }
end

function View:onEvent(event, ...)
    if event == "LOCAL_GUIDE_CHANE" then
        self:initGuide();
    end
end

function View:InitBottom()
    local c1, c2, c3 = HuntingModule.GetCount();
    self.view.Dialog.Content.Tail.CountSingle.Value:TextFormat("{0}/50", c1)
    self.view.Dialog.Content.Tail.CountDouble.Value:TextFormat("{0}/100", c2 + c3)

    self.view.Dialog.Content.Tail.filter.DropdownItem1[UnityEngine.UI.Dropdown].onValueChanged:AddListener(function (i)
        if i == 0 then
            self.ele_filter = 0xffffffff;
        else
            self.ele_filter = (1 << (i-1))
        end
        self.list = self:GetFilterList();
        self.ScrollView.DataCount = #self.list
        self.view.Dialog.Content.None:SetActive(#self.list == 0);
    end)
    self.view.Dialog.Content.Tail.filter.DropdownItem2[UnityEngine.UI.Dropdown].onValueChanged:AddListener(function (i)
        self.drop_filter = i;
        self.list = self:GetFilterList();
        self.ScrollView.DataCount = #self.list
        self.view.Dialog.Content.None:SetActive(#self.list == 0);
    end)
    CS.UGUIClickEventListener.Get(self.view.Dialog.Content.Head.Help.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("shoulie_tip1"), nil, self.view)
    end
    CS.UGUIClickEventListener.Get(self.view.Dialog.Content.Tail.CountSingle.Icon.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("shoulie_tip2"), nil, self.view)
    end
    CS.UGUIClickEventListener.Get(self.view.Dialog.Content.Tail.CountDouble.Icon.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("shoulie_tip3"), nil, self.view)
    end
end

local function mapMatch(v, filter)
    return ((v.monster_property1 & filter) ~= 0)
        or ((v.monster_property2 & filter) ~= 0)
        or ((v.monster_property3 & filter) ~= 0)
end

function View:InitMaps()
    self.ScrollView.RefreshIconCallback = function (obj,idx)
        self:UpdateOneMap(SGK.UIReference.Setup(obj), self.list[idx + 1]);
    end
    self.view.Dialog.Content.Tail.filter.DropdownItem1[UnityEngine.UI.Dropdown].value = self.savedValues.ele_filter or 0;
    self.view.Dialog.Content.Tail.filter.DropdownItem2[UnityEngine.UI.Dropdown].value = self.savedValues.drop_filter or 0;

    if self.list == nil then
        self.list = self:GetFilterList();
        self.ScrollView.DataCount = #self.list
    end
    
    local idx = #self.list;
    for i,v in ipairs(self.list) do
        if module.playerModule.Get().level <= v.depend_level_id then
            idx = i - 1;
            break;
        end
    end
    local move_height = self.savedValues.move_height or (idx * 115 - self.view.Dialog.Content.ScrollView[UnityEngine.RectTransform].rect.height);
    if move_height > 0 then
        self.view.Dialog.Content.ScrollView.Viewport.Content.transform.localPosition = Vector3(0, move_height, 0);
        self.view.Dialog.Content.ScrollView.Viewport.Content.transform:DOLocalMove(Vector3(0, 1, 0), 0):SetRelative(true);
        -- local num = math.ceil(move_height / 115);
        -- self.view.Dialog.Content.ScrollView.Viewport.Content.transform:DOLocalMove(Vector3(0, move_height, 0), num * 0.05):SetDelay(0.1):SetEase(CS.DG.Tweening.Ease.InOutQuad);
    end
end

function View:GetFilterList()
    local list = {}
    local maps = HuntingModule.GetMapList();
    for _, v in pairs(maps) do
        v.monster_property1 = tonumber(v.monster_property1) or 0;
        v.monster_property2 = tonumber(v.monster_property2) or 0;
        v.monster_property3 = tonumber(v.monster_property3) or 0;

        if self.ele_filter == 0xffffffff or mapMatch(v, self.ele_filter) then
            if self.drop_filter == 0 or self.drop_filter == v.equipment then
                table.insert(list, v);
            end
        end
    end

    table.sort(list, function(a,b) 
        -- local a_map = MapConfig.GetMapConf(a.map_id).depend_level <= module.playerModule.Get().level and 1 or 0;
        -- local b_map = MapConfig.GetMapConf(b.map_id).depend_level <= module.playerModule.Get().level and 1 or 0;
        -- if a_map ~= b_map then
        --     return a_map > b_map;
        -- end
        if a.depend_level_id == b.depend_level_id then
            return a.map_id < b.map_id;
        end
        return a.depend_level_id < b.depend_level_id;
    end);
    return list
end

function View:UpdateOneMap(view, map)
    view.Image[UnityEngine.UI.Image]:LoadSprite("guanqia/gq_icon/" .. map.map_icon1);

    if map.depend_level_id > module.playerModule.Get().level then
        view.pos.Limit.Text:TextFormat("<color=red>推荐等级 Lv{0}+</color>", map.depend_level_id);
    else
        view.pos.Limit.Text:TextFormat("推荐等级 Lv{0}+", map.depend_level_id);
    end
    
    local mapCfg = MapConfig.GetMapConf(map.map_id);    --mapCfg.depend_level

    view.pos[UI.Text].text = mapCfg.map_name;

    view.Lock:SetActive(map.depend_level_id > module.playerModule.Get().level);

    view.Flag:SetActive(map.duration ~= 0);
    
    view.Drop1[UI.Image]:LoadSprite("propertyIcon/"..map.equipment_icon)
    local elements = map.monster_property1 | map.monster_property2 | map.monster_property3;

    local n = 1;
    for i = 0, 5 do
        if (elements & (1<<i)) ~= 0 then
            view['Element' .. n]:SetActive(true);
            view['Element' .. n][CS.UGUISpriteSelector].index = i;
            n = n + 1;
        end
    end

    for i = n, 3 do
        view['Element' .. i]:SetActive(false);
    end

    CS.UGUIClickEventListener.Get(view.gameObject).onClick = function()
        if map.depend_level_id <= module.playerModule.Get().level then
            DialogStack.Push("hunting/HuntingInfo", {map_id = map.map_id})
        else
            self.Tip:SetActive(false);
            self.Tip.transform:SetParent(view.gameObject.transform, true);
            self.Tip.Text[UI.Text]:TextFormat("{0}级解锁", map.depend_level_id);
            self.Tip[UnityEngine.CanvasGroup]:DOKill();
            self.Tip[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0, 30);
            self.Tip[UnityEngine.CanvasGroup].alpha = 1;
            -- local pos = self.Tip.transform.position;
            -- self.Tip.transform.position = Vector3(pos.x, view.gameObject.transform.position.y, pos.z);
            self.Tip:SetActive(true);
            self.Tip[UnityEngine.CanvasGroup]:DOFade(0, 1):SetDelay(1);
        end
    end

    view:SetActive(true);
end

function View:OnDestroy()
    self.list = nil;
    self.savedValues.ele_filter = self.view.Dialog.Content.Tail.filter.DropdownItem1[UnityEngine.UI.Dropdown].value;
    self.savedValues.drop_filter = self.view.Dialog.Content.Tail.filter.DropdownItem2[UnityEngine.UI.Dropdown].value;
    self.savedValues.move_height = self.view.Dialog.Content.ScrollView.Viewport.Content.transform.localPosition.y;
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return View;