local ChatManager = require 'module.ChatModule'
local playerModule = require "module.playerModule"

local myMsgSetting = {}

function myMsgSetting:Start()
    self:initData()
    self:initUi()
end

function myMsgSetting:initData()

end

function myMsgSetting:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.view.myMsgSettingRoot.notMsg:SetActive(not (#ChatManager.GetAtMyMsg() > 0))
    self.view.myMsgSettingRoot.haveMsg:SetActive(#ChatManager.GetAtMyMsg() > 0)
    self:initScrollView()
end

function myMsgSetting:initScrollView()
    self.scrollView = self.view.myMsgSettingRoot.haveMsg.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function ( obj, idx )
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = ChatManager.GetAtMyMsg()[#ChatManager.GetAtMyMsg() - idx]

        _view.msg[UI.Text].text = _tab.message
        _view.name[UI.Text].text = _tab.fromname

        if playerModule.IsDataExist(_tab.fromid) then
            local head = playerModule.IsDataExist(_tab.fromid).head ~= 0 and playerModule.IsDataExist(_tab.fromid).head or 11001
            _view.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..head)
        else
            playerModule.Get(_tab.fromid,(function( ... )
                local head = playerModule.IsDataExist(_tab.fromid).head ~= 0 and playerModule.IsDataExist(_tab.fromid).head or 11001
                _view.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..head)
            end))
        end

        obj.gameObject:SetActive(true)
    end
    self.scrollView.DataCount = #ChatManager.GetAtMyMsg()
end

function myMsgSetting:listEvent()
    return {
        "Chat_ATMYMSG_CHANGE",
    }
end

function myMsgSetting:onEvent(event, data)
    if event == "Chat_ATMYMSG_CHANGE" then
        self.scrollView.DataCount = #ChatManager.GetAtMyMsg()
    end
end

return myMsgSetting