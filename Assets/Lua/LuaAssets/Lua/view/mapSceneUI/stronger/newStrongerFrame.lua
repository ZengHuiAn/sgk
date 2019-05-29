local strongerModule = require "module.strongerModule"
local newStrongerFrame = {}

local childCfg = {
    [1] = {name = "mapSceneUI/stronger/newStrongerUp"},
    [2] = {name = "mapSceneUI/stronger/newStrongerResources"}
}

function newStrongerFrame:initData()
    self.loadLock = false
    self.childeList = {}
end

function newStrongerFrame:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.bg.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self:initBottom()
end

function newStrongerFrame:showChilde(i)
    if childCfg[i] and not self.loadLock then
        if self.childeList[i] then
            for k,v in pairs(self.childeList) do
                self.childeList[k]:SetActive(k == i)
            end
        else
            self.loadLock = true
            DialogStack.PushPref(childCfg[i].name, {}, self.view.root.childNode.transform, function(obj)
                self.loadLock = false
                self.childeList[i] = obj
                for k,v in pairs(self.childeList) do
                    self.childeList[k]:SetActive(k == i)
                end
            end)
        end
    end
end

function newStrongerFrame:initBottom()
    for i = 1, #self.view.root.bottom.group-1 do
        local _view = self.view.root.bottom.group[i+1]
        _view[UI.Toggle].onValueChanged:RemoveAllListeners()
        _view[UI.Toggle].onValueChanged:AddListener(function(value)
            self.savedValues.idx = i
            _view.arr:SetActive(value)
        end)
        CS.UGUIClickEventListener.Get(_view.gameObject,true).onClick = function()
            self:showChilde(i)
        end
    end
    self.view.root.bottom.group[(self.savedValues.idx or 1)+1][UI.Toggle].isOn = true
    self:showChilde(self.savedValues.idx or 1)
end

function newStrongerFrame:Start()
    self:initData()
    self:initUi()
end

function newStrongerFrame:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
    strongerModule.StrongerUpArg = {}
	return true;
end

return newStrongerFrame
