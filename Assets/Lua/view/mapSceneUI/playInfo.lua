local playerModule = require "module.playerModule"
local heroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule=require"module.ItemModule"

local playInfo = {}

function playInfo:Start()
    self:initData()
    self:initUi()
end

function playInfo:initData()
    self.showSource = playerModule.GetShowSource()
    self.sourceTab = {}
end

function playInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:upTop()
    self:initBottom()
    self:upBottom()
end

function playInfo:initTop()
    self.icon = self.view.playInfoRoot.top.icon[UI.Image]
    self.name = self.view.playInfoRoot.top.name[UI.Text]
    self.id = self.view.playInfoRoot.top.id.value[UI.Text]
    self.level = self.view.playInfoRoot.top.Slider.level[UI.Text]
    CS.UGUIClickEventListener.Get(self.view.playInfoRoot.top.changeIcon.gameObject).onClick = function()
        DialogStack.PushPrefStact("mapSceneUI/changeIcon", nil, UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
    end
    CS.UGUIClickEventListener.Get(self.view.playInfoRoot.top.changeName.gameObject).onClick = function()
        DialogStack.PushPrefStact("mapSceneUI/changeName", nil, UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
    end

    CS.UGUIClickEventListener.Get(self.view.playInfoRoot.top.vip.gameObject, true).onClick = function()
        DialogStack.Push("SubmitForm")
    end
end

function playInfo:upTop()
    local hero = heroModule.GetManager():Get(11000)
    local cfg = heroModule.GetConfig(playerModule.Get().head) or {icon = "11001"}
    self.icon:LoadSprite("icon/".. cfg.icon)
    self.name.text = playerModule.Get().name
    self.level:TextFormat("Lv{0}", hero.level)
    self.id.text = tostring(playerModule.GetSelfID())
end

function playInfo:initBottom()
    local _prefab = self.view.playInfoRoot.bottom.itemNode.item.gameObject
    for i,v in ipairs(self.showSource) do
        local _item = CS.UnityEngine.GameObject.Instantiate(_prefab, self.view.playInfoRoot.bottom.itemNode.gameObject.transform)
        _item.gameObject:SetActive(true)
        self.sourceTab[i] = {item = _item, id = v.id, typeId = v.typeId}
    end
end

function playInfo:upBottom()
    for k,v in pairs(self.sourceTab) do
        local _itemCfg = ItemHelper.Get(v.typeId, v.id)
        local _view = CS.SGK.UIReference.Setup(v.item)
        _view.icon[UI.Image]:LoadSprite("icon/".. _itemCfg.icon)
        _view.number[UI.Text].text = tostring(ItemModule.GetItemCount(v.id) or 0)
    end
end

function playInfo:listEvent()
    return {
        "PLAYER_INFO_CHANGE",
        "ITEM_INFO_CHANGE",
    }
end

function playInfo:onEvent(event, ...)
    if event == "PLAYER_INFO_CHANGE" then
        self:upTop()
    elseif event == "ITEM_INFO_CHANGE" then
        self:upBottom()
    end
end

return playInfo