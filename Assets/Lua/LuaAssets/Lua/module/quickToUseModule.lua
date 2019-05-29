local itemList = {}
local ItemHelper = require "utils.ItemHelper"
local EventManager = require 'utils.EventManager'

local index = 1
local itemListHs = {}
local function addItem(gid)
    if not itemListHs[gid] then
        local _temp = {}
        _temp.gid = gid
        _temp.index = index
        table.insert(itemList, _temp)
        index = index + 1
        itemListHs[gid] = {}
        DispatchEvent("LOCLA_QUICKTOSUE_CHANE")
    end
end

local function removeItem(gid, data)
    local i = 1
    while i <= #itemList do
        if itemList[i].gid == gid then
            table.remove(itemList, i)
            if not data then
                return #itemList
            end
        else
            i = i + 1
        end
    end
    itemListHs[gid] = nil
    return #itemList
end

local function Clear()
    itemListHs = {}
    itemList = {}
end

local function getList()
    table.sort(itemList, function(a, b)
        return a.index > b.index
    end)
    table.sort(itemList, function(a, b)
        return a.gid > b.gid
    end)
    return itemList
end

EventManager.getInstance():addListener("ITEM_INFO_CHANGE", function(event, data)
    if data then
        local _item = ItemHelper.Get(ItemHelper.TYPE.ITEM, data.gid)
        if _item and _item.type_Cfg.quick_use and _item.type_Cfg.quick_use ~= 0 then
            --for i = 1, data.count do
            addItem(data.gid)
            --end
        end
    end
end)

return {
    Get = getList,
    RemoveItem = removeItem,
    Clear = Clear,
}
