local Time = require "module.Time"
local TradeModule = require "module.TradeModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local UserDefault = require "utils.UserDefault"
local EquipmentConfig = require "config.equipmentConfig"
local equipmentModule =require "module.equipmentModule"

local View = {};
local trade_data = UserDefault.Load("trade_data", true);
local quality_type = {"绿色","蓝色","紫色","橙色","红色"}
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
    self.dialog = self.root.dialog;
    self.mode = self.savedValues and self.savedValues.mode or 1;
    self.find_id = data and data.find_id or 0;
	self:InitData();
	self:InitView();
end

function View:OnDestroy()
    self.savedValues.mode = self.mode;
end

function View:InitData()
    self.config = {};
    self.ToggleUI = {};
    self.pack_idx = 100;
    self.sub_idx = 0;
    self.gid_idx = 0;
    self.log_idx = 1;
    self.goods_rank = {};
    self.select = 0;
    self.care_count = 0;
    self.player_order = {};
    self.record = {};
    self.screen = {};
    self.search = false
    self.search_str = "";
    self.screen_quality = {};
    self.screen_level = {};
    self.sort_type = {};
    self.screen_list = {};
    self.quality_idx = {};
    if self.find_id ~= 0 then
        self.mode = 1;
        self:InitConfig();
    end
end

function View:InitView()
	CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function (obj)
        DialogStack.Pop();
    end
    CS.UGUIClickEventListener.Get(self.root.BG.gameObject, true).onClick = function (obj)        
        DialogStack.Pop();
    end

    CS.UGUIClickEventListener.Get(self.view.bottom.buy.back.gameObject).onClick = function (obj)        
        if self.gid_idx ~= 0 then
            self.select = 0
            self.gid_idx = 0;
        elseif self.search then
            self.search = false;
            self.view.bottom.buy.search.InputField[UnityEngine.UI.InputField].text = "";
            self.search_str = "";
        elseif self.sub_idx ~= 0 then
            self.sub_idx = 0;
        else
            return;
        end
        self:UpdateBuyMode();
    end

    CS.UGUIClickEventListener.Get(self.view.bottom.buy.buy.gameObject).onClick = function (obj)        
        if self.select ~= 0 then
            local info = self.goods_rank[self.select];
            if ItemModule.GetItemCount(info[3][2]) < info[3][3] then
                showDlgError(nil, "货币不足");
                return;
            end
            TradeModule.Buy(info[1], info);
        end
    end

    CS.UGUIClickEventListener.Get(self.view.bottom.buy.care.gameObject).onClick = function (obj)        
        if self.select ~= 0 then
            local info = self.goods_rank[self.select];
            if info[6] == 1 then
                TradeModule.CareAboutOrder(info[1], 0);
                self.care_count = self.care_count - 1;
            else
                if self.care_count >= 8 then
                    showDlgError(nil, "关注栏已满")
                else
                    TradeModule.CareAboutOrder(info[1], 1);
                    self.care_count = self.care_count + 1;
                end
            end
        end
    end

    CS.UGUIClickEventListener.Get(self.view.bottom.buy.search.btn.gameObject).onClick = function (obj)     
        if self.view.bottom.buy.search.InputField[UnityEngine.UI.InputField].text ~= "" then
            self.gid_idx = 0;
            self.sub_idx = 0;
            self.search_str = self.view.bottom.buy.search.InputField[UnityEngine.UI.InputField].text;
            self.search = true;
            self:UpdateBuyMode();
        end
    end

    self.view.bottom.buy.Dropdown[UnityEngine.UI.Dropdown].onValueChanged:AddListener(function (i)
        -- local pack_type = self.config[self.pack_idx].type;
        -- if pack_type == 2 or pack_type == 3 then
        --     if i ~= 0 then
        --         self.screen_level[self.pack_idx][1] = i;
        --     else
        --         self.screen_level[self.pack_idx] = {}
        --     end
        --     trade_data.screen_data[self.config[self.pack_idx].type].screen_level = self.screen_level[self.pack_idx];
        -- else
        -- end
        if i ~= 0 then
            self.screen_quality[self.pack_idx][1] = self.quality_idx[i];
        else
            self.screen_quality[self.pack_idx] = {}
        end
        trade_data.screen_data[self.config[self.pack_idx].type].screen_quality = self.screen_quality[self.pack_idx];
        self.screen[self.pack_idx] = i ~= 0;
        trade_data.screen_data[self.config[self.pack_idx].type].screen = self.screen[self.pack_idx] and 1 or 0;

        print("选择", i)
        self:UpdateBuyMode();
    end)

    CS.UGUIClickEventListener.Get(self.view.bottom.buy.screen.gameObject).onClick = function (obj)   
        self:ShowScreenDialog();
    end
    
    CS.UGUIClickEventListener.Get(self.view.bottom.log.clear.gameObject).onClick = function (obj)        
        TradeModule.CleanTradeRecord(self.log_idx);
    end

    CS.UGUIClickEventListener.Get(self.dialog.success.ok.gameObject).onClick = function (obj)        
        self:CloseDialog();
    end
    CS.UGUIClickEventListener.Get(self.dialog.success.BG.gameObject, true).onClick = function (obj)        
        self:CloseDialog();
    end
    CS.UGUIClickEventListener.Get(self.dialog.success.title.close.gameObject).onClick = function (obj)        
        self:CloseDialog();
    end

    for i=1,3 do
        local mode_item = self.view.top.mode["type"..i];
        mode_item[UnityEngine.UI.Toggle].onValueChanged:AddListener(function (value)
            mode_item.Image:SetActive(value);
            mode_item.Checkmark.Image:SetActive(value);
        end)
        CS.UGUIClickEventListener.Get(mode_item.gameObject, true).onClick = function (obj) 
            if i ~= self.mode then
                self:SwitchMode(i);
                self.mode = i;
            end       
        end
    end

    self.view.bottom.buy.content.typeView[CS.UIMultiScroller].RefreshIconCallback = function ( obj, idx )
        local info = self.config[self.pack_idx].list[idx + 1];
        local item = CS.SGK.UIReference.Setup(obj);
        item.name[UnityEngine.UI.Text]:TextFormat(info.name);
        CS.UGUIClickEventListener.Get(item.gameObject, true).onClick = function (obj) 
            if self.sub_idx ~= idx + 1 then
                self.sub_idx = idx + 1;
                self:UpdateBuyMode();
                self:UpdateDropdown();
            end
        end
        item:SetActive(true);
    end

    self.view.bottom.buy.content.goodsView[CS.UIMultiScroller].RefreshIconCallback = function ( obj, idx )
        local info = nil;
        if self.search or self.screen[self.pack_idx] then
            info = self.screen_list[idx + 1];
        else
            info = self.config[self.pack_idx].list[self.sub_idx].list[idx + 1];
        end
        local item = CS.SGK.UIReference.Setup(obj);
        local cfg = ItemHelper.Get(info.item_type, info.item_id);
        -- if info.pack_type == 3 then
        --     local equip_cfg = EquipmentConfig.GetConfig(info.item_id);
        --     item.name[UnityEngine.UI.Text]:TextFormat("{0}({1}~{2}级)", cfg.name, equip_cfg.init_min_level, equip_cfg.init_max_level);
        -- else
        -- end
        item.name[UnityEngine.UI.Text]:TextFormat(cfg.name);
        utils.IconFrameHelper.Create(item.IconFrame,{type = info.item_type, id = info.item_id, count = 0})
        CS.UGUIClickEventListener.Get(item.gameObject, true).onClick = function (obj) 
            if self.gid_idx ~= idx + 1 then
                self.gid_idx = idx + 1;
                self:UpdateBuyMode();
            end
        end
        item:SetActive(true);
    end

    self.view.bottom.buy.content.buyView[CS.UIMultiScroller].RefreshIconCallback = function ( obj, idx )
        local info = self.goods_rank[idx + 1];
        local item = CS.SGK.UIReference.Setup(obj);
        local cfg = ItemHelper.Get(info[2][1], info[2][2]);
        local trade_cfg = TradeModule.GetConfigById(info[2][1], info[2][2]);
        item[UnityEngine.UI.Toggle].isOn = (self.select == idx + 1);
        item.name[UnityEngine.UI.Text]:TextFormat(cfg.name);
        item.Toggle:SetActive(trade_cfg.is_special == 1);
        if trade_cfg.is_special == 1 then
            item.Toggle.Checkmark:SetActive(info[6] == 1);
            local value = info[5] or 0;
            item.Toggle.Label[UnityEngine.UI.Text].text = value > 1000 and "999+" or value;
        end
        
        self:CreateIcon(item.IconFrame, info[2], true)
        item.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..info[3][2].."_small");
        item.count[UnityEngine.UI.Text].text = info[3][3];
        CS.UGUIClickEventListener.Get(item.gameObject, true).onClick = function (obj) 
            self.select = idx + 1;
            if not self.view.bottom.buy.buy.activeSelf then
                self.view.bottom.buy.buy:SetActive(true);
            end
            if trade_cfg.is_special == 1 then
                if not self.view.bottom.buy.care.activeSelf then
                    self.view.bottom.buy.care:SetActive(true);
                end
                if info[6] == 1 then
                    self.view.bottom.buy.care[CS.UGUISelectorGroup].index = 0;
                    self.view.bottom.buy.care.Text[UnityEngine.UI.Text]:TextFormat("取消关注");
                else
                    self.view.bottom.buy.care[CS.UGUISelectorGroup].index = 3;
                    self.view.bottom.buy.care.Text[UnityEngine.UI.Text]:TextFormat("关注");
                end
            end
        end
        item:SetActive(true);
    end
                
    self.view.bottom.sale.content.saleView[CS.UIMultiScroller].RefreshIconCallback = function ( obj, idx )
        local info = self.player_order[idx + 1];
        local item = CS.SGK.UIReference.Setup(obj);
        if info then
            item.IconFrame:SetActive(true);
            item.Text:SetActive(false);
            item.time:SetActive((info[4] + 86400) > Time.now());--09EBFFFF 35.4
            item.state:SetActive((info[4] + 86400) <= Time.now());
            if (info[4] + 86400) > Time.now() then
                item.time[UnityEngine.UI.Text]:TextFormat("剩{0}时", math.ceil((info[4] + 86400 - Time.now()) / 3600));
            end
            local cfg = ItemHelper.Get(info[2][1], info[2][2], nil, info[2][3]);
            self:CreateIcon(item.IconFrame, info[2])
            item.info.name[UnityEngine.UI.Text]:TextFormat(cfg.name);
            item.info.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..info[3][2].."_small");
            item.info.count[UnityEngine.UI.Text].text = info[3][3];
            item.info:SetActive(true);
            CS.UGUIClickEventListener.Get(item.gameObject, true).onClick = function (obj) 
                self.select = info[1];
                print("查看上架物品")
                DialogStack.PushPrefStact("Trade_Sale_Frame", {type = 2, order = info, uuid = info[2][4], canSell = true});
            end
        else
            item.IconFrame:SetActive(false);
            item.Text:SetActive(true);
            item.info:SetActive(false);
            item.time:SetActive(false);
            item.state:SetActive(false);
            CS.UGUIClickEventListener.Get(item.gameObject, true).onClick = function (obj) 
                -- self.select = info[1];
                print("上架物品")
                DialogStack.PushPrefStact("Trade_Item_Bag", {slot = #self.player_order});
            end
        end
        item:SetActive(true);
    end

    self.view.bottom.log.content.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function ( obj, idx )
        local info = self.record[idx + 1];
        local item = CS.SGK.UIReference.Setup(obj);
        local cfg = ItemHelper.Get(info[2][1], info[2][2], nil, info[2][3]);
        -- item.newItemIcon[SGK.newItemIcon]:SetInfo(cfg);
        utils.IconFrameHelper.Create(item.IconFrame,{type = info[2][1], id = info[2][2], count = info[2][3]})
        -- self:CreateIcon(item.IconFrame, info[2], self.log_idx == 1 and info[1] or module.playerModule.GetSelfID())
        item.name[UnityEngine.UI.Text]:TextFormat(cfg.name);
        item.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..info[3][2].."_small");
        item.count[UnityEngine.UI.Text].text = info[3][3];
        module.playerModule.Get(info[1],function (player)
            item.player[UnityEngine.UI.Text]:TextFormat("{0}：{1}", self.log_idx == 1 and "购买者" or "出售者", self:utf8sub(2, player.name).."****")
        end)
        item:SetActive(true);
    end

    TradeModule.GetCommodityConfig(function (info)
        if info and info.tax then
            self.view.bottom.sale.tip.Text[UnityEngine.UI.Text]:TextFormat("税率{0}%", math.floor(info.tax * 100));
            self.dialog.success.Text[UnityEngine.UI.Text]:TextFormat("出售期1天，未出售的商品自动下架。\n今日税率：{0}%", math.floor(info.tax * 100));
        end
    end)

    self.view.top.mode["type"..self.mode][UnityEngine.UI.Toggle].isOn = true;
    self:SwitchMode(self.mode);
end

function View:CloseDialog()
    if self.dialog.success.Toggle[UnityEngine.UI.Toggle].isOn then
        local _now = os.date("*t", Time.now());
        trade_data.time = Time.now() - _now.sec - (_now.min * 60) - (_now.hour * 3600);
    end
    self.dialog.success:SetActive(false);
end

function View:CreateIcon(IconFrame, info, showDetail, pid)
    pid = math.floor(pid or 100000);
    if info[1] ~= 43 and info[1] ~= 45 then
        utils.IconFrameHelper.Create(IconFrame,{type = info[1], id = info[2], count = info[3], showDetail = showDetail})
    else
        equipmentModule.QueryEquipInfoFromServer(pid, info[4], function (equip)
            utils.IconFrameHelper.Create(IconFrame,{type = info[1], uuid = info[4], otherPid = pid, showDetail = showDetail})
        end);
    end
end

function View:utf8sub(size, input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local _count = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        if i ~= 1 then
            _count = _count + i
        else
            cnt = cnt + 1
        end
        if (cnt + _count) >= size then
            return string.sub(input, 1, cnt + _count)
        end
    end
    return input;
end

function View:InitConfig()
    print("筛选设置", sprinttb(trade_data.screen_data))
    TradeModule.GetItemFilter();
    local _config = TradeModule.GetConfigByType();
    local info = {};
    local pack_idx = 0;
    for i,v in pairs(_config) do
        local pack_type = {};
        pack_type.type = i;
        pack_type.name = v.name;
        pack_type.list = {};
        for k,j in pairs(v.list) do
            local sub_type = {};
            sub_type.type = k;
            sub_type.name = j.name;
            sub_type.list = j.list;
            if self.find_id ~= 0 then
                for x,y in ipairs(j.list) do
                    if y.item_id == self.find_id then
                        self.find_id = 0;
                        self.pack_idx = #info + 1;
                        self.sub_idx = #pack_type.list + 1;
                        self.gid_idx = x;
                        print("查找", self.pack_idx, self.sub_idx, self.gid_idx)
                    end
                end
            end
            table.insert(pack_type.list, sub_type);
        end
        table.insert(info, pack_type);
        pack_idx = pack_idx + 1;
        if trade_data.screen_data == nil then
            trade_data.screen_data = {};
        end
        if trade_data.screen_data[i] == nil then
            trade_data.screen_data[i] = {};
            trade_data.screen_data[i].screen_quality = {};
            trade_data.screen_data[i].sort_type = 0;
            -- if i == 2 or i == 3 then
            --     trade_data.screen_data[i].screen_level = {};
            --     local sortCfg = TradeModule.GetSortConfig(i)
            --     for x=#sortCfg,1,-1 do
            --         if module.playerModule.Get().level >= sortCfg[x].min_lv then
            --             table.insert(trade_data.screen_data[i].screen_level, x);
            --             break;
            --         end
            --     end
            --     trade_data.screen_data[i].screen = 1;
            -- else
            --     trade_data.screen_data[i].screen_level = {};
            --     trade_data.screen_data[i].screen = 0;
            -- end   
        end
        self.screen_quality[pack_idx] = trade_data.screen_data[i].screen_quality;
        self.screen_level[pack_idx] = trade_data.screen_data[i].screen_level;
        self.sort_type[pack_idx] = trade_data.screen_data[i].sort_type;
        self.screen[pack_idx] = trade_data.screen_data[i].screen == 1;
    end
    self.config = info;
end

function View:SwitchMode(mode)
    -- print("切换模式", mode)
    for i,v in pairs(self.ToggleUI) do
        v[UnityEngine.UI.Toggle].isOn = false;
        v:SetActive(false);
    end
    self.view.bottom.buy:SetActive(mode == 1);
    self.view.bottom.sale:SetActive(mode == 2);
    self.view.bottom.log:SetActive(mode == 3);
    if self.ToggleUI[100] then
        self.ToggleUI[100]:SetActive(mode == 1)
    end
    -- self.view.top.Text:SetActive(mode == 2);
    self.select = 0;
    if mode == 1 then
        if self.mode ~= mode then
            self.sub_idx = 0;
            self.gid_idx = 0;
        end
        if #self.config == 0 then
            self:InitConfig();
        end
        if self.ToggleUI[100] == nil then
            local obj = UnityEngine.Object.Instantiate(self.view.bottom.typeView.Viewport.Content.Toggle.gameObject, self.view.bottom.typeView.Viewport.Content.gameObject.transform);
            obj.name = "Toggle100";
            local item = CS.SGK.UIReference.Setup(obj);
            self.ToggleUI[100] = item;
            item.Label[UnityEngine.UI.Text]:TextFormat("关注");
            item:SetActive(true)
            CS.UGUIClickEventListener.Get(item.gameObject, true).onClick = function (obj)        
                if self.pack_idx ~= 100 then
                    self.pack_idx = 100;
                    self.sub_idx = 0;
                    self.gid_idx = 0;
                    self.select = 0;
                    self:UpdateBuyMode();
                end
            end
        end
        for i,v in ipairs(self.config) do
            local item = nil;
            if self.ToggleUI[i] == nil then
                local obj = UnityEngine.Object.Instantiate(self.view.bottom.typeView.Viewport.Content.Toggle.gameObject, self.view.bottom.typeView.Viewport.Content.gameObject.transform);
                obj.name = "Toggle"..i;
                item = CS.SGK.UIReference.Setup(obj);
                self.ToggleUI[i] = item;
            else
                item = self.ToggleUI[i];
            end
            item.Label[UnityEngine.UI.Text]:TextFormat(v.name);
            item:SetActive(true)
            CS.UGUIClickEventListener.Get(item.gameObject, true).onClick = function (obj)        
                if i ~= self.pack_idx then
                    self.pack_idx = i;
                    self.sub_idx = 0;
                    self.gid_idx = 0;
                    self.select = 0;
                    self:UpdateBuyMode();
                end
            end
        end
        if self.pack_idx == 0 then
            self.pack_idx = 1;
        end
        if self.ToggleUI[self.pack_idx] then
            self.ToggleUI[self.pack_idx][UnityEngine.UI.Toggle].isOn = true;
        end
        self:UpdateBuyMode();
    elseif mode == 2 then
        TradeModule.GetPlayerOrders(function (list)
            self.player_order = list;
            self.view.bottom.sale.tip.count[UnityEngine.UI.Text]:TextFormat("我的货架{0}/8", #self.player_order)
            self.view.bottom.sale.content.saleView[CS.UIMultiScroller].DataCount = 8;
        end)
    elseif mode == 3 then
        for i=1,2 do
            local item = nil;
            if self.ToggleUI[i] == nil then
                local obj = UnityEngine.Object.Instantiate(self.view.bottom.typeView.Viewport.Content.Toggle.gameObject, self.view.bottom.typeView.Viewport.Content.gameObject.transform);
                obj.name = "Toggle"..i;
                item = CS.SGK.UIReference.Setup(obj);
                self.ToggleUI[i] = item;
            else
                item = self.ToggleUI[i];
            end
            if i == 1 then
                item.Label[UnityEngine.UI.Text]:TextFormat("出售记录");
            else
                item.Label[UnityEngine.UI.Text]:TextFormat("购买记录");
            end
            item:SetActive(true)
            CS.UGUIClickEventListener.Get(item.gameObject, true).onClick = function (obj)  
                if self.log_idx ~= i then
                    self.log_idx = i;
                    self:UpdateRecord();
                end
            end
        end
        self.ToggleUI[self.log_idx][UnityEngine.UI.Toggle].isOn = true;
        self:UpdateRecord();
    end
end

function View:UpdateDropdown()
    if self.config[self.pack_idx] == nil then
        return;
    end
    local pack_type = self.config[self.pack_idx].type;
    self.view.bottom.buy.Dropdown[UnityEngine.UI.Dropdown]:ClearOptions();
    -- if pack_type == 2 or pack_type == 3 then
    --     self.view.bottom.buy.Dropdown[SGK.DropdownController]:AddOpotion("全部等级")
    --     local sortCfg = TradeModule.GetSortConfig(pack_type)
    --     if sortCfg then
    --         for i,v in ipairs(sortCfg) do
    --             self.view.bottom.buy.Dropdown[SGK.DropdownController]:AddOpotion(v.min_lv.."级")
    --         end
    --     end
    --     self.view.bottom.buy.Dropdown[UnityEngine.UI.Dropdown].value = self.screen_level[self.pack_idx][1] or 0
    --     self.view.bottom.buy.Dropdown.Label[UnityEngine.UI.Text].text = self.view.bottom.buy.Dropdown[UnityEngine.UI.Dropdown].options[self.view.bottom.buy.Dropdown[UnityEngine.UI.Dropdown].value].text;
    -- else
    -- end
    self.view.bottom.buy.Dropdown[SGK.DropdownController]:AddOpotion("全部品质")
    self.quality_idx = {};
    local idx = 0
    local target_list = self.config[self.pack_idx].list[self.sub_idx].list
    local filter = TradeModule.GetItemFilter(target_list[1].pack_type, target_list[1].sub_type)
    for i,v in ipairs(quality_type) do
        if filter[i] then
            idx = idx + 1;
            self.quality_idx[idx] = i
            self.view.bottom.buy.Dropdown[SGK.DropdownController]:AddOpotion(v);
        end
    end
    local quality_idx = 0
    for i,v in ipairs(self.quality_idx) do
        if v == self.screen_quality[self.pack_idx][1] then
            quality_idx = i;
        end
    end
    self.view.bottom.buy.Dropdown[UnityEngine.UI.Dropdown].value = quality_idx or 0
    self.view.bottom.buy.Dropdown.Label[UnityEngine.UI.Text].text = self.view.bottom.buy.Dropdown[UnityEngine.UI.Dropdown].options[self.view.bottom.buy.Dropdown[UnityEngine.UI.Dropdown].value].text;
end

function View:UpdateRecord()
    if self.log_idx == 1 then
        self.view.bottom.log.content.none.Text[UnityEngine.UI.Text]:TextFormat("暂无出售记录哦")
        self.view.bottom.log.Text2[UnityEngine.UI.Text]:TextFormat("金额")
    else
        self.view.bottom.log.content.none.Text[UnityEngine.UI.Text]:TextFormat("暂无购买记录哦")
        self.view.bottom.log.Text2[UnityEngine.UI.Text]:TextFormat("花费")
    end
    TradeModule.GetTradeRecord(self.log_idx, function (record_list)
        if record_list and #record_list ~= 0 then
            self.view.bottom.log.content.none:SetActive(false);
            self.record = record_list;
            self.view.bottom.log.content.ScrollView[CS.UIMultiScroller].DataCount = #record_list;
            print("交易记录", sprinttb(record_list))
        else
            self.view.bottom.log.content.ScrollView[CS.UIMultiScroller].DataCount = 0;
            self.view.bottom.log.content.none:SetActive(true);
        end
    end);
end

function View:ScreenList()
    local screen_list = {};
    local sortCfg = TradeModule.GetSortConfig(self.config[self.pack_idx].type);
    local target_list = {};
    -- print("筛选", self.pack_idx, self.sub_idx, self.search_str == "", sprinttb(self.screen_quality[self.pack_idx]))
    if self.search_str ~= "" then
        for _,v in pairs(self.config[self.pack_idx].list) do
            for _,j in pairs(v.list) do
                local cfg = ItemHelper.Get(j.item_type, j.item_id);
                if string.find(cfg.name, self.search_str) then
                    table.insert(target_list, j);
                end
            end
        end
    else
        target_list = self.config[self.pack_idx].list[self.sub_idx].list
    end

    for _,j in pairs(target_list) do
        repeat
            local cfg = ItemHelper.Get(j.item_type, j.item_id);
            if self.search_str ~= "" and string.find(cfg.name, self.search_str) == nil then
                break;
            end
            if self.screen_quality[self.pack_idx] and #self.screen_quality[self.pack_idx] ~= 0 then
                local next = false;
                for _,k in ipairs(self.screen_quality[self.pack_idx]) do
                    if cfg.quality == k then
                        next = true;
                        break;
                    end
                end
                if not next then
                    break;
                end
            end
            if self.screen_level[self.pack_idx] and #self.screen_level[self.pack_idx] ~= 0 and sortCfg then
                local next = false;
                for _,k in ipairs(self.screen_level[self.pack_idx]) do
                    if j.item_type == 45 or j.item_type == 43 then
                        local equip_cfg = EquipmentConfig.GetConfig(j.item_id);
                        if equip_cfg and sortCfg[k].min_lv == equip_cfg.equip_level then
                            next = true;
                            break;
                        end
                    else
                        next = true;
                        break;
                    -- elseif j.item_type == 43 then
                    --     if sortCfg[k].min_lv <= (j.item_id % 100) * 20 - 10 and sortCfg[k].max_lv >= (j.item_id % 100) * 20 then
                    --         next = true;
                    --     end
                    --     break;
                    end
                end
                if not next then
                    break;
                end
            end
            table.insert(screen_list, j)
        until true
    end

    -- table.sort(screen_list, function (a,b)
    --     if a.item_id ~= b.item_id then
    --         if self.config[self.pack_idx].type == 2 then
    --             if self.sort_type[self.pack_idx] == 0 then
    --                 return (a.item_id % 100) < (b.item_id % 100)
    --             else
    --                 return (a.item_id % 100) > (b.item_id % 100)
    --             end
    --         elseif self.config[self.pack_idx].type == 3 then
    --             local equip_cfg1 = EquipmentConfig.GetConfig(a.item_id);
    --             local equip_cfg2 = EquipmentConfig.GetConfig(b.item_id);
    --             if equip_cfg1 and equip_cfg2 and equip_cfg1.init_min_level ~= equip_cfg2.init_min_level then
    --                 if self.sort_type[self.pack_idx] == 0 then
    --                     return equip_cfg1.init_min_level < equip_cfg2.init_min_level
    --                 else
    --                     return equip_cfg1.init_min_level > equip_cfg2.init_min_level
    --                 end
    --             end
    --         end
    --     end
    --     return a.gid < b.gid
    -- end)
    self.screen_list = screen_list;
end

function View:ShowScreenDialog()
    for i=1,5 do
        self.dialog.screen.content.screen.quality["Toggle"..i][UnityEngine.UI.Toggle].isOn = false;
    end
    for i,v in ipairs(self.screen_quality[self.pack_idx]) do
        self.dialog.screen.content.screen.quality["Toggle"..v][UnityEngine.UI.Toggle].isOn = true;
    end
    local sortCfg = TradeModule.GetSortConfig(self.config[self.pack_idx].type)
    if sortCfg then
        self.dialog.screen.content.screen.level:SetActive(true);
        self.dialog.screen.content[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,843);
        self.dialog.screen.content.screen[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,688);
        self.dialog.screen.content.type.Toggle2.Background[UnityEngine.UI.Image].material = nil;
        self.dialog.screen.content.type.Toggle2.Label[CS.UGUIColorSelector].index = self.dialog.screen.content.type.Toggle2[UnityEngine.UI.Toggle].isOn and 1 or 0;
        self.dialog.screen.content.type.Toggle2[UnityEngine.UI.Toggle].interactable = true;
        for i=1,10 do
            if sortCfg[i] then
                self.dialog.screen.content.screen.level["Toggle"..i]:SetActive(true);
                self.dialog.screen.content.screen.level["Toggle"..i].Text[UnityEngine.UI.Text]:TextFormat("{0}~{1}级", sortCfg[i].min_lv, sortCfg[i].max_lv);
                self.dialog.screen.content.screen.level["Toggle"..i][UnityEngine.UI.Toggle].isOn = false;
            else
                self.dialog.screen.content.screen.level["Toggle"..i]:SetActive(false);
            end
        end
        for i,v in ipairs(self.screen_level[self.pack_idx]) do
            self.dialog.screen.content.screen.level["Toggle"..v][UnityEngine.UI.Toggle].isOn = true;
        end
        
        self.dialog.screen.content.search.level.Image.transform.localScale = Vector3(1, self.sort_type[self.pack_idx] == 0 and -1 or 1, 1);
    else
        self.dialog.screen.content.screen.level:SetActive(false);
        self.dialog.screen.content[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,455);
        self.dialog.screen.content.screen[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,270);
        self.dialog.screen.content.type.Toggle2.Background[UnityEngine.UI.Image].material = self.dialog.screen.content.type.Toggle2.Background[CS.UnityEngine.MeshRenderer].materials[0];
        self.dialog.screen.content.type.Toggle2.Label[CS.UGUIColorSelector].index = 2;
        if self.dialog.screen.content.type.Toggle2[UnityEngine.UI.Toggle].isOn then
            self.dialog.screen.content.type.Toggle1[UnityEngine.UI.Toggle].isOn = true;
        end
    end
    self.dialog.screen.content.type.Toggle2[UnityEngine.UI.Toggle].interactable = false;
    
    local sort_type = self.sort_type[self.pack_idx];
    CS.UGUIClickEventListener.Get(self.dialog.screen.content.search.level.gameObject).onClick = function (obj)   
        if sort_type == 0 then
            sort_type = 1;
            self.dialog.screen.content.search.level.Image.transform.localScale = Vector3(1, 1, 1);
        else
            sort_type = 0;
            self.dialog.screen.content.search.level.Image.transform.localScale = Vector3(1, -1, 1);
        end
    end
    CS.UGUIClickEventListener.Get(self.dialog.screen.content.ok.gameObject).onClick = function (obj)  
        self.screen_quality[self.pack_idx] = {};
        for i=1,5 do
            if self.dialog.screen.content.screen.quality["Toggle"..i][UnityEngine.UI.Toggle].isOn then
                table.insert(self.screen_quality[self.pack_idx], i);
            end
        end
        self.screen_level[self.pack_idx] = {};
        for i=1,10 do
            if self.dialog.screen.content.screen.level["Toggle"..i][UnityEngine.UI.Toggle].isOn then
                table.insert(self.screen_level[self.pack_idx], i);
            end
        end
        self.sort_type[self.pack_idx] = sort_type;
        if #self.screen_quality[self.pack_idx] > 0 or #self.screen_level[self.pack_idx] > 0 or self.sort_type[self.pack_idx] ~= 0 then
            self.screen[self.pack_idx] = true;
        else
            self.screen[self.pack_idx] = false;
        end
        if trade_data.screen_data[self.config[self.pack_idx].type] == nil then
            trade_data.screen_data[self.config[self.pack_idx].type] = {};
        end
        trade_data.screen_data[self.config[self.pack_idx].type].screen_quality = self.screen_quality[self.pack_idx];
        trade_data.screen_data[self.config[self.pack_idx].type].screen_level = self.screen_level[self.pack_idx];
        trade_data.screen_data[self.config[self.pack_idx].type].sort_type = self.sort_type[self.pack_idx];
        trade_data.screen_data[self.config[self.pack_idx].type].screen = self.screen[self.pack_idx] and 1 or 0;
        self:UpdateBuyMode();
        self.dialog.screen.gameObject:SetActive(false);
    end
    self.dialog.screen.gameObject:SetActive(true);
end

function View:UpdateBuyMode()
    if self.screen[self.pack_idx] then
        self.view.bottom.buy.screen[CS.UGUISelectorGroup]:reset();
    else
        self.view.bottom.buy.screen[CS.UGUISelectorGroup]:setGray();
    end
    self.view.bottom.buy.Dropdown[UnityEngine.CanvasGroup].alpha = 0; 
    self.view.bottom.buy.content.none:SetActive(false);
    self.view.bottom.buy.buy:SetActive(false);
    self.view.bottom.buy.care:SetActive(false);
    self.view.bottom.buy.tip:SetActive(self.pack_idx ~= 100);
    self.view.bottom.buy.search:SetActive(self.pack_idx ~= 100);
    self.view.bottom.buy.care_tip:SetActive(self.pack_idx == 100);
    self.view.bottom.buy.back:SetActive(self.gid_idx ~= 0 or (self.gid_idx == 0 and self.sub_idx ~= 0 or (self.search and self.pack_idx ~= 100)));
    self.view.bottom.buy.content.buyView:SetActive(self.gid_idx ~= 0 or (self.gid_idx == 0 and self.sub_idx == 0 and not (self.search and self.pack_idx ~= 100) and self.pack_idx == 100));
    self.view.bottom.buy.content.goodsView:SetActive(self.gid_idx == 0 and (self.sub_idx ~= 0 or (self.search and self.pack_idx ~= 100)));
    self.view.bottom.buy.content.typeView:SetActive(self.gid_idx == 0 and self.sub_idx == 0 and not (self.search and self.pack_idx ~= 100) and self.pack_idx ~= 0 and self.pack_idx ~= 100);

    -- self.view.bottom.buy.content.buyView:SetActive(false);
    -- self.view.bottom.buy.content.goodsView:SetActive(false);
    -- self.view.bottom.buy.content.typeView:SetActive(false);
    if self.gid_idx ~= 0 then
        local cfg = nil;
        if self.search or self.screen[self.pack_idx] then
            cfg = self.screen_list[self.gid_idx];
        else
            cfg = self.config[self.pack_idx].list[self.sub_idx].list[self.gid_idx];
        end
        local callback = function (ranklist)
            self.goods_rank = ranklist;
            if ranklist[self.select] == nil then
                self.select = 0;
            end
            self.view.bottom.buy.content.buyView[CS.UIMultiScroller].DataCount = #ranklist;
            -- self.view.bottom.buy.content.buyView:SetActive(true);
            self.view.bottom.buy.content.none:SetActive(#ranklist == 0);
            if #ranklist == 0 then
                self.view.bottom.buy.content.none.Text[UnityEngine.UI.Text]:TextFormat("暂时无人出售此商品");
                self.select = 0;
            end
            
            self.view.bottom.buy.buy:SetActive(self.select ~= 0);
            self.view.bottom.buy.care:SetActive(cfg.is_special == 1 and self.select ~= 0);
            if self.select ~= 0 then
                local info = self.goods_rank[self.select];
                if info[6] == 1 then
                    self.view.bottom.buy.care[CS.UGUISelectorGroup].index = 0;
                    self.view.bottom.buy.care.Text[UnityEngine.UI.Text]:TextFormat("取消关注");
                else
                    self.view.bottom.buy.care[CS.UGUISelectorGroup].index = 3;
                    self.view.bottom.buy.care.Text[UnityEngine.UI.Text]:TextFormat("关注");
                end
            end
        end
        TradeModule.QueryOrdersRank(cfg.gid, callback);
        self.view.bottom.buy.back.Text[UnityEngine.UI.Text]:TextFormat("返回上级");
        self.view.bottom.buy.tip.Text[UnityEngine.UI.Text]:TextFormat("仅显示前50件商品");
    elseif self.sub_idx ~= 0 or (self.search and self.pack_idx ~= 100) then
        self.view.bottom.buy.Dropdown[UnityEngine.CanvasGroup].alpha = 1; 
        if self.search then
            self.view.bottom.buy.tip.Text[UnityEngine.UI.Text]:TextFormat("找到符合条件的如下");
            self.view.bottom.buy.back.Text[UnityEngine.UI.Text]:TextFormat("取消搜索");
        else
            self.view.bottom.buy.back.Text[UnityEngine.UI.Text]:TextFormat("返回上级");
            self.view.bottom.buy.tip.Text[UnityEngine.UI.Text]:TextFormat("选择 <color=#51FDFFFF>{0}</color> 商品分类", self.config[self.pack_idx].list[self.sub_idx].name);
        end
        if self.search or self.screen[self.pack_idx] then
            self:ScreenList();
            self.view.bottom.buy.content.goodsView[CS.UIMultiScroller].DataCount = #self.screen_list;
            if #self.screen_list == 0 then
                self.view.bottom.buy.content.none.Text[UnityEngine.UI.Text]:TextFormat("未找到符合条件的商品");
                self.view.bottom.buy.content.none:SetActive(true);
            end
        else
            self.view.bottom.buy.content.goodsView[CS.UIMultiScroller].DataCount = #self.config[self.pack_idx].list[self.sub_idx].list
        end
        -- self.view.bottom.buy.content.goodsView:SetActive(true)
    elseif self.pack_idx ~= 0 then
        if self.pack_idx == 100 then
            local callback = function (ranklist)
                self.goods_rank = ranklist;
                if ranklist[self.select] == nil then
                    self.select = 0;
                end
                self.view.bottom.buy.content.buyView[CS.UIMultiScroller].DataCount = #ranklist;
                self.care_count = #ranklist;
                -- self.view.bottom.buy.content.buyView:SetActive(true);
                self.view.bottom.buy.content.none:SetActive(#ranklist == 0);
                if #ranklist == 0 then
                    self.view.bottom.buy.content.none.Text[UI.Text].text = SGK.Localize:getInstance():getValue("jiaoyihang_tip_1")
                    self.select = 0;
                end
                self.view.bottom.buy.care_tip.Text[UnityEngine.UI.Text]:TextFormat("我的关注：{0} / 8", #ranklist)
                self.view.bottom.buy.buy:SetActive(self.select ~= 0);
                self.view.bottom.buy.care:SetActive(self.select ~= 0);
                if self.select ~= 0 then
                    local info = self.goods_rank[self.select];
                    if info[6] == 1 then
                        self.view.bottom.buy.care[CS.UGUISelectorGroup].index = 0;
                        self.view.bottom.buy.care.Text[UnityEngine.UI.Text]:TextFormat("取消关注");
                    else
                        self.view.bottom.buy.care[CS.UGUISelectorGroup].index = 3;
                        self.view.bottom.buy.care.Text[UnityEngine.UI.Text]:TextFormat("关注");
                    end
                end
            end
            TradeModule.QueryCareAboutList(callback);
        else
            self.view.bottom.buy.content.typeView[CS.UIMultiScroller].DataCount = #self.config[self.pack_idx].list;
            -- self.view.bottom.buy.content.typeView:SetActive(true)
            self.view.bottom.buy.tip.Text[UnityEngine.UI.Text]:TextFormat("选择 <color=#51FDFFFF>{0}</color> 商品分类", self.config[self.pack_idx].name);
        end
    end
end

function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
        "TRADE_BUY_SUCCESS",
        "TRADE_TAKEBACK_FAILD",
        "TRADE_TAKEBACK_SUCCESS",
        "TRADE_RECORD_CHANGE",
        "TRADE_SELL_SUCCESS",
        "TRADE_ORDER_NOT_EXIST",
        "TRADE_ORDER_CRAE_SUCCESS"
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "TRADE_BUY_SUCCESS"  then
        self:UpdateBuyMode();
    elseif event == "TRADE_TAKEBACK_SUCCESS" or event == "TRADE_TAKEBACK_FAILD" or event == "TRADE_SELL_SUCCESS" then
        if event == "TRADE_TAKEBACK_FAILD" then
            showDlgError(nil, "商品已被买走")
        end
        if event == "TRADE_SELL_SUCCESS" then
            if trade_data and trade_data.time and trade_data.time + 86400 > Time.now() then --604800
            else
                self.dialog.success:SetActive(true);
            end
        end
        TradeModule.GetPlayerOrders(function (list)
            self.player_order = list;
            self.view.bottom.sale.tip.count[UnityEngine.UI.Text]:TextFormat("我的货架{0}/8", #self.player_order)
            self.view.bottom.sale.content.saleView[CS.UIMultiScroller].DataCount = 8;
        end)
    elseif event == "TRADE_RECORD_CHANGE" then
        self:UpdateRecord();
    elseif event == "TRADE_ORDER_NOT_EXIST" then
        showDlgError(nil, "下手慢了，商品已经被人买走了")
        self.select = 0;
        self:UpdateBuyMode();
    elseif event == "TRADE_ORDER_CRAE_SUCCESS" then
        local data = ...;
        if data == 1 then
            showDlgError(nil, SGK.Localize:getInstance():getValue("trading_1"));
        elseif data == 0 then
            showDlgError(nil, SGK.Localize:getInstance():getValue("trading_2"));
        end
        self:UpdateBuyMode();
	end
end

return View;