local ItemHelper = require "utils.ItemHelper"
local ParameterShowInfo = require "config.ParameterShowInfo";
local HeroModule = require "module.HeroModule"
local View = {}
function View:Start(arg)
	self.root =SGK.UIReference.Setup(self.gameObject);
	self.view=self.root.view
	self:RefView()
	self:InitView(arg)

	self.view.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(0,270),0.15):OnComplete(function ( ... )
		self.view[UnityEngine.CanvasGroup]:DOFade(1,0.15)
	end)
	CS.UGUIClickEventListener.Get(self.root.gameObject).onClick = function()
		--CS.UnityEngine.GameObject.Destroy(self.root.gameObject)
	end
end

function View:deActive(deActive)
	if self.view then
		local co = coroutine.running();
		self.view[UnityEngine.CanvasGroup]:DOFade(0,0.1):OnComplete(function ( ... )
			--self.view.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(750,0),0.1):OnComplete(function ( ... )
				coroutine.resume(co);
			--end)
		end)
		coroutine.yield();
		DispatchEvent("RoleEquipBack")
		return true
	end
end

local R1 = {{"ad","armor","addPhyDamage","phyDamageAbsorb","ignoreArmor","ignoreArmorPer"},
			{"ap","resist","addMagicDamage","magicDamageAbsorb","ignoreResist","ignoreResistPer"},
			{"speed","critPer","critValue","phySuck",1232,"tenacity",},
			{"combo","reduceCritPer","reduceCritValue","magicSuck",1233,"hpRevert",}
		}
local R2 = {{"phyDamagePromote","magicDamagePromote",1604,1624,1614,1634},
			{"waterMaster","fireMaster",1603,1623, 1613, 1633,},
			{"airMaster","dirtMaster",1601,1621, 1611, 1631,},
			{"lightMaster","darkMaster",1602,1622, 1612, 1632,},
		}

function View:InitView(data)
	self.heroID = data and data.heroID or (self.savedValues.HeroID and self.savedValues.HeroID or 11001);
	self.hero = HeroModule.GetManager():Get(self.heroID)

	self.status = data and data.state 
	if self.status==nil  then
		self.status=true --为角色 false为武器
	end
	self.weaponData=self.hero:GetWeaponProp()

	
	self.SelectIdx=0

	self._tab={}
	self.sizeX=self.view[UnityEngine.RectTransform].sizeDelta.x
	self:RefProperty(R1,0)
	self:RefProperty(R2,1)

	self.UIPageViewScript=self.view.pageView[CS.UIPageView]
	self.UIPageViewScript.OnPageChanged =(function (index)
		self.SelectIdx=index
 		self.view.TogglePoint[1][UI.Toggle].isOn=index==0
 		self.view.TogglePoint[2][UI.Toggle].isOn=index==1
 	end)
end

function View:RefView()
	self._UITab={}
	for i=1,4 do
		CS.UGUIPointerEventListener.Get(self.view.showButtons[i].gameObject).onPointerDown = function(go, pos)
			self:refreshdetailInfo(self._tab[self.SelectIdx][i])
		end
		CS.UGUIPointerEventListener.Get(self.view.showButtons[i].gameObject).onPointerUp = function(go, pos)
			self.view.Pos.detailInfoText.gameObject:SetActive(false)
		end
	end
end

function View:RefProperty(R,Idx)
	self._tab[Idx]={}

	local root=Idx==0 and self.view.pageView.Viewport.Content.page1 or self.view.pageView.Viewport.Content.page2
	
	local i=0;
	local prefab =self.view.property
	for m=1,#R do
		for _, k in ipairs(R[m]) do
			i=i+1;
			local _obj=nil
			local cfg = ParameterShowInfo.Get(k);
			if cfg then
				if self._UITab[k]==nil then
					_obj=UnityEngine.Object.Instantiate(prefab.gameObject)
					_obj.transform:SetParent(root.gameObject.transform,false)
					self._UITab[k]=_obj
				else
					_obj=self._UITab[k]
				end

				_obj.name=tostring(k)
				_obj.gameObject:SetActive(true)
				local property=CS.SGK.UIReference.Setup(_obj.transform)

				property.num.Key[UI.Text].text=string.format("%s:",cfg.name);

				if self.status then
					if cfg.rate == 1 then
						property.num.Value[UI.Text].text = tostring(math.ceil(self.hero[k]));
					else
						local _value=type(k)=="string" and math.ceil(self.hero[k]*100)  or math.ceil(self.hero[k]*100/cfg.rate)  
						property.num.Value[UI.Text].text = string.format("%s%%",tostring(_value==0 and 0 or _value))
					end
				else
					property.num.Value[UI.Text].text= tostring(math.ceil(self.weaponData.props[k]))	
				end

				self._tab[Idx][m]=self._tab[Idx][m] or {}
				
				table.insert(self._tab[Idx][m],cfg)
				property.num.gameObject:SetActive(true);
			end
		end
	end
	local _width=root[CS.UnityEngine.RectTransform].sizeDelta.x
	local _height=prefab[CS.UnityEngine.RectTransform].sizeDelta.y
	root[CS.UnityEngine.RectTransform].sizeDelta=CS.UnityEngine.Vector2(_width,(_height+8)*#R[1]+65)
end

function View:refreshdetailInfo(cfg)
	if cfg==nil then return end
	self.view.Pos.detailInfoText.gameObject:SetActive(true)

	self.view.Pos.detailInfoText[UI.Text].text=string.format(string.rep("%s:%s\n",#cfg),
		cfg[1] and cfg[1].name or "",cfg[1] and cfg[1].desc or "",
		cfg[2] and cfg[2].name or "",cfg[2] and cfg[2].desc or "",
		cfg[3] and cfg[3].name or "",cfg[3] and cfg[3].desc or "",
		cfg[4] and cfg[4].name or "",cfg[4] and cfg[4].desc or "",
		cfg[5] and cfg[5].name or "",cfg[5] and cfg[5].desc or "",
		cfg[6] and cfg[6].name or "",cfg[6] and cfg[6].desc or ""
	)

	self.view.Pos.detailInfoText.tip[UI.Text].text=string.format(string.rep("%s:%s%s%s\n",#cfg),
		cfg[1] and cfg[1].name or "","<color=#FFD800FF>",cfg[1] and cfg[1].desc or "","</color>",
		cfg[2] and cfg[2].name or "","<color=#FFD800FF>",cfg[2] and cfg[2].desc or "","</color>",
		cfg[3] and cfg[3].name or"" ,"<color=#FFD800FF>",cfg[3] and cfg[3].desc or "","</color>",
		cfg[4] and cfg[4].name or"" ,"<color=#FFD800FF>",cfg[4] and cfg[4].desc or "","</color>",
		cfg[5] and cfg[5].name or"" ,"<color=#FFD800FF>",cfg[5] and cfg[5].desc or "","</color>",
		cfg[6] and cfg[6].name or"" ,"<color=#FFD800FF>",cfg[6] and cfg[6].desc or "","</color>"
	)
end


function View:OnDestroy( ... )
	self.savedValues.HeroID=self.heroID;
	self.savedValues.CurrView=self.CurrView
end

function View:listEvent()
	return {
		"Equip_Hero_Index_Change",
		"REF_EASYDATA_DATA",
	}
end

function View:onEvent(event, data)
	if event == "Equip_Hero_Index_Change" or "REF_EASYDATA_DATA" then
		local info={}
		info.heroID=data.heroid
		self:InitView(info)
	end
end

return View;