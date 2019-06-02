local ItemHelper = require "utils.ItemHelper"
local quickToUseModule = require "module.quickToUseModule"
local quickToUse = {}

function quickToUse:Start(data)
    self:initData(data)
    self:initUi()
end

function quickToUse:initData(data)
    if not data then
        data = {}
    end
    self.id = data.id
    self.type = data.type
    self.func = data.func
    self.effectName = data.effectName
    self.effTime = data.effTime
    self.showType = data.showType
    self.textName = data.play_text
    self.effectIcon = data.play_icon
    self.btnName = data.btnName
end

function quickToUse:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initCloseBtn()
    self:initUseBtn()
    self:initItem()

    self.view.quickToUseRoot.bg.Text[UI.Text].text = self._cfg.type_Cfg.name
    if self._cfg.type_Cfg.quick_use == 1 or self._cfg.type_Cfg.quick_use == 4 then
        self.view.quickToUseRoot.btnMask.useBtn.Text[UI.Text]:TextFormat("打开")
    else
        self.view.quickToUseRoot.btnMask.useBtn.Text[UI.Text]:TextFormat("使用")
    end
    if self.btnName then
        self.view.quickToUseRoot.btnMask.useBtn.Text[UI.Text].text = self.btnName
    end
end

function quickToUse:initCloseBtn()
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        if quickToUseModule.RemoveItem(self.id, {colseAll = true}) <= 0 then
            UnityEngine.GameObject.Destroy(self.gameObject)
        else
            for k,v in pairs(quickToUseModule.Get()) do
                self:initData({type = ItemHelper.TYPE.ITEM, id = v.gid})
                self:initUi()
                return
            end
        end
    end
    CS.UGUIClickEventListener.Get(self.view.quickToUseRoot.closeBtn.gameObject).onClick = function()
        if quickToUseModule.RemoveItem(self.id, {colseAll = true}) <= 0 then
            UnityEngine.GameObject.Destroy(self.gameObject)
        else
            for k,v in pairs(quickToUseModule.Get()) do
                self:initData({type = ItemHelper.TYPE.ITEM, id = v.gid})
                self:initUi()
                return
            end
        end
    end
end

function quickToUse:initUseBtn()
    CS.UGUIClickEventListener.Get(self.view.quickToUseRoot.btnMask.useBtn.gameObject).onClick = function()
        if self.func and type(self.func) == "function" then
            if self.effectName then
                if self.textName and self.effectIcon then
                    local _item = SGK.ResourcesManager.Load("prefabs/effect/UI/"..self.effectName..".prefab")
                    local _obj = CS.UnityEngine.GameObject.Instantiate(_item, UnityEngine.GameObject.FindWithTag("UITopRoot").transform)
                    local _view = CS.SGK.UIReference.Setup(_obj)

                    _view.fx_woring_ui_1.gzz_ani.text_working[UI.Text].text = self.textName
        			_view.fx_woring_ui_1.gzz_ani.icon_working[UI.Image]:LoadSprite("icon/" .. self.effectIcon)

                    CS.UnityEngine.GameObject.Destroy(_obj, self.effTime)
                end
                StartCoroutine(function()
                    WaitForSeconds(self.effTime or 1)
                    self.func()
                end)
            end
        else
            if self._cfg.type_Cfg.quick_use == 1 then   --宝箱
                if ItemHelper.IsCanOpen(ItemHelper.TYPE.ITEM, self.id) then
                    ItemHelper.OpenGiftBag(ItemHelper.TYPE.ITEM, self.id)
                else
                    local _giftCfg = module.ItemModule.GetGiftBagConfig(self.id).consume
                    if _giftCfg and _giftCfg[2] and _giftCfg[2].id then
                        DialogStack.PushPref("easyBuyFrame", {id = _giftCfg[2].id, type = ItemHelper.TYPE.ITEM, shop_id = 1}, UnityEngine.GameObject.FindWithTag("UITopRoot"))
                        return
                    end
                end
            elseif self._cfg.type_Cfg.quick_use == 2 then   --任务
                local _questItemUUId = module.ItemModule.GetQuestItemUUId(self.id)
                if _questItemUUId then
                    local _quest = module.QuestModule.Get(_questItemUUId)
                    if _quest then
                        StartCoroutine(function()
                            WaitForSeconds(2)
                            utils.EventManager.getInstance():dispatch("LoadPlayerStateEffect")
                        end)
                        utils.EventManager.getInstance():dispatch("LoadPlayerStateEffect", _quest.play_effect_name)
                    end
                end
            elseif self._cfg.type_Cfg.quick_use == 3 then
                self.QuestId = utils.ItemHelper.GetItemQuest(self.type,self.id)
                if self.QuestId then
                    module.QuestModule.Accept(self.QuestId)
                end
            elseif self._cfg.type_Cfg.quick_use == 4 then
                local exchangeTab = module.ShopModule.GetExchangeItemList(self.id)
                if exchangeTab and next(exchangeTab) then
                    DialogStack.PushPref("exchangeContentFrame", {id=self.id,type=self.type}, UnityEngine.GameObject.FindWithTag("UITopRoot"))
                else
                    ERROR_LOG("exchangeTab is nil or {} id",self.id)
                end
            end
        end

        if quickToUseModule.RemoveItem(self.id) <= 0 then
            UnityEngine.GameObject.Destroy(self.gameObject)
        else
            for k,v in pairs(quickToUseModule.Get()) do
                self:initData({type = ItemHelper.TYPE.ITEM, id = v.gid})
                self:initUi()
                return
            end
        end
    end
end

function quickToUse:initItem()
    if self.id and self.type then
        self._cfg = ItemHelper.Get(self.type, self.id)
        utils.IconFrameHelper.Create(self.view.quickToUseRoot.newItemIcon, {id = self._cfg.id, type = self._cfg.type, showName = true,showDetail = true})
        --self.view.quickToUseRoot.newItemIcon[SGK.newItemIcon]:SetInfo(self._cfg)
        --self.view.quickToUseRoot.name[UI.Text].text = self._cfg.name
        -- CS.UGUIClickEventListener.Get(self.view.quickToUseRoot.newItemIcon.gameObject).onClick = function()
        --     DialogStack.PushPrefStact("ItemDetailFrame", {id = self._cfg.id,type = self._cfg.type}, self.view.gameObject.transform)
        -- end
    else
        self.view.quickToUseRoot.newItemIcon.gameObject:SetActive(false)
        self.view.quickToUseRoot.name.gameObject:SetActive(false)
        ERROR_LOG("quickToUse id type", self.id, self.type)
    end
end

-- function quickToUse:OnDestroy()
--     SGK.Action.DelayTime.Create(0.5):OnComplete(function()
--         DispatchEvent("LOCLA_QUICKTOSUE_CHANE")
--     end)
-- end

function quickToUse:listEvent()
    return {
        "ITEM_INFO_CHANGE",
        "GUIDE_DIALOG_START",
    }
end

function quickToUse:onEvent(event, data)
    if event == "ITEM_INFO_CHANGE" then
        self:initItem()
    elseif event == "GUIDE_DIALOG_START" then
        quickToUseModule.Clear()
        UnityEngine.GameObject.Destroy(self.gameObject)
    end
end

return quickToUse
