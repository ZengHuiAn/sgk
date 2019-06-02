local ItemHelper = require "utils.ItemHelper"
local ParameterShowInfo = require "config.ParameterShowInfo";
local HeroModule = require "module.HeroModule"
local View = {}

function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	self.Property = self.view.view;

	self:SetData(data)

	self.Property.Bg.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(750,254),0.15):OnComplete(function ( ... )
		self.Property.Top[UnityEngine.CanvasGroup]:DOFade(1,0.15)
		self.Property.Bg.sign.gameObject.transform:DOLocalMove(Vector3(-375,128,0),0.15)
	end)
end
function View:deActive(deActive)
	if self.view then
		local co = coroutine.running();
		self.Property.Top[UnityEngine.CanvasGroup]:DOFade(0,0.1):OnComplete(function ( ... )
				self.Property.Top[UnityEngine.CanvasGroup]:DOFade(0,0.1)
				self.Property.Bg.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(750,80),0.1):OnComplete(function ( ... )
					coroutine.resume(co);
				end)
		end)
		coroutine.yield();
		return true
	end
end

function View:SetData(data)
	self.heroID = data and data.heroID or (	self.savedValues.HeroID and self.savedValues.HeroID  or 11001);
	self.hero = HeroModule.GetManager():Get(self.heroID)
	self:UpdateTop();
end
local _tab={}
function View:UpdateTop()
	local data=self.hero:GetWeaponProp()
	local R = {"hpp","mpp", "hpRevert", "mpRevert","ad","ap","armor","resist",
		 "ignoreArmor","ignoreArmorPer","ignoreExtraArmorPer","ignoreResist",
		"ignoreResistPer",
		 "phyDamagePromote","magicDamagePromote",--"addPhyDamage","addMagicDamage","addTrueDamage",
		-- "critPer","critValue","reduceCritPer","reduceCritValue","phySuck","magicSuck","speed","combo",
		-- "reduceDamage","tenacity","phyDamageReduce","magicDamageReduce",
			}
	local i=0;
	for _, k in ipairs(R) do
		i=i+1;
		local property =self.Property.Top.PropertyNum[i]--SGK.UIReference.Setup(CS.UnityEngine.GameObject.Instantiate( prefab.gameObject,self.Property.Top.rightPropertyNum.gameObject.transform));
		local cfg=ParameterShowInfo.Get(k)
		property.num.Key[UI.Text].text=string.format("%s:",cfg.name);
		property.num.Value[UI.Text].text= tostring(math.floor(data.props[k]))	


		if i>=4 then
			if  _tab[(i-3)%4==0 and 4 or (i-3)%4]==nil then
				_tab[(i-3)%4==0 and 4 or (i-3)%4]={}
			end
			table.insert(_tab[(i-3)%4==0 and 4 or (i-3)%4],cfg)
		end
		property.num.gameObject:SetActive(true);
	end
	for i=1,4 do
		CS.UGUIPointerEventListener.Get(self.Property.Top.PropertyNum.showButtons[i].gameObject).onPointerDown = function(go, pos)
			self:refreshdetailInfo(_tab[i])
		end
		CS.UGUIPointerEventListener.Get(self.Property.Top.PropertyNum.showButtons[i].gameObject).onPointerUp = function(go, pos)
			self:resetDetailInfoUI()
		end
	end
end

function View:resetDetailInfoUI()
	self.Property.Top.Pos.detailInfoText.gameObject:SetActive(false)
end

function View:refreshdetailInfo(cfg)
	self.Property.Top.Pos.detailInfoText.gameObject:SetActive(true)	
	self.Property.Top.Pos.detailInfoText[UI.Text].text=string.format("%s:%s\n%s:%s\n%s:%s",cfg[1].name,cfg[1].desc,cfg[2].name,cfg[2].desc,cfg[3].name,cfg[3].desc)
	self.Property.Top.Pos.detailInfoText.tip[UI.Text].text=string.format("%s:%s%s%s\n%s:%s%s%s\n%s:%s%s%s",cfg[1].name,"<color=#FFD800FF>",cfg[1].desc,"</color>",cfg[2].name,"<color=#FFD800FF>",cfg[2].desc,"</color>",cfg[3].name,"<color=#FFD800FF>",cfg[3].desc,"</color>")
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