local quickToUseMax = {}

function quickToUseMax:Start(data)
    self:initData(data)
    self:initUi()
end

function quickToUseMax:initData(data)
    self.id = data.id
    self.type = data.type

    self.item=utils.ItemHelper.Get(self.type, self.id)
end

function quickToUseMax:closeUi()
    if module.quickToUseModule.RemoveItem(self.id, {colseAll = true}) <= 0 then
        UnityEngine.GameObject.Destroy(self.gameObject)
    else
        for k,v in pairs(module.quickToUseModule.Get()) do
            self:initData({type = utils.ItemHelper.TYPE.ITEM, id = v.gid})
            self:initUi()
            return
        end
    end
end

function quickToUseMax:initUi()
    self.root = CS.SGK.UIReference.Setup(self.gameObject)
    self.view = self.root.root.view

    self.view.bottom.maxBtn:SetActive(module.ItemModule.GetItemCount(self.id)>1)
    CS.UGUIClickEventListener.Get(self.root.mask.gameObject, true).onClick = function()
        self:closeUi()
    end
    CS.UGUIClickEventListener.Get(self.view.bottom.closeBtn.gameObject).onClick = function()
        self:closeUi()
    end
    self:initBtn()
    self:upUi()
end

function quickToUseMax:upUi()
    local _item = utils.ItemHelper.Get(self.type, self.id)
    utils.IconFrameHelper.Create(self.view.top.IconFrame,{id = self.id, type = self.type, showDetail = true, showName = true})
    self.maxCount = module.ItemModule.GetItemCount(self.id)
    self.count = 1
    self.view.bottom.numSelect.number[UI.Text].text = tostring(self.count)
    self.view.top.name[UI.Text].text = _item.name
end

function quickToUseMax:initBtn()
    CS.UGUIClickEventListener.Get(self.view.bottom.numSelect.addBtn.gameObject).onClick = function()
        if self.maxCount > self.count and self.count < 99 then
            self.count = self.count + 1
        end
        self.view.bottom.numSelect.number[UI.Text].text = tostring(self.count)
    end

    CS.UGUIClickEventListener.Get(self.view.bottom.numSelect.subBtn.gameObject).onClick = function()
        if 1 < self.count then
            self.count = self.count - 1
        end
        self.view.bottom.numSelect.number[UI.Text].text = tostring(self.count)
    end
    local _count = module.ItemModule.GetItemCount(self.id)
    if _count >= 99 then
        _count = 99
    end
    self.view.bottom.maxBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("tips_kuaisu_shiyong_2", _count)
    CS.UGUIClickEventListener.Get(self.view.bottom.maxBtn.gameObject).onClick = function()
        self.count = module.ItemModule.GetItemCount(self.id)
        if self.count >= 99 then
            self.count = 99
        end
        self.view.bottom.numSelect.number[UI.Text].text = tostring(self.count)
        self:OnClickOpenBtn()
    end

    self.view.bottom.openBtn.Text[UI.Text].text=self.item.type_Cfg.quick_use == 1 and "打开" or "使用"
    CS.UGUIClickEventListener.Get(self.view.bottom.openBtn.gameObject).onClick = function()
        self:OnClickOpenBtn()
    end
end

function quickToUseMax:OnClickOpenBtn()
	if self.item.type_Cfg.quick_use == 1 then
        if utils.ItemHelper.IsCanOpen(self.type, self.id, self.count) then
            utils.ItemHelper.OpenGiftBag(self.type, self.id, self.count)
        else
            local _giftCfg = module.ItemModule.GetGiftBagConfig(self.id).consume
            if _giftCfg and _giftCfg[2] and _giftCfg[2].id then
                DialogStack.PushPref("easyBuyFrame", {id = _giftCfg[2].id, type = utils.ItemHelper.TYPE.ITEM, shop_id = 1}, UnityEngine.GameObject.FindWithTag("UITopRoot"))
                return
            end
        end
    elseif self.item.type_Cfg.quick_use == 3 then
    	if self.count ==1 then
	    	self.QuestId=utils.ItemHelper.GetItemQuest(self.type,self.id)
	    	if self.QuestId then
				module.QuestModule.Accept(self.QuestId)
			else
				self:closeUi()
			end
		elseif self.count>1 then
			showDlgError(nil,"不能一次使用多个物品")
		else
			self:closeUi()
		end
    else
    	ERROR_LOG("未知操作类型：",self.item.type_Cfg.quick_use);
    end
end

function quickToUseMax:OnEnable()
    if module.ItemModule.GetItemCount(self.id) <= 0 then
        self:closeUi()
    else
        self:upUi()
    end
end

function quickToUseMax:listEvent()
    return {
        "GET_GIFT_ITEM",
        "QUEST_INFO_CHANGE",
        "GUIDE_DIALOG_START",

    }
end

function quickToUseMax:onEvent(event, data)
    if event == "GET_GIFT_ITEM" then
        module.quickToUseModule.RemoveItem(self.id, {colseAll = true})
        self:closeUi()
    elseif event =="QUEST_INFO_CHANGE" then
		if module.QuestModule.Get(self.QuestId) then
			if module.QuestModule.Get(self.QuestId).status==0 then
				self:closeUi()
				showDlgError(nil,string.format("领取任务%s",module.QuestModule.GetCfg(self.QuestId).name))
			end
		end
    elseif event =="GUIDE_DIALOG_START" then
        module.quickToUseModule.Clear()
        UnityEngine.GameObject.Destroy(self.gameObject)
    end
end

return quickToUseMax
