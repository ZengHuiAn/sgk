local EquipmentModule = require "module.equipmentModule"
local EquipConfig = require "config.equipmentConfig"
local EquipHelp = require "module.EquipHelp"
local HeroModule = require "module.HeroModule"
local HeroScroll = require "hero.HeroScroll"
local ParameterConf = require "config.ParameterShowInfo"
local Property = require "utils.Property"
local CommonConfig = require "config.commonConfig"
local ChatManager = require 'module.ChatModule'

local View = {}
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view;

	self.view.title.Text[UI.Text].text = SGK.Localize:getInstance():getValue("分享")
	self.view.tip[UI.Text].text = SGK.Localize:getInstance():getValue("分享装备到")
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	CS.UGUIClickEventListener.Get(self.view.Cancel.gameObject).onClick = function (obj)
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	for i=1,3 do
		CS.UGUIClickEventListener.Get(self.view.Content[i].gameObject).onClick = function (obj)
			self:Share(data,i)
			CS.UnityEngine.GameObject.Destroy(self.gameObject)
		end
	end
	
end

function View:Share(uuid,Idx)
	if not uuid then return end
	self.SelectEquip = EquipmentModule.GetByUUID(uuid)
	if Idx ==1 then
		
	elseif  Idx ==2 then
		if module.unionModule.Manage:GetUionId() == 0 then
			showDlgError(nil,"您需要先加入一个公会")
		else
			ChatManager.ChatMessageRequest(3,"4"..self.SelectEquip.cfg.name.."\n"..SGK.Localize:getInstance():getValue("zhuangbeifenxiang").."|"..uuid)
		end
	elseif  Idx ==3 then
		ChatManager.ChatMessageRequest(1,"4"..self.SelectEquip.cfg.name.."\n"..SGK.Localize:getInstance():getValue("zhuangbeifenxiang").."|"..uuid)
	end
end


function View:listEvent()
	return {
	}
end

function View:onEvent(event, data)

end

return View;
