local ItemHelper=require"utils.ItemHelper"
local ParameterShowInfo = require "config.ParameterShowInfo";
local HeroModule = require "module.HeroModule"

local View = {}

function View:Start(data)
	self.view=CS.SGK.UIReference.Setup(self.gameObject);
	self:Init(data);
end


function View:Init(data)
	self.hero=HeroModule.GetManager():Get(data.heroid)
	self.view.Bg[UI.Button].onClick:AddListener(function ()	
		DialogStack.Pop()
	end) 

	local L={}
	if data.type==1 then
		L = {
			{Key="生命:",Value=tostring(math.floor(self.hero.hp))},
			{Key="法力:",Value=tostring(math.floor(self.hero.mp))},
			{Key="战力:",Value=tostring(math.floor(self.hero.capacity))},
			}
	else	
		local _L = {"hpp", "mpp", "ad", }
		local _tab={}
		for _, k in ipairs(_L) do
			local cfg = ParameterShowInfo.Get(k);
			_tab.Key=cfg.name..":";
			if cfg.rate == 1 then
				_tab.Value=tostring(math.floor(self.hero[k]));
			else
				_tab.Value = string.format("%d%%", math.floor(self.hero[k]/cfg.rate));
			end
			table.insert(L,_tab)
		end		
	end

	for i=1,#L do
		local property =self.view.Grid[i]--SGK.UIReference.Setup(CS.UnityEngine.GameObject.Instantiate(prefab.gameObject,self.Property.Top.leftPropertyNum.gameObject.transform ));
		property.Key[UI.Text]:TextFormat("{0}",L[i].Key)--.text=L[i].Key;
		property.Value[UI.Text].text=L[i].Value;
		property.gameObject:SetActive(true);
	end

	local R = {--"hpp", "mpp","ap", "hpRevert",
				 "ad","mpRevert","armor","resist","speed",
				"combo","critPer","critValue",
				"reduceCritPer","reduceCritValue","ignoreArmor","ignoreArmorPer",
				"ignoreResist","ignoreResistPer","phySuck","magicSuck",   
				}
				
	local i=#L;
	local tab={}
	for _, k in ipairs(R) do
		local cfg = ParameterShowInfo.Get(k);
		i=i+1;
		local property =self.view.Grid[i]--SGK.UIReference.Setup(CS.UnityEngine.GameObject.Instantiate( prefab.gameObject,self.Attribute.numPage.numGrid.gameObject.transform));

		property.Key[UI.Text].text=cfg.name..":";
		property.Value[UI.Text].text= cfg.rate == 1  and tostring(math.floor(self.hero[k])) or string.format("%d%%", math.floor(self.hero[k]/cfg.rate));
		if i>=4 then
			if  tab[(i-3)%4==0 and 4 or (i-3)%4]==nil then
				tab[(i-3)%4==0 and 4 or (i-3)%4]={}
			end
			table.insert(tab[(i-3)%4==0 and 4 or (i-3)%4],cfg)	
		end
		property.gameObject:SetActive(true);
	end
	for i=1,4 do	
		CS.UGUIPointerEventListener.Get(self.view.Grid.showButtons[i].gameObject).onPointerDown = function(go, pos)
			self:refreshdetailInfo(tab[i])
		end
		CS.UGUIPointerEventListener.Get(self.view.Grid.showButtons[i].gameObject).onPointerUp = function(go, pos)
			self.view.Pos.detailInfoText.gameObject:SetActive(false)
		end
	end
	self.view.tip[UI.Text]:DOFade(0,0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad)
end

function View:refreshdetailInfo(cfg)
	if cfg==nil then return end
	self.view.Pos.detailInfoText.gameObject:SetActive(true)	
	self.view.Pos.detailInfoText[UI.Text].text=string.format("%s:%s\n%s:%s\n%s:%s\n%s:%s\n",cfg[1].name,cfg[1].desc,cfg[2].name,cfg[2].desc,cfg[3].name,cfg[3].desc,cfg[4].name,cfg[4].desc)
	self.view.Pos.detailInfoText.tip[UI.Text].text=string.format("%s:%s%s%s\n%s:%s%s%s\n%s:%s%s%s\n%s:%s%s%s",cfg[1].name,"<color=#FFD800FF>",cfg[1].desc,"</color>",cfg[2].name,"<color=#FFD800FF>",cfg[2].desc,"</color>",cfg[3].name,"<color=#FFD800FF>",cfg[3].desc,"</color>",cfg[4].name,"<color=#FFD800FF>",cfg[4].desc,"</color>")
end

return View;