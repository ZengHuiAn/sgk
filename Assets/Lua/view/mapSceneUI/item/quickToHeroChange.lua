local ItemHelper = require"utils.ItemHelper"
local equipModule = require "module.equipmentModule"
local HeroModule = require "module.HeroModule"

local quickToHeroChange = {}

function quickToHeroChange:initData(data)
    self.newUuid = 0
    self.oldUuid = 0
    if data then
        self.newUuid = data.newUuid
        self.oldUuid = data.oldUuid
        self.heroCfg = ItemHelper.Get(ItemHelper.TYPE.HERO, data.heroId)
        self.equipCfg = equipModule.GetByUUID(self.newUuid)
        if self.equipCfg.heroid ~= 0 then
            UnityEngine.GameObject.Destroy(self.gameObject)
            module.EquipHelp.RemoveQuick()
            return false
        end
        self.oldEquipCfg = equipModule.GetByUUID(self.oldUuid)
        self.placeholder = data.placeholder
    end
    if not self.equipCfg or not self.oldEquipCfg then
        UnityEngine.GameObject.Destroy(self.gameObject)
        module.EquipHelp.RemoveQuick()
        return false
    end
    local _hero = module.HeroModule.GetManager():Get(self.heroCfg.id)
    _hero:ReCalcProperty()
    self.capacity = _hero.capacity
    return true
end

function quickToHeroChange:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initBtn()
    self:initIcon()
end

function quickToHeroChange:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        local _hero = module.HeroModule.GetManager():Get(self.heroCfg.id)
		_hero:ReCalcProperty()
        UnityEngine.GameObject.Destroy(self.gameObject)
        module.EquipHelp.RemoveQuick()
    end
    CS.UGUIClickEventListener.Get(self.view.root.changeBtn.gameObject).onClick = function()
        if self.heroCfg and self.equipCfg then
            local top = DialogStack.Top();
            if top and top.name == "newRole/roleFramework" then
                DispatchEvent("LOCAL_CHANGE_HERO", {heroId = self.heroCfg.id,goInsc = self.equipCfg.type ~= 0})
            else
                if self.equipCfg.type == 0 then
                    DialogStack.Push("newRole/roleFramework",{heroid = self.heroCfg.id, showIdx = self.placeholder})
                else
                    DialogStack.Push("newRole/roleFramework",{heroid = self.heroCfg.id, goInsc = true, showIdx = self.placeholder})
                end
            end

           
            UnityEngine.GameObject.Destroy(self.gameObject)
            module.EquipHelp.RemoveQuick()
            --equipModule.EquipmentItems(self.equipCfg.uuid, self.heroCfg.id, self.placeholder)
        end
    end
end

function quickToHeroChange:initIcon()
    self.newEquip = self.view.root.newEquip[SGK.EquipIcon]
    self.nowEquip = self.view.root.nowEquip[SGK.EquipIcon]
    self.heroName = self.view.root.name[UI.Text]
    self.newName = self.view.root.newName[UI.Text]
    self.nowName = self.view.root.nowName[UI.Text]
    self.score = self.view.root.score[UI.Text]
    self:upIcon()
end

function quickToHeroChange:upIcon()
    self.equipCfg.ItemType=self.equipCfg.type==0 and 43 or 45
    self.oldEquipCfg.ItemType=self.oldEquipCfg.type==0 and 43 or 45

    utils.IconFrameHelper.Create(self.view.root.newEquip, {uuid = self.equipCfg.uuid, showDetail = true})
    utils.IconFrameHelper.Create(self.view.root.nowEquip, {uuid = self.oldEquipCfg.uuid, showDetail = true})
    -- self.newEquip:SetInfo(self.equipCfg)
    -- self.nowEquip:SetInfo(self.oldEquipCfg)
    -- self.newEquip.showDetail = true
    -- self.newEquip.pos = 2
    -- self.nowEquip.showDetail = true
    -- self.nowEquip.pos = 2
    utils.IconFrameHelper.Create(self.view.root.IconFrame, {type = 42, uuid = self.heroCfg.uuid})
    self.heroName.text = self.heroCfg.name
    self.newName.text = self.equipCfg.cfg.name
    self.nowName.text = self.oldEquipCfg.cfg.name
    local _value = module.EquipHelp.GetInscAddScore(self.heroCfg.id, self.equipCfg.uuid, self.placeholder)
    self.score.text = string.format("%s%s",_value>0 and "+" or "",_value)
end

function quickToHeroChange:Start(data)
    if self:initData(data) then
        self:initUi()
    end
end

function quickToHeroChange:OnDestroy()
    DispatchEvent("LOCAL_EQUIP_QUERY_QUICKTOHERO")
end

function quickToHeroChange:listEvent()
    return {
        "EQUIPMENT_INFO_CHANGE",
        "LOCAL_PLACEHOLDER_CHANGE",
    }
end

function quickToHeroChange:onEvent(event, data)
    if event == "EQUIPMENT_INFO_CHANGE" then
        if data == self.equipCfg.uuid then
            -- local _hero = module.HeroModule.GetManager():Get(self.heroCfg.id)
    		-- _hero:ReCalcProperty()
            -- -- local _capacity = _hero.capacity - self.capacity
            -- -- showPropertyChange({"战力"}, {_capacity}, self.heroCfg.name)
            -- showDlgError(nil, "替换成功")
            UnityEngine.GameObject.Destroy(self.gameObject)
            module.EquipHelp.RemoveQuick()
        end
    elseif event == "LOCAL_PLACEHOLDER_CHANGE" then
        self:checkHeroOnline()
    end
end

function quickToHeroChange:checkHeroOnline()
    for i,v in ipairs(module.HeroModule.GetManager():GetFormation()) do
        if v ~= 0 and v == self.heroCfg.id then
            return
        end
    end
    UnityEngine.GameObject.Destroy(self.gameObject)
    module.EquipHelp.RemoveQuick()
end

function quickToHeroChange:OnEnable()
    self.equipCfg = equipModule.GetByUUID(self.newUuid)
    self.oldEquipCfg = equipModule.GetByUUID(self.oldUuid)
    if self.equipCfg and self.equipCfg.heroid == 0 then
        local _cfg = equipModule.GetHeroEquip(self.heroCfg.id, self.placeholder)
        if _cfg then
            if self.oldEquipCfg then
                if self.oldEquipCfg.uuid ~= _cfg.uuid then
                    UnityEngine.GameObject.Destroy(self.gameObject)
                    module.EquipHelp.RemoveQuick()
                    return
                end
            end
        else
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

return quickToHeroChange
