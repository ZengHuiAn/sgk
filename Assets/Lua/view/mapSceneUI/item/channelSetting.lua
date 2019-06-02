local channelSetting = {}

function channelSetting:Start()
    self:initData()
    self:initUi()
end

function channelSetting:initData()
    self.channelMesg = {
        {id = 1, text = "世界频道"},
        {id = 2, text = "XX频道"},
        {id = 3, text = "公会频道"},
        {id = 4, text = "好友频道"},
        {id = 5, text = "小队频道"},
        {id = 6, text = "XX频道"},
        {id = 7, text = "组队频道仅显示与我等级相符的信息"}
    }
end

function channelSetting:initChannelAllBtn()
    self.allBtn = self.view.channelSettingRoot.allBtn
    for i = 1, #self.allBtn do
        local _view = self.allBtn[i]
        _view.Label[UI.Text]:TextFormat(self.channelMesg[i].text)
        _view[UI.Toggle].onValueChanged:AddListener(function()
            print(_view[UI.Toggle].isOn, self.channelMesg[i].id)
        end)
    end
end

function channelSetting:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initChannelAllBtn()
end

return channelSetting