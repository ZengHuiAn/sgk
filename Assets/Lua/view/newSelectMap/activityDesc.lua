local CemeteryConf = require "config.cemeteryConfig"
local activityDesc = {}

function activityDesc:Start(data)
    self:initData(data)
    self:initUi()
end

function activityDesc:initData(data)
    self.cemeteryCfg = CemeteryConf.Getteam_battle_conf(data.gid)
end

function activityDesc:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initActivityDesc()
end

function activityDesc:initActivityDesc()
    CS.UGUIClickEventListener.Get(self.view.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self.view.name[UI.Text].text = self.cemeteryCfg.story_title
    self.view.ScrollView.Viewport.Content.info[UI.Text].text = SGK.Localize:getInstance():getValue(self.cemeteryCfg.story)
end

return activityDesc
