local npcConfig = require "config.npcConfig"
local IconFrameHelper = require "utils.IconFrameHelper"
local ItemModule = require "module.ItemModule"
local NpcChatMoudle = require "module.NpcChatMoudle"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self:ChatCountLimit()
	self.npc_Friend_list = {}
	for k,v in pairs(npcConfig.GetNpcFriendList()) do
		if v.npc_id ~= 0 then
			local _isChat =npcConfig.GetnpcTopic(v.npc_id)
			if _isChat then 
				self.npc_Friend_list[#self.npc_Friend_list+1] = v
			end
		end
	end
	local npc_List = npcConfig.GetnpcList()
	--print("zoe查看 NpcListFrame",#npc_List,sprinttb(npc_List))
	--print("zoe查看 NpcListFrame",#self.npc_Friend_list,sprinttb(self.npc_Friend_list))
	self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
	self.nguiDragIconScript.RefreshIconCallback = function (go,idx)
		local NpcView = CS.SGK.UIReference.Setup(go)
		local npc_Friend_cfg = self.npc_Friend_list[idx+1]
		local npc_cfg = npc_List[npc_Friend_cfg.npc_id]
		--ERROR_LOG(npc_cfg.name)
		--ERROR_LOG(npc_cfg.mode)
		--print("zoe查看 NpcListFrame npc_cfg",sprinttb(npc_cfg),sprinttb(npc_Friend_cfg))
		NpcView.name[UI.Text].text = npc_cfg.name
		local HeroClone = SGK.UIReference.Setup(go)
		-- if HeroClone.hero.pos.transform.childCount == 0 then
		-- 	IconFrameHelper.Hero({icon = npc_cfg.icon,level = npc_cfg.levelm,quality = npc_cfg.quality,star=npc_cfg.star,vip=npc_cfg.vip,sex=npc_cfg.sex,headFrame=npc_cfg.HeadFrame},HeroClone.hero.pos)
		-- else
		-- 	HeroClone = HeroClone.hero.pos.transform:GetChild(0)
		-- 	IconFrameHelper.UpdateHero({icon = npc_cfg.icon,level = npc_cfg.levelm,quality = npc_cfg.quality,star=npc_cfg.star,vip=npc_cfg.vip,sex=npc_cfg.sex,headFrame=npc_cfg.HeadFrame},SGK.UIReference.Setup(HeroClone))
		-- end
		HeroClone.hero.pos[UI.Image]:LoadSprite("icon/"..npc_cfg.icon);
		local stageNum = module.ItemModule.GetItemCount(npc_Friend_cfg.stage_item)
		local relation = StringSplit(npc_Friend_cfg.qinmi_max,"|")
		local relation_desc = StringSplit(npc_Friend_cfg.qinmi_name,"|")
		local relation_value = ItemModule.GetItemCount(npc_Friend_cfg.arguments_item_id)
		local relation_Next_value = relation[stageNum+2] or "max"
		if relation_Next_value == "max" then
			NpcView.value[UI.Text].text = relation_Next_value
			NpcView.Scrollbar[UI.Scrollbar].size = 1
		else
			NpcView.value[UI.Text].text = relation_value.."/"..tonumber(relation_Next_value)
			if relation_value > tonumber(relation_Next_value) then
				NpcView.Scrollbar[UI.Scrollbar].size = 1
			else
				NpcView.Scrollbar[UI.Scrollbar].size = relation_value/math.floor(relation_Next_value)
			end
		end
		NpcView.Scrollbar.SlidingArea:SetActive(NpcView.Scrollbar[UI.Scrollbar].size > 0)
		--print("zoe查看 NpcListFrame",stageNum)
		NpcView.statusbg[CS.UGUISpriteSelector].index = stageNum
		--NpcView.yBtn:SetActive(relation_value > 0)
		local pos = nil 
		--local npcFriendData = nil
		for i,v in ipairs(self.npc_Friend_list) do
			if npc_cfg.npc_id == v.npc_id then
            	pos = i
            	--npcFriendData = self.npc_Friend_list
			end
		end
		--local _isChat =npcConfig.GetnpcTopic(npc_Friend_cfg.npc_id)
		local _hero =module.HeroModule.GetManager():Get(npc_Friend_cfg.npc_id)
		if _hero then
			NpcView.lastChat[UI.Text].text="可以私聊我"
		else
			NpcView.lastChat[UI.Text].text="未获得角色"
			NpcView[CS.UGUISpriteSelector].index=2
		end
		NpcView[CS.UGUIClickEventListener].onClick = function ( ... )
			if _hero then
				if self.chatCount > 0 then
					DialogStack.PushPrefStact("npcChat/npcChat",{data=npc_Friend_cfg,npcCfg=npc_cfg})
				else
					showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_wanjia_tips_02"))
				end
			else
				showDlgError(nil,"未获得角色");
			end
		end
		NpcView.yBtn[CS.UGUIClickEventListener].onClick = function ( ... )
			DialogStack.PushPrefStact("dataBox/NpcData", {pos = pos, npcFriendData = self.npc_Friend_list});
		end
		-- NpcView.hero[CS.UGUIClickEventListener].onClick = function ( ... )
		-- 	DialogStack.PushPrefStact("npcChat/npcTransaction")
		-- end
		
		--if _hero then
			go:SetActive(true)
		-- else
		-- 	CS.UnityEngine.GameObject.Destroy(go)
		-- end
	end
	-- table.sort( self.npc_Friend_list,function (a,b)
	-- 	return ItemModule.GetItemCount(a.arguments_item_id) > ItemModule.GetItemCount(b.arguments_item_id)
	-- end )
	self.nguiDragIconScript.DataCount = #self.npc_Friend_list
end
function View:ChatCountLimit()
	self.chatCount=ItemModule.GetItemCount(3004)
	self.view.dailyTopic.Text[UI.Text].text="今日已聊话题数："..(5-self.chatCount).."/5"
end
function View:onEvent(event,data)
	if event == "NpcListFrameMove" then
	elseif event == "SHOP_BUY_SUCCEED" then
		-- table.sort( self.npc_Friend_list,function (a,b)
		-- 	return ItemModule.GetItemCount(a.arguments_item_id) > ItemModule.GetItemCount(b.arguments_item_id)
		-- end )
		self.nguiDragIconScript:ItemRef()
	elseif event == "QUEST_INFO_CHANGE" then
		self:ChatCountLimit()
		-- table.sort( self.npc_Friend_list,function (a,b)
		-- 	return ItemModule.GetItemCount(a.arguments_item_id) > ItemModule.GetItemCount(b.arguments_item_id)
		-- end )
		self.nguiDragIconScript:ItemRef()
	end
end
function View:listEvent()
	return {
		"SHOP_BUY_SUCCEED",
		"QUEST_INFO_CHANGE",
	}
end
function View:OnDestroy( ... )
	DialogStack.Destroy("NpcListFrame")
end
return View