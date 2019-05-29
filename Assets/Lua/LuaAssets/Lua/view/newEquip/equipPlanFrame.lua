local EquipmentModule = require "module.equipmentModule";
local HeroModule = require "module.HeroModule"
local ParameterConf = require "config.ParameterShowInfo"
local InscModule = require "module.InscModule"
local Property = require "utils.Property"
local equipmentConfig = require "config.equipmentConfig"
local EquipHelp = require "module.EquipHelp"
local ItemHelper = require "utils.ItemHelper"

local HeroScroll = require "hero.HeroScroll"
local View = {}

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function (obj)
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	local planCfg = data and data.planCfg
	local state = data and data.state
	if not planCfg then return end

	self.view.bottom.noticeBtn[CS.UGUISpriteSelector].index = planCfg.status and 1 or 0
	local _uuids =  planCfg.EquipTab or {}
	self:upEquipInfo(_uuids,state)

	-- CS.UGUIClickEventListener.Get(self.view.bottom.deleBtn.gameObject).onClick = function (obj)
	-- 	showDlgMsg(SGK.Localize:getInstance():getValue("是否要删除该方案"), 
	-- 		function ()
	-- 			if planCfg.name then
	-- 				EquipHelp.RemovePlan(planCfg.name)
	-- 			end
	-- 			CS.UnityEngine.GameObject.Destroy(self.gameObject)
	-- 		end, 
	-- 		function () end, 
	-- 		SGK.Localize:getInstance():getValue("common_queding_01"), --确定
	-- 		SGK.Localize:getInstance():getValue("common_cancle_01") --取消
	-- 	)
	-- end	

	-- CS.UGUIClickEventListener.Get(self.view.bottom.noticeBtn.gameObject).onClick = function (obj)
	-- 	if planCfg.name then
	-- 		self.view.bottom.noticeBtn[CS.UGUISpriteSelector].index = planCfg.status and 0 or 1
	-- 		EquipHelp.ChangePlan(planCfg.name,nil,not planCfg.status)
	-- 	end
	-- 	-- CS.UnityEngine.GameObject.Destroy(self.gameObject)
	-- end
end

local roleEquipIdx = {
	[1] = 1,[2] = 3,[3] = 4,[4] = 2,[5] = 5,[6] = 6
}
function View:upEquipInfo(uuids,state)
	local equipList = {}
	for i = 1, self.view.equipList.transform.childCount do
		local _view = self.view.equipList[i]
		local _idx = roleEquipIdx[i] + 6
		if not state then
			_idx = i
		end

		local _uuid = uuids[_idx]
		local _equip = _uuid and EquipmentModule.GetEquip()[ _uuid]
		_view.icon.IconFrame:SetActive(not not _equip)
		_view.add:SetActive(_equip == nil)
		_view.addBg:SetActive(_equip == nil)
		if state then
			_view.addBg[CS.UGUISpriteSelector].index = 0
		else
			_view.addBg[CS.UGUISpriteSelector].index = 1
		end

		if _view.icon.IconFrame.activeSelf then
			table.insert(equipList,_equip)
			utils.IconFrameHelper.Create(_view.icon.IconFrame, {uuid = _equip.uuid})
			CS.UGUIClickEventListener.Get(_view.icon.IconFrame.gameObject).onClick = function()
				DialogStack.PushPref("newEquip/equipInfoFrame", {uuid = _equip.uuid})
			end
		end
	end

	self:upEquipProperty(equipList)
	self:upEquipSuitDesc(equipList)
end

local basePropertyTab = {[1002]=1,[1302]=2,[1502]=3,[1013]=4,[1313]=5,[1513]=6,[1201]=7,[1202]=8,[1203]=9,[1211]=10}
local suitCountTab = {2,4,6}
local function GetSuitList(equipList)
	local suitTab,suitList = {},{}
	for i=1,#equipList do
		local _equip = equipList[i]
		-- ERROR_LOG(_equip.cfg.suit_id,sprinttb(_equip))
		suitTab[_equip.cfg.suit_id] = suitTab[_equip.cfg.suit_id] and suitTab[_equip.cfg.suit_id]+1 or 1
	end

	for k,v in pairs(suitTab) do
		local count = math.floor(v/2)*2
		if count > 0 then
			local suitCfgTab = HeroScroll.GetSuitCfg(k)
			if suitCfgTab and suitCfgTab[2] then
				-- local _suitQuality = 0
				-- for __,_suitCfg in pairs(suitCfgTab[2]) do
				-- 	if _suitCfg.quality>= _suitQuality then
				-- 		_suitQuality = _suitCfg.quality
				-- 	end
				-- end
				table.insert(suitList,{_length = count,suitIdx = k,quality = suitCfgTab[2].quality,suitCfgTab = suitCfgTab})
			end
		end
	end
	return suitList
end
--计算多件装备的套装属性
local function CaclPropertyByEqList(equipList)
	local suitPropertyTab = {}
	local suitList = GetSuitList(equipList)
	for i=1,#suitList do
		for j=1,#suitCountTab do
			local __count = suitCountTab[j]
			if __count <= suitList[i]._length then
				local __suitcfg = suitList[i].suitCfgTab and suitList[i].suitCfgTab[__count] and suitList[i].suitCfgTab[__count][suitList[i].quality]
				if __suitcfg then
					for k=1,2 do
						-- ERROR_LOG(__suitcfg["type"..k],__suitcfg["value"..k])
						if __suitcfg["type"..k] ~=0 and __suitcfg["value"..k] ~=0 then
							if basePropertyTab[__suitcfg["type"..k]] then
								suitPropertyTab[__suitcfg["type"..k]] = suitPropertyTab[__suitcfg["type"..k]] and suitPropertyTab[__suitcfg["type"..k]] + __suitcfg["value"..k] or __suitcfg["value"..k]
							end
						end
					end
				end
			end
		end
	end
	return suitPropertyTab
end


local function CaclProperty(equipList)
	local propertyTab = {}
	for i=1,#equipList do
		if equipList[i].type == 0 then
			local _propertyTab = EquipmentModule.CaclPropertyByEq(equipList[i])
			if _propertyTab and next(_propertyTab) ~= nil then
				for k,v in pairs(_propertyTab) do
					if k ~= 0 and v ~= 0 then
						propertyTab[k] = propertyTab[k] and propertyTab[k]+v or v
					end
				end
			end
		end
	end
	-- ERROR_LOG(sprinttb(propertyTab))
	local _suitPropertyTab = CaclPropertyByEqList(equipList)
	-- ERROR_LOG(sprinttb(_suitPropertyTab))
	for k,v in pairs(_suitPropertyTab) do
		if k ~= 0 and v ~= 0 then
			propertyTab[k] = propertyTab[k] and propertyTab[k]+v or v
		end
	end

	local propertyList = {}
	for k,v in pairs(propertyTab) do
		table.insert(propertyList,{key =k ,value = v})
	end
	table.sort(propertyList,function (a,b)
		local a_idx = basePropertyTab[a.key]
		local b_idx = basePropertyTab[b.key]
		return a_idx < b_idx
	end)
	return propertyList
end

function View:upEquipProperty(equipList)
	local propertyList = CaclProperty(equipList)
	
	for i=1,self.view.mid.property.Content.transform.childCount do
		self.view.mid.property.Content.transform:GetChild(i-1).gameObject:SetActive(false)
	end

	for i=1,#propertyList do
		local item = utils.SGKTools.GetCopyUIItem(self.view.mid.property.Content,self.view.mid.property.Content.item,i)
		local _propertyCfg = ParameterConf.Get(propertyList[i].key)
		if _propertyCfg then
			item.Image:SetActive(_propertyCfg.icon ~= "")
			if _propertyCfg.icon ~= "" then
				item.Image[UI.Image]:LoadSprite("propertyIcon/".._propertyCfg.icon)
				item.Image[UI.Image].color = {r = 0, g = 0, b = 0, a = 1}
			end
			item.key[UI.Text].text = _propertyCfg.name
			local _showValue = ParameterConf.GetPeropertyShowValue(propertyList[i].key,propertyList[i].value)  
            item.value[UI.Text].text = _showValue
		else
			item:SetActive(false)
		end
	end
end

local function GetActiveSuitEffect(equipList)
	local suitList = GetSuitList(equipList)
	table.sort(suitList,function (a,b)
		if a._length ~= b._length then
			return a._length < b._length
		end
		if a.quality ~= b.quality then
			return a.quality < b.quality
		end
		return a.suitIdx < b.suitIdx
	end)

	local desc = ""
	for i=1,#suitList do
		for j=1,#suitCountTab do
			local __count = suitCountTab[j]
			-- ERROR_LOG(__count,suitList[i]._length)
			if __count <= suitList[i]._length then

				local __suitcfg = suitList[i].suitCfgTab and suitList[i].suitCfgTab[__count] and suitList[i].suitCfgTab[__count][suitList[i].quality]
				-- ERROR_LOG(sprinttb(__suitcfg))
				if __suitcfg and not basePropertyTab[__suitcfg.type1] then
					desc = string.format("%s%s[%s]%s",desc,desc~="" and "\n" or "",__count,__suitcfg.desc)
				end
			end
		end
	end
	return desc
end

function View:upEquipSuitDesc(equipList)
	self.view.mid.suitDesc.Text[UI.Text].text = SGK.Localize:getInstance():getValue("套装效果")
	self.view.mid.suitDesc:SetActive(false)
	if #equipList>0 then
		local _desc = GetActiveSuitEffect(equipList)
		if _desc ~= "" then
			self.view.mid.suitDesc:SetActive(true)
		end
		self.view.mid.suitDesc.descText[UI.Text].text = _desc
	end
end

return View;