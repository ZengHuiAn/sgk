local HeroScroll = require "hero.HeroScroll"
local EquipHelp = require "module.EquipHelp"
local HeroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local EquipmentModule = require "module.equipmentModule";
local EquipmentConfig = require "config.equipmentConfig"
local EquipRecommend = require "module.EquipRecommend"

local InscModule = require "module.InscModule"
local ParameterConf = require "config.ParameterShowInfo"
local Property = require "utils.Property"
local DataBoxModule = require "module.DataBoxModule"

local View = {}
local ScrollViewOriginalHeight = 0
local FifterScrollViewOriginalHeight = 0
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view;
	self:Init(data);
	
	module.guideModule.PlayByType(111, 0.3)
end

local tabsName = {"套装","部件"}
local euqipSuitsName = {"bingzhuangku_zhuangbei01","bingzhuangku_zhuangbei02","bingzhuangku_zhuangbei03"}
local inscSuitsName = {"baoshiji_baoshi01","baoshiji_baoshi02","baoshiji_baoshi03"}
local propertySortList = {"等级","品质",1002,1302,1502,1013,1313,1513,1201,1202,1203,1211}
local suitsList = {}
function View:Init(data)
	suitsList = HeroScroll.GetSuitsList()
	if not self.suitFifter then
		self.suitFifter = {list = {},tab = {}}
		local equipList = EquipmentModule.GetEquip()
		for k,v in pairs(equipList) do
			if not self.suitFifter.tab[v.cfg.suit_id] then
				self.suitFifter.tab[v.cfg.suit_id] = true
				table.insert(self.suitFifter.list,v.cfg.suit_id)
			end
		end

		table.sort(self.suitFifter.list,function (a,b)
			local a_quality = HeroScroll.GetSuitCfg(a) and HeroScroll.GetSuitCfg(a).quality or 0
			local b_quality = HeroScroll.GetSuitCfg(b) and HeroScroll.GetSuitCfg(b).quality or 0
			if a_quality ~= b_quality then
				return a_quality > b_quality
			end
			return a < b
		end)
	end

	self.state = data and data.state or self.savedValues.State--装备还是铭文
	self.EquipBarIdx = data and data.suits --装备栏Idx
	self.PlaceIdx = data and data.index  --装备位置 
	self.selectSuitIdx = nil --筛选套装
	self.fifterIdx = 1 --常规属性筛选
	self.EquipState = false; --穿戴状态筛选
	self.PageIdx = self.PlaceIdx and 2 or 1; --页签

	local heroId = data and data.heroId or 11000
	self:UpdateHeroInfo(heroId)

	self:SetCallback();
	self:InPageChange(self.PageIdx)
end

local EQUIP_SELECT = {SUIT=1,PROPERTY=2}
local roleEquipIdx = {[1] = 1,[2] = 3,[3] = 4,[4] = 2,[5] = 5,[6] = 6}
function View:SetCallback()
	CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"),self.root.transform)

	DispatchEvent("CurrencyRef",{3,90002})

	for i=1,#tabsName do
		self.view.tag[i].Text[UI.Text].text = SGK.Localize:getInstance():getValue(tabsName[i])
		self.view.tag[i][UI.Toggle].isOn = i == self.PageIdx
		CS.UGUIClickEventListener.Get(self.view.tag[i].gameObject).onClick = function (obj)
			DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
			if self.PageIdx ~= i then
				self:InPageChange(i)
			end
		end
	end
	
	for i=1,3 do
		self.view.bottom.Dropdown[SGK.DropdownController]:AddOpotion(SGK.Localize:getInstance():getValue(self.state and euqipSuitsName[i] or inscSuitsName[i]))
	end
	self.view.bottom.Dropdown[UnityEngine.UI.Dropdown].value = self.EquipBarIdx or 0
	self.view.bottom.Dropdown.Label[UnityEngine.UI.Text].text = self.view.bottom.Dropdown[UnityEngine.UI.Dropdown].options[self.EquipBarIdx].text;
	self.view.bottom.Dropdown[UnityEngine.UI.Dropdown].onValueChanged:AddListener(function (i)
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
		self.EquipBarIdx = i
		self:upHeroEquipInfo()
		
		if self.PageIdx == 4 then
			self:InScrollView()
		end
    end)

	self.view.fifter.Toggle[UI.Toggle].isOn = self.EquipState
	self.view.fifter.Toggle[UI.Toggle].onValueChanged:AddListener(function ( b )
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
		self.EquipState = b
		self:InScrollView()
	end)

	CS.UGUIClickEventListener.Get(self.view.ScrollViewSuit.gameObject,true).onClick = function (obj)
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
	end
	CS.UGUIClickEventListener.Get(self.view.ScrollViewEquip.gameObject,true).onClick = function (obj)
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
	end
	CS.UGUIClickEventListener.Get(self.view.ScrollViewPlan.gameObject,true).onClick = function (obj)
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
	end

	-- ScrollViewOriginalHeight = self.view.ScrollViewSuit[UnityEngine.RectTransform].rect.height
	self.UIDragSuitScript = self.view.ScrollViewSuit.Viewport.Content[CS.ScrollViewContent]
	self.UIDragSuitScript.RefreshIconCallback = (function (obj,idx)
		self:refreshSuitsData(obj,idx)
	end)

	self.UIDragEquipScript = self.view.ScrollViewEquip.Viewport.Content[CS.ScrollViewContent]
	self.UIDragEquipScript.RefreshIconCallback = (function (obj,idx)
		self:refreshEquipsData(obj,idx)
	end)

	self.UIDragPlanScript = self.view.ScrollViewPlan.Viewport.Content[CS.ScrollViewContent]
	self.UIDragPlanScript.RefreshIconCallback = (function (obj,idx)
		self:refreshPlansData(obj,idx)
	end)

	CS.UGUIClickEventListener.Get(self.view.bottom.planBtn.gameObject).onClick = function (obj)
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
		self:InPageChange(4)
	end

	CS.UGUIClickEventListener.Get(self.view.fifter.propertyFifter.gameObject).onClick = function (obj)
		self.selectorType = EQUIP_SELECT.PROPERTY
		self:upEquipSelector()
	end

	CS.UGUIClickEventListener.Get(self.view.fifter.suitFifter.gameObject).onClick = function (obj)
		self.selectorType = EQUIP_SELECT.SUIT
		self:upEquipSelector()
	end

	CS.UGUIClickEventListener.Get(self.view.equipSelector.gameObject,true).onClick = function (obj)
		self.view.equipSelector:SetActive(false)
	end

	FifterScrollViewOriginalHeight = self.view.equipSelector.ScrollView[UnityEngine.RectTransform].rect.height
	self.UIDragSelectorScript = self.view.equipSelector.ScrollView.Viewport.Content[CS.ScrollViewContent]
	self.UIDragSelectorScript.RefreshIconCallback = (function (obj,idx)
		self:refreshSelectorData(obj,idx)
	end)

	CS.UGUIClickEventListener.Get(self.view.fifter.backBtn.gameObject).onClick = function (obj)
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
		if self.PageIdx == 3 then
			self:InPageChange(1)
		else
			self:InPageChange(self.lastPageIdx)
		end
	end

	for i=1,self.view.fifter.placeFifter.transform.childCount do
		CS.UGUIClickEventListener.Get(self.view.fifter.placeFifter[i].gameObject).onClick = function (obj)
			DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
			local _lastSelectIdx = self.PlaceIdx 
			if self.PlaceIdx and self.PlaceIdx == roleEquipIdx[i] then
				if self.PageIdx == 3 then--套装筛选界面
					self.PlaceIdx = nil
					for j=1,self.view.bottom.equipList.transform.childCount do
						self.view.bottom.equipList[j].CheckMark:SetActive(false)
					end
				end
			else
				self.PlaceIdx = roleEquipIdx[i]
				for j=1,self.view.bottom.equipList.transform.childCount do
					self.view.bottom.equipList[j].CheckMark:SetActive(j==i)
				end
			end

			if self.PageIdx == 2 or self.PageIdx == 3 then--非方案界面
				self:InScrollView()
			end
		end
	end

	CS.UGUIClickEventListener.Get(self.view.bg.gameObject,true).onClick = function (obj)
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
	end
end

function View:UpdateHeroInfo(heroId)
	self.heroId = heroId
	local _hero = HeroModule.GetManager():Get(self.heroId)
	self.view.bottom.Icon[UI.Image]:LoadSprite("icon/".._hero.icon)

	CS.UGUIClickEventListener.Get(self.view.bottom.Icon.gameObject).onClick = function (obj)
		DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
		DialogStack.PushPref("newEquip/roleListFrame",heroId)
	end

	self:upHeroEquipInfo()
	self:upSuitInfo()
end

local equipPlaceToIdx = {[1] = 1,[2] = 4,[3] = 2,[4] = 3,[5] = 5,[6] = 6}
function View:upHeroEquipInfo()
	local suitIdx = self.EquipBarIdx or 0

	self.view.bottom.equipBarTip[UI.Text]:TextFormat("提供{0}%属性",suitIdx == 0 and "100" or (self.state and EquipmentConfig.GetOtherSuitsCfg().Eq*100 or EquipmentConfig.GetOtherSuitsCfg().In*100))
	
	for i = 1, self.view.bottom.equipList.transform.childCount do
		local _view = self.view.bottom.equipList[i]
		local _idx = roleEquipIdx[i] + 6
		if not self.state then
			_idx = i
		end

		local _equip = module.equipmentModule.GetHeroEquip(self.heroId, _idx,suitIdx)
		_view.icon.IconFrame:SetActive(_equip and true)
		_view.add:SetActive(_equip == nil)
		_view.addBg:SetActive(_equip == nil)

		_view.CheckMark:SetActive(i == equipPlaceToIdx[self.PlaceIdx])
		if self.state then
			_view.addBg[CS.UGUISpriteSelector].index = 0
		else
			_view.addBg[CS.UGUISpriteSelector].index = 1
		end

		_view.redDot:SetActive(false)
        if _equip == nil then
            local _hash = EquipmentModule.HashBinary[_idx]
            local _list = EquipmentModule.GetPlace()[_hash]
            for k,v in pairs(_list or {}) do
                if EquipmentConfig.GetEquipOpenLevel(self.EquipBarIdx, _idx) then
                    if v.heroid == 0 then
                        _view.redDot:SetActive(true)
                        break
                    end
                end
            end
        end

		--激活套装属性效果
		_view.resonance:SetActive(false)
		local _suitCfgHero = HeroModule.GetManager():GetEquipSuit(self.heroId)
		for k,v in pairs(_suitCfgHero[suitIdx] or {}) do
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
		end
		--位置筛选
		local function OnClickPlaceHolder(i)
			if self.PlaceIdx and self.PlaceIdx ~= roleEquipIdx[i] and self.view.bottom.equipList[equipPlaceToIdx[self.PlaceIdx]] then
				self.view.bottom.equipList[equipPlaceToIdx[self.PlaceIdx]].CheckMark:SetActive(false)
				self.view.fifter.placeFifter[equipPlaceToIdx[self.PlaceIdx]][UI.Toggle].isOn = false
			end

			if self.PlaceIdx and self.PlaceIdx == roleEquipIdx[i] then
				DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
			end
			if self.PageIdx ~= 4 then--非方案界面
				if self.PlaceIdx and self.PlaceIdx == roleEquipIdx[i] then
					if self.PageIdx ~= 2 then
						self.PlaceIdx = nil
						self.view.bottom.equipList[i].CheckMark:SetActive(false)
						self.view.fifter.placeFifter[i][UI.Toggle].isOn = false
					end
				else
					self.PlaceIdx = roleEquipIdx[i]
					self.view.bottom.equipList[i].CheckMark:SetActive(true)
					self.view.fifter.placeFifter[i][UI.Toggle].isOn = true
				end

				self:InScrollView()
			end
		end

		if _view.icon.IconFrame.activeSelf then
			utils.IconFrameHelper.Create(_view.icon.IconFrame, {uuid = _equip.uuid})
			CS.UGUIClickEventListener.Get(_view.icon.IconFrame.gameObject).onClick = function()
				if self.equipInfoFrame then
					DispatchEvent("LOCAL_EQUIP_CHANGE",{roleID = self.heroId, suits = self.EquipBarIdx, index = _idx, state = self.selectIdx,offset = 410})
				else
					DialogStack.PushPref("newEquip/equipInfoFrame",{roleID = self.heroId, suits = self.EquipBarIdx, index = _idx, state = self.selectIdx,offset = 410},self.root.gameObject)
				end

				OnClickPlaceHolder(i)
			end
		end

		local equiIsOpen,equipOpenLv,shortLv = EquipmentConfig.GetEquipOpenLevel(suitIdx,_idx)--套装 位置
		_view.equipLock.gameObject:SetActive(not equiIsOpen)
		if not equiIsOpen then
			_view.equipLock.Image:SetActive(not shortLv)
			_view.equipLock.Text:SetActive(not not shortLv)
			if shortLv then
				_view.equipLock.Text[UI.Text].text = string.format("Lv%s",equipOpenLv)
			else
				_view.equipLock.Image.Text[UI.Text].text = string.format("X%s",equipOpenLv)
			end

			CS.UGUIClickEventListener.Get(_view.equipLock.gameObject,true).onClick = function()
				if shortLv then
					showDlgError(nil,SGK.Localize:getInstance():getValue("huoban_zhuangbei_03")..SGK.Localize:getInstance():getValue("tips_lv_02",equipOpenLv))
				else
					showDlgError(nil,SGK.Localize:getInstance():getValue("equip_open_tips",equipOpenLv))
				end
				DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
			end
		else
			CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
				DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
				OnClickPlaceHolder(i)
			end
		end
	end
end

local basePropertyTab = {[1002]=1,[1302]=2,[1502]=3,[1013]=4,[1313]=5,[1513]=6,[1201]=7,[1202]=8,[1203]=9,[1211]=10}
local showPropertyList = {{key = 1002},{key = 1502},{key = 1302},{key = 1211},{key = 1201},{key = 1202},{key = 1203}}
local suitCountTab = {2,4,6}

local addPropertyTab = {
							[1002] = { A_P = 1013,H_P = "baseAd"},
							[1302] = { A_P = 1313,H_P = "baseArmor"},
							[1502] = { A_P = 1513,H_P = "baseHp"},}
function View:upSuitInfo()
	local function GetSuitHeroListFunc(heroId,suitIdx,state)
		local suitTab,suitList = {},{}

		for i=1,6 do
			local _idx = roleEquipIdx[i] + 6
			if not state then
				_idx = i
			end
			local _equip = module.equipmentModule.GetHeroEquip(heroId, _idx,suitIdx)
			if _equip then
				suitTab[_equip.cfg.suit_id] = suitTab[_equip.cfg.suit_id] and suitTab[_equip.cfg.suit_id]+1 or 1
			end
		end

		for k,v in pairs(suitTab) do
			local count = math.floor(v/2)*2
			if count > 0 then
				local suitCfgTab = HeroScroll.GetSuitCfg(k)
				table.insert(suitList,{_length = count,suitIdx = k,quality = suitCfgTab.quality,suitCfgTab = suitCfgTab})
			end
		end
		return suitList
	end


	for i=1,self.view.bottom.suitInfo.property.Content.transform.childCount do
		self.view.bottom.suitInfo.property.Content.transform:GetChild(i-1).gameObject:SetActive(false)
	end

	local _propertyTab = {}
	local hero = HeroModule.GetManager():Get(self.heroId)
	local _propertyTab = EquipmentModule.CaclProperty(hero)
	local __showTab = {}
	for i=1,#showPropertyList do
		local _key = showPropertyList[i].key
		local _addValue  = addPropertyTab[_key] and _propertyTab[addPropertyTab[_key].A_P] and ((hero[addPropertyTab[_key].H_P] or 0)*(_propertyTab[addPropertyTab[_key].A_P]/ParameterConf.Get(addPropertyTab[_key].A_P).rate)) or 0
		__showTab[_key] = (_propertyTab[_key] or 0)+_addValue

		local item = utils.SGKTools.GetCopyUIItem(self.view.bottom.suitInfo.property.Content,self.view.bottom.suitInfo.property.Content.item,i)
		local _propertyCfg = ParameterConf.Get(_key)
		if _propertyCfg then
			item.Image:SetActive(_propertyCfg.icon ~= "")
			if _propertyCfg.icon ~= "" then
				item.Image[UI.Image]:LoadSprite("propertyIcon/".._propertyCfg.icon)
				item.Image[UI.Image].color = {r = 0, g = 0, b = 0, a = 1}
			end
			item.key[UI.Text].text = _propertyCfg.name
			local _showValue = ParameterConf.GetPeropertyShowValue(_key,__showTab[_key])  
			item.value[UI.Text].text = "+" .._showValue
		else
			item:SetActive(false)
		end
	end

	local function GetActiveSuitEffectFunc( heroId,suitIdx,state )
		local suitList = GetSuitHeroListFunc(heroId,suitIdx,state)
		table.sort(suitList,function (a,b)
			if a._length ~= b._length then
				return a._length < b._length
			end
			if a.quality ~= b.quality then
				return a.quality < b.quality
			end
			return a.suitIdx < b.suitIdx
		end)

		local function showActiveSuits()
			if suitList[1] and suitList[1]._length>=2 then
				if self.activeSuits and self.activeSuits <suitList[1]._length/2 then
					local tips = SGK.UIReference.Instantiate(self.view.bottom.tipsView,self.view.bottom.transform)
                    tips:SetActive(true);
                    tips[UnityEngine.CanvasGroup].alpha = 0;
                    tips.Text[UnityEngine.UI.Text].text = string.format("激活%s件套",suitCountTab[suitList[1]._length/2]);
                    tips[UnityEngine.CanvasGroup]:DOFade(1, 0.3):SetDelay(0.3);

                    local startPos = self.view.bottom.tipsView.transform.localPosition
                    tips.transform:DOLocalMove(startPos+Vector3(0, 150, 0), 1):SetDelay(0.4):SetEase(CS.DG.Tweening.Ease.Linear);
                    tips[UnityEngine.CanvasGroup]:DOFade(0, 0.3):SetDelay(1);
                    UnityEngine.GameObject.Destroy(tips.gameObject, 1.3);
				end
				self.activeSuits = suitList[1]._length/2
			else
				self.activeSuits = 0
			end
		end
		--显示激活套装
		showActiveSuits()

		local desc = ""
		for i=1,#suitList do
			for j=1,#suitCountTab do
				local _count = suitCountTab[j]
				if _count <= suitList[i]._length then
					local _suitcfg = suitList[i].suitCfgTab and suitList[i].suitCfgTab.effect[_count]
					if _suitcfg and not basePropertyTab[_suitcfg.type1] then
						desc = string.format("%s%s[%s]%s",desc,desc~="" and "\n" or "",_count,_suitcfg.desc)
					end
				end
			end
		end
		return desc
	end

	local desc = GetActiveSuitEffectFunc(self.heroId,0,self.state)
	self.view.bottom.suitInfo.suitDesc.desc[UI.Text].text = desc
end

function View:InScrollView()
	self.Equiplist = {}
	if self.state then--装备
		if self.PageIdx == 1 then
			local suitTab = {}
			local equipList = EquipmentModule.GetEquip()
			for k,v in pairs(equipList) do
				suitTab[v.cfg.suit_id] = suitTab[v.cfg.suit_id] or {}
				suitTab[v.cfg.suit_id].totalNum = suitTab[v.cfg.suit_id].totalNum and suitTab[v.cfg.suit_id].totalNum+1 or 1

				suitTab[v.cfg.suit_id][v.cfg.type] = suitTab[v.cfg.suit_id][v.cfg.type] or {}
				suitTab[v.cfg.suit_id][v.cfg.type].Num = suitTab[v.cfg.suit_id][v.cfg.type].Num and suitTab[v.cfg.suit_id][v.cfg.type].Num+1 or 1
			end
			
			local _role_Class = EquipRecommend.GetClass(self.heroId)
			local _hash = self.PlaceIdx and EquipmentModule.HashBinary[self.state and self.PlaceIdx+6 or self.PlaceIdx]
			local _suitsTab = HeroScroll.GetSuitCfg()
			for k,v in pairs(_suitsTab) do
				local _suit_id = k
				local _totalNum = suitTab[_suit_id] and suitTab[_suit_id].totalNum or 0
				local _num =  _hash and suitTab[_suit_id] and suitTab[_suit_id][_hash] and suitTab[_suit_id][_hash].Num or 0

				local _classIdx = 255
				for i=1,#_role_Class do
					if _role_Class[i].class == v.class then
						_classIdx = i
					end
				end
				local _suitTab = setmetatable({classIdx = _classIdx,totalNum =_totalNum,num = _num},{__index = v})
				table.insert(self.Equiplist,_suitTab)
			end
			
			table.sort(self.Equiplist,function (a,b)
				local a_own = a.totalNum > 0
				local b_own = b.totalNum > 0
				if a_own ~= b_own then
					return a_own
				end
				
				if a.classIdx ~= b.classIdx then
					return a.classIdx < b.classIdx
				end
				if a.quality ~= b.quality then
					return a.quality > b.quality
				end
				return a.suit_id < b.suit_id
			end)
			self.UIDragSuitScript.DataCount = #self.Equiplist
		elseif self.PageIdx == 2 or self.PageIdx == 3 then
			local equipList = EquipmentModule.GetEquip()

			local InsertListFunc = function (list,v)
									table.insert(list,
										setmetatable(v,{__index = function(t, k)
											if basePropertyTab[k] then
												local _propretyTab = EquipmentModule.CaclPropertyByEq(v)
												return _propretyTab[k] or 0
											end
										end})
									)
									return list
								end

			local fifterEquipFunc = function(v)
										--穿戴位置Idx
										if not self.EquipState then--无穿戴筛选
											if not self.PlaceIdx then
												self.Equiplist = InsertListFunc(self.Equiplist,v)
											elseif self.PlaceIdx and (1<<(self.PlaceIdx+5))&v.cfg.type ~= 0 then--部位筛选
												self.Equiplist = InsertListFunc(self.Equiplist,v)
											end
										elseif self.EquipState and v.heroid == 0 then----穿戴筛选未穿戴中
											if not self.PlaceIdx then--无部位筛选
												self.Equiplist = InsertListFunc(self.Equiplist,v)
											elseif self.PlaceIdx and (1<<(self.PlaceIdx+5))&v.cfg.type ~= 0 then--部位筛选
												self.Equiplist = InsertListFunc(self.Equiplist,v)
											end
										end
									end

			for k,v in pairs(equipList) do
				if not self.selectSuitId then--无套装筛选
					fifterEquipFunc(v)
				elseif self.selectSuitId == v.cfg.suit_id then--套装筛选
					fifterEquipFunc(v)
				end
			end
			
			table.sort(self.Equiplist,function (a,b)
				if self.fifterIdx then
					if self.fifterIdx == 1 then
						if a.level ~= b.level then
							return a.level > b.level
						end
						if a.quality ~= b.quality then
							return a.quality > b.quality
						end
					elseif self.fifterIdx == 2 then
						if a.quality ~= b.quality then
							return a.quality > b.quality
						end
						if a.level ~= b.level then
							return a.level > b.level
						end
					else
						if a[propertySortList[self.fifterIdx]] ~= b[propertySortList[self.fifterIdx]] then
							return a[propertySortList[self.fifterIdx]] > b[propertySortList[self.fifterIdx]]
						end
					end
					return a.uuid<b.uuid
				end
			end)
			
			self.UIDragEquipScript.DataCount = #self.Equiplist
		elseif self.PageIdx == 4 then
			self.Equiplist = EquipHelp.GetPlan()
			self.UIDragPlanScript.DataCount = #self.Equiplist+1
		end
		--强制刷新layout组件
		-- UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform])
		-- self.UIDragIconScript:ScrollMove(0)
	end
end

local EquipPosToIdx = {[1] = 1,[2] = 4,[3] = 2,[4] = 3,[5] = 5,[6] = 6}
function View:refreshSuitsData(obj,idx)
	local item = CS.SGK.UIReference.Setup(obj);
	local _idx = idx+1;--idx从 0开始
	local _cfg = self.Equiplist[_idx]
	if _cfg then
		item.name[UI.Text].text = _cfg.name
		local _num = self.PlaceIdx and _cfg.num or _cfg.totalNum
		item.num[UI.Text].text = SGK.Localize:getInstance():getValue("所持: ").._num

		item.Icon[UI.Image]:LoadSprite("icon/".._cfg.icon)
		item.Frame[CS.UGUISpriteSelector].index = _cfg.quality

		item.bg.Image[CS.UGUISpriteSelector].index = _num == 0 and 0 or 1
		if _num == 0 then
			item.Icon[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
			item.Frame[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
		else
			item.Icon[UI.Image].material = nil
			item.Frame[UI.Image].material = nil
		end
		local _desc = ""
		for i=1,3 do
			if _cfg.effect and _cfg.effect[i*2] and _cfg.effect[i*2].desc then
				_desc = string.format("%s%s[%s]%s</color>",_num == 0 and "<color=#00000099>" or "<color=#000000FF>",_desc~="" and string.format("%s\n",_desc) or "",i*2,_cfg.effect[i*2].desc)
			end
		end	
		item.descText[UI.Text].text = _desc

		CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj)
			DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
			self.selectSuitId = _cfg.suit_id
			self:InPageChange(3)
		end
		
		item.gameObject:SetActive(not not _cfg)
	else
		ERROR_LOG("2 quality cfg is nil",sprinttb(_cfg))
	end
end

function View:refreshEquipsData(obj,idx)
	local item = CS.SGK.UIReference.Setup(obj);
	local _idx = idx+1;--idx从 0开始

	local _cfg = self.Equiplist[_idx]
	if _cfg then
		utils.IconFrameHelper.Create(item.IconFrame, {customCfg = _cfg,showName = true,showDetail = true,showOwner = true,onClickFunc = function ()
			if self.equipInfoFrame then
				DispatchEvent("LOCAL_EQUIP_CHANGE",{roleID = self.heroId, index = math.floor(math.log(_cfg.cfg.type,2))+1,suits = self.EquipBarIdx,uuid = _cfg.uuid})
			else
				DialogStack.PushPref("newEquip/equipInfoFrame",{roleID = self.heroId, index = math.floor(math.log(_cfg.cfg.type,2))+1,suits = self.EquipBarIdx,uuid = _cfg.uuid},self.root.gameObject)
			end
		end})
		item.gameObject:SetActive(not not _cfg)
	end
end

function View:refreshPlansData(obj,idx)
	local item = CS.SGK.UIReference.Setup(obj);
	local _idx = idx+1;--idx从 0开始
	item.RenameBtn:SetActive(_idx ~= 1)
	item.Icon:SetActive(_idx ~= 1)
	item.Frame:SetActive(_idx ~= 1)

	item.SaveBtn:SetActive(_idx ~= 1)
	item.deleBtn:SetActive(_idx ~= 1)
	item.noticeBtn:SetActive(_idx ~= 1)

	item.LoadBtn:SetActive(false)
	item.Loading:SetActive(false)

	item[CS.UGUIClickEventListener].interactable = _idx ~= 1
	if _idx == 1 then
		item.name[UI.Text].text = SGK.Localize:getInstance():getValue("新增方案")

		CS.UGUIClickEventListener.Get(item.add.gameObject).onClick = function (obj)
			DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
			self:InCreatPlan()
		end
	else
		local _cfg = self.Equiplist[_idx-1]
		if _cfg then
			item.name[UI.Text].text = _cfg.name

			local function GetSuitsIdAndCount(equipTab)
				local _suitTab,_suitList = {},{}
				for k,v in pairs(equipTab) do
					if v ~= 0 then
						local _equip = EquipmentModule.GetByUUID(v)
						if _equip then
							_suitTab[_equip.cfg.suit_id] = (_suitTab[_equip.cfg.suit_id] or 0) + 1
						end
					end
				end
				for k,v in pairs(_suitTab) do
					local  _suitCfg = HeroScroll.GetSuitCfg(k)
					table.insert(_suitList,{suit_id = k,value = v,icon = _suitCfg.icon,quality = _suitCfg.quality})
				end
				table.sort(_suitList,function (a,b)
					if a.value ~= b.value then
						return a.value > b.value
					end
					if a.quality ~= b.quality then
						return a.quality > b.quality
					end
					return a.suit_id < b.suit_id
				end)
				local _count,_suit_Id,_icon,_quality = 0,0,"",0
				if _suitList[1] then
					_count,_suit_Id,_icon,_quality = _suitList[1].value,_suitList[1].suit_id,_suitList[1].icon,_suitList[1].quality
				end
				return _count,_suit_Id,_icon,_quality
			end

			local _suit_count,_suit_id,_icon,_quality = GetSuitsIdAndCount(_cfg.EquipTab)
			
			if _suit_count>= 4 then
				item.Icon[UI.Image]:LoadSprite("icon/".._icon)
				item.Frame[CS.UGUISpriteSelector].index = _quality or 0
			else
				item.Icon[UI.Image].sprite = item.Icon[CS.UGUISpriteSelector].sprites[0]
				item.Frame:SetActive(false)
			end
			--对比方案和当前套装
			local function ComparePlanVSCur(equipTab)
				local suitIdx = self.EquipBarIdx or 0
				local result = true
				for k,v in pairs(equipTab) do
					local _equip = EquipmentModule.GetHeroEquip(self.heroId, k,suitIdx)
					local _uuid = _equip and _equip.uuid or 0
					if _uuid ~= v then
						result = false
						break
					end
				end
				return result
			end

			local _equal = ComparePlanVSCur(_cfg.EquipTab)
			item.Loading:SetActive(_equal)
			item.LoadBtn:SetActive(not _equal)

			CS.UGUIClickEventListener.Get(item.SaveBtn.gameObject).onClick = function (obj)
				DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
				self:InSavePlan(_cfg)
			end

			CS.UGUIClickEventListener.Get(item.RenameBtn.gameObject).onClick = function (obj)
				DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
				self:InCreatPlan(_cfg.name)
			end

			CS.UGUIClickEventListener.Get(item.LoadBtn.gameObject).onClick = function (obj)
				DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
				self:InQuickToHero(_cfg)
			end

			CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj)
				DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
				DialogStack.PushPref("newEquip/equipPlanFrame",{planCfg = _cfg,state = true})
			end

			CS.UGUIClickEventListener.Get(item.deleBtn.gameObject).onClick = function (obj)
				showDlgMsg(SGK.Localize:getInstance():getValue("是否要删除该方案"), 
					function ()
						if _cfg.name then
							EquipHelp.RemovePlan(_cfg.name)
						end
					end, 
					function () end, 
					SGK.Localize:getInstance():getValue("common_queding_01"), --确定
					SGK.Localize:getInstance():getValue("common_cancle_01") --取消
				)
			end	

			item.noticeBtn[CS.UGUISpriteSelector].index = _cfg.status and 1 or 0
			CS.UGUIClickEventListener.Get(item.noticeBtn.gameObject).onClick = function (obj)
				if _cfg.name then
					item.noticeBtn[CS.UGUISpriteSelector].index = _cfg.status and 0 or 1
					EquipHelp.ChangePlan(_cfg.name,nil,not _cfg.status)
				end
			end
		else
			ERROR_LOG("_cfg is nil")
		end
	end
end

function View:InCreatPlan(name)
	if not name then
		local _exist,_uuidTab = self:checkEquipTab()
		if _exist then
			showDlgError(nil,SGK.Localize:getInstance():getValue("该方案已存在"))
			return
		else
			local _uuidTabIsNull = true
			for k,v in pairs(_uuidTab) do
				if v ~= 0 then
					_uuidTabIsNull = false
				end
			end
			if _uuidTabIsNull then
				showDlgError(nil,SGK.Localize:getInstance():getValue("不能设置一套空的方案"))
				return
			end
		end
	end

	self.view.creatPlan:SetActive(true)
	self.view.creatPlan.view.Tip[UI.Text].text = SGK.Localize:getInstance():getValue("请输入方案名称")

	local _idx = 1
	local _planList = EquipHelp.GetPlan()
	local _defaultName = "新增方案".._idx
	if not name then
		while self:checkPlanName(_defaultName) do
			_idx = _idx + 1 
			_defaultName = "新增方案".._idx
			if not self:checkPlanName(_defaultName) then
				break
			end
		end
	end

	self.view.creatPlan.view.InputField[UnityEngine.UI.InputField].text = name and name or _defaultName

	CS.UGUIClickEventListener.Get(self.view.creatPlan.mask.gameObject).onClick = function()
		self.view.creatPlan:SetActive(false)
	end

	CS.UGUIClickEventListener.Get(self.view.creatPlan.view.Cancel.gameObject).onClick = function()
		self.view.creatPlan:SetActive(false)
	end

	CS.UGUIClickEventListener.Get(self.view.creatPlan.view.Ensure.gameObject).onClick = function()
		local planName = self.view.creatPlan.view.InputField[UnityEngine.UI.InputField].text
 		if #self:string_segmentation(planName) > 0 then
 			--方案名已存在
 			local _exist = self:checkPlanName(planName)
 			if _exist then
 				showDlgError(nil,"该方案名已存在")
 			else
				if name then
					EquipHelp.ChangePlan(name,planName)
				else
					local _uuidTab = {}
					for i = 1, 6 do
						local _placeHolder = roleEquipIdx[i] + 6
						if not self.state then
							_placeHolder = i
						end
						local _equip = module.equipmentModule.GetHeroEquip(self.heroId, _placeHolder,self.EquipBarIdx)
						_uuidTab[_placeHolder] = _equip and _equip.uuid or 0
					end
					EquipHelp.AddPlan(planName,_uuidTab)
				end
				self.view.creatPlan:SetActive(false)
 			end
		else
			showDlgError(nil,"方案名不能为空")
		end
	end
end

--查看方案名是否存在
function View:checkPlanName(name)
	local exist = false
	local planList = EquipHelp.GetPlan()
	for i=1,#planList do
		if planList[i].name == name then
			exist = true
			break
		end
	end
	return exist
end

--查看装备方案是否重复
function View:checkEquipTab()
	local exist = false
	local _uuidTab = {}
	for i = 1, 6 do
		local _placeHolder = roleEquipIdx[i] + 6
		if not self.state then
			_placeHolder = i
		end
		local _equip = module.equipmentModule.GetHeroEquip(self.heroId, _placeHolder,self.EquipBarIdx)
		_uuidTab[_placeHolder] = _equip and _equip.uuid or 0
	end
	local planList = EquipHelp.GetPlan()

	for i=1,#planList do
		local _allEqual = true
		local _equipTab = planList[i].EquipTab
		for k,v in pairs(_uuidTab) do
			if v ~= _equipTab[k] then
				_allEqual = false
			end
		end
		if _allEqual then
			exist = true
			break
		end
	end
	return exist,_uuidTab
end

function View:InSavePlan(planCfg)
	local _exist,_uuidTab = self:checkEquipTab()
	if _exist then
		showDlgError(nil,SGK.Localize:getInstance():getValue("该方案已存在"))
	else
		local _isNull = true
		for k,v in pairs(_uuidTab) do
			if v~=0 then
				_isNull = false
				break
			end
		end
		if _isNull then
			showDlgError(nil,SGK.Localize:getInstance():getValue("你不能保存一套空的方案"))
		else
			showDlgMsg(SGK.Localize:getInstance():getValue("是否要替换该方案"), 
				function ()
					EquipHelp.ChangePlan(planCfg.name,nil,nil,_uuidTab)
				end, 
				function () end, 
				SGK.Localize:getInstance():getValue("common_queding_01"), --确定
				SGK.Localize:getInstance():getValue("common_cancle_01") --取消
			)
		end
	end
end

local PauseRefresh = false
function View:quickToHero(equipTab,heroId,suitIdx)
	PauseRefresh = true
	for k,_uuid in pairs(equipTab) do
		local _equip = EquipmentModule.GetHeroEquip(heroId, k,suitIdx)
		if _uuid ~= 0 then
			if not _equip or _equip.uuid ~= _uuid then
				local equiIsOpen = EquipmentConfig.GetEquipOpenLevel(suitIdx,k)--套装 位置(除第一套装，一件则全部开启)
				if equiIsOpen then
					EquipmentModule.EquipmentItems(_uuid,heroId, k, suitIdx)
				end
			end
		else
			if _equip then
				EquipmentModule.UnloadEquipment(_equip.uuid)
			end
		end
	end
	self.view.transform:DOScale(Vector3.one, 0.5):OnComplete(function()
		PauseRefresh = false
		self:upHeroEquipInfo()
		self:upSuitInfo()
		self.UIDragIconScript:ItemRef()
	end)
end

function View:InQuickToHero(planCfg)
	local equipTab = planCfg.EquipTab
	local planName = planCfg.name
	local suitIdx = self.EquipBarIdx or 0
	local _owned = nil
	for k,_uuid in pairs(equipTab) do
		local _equip = _uuid and EquipmentModule.GetEquip()[_uuid]
		if _equip and _equip.heroid ~= 0 and (_equip.heroid ~= self.heroId or (_equip.heroid == self.heroId and _equip.suits ~= suitIdx)) then
			_owned = true
			break
		end
	end

	if _owned then
		DialogStack.PushPref("newEquip/changeTipFrame", {equipTab =  equipTab,heroId = self.heroId, suitIdx = suitIdx,state = true})
	else
		showDlgMsg(SGK.Localize:getInstance():getValue("是否替换:"..planName), 
			function ()
				self:quickToHero(equipTab,self.heroId,suitIdx)	
			end,
			function ()
			end
		)
	end
end

function View:upEquipSelector()
	DispatchEvent("LOCAL_CLOSE_EQUIPINFOFRAME");
	self.view.equipSelector:SetActive(true)

	local pos_Y = self.view.equipSelector.ScrollView.transform.localPosition.y
	if self.selectorType == EQUIP_SELECT.SUIT then
		self.view.equipSelector.ScrollView[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,math.min(FifterScrollViewOriginalHeight,55*math.ceil(#self.suitFifter.list/2))+20);
		self.UIDragSelectorScript.DataCount = #self.suitFifter.list
		--强制刷新layout组件
		UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.view.equipSelector.ScrollView.Viewport.Content[UnityEngine.RectTransform])
		
		self.selectSuitIdx = nil
		for i=1,#self.suitFifter.list do
			if self.suitFifter.list[i] == self.selectSuitId then
				self.selectSuitIdx = i
				if FifterScrollViewOriginalHeight < 55*math.ceil(#self.suitFifter.list/2) then
					self.UIDragSelectorScript:ScrollMove(i-1)
				end
				break
			end
		end

		self.view.equipSelector.ScrollView.transform.localPosition = Vector3(-5,pos_Y,0)
	elseif self.selectorType == EQUIP_SELECT.PROPERTY then
		self.view.equipSelector.ScrollView[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,FifterScrollViewOriginalHeight);
		self.UIDragSelectorScript.DataCount = #propertySortList
		self.view.equipSelector.ScrollView.transform.localPosition = Vector3(105,pos_Y,0)
	end
end

function View:refreshSelectorData(obj,idx)
	local Item = CS.SGK.UIReference.Setup(obj);
	Item.gameObject:SetActive(true)

	Item.itemSuit:SetActive(self.selectorType == EQUIP_SELECT.SUIT)
	Item.itemProperty:SetActive(self.selectorType == EQUIP_SELECT.PROPERTY)
	local _idx = idx+1
	if self.selectorType == EQUIP_SELECT.SUIT then
		local _suit_id = self.suitFifter.list[_idx]
		local _cfg = HeroScroll.GetSuitCfg(_suit_id)
		if _cfg then
			local item = Item.itemSuit
			item.Image[UI.Image]:LoadSprite("icon/".._cfg.icon)
			item.Frame[CS.UGUISpriteSelector].index = _cfg.quality
			item.Text[UI.Text].text = _cfg.name
			
			item.Checkmark:SetActive(self.selectSuitIdx == _idx)

			CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj)
				if self.selectSuitIdx ~= _idx then
					if self.selectSuitIdx then
						local _obj = self.UIDragSelectorScript:GetItem(self.selectSuitIdx-1)
						if _obj then
							local _lastSelectItem = CS.SGK.UIReference.Setup(_obj)
							_lastSelectItem.itemSuit.Checkmark:SetActive(false)
						end
					end

					item.Checkmark:SetActive(true)

					self.selectSuitId = _cfg.suit_id
					self.selectSuitIdx = _idx

					self:InScrollView()

					self.view.fifter.suitFifter.Image[UI.Image]:LoadSprite("icon/".._cfg.icon)
					self.view.fifter.suitFifter.Frame[CS.UGUISpriteSelector].index = _cfg.quality
					self.view.fifter.suitFifter.Text[UI.Text].text = _cfg.name
				end
				self.view.equipSelector:SetActive(false)
			end
		end
	elseif self.selectorType == EQUIP_SELECT.PROPERTY then
		local _cfg = propertySortList[_idx]
		if _cfg then
			local item = Item.itemProperty
			local _name = _cfg
			if type(_cfg) == "number" then
				if ParameterConf.Get(_cfg) then
					_name = ParameterConf.Get(_cfg).name
				end
			end
			item.Text[UI.Text].text =  _name

			item.Checkmark:SetActive(self.fifterIdx == _idx)
			CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj)
				if self.fifterIdx ~= _idx then
					if self.fifterIdx then
						local _obj = self.UIDragSelectorScript:GetItem(self.fifterIdx-1)
						if _obj then
							local _lastSelectItem = CS.SGK.UIReference.Setup(_obj)
							_lastSelectItem.itemProperty.Checkmark:SetActive(false)
						end
					end

					item.Checkmark:SetActive(true)

					self.fifterIdx = _idx
					self:InScrollView()

					self.view.fifter.propertyFifter.Text[UI.Text].text = _name
				end
				self.view.equipSelector:SetActive(false)
			end
		end
	end
end

function View:upFifterBtnDesc()
	--更新属性筛选Btn
	if self.view.fifter.propertyFifter.activeSelf then
		self.fifterIdx = self.fifterIdx or 1
		if propertySortList[self.fifterIdx] then
			local _name = propertySortList[self.fifterIdx]
			if type(propertySortList[self.fifterIdx]) == "number" then
				if ParameterConf.Get(propertySortList[self.fifterIdx]) then
					_name = ParameterConf.Get(propertySortList[self.fifterIdx]).name
				end
			end
			self.view.fifter.propertyFifter.Text[UI.Text].text = _name
		end
	end

	--更新套装筛选Btn
	if self.view.fifter.suitFifter.activeSelf then
		local _cfg = HeroScroll.GetSuitCfg(self.selectSuitId)
		if _cfg then
			self.view.fifter.suitFifter.Image[UI.Image]:LoadSprite("icon/".._cfg.icon)
			self.view.fifter.suitFifter.Frame[CS.UGUISpriteSelector].index = _cfg.quality
			self.view.fifter.suitFifter.Text[UI.Text].text = _cfg.name
		end
	end
end

function View:InPageChange(Idx)
	self.lastPageIdx = self.PageIdx or 1
	self.PageIdx = Idx

	self.view.fifter.Toggle:SetActive(Idx == 2 or Idx == 3)
	self.view.fifter.propertyFifter:SetActive(Idx == 2 or Idx == 3)

	self.view.fifter.suitFifter:SetActive(Idx == 3 and  #self.suitFifter.list > 0)
	self.view.fifter.backBtn:SetActive(Idx == 3 or Idx == 4)
	self.view.tag:SetActive(Idx == 1 or Idx == 2)

	self.view.fifter.placeFifter:SetActive(Idx == 2 or Idx == 3)

	self.view.bottom.planBtn:SetActive(Idx ~= 4)

	self.view.ScrollViewSuit:SetActive(Idx == 1)
	self.view.ScrollViewEquip:SetActive(Idx == 2 or Idx == 3)
	self.view.ScrollViewPlan:SetActive(Idx == 4)

	if self.lastPageIdx ~= 3  or  Idx == 4 then
		self.PlaceIdx  = nil
		for i=1,self.view.bottom.equipList.transform.childCount do
			self.view.bottom.equipList[i].CheckMark:SetActive(false)
		end
	end

	self.view.fifter.placeFifter[UI.ToggleGroup].allowSwitchOff = Idx == 3 
	if Idx == 2 then
		self.selectSuitId = nil --筛选套装
		if not self.PlaceIdx then
			self.PlaceIdx  = roleEquipIdx[1]
		end

		for i=1,self.view.bottom.equipList.transform.childCount do
			self.view.bottom.equipList[i].CheckMark:SetActive(equipPlaceToIdx[self.PlaceIdx] == i)
			self.view.fifter.placeFifter[i][UI.Toggle].isOn = equipPlaceToIdx[self.PlaceIdx] == i
		end
	elseif Idx == 3 then
		for i=1,self.view.fifter.placeFifter.transform.childCount do
			self.view.fifter.placeFifter[i][UI.Toggle].isOn = equipPlaceToIdx[self.PlaceIdx] == i
		end
	end
	
	self:upFifterBtnDesc()
	self:InScrollView()
end

function View:string_segmentation(str)
	--print(str)
    local len  = #str
    local left = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    local t = {}
    local start = 1
    local wordLen = 0
    while len ~= left do
        local tmp = string.byte(str, start)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                break
            end
            i = i - 1
        end
        wordLen = i + wordLen
        local tmpString = string.sub(str, start, wordLen)
        start = start + i
        left = left + i
        t[#t + 1] = tmpString
    end
    return t
end

function View:OnDestroy()
	DispatchEvent("CurrencyRef")
end



function View:listEvent()
	return {
		"EQUIPMENT_INFO_CHANGE",
		"LOCAL_DECOMPOSE_OK" ,
		"LOCAL_GUIDE_CHANE",

		"LOCAL_EQUIPPLAN_CHANGE",
		"LOCAL_NEWROLE_HEROIDX_CHANGE",
		"ADVANCED_OVER",

		"LOCAL_CLOSE_EQUIPINFOFRAME",
		"PushPref_Load_success",
	}
end

function View:onEvent(event, data)
	if event == "LOCAL_EQUIPPLAN_CHANGE" then
		print("EQUIPPLAN_CHANGE")
		if self.PageIdx == 4 then
			self:InScrollView()
		end
	elseif event == "EQUIPMENT_INFO_CHANGE" then
		if not PauseRefresh then
			if not self.refshing then
				self.refshing = true
				self.root.transform:DOScale(Vector3.one,0.2):OnComplete(function() 
					self:upHeroEquipInfo()
					self:upSuitInfo()
					-- self.UIDragIconScript:ItemRef()
					self:InScrollView()
					self.refshing = false
				end)
			end
		end
	elseif event == "ADVANCED_OVER" then
		if not self.refshing then
			self.refshing = true
			self.root.transform:DOScale(Vector3.one,0.2):OnComplete(function() 
				self:upHeroEquipInfo()
				self:upSuitInfo()
				self:InScrollView()
				self.refshing = false
			end)
		end
	elseif event == "LOCAL_NEWROLE_HEROIDX_CHANGE" then
		local heroId = data and data.heroId
		if heroId then
			self:UpdateHeroInfo(heroId)
		end
	elseif event == "LOCAL_CLOSE_EQUIPINFOFRAME" then
		self.equipInfoFrame = false
	elseif event == "PushPref_Load_success" then
        if data and data.name == "newEquip/equipInfoFrame" then
            self.equipInfoFrame = true
        end
	elseif event == "LOCAL_GUIDE_CHANE" then
		module.guideModule.PlayByType(111, 0.3)
	end
end

return View;