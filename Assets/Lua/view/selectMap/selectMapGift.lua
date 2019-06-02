local rewardModule = require "module.RewardModule"
local ItemHelper=require"utils.ItemHelper"
local selectMapGift = {}

function selectMapGift:initData(data)
    self.gid = tonumber(data.chapterId)
    self.star = data.star or 0
    self.index = data.index or 1
    self.readyTab = {}
end

function selectMapGift:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initButton()
    self:initMiddle()
    self:upButton()
end

function selectMapGift:upButton()
    if #self.readyTab == 0 then
        self.view.selectMapGiftRoot.getAllGift[CS.UGUISelectorGroup]:setGray()
    else
        self.view.selectMapGiftRoot.getAllGift[CS.UGUISelectorGroup]:reset()
    end
end

function selectMapGift:initButton()
    CS.UGUIClickEventListener.Get(self.view.selectMapGiftRoot.bg.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.selectMapGiftRoot.getAllGift.gameObject).onClick = function()
        if #self.readyTab > 0 then
            for i,v in ipairs(self.readyTab) do
                self.view.selectMapGiftRoot.getAllGift[CS.UGUIClickEventListener].interactable = false
                self.view.selectMapGiftRoot.getAllGift[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                rewardModule.GatherSyn(v, function()
                    self.view.selectMapGiftRoot.getAllGift[CS.UGUIClickEventListener].interactable = true
                    self.view.selectMapGiftRoot.getAllGift[UI.Image].material = nil
                end)
            end
        else
            showDlgError(nil, SGK.Localize:getInstance():getValue("common_lingqu_03"))
        end
    end
end

function selectMapGift:initMiddle()
    self.scrollView = self.view.selectMapGiftRoot.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function ( obj, idx )
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = rewardModule.GetConfigByType(self.index, self.gid)[idx+1]

        local _scrollView = _view.ScrollView[CS.UIMultiScroller]
        _scrollView.RefreshIconCallback = function ( _obj, _idx )
            local _rewardView = CS.SGK.UIReference.Setup(_obj)
            local _rewardTab = _tab.reward[_idx+1]
            local icon = utils.IconFrameHelper.Create(_rewardView, {id = _rewardTab.id, type = _rewardTab.type, showDetail = true, count = _rewardTab.value})
            icon[UnityEngine.RectTransform].anchoredPosition = CS.UnityEngine.Vector2(0,0)
            _obj.gameObject:SetActive(true)
        end
        _scrollView.DataCount = #_tab.reward

        _view.getGiftText[UI.Text].text = SGK.Localize:getInstance():getValue("huiyilu_xingxingjl_04", _tab.condition_value)
        _view.getGift.Text[UI.Text].color = {r=0,g=0,b=0,a=1} 
        if rewardModule.Check(_tab.id) == rewardModule.STATUS.READY then
            table.insert(self.readyTab, _tab.id)
            _view.getGift:SetActive(true)
            _view.haved.gameObject:SetActive(false)
            --_view.unHave.gameObject:SetActive(false)
            self:upButton()
        else
            if rewardModule.Check(_tab.id) == rewardModule.STATUS.DONE then
                --_view.unHave[UI.Text].text = SGK.Localize:getInstance():getValue("huiyilu_xingxingjl_02")
                _view.haved.gameObject:SetActive(true)
                _view.getGift:SetActive(false)
            else
                --_view.unHave[UI.Text].text = SGK.Localize:getInstance():getValue("huiyilu_xingxingjl_03")
                _view.haved.gameObject:SetActive(false)
                _view.getGift:SetActive(true)
            end
            _view.getGift[CS.UGUISelectorGroup].index = 4
            --_view.unHave.gameObject:SetActive(true)
        end

        CS.UGUIClickEventListener.Get(_view.getGift.gameObject).onClick = function()
            if rewardModule.Check(_tab.id) == rewardModule.STATUS.READY then
                _view.getGift[CS.UGUIClickEventListener].interactable = false
                --_view.getGift[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                rewardModule.GatherSyn(_tab.id, function()
                    _view.getGift[CS.UGUIClickEventListener].interactable = true
                    _view.getGift[UI.Image].material = nil
                end)
            else
                if rewardModule.Check(_tab.id) == rewardModule.STATUS.DONE then
                    showDlgError(nil, SGK.Localize:getInstance():getValue("common_lingqu_02"))
                else
                    showDlgError(nil, SGK.Localize:getInstance():getValue("common_lingqu_03"))
                end
            end
        end

        obj.gameObject:SetActive(true)
    end
    table.sort(rewardModule.GetConfigByType(self.index, self.gid), function(a, b)
        local _a = tonumber(a.condition_value)
        local _b = tonumber(b.condition_value)
        return _a < _b
    end)
    self.scrollView.DataCount = #rewardModule.GetConfigByType(self.index, self.gid)
end

function selectMapGift:Start(data)
    self:initData(data)
    self:initUi()
    self:initGuide()
end

function selectMapGift:initGuide()
    module.guideModule.PlayByType(113,0.2)
end

function selectMapGift:listEvent()
    return {
        "ONE_TIME_REWARD_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
    }
end

function selectMapGift:onEvent(event, ...)
    if event == "ONE_TIME_REWARD_INFO_CHANGE" then
        self.readyTab = {}
        self.scrollView.DataCount = #rewardModule.GetConfigByType(self.index, self.gid)
        self:upButton()
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    end
end

return selectMapGift
