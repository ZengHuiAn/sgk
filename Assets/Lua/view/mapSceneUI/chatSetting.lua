local chatSetting = {}

function chatSetting:Start()
    self:initData()
    self:initUi()
end

function chatSetting:initData()
    self.dialogTab = {
        {name = "mapSceneUI/item/channelSetting"},
        {name = "mapSceneUI/item/myMsgSetting"},
        {name = "mapSceneUI/item/blacklist"},
    }
end

function chatSetting:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.settingNode = self.view.chatSettingRoot.settingNode
    self.nowShowNode = "mapSceneUI/item/channelSetting"
    DialogStack.PushPref("mapSceneUI/item/channelSetting", nil, self.settingNode)
    self:initTopBtn()
end

function chatSetting:pushDialog(id)
    self.nowShowNode = DialogStack.GetPref_list(self.nowShowNode)
    if self.nowShowNode then
        UnityEngine.GameObject.Destroy(self.nowShowNode)
    end
    if self.dialogTab[id] and self.dialogTab[id].name then
        self.nowShowNode = self.dialogTab[id].name
        DialogStack.PushPref(self.dialogTab[id].name, nil, self.settingNode)
    end
    for i = 1, #self.view.chatSettingRoot.topBtn do
        local _view = self.view.chatSettingRoot.topBtn[i]
        if i == id then
            _view[UI.Image].color = {r = 1, g = 185/255, b = 0, a = 1}
        else
            _view[UI.Image].color = {r = 52/255, g = 31/255, b = 0, a = 1}
        end
    end
end

function chatSetting:initTopBtn()
    CS.UGUIClickEventListener.Get(self.view.chatSettingRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.chatSettingRoot.topBtn.channelSetting.gameObject).onClick = function()
        print("频道设置")
        self:pushDialog(1)
    end
    CS.UGUIClickEventListener.Get(self.view.chatSettingRoot.topBtn.message.gameObject).onClick = function()
        print("我的消息")
        self:pushDialog(2)
    end
    CS.UGUIClickEventListener.Get(self.view.chatSettingRoot.topBtn.blacklist.gameObject).onClick = function()
        print("屏蔽列表")
        self:pushDialog(3)
    end
end

return chatSetting