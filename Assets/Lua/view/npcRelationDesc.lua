local npcConfig = require "config.npcConfig"
local IconFrameHelper = require "utils.IconFrameHelper"
local ItemModule = require "module.ItemModule"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data
	local npc_List = npcConfig.GetnpcList()
	local npc_Friend_cfg = npcConfig.GetNpcFriendList()[data.id]
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		UnityEngine.GameObject.Destroy(self.gameObject)
	end
	self.view.Root.exitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		UnityEngine.GameObject.Destroy(self.gameObject)
	end
	self.view.Root.desc[UI.Text].text = "喜欢:美元、软妹币、欧元\n厌恶:不值钱的东西"
	self.view.Root.name[UI.Text].text = npc_List[data.id].name
	local relation = StringSplit(npc_Friend_cfg.qinmi_max,"|")
	local relation_desc = StringSplit(npc_Friend_cfg.qinmi_name,"|")
	local relation_value = ItemModule.GetItemCount(npc_Friend_cfg.arguments_item_id)
	local relation_index = 0
	for i = 1,#relation do
		if relation_value >= tonumber(relation[i]) then
			relation_index = i
		end
	end
	self.view.Root.value[UI.Text].text = relation_value
	self.view.Root.relation[UI.Text].text = relation_desc[relation_index]
	self.view.Root.statusbg[CS.UGUISpriteSelector].index = relation_index-1
	local item_id = {90002,90006}
	local item_count = {999999999,999999999}
	for i = 1,#item_id do
		IconFrameHelper.Item({id = item_id[i],count = item_count[i]},self.view.Root.Group,{showDetail = true})
	end
	self.view.Root.yBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		-- local shop = module.ShopModule.GetManager((data.id*100)+1)
		-- module.ShopModule.GetManager((data.id*100)+98)
		-- module.ShopModule.GetManager((data.id*100)+99)
		DialogStack.PushPref("npcBribeTaking",{id = self.Data.id,item_id = self.Data.item_id},self.view.gameObject)
		-- if shop and shop.shoplist then
		-- 	DialogStack.PushPref("npcBribeTaking",{id = self.Data.id},self.view.gameObject)
		-- else
		-- 	showDlgError(nil,"才这么一点？你是打发要饭的吗？")
		-- end
	end
end
function View:onEvent(event,data)
	if event == "SHOP_INFO_CHANGE" then
		--DialogStack.PushPref("npcBribeTaking",{id = self.Data.id},self.view.gameObject)
	end
end
function View:listEvent()
	return {
	"SHOP_INFO_CHANGE",
	}
end
return View
