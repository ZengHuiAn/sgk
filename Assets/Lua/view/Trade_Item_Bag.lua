local TradeModule = require "module.TradeModule"
local ItemHelper = require "utils.ItemHelper"
local EquipModule = require "module.equipmentModule"

local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
    self.pack_idx = 1;
    self.select_idx = 0;
    self.slot = data and data.slot or 0;
    self:InitData();
    self:InitView();
end

function View:InitData()
    self.ToggleUI = {};
    local allEquip = EquipModule.OneselfEquipMentTab();
    local equip_list = {};
    for k,v in pairs(allEquip) do
        if v.heroid == 0 then
            if equip_list[v.type] == nil then
                equip_list[v.type] = {};
            end
            if equip_list[v.type][v.id] == nil then
                equip_list[v.type][v.id] = {};
            end
            table.insert(equip_list[v.type][v.id], v);
        end
    end
    -- for k,v in pairs(equip_list[0]) do
    --     print("测试",k)
    -- end
    local _config = TradeModule.GetConfigByType();
    local info = {};
    for i,v in pairs(_config) do
        local pack_type = {};
        pack_type.type = i;
        pack_type.name = v.name;
        pack_type.list = {};
        for k,j in pairs(v.list) do
            for _,cfg in ipairs(j.list) do
                if cfg.item_type == 43 and equip_list[0] and equip_list[0][cfg.item_id] and #equip_list[0][cfg.item_id] > 0 then
                    for _,equip in ipairs(equip_list[0][cfg.item_id]) do
                        local data = {};
                        data = cfg;
                        data.uuid = equip.uuid;
                        table.insert(pack_type.list, data);
                    end
                elseif cfg.item_type == 45 and equip_list[1] and equip_list[1][cfg.item_id] and #equip_list[1][cfg.item_id] > 0 then
                    for _,equip in ipairs(equip_list[1][cfg.item_id]) do
                        local data = {};
                        data = cfg;
                        data.uuid = equip.uuid;
                        table.insert(pack_type.list, data);
                    end
                elseif ItemHelper.Get(cfg.item_type, cfg.item_id).count > 0 then
                    table.insert(pack_type.list, cfg);
                end
            end
        end
        table.insert(info, pack_type);
    end
    -- print("物品列表",sprinttb(info))
    self.config = info;
end

function View:InitView()
    for i,v in ipairs(self.config) do
        local item = nil;
        if self.ToggleUI[i] == nil then
            local obj = UnityEngine.Object.Instantiate(self.view.pageContainer.Viewport.Content.Toggle.gameObject, self.view.pageContainer.Viewport.Content.gameObject.transform);
            obj.name = "Toggle"..i;
            item = CS.SGK.UIReference.Setup(obj);
            self.ToggleUI[i] = item;
        else
            item = self.ToggleUI[i];
        end
        item.name[CS.UGUISpriteSelector].index = v.type;
        item:SetActive(true)
        CS.UGUIClickEventListener.Get(item.gameObject, true).onClick = function (obj)        
            if i ~= self.pack_idx then
                self.pack_idx = i;
                self:UpdateView();
            end
        end
    end
    self.ToggleUI[self.pack_idx][UnityEngine.UI.Toggle].isOn = true;

    self.view.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function ( obj, idx )
        self:UpdateItem(obj, idx);
    end

    CS.UGUIClickEventListener.Get(self.view.bg.closeBtn.gameObject).onClick = function (obj)        
        DialogStack.Pop();
    end
    CS.UGUIClickEventListener.Get(self.root.BG.gameObject, true).onClick = function (obj)        
        DialogStack.Pop();
    end
    self:UpdateView();
end

function View:UpdateView()
    self.view.NoItemPage:SetActive(#self.config[self.pack_idx].list == 0)
    self.view.ScrollView[CS.UIMultiScroller].DataCount = #self.config[self.pack_idx].list;
end

function View:UpdateItem(obj, idx)
    local info = self.config[self.pack_idx].list[idx + 1];
    local item = CS.SGK.UIReference.Setup(obj);
    local cfg = ItemHelper.Get(info.item_type, info.item_id)
    if info.item_type == 43 or info.item_type == 45 then
        -- print("装备", info.item_type, info.uuid)
        utils.IconFrameHelper.Create(item.IconFrame,{type = info.item_type, uuid = info.uuid})
    else
        utils.IconFrameHelper.Create(item.IconFrame,{type = info.item_type, id = info.item_id, count = cfg.count})
    end
    item.Name[UnityEngine.UI.Text]:TextFormat(cfg.name)
    CS.UGUIClickEventListener.Get(item.IconFrame.gameObject, true).onClick = function (obj)        
        self.select_idx = idx;
        DialogStack.PushPrefStact("Trade_Sale_Frame",{type = 1, gid = info.gid, uuid = info.uuid, canSell = (self.slot < 8)})
    end
    item:SetActive(true);
end

function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
		"TRADE_SELL_SUCCESS",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "TRADE_SELL_SUCCESS"  then
        -- local obj = self.view.ScrollView[CS.UIMultiScroller]:GetItem(self.select_idx);
        -- if obj then
        --     self:UpdateItem(obj, self.select_idx);
        -- end
        self.slot = self.slot + 1;
        -- showDlgError(nil, "上架成功");
        DialogStack.Pop();
        DialogStack.Pop();
	end
end

return View;