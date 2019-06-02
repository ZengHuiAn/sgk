local ItemHelper = require"utils.ItemHelper"
local equipModule = require "module.equipmentModule"
local HeroModule = require "module.HeroModule"
local quickToHero = {}

function quickToHero:initData(data)
    self.uuid = 0
    if data then
        self.uuid = data.newUuid
        self.heroCfg = ItemHelper.Get(ItemHelper.TYPE.HERO, data.heroId)
        self.equipCfg = equipModule.GetByUUID(data.newUuid or 0)
        if self.equipCfg.heroid ~= 0 then
            UnityEngine.GameObject.Destroy(self.gameObject)
            module.EquipHelp.RemoveQuick()
            return
        end
        self.placeholder = data.placeholder
    end
    if not self.equipCfg then
        UnityEngine.GameObject.Destroy(self.gameObject)
        module.EquipHelp.RemoveQuick()
        return
    end
    local _hero = HeroModule.GetManager():Get(self.heroCfg.id)
    _hero:ReCalcProperty()
    self.capacity = _hero.capacity
end

function quickToHero:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initBtn()
    self:initIcon()
end

function quickToHero:initGuide()
    module.guideModule.PlayByType(105,0.2)
end

function quickToHero:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        UnityEngine.GameObject.Destroy(self.gameObject)
        module.EquipHelp.RemoveQuick()
    end
    CS.UGUIClickEventListener.Get(self.view.root.changeBtn.gameObject).onClick = function()
        if self.heroCfg and self.equipCfg then
            equipModule.EquipmentItems(self.equipCfg.uuid, self.heroCfg.id, self.placeholder)
            -- local top = DialogStack.Top();
            -- if top and top.name == "newRole/roleFramework" then
            --     DispatchEvent("LOCAL_CHANGE_HERO", {heroId = self.heroCfg.id})
            -- else
            --     if self.equipCfg.type == 0 then
            --         DialogStack.Push("newRole/roleFramework",{heroid = self.heroCfg.id})
            --     else
            --         DialogStack.Push("newRole/roleFramework",{heroid = self.heroCfg.id, goInsc = true})
            --     end
            -- end
            UnityEngine.GameObject.Destroy(self.gameObject)
            module.EquipHelp.RemoveQuick()
        end
    end
end

function quickToHero:listEvent()
    return {
        "EQUIPMENT_INFO_CHANGE",
        "LOCAL_PLACEHOLDER_CHANGE",
        "LOCAL_GUIDE_CHANE",
        "GUIDE_DIALOG_START",
    }
end

function quickToHero:onEvent(event, data)
    if event == "EQUIPMENT_INFO_CHANGE" then
        if data == self.equipCfg.uuid then
            -- local _hero = module.HeroModule.GetManager():Get(self.heroCfg.id)
    		-- _hero:ReCalcProperty()
            -- -- local _capacity = _hero.capacity - self.capacity
            -- -- showPropertyChange({"战力"}, {_capacity}, self.heroCfg.name)
            -- showDlgError(nil, "装备成功")
            UnityEngine.GameObject.Destroy(self.gameObject)
            module.EquipHelp.RemoveQuick()
        end
    elseif event == "LOCAL_PLACEHOLDER_CHANGE" then
        self:checkHeroOnline()
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    elseif event == "GUIDE_DIALOG_START" then
        module.EquipHelp.RemoveQuick()
        UnityEngine.GameObject.Destroy(self.gameObject)
    end
end

function quickToHero:upIcon()
    if not self.heroCfg or not self.equipCfg then
        return
    end
    --self.view.root.newCharacterIcon[SGK.newCharacterIcon]:SetInfo(self.heroCfg)
    utils.IconFrameHelper.Create(self.view.root.IconFrame, {uuid = self.equipCfg.uuid, showDetail = true, showName = true})
    utils.IconFrameHelper.Create(self.view.root.newEquip.IconFrame, {type = 42, uuid = self.heroCfg.uuid})
    self.equipName.text = self.equipCfg.cfg.name
    self.heroName.text = self.heroCfg.name.."\n可以装备"
    self.score.text = tostring(module.EquipHelp.GetInscAddScore(self.heroCfg.id, self.equipCfg.uuid, self.placeholder))
end

function quickToHero:initIcon()
    self.equipName = self.view.root.newName[UI.Text]
    self.heroName = self.view.root.name[UI.Text]
    self.score = self.view.root.score[UI.Text]
    self:upIcon()
end

function quickToHero:OnDestroy()
    DispatchEvent("LOCAL_EQUIP_QUERY_QUICKTOHERO")
end

function quickToHero:checkHeroOnline()
    for i,v in ipairs(module.HeroModule.GetManager():GetFormation()) do
        if v ~= 0 and v == self.heroCfg.id then
            return
        end
    end
    UnityEngine.GameObject.Destroy(self.gameObject)
    module.EquipHelp.RemoveQuick()
end

function quickToHero:OnEnable()
    self.equipCfg = equipModule.GetByUUID(self.uuid)
    if self.equipCfg and self.equipCfg.heroid == 0 then
        if equipModule.GetHeroEquip(self.heroCfg.id, self.placeholder) then
            UnityEngine.GameObject.Destroy(self.gameObject)
            module.EquipHelp.RemoveQuick()
            return
        end
    else
        UnityEngine.GameObject.Destroy(self.gameObject)
        module.EquipHelp.RemoveQuick()
        return
    end
    self:checkHeroOnline()
end

function quickToHero:Start(data)
    self:initData(data)
    self:initUi()
    self:initGuide()
end

return quickToHero
