local unionModule = require "module.unionModule"
local heroModule = require "module.HeroModule"
local playerModule = require "module.playerModule"
local unionConfig = require "config.unionConfig"
local newUnionJoin = {}

function newUnionJoin:initData()
    self.Manage = unionModule.Manage
    self.unionMsg = unionModule.Manage:GetSelfUnion()
    self.fightingPid = {}
    self:upData()
end

function newUnionJoin:upData()
    self.applyLab = self.Manage:GetApply()
    self.onlineTab = {}
    self.offlineTab = {}
    self.allTab = {}
    for k,v in pairs(self.applyLab) do
        if v.online then
            table.insert(self.onlineTab, v)
        else
            table.insert(self.offlineTab, v)
        end
        table.insert(self.allTab, v)
    end
    self.tempTab = self.allTab
    self.mcount = #self.allTab
end

function newUnionJoin:initBottom()
    self.onlineNumber = self.view.root.bottom.online.number.number[UI.Text]
    self.onlineToggle = self.view.root.bottom.online.Toggle[UI.Toggle]
    CS.UGUIClickEventListener.Get(self.view.root.bottom.agreedApply.gameObject).onClick = function()
        if self.unionMsg.mcount >= (unionConfig.GetNumber(self.unionMsg.unionLevel).MaxNumber + self.unionMsg.memberBuyCount) then
            showDlgError(nil, "公会人数已满")
        else
            for k,v in pairs(self.applyLab) do
                unionModule.AgreedApply(v.pid)
            end
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.refusedApply.gameObject).onClick = function()
        for k,v in pairs(self.applyLab) do
            unionModule.CleanApply()
            return
        end
    end
    self.onlineToggle.onValueChanged:AddListener(function (value)
        self:upUi()
    end)
end

function newUnionJoin:initScrollView()
    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function ( obj, idx )
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.tempTab[idx+1]
        _view.name[UI.Text].text = _tab.name

        utils.IconFrameHelper.Create(_view.IconFrame, {pid = _tab.pid})
        -- if playerModule.IsDataExist(_tab.pid) then
        --     _view.newCharacterIcon[SGK.newCharacterIcon].icon = tostring(playerModule.IsDataExist(_tab.pid).head)
        -- else
        --     playerModule.Get(_tab.pid,(function( ... )
        --         _view.newCharacterIcon[SGK.newCharacterIcon].icon = tostring(playerModule.IsDataExist(_tab.pid).head)
        --     end))
        -- end
        -- _view.newCharacterIcon[SGK.newCharacterIcon].level = _tab.level
        --
        -- utils.PlayerInfoHelper.GetPlayerAddData(_tab.pid, 99, function (playerAddData)
        --     _view.newCharacterIcon[SGK.newCharacterIcon].headFrame = playerAddData.HeadFrame
        --     _view.newCharacterIcon[SGK.newCharacterIcon].sex = playerAddData.Sex
        -- end)

        if _tab.online then
            _view.onlie[UI.Text]:TextFormat("<color=#3BFFBC>在线</color>")
        else
            _view.onlie[UI.Text]:TextFormat("<color=#DE040E>离线</color>")
        end

        if playerModule.GetFightData(_tab.pid) then
            _view.fighting.Text[UI.Text].text = tostring(math.ceil(playerModule.GetFightData(_tab.pid).capacity))
        else
            self.fightingPid[_tab.pid] = idx
        end

        CS.UGUIClickEventListener.Get(_view.agreed.gameObject).onClick = function()
            if self.unionMsg.mcount >= (unionConfig.GetNumber(self.unionMsg.unionLevel).MaxNumber + self.unionMsg.memberBuyCount) then
                showDlgError(nil, "公会人数已满")
            else
                unionModule.AgreedApply(_tab.pid)
            end
        end
        CS.UGUIClickEventListener.Get(_view.refused.gameObject).onClick = function()
            unionModule.RefusedApply(_tab.pid)
        end
        obj:SetActive(true)
    end
end

function newUnionJoin:upFightingData(index)
    local _item = self.scrollView:GetItem(self.fightingPid[index])
    if _item then
        local _view = CS.SGK.UIReference.Setup(_item)
        _view.fighting.Text[UI.Text].text = tostring(math.ceil(playerModule.GetFightData(index).capacity))
    end
    self.fightingPid[index] = nil
end

function newUnionJoin:upScrollView()
    self.scrollView.DataCount = #self.tempTab
    self.view.root.nothing:SetActive(self.scrollView.DataCount == 0)
end

function newUnionJoin:upUi()
    self.onlineNumber.text = #self.onlineTab.."/"..self.mcount
    if self.onlineToggle.isOn then
        self.tempTab = self.onlineTab
    else
        self.tempTab = self.allTab
    end
    self:upScrollView()
end

function newUnionJoin:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.bg.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    self:initBottom()
    self:initScrollView()
    self:upUi()
end

function newUnionJoin:Start()
    self:initData()
    self:initUi()
end

function newUnionJoin:listEvent()
    return {
        "PLAYER_FIGHT_INFO_CHANGE",
        "LOCAL_CHANGE_APPLYLIST",
        "LOCAL_UNION_UPDATE_UI",
    }
end

function newUnionJoin:onEvent(event, data)
    if event == "PLAYER_FIGHT_INFO_CHANGE" then
        self:upFightingData(data)
    elseif event == "LOCAL_CHANGE_APPLYLIST" or event == "LOCAL_UNION_UPDATE_UI" then
        self:upData()
        self:upUi()
    end
end

return newUnionJoin
