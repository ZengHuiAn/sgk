local TipCfg = require "config.TipConfig"
local newUnionExplain = {}

function newUnionExplain:initData(data)
    self.name = ""
    self.info = ""
    if data then
        self.name = TipCfg.GetAssistDescConfig(data.infoId).tittle
        self.info = TipCfg.GetAssistDescConfig(data.infoId).info
    end
end

function newUnionExplain:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.view.root.bg.Text[UI.Text]:TextFormat(self.name)
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self.view.root.desc[UI.Text].text = self.info
end

function newUnionExplain:Start(data)
    self:initData(data)
    self:initUi()
end

function newUnionExplain:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return newUnionExplain
