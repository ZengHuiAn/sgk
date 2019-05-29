local ItemHelper = require "utils.ItemHelper"
local ParameterShowInfo = require "config.ParameterShowInfo";
local HeroModule = require "module.HeroModule"
local equipmentModule = require "module.equipmentModule";
local equipmentConfig = require "config.equipmentConfig"
local View = {}

function View:Start(arg)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self.Property = self.view.viewRoot.view;

	self:SetData(arg)
	self:SetCallback();	

	self.view.viewRoot.Bg.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(750,485),0.15):OnComplete(function ( ... )
		self.Property[UnityEngine.CanvasGroup]:DOFade(1,0.15)
		self.view.viewRoot.Bg.sign.gameObject.transform:DOLocalMove(Vector3(-375,265,0),0.15)
	end)		
end

function View:deActive(deActive)
	if self.view.viewRoot then
		local co = coroutine.running();
		self.Property[UnityEngine.CanvasGroup]:DOFade(0,0.1):OnComplete(function ( ... )
			self.view.viewRoot.view[UnityEngine.CanvasGroup]:DOFade(0,0.1)
			self.view.viewRoot.Bg.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(750,80),0.1):OnComplete(function ( ... )
				coroutine.resume(co);
			end)
		end)
		coroutine.yield();
		return true
	end
end

function View:SetData(data)
	self.heroID = data and data.heroID or (self.savedValues.HeroID and self.savedValues.HeroID or 11001);
	self.hero = HeroModule.GetManager():Get(self.heroID)
	self._tab={}
	self.EquipList={}
	self.EquipList.equiplist=equipmentModule.GetHeroEquip()[self.heroID] or {};
	self.EquipList.EquipSuit=HeroModule.GetManager():GetEquipSuit(self.heroID)[0]
	self.EquipList.ScrollSuit=HeroModule.GetManager():GetPrefixSuit(self.heroID)[0]
	self.EquipList.EquipCfg={}

	for k,v in pairs(self.EquipList.equiplist) do	
		if v.type==0 then--装备
			if self.EquipList.EquipCfg[v.uuid]==nil then
				self.EquipList.EquipCfg[v.uuid]={}
				self.EquipList.EquipCfg[v.uuid].equipCfg=ItemHelper.Get(ItemHelper.TYPE.EQUIPMENT,v.id,v.uuid)
			end	
		end
	end

	self:UpdateTop();
	self:UpdateBottom();
end

function View:SetCallback()
	self.Property.Top.tip.propertyDetailButton[UI.Button].onClick:AddListener(function ()
		DialogStack.Push("DetailPropertyValueFrame",{heroid = self.heroID,type=1})
	end)
	
	self.Property.detailPropertyPage.Bg[UI.Button].onClick:AddListener(function ()	
		self.Property.detailPropertyPage.gameObject:SetActive(false);
	end)

	self.Property.detailSuitDescription.Bg[UI.Button].onClick:AddListener(function ()	
		self.Property.detailSuitDescription.gameObject:SetActive(false);
	end)
end

function View:UpdateTop()
	local R = {"hpp", "mpp", "hpRevert","__",
		"ad","ap","armor","resist","speed",
		"combo","critPer","critValue",
	}
	local i=0;
	for _, k in ipairs(R) do
		i=i+1;
		local cfg = ParameterShowInfo.Get(k);
		local property =self.Property.Top.rightPropertyNum[i]
		if cfg then 
			property.num.Key[UI.Text].text=cfg.name..":";
			if cfg.rate == 1 then
				property.num.Value[UI.Text].text = tostring(math.floor(self.hero[k]));
			else
				property.num.Value[UI.Text].text = string.format("%d%%", math.floor(self.hero[k]/cfg.rate));
			end

			if self._tab[i%4==0 and 4 or i%4]==nil then
				self._tab[i%4==0 and 4 or i%4]={}
			end
			table.insert(self._tab[i%4==0 and 4 or i%4],cfg)
			property.num.gameObject:SetActive(true);
		end
	end
	for i=1,4 do
		CS.UGUIPointerEventListener.Get(self.Property.Top.rightPropertyNum.showButtons[i].gameObject).onPointerDown = function(go, pos)
			self:refreshdetailInfo(self._tab[i])
		end
		CS.UGUIPointerEventListener.Get(self.Property.Top.rightPropertyNum.showButtons[i].gameObject).onPointerUp = function(go, pos)
			self.Property.Pos.detailInfoText.gameObject:SetActive(false)
		end
	end
end

function View:refreshdetailInfo(cfg)
	if cfg==nil then return end
	self.Property.Pos.detailInfoText.gameObject:SetActive(true)	
	self.Property.Pos.detailInfoText[UI.Text].text=string.format(string.rep("%s:%s\n",#cfg),cfg[1].name,cfg[2].desc,cfg[2].name,cfg[2].desc,cfg[3] and cfg[3].name or "",cfg[3] and cfg[3].desc or "")
	self.Property.Pos.detailInfoText.tip[UI.Text].text=string.format(string.rep("%s:%s%s%s\n",#cfg),cfg[1].name,"<color=#FFD800FF>",cfg[1].desc,"</color>",cfg[2].name,"<color=#FFD800FF>",cfg[2].desc,"</color>",cfg[3] and cfg[3].name or"" ,"<color=#FFD800FF>",cfg[3] and cfg[3].desc or "","</color>")
end

function View:UpdateBottom()
	self:refreshBottomUIShow(self.EquipList.EquipSuit,self.Property.Bottom.Left,1)
	self:refreshBottomUIShow(self.EquipList.ScrollSuit,self.Property.Bottom.Right,2)
end

function  View:refreshBottomUIShow(suitList,Item,type)
	self.lastSelectProperty=nil
	if next(suitList)~=nil then
		local i=0;
		Item.NoSuitTip.gameObject:SetActive(true)
		for _,v in pairs(suitList) do
			if #v.IdxList>=2 then
				Item.NoSuitTip.gameObject:SetActive(false)
				i=i+1;
				local property =Item.Grid[i]		
				self:refreshSuitDescNum(property,v,type)
				property.gameObject:SetActive(true);
				property.Button[UI.Button].onClick:AddListener(function ()
					self:UpdateSuitDescription(v,type)
				end)
			end
		end
	else
		Item.NoSuitTip.gameObject:SetActive(true)
	end
end

function  View:refreshSuitDescNum(Desc,suitDesc,type)
	for i=1,6 do
		Desc.NumGrid[i].border.gameObject:SetActive(false)			
	end
	local equip=nil
	for i=1,#suitDesc.IdxList do
		Desc.NumGrid[suitDesc.IdxList[i]].border.gameObject:SetActive(true)

		for k,v in pairs(self.EquipList.equiplist) do
			if v.type==0 then--装备
				if v.placeholder== suitDesc.IdxList[i]+6 then
					equip =self.EquipList.EquipCfg[v.uuid]
					Desc.NumGrid[suitDesc.IdxList[i]].border[UI.Image].color=ItemHelper.QualityColor(equip.equipCfg.quality);
				end	
			end
		end
	end

	Desc.Icon.suitIcon.gameObject:SetActive(type==1)
	Desc.Icon.scrollIcon.gameObject:SetActive(type==2)

	local Icon=type==1 and Desc.Icon.suitIcon.Icon or Desc.Icon.scrollIcon.Icon
	Icon[UI.Image]:LoadSprite("icon/" ..suitDesc.icon );
	
	if Desc.num then	
		Desc.num[UI.Text].text="x"..#suitDesc.IdxList	
	end
	Desc.name[UI.Text].text=suitDesc.name	
end

function View:UpdateSuitDescription(suitDesc,type)
	local _, color1 =UnityEngine.ColorUtility.TryParseHtmlString('#35EAB0FF');	 
	local _, color2 =UnityEngine.ColorUtility.TryParseHtmlString('#898989FF');

	self.Property.detailSuitDescription.gameObject:SetActive(true);
	local  Desc =self.Property.detailSuitDescription.description;

	Desc.description2[UI.Text].text=suitDesc.Desc[1]
	Desc.description4[UI.Text].text=suitDesc.Desc[2]
	--Desc.description6[UI.Text].text=suitDesc.Desc[2]
	Desc.tip6.gameObject:SetActive(false)
	Desc.description6.gameObject:SetActive(false)

	Desc.description2[UI.Text].color=#suitDesc.IdxList>=2 and color1 or color2	
	Desc.description4[UI.Text].color=#suitDesc.IdxList>=4 and color1 or color2
	Desc.description6[UI.Text].color=#suitDesc.IdxList>=6 and color1 or color2

	self:refreshSuitDescNum(Desc,suitDesc,type)
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