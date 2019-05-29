local guideCommon = {}

function guideCommon:Start(data)
    self:initData(data)
    self:initUi()
end

function guideCommon:initData(data)
    if data then
        self.savedValues.cfgData = data
    end
    self.questId = data or self.savedValues.cfgData
    self.cfg = module.QuestModule.GetCfg(self.questId)
end

function guideCommon:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    self:initInfo()
end

function guideCommon:upUi()
    self.view.root.title[UI.Text].text = self.cfg.name
    self.view.root.info[UI.Text].text = self.cfg.button_des
    local _imageIdx = tonumber(self.cfg.play_icon)
    if _imageIdx == 100 then
        self.view.root.icon[UI.Image]:LoadSprite("guanqia/"..self.cfg.play_text)
    else
        self.view.root.icon[CS.UGUISpriteSelector].index = (_imageIdx - 1)
    end
    if _imageIdx == 5 then
        self.view.root.icon.name:SetActive(true)
        self.view.root.icon.name[UI.Text].text = self.cfg.desc1
    elseif _imageIdx == 11 then
        self.view.root.capacity:SetActive(true)
        self.view.root.capacity[UI.Text].text = self.cfg.event_count1
    elseif _imageIdx == 100 then
        self.view.root.icon.name:SetActive(true)
        self.view.root.icon.bg:SetActive(true)
        self.view.root.icon.name[UI.Text].text = self.cfg.desc1
    end

    local _gray = not module.QuestModule.CanSubmit(self.questId)
    if _gray then
        self.view.root.getBtn[CS.UGUISelectorGroup]:setGray()
    else
        self.view.root.getBtn[CS.UGUISelectorGroup]:reset()
    end
    self.quest = module.QuestModule.Get(self.questId)
end

function guideCommon:initInfo()
    self:upUi()
    self:initReward()
    CS.UGUIClickEventListener.Get(self.view.root.getBtn.gameObject).onClick = function()
        if self.quest and self.quest.stauts == 1 then
            showDlgError(nil, SGK.Localize:getInstance():getValue("xiaobai_xiaositaya_10"))
            return
        end
        if self.quest and module.QuestModule.CanSubmit(self.questId) then
            self.view.root.getBtn[CS.UGUIClickEventListener].interactable = false
            coroutine.resume(coroutine.create(function()
                module.QuestModule.Finish(self.questId)
                if self.quest.uuid == module.guideLayerModule.Type.ChangeIcon then
                    local suitId=5011000
                    local _hero=utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, 11000);
                    local productSuit = module.ShopModule.GetManager(8,suitId) and module.ShopModule.GetManager(8,suitId)[1];
                    if productSuit then
                        local consumeId=productSuit.consume_item_id1
                        local consumePrice=productSuit.consume_item_value1
                        local targetGid=productSuit.gid
                        local ownCount=module.ItemModule.GetItemCount(consumeId)
                        if ownCount>=consumePrice then
                            if module.ShopModule.BuyTarget(8, targetGid, 1, _hero.uuid) then
                                module.HeroModule.ChangeSpecialStatus(_hero.uuid,suitId,true)
                                utils.PlayerInfoHelper.ChangeActorShow(11000) 
                                module.PlayerModule.ChangeIcon(11000)
                            end
                        else
                            ERROR_LOG("时装兑换资源不足", consumeId);
                        end
                    else
                        ERROR_LOG("时装已停售",suitId);
                    end
                end
                self.view.root.getBtn[CS.UGUISelectorGroup]:reset()
                self.view.root.getBtn[CS.UGUIClickEventListener].interactable = true
                DialogStack.Pop()
            end))
            return
        end
        showDlgError(nil, SGK.Localize:getInstance():getValue("huiyilu_xingxingjl_03"))
    end
end

function guideCommon:initReward()
    if self.cfg then
        local _item = SGK.ResourcesManager.Load("prefabs/base/IconFrame.prefab")
        for i,v in ipairs(self.cfg.reward) do
            local _obj = UnityEngine.Object.Instantiate(_item, self.view.root.rewardNode.gameObject.transform)
            _obj.transform.localScale = Vector3(0.6, 0.6, 1)
            utils.IconFrameHelper.Create(_obj, {id = v.id, type = v.type, count = v.value, showDetail = true})
        end
    end
end

function guideCommon:listEvent()
    return {
        "QUEST_INFO_CHANGE",
        "PLAYER_LEVEL_UP",
    }
end

function guideCommon:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" or event == "PLAYER_LEVEL_UP" then
        self:upUi()
    end
end

return guideCommon
