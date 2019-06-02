local EquipmentModule = require "module.equipmentModule";
local EquipConfig = require "config.equipmentConfig"
local HeroScroll = require "hero.HeroScroll"
local ItemHelper = require "utils.ItemHelper"
local HeroModule = require "module.HeroModule"
local ParameterConf = require "config.ParameterShowInfo"
local Property = require "utils.Property"
local InscModule = require "module.InscModule"
local IconFrameHelper = require "utils.IconFrameHelper"
local openLevelCfg = require "config.openLevel"
local EquipHelp = require "module.EquipHelp"

local View = {}
function View:Start(data)
	self.root=SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view.Content
	self.root.view.gameObject:SetActive(false)
	self.propretyUITab={}
	
	self:UpdateEquipDetail(data)
	self:SetCallback()
end

function View:UpdateEquipDetail(data)
	self.SelectEquip=data and data.equip
	self.Index=data and data.idx or 1
	self.heroId=data and data.heroId
	self.suits=data and data.suits

	self.equip=EquipmentModule.GetHeroEquip(self.heroId,self.Index,self.suits)
	self:InitView()
end

function View:SetCallback()
	CS.UGUIClickEventListener.Get(self.root.view.Close.gameObject).onClick = function (obj)
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end

	CS.UGUIClickEventListener.Get(self.view.top.decomposeBtn.gameObject).onClick = function (obj)
		EquipmentModule.Decompose(self.SelectEquip.uuid)
	end

	CS.UGUIClickEventListener.Get(self.view.bottom.ChangeBtn.gameObject).onClick = function (obj)
		local heroLv=module.HeroModule.GetManager():Get(self.heroId).level
		if self.SelectEquip.cfg.equip_level<= heroLv then
			local _consumeCfg=EquipConfig.ChangePrice(self.SelectEquip.type,self.SelectEquip.quality)
			local _item=ItemHelper.Get(_consumeCfg.type,_consumeCfg.id)
		
			if _consumeCfg.value>0 and self.SelectEquip.heroid~=0 and self.SelectEquip.heroid ~=self.heroId then
				local tip=string.format("当前%s已和其他伙伴绑定,是否消耗以下资源解除绑定?",self.SelectEquip.type==0 and "装备" or "守护")--,"<color=#FFD800FF>",_item.name,"</color>")
				local func=function ()
					if _item.count>=_consumeCfg.value then
						EquipmentModule.UnloadEquipment(self.SelectEquip.uuid)--选中装备解绑
						if self.equip then
							EquipmentModule.UnloadEquipment(self.equip.uuid)--选中装备解绑
						end
						EquipmentModule.EquipmentItems(self.SelectEquip.uuid,self.heroId,self.Index, self.suits);	
					else
						showDlgError(nil, string.format("%s不足",_item.name))
					end
				end
				self:UpEnsurePanel(tip,func,_item,_consumeCfg.value)
			else		
				if self.equip then
					EquipmentModule.UnloadEquipment(self.equip.uuid)--选中装备解绑
				end
				EquipmentModule.EquipmentItems(self.SelectEquip.uuid,self.heroId,self.Index, self.suits);
			end
		else
			showDlgError(nil,"未达到装备所需等级")
		end
	end
end

function View:InitView()
	if not self.SelectEquip then return end

	self.root.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue(self.SelectEquip.type==0 and "biaoti_zhuangbeixinxi_01" or "biaoti_shouhuxinxi_01")

	self.view.bottom.ChangeBtn.Text:TextFormat("{0}",not self.equip and "装备" or "更换")
	utils.IconFrameHelper.Create(self.view.top.IconFrame, {customCfg=self.SelectEquip});

	self.view.top.info.name[UI.Text].text = tostring(self.SelectEquip.cfg.name)
	self.view.top.info.name[UI.Text].color = ItemHelper.QualityColor(self.SelectEquip.cfg.quality)
	
	self.view.top.info.lv:SetActive(false)
	self.view.top.info.lv[UI.Text]:TextFormat("最低装备等级:{0}",self.SelectEquip.cfg.equip_level)
	self.view.top.info.score[UI.Text]:TextFormat("装备评分:{0}",self.SelectEquip.type==0 and tostring(Property(EquipmentModule.CaclPropertyByEq(self.SelectEquip)).calc_score) or tostring(Property(InscModule.CaclPropertyByInsc(self.SelectEquip)).calc_score))
	self.view.top.status:SetActive(self.SelectEquip.heroid ~= 0)
	if self.SelectEquip.heroid ~= 0 then
		local hero=HeroModule.GetManager():Get(self.SelectEquip.heroid)
		self.view.top.status.name[UI.Text].text=tostring(hero.name)
		self.view.top.status.staticText[UI.Text].text=tostring(self.SelectEquip.isLock and "已绑定" or "已装备")
	end
	self.view.desc.Text[UI.Text].text=tostring(self.SelectEquip.cfg.info)

	local _itemType = self.SelectEquip.type == 0 and utils.ItemHelper.TYPE.EQUIPMENT or utils.ItemHelper.TYPE.INSCRIPTION
	local _lock = EquipHelp.CheckEquipLockStatus(_itemType,self.SelectEquip.id,self.SelectEquip.uuid)
	self.view.top.lock[CS.UGUISpriteSelector].index = _lock and 1 or 0
	CS.UGUIClickEventListener.Get(self.view.top.lock.gameObject).onClick = function (obj) 
		local _index = self.view.top.lock[CS.UGUISpriteSelector].index
		self.view.top.lock[CS.UGUISpriteSelector].index = (_index +1)%2
		EquipHelp.ChangeEquipLockStatus(_itemType,self.SelectEquip.id,self.SelectEquip.uuid)
	end

	self:UpdateEquipProprety()
	self:UpdateEquipSuitDesc()

	local currLv= module.HeroModule.GetManager():Get(self.heroId).level
	self.view.bottom.ChangeBtn:SetActive(self.SelectEquip.cfg.equip_level<=currLv)
	self.view.bottom.tip:SetActive(self.SelectEquip.cfg.equip_level>currLv)
	if self.SelectEquip.cfg.equip_level>currLv then
		self.view.bottom.tip[UI.Text]:TextFormat("{0}最低装备等级{1}(当前{2}级)</color>","<color=#FF1A1AFF>",self.SelectEquip.cfg.equip_level,currLv)
	end

	--self.view.top.decomposeBtn:SetActive(self.SelectEquip.heroid == 0)

	local currCapacity=self.equip and module.EquipHelp.GetInscAddScore(self.heroId, self.equip.uuid) or 0
	local capacity=module.EquipHelp.GetInscAddScore(self.heroId, self.SelectEquip.uuid)
	self.view.bottom.Capacity:SetActive(capacity~=currCapacity)
	self.view.bottom.Capacity.Text:TextFormat("{0}{1}{2}</color>",capacity-currCapacity>0 and "<color=#0CFF00FF>" or "<color=#FF1A1AFF>",capacity-currCapacity>0 and "+" or "",capacity-currCapacity)

	self.root.view.gameObject:SetActive(true)
end

function View:UpdateEquipProprety()
	local basePropertyTab={{},{}}
	local addPropertyTab={{},{}}

	local baseShowpropertyTab={}
	local addShowpropertyTab={}
	if self.equip then
		local _tab=EquipmentModule.GetEquipBaseAtt(self.equip.uuid)
		local _basePropretyTab=self:GetPropretyShowValue(_tab)
		
		local _tab1=EquipmentModule.GetAttribute(self.equip.uuid)
		local _addPropretyTab=self:GetPropretyShowValue(_tab1)

		for i,v in ipairs(_basePropretyTab) do
			if v.key~=0 and v.allValue~=0 then
				basePropertyTab[1][v.key]=-v.allValue
				baseShowpropertyTab[v.key]=-v.allValue
			end
		end

		for i,v in ipairs(_addPropretyTab) do
			if v.key~=0 and v.allValue~=0 then
				addPropertyTab[1][v.key]=-v.allValue
				addShowpropertyTab[v.key]=-v.allValue
			end
		end		
	end

	local __tab=EquipmentModule.GetEquipBaseAtt(self.SelectEquip.uuid)
	local _SelectBasePropretyTab=self:GetPropretyShowValue(__tab)

	local __tab1=EquipmentModule.GetAttribute(self.SelectEquip.uuid)
	local _SelectAddPropretyTab=self:GetPropretyShowValue(__tab1)
	for i,v in ipairs(_SelectBasePropretyTab) do
		if v.key~=0 and v.allValue~=0 then
			basePropertyTab[2][v.key]=math.floor(v.allValue)
			baseShowpropertyTab[v.key]=math.floor(v.allValue)
		end
	end

	for i,v in ipairs(_SelectAddPropretyTab) do
		if v.key~=0 and v.allValue~=0 then
			addPropertyTab[2][v.key]=math.floor(v.allValue)
			addShowpropertyTab[v.key]=math.floor(v.allValue)
		end
	end

	for k,v in pairs(self.propretyUITab) do
		v.gameObject:SetActive(false)
	end

	local _baseCount=self:RefBasePropretyValue(baseShowpropertyTab,basePropertyTab,self.view.proprety.basePropretys,true)
	local _addCount=self:RefBasePropretyValue(addShowpropertyTab,addPropertyTab,self.view.proprety.addPropretys)
	
	self.view.proprety.basePropretys:SetActive(_baseCount>0)
	self.view.proprety.addPropretys:SetActive(_addCount>0)
	
	local y = self.view.proprety.proprety[UnityEngine.RectTransform].sizeDelta.y
	self.view.proprety.basePropretys[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,_baseCount*y)
	self.view.proprety.addPropretys[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,_addCount*y)
	
	local base_y=_baseCount>0 and self.view.proprety.basePropretys[UnityEngine.RectTransform].sizeDelta.y or 0
	local add_y=_addCount>0 and self.view.proprety.addPropretys[UnityEngine.RectTransform].sizeDelta.y or 0
	
	self.view.proprety:SetActive(base_y+add_y>0)
	self.view.proprety[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical, base_y+add_y+45)
	self.root.view[CS.UGUIFitHeight].baseHeight=self.SelectEquip.type==0 and 670 or 555
end

function View:RefBasePropretyValue(showTab,Tab,childRoot,IsBase)
	local comTab={}

	local AddTab={}
	local SubTab={}
	for k,v in pairs(showTab) do
		if Tab[2] and Tab[2][k] and Tab[1] and Tab[1][k] then--变化属性
			local _difValue=Tab[1][k]+Tab[2][k]
			local _mark=_difValue>0 and "+" or ""
			local _difColor=_difValue>0 and "<color=#00A600FF>" or "<color=#BC0000FF>"
			table.insert(comTab,{key=k,value=Tab[2][k],difValue=_difValue,valueColor=IsBase and "<color=#000000FF>" or "<color=#D24A00FF>",mark=_mark,difColor=_difColor,valueMark=""})
			--table.insert(comTab,{key=k,value=Tab[2][k],difValue=_difValue,valueColor="<color=#000000FF>",mark=_mark,difColor=_difColor,valueMark=""})
		elseif (Tab[2] and Tab[2][k] and not Tab[1]) or  (Tab[2] and Tab[2][k] and Tab[1] and not Tab[1][k]) then--新增属性
			table.insert(AddTab,{key=k,value=Tab[2][k],difValue=0,valueColor="<color=#00A600FF>",valueMark="+"})
		elseif (Tab[1] and Tab[1][k] and not Tab[2]) or  (Tab[1] and Tab[1][k] and Tab[2] and not Tab[2][k]) then--减少属性
			table.insert(SubTab,{key=k,value=Tab[1][k],difValue=0,valueColor="<color=#BC0000FF>",valueMark="-"})
		end
	end
	table.sort(comTab,function (a,b)
		local IsNoChange_a=a.difValue==0
		local IsNoChange_b=b.difValue==0
		if IsNoChange_a~= IsNoChange_b then
			return IsNoChange_a
		end
		return a.difValue >b.difValue
	end)
	for i=1,#AddTab do
		table.insert(comTab,AddTab[i])
	end
	for i=1,#SubTab do
		table.insert(comTab,SubTab[i])
	end

	for i=1,#comTab do
		local propertyItem=nil
		propertyItem,self.propretyUITab=self:InCopyUIPrefab(self.propretyUITab,childRoot,self.view.proprety.proprety,IsBase and i or 10+i)
		
		local cfg=ParameterConf.Get(comTab[i].key)
		if cfg then
			propertyItem.Text[UI.Text].text=string.format("%s%s:</color>",comTab[i].valueColor,cfg.name)

			local _value=ParameterConf.GetPeropertyShowValue(comTab[i].key,math.abs(comTab[i].value))
			if comTab[i].difValue~=0 then
				local _dif=ParameterConf.GetPeropertyShowValue(comTab[i].key,comTab[i].difValue)
				propertyItem.Text.Text.Text[UI.Text].text=string.format("(%s%s%s</color>)",comTab[i].difColor,comTab[i].mark,_dif)
			else	
				propertyItem.Text.Text.Text[UI.Text].text=""
			end
			propertyItem.Text.Text[UI.Text].text=string.format("%s%s%s</color>",comTab[i].valueColor,comTab[i].valueMark,_value)
		end
	end
	return #comTab
end

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
	
	local suitCfg=nil
	local _suitCfg=nil
	local _suitCfgHero=HeroModule.GetManager():GetEquipSuit(self.heroId)
	if _suitCfgHero  and _suitCfgHero[self.SelectEquip.suits] and _suitCfgHero[self.SelectEquip.suits][self.SelectEquip.cfg.suit_id] then
		_suitCfg=_suitCfgHero[self.SelectEquip.suits][self.SelectEquip.cfg.suit_id]
	end

	if _suitCfg then
		--跟当前位置装备 激活的时候是同一套装
		local _activeNum=self.equip and self.equip.cfg.suit_id==self.SelectEquip.cfg.suit_id and #_suitCfg.IdxList or #_suitCfg.IdxList+1
		local _IdxList=self.equip and self.equip.cfg.suit_id==self.SelectEquip.cfg.suit_id and _suitCfg.IdxList or table.insert(_suitCfg.IdxList,self.Index-6)
		suitCfg=setmetatable({Desc={[2]=_suitCfg.Desc[1],[4]=_suitCfg.Desc[2],[6]=_suitCfg.Desc[3]},activeNum=_activeNum,IdxList=_IdxList},{__index=_suitCfg})
	else
		_suitCfg = HeroScroll.GetSuitConfig(self.SelectEquip.cfg.suit_id)
		suitCfg=setmetatable({Desc={[2]=_suitCfg[2] and _suitCfg[2][self.SelectEquip.cfg.quality].desc,[4]=_suitCfg[4] and _suitCfg[4][self.SelectEquip.cfg.quality].desc,[6]=_suitCfg[6] and _suitCfg[6][self.SelectEquip.cfg.quality].desc},activeNum=1},{__index=_suitCfg[4] and _suitCfg[4][self.SelectEquip.cfg.quality]})
	end

	self.view.suitDesc.Title.Text[UI.Text].text=suitCfg.name
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

	self.view.suitDesc.suitIdx[EquipPosToIdx[self.Index-6]][CS.DG.Tweening.DOTweenAnimation].tween:Play()
	
	for i=1,self.view.suitDesc.descText.transform.childCount do
		self.view.suitDesc.descText[i]:SetActive(suitCfg.Desc[i*2])
		if suitCfg.Desc[i*2] then
			self.view.suitDesc.descText[i]:TextFormat("{0}[{1}]{2}{3}",suitCfg.activeNum>=i*2 and "<color=#00A600FF>" or "<color=#00000099>",i*2,suitCfg.Desc[i*2],"</color>")
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

function View:InCopyUIPrefab(UITab,pos,prefab,k)
	local _obj=nil
	if UITab[k]==nil then
		_obj=UnityEngine.Object.Instantiate(prefab.gameObject)
		_obj.transform:SetParent(pos.gameObject.transform,false)
		_obj.name=tostring(k)
		UITab[k]=_obj
	else
		_obj=UITab[k]
	end
	_obj.gameObject:SetActive(true)
	local item=CS.SGK.UIReference.Setup(_obj.transform)	
	return item,UITab
end

function View:GetPropretyShowValue(_tab,showTab)
	local tab,showTab={},{}
	for i=1,#_tab do
		if _tab[i].key~=0 and _tab[i].allValue~=0 then 
			tab[_tab[i].key]={value=tab[_tab[i].key] and tab[_tab[i].key].value or 0,scrollId=_tab[i].scrollId}
			tab[_tab[i].key].value=tab[_tab[i].key].value+_tab[i].allValue
		end
	end
	for k,v in pairs(tab) do
		table.insert(showTab,{key=k,allValue=v.value,scrollId=v.scrollId})
	end
	return showTab
end		

function View:listEvent()
	return {
		"EQUIPMENT_INFO_CHANGE",
		"LOCAL_DECOMPOSE_OK",
	}
end

function View:onEvent(event,data)
	if event=="EQUIPMENT_INFO_CHANGE" then
		self.SelectEquip=EquipmentModule.GetByUUID(self.SelectEquip.uuid)
		if self.SelectEquip and self.SelectEquip.heroid and self.SelectEquip.heroid==self.heroId and (self.SelectEquip.type==0 and self.SelectEquip.localPlace-6==self.Index  or self.SelectEquip.localPlace==self.Index) then--穿装
			for i=#DialogStack.GetPref_stact(),1,-1 do
				if DialogStack.GetPref_stact()[i] and utils.SGKTools.GameObject_null(DialogStack.GetPref_stact()[i])~=true then
					if DialogStack.GetPref_stact()[i].name == "EquipCompareFrame(Clone)" 
					or DialogStack.GetPref_stact()[i].name == "EquipChange(Clone)"
					or DialogStack.GetPref_stact()[i].name == "EquipInfo(Clone)" then
						DialogStack.Pop()
					end
				end
			end
		else
			self:InitView()
		end
	elseif event=="LOCAL_DECOMPOSE_OK"  then--摧毁
		DialogStack.Pop()
	end
end

return View;