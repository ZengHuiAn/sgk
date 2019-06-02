local ItemModule = require "module.ItemModule"
local npcConfig = require "config.npcConfig"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject).Root
	self.Data = data or {key = 0,id = 0}
	self.key =  self.Data.key
	self.id = self.Data.id
	self:updateValue()
end
function View:updateValue()
	if self.id == 0 then
		self.view:SetActive(false)
		return
	end
	local npc_List = npcConfig.GetnpcList()
	local npc_Friend_cfg = npcConfig.GetNpcFriendList()[self.id]
	if npc_Friend_cfg and npc_Friend_cfg.arguments_item_id ~= 0 then
		local stageNum = ItemModule.GetItemCount(npc_Friend_cfg.stage_item)
		local relation = StringSplit(npc_Friend_cfg.qinmi_max,"|")
		local relation_desc = StringSplit(npc_Friend_cfg.qinmi_name,"|")
		local relation_value = ItemModule.GetItemCount(npc_Friend_cfg.arguments_item_id)
		if not module.HeroModule.GetManager():Get(self.id) then
	        self.view.statusbg[CS.UGUISpriteSelector].index = 0
	    else
	        self.view.statusbg[CS.UGUISpriteSelector].index = stageNum
	    end
		local relation_Next_value = relation[stageNum+2] or "max"
		if relation_Next_value == "max" then
			self.view.value[UI.Text].text = relation_Next_value
			self.view.Scrollbar[UI.Scrollbar].size = 1
		else
			self.view.value[UI.Text].text = (relation_value - tonumber(relation[stageNum+1])).."/".. (tonumber(relation_Next_value) - tonumber(relation[stageNum+1]))
			if relation_value - tonumber(relation[stageNum+1]) > (tonumber(relation_Next_value) - tonumber(relation[stageNum+1])) then
				self.view.Scrollbar[UI.Scrollbar].size = 1
			else
				self.view.Scrollbar[UI.Scrollbar].size = (relation_value - tonumber(relation[stageNum+1]))/math.floor(relation_Next_value - tonumber(relation[stageNum+1]))
			end
		end
		self.view.Scrollbar.SlidingArea:SetActive(self.view.Scrollbar[UI.Scrollbar].size > 0)
	else
		self.view.statusbg[CS.UGUISpriteSelector].index = 0
		self.view.value[UI.Text].text = "0/250"
		print(self.key,"id"..self.id.."在arguments_npc表里npc_id列中找不到或arguments_item_id不存在")
	end
	self.view:SetActive(npc_Friend_cfg)
end
function View:onEvent(event,data)
	if event == "update_likingValue_Key" then
		if self.key == data.key then
			self.id = data.id
			self:updateValue()
		end
	end
end
function View:listEvent()
	return {
	"update_likingValue_Key",
	}
end
return View