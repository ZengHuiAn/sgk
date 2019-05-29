local EquipmentModule = require "module.equipmentModule";
local ParameterConf = require "config.ParameterShowInfo"
local Property = require "utils.Property"
local CommonConfig = require "config.commonConfig"
local HeroScroll = require "hero.HeroScroll"
local EquipConfig = require "config.equipmentConfig"
local ItemModule = require "module.ItemModule"
local ItemHelper = require "utils.ItemHelper"
local TipCfg = require "config.TipConfig"
local EquipHelp = require "module.EquipHelp"

local View = {}
local otherConsumeCfg = TipCfg.GetConsumeConfig(27)
local function GetConsumeCfg(equip,level)
    local level = level or 1
    local _levelCfg = EquipConfig.EquipmentLevTab()[equip.cfg.id]
    --通过配置消耗类型，和等级拿到
    local _cfg = EquipConfig.GetCfgByColumnAndLv(_levelCfg.column,level)
    return _cfg
end
--获取升到某一级需要的资源数
local function GetAddConsumeValue(equip,nextLevel,nowLevel)
    local value = 0 
    nowLevel = nowLevel or equip.level
    nextLevel = nextLevel or nowLevel+1
    local cfgNow = GetConsumeCfg(equip,nowLevel)
    local cfgNext = GetConsumeCfg(equip,nextLevel)
    if cfgNext then
        if cfgNow then
            value = cfgNext.value - cfgNow.value
        else--没有上一级 本级为 1级 
            value = cfgNext.value
        end
    else--没有下一级 本级为最高级
        value = cfgNow.value
    end
    return value
end

local function CalculateCountById(_quenchValue,v,equip,suitAdd,posAdd)
    local _Addvalue = _quenchValue
    if v.cfg.type ==equip.cfg.type then
        _Addvalue = _Addvalue +_quenchValue*posAdd
    end
    if v.cfg.suit_id ==equip.cfg.suit_id then
        _Addvalue = _Addvalue +_quenchValue*suitAdd
    end
    return _Addvalue
end

--计算吞噬当前装备 返还的 道具数量
local backValueTab = {SAMEPOS=410,SAMESUIT=411}
local function CalculateReturnCount(equip,tab)
    local count = 0
    local _consumeId = GetConsumeCfg(equip) and GetConsumeCfg(equip).id
    --套装加成
    local suitAdd = CommonConfig.Get(backValueTab.SAMESUIT).para1/10000
    --位置加成
    local posAdd = CommonConfig.Get(backValueTab.SAMEPOS).para1/10000

    local _value = CommonConfig.Get(equip.type==0 and 9 or 10).para1/10000
    for k,v in pairs(tab) do
        if v.cfg.swallowed_id == _consumeId then
            local _quenchValue = v.cfg.swallowed + (v.cfg.swallowed_incr and v.cfg.swallowed_incr * (v.level - 1) or 0)
            _quenchValue = CalculateCountById(_quenchValue,v,equip,suitAdd,posAdd)
            count = count + _quenchValue
        end
        if v.cfg.swallowed_id2 == _consumeId then
            local _quenchValue=v.cfg.swallowed2+ (v.cfg.swallowed_incr2 and v.cfg.swallowed_incr2 * (v.level - 1) or 0)
            _quenchValue = CalculateCountById(_quenchValue,v,equip,suitAdd,posAdd)
            count = count + _quenchValue
        end
        count = math.ceil(count + v.exp *_value)
    end
    return count
end

local function CheckAddOver(equip,tab)
    --吞噬返还 value
    local consumeValue = CalculateReturnCount(equip,tab)
    local GetMax = false
    for i=equip.level,math.huge do
        --到 i级消耗的资源总量
        local _cfg = GetConsumeCfg(equip,i)
        if _cfg then
            if _cfg.value >= equip.exp + consumeValue then
                break
            end
        else
            GetMax = true
            break
        end
    end
    return GetMax
end

local function CheckEquipScroll(equip)
    local result = false
    local cost_id = 0
    local cotst_value = 0
    if equip.type ==0 then
        local _attribute = equip.attribute
        for i=1,#_attribute do
            if _attribute[i].cfg.type == 0 then--可刷新
                result = true
                cost_id = _attribute[i].cfg.cost_id
                cotst_value = _attribute[i].cfg.cost_value
                break
            end
        end
    end
    return result,cost_id,cotst_value
end

local function GetCopyUIItem(parent,prefab,i)
    local obj = nil
    if i <= parent.transform.childCount then
        obj = parent.transform:GetChild(i-1).gameObject
    else
        obj = CS.UnityEngine.GameObject.Instantiate(prefab.gameObject,parent.transform)
        obj.transform.localPosition = Vector3.zero
    end
    obj:SetActive(true)
    local item = CS.SGK.UIReference.Setup(obj)
    return item
end

local propertyTab = {{},{}}
local function GetAndSetEquipProperty(equip)
    if equip then
        propertyTab = {{},{}}
        local _tab = EquipmentModule.GetEquipBaseAtt(equip.uuid)
        local _tab1 = EquipmentModule.GetAttribute(equip.uuid)
        for k,v in pairs(_tab) do
            if v.key~=0 and v.allValue ~= 0 then
                propertyTab[1][v.key] = propertyTab[1][v.key] and propertyTab[1][v.key]+v.allValue or v.allValue 
            end
        end
        for k,v in pairs(_tab1) do
            if v.key~=0 and v.allValue ~= 0 then
                propertyTab[2][v.key] = propertyTab[2][v.key] and propertyTab[2][v.key]+v.allValue or v.allValue
            end
        end
        return propertyTab
    else
        local tab = {}
        for k,v in pairs(propertyTab) do
            tab[k] = v
        end
        return tab
    end
end

function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject)
    self.view = self.root.view.Content

    self.root.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_equip_grow")

    CS.UGUIClickEventListener.Get(self.root.view.Close.gameObject).onClick = function (obj) 
        DialogStack.Pop()
    end

    CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function (obj) 
        DialogStack.Pop()
    end
    self.root.lockMask:SetActive(false)

    CS.UGUIClickEventListener.Get(self.view.bottom.addBtn.gameObject).onClick = function (obj)
        self.view.detailInfoPanel:SetActive(false)
        if self.Equip then
            if GetConsumeCfg(self.Equip,self.Equip.level+1) then
                if  next(self.SelectEquipTab)~=nil then
                    local _selectCount = 0
                    for k,v in pairs(self.SelectEquipTab) do
                        _selectCount = _selectCount +1
                    end
                    local consumeCount = otherConsumeCfg.item_value*_selectCount
                    local ownedCount = ItemModule.GetItemCount(otherConsumeCfg.item_id)
                    if ownedCount >= consumeCount then
                        local _equipTab = {}
                        local maxQuality = 0
                        for k,v in pairs(self.SelectEquipTab) do
                            table.insert(_equipTab,k)
                            if v.quality >maxQuality then
                                maxQuality = v.quality
                            end
                        end
                        --紫色以上品质增加二次确认
                        if maxQuality>=3 then
                            showDlgMsg(SGK.Localize:getInstance():getValue("zhuangbeiqianghuatishi_tip"), 
                                function ()
                                    EquipmentModule.AdvLevelMsg(self.Equip.uuid,_equipTab)
                                    GetAndSetEquipProperty(self.Equip)
                                    self.locked = true
                                end, 
                                function () end, 
                                SGK.Localize:getInstance():getValue("common_queding_01"), --确定
                                SGK.Localize:getInstance():getValue("common_cancle_01") --取消
                            )
                        else
                            EquipmentModule.AdvLevelMsg(self.Equip.uuid,_equipTab)
                            GetAndSetEquipProperty(self.Equip)
                            self.locked = true
                        end  
                    else
                        local cfg = ItemHelper.Get(otherConsumeCfg.type,otherConsumeCfg.item_id)
                        showDlgError(nil,cfg.name.."不足")
                    end
                else
                    showDlgError(nil,"请先放入消耗装备")
                end
            else
                showDlgError(nil,"强化已达上限")
            end
        end
    end

    self.SelectEquipTab = {}

    self.uuid = data

    self.placeholderFigter = 0
    self.equipFigter = 0

    self:UpdateEquipInfo()
    self:updateLevelAndExpChange()

    self.view.mid.TipBtn.Tip:SetActive(true)
 
    self.view.mid.TipBtn.Tip.Text[UI.Text].text = SGK.Localize:getInstance():getValue("zhuangbeiqianghua_tip")
    self.view.mid.TipBtn.transform:DOScale(Vector3.one,1):OnComplete(function() 
        self.view.mid.TipBtn.Tip[CS.DG.Tweening.DOTweenAnimation]:DOPlay();
    end)

    self.view.transform:DOScale(Vector3.one,3.2):OnComplete(function()
        --策划需求2秒后自动关闭
        if self.view.mid.TipBtn.Tip.activeSelf then
            self.view.mid.TipBtn.Tip:SetActive(false)
        end
    end)

    CS.UGUIClickEventListener.Get(self.view.mid.TipBtn.Btn.gameObject).onClick = function (obj) 
        self.view.detailInfoPanel:SetActive(false)
        if self.view.mid.TipBtn.Tip.activeSelf then
            self.view.mid.TipBtn.Tip:SetActive(false)
        else
            self.view.mid.TipBtn.Tip:SetActive(true)
            self.view.mid.TipBtn.Tip[CS.DG.Tweening.DOTweenAnimation]:DORestart(true)
        end
    end

    CS.UGUIClickEventListener.Get(self.view.mid.fifter.AutoSelectBtn.gameObject).onClick = function (obj) 
        self.view.detailInfoPanel:SetActive(false)
        self:OnAddToMax()
    end

    CS.UGUIClickEventListener.Get(self.root.view.gameObject,true).onClick = function (obj) 
        self.view.detailInfoPanel:SetActive(false)
    end
end

function View:UpdateEquipInfo()
    self.Equip = EquipmentModule.GetByUUID(self.uuid)
    if self.Equip and utils.SGKTools.GameObject_null(self.view) ~= true then
        self.view.top.info.name[UI.Text].text = self.Equip.cfg.name
        self.view.top.info.name[UI.Text].color = ItemHelper.QualityColor(self.Equip.cfg.quality)
        self.view.top.info.score[UI.Text]:TextFormat("装备评分:{0}",self.Equip.type==0 and tostring(Property(EquipmentModule.CaclPropertyByEq(self.Equip)).calc_score) or tostring(Property(InscModule.CaclPropertyByInsc(self.Equip)).calc_score))
        utils.IconFrameHelper.Create(self.view.top.IconFrame, {customCfg = self.Equip,onClickFunc = function ()
                DialogStack.PushPref("newEquip/equipInfoFrame",{uuid = self.Equip.uuid,showMask = true})
            end});

        self.view.mid.nowLvText[UI.Text].text = self.Equip.level
        
        local cfg = ItemHelper.Get(otherConsumeCfg.type,otherConsumeCfg.item_id)
        self.view.bottom.addTip.Icon[UI.Image]:LoadSprite("icon/"..cfg.icon.."_small")

        --self.view.bottom.addBtn[CS.UGUISpriteSelector].index = not GetConsumeCfg(self.Equip,self.Equip.level+1) and 1 or 0

        self:UpdateDropDown()
        self:UpdateEquipProprety()

        local _status,cost_id,cost_value = CheckEquipScroll(self.Equip)
        self.view.Identification:SetActive(_status)
        if _status then
            self.view.Identification.Image:SetActive(cost_id~=0 and cost_value ~= 0)
            if cost_id~=0 and cost_value ~= 0 then
                local _count = module.ItemModule.GetItemCount(cost_id)
                self.view.Identification.Image.Text[UI.Text].text = string.format("%s%s</color>/%s",_count>=cost_value and "<color=#FFFFFFFF>" or "<color=#BC0000FF>",_count,cost_value)
            end
        end
        CS.UGUIClickEventListener.Get(self.view.Identification.IdentificationBtn.gameObject).onClick = function (obj) 
            self.view.detailInfoPanel:SetActive(false)
            self:InIdentification()
        end
    end
end

local function GetPropretyShowValue(_tab,equip)
    local tab,showTab={},{}
    for i=1,#_tab do
        if _tab[i].key~=0 and _tab[i].allValue~=0 then 
            tab[_tab[i].key]=setmetatable({value=tab[_tab[i].key] and tab[_tab[i].key].value or 0},{__index=_tab[i]})
            tab[_tab[i].key].value=tab[_tab[i].key].value+_tab[i].allValue
        end
    end
    for k,v in pairs(tab) do
        table.insert(showTab,setmetatable({key=k,allValue=v.value},{__index=v}))
    end

    if equip then
        local sortTab = {}
        local Idx = 0
        local _baseAtt = EquipmentModule.GetEquipBaseAtt(equip.uuid)
        for i=1,#_baseAtt do
            if _baseAtt[i].key~=0  then
                Idx = Idx+i-100
                sortTab[_baseAtt[i].key] = sortTab[_baseAtt[i].key] or Idx
            end
        end

        if equip.pool5 then
            for i=1,#equip.pool5 do
                if equip.pool5[i].key and equip.pool5[i].key~=0 and equip.pool5[i].value and equip.pool5[i].value~=0 then
                    sortTab[equip.pool5[i].key] = sortTab[equip.pool5[i].key] and -10 or -10
                end
            end
        end

        if equip.pool6 then
            for i=1,#equip.pool6 do
                if equip.pool6[i].key and equip.pool6[i].key~=0 and equip.pool6[i].value and equip.pool6[i].value~=0 then
                    sortTab[equip.pool6[i].key] = sortTab[equip.pool6[i].key] and -5 or -5
                end
            end
        end

        if equip.attribute then
            for i=1,#equip.attribute do
                if equip.attribute[i].key ~= 0 then
                    Idx = Idx*10 +i
                    sortTab[equip.attribute[i].key] = sortTab[equip.attribute[i].key] or Idx
                end
            end
        end
        table.sort(showTab,function (a,b)
            return sortTab[a.key]<sortTab[b.key]
        end)
    end
    return showTab
end 

local function GetBassAtt(equip,lv)
    --[==[
    local _tab,_basePropretyTab,_addLvTab = {},{},{}
    if equip then
        _tab = EquipmentModule.GetEquipBaseAtt(equip.uuid)
        _basePropretyTab = GetPropretyShowValue(_tab,equip)
        if equip.type == 0 then
            local _addLvCfg = EquipConfig.EquipmentLevTab()[equip.cfg.id]
            if _addLvCfg then
                for i=0,3 do
                    if _addLvCfg["type"..i] and _addLvCfg["type"..i]~=0 and _addLvCfg["value"..i]~=0 then
                        _addLvTab[_addLvCfg["type"..i]] = math.floor(_addLvCfg["value"..i])*(equip.level-1)
                    end
                end
            else
                ERROR_LOG("_addLvCfg is nil,id",equip.cfg.id)
            end
        end
    end
    return _tab,_basePropretyTab,_addLvTab
    --]==]
    -- ERROR_LOG(sprinttb(equip))
    local _showLv = lv and lv-equip.level+1 or 1
    local _tab,_basePropretyTab,_addLvTab = {},{},{}
    if equip then
        _tab = EquipmentModule.GetEquipBaseAtt(equip.uuid)
        _basePropretyTab = GetPropretyShowValue(_tab,equip)
        if equip.type == 0 then
            local _addLvCfg = EquipConfig.EquipmentLevTab()[equip.cfg.id]
            if _addLvCfg and _showLv-1>=0 then
                for i=0,3 do
                    if _addLvCfg["type"..i] and _addLvCfg["type"..i]~=0 and _addLvCfg["value"..i]~=0 then
                        _addLvTab[_addLvCfg["type"..i]] = math.floor(_addLvCfg["value"..i])*(_showLv-1)
                    end
                end

                if equip.pool5 then
                    for i=1,#equip.pool5 do
                        if equip.pool5[i].key and equip.pool5[i].key~=0 and equip.pool5[i].value and equip.pool5[i].value~=0 then
                            _addLvTab[equip.pool5[i].key] = math.floor(equip.pool5[i].value * (_showLv - 1) * equip.pool5[i].cfg.property_lev_per / 10000) + equip.pool5[i].grow or 0
                        end
                    end
                end
                if equip.pool6 then
                    for i=1,#equip.pool6 do
                        if equip.pool6[i].key and equip.pool6[i].key~=0 and equip.pool6[i].value and equip.pool6[i].value~=0 then
                            _addLvTab[equip.pool6[i].key] = math.floor(equip.pool6[i].value * (_showLv - 1) * equip.pool6[i].cfg.property_lev_per / 10000) + equip.pool6[i].grow or 0
                        end
                    end
                end
            else
                ERROR_LOG("_addLvCfg is nil,id",equip.cfg.id)
            end
        end
    end
    return _tab,_basePropretyTab,_addLvTab
end

local function SetBassAtt(type,propertyItem,_basePropretyTab,_addLvTab,i)
    -- ERROR_LOG(sprinttb(_basePropretyTab),sprinttb(_addLvTab))
    if _basePropretyTab[i] then
        local cfg = ParameterConf.Get(_basePropretyTab[i].key)
        if cfg then
            if type == 0 then
                local _addLvValue = _addLvTab[_basePropretyTab[i].key] and _addLvTab[_basePropretyTab[i].key] or 0

                local _showAddLvValue = ParameterConf.GetPeropertyShowValue(_basePropretyTab[i].key,_addLvValue)
                --local _showBaseValue = ParameterConf.GetPeropertyShowValue(_basePropretyTab[i].key,_basePropretyTab[i].allValue-_addLvValue)
                local _showBaseValue = ParameterConf.GetPeropertyShowValue(_basePropretyTab[i].key,_basePropretyTab[i].allValue)
                if _addLvValue ~= 0 then
                    propertyItem.Text[UI.Text]:TextFormat("{0}:{1}(<color=#00A600FF>+{2}</color>)",cfg.name,_showBaseValue,_showAddLvValue)
                else
                    propertyItem.Text[UI.Text]:TextFormat("{0}:{1}",cfg.name,_showBaseValue)
                end
            else
                local _showValue = ParameterConf.GetPeropertyShowValue(_basePropretyTab[i].key,_basePropretyTab[i].allValue)  
                propertyItem.Text[UI.Text]:TextFormat("{0}{1}{2}",cfg.name,cfg.rate ~= -1 and "+" or "",_showValue)
            end
        else
            ERROR_LOG("parameter cfg is nil,key",_basePropretyTab[i])
        end
    else
        ERROR_LOG("_basePropretyTab[i] is nil,i",i)
    end 
end

local function GetAddAtt(equip)
    local _tab1,_addPropretyTab = {},{}
    if equip then
        _tab1 = EquipmentModule.GetAttribute(equip.uuid)
        _addPropretyTab = GetPropretyShowValue(_tab1,equip)
    end
    return _tab1,_addPropretyTab
end

local function SetAddAtt(type,propertyItem,_addPropretyTab,i,level)
    local cfg = ParameterConf.Get(_addPropretyTab[i].key)
    if _addPropretyTab[i].key~=0 and _addPropretyTab[i].allValue~=0 and cfg then
        local _, color =UnityEngine.ColorUtility.TryParseHtmlString('#D24A00FF');  
        if type == 0 then
            local _showValue = ParameterConf.GetPeropertyShowValue(_addPropretyTab[i].key,_addPropretyTab[i].allValue)    
            propertyItem.Text[UI.Text]:TextFormat("{0}:{1}",cfg.name,_showValue)
        else
            local _scroll = HeroScroll.GetScrollConfig(_addPropretyTab[i].scrollId)
            local _max = _scroll.max_value + _scroll.lev_max_value * (level - 1)
            local _showMax = ParameterConf.GetPeropertyShowValue(_addPropretyTab[i].key,_max)

            local _showValue = ParameterConf.GetPeropertyShowValue(_addPropretyTab[i].key,_addPropretyTab[i].allValue)
            propertyItem.Text[UI.Text]:TextFormat("{0}:{1}",cfg.name,_showValue)
            propertyItem.TopText[UI.Text]:TextFormat("<color=#000000B2>{0}{1}</color>",TipCfg.GetAssistDescConfig(51001).info, _showMax)  
            
            propertyItem.Text.Text[UI.Text].color = color
            propertyItem.Text.Text.Text[UI.Text].color = color
        end
        propertyItem.Text[UI.Text].color = color
    else
        ERROR_LOG("parameter cfg is nil or value ==0,key,allValue",_addPropretyTab[i].key,_addPropretyTab[i].allValue)
    end
end

--装备属性开启等级Id
local commonLvId = {400,401,402,403}
function View:UpdateEquipProprety(lv)
    if not self.Equip then return end

    local _tab,_basePropretyTab,_addLvTab = GetBassAtt(self.Equip,lv)
    for i=1,self.view.proprety.basePropretys.transform.childCount do
        self.view.proprety.basePropretys.transform:GetChild(i-1).gameObject:SetActive(false)
    end

    for i=1,#_basePropretyTab do
        local propertyItem = GetCopyUIItem(self.view.proprety.basePropretys,self.view.proprety.proprety,i)
        SetBassAtt(self.Equip.type,propertyItem,_basePropretyTab,_addLvTab,i)
    end

    local _tab1,_addPropretyTab = GetAddAtt(self.Equip)
    for i=1,self.view.proprety.addPropretys.transform.childCount do
        self.view.proprety.addPropretys.transform:GetChild(i-1).gameObject:SetActive(false)
    end

    for i=1,4 do
        local propertyItem = GetCopyUIItem(self.view.proprety.addPropretys,self.view.proprety.proprety,i)
        if _addPropretyTab[i] then
            propertyItem[UnityEngine.CanvasGroup]:DOKill();
            propertyItem[UnityEngine.CanvasGroup].alpha = 1
            SetAddAtt(self.Equip.type,propertyItem,_addPropretyTab,i,self.Equip.level)
        else
            if _tab1[i] and _tab1[i].key ==0 then
                local openCfg = CommonConfig.Get(commonLvId[i])
                propertyItem.Text[UI.Text].text = string.format("<color=#00000080>??????(强化至%s级解锁)</color>",openCfg.para1)
                propertyItem.TopText[UI.Text].text =""
                if lv and openCfg.para1<= lv then
                    propertyItem[UnityEngine.CanvasGroup]:DOFade(0.5,0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad)
                end
            else
                propertyItem:SetActive(false)
            end
        end
    end
end

local sortLawTab = {"等级升序","等级降序","品质升序","品质降序","入手顺序"}
function View:UpdateDropDown()
    self.view.mid.fifter[1][SGK.DropdownController]:AddOpotion("全部")
    self.view.mid.fifter[1].Label[UI.Text].text="全部"
    if self.Equip then
        local itemType = self.Equip.type == 0 and ItemHelper.TYPE.EQUIPMENT or ItemHelper.TYPE.INSCRIPTION
        local typeCfg = ItemModule.GetItemType(itemType)
        local _opotionTab = {}
        for k,v in pairs(typeCfg) do
            table.insert(_opotionTab,v)
        end
        table.sort(_opotionTab,function(a, b)
            return a.sub_type < b.sub_type;
        end);
        for i=1,#_opotionTab do
            self.view.mid.fifter[1][SGK.DropdownController]:AddOpotion(_opotionTab[i].sub_pack)
        end
    
        self.view.mid.fifter[2].Label[UI.Text].text = sortLawTab[1]
        for i=1,#sortLawTab do
            self.view.mid.fifter[2][SGK.DropdownController]:AddOpotion(sortLawTab[i])
        end

        self.view.mid.fifter[1][UI.Dropdown].onValueChanged:AddListener(function (i)    
            self.placeholderFigter = _opotionTab[i] and _opotionTab[i].sub_type or 0
            self:UpdateEquipList()
        end)
        self.view.mid.fifter[2][UI.Dropdown].onValueChanged:AddListener(function (i)
            self.equipFigter = i
            self:UpdateEquipList()
        end)

        self:UpdateEquipList()
    end
end

function View:UpdateEquipList()
    self.view.detailInfoPanel:SetActive(false)
    local localEquipList = EquipmentModule.OneselfEquipMentTab()
    local list = {}
    for k,v in pairs(localEquipList) do
        if not EquipHelp.CheckEquipLockStatus(utils.ItemHelper.TYPE.EQUIPMENT,v.id,v.uuid) then
            if self.placeholderFigter ~= 0 then
                if v.type == self.Equip.type and v.heroid == 0 and v.cfg.type == self.placeholderFigter and v.uuid~= self.uuid then
                    table.insert(list,v)
                end
            else
                if v.type == self.Equip.type and v.heroid == 0 and v.uuid~= self.uuid then
                    table.insert(list,v)
                end
            end
        end
    end
    if self.equipFigter == 0 then
        table.sort(list,function (a,b)
            if a.level ~= b.level then
                return a.level < b.level
            end
            --加成1
            local sameSuit_a = a.cfg.suit_id == self.Equip.cfg.suit_id
            local sameSuit_b = b.cfg.suit_id == self.Equip.cfg.suit_id
            if sameSuit_a ~= sameSuit_b then
                return sameSuit_a
            end

            --加成2
            local samePlaceholder_a = a.cfg.type == self.Equip.cfg.type
            local samePlaceholder_b = b.cfg.type == self.Equip.cfg.type
            if samePlaceholder_a ~= samePlaceholder_b then
                return samePlaceholder_a
            end
            

            if a.cfg.quality ~= b.cfg.quality then
                return a.cfg.quality < b.cfg.quality
            end

            if a.cfg.type ~= b.cfg.type then
                return a.cfg.type < b.cfg.type
            end
            if a.cfg.suit_id~= b.cfg.suit_id then
                return a.cfg.suit_id < b.cfg.suit_id
            end
            if a.time ~= b.time then
                return a.time > b.time
            end
            return a.uuid < b.uuid
        end)
    elseif self.equipFigter == 1 then
        table.sort(list,function (a,b)
            if a.level ~= b.level then
                return a.level > b.level
            end
            --加成1
            local sameSuit_a = a.cfg.suit_id == self.Equip.cfg.suit_id
            local sameSuit_b = b.cfg.suit_id == self.Equip.cfg.suit_id
            if sameSuit_a ~= sameSuit_b then
                return sameSuit_a
            end

            --加成2
            local samePlaceholder_a = a.cfg.type == self.Equip.cfg.type
            local samePlaceholder_b = b.cfg.type == self.Equip.cfg.type
            if samePlaceholder_a ~= samePlaceholder_b then
                return samePlaceholder_a
            end

            if a.cfg.quality ~= b.cfg.quality then
                return a.cfg.quality < b.cfg.quality
            end
            if a.cfg.type ~= b.cfg.type then
                return a.cfg.type < b.cfg.type
            end
            if a.cfg.suit_id~= b.cfg.suit_id then
                return a.cfg.suit_id < b.cfg.suit_id
            end
            if a.time ~= b.time then
                return a.time > b.time
            end
            return a.uuid <b.uuid
        end)
    elseif self.equipFigter == 2 then
        table.sort(list,function (a,b)
            if a.cfg.quality ~= b.cfg.quality then
                return a.cfg.quality < b.cfg.quality
            end
            if a.level ~= b.level then
                return a.level < b.level
            end
            --加成1
            local sameSuit_a = a.cfg.suit_id == self.Equip.cfg.suit_id
            local sameSuit_b = b.cfg.suit_id == self.Equip.cfg.suit_id
            if sameSuit_a ~= sameSuit_b then
                return sameSuit_a
            end

            --加成2
            local samePlaceholder_a = a.cfg.type == self.Equip.cfg.type
            local samePlaceholder_b = b.cfg.type == self.Equip.cfg.type
            if samePlaceholder_a ~= samePlaceholder_b then
                return samePlaceholder_a
            end
            if a.cfg.type ~= b.cfg.type then
                return a.cfg.type < b.cfg.type
            end
            if a.cfg.suit_id~= b.cfg.suit_id then
                return a.cfg.suit_id < b.cfg.suit_id
            end
            if a.time ~= b.time then
                return a.time > b.time
            end
            return a.uuid <b.uuid
        end)
    elseif self.equipFigter == 3 then
        table.sort(list,function (a,b)
            if a.cfg.quality ~= b.cfg.quality then
                return a.cfg.quality > b.cfg.quality
            end
            if a.level ~= b.level then
                return a.level < b.level
            end
            --加成1
            local sameSuit_a = a.cfg.suit_id == self.Equip.cfg.suit_id
            local sameSuit_b = b.cfg.suit_id == self.Equip.cfg.suit_id
            if sameSuit_a ~= sameSuit_b then
                return sameSuit_a
            end

            --加成2
            local samePlaceholder_a = a.cfg.type == self.Equip.cfg.type
            local samePlaceholder_b = b.cfg.type == self.Equip.cfg.type
            if samePlaceholder_a ~= samePlaceholder_b then
                return samePlaceholder_a
            end
            if a.cfg.type ~= b.cfg.type then
                return a.cfg.type < b.cfg.type
            end
            if a.cfg.suit_id~= b.cfg.suit_id then
                return a.cfg.suit_id < b.cfg.suit_id
            end
            if a.time ~= b.time then
                return a.time > b.time
            end
            return a.uuid <b.uuid
        end)
    elseif self.equipFigter == 4 then
        table.sort(list,function (a,b)
            if a.time ~= b.time then
                return a.time> b.time
            end
            
            if a.level ~= b.level then
                return a.level < b.level
            end

            --加成1
            local sameSuit_a = a.cfg.suit_id == self.Equip.cfg.suit_id
            local sameSuit_b = b.cfg.suit_id == self.Equip.cfg.suit_id
            if sameSuit_a ~= sameSuit_b then
                return sameSuit_a
            end

            --加成2
            local samePlaceholder_a = a.cfg.type == self.Equip.cfg.type
            local samePlaceholder_b = b.cfg.type == self.Equip.cfg.type
            if samePlaceholder_a ~= samePlaceholder_b then
                return samePlaceholder_a
            end
            if a.cfg.type ~= b.cfg.type then
                return a.cfg.type < b.cfg.type
            end
            if a.cfg.suit_id~= b.cfg.suit_id then
                return a.cfg.suit_id < b.cfg.suit_id
            end
            if a.cfg.quality ~= b.cfg.quality then
                return a.cfg.quality < b.cfg.quality
            end
            return a.uuid <b.uuid
        end)
    end

    self:InScrollView(list)
end

function View:updateLevelAndExpChange(level,Exp)
    local _overExp,_lvExp,_showNextLv = nil
    local lvExpValue = GetAddConsumeValue(self.Equip,self.Equip.level,1)

    local _selectCount = 0
    if self.SelectEquipTab and next(self.SelectEquipTab)~=nil then
        local consumeValue = CalculateReturnCount(self.Equip,self.SelectEquipTab)
        for i=self.Equip.level,math.huge do
            --到 i级消耗的资源总量
            local _cfg = GetConsumeCfg(self.Equip,i)
            if _cfg then--i >1
                --经验不足以升到 i级
                if _cfg.value > self.Equip.exp + consumeValue then
                    _showNextLv = i-1
                    --到达第i级需要的经验
                    _lvExp = GetAddConsumeValue(self.Equip,i,i-1)
                    local lastLvValue = GetAddConsumeValue(self.Equip,i-1,1)
                  
                    _overExp = self.Equip.exp + consumeValue -lastLvValue
                    break
                elseif _cfg.value == self.Equip.exp + consumeValue then
                    _showNextLv = i
                    
                    if GetConsumeCfg(self.Equip,i+1) then
                        _lvExp = GetAddConsumeValue(self.Equip,i+1,i)
                        _overExp = 0
                    else
                        _lvExp = GetAddConsumeValue(self.Equip,i,i-1)
                        _overExp = GetAddConsumeValue(self.Equip,i,i-1)
                    end
                    break
                end
            else--i-1为MaxLv        
                _showNextLv = i-1
                _lvExp = GetAddConsumeValue(self.Equip,i-1,i-2)
                _overExp = GetAddConsumeValue(self.Equip,i-1,i-2)
                break
            end
        end

        for k,v in pairs(self.SelectEquipTab) do
            _selectCount = _selectCount +1
        end
    else  
        if GetConsumeCfg(self.Equip,self.Equip.level+1) then--没有达到最高级
            _lvExp = GetAddConsumeValue(self.Equip,self.Equip.level+1,self.Equip.level)
        else 
            _lvExp = GetAddConsumeValue(self.Equip,self.Equip.level,self.Equip.level-1)
        end
        if self.Equip.exp-lvExpValue >= _lvExp then
            _overExp = _lvExp
        else
            _overExp = self.Equip.exp-lvExpValue
        end
        _showNextLv = self.Equip.level
    end

    self.view.bottom.addTip.num[UI.Text].text = "x"..otherConsumeCfg.item_value*_selectCount

    self.view.mid.Exp.transform.localScale = Vector3(1-_overExp/_lvExp,1,1)
    self.view.mid.Value[UI.Text].text = _overExp.."/".._lvExp
    self.view.mid.nextLvText[UI.Text].text = _showNextLv

    local GetMax = not GetConsumeCfg(self.Equip,_showNextLv+1) and _overExp==_lvExp
    self.view.mid.fifter.AutoSelectBtn[CS.UGUISpriteSelector].index = GetMax and 1 or 0

    self:UpdateEquipProprety(_showNextLv)
end

local MaxAddValue = 30 --服务器允许 添加(件数)的最大值
local OneAddMax = 10 --一键添加单次添加上限
function View:InScrollView(list)
    self.list = list
    self.selectIdx = nil
    -- self.SelectEquipTab = {}
    -- self.view.bottom.addTip.num[UI.Text].text = "x0"

    self.UIDragIconScript = self.UIDragIconScript or self.view.mid.ScrollView.Viewport.Content[CS.ScrollViewContent]
    self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
        local item = CS.SGK.UIReference.Setup(obj);
        item:SetActive(true)
        local equip = self.list[idx+1]--list[idx+1]
        if equip then
            utils.IconFrameHelper.Create(item.IconFrame,{customCfg = equip})
   
            item.selectMark:SetActive(self.SelectEquipTab[equip.uuid])
            item.checkMark:SetActive(self.selectIdx and self.selectIdx == idx)

            item.topMark:SetActive(self.Equip.cfg.suit_id ==equip.cfg.suit_id or self.Equip.cfg.type ==equip.cfg.type)

            CS.UGUIClickEventListener.Get(item.markBtn.gameObject,true).onClick = function (obj)
                local GetMax = CheckAddOver(self.Equip,self.SelectEquipTab)

                local _selectEquipCount = 0
                for k,v in pairs(self.SelectEquipTab) do
                    _selectEquipCount = _selectEquipCount +1
                end

                if _selectEquipCount< MaxAddValue then
                    if not GetMax then 
                        self.SelectEquipTab[equip.uuid] = equip  
                        if self.selectIdx then
                            local lastSelectObj = self.UIDragIconScript:GetItem(self.selectIdx)
                            if lastSelectObj then
                                local lastSelectItem = CS.SGK.UIReference.Setup(lastSelectObj.gameObject)
                                lastSelectItem.checkMark:SetActive(false)
                            end
                        end 
       
                        self.selectIdx = idx
                        item.selectMark:SetActive(true)
                        item.checkMark:SetActive(true)
                        if not self.view.detailInfoPanel.activeSelf then
                            self.view.detailInfoPanel:SetActive(true)
                        end 
                        self:updateLevelAndExpChange()
                        -- self:updateLevelAndExpChange(addLv,surplusValue)
                        self:UpdateDetailInfoShow(equip)
                    else
                        if next(self.SelectEquipTab)~= nil then
                            showDlgError(nil,SGK.Localize:getInstance():getValue("equip_levelup_tips2"))
                        else
                            showDlgError(nil,"强化已达上限")
                        end
                    end
                else
                    showDlgError(nil,SGK.Localize:getInstance():getValue("equip_levelup_tips1"))
                end
            end

            CS.UGUIClickEventListener.Get(item.selectMark.gameObject,true).onClick = function (obj) 
                if self.selectIdx then
                    local lastSelectObj = self.UIDragIconScript:GetItem(self.selectIdx)  
                    if lastSelectObj then
                        local lastSelectItem = CS.SGK.UIReference.Setup(lastSelectObj.gameObject)
                        lastSelectItem.checkMark:SetActive(false)
                    end
                    self.selectIdx = false
                end

                item.selectMark:SetActive(false)
                item.checkMark:SetActive(false)
                self.view.detailInfoPanel:SetActive(false)

                self.SelectEquipTab[equip.uuid] = nil
                self:updateLevelAndExpChange()
            end
        end
    end)

    if self.UIDragIconScript.DataCount ~= #list then
        self.UIDragIconScript.DataCount = #list
    else
        self.UIDragIconScript:ItemRef()
    end
end

function View:OnAddToMax()
    if self.list and next(self.list) then
        --可添加列表
        local _selectTab = {}
        for i=1,#self.list do
            if not self.SelectEquipTab[self.list[i].uuid] then
                _selectTab[#_selectTab+1] = self.list[i]
            end
        end
        --已添加件数
        local _selectEquipCount = 0
        for k,v in pairs(self.SelectEquipTab) do
            _selectEquipCount = _selectEquipCount +1
        end
        --未达上限
        if _selectEquipCount< MaxAddValue then
            if self.view.detailInfoPanel.activeSelf then
                self.view.detailInfoPanel:SetActive(false)
            end 
            --可添加件数(不能超过单次上限) 
            local CanAddCount = #_selectTab>=OneAddMax and OneAddMax or #_selectTab
            --最后选择的装备 用来定位
            local lastSelectUuid = nil
            for i=1,CanAddCount do 
                local GetMax = CheckAddOver(self.Equip,self.SelectEquipTab)

                local __selectEquipCount = 0
                for k,v in pairs(self.SelectEquipTab) do
                    __selectEquipCount = __selectEquipCount +1
                end

                if __selectEquipCount< MaxAddValue then
                    if not GetMax then 
                        local _equip = _selectTab[i]
                        self.SelectEquipTab[_equip.uuid] = _equip
                        lastSelectUuid = _equip.uuid
                    else
                        showDlgError(nil,SGK.Localize:getInstance():getValue("equip_levelup_tips2"))
                        break
                    end  
                end
            end
            self:updateLevelAndExpChange()
            self.UIDragIconScript:ItemRef()

            --DoMove
            local __selectEquipCount = 0
            for k,v in pairs(self.SelectEquipTab) do
                __selectEquipCount = __selectEquipCount +1
            end
            local selectIdx = 0
            if lastSelectUuid then
                for i=1,#self.list do
                    if self.list[i].uuid == lastSelectUuid then
                        selectIdx = i
                        break
                    end
                end
            end
            local moveLine = math.ceil(selectIdx/self.UIDragIconScript.constraintCount)-2

            if moveLine>0 then
                self.view.mid.ScrollView.Viewport.Content.transform:DOLocalMove(Vector3(0,self.UIDragIconScript.cellSize.y*moveLine,0),0.5)
            end
        else
            showDlgError(nil,SGK.Localize:getInstance():getValue("equip_levelup_tips1"))
        end
    end
end

function View:UpdateDetailInfoShow(equip)
    local panel = self.view.detailInfoPanel.view
    utils.IconFrameHelper.Create(panel.top.IconFrame,{customCfg = equip})
    panel.top.name[UI.Text].text = equip.cfg.name
    panel.top.name[UI.Text].color = ItemHelper.QualityColor(equip.cfg.quality)
    
    panel.top.score[UI.Text]:TextFormat("装备评分:{0}",equip.type==0 and tostring(Property(EquipmentModule.CaclPropertyByEq(equip)).calc_score) or tostring(Property(InscModule.CaclPropertyByInsc(equip)).calc_score))

    local suitCfg = HeroScroll.GetSuitConfig(equip.cfg.suit_id)
    if suitCfg then
        panel.bottom.Text[UI.Text]:TextFormat("{0}\n{1}\n{2}","[2]"..suitCfg[2][equip.cfg.quality].desc,suitCfg[4] and "[4]"..suitCfg[4][equip.cfg.quality].desc,suitCfg[6] and "[6]"..suitCfg[6][equip.cfg.quality].desc)
    else
        panel.bottom.Text[UI.Text].text = ""
        ERROR_LOG("suitCfg is nil,suit_id",equip.cfg.suit_id)
    end
    
    for i=1,panel.mid.transform.childCount do
        panel.mid.transform:GetChild(i-1).gameObject:SetActive(false)
    end

    local _tab,_basePropretyTab,_addLvTab = GetBassAtt(equip)
    if #_basePropretyTab>0 then
        for i=1,#_basePropretyTab do
            local propertyItem = GetCopyUIItem(panel.mid,panel.mid.proprety.gameObject,i)
            SetBassAtt(equip.type,propertyItem,_basePropretyTab,_addLvTab,i)
        end
    end

    local _, color =UnityEngine.ColorUtility.TryParseHtmlString('#FFAE22FF');   
    local _tab1,_addPropretyTab = GetAddAtt(equip)
    if #_addPropretyTab>0 then
        for i=1,#_addPropretyTab do
            local propertyItem = GetCopyUIItem(panel.mid,panel.mid.proprety.gameObject,#_basePropretyTab+i)
            
            SetAddAtt(equip.type,propertyItem,_addPropretyTab,i,equip.level)
            propertyItem.Text[UI.Text].color = color
            propertyItem.Text.Text[UI.Text].color = color
            propertyItem.Text.Text.Text[UI.Text].color = color
        end
    end

    local y = panel.mid.proprety[UnityEngine.RectTransform].sizeDelta.y
    panel.mid[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,#_basePropretyTab+#_addPropretyTab>0 and (#_basePropretyTab+#_addPropretyTab)*y or 0)
end

function View:playEffect(effectName,position,node,rotation,scale,layerName,sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName..".prefab");
    if node and utils.SGKTools.GameObject_null(prefab) ~= true then
        local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.gameObject.transform);
        if o then
            local transform = o.transform;
            transform.localPosition = position or UnityEngine.Vector3.zero;
            transform.localRotation = UnityEngine.Quaternion.identity;
            transform.localScale = scale and scale*UnityEngine.Vector3.one or UnityEngine.Vector3.one
            if layerName then
                o.layer = UnityEngine.LayerMask.NameToLayer(layerName);
                for i = 0,transform.childCount-1 do
                    transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer(layerName);
                end
            end
            if sortOrder then
                SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
            end
        end
        return o
    end
end

function View:ShowChangeProprety()
    local starTab = GetAndSetEquipProperty()
    local nowTab = GetAndSetEquipProperty(self.Equip)
    local changeTab = {}
    for i=1,2 do
        for k,v in pairs(nowTab[i]) do
            local changeValue = starTab[i][k] and v-starTab[i][k] or v
            if changeValue >0 then
                table.insert(changeTab,{key = k,value = changeValue})
            end
        end
    end
    
    for i=1,#changeTab do
        local cfg = ParameterConf.Get(changeTab[i].key)
        if cfg then
            local tips = SGK.UIReference.Instantiate(self.view.top.tipsView, self.view.top.transform)
            tips:SetActive(true);
            tips[UnityEngine.CanvasGroup].alpha = 0;
            
            local _showValue = ParameterConf.GetPeropertyShowValue(changeTab[i].key,changeTab[i].value)
            tips.Text[UnityEngine.UI.Text].text = cfg.name.."<color=#00A600FF>+".._showValue.."</color>"
            tips[UnityEngine.CanvasGroup]:DOFade(1, 0.3):SetDelay((#changeTab - i) * 0.3);
            tips.transform:DOLocalMove(Vector3(0, -50, 0), 1):SetDelay((#changeTab - i) * 0.3 + 0.1):SetEase(CS.DG.Tweening.Ease.Linear);
            tips[UnityEngine.CanvasGroup]:DOFade(0, 0.3):SetDelay((#changeTab - i) * 0.3 + 0.7);
            UnityEngine.GameObject.Destroy(tips.gameObject, 1 + (#changeTab - i) * 0.3);
        else
            ERROR_LOG("property cfg is nil,id",changeTab[i].key)
        end
    end
end

--鉴定(刷新前缀)
function View:InIdentification()
    if self.Equip.type == 0 then
        local _attribute = self.Equip.attribute
        for i=1,#_attribute do
            if _attribute[i].cfg.type == 0 then--可刷新
                if _attribute[i].cfg.cost_id ~= 0 and _attribute[i].cfg.cost_value ~= 0 then
                    local consumeCfg = ItemHelper.Get(ItemHelper.TYPE.ITEM, _attribute[i].cfg.cost_id)
                    if consumeCfg then
                        local _count = module.ItemModule.GetItemCount(_attribute[i].cfg.cost_id)
                        if _count>= _attribute[i].cfg.cost_value then
                            local openCfg = CommonConfig.Get(commonLvId[i])
                            showDlgMsg(SGK.Localize:getInstance():getValue("jianding",openCfg.para1), 
                                function ()
                                    EquipmentModule.ChangeEquipScroll(self.Equip.uuid,i)
                                end, 
                                function () end, 
                                SGK.Localize:getInstance():getValue("common_queding_01"), --确定
                                SGK.Localize:getInstance():getValue("common_cancle_01") --取消
                            )
                        else
                            --showDlgError(nil,consumeCfg.name.."不足")
                            DialogStack.PushPrefStact("ItemDetailFrame", {id = _attribute[i].cfg.cost_id,type = ItemHelper.TYPE.ITEM,InItemBag=2},self.gameObject)
                        end
                    else
                        ERROR_LOG("Cfg is nil,id",_attribute[i].cfg.cost_id)
                    end
                else
                    EquipmentModule.ChangeEquipScroll(self.Equip.uuid,i)
                end
                break
            end
        end
    end
end

function View:listEvent()
    return {
        "EQUIPMENT_INFO_CHANGE",
        "ADVANCED_OVER",
    }
end

function View:onEvent(event, data)
    if event == "EQUIPMENT_INFO_CHANGE" then
        if not self.locked then
            self.SelectEquipTab = {}
            self:UpdateEquipInfo()
        else
            if not self.refresh then
                self.refresh = true
                self.root.transform:DOScale(Vector3.one,1):OnComplete(function() 
                    self.locked = false
                    self.refresh = false
                    self.SelectEquipTab = {}
                    self:UpdateEquipInfo()

                    self:ShowChangeProprety()
                end)
            end
        end
    elseif event == "ADVANCED_OVER" then
        local o = self:playEffect("fx_xp_up_1", Vector3.zero,self.view.top.IconFrame,UnityEngine.Vector3.zero,150,"UI",30000)  
        local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
        UnityEngine.Object.Destroy(o, _obj.main.duration)
        self.UIDragIconScript:ScrollMove(0)
    end
end

return View