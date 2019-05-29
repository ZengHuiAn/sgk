local FriendModule = require "module.FriendModule"
local playerModule = require "module.playerModule"
local NetworkService = require "utils.NetworkService"

local blacklist = {}

function blacklist:Start()
    self:initData()
    self:initUi()
end

function blacklist:initData()
    self.blacklistTab = FriendModule.GetManager(2)
end

function blacklist:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initScrollView()
end

function blacklist:initScrollView()
    self.scrollView = self.view.blacklistRoot.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function ( obj, idx )
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.blacklistTab[idx + 1]
        _view.info.gameObject:SetActive(not (idx == #self.blacklistTab))
        _view.add.gameObject:SetActive(idx == #self.blacklistTab)

        if _tab then
            _view.info.name[UI.Text].text = _tab.name
            _view.info.id[UI.Text].text = tostring(math.ceil(_tab.pid))
            if playerModule.IsDataExist(_tab.pid) then
                local head = playerModule.IsDataExist(_tab.pid).head ~= 0 and playerModule.IsDataExist(_tab.pid).head or 11001
                _view.info.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..head)
            else
                playerModule.Get(_tab.pid,(function( ... )
                    local head = playerModule.IsDataExist(_tab.pid).head ~= 0 and playerModule.IsDataExist(_tab.pid).head or 11001
                    _view.info.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..head)
                end))
            end

            CS.UGUIClickEventListener.Get(_view.info.remove.gameObject).onClick = function()
                NetworkService.Send(5013,{nil, 1, _tab.pid})
            end
        else
            CS.UGUIClickEventListener.Get(_view.add.addButton.gameObject).onClick = function()
                DialogStack.PushPrefStact("mapSceneUI/item/addBlackList", nil, self.view.blacklistRoot)
            end
        end

        obj.gameObject:SetActive(true)
    end
    self.scrollView.DataCount = #self.blacklistTab + 1
end

function blacklist:listEvent()
    return {
        "Friend_INFO_CHANGE"
    }
end

function blacklist:onEvent(event,data)
    if event == "Friend_INFO_CHANGE" then
        self.blacklistTab = FriendModule.GetManager(2)
        self.scrollView.DataCount = #self.blacklistTab + 1
    end
end


return blacklist