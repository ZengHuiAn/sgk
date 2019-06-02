local EquipmentModule = require "module.equipmentModule"
local EquipConfig = require "config.equipmentConfig"
local EquipHelp = require "module.EquipHelp"
local HeroModule = require "module.HeroModule"
local HeroScroll = require "hero.HeroScroll"
local ParameterConf = require "config.ParameterShowInfo"
local Property = require "utils.Property"
local CommonConfig = require "config.commonConfig"

local View = {}
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view;

	self:UpdateEquipDetail(data)
	self:SetCallback()	
end

function View:SetCallback()
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
	end
end

function View:UpdateEquipDetail(data)
	self.Index = data and data.index or 1
	self.heroId = data and data.roleID
	self.suits = data and data.suits
	self.uuid = data and data.uuid
	self.unShowBtn = data and data.unShowBtn
	self.offset = data and data.offset
	self.showMask = data and data.showMask
	self:InitView()
end

local function GetConsumeCfg(equip,level)
    local level = level or 1
    local _levelCfg = EquipConfig.EquipmentLevTab()[equip.cfg.id]
    --通过配置消耗类型，和等级拿到
    local _cfg = EquipConfig.GetCfgByColumnAndLv(_levelCfg.column,level)
    return _cfg
end

function View:InitView()
	if self.uuid then
		self.SelectEquip = EquipmentModule.GetByUUID(self.uuid)
		if self.heroId and self.suits and self.Index then
			self.currEquip = EquipmentModule.GetHeroEquip(self.heroId,self.Index,self.suits)
		else
			self.view.equipInfo.bottom:SetActive(false)
		end
		if self.currEquip and self.currEquip.uuid == self.uuid then
			self.currEquip = nil
		end
	else
		self.SelectEquip = EquipmentModule.GetHeroEquip(self.heroId,self.Index,self.suits)
		self.currEquip = nil
	end

	if not self.SelectEquip then
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
		return
	end

	if utils.SGKTools.GameObject_null(self.root.view)==true then
		return
	end
	self.root.mask:SetActive(not not self.showMask)
	self.view[UI.HorizontalLayoutGroup].enabled = not self.offset
	
	if self.offset then
		self.view.equipInfo[UnityEngine.RectTransform].anchorMin = CS.UnityEngine.Vector2(0.5,0)
		self.view.equipInfo[UnityEngine.RectTransform].anchorMax = CS.UnityEngine.Vector2(0.5,0)
		self.view.equipInfo[UnityEngine.RectTransform].pivot = CS.UnityEngine.Vector2(0.5, 0)
		local ScreenHeight = UnityEngine.Screen.height /  UnityEngine.Screen.width * 750;
		self.view.equipInfo[UnityEngine.RectTransform].localPosition = Vector3(0,-ScreenHeight/2+self.offset,0)
	else
		self.view[UI.HorizontalLayoutGroup].padding.top = 195
		self.view.equipInfo[UnityEngine.RectTransform].pivot = CS.UnityEngine.Vector2(0.5,1)
	end

	self.view.equipInfo:SetActive(not not self.SelectEquip)
	self.view.otherEquipInfo:SetActive(not not self.currEquip)

	if self.view.equipInfo.activeSelf then
		self:upEquipInfo(self.view.equipInfo,self.SelectEquip)
	end

	if self.view.otherEquipInfo.activeSelf then
		self:upEquipInfo(self.view.otherEquipInfo,self.currEquip,self.SelectEquip)
	end
end

function View:upEquipInfo(_view,equip,showTip)
	utils.IconFrameHelper.Create(_view.top.IconFrame, {customCfg = equip});
	_view.top.name[UI.Text].text = tostring(equip.cfg.name)
	_view.top.static_score[UI.Text].text = "装备评分:"
	_view.top.score[UI.Text]:TextFormat("{0}",equip.type==0 and tostring(Property(EquipmentModule.CaclPropertyByEq(equip)).calc_score) or tostring(Property(InscModule.CaclPropertyByInsc(equip)).calc_score))
	
	local _itemType = equip.type == 0 and utils.ItemHelper.TYPE.EQUIPMENT or utils.ItemHelper.TYPE.INSCRIPTION
	local _lock = EquipHelp.CheckEquipLockStatus(_itemType,equip.id,equip.uuid)
	_view.top.lock[CS.UGUISpriteSelector].index = _lock and 1 or 0
	CS.UGUIClickEventListener.Get(_view.top.lock.gameObject).onClick = function (obj) 
		local _index = _view.top.lock[CS.UGUISpriteSelector].index
		_view.top.lock[CS.UGUISpriteSelector].index = (_index +1)%2
		EquipHelp.ChangeEquipLockStatus(_itemType,equip.id,equip.uuid)
	end

	_view.mid.property.Text[UI.Text].text = "基础属性"
	self:UpdateEquipProprety(_view.mid.property,equip)
	self:UpdateEquipSuitDesc(_view.mid.suitDesc,equip)

	_view.bottom.LoadingTip:SetActive(showTip)

	local _add_cfg = GetConsumeCfg(equip,equip.level+1)
	_view.bottom.share:SetActive(not showTip and not _add_cfg)
	_view.bottom.Ensure:SetActive(not showTip and not not _add_cfg)
	_view.bottom.Cancel:SetActive(not showTip and equip.heroid ~= 0 and equip.heroid == self.heroId)
	_view.bottom.Load:SetActive(self.heroId and self.Index and self.suits and equip.heroid ~= self.heroId)

	_view.bottom.share.Text[UI.Text].text = "分享"
	_view.bottom.Ensure.Text[UI.Text].text = "强化"
	_view.bottom.Cancel.Text[UI.Text].text = "卸下"
	_view.bottom.Load.Text[UI.Text].text = "装备"

	CS.UGUIClickEventListener.Get(_view.bottom.share.gameObject,true).onClick = function (obj)
		DialogStack.PushPref("newEquip/equipShareFrame",equip.uuid)
	end

	CS.UGUIClickEventListener.Get(_view.bottom.Ensure.gameObject,true).onClick = function (obj)
		DialogStack.PushPrefStact("newEquip/EquipAdvance",equip.uuid)
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
	end

	CS.UGUIClickEventListener.Get(_view.bottom.Cancel.gameObject,true).onClick = function (obj)
		EquipmentModule.UnloadEquipment(equip.uuid)
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
	end
	CS.UGUIClickEventListener.Get(_view.bottom.Load.gameObject,true).onClick = function (obj)
		SGK.ResourcesManager.LoadAsync("sound/equipment_1.wav",typeof(UnityEngine.AudioClip),function (Audio)
			SGK.BackgroundMusicService.PlayUIClickSound(Audio)
			EquipmentModule.EquipmentItems(equip.uuid,self.heroId,self.Index,self.suits)
			DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
		end)
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

local function GetBassAtt(equip)
    local _tab,_basePropretyTab,_addLvTab = {},{},{}
    if equip then
        _tab = EquipmentModule.GetEquipBaseAtt(equip.uuid)
        _basePropretyTab = GetPropretyShowValue(_tab,equip)
        if equip.type == 0 then
            local _addLvCfg = EquipConfig.EquipmentLevTab()[equip.cfg.id]
            for i=0,3 do
                if _addLvCfg["type"..i] and _addLvCfg["type"..i]~=0 and _addLvCfg["value"..i]~=0 then
                    _addLvTab[_addLvCfg["type"..i]] = math.floor(_addLvCfg["value"..i])*(equip.level-1)
                end
            end
        end
    end
    return _tab,_basePropretyTab,_addLvTab
end

local function SetBassAtt(propertyItem,_basePropretyTab,_addLvTab,i)
    if _basePropretyTab[i] then
        local cfg = ParameterConf.Get(_basePropretyTab[i].key)
        if cfg then
        	propertyItem.key[UI.Text]:TextFormat("{0}:",cfg.name)
            local _addLvValue = _addLvTab[_basePropretyTab[i].key] and _addLvTab[_basePropretyTab[i].key] or 0
            local _showBaseValue = ParameterConf.GetPeropertyShowValue(_basePropretyTab[i].key,_basePropretyTab[i].allValue)
            propertyItem.value[UI.Text]:TextFormat("<color=#31FF00FF>+{0}</color>",_showBaseValue)
        end
    else
        ERROR_LOG("parameter cfg is nil,key",_basePropretyTab[i].key)
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

local function SetAddAtt(propertyItem,_addPropretyTab,i,level)
	local cfg = ParameterConf.Get(_addPropretyTab[i].key)
	if _addPropretyTab[i].key~=0 and _addPropretyTab[i].allValue~=0 and cfg then
		propertyItem.key[UI.Text]:TextFormat("{0}:",cfg.name)
		local _showValue = ParameterConf.GetPeropertyShowValue(_addPropretyTab[i].key,_addPropretyTab[i].allValue)    
		propertyItem.value[UI.Text]:TextFormat("<color=#31FF00FF>+{0}</color>",_showValue)
	else
		ERROR_LOG("parameter cfg is nil or value ==0,key,allValue",_addPropretyTab[i].key,_addPropretyTab[i].allValue)
	end
end
--装备属性开启等级Id
local commonLvId = {400,401,402,403}
function View:UpdateEquipProprety(view,equip)
	local _tab,_basePropretyTab,_addLvTab = GetBassAtt(equip)
	for i=1, view.Content.transform.childCount do
		view.Content.transform:GetChild(i-1).gameObject:SetActive(false)
	end

	for i=1,#_basePropretyTab do
		local propertyItem = utils.SGKTools.GetCopyUIItem(view.Content,view.Content[1],i)
		SetBassAtt(propertyItem,_basePropretyTab,_addLvTab,i)
	end

	local _tab1,_addPropretyTab = GetAddAtt(equip)
	for i=1,4 do
		local propertyItem = utils.SGKTools.GetCopyUIItem(view.Content,view.Content[1],#_basePropretyTab+i)
		if _addPropretyTab[i] then
			SetAddAtt(propertyItem,_addPropretyTab,i,equip.level)
		else
			if _tab1[i] and _tab1[i].key ==0 then
				local openCfg = CommonConfig.Get(commonLvId[i])
				propertyItem.key[UI.Text].text = string.format("<color=#FFFFFF99>??????(强化至%s级解锁)</color>",openCfg.para1)
				propertyItem.value[UI.Text].text =""
			else
				propertyItem:SetActive(false)
			end
		end
	end
end

function View:UpdateEquipSuitDesc(view,equip,CompareEquip)
	view.gameObject:SetActive(equip.type==0)
	if equip.type~=0 then return end
	
	local suitCfg,_suitCfg=nil
	if self.heroId then
		local _suitCfgHero = HeroModule.GetManager():GetEquipSuit(self.heroId)
		if _suitCfgHero and _suitCfgHero[equip.suits] and _suitCfgHero[equip.suits][equip.cfg.suit_id] then
			_suitCfg = _suitCfgHero[equip.suits][equip.cfg.suit_id]
		end
	end
	if _suitCfg then
		local _activeNum = CompareEquip and (CompareEquip.cfg.suit_id ~= equip.cfg.suit_id  and #_suitCfg.IdxList+1 or #_suitCfg.IdxList) or #_suitCfg.IdxList
		local _IdxList = CompareEquip and (CompareEquip.cfg.suit_id ~= equip.cfg.suit_id and table.insert(_suitCfg.IdxList,EquipPosToIdx[self.Index-6]) or _suitCfg.IdxList) or _suitCfg.IdxList
		suitCfg = setmetatable({Desc={[2] = _suitCfg.Desc[1],[4]=_suitCfg.Desc[2],[6] = _suitCfg.Desc[3]},activeNum = _activeNum},{__index = _suitCfg})
	else
		_suitCfg = HeroScroll.GetSuitConfig(equip.cfg.suit_id)
		if _suitCfg then
			suitCfg = setmetatable({Desc = {[2] = _suitCfg[2] and _suitCfg[2][equip.cfg.quality].desc,[4] = _suitCfg[4] and _suitCfg[4][equip.cfg.quality].desc,[6] = _suitCfg[6] and _suitCfg[6][equip.cfg.quality].desc},activeNum = 1,name = _suitCfg[2] and _suitCfg[2][equip.cfg.quality].name or ""},{__index = _suitCfg})
		else
			ERROR_LOG("suitCfg is nil",equip.cfg.suit_id)
		end
	end
	view.Text[UI.Text].text = suitCfg.name
	local _desc = ""
	for i=1,3 do
		if suitCfg.Desc[i*2] then
			_desc = string.format("%s%s[%s]%s</color>",_desc~="" and string.format("%s\n",_desc) or "",suitCfg.activeNum>=i*2 and "<color=#31FF00FF>" or "<color=#FFFFFF99>",i*2,suitCfg.Desc[i*2])
		end
	end	
	view.descText[UI.Text].text = _desc 
end

function View:listEvent()
	return {
			"EQUIPMENT_INFO_CHANGE",
			"LOCAL_CLOSE_EQUIPINFOFRAME",
			"LOCAL_EQUIP_CHANGE"
	}
end

function View:onEvent(event, data)
	if event == "EQUIPMENT_INFO_CHANGE" then
		self:InitView()
	elseif event == "LOCAL_CLOSE_EQUIPINFOFRAME" then
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	elseif event == "LOCAL_EQUIP_CHANGE" then
		self:UpdateEquipDetail(data)
	end
end

return View;
