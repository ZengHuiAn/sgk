local EquipmentModule = require "module.equipmentModule";
local EquipConfig = require "config.equipmentConfig"
local HeroScroll = require "hero.HeroScroll"
local ItemHelper = require "utils.ItemHelper"
local HeroModule = require "module.HeroModule"
local ParameterConf = require "config.ParameterShowInfo"
local Property = require "utils.Property"
local InscModule = require "module.InscModule"
local IconFrameHelper = require "utils.IconFrameHelper"
local EquipHelp = require "module.EquipHelp"
local openLevelCfg = require "config.openLevel"
local TipCfg = require "config.TipConfig"
local CommonConfig = require "config.commonConfig"


local View = {}
function View:Start(data)
	self.root=SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view.Content
	self.view.gameObject:SetActive(false)

	self:UpdateEquipDetail(data)
	self:SetCallback()
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

function View:UpdateEquipDetail(data)
	self.Index=data and data.index or 1
	self.heroId=data and data.roleID
	self.suits=data and data.suits
	self.uuid= data and data.uuid
	self.unShowBtn=data and data.unShowBtn
	self:InitView()
end

function View:SetCallback()
	CS.UGUIClickEventListener.Get(self.root.view.Close.gameObject).onClick = function (obj)
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end

	CS.UGUIClickEventListener.Get(self.view.top.info.changeBtn.gameObject).onClick = function (obj)
		if not self.uuid then
			DialogStack.PushPrefStact("newEquip/EquipChange", {heroId = self.heroId, suits = self.suits, state =self.SelectEquip.type==0, index = self.Index,uuid=self.SelectEquip.uuid},self.root.childRoot.transform)
		else
			local heroLv=module.HeroModule.GetManager():Get(self.heroId).level
			if self.SelectEquip.cfg.equip_level<= heroLv then
				local _consumeCfg=EquipConfig.ChangePrice(self.SelectEquip.type,self.SelectEquip.quality)
				local _item=ItemHelper.Get(_consumeCfg.type,_consumeCfg.id)
			
				if _consumeCfg.value>0 and self.SelectEquip.heroid~=0 and self.SelectEquip.heroid ~=self.heroId then
					local tip=string.format("当前%s已和其他伙伴绑定,是否消耗以下资源解除绑定?",self.SelectEquip.type==0 and "装备" or "守护")--,"<color=#FFD800FF>",_item.name,"</color>")
					local func=function ()
						if _item.count>=_consumeCfg.value then
							EquipmentModule.UnloadEquipment(self.SelectEquip.uuid)--选中装备解绑
							EquipmentModule.EquipmentItems(self.SelectEquip.uuid,self.heroId,self.Index, self.suits);	
						else
							showDlgError(nil, string.format("%s不足",_item.name))
						end
					end
				else		
					EquipmentModule.EquipmentItems(self.SelectEquip.uuid,self.heroId,self.Index, self.suits);
				end
			else
				showDlgError(nil,"未达到装备所需等级")
			end
		end
	end

	CS.UGUIClickEventListener.Get(self.view.sourceBtn.gameObject).onClick = function (obj) 	
		--sourceShow[SGK.LuaBehaviour]:Call("showGetSourceItem",nil)
	end

	CS.UGUIClickEventListener.Get(self.view.proprety.IdentificationBtn.gameObject).onClick = function (obj) 	
		self:InIdentification()
	end

	self.view.bottom.addBtn.Text[UI.Text].text=self.SelectEquip.type==0 and "强化" or "淬炼"
	if not openLevelCfg.GetStatus(self.SelectEquip.type==0 and 1121 or 1122) then
		if self.SelectEquip.type==0 then
			self.view.bottom.addBtn.Text[UI.Text].text=string.format("强化(%s级开启)",openLevelCfg.GetCfg(1121).open_lev)
		else
			self.view.bottom.addBtn.Text[UI.Text].text=string.format("淬炼(%s级开启)",openLevelCfg.GetCfg(1122).open_lev)
		end
	end

	--tabIdx==3--跳转至进阶或淬炼
	self.view.bottom.addBtn[CS.UGUIClickEventListener].interactable= openLevelCfg.GetStatus(self.SelectEquip.type==0 and 1121 or 1122)

	CS.UGUIClickEventListener.Get(self.view.bottom.addBtn.gameObject).onClick = function (obj)
		--showDlg(nil,"是否进入新版强化",function()
			DialogStack.PushPrefStact("newEquip/EquipAdvance",self.SelectEquip.uuid)
		-- end,function()
		-- 	self:addEquip()
		-- end)
	end
	module.guideModule.PlayByType(112, 0.3)
end

local QuenchingTab={}
function View:InitView()
	if self.uuid then
		self.SelectEquip=EquipmentModule.GetByUUID(self.uuid)
		self.currEquip=EquipmentModule.GetHeroEquip(self.heroId,self.Index,self.suits)
	else
		self.SelectEquip=EquipmentModule.GetHeroEquip(self.heroId,self.Index,self.suits)
	end

	if not self.SelectEquip then
		DialogStack.Pop()
		return
	end

	if utils.SGKTools.GameObject_null(self.root.view)==true then
		return
	end

	self.root.view.Title[UI.Text].text=SGK.Localize:getInstance():getValue(self.SelectEquip.type==0 and "biaoti_zhuangbeixinxi_01" or "biaoti_shouhuxinxi_01")

	self.root.mask.gameObject:SetActive(not not self.unShowBtn)
	self.view.top.info.changeBtn:SetActive(not self.unShowBtn)
	self.view.top.info.changeBtn.Text:TextFormat("{0}",(self.uuid and not self.currEquip) and "装备" or "更换")
	utils.IconFrameHelper.Create(self.view.top.IconFrame, {customCfg=self.SelectEquip});

	self.view.top.info.name[UI.Text].text = tostring(self.SelectEquip.cfg.name)
	self.view.top.info.name[UI.Text].color = ItemHelper.QualityColor(self.SelectEquip.cfg.quality)

	self.view.top.info.lv:SetActive(false)
	self.view.top.info.lv[UI.Text]:TextFormat("最低装备等级:{0}",self.SelectEquip.cfg.equip_level)
	
	self.view.top.info.score[UI.Text]:TextFormat("装备评分:{0}",self.SelectEquip.type==0 and tostring(Property(EquipmentModule.CaclPropertyByEq(self.SelectEquip)).calc_score) or tostring(Property(InscModule.CaclPropertyByInsc(self.SelectEquip)).calc_score))

	self.view.top.status:SetActive(self.SelectEquip.heroid ~= 0)
	if self.SelectEquip.heroid ~= 0 then
		local hero=HeroModule.GetManager():Get(self.SelectEquip.heroid)
		self.view.top.status.name[UI.Text]:TextFormat("{0}",hero.name)
		self.view.top.status.staticText[UI.Text].text=tostring(self.SelectEquip.isLock and "已绑定" or "已装备")
	end
	
	local _itemType = self.SelectEquip.type == 0 and utils.ItemHelper.TYPE.EQUIPMENT or utils.ItemHelper.TYPE.INSCRIPTION
	local _lock = EquipHelp.CheckEquipLockStatus(_itemType,self.SelectEquip.id,self.SelectEquip.uuid)
	self.view.top.lock[CS.UGUISpriteSelector].index = _lock and 1 or 0
	CS.UGUIClickEventListener.Get(self.view.top.lock.gameObject).onClick = function (obj) 
		local _index = self.view.top.lock[CS.UGUISpriteSelector].index
		self.view.top.lock[CS.UGUISpriteSelector].index = (_index +1)%2
		EquipHelp.ChangeEquipLockStatus(_itemType,self.SelectEquip.id,self.SelectEquip.uuid)
	end
	--是否显示I鉴定功能
	self:updateIdentification()

	self.view.desc.Text[UI.Text].text=tostring(self.SelectEquip.cfg.info)
	self:UpdateEquipProprety()
	self:UpdateEquipSuitDesc()

	self:upAddInfo()
	self.view.gameObject:SetActive(true)
end

function View:updateIdentification()
	local _status,cost_id,cost_value = CheckEquipScroll(self.SelectEquip)
	self.view.proprety.IdentificationBtn:SetActive(_status)
	if _status then
		self.view.proprety.IdentificationBtn.Image:SetActive(cost_id~=0 and cost_value ~= 0)
		if cost_id~=0 and cost_value ~= 0 then
			local _count = module.ItemModule.GetItemCount(cost_id)
			self.view.proprety.IdentificationBtn.Image.Text[UI.Text].text = string.format("%s%s</color>/%s",_count>=cost_value and "<color=#FFFFFFFF>" or "<color=#BC0000FF>",_count,cost_value)
		end
	end
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

local function SetBassAtt(type,propertyItem,_basePropretyTab,_addLvTab,i)
    if _basePropretyTab[i] then
        local cfg = ParameterConf.Get(_basePropretyTab[i].key)
        if cfg then
            if type == 0 then
                local _addLvValue = _addLvTab[_basePropretyTab[i].key] and _addLvTab[_basePropretyTab[i].key] or 0

                local _showAddLvValue = ParameterConf.GetPeropertyShowValue(_basePropretyTab[i].key,_addLvValue)
                local _showBaseValue = ParameterConf.GetPeropertyShowValue(_basePropretyTab[i].key,_basePropretyTab[i].allValue)
                -- local _showBaseValue = ParameterConf.GetPeropertyShowValue(_basePropretyTab[i].key,_basePropretyTab[i].allValue-_addLvValue)
                -- if _addLvValue ~= 0 then
                --     propertyItem.Text[UI.Text]:TextFormat("{0}:{1}(<color=#00A600FF>+{2}</color>)",cfg.name,_showBaseValue,_showAddLvValue)
                -- else
                --     propertyItem.Text[UI.Text]:TextFormat("{0}:{1}",cfg.name,_showBaseValue)
                -- end
                propertyItem.Text[UI.Text]:TextFormat("{0}:{1}",cfg.name,_showBaseValue)
            else
                local _showValue = ParameterConf.GetPeropertyShowValue(_basePropretyTab[i].key,_basePropretyTab[i].allValue)  
                propertyItem.Text[UI.Text]:TextFormat("{0}{1}{2}",cfg.name,cfg.rate ~= -1 and "+" or "",_showValue)
            end
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

local function SetAddAtt(type,propertyItem,_addPropretyTab,i,level)
	local cfg = ParameterConf.Get(_addPropretyTab[i].key)
	if _addPropretyTab[i].key~=0 and _addPropretyTab[i].allValue~=0 and cfg then
		if type == 0 then
			local _showValue = ParameterConf.GetPeropertyShowValue(_addPropretyTab[i].key,_addPropretyTab[i].allValue)    
			propertyItem.Text[UI.Text]:TextFormat("{0}:{1}",cfg.name,_showValue)
		else
			local _scroll = HeroScroll.GetScrollConfig(_addPropretyTab[i].scrollId)
			local _max = _scroll.max_value + _scroll.lev_max_value * (level - 1)
			local _showMax = ParameterConf.GetPeropertyShowValue(_addPropretyTab[i].key,_max)

			local _showValue=ParameterConf.GetPeropertyShowValue(_addPropretyTab[i].key,_addPropretyTab[i].allValue)
			propertyItem.Text[UI.Text]:TextFormat("{0}:{1}",cfg.name,_showValue)
			--propertyItem.TopText[UI.Text]:TextFormat("<color=#000000B2>{0}{1}</color>",TipCfg.GetAssistDescConfig(51001).info, _showMax)
		end
		local _, color =UnityEngine.ColorUtility.TryParseHtmlString('#D24A00FF');
		propertyItem.Text[UI.Text].color = color
	else
		ERROR_LOG("parameter cfg is nil or value ==0,key,allValue",_addPropretyTab[i].key,_addPropretyTab[i].allValue)
	end
end

---[==[
--装备属性开启等级Id
local commonLvId = {400,401,402,403}
function View:UpdateEquipProprety()
	local _tab,_basePropretyTab,_addLvTab = GetBassAtt(self.SelectEquip)
	for i=1, self.view.proprety.basePropretys.transform.childCount do
		self.view.proprety.basePropretys.transform:GetChild(i-1).gameObject:SetActive(false)
	end

	for i=1,#_basePropretyTab do
		local propertyItem = GetCopyUIItem(self.view.proprety.basePropretys,self.view.proprety.proprety,i)
		SetBassAtt(self.SelectEquip.type,propertyItem,_basePropretyTab,_addLvTab,i)
	end

	local _tab1,_addPropretyTab = GetAddAtt(self.SelectEquip)
	for i=1,self.view.proprety.addPropretys.transform.childCount do
		self.view.proprety.addPropretys.transform:GetChild(i-1).gameObject:SetActive(false)
	end

	for i=1,4 do
		local propertyItem = GetCopyUIItem(self.view.proprety.addPropretys,self.view.proprety.proprety,i)
		if _addPropretyTab[i] then
			SetAddAtt(self.SelectEquip.type,propertyItem,_addPropretyTab,i,self.SelectEquip.level)
		else
			if _tab1[i] and _tab1[i].key ==0 then
				local openCfg = CommonConfig.Get(commonLvId[i])
				propertyItem.Text[UI.Text].text = string.format("<color=#00000080>??????(强化至%s级解锁)</color>",openCfg.para1)
				propertyItem.TopText[UI.Text].text =""
			else
				propertyItem:SetActive(false)
			end
		end
	end

	local x=self.view[UnityEngine.RectTransform].rect.width
	local y=self.view.proprety.proprety[UnityEngine.RectTransform].sizeDelta.y
	self.view.proprety.basePropretys[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,#_basePropretyTab*y)
	self.view.proprety.addPropretys[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,4*y)
	
	local base_y = #_basePropretyTab>0 and self.view.proprety.basePropretys[UnityEngine.RectTransform].sizeDelta.y or 0
	local add_y = self.view.proprety.addPropretys[UnityEngine.RectTransform].sizeDelta.y
	
	self.view.proprety:SetActive(base_y+add_y>0)
	self.view.proprety[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,base_y+add_y+45)
	self.root.view[CS.UGUIFitHeight].baseHeight=self.SelectEquip.type==0 and 550 or 435
end--]==]

local EquipPosToIdx = {
    [1] = 1,
    [2] = 4,
    [3] = 2,
    [4] = 3,
    [5] = 5,
    [6] = 6
}

function View:UpdateEquipSuitDesc()
	self.view.suitDesc.gameObject:SetActive(self.SelectEquip.type==0)
	if self.SelectEquip.type~=0 then return end
	
	local suitCfg,_suitCfg=nil
	local _suitCfgHero=HeroModule.GetManager():GetEquipSuit(self.heroId)
	if _suitCfgHero and _suitCfgHero[self.SelectEquip.suits] and _suitCfgHero[self.SelectEquip.suits][self.SelectEquip.cfg.suit_id] then
		_suitCfg=_suitCfgHero[self.SelectEquip.suits][self.SelectEquip.cfg.suit_id]
	end

	if _suitCfg then
		local _activeNum=self.currEquip and (self.currEquip.cfg.suit_id~=self.SelectEquip.cfg.suit_id  and #_suitCfg.IdxList+1 or #_suitCfg.IdxList) or #_suitCfg.IdxList
		local _IdxList=self.currEquip and (self.currEquip.cfg.suit_id~=self.SelectEquip.cfg.suit_id and table.insert(_suitCfg.IdxList,EquipPosToIdx[self.Index-6]) or _suitCfg.IdxList) or _suitCfg.IdxList
		suitCfg=setmetatable({Desc={[2]=_suitCfg.Desc[1],[4]=_suitCfg.Desc[2],[6]=_suitCfg.Desc[3]},activeNum=_activeNum},{__index=_suitCfg})
	else
		_suitCfg = HeroScroll.GetSuitConfig(self.SelectEquip.cfg.suit_id)
		if _suitCfg then
			suitCfg = setmetatable({Desc={[2]=_suitCfg[2] and _suitCfg[2][self.SelectEquip.cfg.quality].desc,[4]=_suitCfg[4] and _suitCfg[4][self.SelectEquip.cfg.quality].desc,[6]=_suitCfg[6] and _suitCfg[6][self.SelectEquip.cfg.quality].desc},activeNum=1},{__index=_suitCfg})
		else
			ERROR_LOG("suitCfg is nil",self.SelectEquip.cfg.suit_id)
		end
	end

	self.view.suitDesc.Title.Text[UI.Text].text = suitCfg.name
	if suitCfg.activeNum>1 then
		if suitCfg and suitCfg.IdxList then
			local _tab={}
			for i=1,#suitCfg.IdxList do
				_tab[EquipPosToIdx[suitCfg.IdxList[i]]]=0
			end
			for i=1,self.view.suitDesc.suitIdx.transform.childCount do
				self.view.suitDesc.suitIdx[i][CS.UGUISpriteSelector].index =_tab[i] and _tab[i] or 1
			end
		else
			ERROR_LOG("suitCfg or suitCfg.IdxList is nil")
		end
	else
		for i=1,self.view.suitDesc.suitIdx.transform.childCount do
			self.view.suitDesc.suitIdx[i][CS.UGUISpriteSelector].index =i==EquipPosToIdx[self.Index-6] and 0 or 1
		end
	end
	for i=1,self.view.suitDesc.suitIdx.transform.childCount do
		self.view.suitDesc.suitIdx[i][UI.Image].color={r=1,g=1,b=1,a=1}
		self.view.suitDesc.suitIdx[i][UI.Image]:DOKill()
	end
	self.view.suitDesc.suitIdx[EquipPosToIdx[self.Index-6]][UI.Image]:DOColor({r=1,g=1,b=1,a=0.5},0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo)

	for i=1,self.view.suitDesc.descText.transform.childCount do
		self.view.suitDesc.descText[i]:SetActive(suitCfg.Desc[i*2])
		if suitCfg.Desc[i*2] then
			self.view.suitDesc.descText[i]:TextFormat("{0}[{1}]{2}{3}",suitCfg.activeNum>=i*2 and "<color=#00A600FF>" or "<color=#00000099>",i*2,suitCfg.Desc[i*2],"</color>")
		end
	end	
end

function View:upInscQuenchingInfo()
    local _needItem = {}
    for i,v in ipairs(self.SelectEquip.attribute) do
        local _scroll = HeroScroll.GetScrollConfig(v.scrollId)
        --ERROR_LOG(v.scrollId,_scroll.grow_cost_id,_scroll.grow_cost_id2)
        if _scroll then
            if not _needItem[_scroll.grow_cost_id] then
                _needItem[_scroll.grow_cost_id] = 0
            end
            if not _needItem[_scroll.grow_cost_id2] then
                _needItem[_scroll.grow_cost_id2] = 0
            end
            local _max = _scroll.max_value + _scroll.lev_max_value * (self.SelectEquip.level - 1)
            --ERROR_LOG(_scroll.grow_cost_value,_scroll.grow_cost_id)
            if v.allValue < _max then
                _needItem[_scroll.grow_cost_id] = _needItem[_scroll.grow_cost_id] + _scroll.grow_cost_value
                _needItem[_scroll.grow_cost_id2] = _needItem[_scroll.grow_cost_id2] + _scroll.grow_cost_value2
            end
        end
    end
    self.QuenchingItem = {}
    for k,v in pairs(_needItem) do
        if v ~= 0 then
            table.insert(self.QuenchingItem, {value = v, id = k})
        end
    end
end

function View:upAddInfo()
	if self.SelectEquip.type==0 then
		local _levelCfg = EquipConfig.EquipmentLevTab()[self.SelectEquip.cfg.id]
		local _cfg = nil
		if _levelCfg then
			_cfg = EquipConfig.GetCfgByColumnAndLv(_levelCfg.column,self.SelectEquip.level+1)
		else
			ERROR_LOG("_levelCfg is nil,id",self.SelectEquip.cfg.id)
		end
		--[[
		self.addLvItem=_cfg
		if _cfg then
			local cusumeCfg=ItemHelper.Get(_cfg.type,_cfg.id,nil,0)
			-- utils.IconFrameHelper.Create(self.view.bottom.addTip.IconFrame,{customCfg=cusumeCfg,showDetail = true,pos=2});
			-- local _count=module.ItemModule.GetItemCount(_cfg.id)
			-- self.view.bottom.addTip.num[UI.Text].text = string.format("%s%s</color>/%s",_count >= _cfg.value and "<color=#FFFFFF>" or "<color=#FF2625>",utils.SGKTools.ScientificNotation(_count),utils.SGKTools.ScientificNotation(_cfg.value))
		
			local _addLvCfg=EquipConfig.EquipmentLevTab()[self.SelectEquip.cfg.id]
			local tab={}
			local str=""

			for i=0,3 do
				if _addLvCfg["type"..i] and _addLvCfg["type"..i]~= 0 and _addLvCfg["value"..i]~=0 then
					if ParameterConf.Get(_addLvCfg["type"..i]) then
						str=string.format("%s\t%s:+%s",str,ParameterConf.Get(_addLvCfg["type"..i]).name,math.floor(_addLvCfg["value"..i]))
					else
						ERROR_LOG("ParameterConf is nil,id ",_addLvCfg["type"..i])
					end
				end
			end
			self.view.bottom.addTip.Text[UI.Text].text= string.format("<color=#00A600FF>%s</color>",str)
		end
		self.view.bottom.addTip:SetActive(not not _cfg)
		--]]

        self.view.bottom.addBtn:SetActive(not not _cfg)
	else
		self:upInscQuenchingInfo()
		local _cfg = self.QuenchingItem[1]
        if _cfg then
            local _itemCfg = ItemHelper.Get(ItemHelper.TYPE.ITEM, _cfg.id, nil, 0)
            utils.IconFrameHelper.Create(self.view.bottom.addTip.IconFrame,{customCfg=_itemCfg,showDetail = true,pos=2});
            local _value = _cfg.value
    
            local _count=module.ItemModule.GetItemCount(_cfg.id)
            self.view.bottom.addTip.num[UI.Text].text = string.format("%s%s/%s</color>",_count >= _cfg.value and "<color=#FFFFFF>" or "<color=#FF2625>",utils.SGKTools.ScientificNotation(_value),utils.SGKTools.ScientificNotation(_count))
        end
        self.view.bottom.addTip:SetActive(not not _cfg)
        self.view.bottom.addBtn:SetActive(not not _cfg)
        self.view.bottom.addTip.Text[UI.Text].text="随机属性"
	end
end

function View:addEquip()
	local count=1
	if self.SelectEquip.type==0 then
		if self.addLvItem then
			local _count=module.ItemModule.GetItemCount(self.addLvItem.id)
			if  self.SelectEquip.level< self.addLvItem.level then
				if self.addLvItem.value>_count then
					showDlgError(nil, "资源不足")
					return
				else
					EquipmentModule.LevelUp(self.SelectEquip.uuid,count)
				end
			end
		else
			showDlgError(nil, "当前已经进阶到最大值")
		end
	else
		-- if not self.changeFlag then
	    --     return
	    -- end
	    -- for i,v in ipairs(self.changeNumberList) do
	    --     local _nowNumber = EquipmentModule.GetAttribute(self.uuid)[v.key].allValue
	    --     v.number = _nowNumber
	    -- end

	    for i,v in ipairs(self.QuenchingItem) do
	        local _count = module.ItemModule.GetItemCount(v.id)
	        if _count < (v.value * count) then
	            showDlgError(nil, "资源不足")
	            return
	        end
	    end
	    for k,v in pairs(EquipmentModule.GetAttribute(self.SelectEquip.uuid)) do
	        local _scroll = HeroScroll.GetScrollConfig(v.scrollId)
	        local _max = _scroll.max_value + _scroll.lev_max_value * (self.SelectEquip.level - 1)
	        if v.allValue < _max then
	            EquipmentModule.Quenching(self.SelectEquip.uuid, count)
	            return
	        end
	    end
	    showDlgError(nil, "当前已经淬炼到最大值")
	end
end

--鉴定(刷新前缀)
function View:InIdentification()
	if self.SelectEquip.type == 0 then
		local _attribute = self.SelectEquip.attribute
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
									EquipmentModule.ChangeEquipScroll(self.SelectEquip.uuid,i)
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
					EquipmentModule.ChangeEquipScroll(self.SelectEquip.uuid,i)
				end
				break
			end
		end
	end
end

function View:UpEnsurePanel(tip,func,item1,count1,item2,count2)
	self.root.EnsurePanel.gameObject:SetActive(true)
	self.root.EnsurePanel.Dialog.Title[UI.Text].text="提示"

	self.root.EnsurePanel.Dialog.Content.tip[UI.Text].text=tip

	self.root.EnsurePanel.Dialog.Content.Content.Item1.gameObject:SetActive(not not item1)
   	if item1 then
		local ItemIconView = nil		
		if self.root.EnsurePanel.Dialog.Content.Content.Item1.transform.childCount == 0  then
			ItemIconView = IconFrameHelper.Item({id = item1.id,count = count1},self.root.EnsurePanel.Dialog.Content.Content.Item1)
		else
			ItemIconView =CS.SGK.UIReference.Setup(self.root.EnsurePanel.Dialog.Content.Content.Item1.transform:GetChild(0))
			IconFrameHelper.UpdateItem({id = item1.id,count = count1},ItemIconView)
		end
	end

	self.root.EnsurePanel.Dialog.Content.Content.Item2.gameObject:SetActive(not not item2 and item2.cfg.is_show==1)
	if item2 and item2.cfg.is_show==1 then
		local ItemIconView = nil		
		if self.root.EnsurePanel.Dialog.Content.Content.Item2.transform.childCount == 0  then
			ItemIconView = IconFrameHelper.Item({id = item2.id,count = count2},self.root.EnsurePanel.Dialog.Content.Content.Item2)
		else
			ItemIconView =CS.SGK.UIReference.Setup(self.root.EnsurePanel.Dialog.Content.Content.Item2.transform:GetChild(0))
			IconFrameHelper.UpdateItem({id = item2.id,count = count2},ItemIconView)
		end
	end

	CS.UGUIClickEventListener.Get(self.root.EnsurePanel.Dialog.Content.Btns.Ensure.gameObject).onClick = function (obj) 
		if func then
			func()
		end
		self.root.EnsurePanel.gameObject:SetActive(false)
	end
	CS.UGUIClickEventListener.Get(self.root.EnsurePanel.Dialog.Content.Btns.Cancel.gameObject).onClick = function (obj) 
		self.root.EnsurePanel.gameObject:SetActive(false)
	end
	CS.UGUIClickEventListener.Get(self.root.EnsurePanel.Dialog.Close.gameObject).onClick = function (obj) 
		self.root.EnsurePanel.gameObject:SetActive(false)
	end
	CS.UGUIClickEventListener.Get(self.root.EnsurePanel.gameObject).onClick = function (obj) 
		self.root.EnsurePanel.gameObject:SetActive(false)
	end
end

function View:playEffect(effectName,position,node,rotation,scale,layerName,sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName..".prefab");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        transform.localRotation = Quaternion.identity;
        transform.localScale = scale and scale*Vector3.one or Vector3.one
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

function View:OnDestroy()
	self.view=nil
end
function View:listEvent()
	return {
		"EQUIPMENT_INFO_CHANGE",
		"LOCAL_EQUIP_QUENCHING_OK",
		"LOCAL_EQUIP_LEVEL_UP_OK",
		"LOCAL_SELECT_EQUIPMENT_CHANGE",

		--"CLOSE_EQUIPINFO_FRAME",
		"LOCAL_NEWROLE_HEROIDX_CHANGE",
		"LOCAL _SCROLL_CHANGE",
		"LOCAL_GUIDE_CHANE",
		"ITEM_INFO_CHANGE",
	}
end

function View:onEvent(event,data)
	if event=="EQUIPMENT_INFO_CHANGE" then
		if not self.RefreshUI then		
			self.RefreshUI=true
			SGK.Action.DelayTime.Create(0.5):OnComplete(function()
				if self.view then		
					local equip=EquipmentModule.GetByUUID(self.uuid)
					if equip and equip.heroid and equip.heroid==self.heroId and (equip.type==0 and equip.localPlace-6==self.Index  or equip.localPlace==self.Index) then--穿装
						for i=#DialogStack.GetPref_stact(),1,-1 do
							if DialogStack.GetPref_stact()[i].name == "EquipCompareFrame(Clone)" 
							or	DialogStack.GetPref_stact()[i].name == "EquipChange(Clone)"
							or	DialogStack.GetPref_stact()[i].name == "EquipInfo(Clone)" then
								DialogStack.Pop()
							end
						end
					else
						self:InitView()
						self.RefreshUI=nil
					end
				end
			end)
		end
	elseif event ==	"LOCAL_NEWROLE_HEROIDX_CHANGE" then--"CLOSE_EQUIPINFO_FRAME" then
		--切换页签
		for i=#DialogStack.GetPref_stact(),1,-1 do
			if DialogStack.GetPref_stact()[i].name == "EquipCompareFrame(Clone)" 
			or	DialogStack.GetPref_stact()[i].name == "EquipChange(Clone)"
			or	DialogStack.GetPref_stact()[i].name == "EquipInfo(Clone)" then
				DialogStack.Pop()
			end
		end
	elseif event ==	"LOCAL_SELECT_EQUIPMENT_CHANGE" then--切换选中装备
		self:UpdateEquipDetail(data)
 	elseif event == "LOCAL_EQUIP_LEVEL_UP_OK" then
        showDlgError(nil, "进阶成功")
    elseif event == "LOCAL_EQUIP_QUENCHING_OK" then
    	showDlgError(nil, "淬炼成功")
  --   elseif event =="LOCAL_NEWROLE_HEROIDX_CHANGE" then
  --   	self.heroId=data and data.heroId
  --   	self.uuid=nil
		-- self:InitView()
	elseif event == "LOCAL _SCROLL_CHANGE" then
		local o = self:playEffect("fx_xp_up_1", Vector3.zero,self.view.top.IconFrame.gameObject,Vector3.zero,150,"UI",30000)  
		local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
		UnityEngine.Object.Destroy(o, _obj.main.duration)
	elseif event == "ITEM_INFO_CHANGE" then
		self:updateIdentification()
	elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(112, 0.3)
	end
end

return View;