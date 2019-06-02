local strongerModule = require "module.strongerModule"
local newStrongerResources = {}

function newStrongerResources:Start()
    self:initData()
    self:initUi()
end

function newStrongerResources:initData()
    self.idx = 1
end

function newStrongerResources:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initLeft()
    self:initRight()
end

function newStrongerResources:initRight()
    self.view.right.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = strongerModule.GetResource(self.idx)[idx + 1]
        _view.icon[UI.Image]:LoadSprite("guideLayer/".._cfg.icon)
        _view.name[UI.Text].text = _cfg.name
        _view.desc[UI.Text].text = _cfg.desc
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            utils.GuideHelper.Go(_cfg.guide,_cfg.guideValue)
            -- local env = setmetatable({
            --     EnterMap = module.EncounterFightModule.GUIDE.EnterMap,
            --     Interact = module.EncounterFightModule.GUIDE.Interact,
            --     GetCurrentMapName = module.EncounterFightModule.GUIDE.GetCurrentMapName,
            --     GetCurrentMapID = module.EncounterFightModule.GUIDE.GetCurrentMapID,
            -- }, {__index=_G})
            -- local _luaFunc = loadfile("guide/".._cfg.guide..".lua", "bt", env)
            -- if _luaFunc then
            --     _luaFunc({cfg = _cfg}) 
            -- end
        end
        obj:SetActive(true)
    end
    self.view.right.ScrollView[CS.UIMultiScroller].DataCount = #strongerModule.GetResource(self.idx)
end

function newStrongerResources:upRight()
    self.view.right.ScrollView[CS.UIMultiScroller].DataCount = #(strongerModule.GetResource(self.idx) or {})
end

function newStrongerResources:initLeft()
    self.view.left.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = strongerModule.GetResourceTitle()[idx + 1]
        _view.Toggle.icon[UI.Image]:LoadSprite("icon/".._cfg.title_icon)
        _view.Toggle.name[UI.Text].text = _cfg.title_name
        CS.UGUIClickEventListener.Get(_view.Toggle.gameObject).onClick = function()
            self.idx = _cfg.title
            self:upRight()
        end
        obj:SetActive(true)
    end
    self.view.left.ScrollView[CS.UIMultiScroller].DataCount = #strongerModule.GetResourceTitle()
    local _obj = self.view.left.ScrollView[CS.UIMultiScroller]:GetItem(0)
    if _obj then
        local _view = CS.SGK.UIReference.Setup(_obj.gameObject)
        _view.Toggle[UI.Toggle].isOn = true
    end
end

return newStrongerResources
