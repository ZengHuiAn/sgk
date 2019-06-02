local unionConfig = require "config.unionConfig"
local unionModule = require "module.unionModule"
local activityModule = require "module.unionActivityModule"
local ItemModule=require"module.ItemModule"
local ItemHelper = require "utils.ItemHelper"
local unionGiftBox = {}

function unionGiftBox:Start(data)
    self:initData(data)
    self:initUi()
end

function unionGiftBox:initData(data)
    self.Manage = activityModule.ExploreManage
    self.type = 1
    self.index = 1
    if data then
        self.type = data.type
        self.index = data.index
    end
    self.giftItemTab = nil
    self.cfg = unionConfig.GetTeamAward(self.index, unionModule.Manage:GetSelfUnion().unionLevel)
end

function unionGiftBox:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTopName()
    self:initScrollView()
    self:initBtn()
    self:initBottom()
    self:upBottom()
    if self.type == 1 then
        ItemModule.GetGiftItem(self.cfg.product_id, function(data)
            self:upScrollView(data)
        end)
        for i = 2, 3 do
            if self.cfg["product_id"..i] ~= 0 then
                ItemModule.GetGiftItem(self.cfg["product_id"..i], function(data)
                    self:upScrollView(data)
                end)
            end
        end
    else
        self:upScrollView(self.Manage:GetMapInfo(self.index).giftBox)
    end
    self:upBtnUi()
end

function unionGiftBox:initTopName()
    self.titleName = self.view.unionGiftBoxRoot.bg.name[UI.Text]
    if self.type == 1 then
        self.titleName.text = SGK.Localize:getInstance():getValue("juntuan_touzi_01")
    elseif self.type == 2 then
        self.titleName.text = SGK.Localize:getInstance():getValue("juntuan_tanxian_01")
    end
end

function unionGiftBox:initScrollView()
    self.scrollView = self.view.unionGiftBoxRoot.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function ( obj, idx )
        local _view = CS.SGK.UIReference.Setup(obj)
        if not self.giftItemTab then return end
        local _tab = self.giftItemTab[idx+1]
        if not _tab then return end
        utils.IconFrameHelper.Create(_view.IconFrame, {id = _tab[2], type = _tab[1], count = _tab[3], showDetail = true})
        obj.gameObject:SetActive(true)
    end
end

function unionGiftBox:upScrollView(data)
    if not self.giftItemTab then
        self.giftItemTab = {}
    end
    for i,v in ipairs(data) do
        table.insert(self.giftItemTab, v)
    end
    if self.giftItemTab then
        self.scrollView.DataCount = #self.giftItemTab
    end
end

function unionGiftBox:initBottom()
    self.expText = self.view.unionGiftBoxRoot.Text[UI.Text]
end

function unionGiftBox:upBottom()
    if self.type == 1 then
        self.expText.text = SGK.Localize:getInstance():getValue("juntuan_touzi_03", self.cfg.condition_value, unionModule.Manage:GetSelfUnion().todayAddExp)
    elseif self.type == 2 then
        self.view.unionGiftBoxRoot.getBtn.gameObject:SetActive(false)
        self.expText.text = SGK.Localize:getInstance():getValue("juntuan_tanxian_02")
    end
end

function unionGiftBox:upBtnUi()
    if self.type == 1 then
        if self.cfg.condition_value <= unionModule.Manage:GetSelfUnion().todayAddExp then
            self.view.unionGiftBoxRoot.getBtn[CS.UGUISelectorGroup]:reset()
        else
            self.view.unionGiftBoxRoot.getBtn[CS.UGUISelectorGroup]:setGray()
        end
    end
end

function unionGiftBox:initBtn()
    CS.UGUIClickEventListener.Get(self.view.unionGiftBoxRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.unionGiftBoxRoot.getBtn.gameObject).onClick = function()
        ---领取
        if self.type == 1 then
            if self.cfg.condition_value <= unionModule.Manage:GetSelfUnion().todayAddExp then
                self.view.unionGiftBoxRoot.getBtn[CS.UGUIClickEventListener].interactable = false
                self.view.unionGiftBoxRoot.getBtn[CS.UGUISelectorGroup]:setGray()
                unionModule.ConstructionReward(self.index, function()
                    self.view.unionGiftBoxRoot.getBtn[CS.UGUISelectorGroup]:reset()
                    self.view.unionGiftBoxRoot.getBtn[CS.UGUIClickEventListener].interactable = true
                end)
            else
                showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_touzi_02"))
            end
        elseif self.type == 2 then

        end
    end
end

function unionGiftBox:listEvent()
    return {
        "LOCAL_UNION_REWARD_OK",
    }
end

function unionGiftBox:onEvent(event, ...)
    if event == "LOCAL_UNION_REWARD_OK" then
        DispatchEvent("LOCAL_UNION_REWARD_GET", {typeId = self.type, index = self.index})
        DialogStack.Pop()
    end
end

function unionGiftBox:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return unionGiftBox
