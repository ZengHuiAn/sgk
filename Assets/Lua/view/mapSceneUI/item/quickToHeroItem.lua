local quickToHeroItem = {}

function quickToHeroItem:Start(data)
    self:initData(data)
    self:initUi()
end

function quickToHeroItem:initData(data)
    self.heroId = data.heroId
    self.itemId = data.itemId
    self.itemIdx = data.itemIdx
    self.idx = data.idx
    self.heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, self.heroId)
end

function quickToHeroItem:closeUi()
    UnityEngine.GameObject.Destroy(self.gameObject)
    module.HeroHelper.RemoveShowRecommendedItem(self.idx)
end

function quickToHeroItem:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        self:closeUi()
    end
    self:initItem()
    self:initUse()
end

function quickToHeroItem:initUse()
    CS.UGUIClickEventListener.Get(self.view.root.changeBtn.gameObject).onClick = function()
        self.view.root.changeBtn[CS.UGUIClickEventListener].interactable = false
        self.view.root.changeBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
        coroutine.resume(coroutine.create(function()
            local _data = utils.NetworkService.SyncRequest(17, {nil, self.heroId, self.itemIdx, 0})
            if _data[2] == 0 then
                self:closeUi()
                return
            end
            self.view.root.changeBtn[CS.UGUIClickEventListener].interactable = true
            self.view.root.changeBtn[UI.Image].material = nil
        end))
    end
end

function quickToHeroItem:OnEnable()
    if self.heroCfg.stage_slot[self.itemIdx] == 1 then
        self:closeUi()
    end
end

function quickToHeroItem:initItem()
    local _cfg = utils.ItemHelper.Get(41, self.itemId, nil, 1)
    self.view.root.newEquip.ItemIcon[SGK.ItemIcon].showDetail = true
    self.view.root.newEquip.ItemIcon[SGK.ItemIcon].pos = 2

    self.view.root.newEquip.ItemIcon[SGK.ItemIcon]:SetInfo(_cfg)
    self.view.root.newCharacterIcon[SGK.CharacterIcon]:SetInfo(self.heroCfg)

    self.view.root.newName[UI.Text].text = _cfg.name
    self.view.root.name[UI.Text].text = self.heroCfg.name
end

-- function quickToHeroItem:listEvent()
--     return {
--         "HERO_INFO_CHANGE",
--         "HERO_Stage_Equip_CHANGE",
--     }
-- end
--
-- function quickToHeroItem:onEvent(event, data)
--     if event == "HERO_INFO_CHANGE" then
--         ERROR_LOG("@@@@@@@@@")
--     elseif event == "HERO_Stage_Equip_CHANGE" then
--         ERROR_LOG("@122")
--     end
-- end

return quickToHeroItem
