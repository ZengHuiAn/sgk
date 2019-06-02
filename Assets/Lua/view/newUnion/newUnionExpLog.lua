local unionModule = require "module.unionModule"
local unionConfig = require "config.unionConfig"
local newUnionExpLog = {}

function newUnionExpLog:initData()

end

function newUnionExpLog:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self:initScrollView()
end

function newUnionExpLog:initScrollView()
    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = unionModule.Manage:GetExpLog(idx+1)
        if _tab.type ~= 0 then
            local _typeTab = unionConfig.GetDonate(_tab.type)
            _view.Text[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_touzi_04", _tab.name, _typeTab.Name, _typeTab.Value, _typeTab.BuildExp)
        else
            _view.Text[UI.Text].text = SGK.Localize:getInstance():getValue("<color=#69F84EFF>{0}</color> 给公会贡献了<color=#00B0F0>{1}</color>建设经验", _tab.name, _tab.number)
        end
        obj:SetActive(true)
    end
    self.scrollView.DataCount = #unionModule.Manage:GetExpLog()
end

function newUnionExpLog:Start()
    self:initData()
    self:initUi()
end

function newUnionExpLog:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return newUnionExpLog
