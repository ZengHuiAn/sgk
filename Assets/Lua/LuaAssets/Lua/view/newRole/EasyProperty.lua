local HeroModule = require "module.HeroModule"
local ParameterConf = require "config.ParameterShowInfo";
local View = {}
function View:Start(data)
	self.root =SGK.UIReference.Setup(self.gameObject);
	self.view=self.root.view
	self._UITab={}

	self:InitView(data)
	self.view.gameObject.transform.localPosition=Vector3(1000,65,0)
	self.view.gameObject.transform:DOLocalMove(Vector3(0,65,0),0.1)
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)	
		self.view.transform:DOLocalMove(Vector3(1000,65,0),0.1):OnComplete(function ( ... )
			if self.PropertyFrame then
				DispatchEvent("Open_EquipGroup_Frame",{idx=7})
			end
			CS.UnityEngine.GameObject.Destroy(self.gameObject)	
		end)
	end
	CS.UGUIClickEventListener.Get(self.view.bg.top_static.DetailBtn.gameObject).onClick = function()
		
		DispatchEvent("Open_EquipGroup_Frame",{idx=7})
			
		if not self.PropertyFrame then
			self.PropertyFrame="newPropertyFrame"
			DialogStack.PushPref("newPropertyFrame", {heroID =data.heroid,state=true},self.root.gameObject.transform)
		else
			self.PropertyFrame = DialogStack.GetPref_list(self.PropertyFrame)
			if self.PropertyFrame then
				CS.UnityEngine.GameObject.Destroy(self.PropertyFrame.gameObject)
			end
			self.PropertyFrame=nil
		end
	end
end

local showAddTab={["ad"]={"baseAd","extraAd"},["ap"]={"baseAp","extraAp"},["armor"]={"baseArmor","extraArmor"},
		["resist"]={"baseResist","extraResist"},["hpp"]={"baseHp","extraHp"}}
function View:InitView(data)
	self.heroID = data and data.heroid or 11000;
	self.hero = HeroModule.GetManager():Get(self.heroID)

	self.status = data and data.ViewState 
	if self.status==nil  then
		self.status=true --为角色 false为武器
	end
	self.weaponData=self.hero:GetWeaponProp()

	local rootTab={self.view.bg.top,self.view.bg.mid,self.view.bg.bottom}
	local prefab1=self.view.propertyItem
	local prefab2=self.view.propertyItem2

	local tab=ParameterConf.GetHeroPeropertyCfg(self.heroID)
	local R={}

	while tab["property"..(#R+1)] do 
		table.insert(R,tab["property"..(#R+1)])
	end

	local _height=prefab1[CS.UnityEngine.RectTransform].sizeDelta.y

	for k,v in pairs(self._UITab) do
		v.gameObject:SetActive(false)
	end

	local showTab={}
	if R then
		for i=1,#R do
			if R[i]~="0" then
				if i<=4 then
					showTab[1]=showTab[1] or {}
					table.insert(showTab[1],R[i])		
				elseif i<= 9 then
					showTab[2]=showTab[2] or {}
					table.insert(showTab[2],R[i])
				else
					showTab[3]=showTab[3] or {}
					table.insert(showTab[3],R[i])
				end
			end
		end

		for i=1,#showTab do
			self.view.bg[i+1][CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,i~=3 and (showTab[i] and (_height+2)*#showTab[i]+20 or (_height+2)*math.ceil(#showTab[i]/2)+20) or 0);
			if showTab[i] then
				self:RefProperty(showTab[i],rootTab[i],i<=2 and prefab2 or prefab1,i>2 and true)
			end
			if i~=3 then
				self.view.bg[i+1][UI.VerticalLayoutGroup].enabled =true
			end
		end
		
		self.view.bg[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,(_height+2)*((showTab[1] and #showTab[1] or 0)+(showTab[2] and #showTab[2] or 0)+math.ceil(showTab[3] and #showTab[3]/2 or 0))+100)
		self.view[CS.UnityEngine.RectTransform].sizeDelta=CS.UnityEngine.Vector2(430,(_height+2)*((showTab[1] and #showTab[1] or 0)+(showTab[2] and #showTab[2] or 0)+math.ceil(showTab[3] and #showTab[3]/2 or 0))+110)
	end
end

function View:RefProperty(R,root,prefab,showMark)
	for i=1,#R do
		local k=R[i]
		local _obj=nil
		local cfg = ParameterConf.Get(k);
		if cfg then
			if self._UITab[root.gameObject.name..i] then
				_obj=self._UITab[root.gameObject.name..i]
			else
				_obj=UnityEngine.Object.Instantiate(prefab.gameObject)
				_obj.transform:SetParent(root.gameObject.transform,false)
				self._UITab[root.gameObject.name..i]=_obj			
			end

			_obj.name=tostring(k)
			_obj.gameObject:SetActive(true)
		
			local property=CS.SGK.UIReference.Setup(_obj.transform)
			if property.Icon and cfg.icon~="" then
				property.Icon[UI.Image]:LoadSprite("propertyIcon/" ..cfg.icon)
			end

			local str=string.format("%s:%s",cfg.name,cfg.desc)
			utils.SGKTools.ShowItemNameTip(_obj,str,1,20)

			property.key[UI.Text].text=string.format("%s:",cfg.name);
			if self.status then
				if showAddTab[k] then
					local _value1=ParameterConf.GetPeropertyShowValue(k,self.hero[showAddTab[k][1]])
					if self.hero[showAddTab[k][2]]>0 then
						local _value2=ParameterConf.GetPeropertyShowValue(k,self.hero[showAddTab[k][2]])	
						property.value[UI.Text].text =string.format("%s%s<color=#FFD800FF>+%s</color>",showMark and "+" or "",_value1,_value2)
					else
						property.value[UI.Text].text =string.format("%s%s",showMark and "+" or "",_value1)
					end
				else
					local __value = self.hero[k]
					if k == "critValue" then
						__value = self.hero[k] + 1.5
					end
					local _value=ParameterConf.GetPeropertyShowValue(k,__value)	
					property.value[UI.Text].text =string.format("%s%s",showMark and "+" or "",_value)
				end
			else
				property.value[UI.Text].text= tostring(math.floor(self.weaponData.props[k]))	
			end
		else
			ERROR_LOG("cfg is nil",k)
		end
	end
end

function View:listEvent()
	return {
		"Equip_Hero_Index_Change",
		"REF_EASYDATA_DATA",
	}
end

function View:onEvent(event, data)
	if event == "Equip_Hero_Index_Change" then
		local info={}
		info.heroid=data.heroid
		info.ViewState=self.status 
		self.view.bg.top[UI.VerticalLayoutGroup].enabled = false
		self.view.bg.mid[UI.VerticalLayoutGroup].enabled =false
		self:InitView(info)
	elseif event == "REF_EASYDATA_DATA" then
		self:InitView(data)
	end
end

return View;