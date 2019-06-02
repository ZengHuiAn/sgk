local heroLevelup = require "hero.HeroLevelup"
local equipCofig = require "config.equipmentConfig"
local ParameterShowInfo = require "config.ParameterShowInfo"
local OpenLevel = require "config.openLevel"

local roleEquip = {}

local roleEquipIdx = {
    [1] = 1,
    [2] = 3,
    [3] = 4,
    [4] = 2,
    [5] = 5,
    [6] = 6
}

function roleEquip:Start(data)
    self.selectIdx = true
    self:initData(data)
    self:initUi()
    self:initGuide()
end


function roleEquip:initGuide()
    module.guideModule.PlayByType(108,0.2)
end

function roleEquip:initData(data)
    if data then
        self.heroId = data.heroId
        if data.goInsc then
            self.selectIdx = false
        end
        if data.showIdxEffect then
            self.showIdxEffect = data.showIdxEffect
        end
    end
    self.suits = 0
    self.heroCfg = module.HeroModule.GetManager():Get(self.heroId or 11000)
end

function roleEquip:upInscBtn()
    if self.selectIdx then
        self.view.root.inscBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("huoban_zhuangbei_01")
        self.view.root.equipBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("huoban_zhuangbei_02")
    else
        self.view.root.inscBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("huoban_shouhu_01")
        self.view.root.equipBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("huoban_shouhuji_01")
    end
end

function roleEquip:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initEquipList()
    self:initBtn()
    self:upUi()
    self.view.root.levelup[SGK.LuaBehaviour]:Call("Init",{heroId = self.heroId})
    self.view.root.switchDiamond[SGK.LuaBehaviour]:Call("InitData",{heroId = self.heroId})
end

function roleEquip:upHeroInfo()
    local _title, _statu = module.titleModule.GetTitleStatus(self.heroCfg)
    self.view.root.titleBtn.Text[UI.Text].text = _title
end

function roleEquip:upUi()
    self:upEquipList()
    self:upProperty()
    self:upHeroInfo()
end

function roleEquip:playHeroAnim()
    -- if self.heroId == 11000 then
    --     local _color = {
    --         [0] = "hong",
    --         [1] = "hong",
    --         [2] = "huang",
    --         [3] = "zi",
    --         [4] = "lv",
    --         [5] = "hei",
    --         [6] = "fen",
    --         [7] = "lan",
    --     }
    --     self.bossAnim.initialSkinName = _color[self.heroCfg.property_value]
    -- else
    --     self.bossAnim.initialSkinName = "default"
    -- end
    -- self.bossAnim.startingAnimation = "idle"
    -- local _pos, _scale = DATABASE.GetBattlefieldCharacterTransform(tostring(self.heroCfg.mode), "ui")
    -- self.view.root.heroAnim.transform.localPosition = (_pos * 100)
    -- self.view.root.heroAnim.transform.localScale = _scale * 0.8
end

function roleEquip:initEquipList()
    for i = 1, #self.view.root.equipList do
        local _view = self.view.root.equipList[i]
        local _idx = roleEquipIdx[i] + 6
        if not self.selectIdx then
            _idx = i
        end
        local _lock, _lockLevel = equipCofig.GetEquipOpenLevel(self.suits, _idx)
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if _lock then
            	DialogStack.Push("newEquip/equipChangeFrame", {heroId = self.heroId, suits = self.suits, state = self.selectIdx, index = self.selectIdx and roleEquipIdx[i] or i})
            else
                showDlgError(nil, _lockLevel)
            end
        end
    end
end

function roleEquip:upEquipList()
    for i = 1, #self.view.root.equipList do
        local _view = self.view.root.equipList[i]
        local _idx = roleEquipIdx[i] + 6
        if not self.selectIdx then
            _idx = i
        end
        local _equip = module.equipmentModule.GetHeroEquip(self.heroId, _idx, self.suits)
        _view.icon.IconFrame:SetActive(_equip and true)
        _view.add:SetActive(_equip == nil)
        _view.addBg:SetActive(_equip == nil)
        if self.selectIdx then
            _view.addBg[CS.UGUISpriteSelector].index = 0
        else
            _view.addBg[CS.UGUISpriteSelector].index = 1
        end
        --_view.guide[UI.Image].color = {r = 1, g = 1, b = 1, a = 0}
        --_view.guide:SetActive(false)
        _view.redDot:SetActive(false)
        if _equip == nil then
            local _hash = module.equipmentModule.HashBinary[_idx]
            local _list = module.equipmentModule.GetPlace()[_hash]
            for k,v in pairs(_list or {}) do
                if equipCofig.GetEquipOpenLevel(self.suits, _idx) then
                    if v.heroid == 0 and v.showLevel <= self.heroCfg.level then
                        --_view.guide[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
                        --_view.guide:SetActive(true)
                        _view.redDot:SetActive(true)
                        break
                    end
                end
            end
        end
        local _suitCfgHero = module.HeroModule.GetManager():GetEquipSuit(self.heroId)
        _view.resonance:SetActive(false)
        for k,v in pairs(_suitCfgHero[0] or {}) do
            if #v.IdxList > 1 then
                for i,v in ipairs(v.IdxList) do
                    if v == (_idx - 6) then
                        _view.resonance:SetActive(true)
                    end
                end
            end
        end

        if self.showIdxEffect and self.showIdxEffect == _idx then
            _view.guide[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
            --_view.guide:SetActive(true)
        end
        if _view.icon.IconFrame.activeSelf then
            utils.IconFrameHelper.Create(_view.icon.IconFrame, {uuid = _equip.uuid})
            CS.UGUIClickEventListener.Get(_view.icon.IconFrame.gameObject).onClick = function()
                -- showDlgMsg("请选择进入界面", 
                -- function ()
                    if self.equipInfoFrame then
                        if self.selectIdx ~= _idx then
                            DispatchEvent("LOCAL_EQUIP_CHANGE",{roleID = self.heroId, suits = self.suits, index = _idx, state = self.selectIdx,offset = 320})
                            self.selectIdx = _idx
                        else
                            DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
                        end
                    else
                        DialogStack.PushPref("newEquip/equipInfoFrame",{roleID = self.heroId, suits = self.suits, index = _idx, state = self.selectIdx,offset = 320},self.view.transform.parent.gameObject)
                        self.selectIdx = _idx
                    end
                -- end, 
                -- function ()
                --     local _obj = DialogStack.GetPref_stact()[#DialogStack.GetPref_stact()]
                --     if _obj and utils.SGKTools.GameObject_null(_obj)~=true and _obj.name == "EquipInfo(Clone)" then
                --         DispatchEvent("LOCAL_SELECT_EQUIPMENT_CHANGE",{roleID = self.heroId, suits = self.suits, index = _idx, state = self.selectIdx})
                --     else
                --         DialogStack.PushPrefStact("newEquip/EquipInfo", {roleID = self.heroId, suits = self.suits, index = _idx, state = self.selectIdx})
                --     end
                -- end, 
                -- "新","旧")
            end
        end
    end
end

function roleEquip:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.fashionBtn.gameObject).onClick = function()
        DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
        DialogStack.PushPrefStact("roleFashionSuitFrame", {heroid = self.heroId})
    end
    CS.UGUIClickEventListener.Get(self.view.root.equipBtn.gameObject).onClick = function()
        local _status = OpenLevel.GetStatus(1302)
        if _status then
            DialogStack.PushPrefStact("newEquip/equipSuitsContent", {heroid = self.heroId, state = self.selectIdx})
        else
            local closeInfo = OpenLevel.GetCloseInfo(1302)
            showDlgError(nil,SGK.Localize:getInstance():getValue("huoban_zhuangbei_03")..closeInfo)
        end
    end
    self:upInscBtn()
    CS.UGUIClickEventListener.Get(self.view.root.inscBtn.gameObject).onClick = function()
        self.selectIdx = not self.selectIdx
        self:upInscBtn()
        self.view.root.equipList[UnityEngine.Animator]:Play("equipList_qie")
        self:initEquipList()
        self:upEquipList()
        DispatchEvent("CLOSE_EQUIPINFO_FRAME")
    end
    CS.UGUIClickEventListener.Get(self.view.root.titleBtn.gameObject).onClick = function()
        local _status = OpenLevel.GetStatus(1102)
        if _status then
            -- DialogStack.PushPrefStact("newRole/roleTitleFrame", {roleID = self.heroId})
        else
            showDlgError(nil, OpenLevel.GetCloseInfo(1102))
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.changeBtn.gameObject).onClick = function()
        DialogStack.Push("newEquip/equipChangeFrame", {heroId = self.heroId, suits = self.suits, state = self.selectIdx})
    end
end

local PropertyCfg = {
    [1] = "ad",
    [2] = "armor",
    [3] = "hpp",
    [4] = "speed",
}

function roleEquip:upPropertyIcon(_view, property)
    local _cfg = ParameterShowInfo.Get(property)
    if _cfg then
	    _view.icon[UI.Image]:LoadSprite("propertyIcon/".._cfg.icon)
    end
end

function roleEquip:upProperty()
    for i = 1, #self.view.root.property.itemNode do
        local _view = self.view.root.property.itemNode[i]
        -- if i == 1 then
        --     if self.heroId == 11000 then
        --         local _cfg = module.TalentModule.GetSkillSwitchConfig(11000)
        --         local _idx = self.heroCfg.property_value
        --         if self.heroCfg.property_value == 0 then
        --             _idx = 2
        --         end
        --         _view.value[UI.Text].text = tostring(math.floor(self.heroCfg[_cfg[_idx].atk_type]))
        --         self:upPropertyIcon(_view, _cfg[_idx].atk_type)
        --     else
        --         local _cfg = heroLevelup.Load()[self.heroId]
        --         if _cfg then
        --             if _cfg[1].value > _cfg[2].value then
        --                 _view.value[UI.Text].text = tostring(math.floor(self.heroCfg.ad))
        --                 self:upPropertyIcon(_view, "ad")
        --             else
        --                 _view.value[UI.Text].text = tostring(math.floor(self.heroCfg.ap))
        --                 self:upPropertyIcon(_view, "ap")
        --             end
        --         end
        --     end
        -- else
            _view.value[UI.Text].text = tostring(math.floor(self.heroCfg[PropertyCfg[i]]))
            self:upPropertyIcon(_view, PropertyCfg[i])
        --end
    end
    CS.UGUIClickEventListener.Get(self.view.root.property.gameObject).onClick = function()
        DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
        DialogStack.PushPref("newRole/EasyProperty", {heroid = self.heroId, ViewState = true})
    end
end

function roleEquip:onEvent(event, data)
    if event == "LOCAL_NEWROLE_HEROIDX_CHANGE" then
        self:initData(data)
        self:upUi()
    elseif event == "EQUIPMENT_INFO_CHANGE" then
        self.showIdxEffect = nil
        self:upEquipList()
        self:upProperty()
    elseif event == "GIFT_INFO_CHANGE" or event == "TITLE_INFO_CHANGE" then
        self:upHeroInfo()
    elseif event == "HERO_INFO_CHANGE" then
        self:initData()
        self:upProperty()
    elseif event == "HERO_BUFF_CHANGE" then
        self:upProperty()
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    elseif event == "PushPref_Load_success" then
        if data and data.name == "newEquip/equipInfoFrame" then
            self.equipInfoFrame = true
        end
    elseif event == "LOCAL_CLOSE_EQUIPINFOFRAME" then
        self.equipInfoFrame = false
    end
end

function roleEquip:listEvent()
	return {
    	"LOCAL_NEWROLE_HEROIDX_CHANGE",
        "EQUIPMENT_INFO_CHANGE",
        "GIFT_INFO_CHANGE",
        "TITLE_INFO_CHANGE",
        "HERO_INFO_CHANGE",
        "HERO_BUFF_CHANGE",
        "LOCAL_GUIDE_CHANE",
        "PushPref_Load_success",
        "LOCAL_CLOSE_EQUIPINFOFRAME",
    }
end

return roleEquip
