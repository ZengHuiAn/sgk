local ItemHelper = require "utils.ItemHelper"
local ParameterShowInfo = require "config.ParameterShowInfo";
local HeroModule = require "module.HeroModule"
local equipmentModule = require "module.equipmentModule";
local equipmentConfig = require "config.equipmentConfig"
local HeroScroll = require "hero.HeroScroll"
local View = {}

function View:Start(arg)
	self.view = SGK.UIReference.Setup(self.gameObject).view;

	self.UITab={}
	self.BgUITab={}
	self:SetData(arg)

	CS.UGUIClickEventListener.Get(self.view.gameObject).onClick = function (obj)
		DialogStack.Pop()
	end

	self.view.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOLocalMove(Vector3(375,110,0),0.15)
end

function View:deActive(deActive)
	if self.view then
		local co = coroutine.running();
		self.view.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOLocalMove(Vector3(1125,110,0),0.1):OnComplete(function ( ... )
			coroutine.resume(co);
		end)
		coroutine.yield();
		return true
	end
end

function View:SetData(data)
	self.heroID = data and data.heroID or (self.savedValues.HeroID and self.savedValues.HeroID or 11001);
	self.hero = HeroModule.GetManager():Get(self.heroID)


	self.EquipList={}
	self.EquipList.EquipCfg={}
	local equiplist=equipmentModule.GetHeroEquip()[self.heroID] or {};
	--print(sprinttb(equiplist))


	for k,v in pairs(self.UITab) do
		v.gameObject:SetActive(false)
	end
	for k,v in pairs(self.BgUITab) do
		v.gameObject:SetActive(false)
	end
	
	for k,v in pairs(equiplist) do	
		if v.type==0 then--装备
			self.EquipList.EquipCfg[v.placeholder]=equiplist[v.placeholder]--ItemHelper.Get(ItemHelper.TYPE.EQUIPMENT,v.id,v.uuid)
		end
	end
	self.EquipList.ScrollSuit={}
	local ScrollSuit=HeroModule.GetManager():GetPrefixSuit(self.heroID)
	--print(sprinttb(ScrollSuit),self.heroID)
	if next(ScrollSuit)~=nil then
		for k,v in pairs(ScrollSuit) do
			if #v.IdxList>=2 then
				table.insert(self.EquipList.ScrollSuit,v)
			end
		end
	end
	self.EquipList.EquipSuit={}
	local EquipSuit=HeroModule.GetManager():GetEquipSuit(self.heroID)[0]
		print(sprinttb(EquipSuit))
	if next(EquipSuit)~=nil then
		for k,v in pairs(EquipSuit) do
			if #v.IdxList>=2 then
				table.insert(self.EquipList.EquipSuit,v)
			end
		end
	end
	self:InitView()
end

function View:InitView()
	self:RefBgSize()
	self:RefSuitUI(1)
	self:RefSuitUI(2)
end

function View:RefBgSize()
	local num=#self.EquipList.ScrollSuit>=#self.EquipList.EquipSuit and #self.EquipList.ScrollSuit or #self.EquipList.EquipSuit
	if num>=2 then
		for i=1,num-1 do
			local _obj
			if self.BgUITab[i]==nil then
				_obj=UnityEngine.Object.Instantiate(self.view.Content.placeholder.gameObject)
				_obj.transform:SetParent(self.view.Content.gameObject.transform,false)
				self.BgUITab[i]=_obj
			else
				_obj=self.BgUITab[i]
			end
			_obj.gameObject:SetActive(true)
		end
	end
end

function View:RefSuitUI(type)
	local list=type==1 and self.EquipList.ScrollSuit or self.EquipList.EquipSuit
	local root=type==1 and self.view.Content.ScrollSuit.gameObject.transform or self.view.Content.EquipSuit.gameObject.transform

	if #list>0 then
		for i=1,#list do
			local cfg=list[i]
			local Item,Icon=self:InRefSuitUI(self.view.Item,root,type,cfg.name)
			Item.Icon.name[UI.Text].text=cfg.name
			Item.Icon.num[UI.Text].text=string.format("X%d",#cfg.IdxList)
			
			Icon[UI.Image]:LoadSprite("icon/"..cfg.icon)

			Item.desc[UI.Text].text=string.format("%s2件:%s\n4件:%s%s","<color=#35EAB0FF>",cfg.Desc[1],cfg.Desc[2],"</color>")
			
			self:RefIdxColor(cfg,Item,type)

		end
	else
		local Item=self:InRefSuitUI(self.view.NoSuitTip,root,type,"None"..type)
		Item.Tip[UI.Text]:TextFormat("暂无{0}效果",type==1 and "前缀组合" or "护符套装")
	end
end

function View:InRefSuitUI(prefab,root,type,k)
	local _obj
	if self.UITab[k]==nil then
		_obj=UnityEngine.Object.Instantiate(prefab.gameObject)
		_obj.transform:SetParent(root,false)
		self.UITab[k]=_obj

	else
		_obj=self.UITab[k]
	end
	_obj:SetActive(true)
	local Item=CS.SGK.UIReference.Setup(_obj.transform)
	local Icon=type==1 and Item.Icon.scrollIcon.Icon or Item.Icon.equipIcon.Icon
	Item.Icon.scrollIcon.gameObject:SetActive(type==1)
	Item.Icon.equipIcon.gameObject:SetActive(type==2)
	return Item,Icon
end

function  View:RefIdxColor(cfg,Item,type)
	for i=1,6 do
		Item.Icon.NumGrid[i][UI.Image].color={r=0.5,g=0.5,b=0.5,a=1}
	end
	for i=1,#cfg.IdxList do
		local Idx=cfg.IdxList[i]
		local equip =self.EquipList.EquipCfg[Idx+6]
		local quality=(type==1 and  HeroScroll.GetScrollConfig(equip.pre_property1_key).quality) or equip.quality
		Item.Icon.NumGrid[cfg.IdxList[i]][UI.Image].color=ItemHelper.QualityColor(quality)
	end
end

function View:GetSuitDescByQuality(equip,type)
	local suitCfg
	if type ==1 then
		local HeroScrollConf = HeroScroll.GetScrollConfig(equip.pre_property1_key)	
		suitCfg =HeroScroll.GetSuitConfig(HeroScrollConf.suit_id);
	else
		local cfg = equipmentConfig.EquipmentTab(equip.id)
		suitCfg = HeroScroll.GetSuitConfig(cfg.suit_id);
	end
	return suitCfg
end

function View:OnDestroy( ... )
	self.savedValues.HeroID=self.heroID;
end

function View:listEvent()
	return {
		"Equip_Hero_Index_Change",
	}
end

function View:onEvent(event, data)
	if event == "Equip_Hero_Index_Change" then
		local info={}
		info.heroID=data.heroid
		self:SetData(info)
	end
end

return View;