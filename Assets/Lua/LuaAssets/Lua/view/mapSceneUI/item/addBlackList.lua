local playerModule = require "module.playerModule"
local NetworkService = require "utils.NetworkService"

local addBlackList = {}

function addBlackList:Start()
    self:initData()
    self:initUi()
end

function addBlackList:initData()
    self.playerTab = {}
end

function addBlackList:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initBtn()
    self:initScrollView()
end

function addBlackList:initScrollView()
    self.scrollView = self.view.addBlackListRoot.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function ( obj, idx )
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.playerTab[idx + 1]
        _view.info.name[UI.Text].text = _tab.name
        _view.info.id[UI.Text].text = tostring(math.ceil(_tab.id))
        local head = _tab.head ~= 0 and _tab.head or 11001
        _view.info.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..head)

        CS.UGUIClickEventListener.Get(_view.info.remove.gameObject).onClick = function()
            NetworkService.Send(5013,{nil, 2, _tab.id})
            self.playerTab = {}
            self.scrollView.DataCount = #self.playerTab
        end

        obj.gameObject:SetActive(true)
    end
    self.scrollView.DataCount = #self.playerTab
end

function addBlackList:upList(cfg)
    self.playerTab = {}
    table.insert(self.playerTab, cfg)
    self.scrollView.DataCount = #self.playerTab
end

function addBlackList:initBtn()
    self.inputField = self.view.addBlackListRoot.InputField[UI.InputField]
    CS.UGUIClickEventListener.Get(self.view.addBlackListRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.addBlackListRoot.find.gameObject).onClick = function()
        if self.inputField.text == "" then
            showDlgError(nil, "请输入要查找的玩家ID")
            return
        end
        local _id = tonumber(self.inputField.text)
        if playerModule.Get(_id, function() self:upList(playerModule.Get(_id)) end) then
            self:upList(playerModule.Get(_id))
        end
    end
end

function addBlackList:listEvent()
    return {
        "QUERY_PLAYER_FAILED",
    }
end

function addBlackList:onEvent(event, data)
    if event == "QUERY_PLAYER_FAILED" then
        showDlgError(nil, "没有找到该用户")
    end
end

return addBlackList