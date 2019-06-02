local equipmentModule = require "module.equipmentModule";
local equipmentConfig = require "config.equipmentConfig"
local HeroModule = require "module.HeroModule"
local ParameterConf = require "config.ParameterShowInfo"
local InscModule = require "module.InscModule"
local EquipHelp = require "module.EquipHelp"
local ItemHelper = require "utils.ItemHelper"
local Property = require "utils.Property"
local ParameterConf = require "config.ParameterShowInfo"

local View = {}

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view.Content
 	self.EquipSuitUITab = {}
 	self.equipUITab = {}

 	self.suitDescUITab={}
 	self.suitsPropretyUITab={}
 	self.suitsOtherPropretyUITab={}

 	self:InitView(data)
end

local suitCount=3--套装方案开放数量
function View:InitView(data)
	self.heroId = data and data.heroid or 11000
	self.state=data and data.state or false

	self.root.view.Title[UI.Text].text=SGK.Localize:getInstance():getValue(self.state and "biaoti_bingzhuangku_01" or "biaoti_baoshiji_01")


	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function()
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.root.view.Close.gameObject).onClick = function()
		DialogStack.Pop()
	end
	self:updateSuitsShow()
	self:UpdateSuitsProperty()
end

function View:UpdateSuitsProperty()
	
	local proprety=self.view.Bottom.proprety

	local hero=HeroModule.GetManager():Get(self.heroId)

	local propertyTab={}
	if self.state then
		propertyTab=equipmentModule.CaclProperty(hero,true)
	else
		propertyTab=InscModule.CaclProperty(hero)
	end

	local _propertyTab={{},{}}
	for k,v in pairs(propertyTab) do
		if k~=0 then
			local cfg=ParameterConf.Get(k)
			if cfg then
				if cfg.icon~="" then
					table.insert(_propertyTab[1],{key=k,value=v,name=cfg.name,icon=cfg.icon})
				else
					table.insert(_propertyTab[2],{key=k,value=v,name=cfg.name})
				end
			end
		end
	end
	self:UpdatePropretyShow(_propertyTab)			
end

local _staticEquip = "bingzhuangku_zhuangbei01"
local _staticInsc = "baoshiji_baoshi01"
local NoEquipSuitsTip = "bingzhuangku_zhuangbei04"
local NoInscSuitsTip = "baoshiji_baoshi04"
function View:UpdatePropretyShow(tab)
	self.view.Bottom.NoPropretyTip.gameObject:SetActive(next(tab[1])==nil and next(tab[2])==nil)
	self.view.Bottom.NoPropretyTip[UI.Text].text = SGK.Localize:getInstance():getValue(self.state and NoEquipSuitsTip or NoInscSuitsTip)

	for k,v in pairs(self.suitsPropretyUITab) do
		v.gameObject:SetActive(false)
	end
	for k,v in pairs(self.suitsOtherPropretyUITab) do
		v.gameObject:SetActive(false)
	end
	local propretyPanel = self.view.Bottom.propretyContent.Viewport.Content
	local prefab1 = propretyPanel.proprety.propretyItem
	local prefab2 = propretyPanel.proprety.others.propretyItem

	local _propertyCount = 0
	if next(tab[1])~=nil then
		_propertyCount = math.ceil(#tab[1]/2)
		for i=1,_propertyCount do
			local _tab = tab[1]
			table.sort(_tab,function (a,b)
				return a.key<b.key
			end)
			local propertyItem
			propertyItem,self.suitsPropretyUITab = self:InCopyUIPrefab(self.suitsPropretyUITab,propretyPanel.proprety,prefab1,i)
			
			for addIdx=1,2 do
				local _Idx = (i-1)*2+addIdx
				propertyItem[addIdx]:SetActive(_tab[_Idx])
				if _tab[_Idx] then
					propertyItem[addIdx].key[UI.Text].text = string.format("%s ",_tab[_Idx].name)
					local _showValue = ParameterConf.GetPeropertyShowValue(_tab[_Idx].key,_tab[_Idx].value)
					propertyItem[addIdx].value[UI.Text].text=tostring(_showValue)
					propertyItem[addIdx].Image[UI.Image]:LoadSprite("propertyIcon/" .._tab[_Idx].icon)
				end
			end
		end
	end

	local _othersPropertyCount = 0
	if next(tab[2])~=nil then
		_othersPropertyCount = math.ceil(#tab[2]/2)
		local _tab = tab[2]
		table.sort(_tab,function (a,b)
			return a.key<b.key
		end)
		for i=1,_othersPropertyCount do	
			local propertyItem 
			propertyItem,self.suitsOtherPropretyUITab = self:InCopyUIPrefab(self.suitsOtherPropretyUITab,propretyPanel.proprety.others,prefab2,i)
			for addIdx=1,2 do
				local _Idx = (i-1)*2+addIdx
				propertyItem[addIdx]:SetActive(_tab[_Idx])
				if _tab[_Idx] then
					propertyItem[addIdx].key[UI.Text].text = string.format("%s ",_tab[_Idx].name)
					local _showValue = ParameterConf.GetPeropertyShowValue(_tab[_Idx].key,_tab[_Idx].value)
					propertyItem[addIdx].value[UI.Text].text=tostring(_showValue)
				end
			end
		end
	end

	local _CellHeight = prefab1[CS.UnityEngine.RectTransform].rect.height

	local _othersHeight = _CellHeight*_othersPropertyCount
	propretyPanel.proprety.others[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,_othersHeight);
	
	propretyPanel.proprety[CS.UGUIFitHeight].baseHeight =  _CellHeight*_propertyCount +20
	propretyPanel.proprety[UnityEngine.UI.VerticalLayoutGroup].padding.bottom = _othersHeight
end
---[[
function View:updateSuitsShow()
	for i=1,suitCount do
		local suit=nil
		suit,self.EquipSuitUITab=self:InCopyUIPrefab(self.EquipSuitUITab,self.view.suitContent.Viewport.Content,self.view.suitContent.Viewport.Content.suit,i)
		self:updateSuitEquip(i)
	end
end

local roleEquipIdx = {[1] = 1,[2] = 3,[3] = 4,[4] = 2,[5] = 5,[6] = 6}
local roleInseIdx = {[1] = 1,[2] = 2,[3] = 3,[4] = 4,[5] = 5,[6] = 6}
local euqipSuitsName = {"bingzhuangku_zhuangbei01","bingzhuangku_zhuangbei02","bingzhuangku_zhuangbei03"}
local inscSuitsName = {"baoshiji_baoshi01","baoshiji_baoshi02","baoshiji_baoshi03"}
function View:updateSuitEquip(Idx)
	local suit=CS.SGK.UIReference.Setup(self.EquipSuitUITab[Idx])
	local suitIdx=Idx-1
	self.equipUITab[Idx]=self.equipUITab[Idx] or {}
	local _scoreValue=0
	for j=1,6 do--装备位置
		local showIdx=self.state and roleEquipIdx[j] or roleInseIdx[j]
		local equipItem=nil
		local pos=suit.equipsContent
		equipItem,self.equipUITab[Idx]=self:InCopyUIPrefab(self.equipUITab[Idx],pos,pos.equip,showIdx)

		local equip=equipmentModule.GetHeroEquip(self.heroId,self.state and showIdx+6 or showIdx,suitIdx)
		
		local equiIsOpen,equipOpenLv,shortLv = equipmentConfig.GetEquipOpenLevel(suitIdx,self.state and showIdx+6 or showIdx)--套装 位置
	
		equipItem.equipLock.gameObject:SetActive(not equiIsOpen)
		if not equiIsOpen then
			equipItem.equipLock.Image:SetActive(not shortLv)
			equipItem.equipLock.Text:SetActive(not not shortLv)
			if shortLv then
				equipItem.equipLock.Text[UI.Text].text=string.format("Lv%s",equipOpenLv)
			else
				equipItem.equipLock.Image.Text[UI.Text].text=string.format("X%s",equipOpenLv)
			end
		end

		equipItem.equipIcon.IconFrame.gameObject:SetActive(not not equip)
		
		if equip then
			utils.IconFrameHelper.Create(equipItem.equipIcon.IconFrame,{customCfg=equip})
			local _score=self.state and Property(equipmentModule.CaclPropertyByEq(equip)).calc_score or Property(InscModule.CaclPropertyByInsc(equip)).calc_score
			_scoreValue=_scoreValue+tonumber(_score)
		end

		CS.UGUIClickEventListener.Get(equipItem.equipLock.gameObject,true).onClick = function()
			if shortLv then
				showDlgError(nil,SGK.Localize:getInstance():getValue("huoban_zhuangbei_03")..SGK.Localize:getInstance():getValue("tips_lv_02",equipOpenLv))
			else
				showDlgError(nil,SGK.Localize:getInstance():getValue("equip_open_tips",equipOpenLv))
			end
		end

		CS.UGUIClickEventListener.Get(equipItem.equipIcon.gameObject).onClick = function()
			if equip  then
				DialogStack.PushPrefStact("newEquip/EquipInfo", {roleID = self.heroId, suits = suitIdx, index = self.state and showIdx+6 or showIdx , state = self.state})
			else
				DialogStack.PushPrefStact("newEquip/EquipChange", {heroId= self.heroId, suits =suitIdx,state =self.state, index =self.state and showIdx+6 or showIdx })
			end
		end
	end

	suit.top.name[UI.Text].text = SGK.Localize:getInstance():getValue(self.state and euqipSuitsName[Idx] or inscSuitsName[Idx])
	suit.top.tip[UI.Text]:TextFormat("<color=#FFD800FF>提供{0}%属性</color>",Idx==1 and "100" or (self.state and equipmentConfig.GetOtherSuitsCfg().Eq*100 or equipmentConfig.GetOtherSuitsCfg().In*100))
	suit.top.score[UI.Text]:TextFormat("<color=#FFD800FF>{0}</color>",_scoreValue)
end

function View:QuickLevelUp(Idx)
	local suitIdx=Equip_Suit_data[self.state and 0 or 1][self.heroId][Idx].SuitIdx

	local allLevelUp=false
	local noEquip=false
	local _heroLevel = HeroModule.GetManager():Get(11000).level
	for i = 1,6 do
		local _cfg = equipmentModule.GetHeroEquip(self.heroId,self.state and i+6 or i,suitIdx)
		if _cfg and _cfg.uuid then
			if _cfg.level< _heroLevel then
				allLevelUp=true
			end
			noEquip=true
		end
	end

	if allLevelUp then
		EquipHelp.QuickLevelUp(self.heroId,suitIdx,self.state and 0 or 1)
		self.localQuickLevelUp=true
	elseif not noEquip then
		showDlgError(nil,string.format("请先安装%s",SGK.Localize:getInstance():getValue(self.state and _staticEquip or _staticInsc)))
	else
		showDlgError(nil,string.format("所有%s已达到当前最大等级",SGK.Localize:getInstance():getValue(self.state and _staticEquip or _staticInsc)))	
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
	local item=CS.SGK.UIReference.Setup(_obj)
	return item,UITab
end

function View:listEvent()
	return {
		"LOCAL_EQUIP_LEVEL_UP_OK",
		"LOCAL_EQUIP_QUICKLEVEL_ERROR",
		"EQUIPMENT_INFO_CHANGE",
	}
end

function View:onEvent(event, data)
	if event == "EQUIPMENT_INFO_CHANGE" then
		if not self.DonRefUIShow then
			self.DonRefUIShow=true
			self.view.transform:DOScale(Vector3.one, 0.5):OnComplete(function()
				self:UpdateSuitsProperty()
				self:updateSuitsShow()
				self.DonRefUIShow=false
			end)
		end
	elseif event == "LOCAL_EQUIP_QUICKLEVEL_ERROR" then
		local item=ItemHelper.Get(41,self.state and 90002 or equipmentConfig.EquipLeveUpTab(1).id)
		showDlgError(nil,item.name.."不足")
		self:updateSuitsShow()
	elseif event == "LOCAL_EQUIP_LEVEL_UP_OK" then
		if self.localQuickLevelUp then
			self.localQuickLevelUp=false
			if not self.canShow then
				self.canShow=true
				showDlgError(nil,"强化成功")
				self.view.transform:DOScale(Vector3.one,1):OnComplete(function()
					self.canShow=false
				end)
			end
		end
	end
end
--]]
return View;
