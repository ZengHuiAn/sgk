local ParameterConf = require "config.ParameterShowInfo"
local Property = require "utils.Property"
local EquipmentModule =require "module.equipmentModule"
local EquipConfig = require "config.equipmentConfig"
local InscModule = require "module.InscModule"
local EquipHelp = require "module.EquipHelp"
local ItemHelper = require "utils.ItemHelper"
local ItemModule=require "module.ItemModule"
local ShopModule = require "module.ShopModule"
local HeroModule = require "module.HeroModule"
local HeroScroll = require "hero.HeroScroll"
local QuestModule = require "module.QuestModule"
local OpenLevel = require "config.openLevel"
local CommonConfig = require "config.commonConfig"

local View={}

local compose_shop_id = 7;
function View:Start(data)
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view.Content	
	self.UIPropertyTab={}
	self.basePropretyUI={}
	self.propretyUITab={}
	self.breakUpUI={}
	self:Init(data);
end

function View:Init(data)
	self.data = data

	local type = data and data.type or 41
	local id = data and data.id
	local count = data and data.count or 1
	local uuid = data and data.uuid 
	local func = data and data.func
	local otherPid = data and data.otherPid

	self.posIdx = data and data.InItemBag or 0
	self.BtnDesc = data and data.BtnDesc

	self.CustomCfg = data and data.CustomCfg
	
	self:InitView(type,id,uuid,count,otherPid)
	--获取途径
	--默认类型[0]不显示物品来源跳转 [1]在背包内 [2]需显示功能
	self.view.sourceShowFrame.gameObject:SetActive(self.posIdx~=0)	
	self.view.sourceShowFrame[SGK.LuaBehaviour]:Call("ShowSourceTitle",data.id,func,true)
	CS.UGUIClickEventListener.Get(self.view.sourceShowFrame.sourceTip.gameObject).onClick = function (obj) 	
		self.view.sourceShowFrame[SGK.LuaBehaviour]:Call("ShowSourceItem",nil)
	end
end

function View:InitView(type,id,uuid,count,otherPid)
	local item = ItemHelper.Get(type,id)
	item.uuid = uuid
	item.otherPid = otherPid

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj) 	
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.root.view.Close.gameObject).onClick = function (obj) 	
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.view.Btns.Btn.gameObject).onClick = function (obj) 	
		DialogStack.Pop()
	end

	self:refDetailData(item,count)
	self:RefUIByType(item)
end

local roleEquipIdx = {
    [1] = 1,
    [2] = 3,
    [3] = 4,
    [4] = 2,
    [5] = 5,
    [6] = 6
}

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

function View:refDetailData(item,count)
	utils.IconFrameHelper.Create(self.view.top.IconFrame,
		{
			uuid=item.uuid,type=item.type,id=item.id,count=count,otherPid=item.otherPid,
			func=function (ItemIcon)
				-- ItemIcon.qualityAnimationFx:SetActive(false)
			end
		})

	if item.type == ItemHelper.TYPE.EQUIPMENT then
		self.root.view.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_zhuangbeixinxi_01")
	elseif item.type == ItemHelper.TYPE.INSCRIPTION then
		self.root.view.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_shouhuxinxi_01")
	else
		self.root.view.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_daojuxinxi_01")
	end

	self.view.top.info.type[UI.Text].text = item.name;
	self.view.top.info.type[UI.Text].color = ItemHelper.QualityColor(item.quality)
	
	--伙伴碎片 21
	self.view.skillView:SetActive(item.type_Cfg and item.type_Cfg.sub_type and item.type_Cfg.sub_type == 21)
	self.view.top.info.ownNum:SetActive(item.type_Cfg and item.type_Cfg.sub_type and item.type_Cfg.sub_type == 21)
	if self.view.skillView.activeSelf then
		local _heroId = item.id-10000
		--有来源显示在底部没来源顶部
		local _Anchors = self.posIdx~= 0 and 1 or 0
		self.view.skillView[SGK.LuaBehaviour]:Call("InitData", {heroId = _heroId,Anchors =_Anchors})-- offset = {100 ,0 ,0 ,-20 ,-85}})
		local _hero = module.HeroModule.GetManager():Get(_heroId)
		local _count = ItemModule.GetItemCount(item.id)
		if not _hero then
			local _product = ShopModule.GetManager(6, _heroId) and ShopModule.GetManager(6, _heroId)[1]
			if _product then
				if _product.consume_item_id1 and _product.consume_item_id1 == item.id and _product.product_item_id and _product.product_item_id == _heroId then
					local limit = _product.consume_item_value1
					self.view.top.info.ownNum[UI.Text].text = string.format("%s%s%s</color>/%s",SGK.Localize:getInstance():getValue("suipian_1"),limit>_count and "<color=#FF0000FF>" or "<color=#FFFFFFFF>",_count,limit)
				else
					ERROR_LOG("info  is err",_product.consume_item_id1,_product.product_item_id)
				end
			end
		else
			self.view.top.info.ownNum[UI.Text].text = string.format("%s%s",SGK.Localize:getInstance():getValue("suipian_1"),_count)
		end
	end

	local case=item.uuid and (item.type ==utils.ItemHelper.TYPE.EQUIPMENT or item.type == utils.ItemHelper.TYPE.INSCRIPTION)	
	
	local propretyShowTab = nil
	if item.type == ItemHelper.TYPE.EQUIPMENT or item.type == ItemHelper.TYPE.INSCRIPTION then
		propretyShowTab = EquipHelp.GetEquipShowProprety(item.id)
	end

	self.view.top.info.score.gameObject:SetActive(case)
	self.view.mid.gameObject:SetActive(case)

	self.view.mid.IdentificationBtn:SetActive(false)

	self.view.midSpecial.gameObject:SetActive(not item.uuid and propretyShowTab)
	
	self.view.desc:SetActive(not (propretyShowTab and not item.uuid))
	if self.view.desc.activeSelf then
		self.view.desc.Text[UI.Text].text=string.format(item.info and string.gsub(item.info,"\n","") or "");
		self.view.desc.bg:SetActive(not case)
	end

	if case then	
		local equip = EquipmentModule.GetByUUID(item.uuid,item.otherPid)
		if equip then
			--评分
			self.view.top.info.score[UI.Text]:TextFormat("评分:{0}",item.type == utils.ItemHelper.TYPE.EQUIPMENT and tostring(Property(EquipmentModule.CaclPropertyByEq(equip,item.otherPid)).calc_score) or tostring(Property(InscModule.CaclPropertyByInsc(equip,item.otherPid)).calc_score))
			--套装
			self.view.mid.suitDesc:SetActive(item.type==utils.ItemHelper.TYPE.EQUIPMENT)
			if item.type==utils.ItemHelper.TYPE.EQUIPMENT then--装备
				local _suitCfg=HeroScroll.GetSuitConfig(equip.cfg.suit_id)
				self:updateSuitShow(_suitCfg,equip.cfg.quality,equip.cfg.type)
			end
			--装备状态
			self.view.top.status:SetActive(equip.heroid ~= 0)
			if equip.heroid ~= 0 then
				local hero = HeroModule.GetManager(item.otherPid):Get(equip.heroid)
				if hero then
					self.view.top.status.name[UI.Text]:TextFormat("{0}",hero.name)
					self.view.top.status.staticText[UI.Text].text=tostring(equip.isLock and "已绑定" or "已装备")
				end
			end

			for k,v in pairs(self.propretyUITab) do
				v.gameObject:SetActive(false)
			end
			self:UpdateProprety(equip,item.otherPid)

			if self.posIdx == 1 then--背包里的装备
				local _status,cost_id,cost_value = CheckEquipScroll(equip)
				self.view.mid.IdentificationBtn:SetActive(_status)
				if _status then
					self.view.mid.IdentificationBtn.Image:SetActive(cost_id~=0 and cost_value ~= 0)
					if cost_id~=0 and cost_value ~= 0 then
						local _count = module.ItemModule.GetItemCount(cost_id)
						self.view.mid.IdentificationBtn.Image.Text[UI.Text].text = string.format("%s%s</color>/%s",_count>=cost_value and "<color=#FFFFFFFF>" or "<color=#BC0000FF>",_count,cost_value)
					end
				end
				
				self.view.top.lock:SetActive(true)
				local _lock = EquipHelp.CheckEquipLockStatus(item.type,item.id,item.uuid)
				self.view.top.lock[CS.UGUISpriteSelector].index = _lock and 1 or 0
				CS.UGUIClickEventListener.Get(self.view.top.lock.gameObject).onClick = function (obj) 
					local _index = self.view.top.lock[CS.UGUISpriteSelector].index
					self.view.top.lock[CS.UGUISpriteSelector].index = (_index +1)%2
					EquipHelp.ChangeEquipLockStatus(item.type,item.id,item.uuid)
				end
			end
		else
			ERROR_LOG("equip cfg is nil",item.uuid,item.otherPid)
		end
	elseif propretyShowTab then--配置装备
		self:UpdatePropretyShowTab(item,propretyShowTab)
	else
		self.view[UI.VerticalLayoutGroup].padding.bottom = (self.posIdx==3 or self.posIdx==1 ) and 105 or 20
		self.gameObject.transform:DOScale(Vector3.one,0.1):OnComplete(function()
			self.root.view[UnityEngine.CanvasGroup].alpha = 1;
		end)	
	end
end

function View:updateSuitShow(suitCfg,quality,type)
	self.view.mid.suitDesc.Title.Text[UI.Text].text = suitCfg[2][quality].name			
	local localPos=1; 
	for i=1,#roleEquipIdx do
		if (1<<(roleEquipIdx[i]+5))&type~=0 then
			localPos = i
		end
	end
	for i=1,self.view.mid.suitDesc.suitIdx.transform.childCount do
		self.view.mid.suitDesc.suitIdx[i][CS.UGUISpriteSelector].index =localPos==i and 0 or 1
	end

	self:updateSuitDesc(self.view.mid.suitDesc,suitCfg,quality)
end

function View:updateSuitDesc(suitDesc,suitCfg,quality)
	for i=1,suitDesc.descText.transform.childCount do
		suitDesc.descText[i]:SetActive(suitCfg[i*2])
		if suitCfg[i*2] then
			suitDesc.descText[i]:TextFormat("<color=#00000099>[{0}]{1}</color>",i*2,suitCfg[i*2][quality].desc)
		end
	end
end

local function GetPropretyShowValue(_tab,equip,pid)
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
		local _baseAtt = EquipmentModule.GetEquipBaseAtt(equip.uuid,pid)
		for i=1,#_baseAtt do
			if _baseAtt[i].key~=0  then
				Idx = Idx+i
				sortTab[_baseAtt[i].key] = Idx
			end
		end

		if equip.attribute then
			for i=1,#equip.attribute do
				if equip.attribute[i].key ~= 0 then
					Idx = Idx*10 +i
					sortTab[equip.attribute[i].key] = Idx
				end
			end
		end
		table.sort(showTab,function (a,b)
			return sortTab[a.key]<sortTab[b.key]
		end)
	end

    return showTab
end 

local function GetBassAtt(equip,pid)
	local _tab,_basePropretyTab,_addLvTab = {},{},{}
	if equip then
		_tab = EquipmentModule.GetEquipBaseAtt(equip.uuid,pid)
		_basePropretyTab = GetPropretyShowValue(_tab,equip,pid)
		if equip.type == 0 then
			local _addLvCfg = EquipConfig.EquipmentLevTab()[equip.cfg.id]
			if _addLvCfg then
				for i=0,3 do
					if _addLvCfg["type"..i] and _addLvCfg["type"..i]~=0 and _addLvCfg["value"..i]~=0 then
						_addLvTab[_addLvCfg["type"..i]] = math.floor(_addLvCfg["value"..i])*(equip.level-1)
					end
				end
			else
				ERROR_LOG("addLvCfg is nil,id",equip.cfg.id)
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
                local _showBaseValue = ParameterConf.GetPeropertyShowValue(_basePropretyTab[i].key,_basePropretyTab[i].allValue-_addLvValue)
                if _addLvValue ~= 0 then
                    propertyItem.Text[UI.Text]:TextFormat("{0}:{1}(<color=#00A600FF>+{2}</color>)",cfg.name,_showBaseValue,_showAddLvValue)
                else
                    propertyItem.Text[UI.Text]:TextFormat("{0}:{1}",cfg.name,_showBaseValue)
                end
            else
                local _showValue = ParameterConf.GetPeropertyShowValue(_basePropretyTab[i].key,_basePropretyTab[i].allValue)  
                propertyItem.Text[UI.Text]:TextFormat("{0}{1}{2}",cfg.name,cfg.rate ~= -1 and "+" or "",_showValue)
            end
        end
    else
        ERROR_LOG("parameter cfg is nil,key",_basePropretyTab[i].key)
    end 
end

local function GetAddAtt(equip,pid)
    local _tab1,_addPropretyTab = {},{}
    if equip then
        _tab1 = EquipmentModule.GetAttribute(equip.uuid,pid)
        _addPropretyTab = GetPropretyShowValue(_tab1,equip,pid)
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

--装备属性开启等级Id
local commonLvId = {400,401,402,403}
function View:UpdateProprety(equip,pid)
	local _tab,_basePropretyTab,_addLvTab = GetBassAtt(equip,pid)
	self.view.mid.basePropretys:SetActive(#_basePropretyTab>0)
	for i=1, self.view.mid.basePropretys.transform.childCount do
		self.view.mid.basePropretys.transform:GetChild(i-1).gameObject:SetActive(false)
	end
	for i=1,#_basePropretyTab do
		local propertyItem = utils.SGKTools.GetCopyUIItem(self.view.mid.basePropretys,self.view.mid.proprety,i)
		SetBassAtt(equip.type,propertyItem,_basePropretyTab,_addLvTab,i)
	end

	local _tab1,_addPropretyTab = GetAddAtt(equip,pid)
	-- self.view.mid.addPropretys:SetActive(#_addPropretyTab>0)
	self.view.mid.addPropretys:SetActive(true)
	for i=1, self.view.mid.addPropretys.transform.childCount do
		self.view.mid.addPropretys.transform:GetChild(i-1).gameObject:SetActive(false)
	end

	for i=1,#commonLvId do
		local propertyItem = utils.SGKTools.GetCopyUIItem(self.view.mid.addPropretys,self.view.mid.proprety,i)	
		if _addPropretyTab[i] then
			SetAddAtt(equip.type,propertyItem,_addPropretyTab,i,equip.level)
		else
			if _tab1[i] and _tab1[i].key ==0 then
				local openCfg = CommonConfig.Get(commonLvId[i])
				propertyItem.Text[UI.Text].text = string.format("<color=#00000080>??????(强化至%s级解锁)</color>",openCfg.para1)
			else
				propertyItem:SetActive(false)
			end
		end
	end
	self:refreshViewByAtt(_basePropretyTab,commonLvId,equip.type)
end

function View:UpdatePropretyShowTab(item,propretyShowTab)
	local _suitCfg = HeroScroll.GetSuitConfig(item.suit_id)
	--self:updateSuitDesc(self.view.midSpecial.suitDesc,_suitCfg,item.quality)
	for i=1,self.view.midSpecial.suitDesc.descText.transform.childCount do
		self.view.midSpecial.suitDesc.descText[i]:SetActive(_suitCfg[i*2])
		if _suitCfg[i*2] then
			self.view.midSpecial.suitDesc.descText[i]:TextFormat("<color=#00000099>({0}){1} : {2}</color>",i*2,_suitCfg[i*2][item.quality].name,_suitCfg[i*2][item.quality].desc)
		end
	end

	local showCount = propretyShowTab.isRandom ==0 and #propretyShowTab.proprety or #propretyShowTab.proprety+1
	for i=1,self.view.midSpecial.Propretys.transform.childCount do
		self.view.midSpecial.Propretys.transform.GetChild(i-1):SetActive(false)
	end
	for i=1,showCount do
		local _propertyItem = utils.SGKTools.GetCopyUIItem(self.view.midSpecial.Propretys,self.view.midSpecial.proprety,i)
		local Idx = propretyShowTab.isRandom == 0 and i or i-1
		if propretyShowTab.proprety[Idx] then
			local _cfg = ParameterConf.Get(propretyShowTab.proprety[Idx].key)
			if _cfg then
				local _showValue = ParameterConf.GetPeropertyShowValue(propretyShowTab.proprety[Idx].key,propretyShowTab.proprety[Idx].allValue)
				_propertyItem.Text[UI.Text]:TextFormat("{0} + {1}",_cfg.name,_showValue)
			else
				ERROR_LOG("ParameterConf is nil,key",propretyShowTab.proprety[Idx].key)
			end
		else
			_propertyItem.Text[UI.Text].text = "在以下属性内随机"
			_propertyItem.Text[UI.Text].fontStyle = UnityEngine.FontStyle.Bold
		end
	end

	local y = self.view.midSpecial.proprety[UnityEngine.RectTransform].sizeDelta.y
	self.view.midSpecial.Propretys[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,y*showCount)
	self.view.midSpecial[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,155 +y*showCount)
	self.view[UI.VerticalLayoutGroup].padding.bottom = 20
	self.gameObject.transform:DOScale(Vector3.one,0.1):OnComplete(function()
		self.root.view[UnityEngine.CanvasGroup].alpha = 1;
	end)
end

function View:refreshViewByAtt(_basePropretyTab,_addPropretyTab,_type)
	local y = self.view.mid.proprety[UnityEngine.RectTransform].sizeDelta.y

	self.view.mid.basePropretys[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,#_basePropretyTab>2 and #_basePropretyTab*y or 60)
	self.view.mid.addPropretys[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,#_addPropretyTab>2 and #_addPropretyTab*y or 60)
	
	local base_y = #_basePropretyTab>0 and self.view.mid.basePropretys[UnityEngine.RectTransform].sizeDelta.y or 0
	local add_y = #_addPropretyTab>0 and self.view.mid.addPropretys[UnityEngine.RectTransform].sizeDelta.y or 0
	local _height = base_y>0 and add_y>0 and base_y+add_y+45 or base_y+add_y+40
	self.view.mid[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,_type==0 and _height+115 or _height)
	self.view[UI.VerticalLayoutGroup].padding.bottom = (self.posIdx==3 or self.posIdx==1 ) and 105 or 20
	self.gameObject.transform:DOScale(Vector3.one,0.1):OnComplete(function()
		self.root.view[UnityEngine.CanvasGroup].alpha = 1;
	end)
end

--鉴定(刷新前缀)
local function InIdentification(uuid)
	local equip =EquipmentModule.GetByUUID(uuid)
	if equip then
		local _attribute = equip.attribute
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
									EquipmentModule.ChangeEquipScroll(uuid,i)
								end, 
								function () end, 
								SGK.Localize:getInstance():getValue("common_queding_01"), --确定
								SGK.Localize:getInstance():getValue("common_cancle_01") --取消
							)
						else
							--showDlgError(nil,consumeCfg.name.."不足")
							DialogStack.PushPrefStact("ItemDetailFrame", {id = _attribute[i].cfg.cost_id,type = ItemHelper.TYPE.ITEM,InItemBag=2})
						end
					else
						ERROR_LOG("Cfg is nil,id",_attribute[i].cfg.cost_id)
					end
				else
					EquipmentModule.ChangeEquipScroll(equip.uuid,i)
				end
				break
			end
		end
	end
end

--{[78]="任务道具",[86]="礼包",[89]="礼包",[189]="钥匙宝箱"}
function View:RefUIByType(item)
	self.view.Btns:SetActive(self.posIdx==1 or self.posIdx==3)
	self.view.Btns.BtnLeft.gameObject:SetActive(false)
	self.view.Btns.Btn.gameObject:SetActive(false)
	self.view.Btns.BtnRight.gameObject:SetActive(false)

	if self.posIdx==1 then--在背包里才有出售和使用功能	
		self.view.Btns.BtnLeft.Lock.gameObject:SetActive(false)
		self.view.Btns.BtnLeft[CS.UGUIClickEventListener].interactable=true
		--宝箱
    	self.view.BuyInfo.gameObject:SetActive(item.type_Cfg.quick_use==1)	
		
		if item.type==utils.ItemHelper.TYPE.EQUIPMENT or item.type==utils.ItemHelper.TYPE.INSCRIPTION then
			self.view.Btns.BtnLeft.gameObject:SetActive(true)
			
			self.view.Btns.BtnRight.gameObject:SetActive(true)

			self.view.Btns.BtnLeft.Text[UI.Text].text="强化"

			self.view.Btns.Btn.Text[UI.Text].text="解除绑定"
				
			local equip=EquipmentModule.GetByUUID(item.uuid)

			if not equip then return end--装备被摧毁

			self.view.Btns.Btn.gameObject:SetActive(equip.isLock)

			local btnTip=equip.heroid~=0 and not equip.isLock and ("前往查看") or (item.type==utils.ItemHelper.TYPE.EQUIPMENT and "前往装备" or "前往守护")

			self.view.Btns.BtnRight.Text[UI.Text].text=btnTip

			self.view.Btns.BtnLeft.Lock:SetActive(false)

			local _levelCfg = EquipConfig.EquipmentLevTab()[item.id]
			local _cfg = nil
			if _levelCfg then
				local equip = EquipmentModule.GetByUUID(item.uuid,item.otherPid)
				if equip then
					_cfg = EquipConfig.GetCfgByColumnAndLv(_levelCfg.column,equip.level+1)
				else
					ERROR_LOG("equip is nil,uuid",item.uuid)
				end
			else
				ERROR_LOG("_levelCfg is nil,id",item.id)
			end
	        self.view.Btns.BtnLeft:SetActive(not not _cfg)

			--装备中的装备isLock==false 
			-- self.view.Btns.BtnLeft.Lock:SetActive(equip.heroid~=0 and not equip.isLock)
			-- self.view.Btns.BtnLeft[CS.UGUIClickEventListener].interactable=(equip.isLock or equip.heroid==0)
		else
			if item.type_Cfg.sub_type == 21 or item.type_Cfg.sub_type == 22 then--伙伴碎片 22 --道具碎片
				local canComposeHeroId=item.type_Cfg.sub_type == 21 and item.id - 10000 or item.id - 11000
				local hero=module.HeroModule.GetManager():Get(canComposeHeroId)
				if hero then	
					self.view.Btns.Btn.gameObject:SetActive(true)
					self.view.Btns.Btn.Text[UI.Text].text=item.type_Cfg.sub_type == 21 and "前往升星" or "前往充能"
				else
					local ComposeHeroItemId=item.type_Cfg.sub_type == 21 and item.id or item.id - 1000
					local ComposeHeroItemCount=ItemModule.GetItemCount(ComposeHeroItemId)
					if ComposeHeroItemCount>=10 then
						self.view.Btns.Btn.gameObject:SetActive(true)
						self.view.Btns.Btn.Text[UI.Text].text="合成"
					end
				end
			elseif item.type_Cfg.sub_type == 56 then--水晶
				self.view.Btns.Btn.gameObject:SetActive(true)
				self.view.Btns.Btn.Text[UI.Text].text="前往进阶"
			elseif item.type_Cfg.sub_type == 81 then
				self.view.Btns.Btn.gameObject:SetActive(true)
				self.view.Btns.Btn.Text[UI.Text].text="去赠礼"
			elseif item.type_Cfg.quick_use~=0 then
    			self.view.Btns.Btn.gameObject:SetActive(item.type_Cfg.quick_use~=0)
				self.view.Btns.Btn.Text[UI.Text].text="使用"

				if item.type_Cfg.quick_use==1 then--可使用宝箱
					--self.GiftBagItem=item
					self:ItemOpenGiftBag(item)--宝箱
				end
			end	
		end

		
		CS.UGUIClickEventListener.Get(self.view.mid.IdentificationBtn.gameObject).onClick = function (obj) 
			if item.type==utils.ItemHelper.TYPE.EQUIPMENT then
				InIdentification(item.uuid)
			end
		end

		CS.UGUIClickEventListener.Get(self.view.Btns.BtnLeft.gameObject).onClick = function (obj)
			if item.type==utils.ItemHelper.TYPE.EQUIPMENT or item.type==utils.ItemHelper.TYPE.INSCRIPTION then	
				DialogStack.PushPrefStact("newEquip/EquipAdvance",item.uuid)
				--[==[--分解功能
				local _equipCfg=EquipConfig.GetConfig(item.id)
				local color = "<color="..ItemHelper.QualityTextColor(_equipCfg.quality)..">"
				local tip=string.format("分解 %s%s</color> 将会获得:",color,item.name)
				
				local _equip=EquipmentModule.GetByUUID(item.uuid)
				if _equip then
					local _cfgTab={}
					if _equip.cfg.swallowed_id and _equip.cfg.swallowed_id~=0 then
						local _quenchValue=_equip.cfg.swallowed+ (_equip.cfg.swallowed_incr and _equip.cfg.swallowed_incr * (_equip.level - 1) or 0 ) 
						_cfgTab[_equip.cfg.swallowed_id]=_cfgTab[_equip.cfg.swallowed_id] and _cfgTab[_equip.cfg.swallowed_id]+_quenchValue or _quenchValue
					end

					if _equip.cfg.swallowed_id2 and _equip.cfg.swallowed_id2~=0 then
						local _quenchValue=_equip.cfg.swallowed_id2+ (_equip.cfg.swallowed_incr2 and _equip.cfg.swallowed_incr2 * (_equip.level - 1) or 0)
						_cfgTab[_equip.cfg.swallowed_id2]=_cfgTab[_equip.cfg.swallowed_id2] and _cfgTab[_equip.cfg.swallowed_id2]+_quenchValue or _quenchValue
					end
					--服务器存装备 分解额外返还资源
					if _equip.otherConsume then
						for i=1,#_equip.otherConsume do
							local _consumeId=_equip.otherConsume[1][2]
							local _consumeValue=_equip.otherConsume[1][3]
							_cfgTab[_consumeId]=_cfgTab[_consumeId] and _cfgTab[_consumeId]+_consumeValue or _consumeValue
						end
					end

					local _GetCount=0
					for k,v in pairs(_cfgTab) do
						_GetCount=_GetCount+v
					end
					if _GetCount==0 then
						tip=string.format("确定要分解 %s%s</color>吗？",color,item.name)
					end
					-- local _levelUpCfg=item.type==utils.ItemHelper.TYPE.EQUIPMENT and EquipConfig.UpLevelCoin(_equip.level) or EquipConfig.EquipLeveUpTab(_equip.level)
					-- _cfgTab[_levelUpCfg.id]=_levelUpCfg.value

					local func=function ( ... )
						EquipmentModule.Decompose(item.uuid)
					end

					self:UpEnsurePanel(tip,func,_cfgTab)
				else
					ERROR_LOG("equip is nil ",item.uuid)
				end
				--]==]
			else--出售
				self:ItemOperation(item);
				DialogStack.Pop()
			end
    	end

		CS.UGUIClickEventListener.Get(self.view.Btns.Btn.gameObject).onClick = function (obj) 
			if item.type_Cfg.quick_use==1 then--宝箱
				if not self.UnShowQuickBuyCase then
					ItemModule.OpenGiftBag(item.id,self.UseNum);
					DialogStack.Pop()
				else
					if self.Consume then
						local _shop_id=2
						local _shopItem= self:IsInComposeShop(self.Consume,_shop_id)
						if _shopItem then
							DialogStack.PushPref("easyBuyFrame", {id =self.Consume.id,type =self.Consume.type,shop_id=_shop_id},self.root.Node.gameObject)
						else
							showDlgError(nil,"商品已停售");
						end
					end
				end
			elseif item.type_Cfg.quick_use==3 then--任务道具
				self.QuestId=utils.ItemHelper.GetItemQuest(item.type,item.id)
				if self.QuestId then
					QuestModule.Accept(self.QuestId)
				else
					DialogStack.Pop()
				end
			elseif item.type_Cfg.quick_use==4 then--宝箱
				local exchangeTab = module.ShopModule.GetExchangeItemList(item.id)
                if exchangeTab and next(exchangeTab) then
                    DialogStack.PushPref("exchangeContentFrame", {id=item.id,type=item.type},self.root.Node.gameObject)
                else
                    ERROR_LOG("exchangeTab is nil or {} id",item.id)
                end
			elseif item.type==utils.ItemHelper.TYPE.EQUIPMENT or item.type==utils.ItemHelper.TYPE.INSCRIPTION then
				local equip=EquipmentModule.GetByUUID(item.uuid)
				local _consumeCfg=EquipConfig.ChangePrice(equip.type,equip.quality)
				local _item=ItemHelper.Get(_consumeCfg.type,_consumeCfg.id)
				if equip.isLock then
					local tip=string.format("当前%s已和伙伴绑定,是否消耗以下资源解除绑定?",item.type==utils.ItemHelper.TYPE.EQUIPMENT and "装备" or "守护")--,"<color=#FFD800FF>",_item.name,"</color>")
					local func=function ( ... )
						if _item.count>=_consumeCfg.value then
							EquipmentModule.UnloadEquipment(equip.uuid)
						else
							showDlgError(nil, string.format("%s不足",_item.name))
						end
					end
					local _cfgTab={}
					_cfgTab[_consumeCfg.id]=_consumeCfg.value
					self:UpEnsurePanel(tip,func,_cfgTab)
				end
			elseif item.type_Cfg.sub_type == 21 or item.type_Cfg.sub_type == 22 then
				local canComposeHeroId=item.type_Cfg.sub_type == 21 and item.id - 10000 or item.id - 11000
				local hero=module.HeroModule.GetManager():Get(canComposeHeroId)
				if hero then
					local openGid=item.type_Cfg.sub_type == 21 and 1103 or 1109
					if OpenLevel.GetStatus(openGid) then
						DialogStack.Pop()
						DialogStack.Push("newRole/roleFramework",{heroid = canComposeHeroId,idx=item.type_Cfg.sub_type == 21 and 3 or 4})
					else
						local playerLv=module.HeroModule.GetManager():Get(11000).level
						local openCfg=OpenLevel.GetCfg(openGid)

						if openCfg.open_lev>playerLv then
							showDlgError(nil,string.format("%s级开启%s",openCfg.open_lev,openCfg.functional_name))
						else
							showDlgError(nil,"开启条件未达成")
						end
					end
				else
					local ComposeHeroItemId=item.type_Cfg.sub_type == 21 and item.id or item.id - 1000
					local ComposeHeroItemCount=ItemModule.GetItemCount(ComposeHeroItemId)
					if ComposeHeroItemCount<10 then
						showDlg(self.view,"您还未拥有该角色，是否前往招募?", 
							function ()
								DialogStack.Pop()
								DialogStack.Push("DrawCard/newDrawCardFrame")
							end, 
							function () 
							end, "招募", "取消")
					else
						showDlg(self.view,"您还未解锁该角色，是否前往解锁?", 
							function ()
								DialogStack.Pop()
								DialogStack.Push("newRole/roleFramework",{heroid = 11000,idx=1})
							end, 
							function () 
							end, "解锁", "取消")
					end
				end
			elseif item.type_Cfg.sub_type == 56 then
				local openGid = 1106
				if OpenLevel.GetStatus(openGid) then
					DialogStack.Pop()
					DialogStack.Push("newRole/roleFramework",{heroid = 11000,idx=2})
				else
					local playerLv=module.HeroModule.GetManager():Get(11000).level
					local openCfg=OpenLevel.GetCfg(openGid)

					if openCfg.open_lev>playerLv then
						showDlgError(nil,string.format("%s级开启%s",openCfg.open_lev,openCfg.functional_name))
					else
						showDlgError(nil,"开启条件未达成")
					end
				end
			elseif item.type_Cfg.sub_type == 81 then--去赠礼
				local openGid = 8100
				if OpenLevel.GetStatus(openGid) then
					DialogStack.Pop()
					DialogStack.Push("dataBox/NpcRelationship")
				else
					local playerLv=module.HeroModule.GetManager():Get(11000).level
					local openCfg=OpenLevel.GetCfg(openGid)

					if openCfg.open_lev>playerLv then
						showDlgError(nil,string.format("%s级开启%s",openCfg.open_lev,openCfg.functional_name))
					else
						showDlgError(nil,"开启条件未达成")
					end
				end
			end
		end	

		CS.UGUIClickEventListener.Get(self.view.Btns.BtnRight.gameObject).onClick = function (obj) 
			local equip=EquipmentModule.GetByUUID(item.uuid)
			DialogStack.Pop()
			DialogStack.Push("newRole/roleFramework",{heroid =equip.heroid~=0 and equip.heroid or  11000,idx=1,goInsc=item.type==utils.ItemHelper.TYPE.INSCRIPTION})
		end
	elseif self.posIdx==3 then
		self.view.Btns.Btn.Text[UI.Text].text=self.BtnDesc and self.BtnDesc or "使用"
		self.view.Btns.Btn.gameObject:SetActive(true)
		CS.UGUIClickEventListener.Get(self.view.Btns.Btn.gameObject).onClick = function (obj) 
			DialogStack.Pop()
			DispatchEvent("Add_Degree_Succed");	
		end
	end	
end

function View:UpEnsurePanel(tip,func,cfgTab)
	self.root.EnsurePanel.gameObject:SetActive(true)
	self.root.EnsurePanel.Dialog.Title[UI.Text].text="提示"

	self.root.EnsurePanel.Dialog.Content.tip[UI.Text].text=tip
	local itemCount=0
	local prefab=SGK.ResourcesManager.Load("prefabs/base/IconFrame.prefab")
	local parent=self.root.EnsurePanel.Dialog.Content.Content
	for k,v in pairs(cfgTab) do
		local _cfg=ItemHelper.Get(ItemHelper.TYPE.ITEM,k)
		if v~=0 and _cfg and _cfg.is_show~=0 then
			itemCount=itemCount+1
			local item=nil
			item,self.breakUpUI=self:InCopyUIPrefab(self.breakUpUI,parent,prefab,itemCount)
			utils.IconFrameHelper.Create(item, {
				customCfg=setmetatable({count=v},{__index=_cfg}),
				showDetail=true,
				func=function (ItemIcon)
					ItemIcon.qualityAnimationFx.gameObject:SetActive(false)
					ItemIcon.gameObject.transform.localScale=Vector3.one*0.9
				end
			})
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

---[[检测 出售 使用
function View:ItemOpenGiftBag(item)--89类型均可打开--需要钥匙的 读gift_bag
	local giftItemTab=ItemModule.GetGiftBagConfig(item.id)
	if giftItemTab and giftItemTab.consume then
		local consumeTab=giftItemTab.consume
		for i=1,#consumeTab do
			if item.id~=consumeTab[i].id  then
				local CanOpen=ItemModule.GetItemCount(consumeTab[i].id)>=consumeTab[i].Count
				self:InUseGiftBag(item,consumeTab,CanOpen)
				break
			end
		end
	else
		self:InUseGiftBag(item)
	end
end

function View:InUseGiftBag(item,consumeTab,CanOpen)
	--使用道具数量选择界面
	self.view.Btns.BtnRight.gameObject:SetActive(false)
	
	local Info=self.view.BuyInfo.buyNum
	Info.Consume.gameObject:SetActive(false)
	local numLimit=item.count
	--local ConsumeId=nil
	local Consume=nil
	if consumeTab then
		for i=1,#consumeTab do
			if consumeTab[i].id~= item.id then
				local _consume=ItemHelper.Get(ItemHelper.TYPE.ITEM,consumeTab[i].id)
				local _count=ItemModule.GetItemCount(consumeTab[i].id)
				if _count <numLimit then
					--ConsumeId=consumeTab[i].id
					Consume=_consume
					numLimit=_count
				end
				Info.Consume.gameObject:SetActive(true)
				Info.Consume.Icon[UI.Image]:LoadSprite("icon/".._consume.icon)
				Info.Consume.Num[UI.Text].text=string.format("拥有: %s",_count>0 and _count or string.format("<color=#FF1A1AFF>%s</color>",_count))
				break
			end
		end
	end

	CS.UGUIClickEventListener.Get(Info.Add.gameObject).onClick = function (obj)
		if self.UseNum+1<= numLimit then
			self.UseNum=self.UseNum+1
			Info.num[UI.Text].text=tostring(self.UseNum)
		else
			if item.count>numLimit and Consume then
				showDlgError(nil,string.format("%s不足",Consume.name))
			end
		end
	end
	self.UseNum=numLimit>0 and 1 or 0
	Info.num[UI.Text].text=tostring(self.UseNum)
	CS.UGUIClickEventListener.Get(Info.Max.gameObject).onClick = function (obj)
		if numLimit<=99 then
			self.UseNum=numLimit
			Info.num[UI.Text].text=tostring(self.UseNum)
		else
			self.UseNum=99
			Info.num[UI.Text].text=tostring(self.UseNum)
			showDlgError(nil,string.format("%s同时打开的最大数量为99",item.name))
		end
	end

	CS.UGUIClickEventListener.Get(Info.Sub.gameObject).onClick = function (obj)
		if self.UseNum>1 then
			self.UseNum=self.UseNum-1
			Info.num[UI.Text].text=tostring(self.UseNum)
		end
	end

	CS.UGUIClickEventListener.Get(Info.InputBtn.gameObject).onClick = function (obj) 
		self.root.buyNumPanel.Dialog.Content.Num[UI.InputField].text=self.UseNum
		self.root.buyNumPanel.gameObject:SetActive(true)
	end

	CS.UGUIClickEventListener.Get(self.root.buyNumPanel.Dialog.Close.gameObject).onClick = function (obj) 
		self.root.buyNumPanel.gameObject:SetActive(false)
	end
	CS.UGUIClickEventListener.Get(self.root.buyNumPanel.gameObject,true).onClick = function (obj) 
		self.root.buyNumPanel.gameObject:SetActive(false)
	end

	CS.UGUIClickEventListener.Get(self.root.buyNumPanel.Dialog.Content.Btns.Save.gameObject).onClick = function (obj) 
		self.root.buyNumPanel.gameObject:SetActive(false)
		local _inputNum=tonumber(self.root.buyNumPanel.Dialog.Content.Num[UI.InputField].text)
		if numLimit<_inputNum and Consume then--当输入数量大于宝箱数量时
			--local _consume=ItemHelper.Get(ItemHelper.TYPE.ITEM,ConsumeId)--ItemModule.Get(keyId)
			showDlgError(nil,string.format("%s不足",Consume.name))
		end
		if _inputNum>99 then
			showDlgError(nil,string.format("%s同时打开的最大数量为99",item.name))
		end
		self.UseNum=numLimit>=_inputNum  and _inputNum or numLimit
		self.UseNum=self.UseNum>=99 and 99 or self.UseNum
		Info.num[UI.Text].text=tostring(self.UseNum)
	end

	CS.UGUIClickEventListener.Get(self.root.buyNumPanel.Dialog.Content.Btns.Cancel.gameObject).onClick = function (obj) 
		self.root.buyNumPanel.gameObject:SetActive(false)
	end	

	if Consume then
		self.UnShowQuickBuyCase=not CanOpen
	end
	self.view.Btns.Btn.Text[UI.Text].text=not self.UnShowQuickBuyCase and "使用" or tostring("购买钥匙")
	self.Consume=Consume
end

function View:IsInComposeShop(selectedItem,ShopId)
	if self.compose_shop_items == nil then
		local shopList = ShopModule.GetManager(ShopId and ShopId or compose_shop_id).shoplist; -- 兑换商店
		if not shopList then
			return nil;
		end

		self.compose_shop_items = {}

		for k, v in pairs(shopList or {}) do
			self.compose_shop_items[v.consume_item_type1] = self.compose_shop_items[v.consume_item_type1] or {}
			self.compose_shop_items[v.consume_item_type1][v.consume_item_id1] = v;
		end
	end

	local ct = self.compose_shop_items[selectedItem.type];
	return ct and ct[selectedItem.id] or nil;
end

function View:canCompose(selectItem)
	local shop_item = self:IsInComposeShop(selectItem);
	if not shop_item then
		-- print(selectItem.name, "not int compose shop")
		return false;
	end

	if shop_item.product_item_type ==utils.ItemHelper.TYPE.HERO and HeroModule.GetManager():Get(shop_item.product_item_id)  ~= nil then
		return false;
	else
		if selectItem.count >= shop_item.consume_item_value1 then
			return shop_item;
		end
	end	
end

function View:ItemOperation(item)--出售
	local current_shop_item = self:canCompose(item);
	if not current_shop_item then
		return;
	end
	 
	local _product_item=ItemHelper.Get(current_shop_item.product_item_type,current_shop_item.product_item_id)
	 showDlg(self.view,string.format("是否出售\t%s\n你将获得%s%s%s x%d",item.name,"<color=#FFD800FF>",_product_item.name,"</color>",current_shop_item.product_item_value),
	 	function() ShopModule.Buy(current_shop_item.shop_id, current_shop_item.gid,1,{consume_uuid=item.uuid}); end,
	 	function() end, 
	 "确认","取消")

end
--]]

function View:OnEnable()
	if self.data then
		self:Init(self.data)
	end
end
function View:OnDestroy()
	--DialogStack.Pop()
end

function View:playEffect(effectName,position,node,rotation,scale,layerName,sortOrder)
	local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName .. ".prefab");
	local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
	if o then
		local transform = o.transform;
		transform.localPosition = position or Vector3.zero;
		transform.localRotation =rotation and  Quaternion.Euler(rotation) or Quaternion.identity;
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

function View:listEvent()
	return {
		"QUEST_INFO_CHANGE",
		"ITEM_INFO_CHANGE",
		"EQUIPMENT_INFO_CHANGE",
		"LOCAL _SCROLL_CHANGE",

	}
end

function View:onEvent(event, data)
	if event =="QUEST_INFO_CHANGE" then
		if QuestModule.Get(self.QuestId) then
			if QuestModule.Get(self.QuestId).status==0 then
				DialogStack.Pop()
				showDlgError(nil,string.format("领取任务%s",QuestModule.GetCfg(self.QuestId).name))
			end
		end
	elseif event =="ITEM_INFO_CHANGE" then
		-- if self.GiftBagItem then--针对宝箱(当快速购买时触发功能)---待修改
		-- 	self:ItemOpenGiftBag(self.GiftBagItem)
		-- end
		self:Init(self.data)
	elseif event == "EQUIPMENT_INFO_CHANGE"	 then--针对解绑装备
		local uuid=self.data.uuid
		local _equip=EquipmentModule.GetByUUID(uuid)
		if uuid and  _equip and next(_equip)~=0 then
			self:Init(self.data)
		else
			DialogStack.Pop()
		end
	elseif event == "LOCAL _SCROLL_CHANGE" then
		local o = self:playEffect("fx_xp_up_1", Vector3.zero,self.view.top.IconFrame.gameObject,Vector3.zero,150,"UI",30000)  
		local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
		UnityEngine.Object.Destroy(o, _obj.main.duration)
	-- elseif event == "LOCAL_CLOSE_DETAILFRAME" then
	-- 	DialogStack.Pop()
	end
end

return View