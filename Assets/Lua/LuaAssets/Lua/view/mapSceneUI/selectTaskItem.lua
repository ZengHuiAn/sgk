local ItemHelper = require "utils.ItemHelper"
local ItemModule=require"module.ItemModule"

local selectTaskItem = {}

function selectTaskItem:Start(data)
    self:initData(data)
    self:initUi()
end

function selectTaskItem:initData(data)
    if not data then
        data = {}
        print("selectTaskItem not data")
    end
    self.consumeTab = data.consumeTab
    self.fun = data.fun
end

function selectTaskItem:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initBtn()
    self:initScrollView()
end

function selectTaskItem:getTabLen(tab)
    local _i = 0
    for k,v in pairs(tab) do
        if v.id ~= 0 and v.value ~= 0 then
            _i = _i + 1
        end
    end
    return _i
end

function selectTaskItem:initScrollView()
    if self:getTabLen(self.consumeTab) == 1 then
        for k,v in pairs(self.consumeTab) do
            if v.id ~= 0 and v.value ~= 0 then
                local _itemCfg = ItemHelper.Get(v.type, v.id, nil, v.value)
                local count = ItemModule.GetItemCount(v.id)
                local const_str = ( (count or 0) >= v.value and (count or 0).."/"..v.value or "<color=red>"..(count or 0).."</color>".. "/"..v.value)
                local icon = utils.IconFrameHelper.Create(self.view.selectTaskItemRoot.newItemIcon, {type = v.type, id = v.id,count_str = const_str , showDetail =  true, pos = 2})
                self.view.selectTaskItemRoot.newItemIcon:SetActive(true)
                return
            end
        end
    end
    self.view.selectTaskItemRoot.newItemIcon:SetActive(false)
    if not self.consumeTab then print("selectTaskItem func not find") return end
    local _item = self.view.selectTaskItemRoot.ScrollView.Viewport.Content.item
    if type(self.consumeTab) ~= "table" then print("selectTaskItem consumeTab is", type(self.consumeTab)) return end
    for k,v in pairs(self.consumeTab) do
        if v.id ~= 0 and v.value ~= 0 then
            local _obj = CS.UnityEngine.GameObject.Instantiate(_item.gameObject, self.view.selectTaskItemRoot.ScrollView.Viewport.Content.gameObject.transform)
            local _view = CS.SGK.UIReference.Setup(_obj)
            local _itemCfg = ItemHelper.Get(v.type, v.id, nil, v.value)
            
            _view[SGK.newItemIcon]:SetInfo(_itemCfg, true)
            _view[SGK.newItemIcon].showDetail = true
            CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
                DialogStack.PushPrefStact("ItemDetailFrame", {id = _itemCfg.id,type = _itemCfg.type,InItemBag=2}, self.view.gameObject.transform)
            end
            

            _obj.gameObject:SetActive(true)
        end
    end
end

function selectTaskItem:upItemInfo(cfg, value)
    self.view.selectTaskItemRoot.itemInfo.gameObject:SetActive(true)
    self.view.selectTaskItemRoot.itemInfo.iconNode.icon[UI.Image]:LoadSprite("icon/".. cfg.icon)
    self.view.selectTaskItemRoot.itemInfo.name[UI.Text].text = cfg.name
    self.view.selectTaskItemRoot.itemInfo.instructions[UI.Text].text = cfg.info
    self.view.selectTaskItemRoot.itemInfo.type.value[UI.Text].text = cfg.type_name
end

function selectTaskItem:initBtn()
    CS.UGUIClickEventListener.Get(self.view.selectTaskItemRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.selectTaskItemRoot.handIn.gameObject).onClick = function()
        if self.fun then
            for k,v in pairs(self.consumeTab) do
                if v.id ~= 0 and v.value ~= 0 then
                    if v.value > ItemModule.GetItemCount(v.id) then
                        showDlgError(nil, "物品数量不足")
                        return
                    end
                end
            end
            self.fun()
        else
            DialogStack.Pop()
        end
    end
end

return selectTaskItem
