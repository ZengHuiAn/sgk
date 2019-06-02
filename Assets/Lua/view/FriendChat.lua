local NetworkService = require "utils.NetworkService";
local EventManager = require 'utils.EventManager';
local ChatManager = require 'module.ChatModule'
local playerModule = require "module.playerModule"
local MailModule = require 'module.MailModule'
local TeamModule = require "module.TeamModule"
local unionModule = require "module.unionModule"
local FriendModule = require 'module.FriendModule'
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local ItemModule = require "module.ItemModule"
local IconFrameHelper = require "utils.IconFrameHelper"
local npcConfig = require "config.npcConfig"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self:init(data)
end
function View:init(data)
	self.Data = data
	self.ChatData = data ~= nil and data.data or {}
	self.ChatObjArr = {}
	self.ChatHeight = 0
	self.SNArr = {}
	if data.is_mask == nil then
		--self.view.maskbg:SetActive(true)--现在全部为隐藏
	else
		self.view.maskbg:SetActive(false)
	end
	
	ChatManager.SetPrivateChatData(data.pid,6)
	local cfg = npcConfig.GetnpcList()[data.pid]
	if not data.source or data.source == 0 then
		DispatchEvent("FriendSystemlist_viewDatasChange",{i = 1,pid = data.pid,name = playerModule.IsDataExist(data.pid).name})--保存当前对话对象数据
		if playerModule.GetFightData(data.pid) then
			self.view.root.PlayerObj.combat[UnityEngine.UI.Text].text =tostring(math.ceil(playerModule.GetFightData(data.pid).capacity))
		else
			self.SNArr[data.pid] = self.view.root.PlayerObj
		end
	else
		DispatchEvent("FriendSystemlist_viewDatasChange",{i = 1,pid = data.pid,name = ""})--保存当前对话对象数据
		self.view.root.PlayerObj.combat[UnityEngine.UI.Text].text ="??????"
	end
	self:ExamineFriend(data.pid)
	if FriendModule.FindId(data.pid) then
		self.view.root.PlayerObj.online:SetActive(FriendModule.FindId(data.pid).online == 1)
	else
		self.view.root.PlayerObj.online:SetActive(false)
		FriendModule.PlayerFinOnline(data.pid,function (online)
			self.view.root.PlayerObj.online:SetActive(online)
		end)
	end
	local unionName = nil
	if unionModule.GetPlayerUnioInfo(data.pid) then
		unionName = unionModule.GetPlayerUnioInfo(data.pid).unionName
	end
	if unionName then
		self.view.root.PlayerObj.guild[UnityEngine.UI.Text].text =unionName
	else
		unionModule.queryPlayerUnioInfo(data.pid,(function ( ... )
			unionName = unionModule.GetPlayerUnioInfo(data.pid).unionName or "无"
			self.view.root.PlayerObj.guild[UnityEngine.UI.Text].text =unionName
		end))
	end
	-- local PLayerIcon = nil
	-- if self.view.root.PlayerObj.hero.transform.childCount == 0 then
	-- 	PLayerIcon = IconFrameHelper.Hero({},self.view.root.PlayerObj.hero)
		local PLayerIcon = IconFrameHelper.Create(self.view.root.PlayerObj.hero,{pid = data.pid})
	-- else
	-- 	local objClone =self.view.root.PlayerObj.hero.transform:GetChild(0).gameObject
	-- 	CS.UnityEngine.GameObject.Destroy(objClone)
	-- 	PLayerIcon = IconFrameHelper.Hero({},self.view.root.PlayerObj.hero)
	-- 	PLayerIcon = IconFrameHelper.Create(PLayerIcon,{pid = data.pid})
	-- end
	if not data.source or data.source == 0 then
		self.view.root.PlayerObj.name[UnityEngine.UI.Text].text = playerModule.IsDataExist(data.pid).name
		-- PlayerInfoHelper.GetPlayerAddData(data.pid,99,function (addData)
		-- 	IconFrameHelper.UpdatePlayer({pid = data.pid,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
		-- end)
	else
		self.view.root.PlayerObj.name[UnityEngine.UI.Text].text = cfg.name
		--IconFrameHelper.UpdatePlayer({icon = cfg.icon,sex = cfg.Sex,headFrame = cfg.HeadFrame},PLayerIcon)
		--PLayerIcon = IconFrameHelper.Create(PLayerIcon,{pid = data.pid})
		self.view.root.PlayerObj.online:SetActive(true)
		local npc_Friend_cfg = npcConfig.GetNpcFriendList()[cfg.npc_id]
		local relation = StringSplit(npc_Friend_cfg.qinmi_max,"|")
		local relation_value = ItemModule.GetItemCount(npc_Friend_cfg.arguments_item_id)
		local relation_desc = StringSplit(npc_Friend_cfg.qinmi_name,"|")
		local relation_index = 0
		for i = 1,#relation do
			if relation_value >= tonumber(relation[i]) then
				relation_index = i
			end
		end
		self.view.root.PlayerObj.friendship[CS.UGUISpriteSelector].index = relation_index-1
	end
	-- for i = 1,#ChatData do
	-- 	self:ChatPanelRef(ChatData[i])
	-- end
	self.view.root.ScrollView[CS.ChatContent].onRefreshItem = (function (go,idx)
		if #self.ChatData > 0 then
			local objView = CS.SGK.UIReference.Setup(go)
			self:ChatPanelRef(self.ChatData[idx],SGK.UIReference.Setup(go),idx)
		end
	end)
	--ERROR_LOG(sprinttb(self.ChatData))
	--ERROR_LOG(sprinttb(ChatManager.GetManager(6)[data.pid]))
	self.view.root.ScrollView[CS.ChatContent]:SetChatCount(#self.ChatData)
	self.view.maskbg[CS.UGUIClickEventListener].onClick = function ( ... )
		DialogStack.Destroy("FriendChat")
	end
	self.view.root.SendBtn[CS.UGUIClickEventListener].onClick = function ()
 		local desc = self.view.root.InputField[UnityEngine.UI.InputField].text
 		if #self:string_segmentation(desc) > 0 then
	 		if not data.source or data.source == 0 then
	 			NetworkService.Send(5009,{nil,data.pid,3,desc,""})
		 		if playerModule.IsDataExist(data.pid) then
		 			ChatManager.SetManager({fromid = data.pid,fromname = playerModule.IsDataExist(data.pid).name,title = desc},1,3)--0聊天显示方向1右2左
		 		else
		 			playerModule.Get(data.pid,(function( ... )
		 				ChatManager.SetManager({fromid = data.pid,fromname = playerModule.IsDataExist(data.pid).name,title = desc},1,3)--0聊天显示方向1右2左
		 			end))
		 		end
		 	else
		 		ChatManager.SetManager({fromid = data.pid,fromname = cfg.name,title = desc,source = 1},1,3)--0聊天显示方向1右2左
		 	end
		 	self.view.root.InputField[UnityEngine.UI.InputField].text = ""
	 	else
	 		showDlgError(nil,"消息内容不能为空")
	 	end
 	end
 	self.view.root.PlayerObj.yBtn[CS.UGUIClickEventListener].onClick = function ()
 		if not data.source or data.source == 0 then
	 		self.view.root.PlayerObj.yBtn.transform.localEulerAngles = Vector3.zero
	 		local list = {}
	 		if FriendModule.GetManager(nil,data.pid) then
	 			if FriendModule.FindId(data.pid).online == 1 then
	 				list = {2,3,5,8}
	 			else
	 				list = {2,5,8}
	 			end
	 			if FriendModule.FindId(data.pid).type == 1 or  FriendModule.FindId(data.pid).type == 3 then
		 			table.insert(list,9)
		 		end
	 		else
	 			list = {1,2,8}
	 		end
	 		utils.SGKTools.FriendTipsNew({self.view,self.view.root.pos},data.pid,list)
	 	end
 	end
 	self.view.root.EmojiBtn[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view.mask:SetActive(true)
 	end
 	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view.mask:SetActive(false)
 		self.view.root.EmojiBtn[UI.Toggle].isOn = false
 	end
 	self.view.mask.EmojiBtn[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view.mask:SetActive(false)
 		self.view.root.EmojiBtn[UI.Toggle].isOn = false
 	end
 	for i =1,#self.view.mask.bg do
 		self.view.mask.bg[i][CS.UGUIClickEventListener].onClick = function ( ... )
 			self.view.root.EmojiBtn[UI.Toggle].isOn = false	
 			self.view.mask:SetActive(false)
 			self.view.root.InputField[UnityEngine.UI.InputField].text = self.view.root.InputField[UnityEngine.UI.InputField].text.."[#"..i.."]"
 		end
 	end
end
function View:ExamineFriend(pid)
	local FriendData = FriendModule.GetManager(nil,pid)
	local ChatData = ChatManager.GetManager(8)--加好友通知
	if ChatData and ChatData[pid] and not FriendData then
		--self.view.root.ScrollView[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(567.8,595)
		--self.view.root.ScrollView[UnityEngine.RectTransform].localPosition = Vector3(0,-43,0)
		self.view.root.hint:SetActive(true)
	else
		self.view.root.hint:SetActive(false)
		--self.view.root.ScrollView[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(567.8,634)
		--self.view.root.ScrollView[UnityEngine.RectTransform].localPosition = Vector3(0,-28,0)
	end
	if FriendData then
		if FriendData.type == 2 then
			--self.view.root.PlayerObj.type[UI.Text].text = "<color=#FD2D2B>黑名单</color>"
			--self.view.root.PlayerObj.friendship
		else
			--self.view.root.PlayerObj.type[UI.Text].text = "<color=#2EFFD7>好友</color>"
			if self.view.root.hint.activeSelf then
				self.view.root.hint.desc[CS.InlineText].text = ChatData[pid][#ChatData[pid]].message
			end
		end
	else
		--self.view.root.PlayerObj.type[UI.Text].text = "<color=#FD2D2B>陌生人</color>"
		if self.view.root.hint.activeSelf then
			self.view.root.hint.desc[CS.InlineText].text = ChatData[pid][#ChatData[pid]].message.."[-1#添加好友]"
			self.view.root.hint.desc[CS.InlineText].onClick = function (name,id)
				if id == 1 then
					--ERROR_LOG("添加好友",sprinttb(ChatData[pid]))
					ChatManager.SetPrivateChatData(pid,8)
					utils.NetworkService.Send(5013,{nil,1,pid})
				end
			end
		end
	end
	ChatManager.SetPrivateChatData(pid,8)--已读取加好友通知
end
function View:ChatPanelRef(data,ChatView,idx)
	--聊天频道刷新
	local desc = data.message
	--print("zoe11111 ",sprinttb(data))
	--print(desc.."->"..#self:string_segmentation(desc))
 	if data and data.channel == 6 then--and #self:string_segmentation(desc) > 0 then
	 	--ChatView:SetActive(true)
 		--print("!!!"..self.ChatType.."\n"..data.fromid..">"..playerModule.Get().id)
 		local ChatObj = nil
 		local ChatView_LR = nil
 		local pid = nil
 		local PLayerIcon = nil
 		if data.fromid == playerModule.Get().id or (data.ChatIdx and data.ChatIdx == 1) then
 			--右边对话
 			pid = playerModule.Get().id
 			ChatObj = ChatView.Right
 			if playerModule.Get().honor == 9999 then
	 			ChatObj.name[UnityEngine.UI.Text].text = "<color=#ff0000ff>[管理员]"..playerModule.Get().name.."</color>"
	 		else
	 			ChatObj.name[UnityEngine.UI.Text].text = playerModule.Get().name
	 		end
 			ChatView.Left.gameObject:SetActive(false)
 			ChatView.Right.gameObject:SetActive(true)
 			if ChatView.Right.icon.transform.childCount == 0 then
				PLayerIcon = IconFrameHelper.Hero({},ChatView.Right.icon)
				PLayerIcon = IconFrameHelper.Create(PLayerIcon,{pid = pid})
				--PLayerIcon.gameObject.transform.localScale=Vector3(1.2,1.2,1)
				-- local pLayerIcon = CS.SGK.UIReference.Setup(PLayerIcon.gameObject)
				-- pLayerIcon.Icon.transform.localScale=UnityEngine.Vector3(1.2,1.2,1)
				-- pLayerIcon.BottomTag[UnityEngine.RectTransform].pivot=UnityEngine.Vector2(0.5,0.5)
				-- pLayerIcon.BottomTag.transform.localScale=UnityEngine.Vector3(1.3,1.3,1)
			else
				local objClone =  ChatView.Right.icon.transform:GetChild(0)
				CS.UnityEngine.GameObject.Destroy(objClone.gameObject)
				PLayerIcon = IconFrameHelper.Hero({},ChatView.Right.icon)
				PLayerIcon = IconFrameHelper.Create(PLayerIcon,{pid = pid})
				--PLayerIcon = SGK.UIReference.Setup(objClone)
				--PLayerIcon.gameObject.transform.localScale=Vector3(1.2,1.2,1)
				
				-- pLayerIcon.LowerRightText[UnityEngine.RectTransform].anchoredPosition=UnityEngine.Vector2(-17.5,0)
			end
			-- local pLayerIcon = PLayerIcon.transform:GetChild(9)
			-- pLayerIcon.gameObject.transform.localScale=UnityEngine.Vector3(1.2,1.2,1)	
			-- pLayerIcon.transform.localPosition=UnityEngine.Vector3(-17.5,0,0)
			local pLayerIcon = CS.SGK.UIReference.Setup(PLayerIcon.gameObject)
			-- pLayerIcon.Icon.transform.localScale=UnityEngine.Vector3(1.2,1.2,1)
			-- pLayerIcon.BottomTag[UnityEngine.RectTransform].pivot=UnityEngine.Vector2(0.5,0.5)
			-- pLayerIcon.BottomTag.transform.localScale=UnityEngine.Vector3(1.3,1.3,1)
			ChatView_LR = ChatView.Right
			ChatView.Center:SetActive(false)
 		else
 			--左边对话
 			ChatObj = ChatView.Left
 			pid = data.fromid
 			ChatView.Right.gameObject:SetActive(false)
 			ChatView.Left.gameObject:SetActive(true)
 			local objClone = nil
 			if ChatView.Left.icon.transform.childCount == 0 then
				PLayerIcon = IconFrameHelper.Hero({},ChatView.Left.icon)
				PLayerIcon = IconFrameHelper.Create(PLayerIcon,{pid = pid})
				--PLayerIcon.gameObject.transform.localScale=Vector3(1.2,1.2,1)
				-- local pLayerIcon = CS.SGK.UIReference.Setup(PLayerIcon.gameObject)
				-- if pLayerIcon.LowerRightText then
				-- 	print("111111")
				-- end
				-- pLayerIcon.LowerRightText.gameObject.transform.localScale=Vector3(1.2,1.2,1)
				-- pLayerIcon.LowerRightText[UnityEngine.RectTransform].anchoredPosition=UnityEngine.Vector2(-17.5,0)
			else
				local objClone = ChatView.Left.icon.transform:GetChild(0)
				--PLayerIcon = SGK.UIReference.Setup(objClone)
				CS.UnityEngine.GameObject.Destroy(objClone.gameObject)
				PLayerIcon = IconFrameHelper.Hero({},ChatView.Left.icon)
				PLayerIcon = IconFrameHelper.Create(PLayerIcon,{pid = pid})
				--PLayerIcon.gameObject.transform.localScale=Vector3(1.2,1.2,1)
				-- local pLayerIcon = CS.SGK.UIReference.Setup(PLayerIcon.gameObject)
				-- pLayerIcon.LowerRightText.gameObject.transform.localScale=Vector3(1.2,1.2,1)
				-- pLayerIcon.LowerRightText[UnityEngine.RectTransform].anchoredPosition=UnityEngine.Vector2(-17.5,0)
			end
			local pLayerIcon = CS.SGK.UIReference.Setup(PLayerIcon.gameObject)
			-- pLayerIcon.Icon.transform.localScale=UnityEngine.Vector3(1.2,1.2,1)
			-- pLayerIcon.BottomTag[UnityEngine.RectTransform].pivot=UnityEngine.Vector2(0.5,0.5)
			-- pLayerIcon.BottomTag.transform.localScale=UnityEngine.Vector3(1.3,1.3,1)
			if not data.source or data.source == 0 then
				if playerModule.IsDataExist(data.fromid) then
					if playerModule.IsDataExist(data.fromid).honor == 9999 then
						ChatObj.name[UnityEngine.UI.Text].text = "<color=#ff0000ff>[管理员]"..playerModule.IsDataExist(data.fromid).name.."</color>"
					else
						ChatObj.name[UnityEngine.UI.Text].text = playerModule.IsDataExist(data.fromid).name
					end
				else
					playerModule.Get(data.fromid,(function( ... )
						if playerModule.IsDataExist(data.fromid).honor == 9999 then
							ChatObj.name[UnityEngine.UI.Text].text = "<color=#ff0000ff>[管理员]"..playerModule.IsDataExist(data.fromid).name.."</color>"
						else
							ChatObj.name[UnityEngine.UI.Text].text = playerModule.IsDataExist(data.fromid).name or ""
						end
					end))
				end
			else
				local cfg = npcConfig.GetnpcList()[pid]
				ChatObj.name[UnityEngine.UI.Text].text = cfg.name
			end
			ChatView_LR = ChatView.Left
			ChatView.Center:SetActive(false)
 		end
 		--ERROR_LOG(idx,data.message,playerModule.Get().id)
 		local UpdatePlayerDataFun = function (addData)
 			local _PlayerData = data.PlayerData or addData
            local SpriteName = ""
			if pid == playerModule.Get().id then
				SpriteName = "bg_lt6"
				--ChatObj.arrows.transform.localPosition = Vector3(173,ChatObj.arrows.transform.localPosition.y,0)
			else
				SpriteName = "bg_lt7"
				--ChatObj.arrows.transform.localPosition = Vector3(-173,ChatObj.arrows.transform.localPosition.y,0)
			end
			if _PlayerData.Bubble ~= 0 and ItemModule.GetShowItemCfg(_PlayerData.Bubble) then
				SpriteName = ItemModule.GetShowItemCfg(_PlayerData.Bubble).effect
			end
            --ChatObj.Content.bg.bg_prefab[UI.Image]:LoadSprite("icon/"..SpriteName)
            --ChatObj.arrows[UI.Image]:LoadSprite("icon/"..SpriteName.."-1")
            if data.ChatIdx == 1 or not data.source or data.source == 0 then
	            --IconFrameHelper.UpdateHero({pid = pid,sex = _PlayerData.Sex,headFrame = _PlayerData.HeadFrame},PLayerIcon)
	        else
	        	local cfg = npcConfig.GetnpcList()[pid]
	        	--IconFrameHelper.UpdateHero({icon = cfg.icon,sex = _PlayerData.Sex,headFrame = _PlayerData.HeadFrame},PLayerIcon)
	        end
            local _idx = data.idx or idx
            ChatManager.ChatUpdate(data.channel,{data.fromid,_idx},{Bubble = _PlayerData.Bubble,Sex = _PlayerData.Sex,HeadFrame = _PlayerData.HeadFrame,HeadFrameId = _PlayerData.HeadFrameId})
 		end
 		local isNpc = false
 		if data.ChatIdx == 1 or not data.source or data.source == 0 then
	 		PlayerInfoHelper.GetPlayerAddData(pid,99,function (addData)
	            --获取头像挂件足迹等
	            --ERROR_LOG(pid,">",sprinttb(addData))
	            --ERROR_LOG(sprinttb(data.PlayerData))
	           UpdatePlayerDataFun(addData)
	        end)
	    else
	    	isNpc = true
	    	local cfg = npcConfig.GetnpcList()[pid]
	    	UpdatePlayerDataFun({Bubble = 0,Sex = cfg.Sex,HeadFrame = cfg.HeadFrame,HeadFrameId = 0})
 		end
 		ChatObj.icon[CS.UGUIClickEventListener].onClick = (function ( ... )
 			if data.ChatIdx and data.ChatIdx == 0 then
 				if not data.source or data.source == 0 then
	 				--PlayerTips({name = data.fromname,level = "nil",pid = data.fromid})
	 				DialogStack.PushPrefStact("mapSceneUI/otherPlayerInfo", data.fromid, self.view)
	 			end
 			end
 		end)
 		local WordFilter = WordFilter.check(desc)--屏蔽字
 		local _PID = data.ChatIdx == 1 and playerModule.Get().id or data.fromid
 		if playerModule.IsDataExist(_PID) and playerModule.IsDataExist(_PID).honor == 9999 then
	 		ChatObj.Content.bg.desc[CS.InlineText].text = "<color=#ff0000ff>"..WordFilter.."</color>"
	 	else
	 		ChatObj.Content.bg.desc[CS.InlineText].text = "<color=#000000>"..WordFilter.."</color>"
	 	end
 		ChatObj.Content.bg.desc[CS.InlineText].onClick = function (name,id)
 			--ERROR_LOG(name..">"..id)
 			if id == 1 then--申请入队
 				local teamInfo = module.TeamModule.GetTeamInfo();
    			if teamInfo.group == 0 then
    				if openLevel.GetStatus(1601) then
		 				self.IsApply = true
		 				module.TeamModule.GetPlayerTeam(data.fromid,true)--查询玩家队伍信息
		 			else
		 				showDlgError(nil,"等级不足")
		 			end
	 			else
	 				showDlgError(nil,"已在队伍中")
	 			end
 			elseif id == 2 then--申请入会
 				if unionModule.Manage:GetUionId() == 0 then
	 				module.unionModule.JoinUnionByPid(data.fromid)
	 			else
	 				showDlgError(nil,"您已经加入了一个公会")
	 			end
 			end
 		end
 		-- ChatObj.Content.bg.bg_prefab[CS.UGUIClickEventListener].onClick = function ( ... )
 		-- 	--玩家装扮
 		-- 	DialogStack.PushPref("FriendInfo",{pid=pid,desc=WordFilter,PlayerData=data.PlayerData,isNpc=isNpc},self.view.gameObject)
 		-- end
 		-- ChatObj.Content.bg.desc[CS.UGUIClickEventListener].onClick = function ( ... )
 		-- 	--玩家装扮
 		-- 	DialogStack.PushPref("FriendInfo",{pid=pid,desc=WordFilter,PlayerData=data.PlayerData,isNpc=isNpc},self.view.gameObject)
 		-- end
 	else
 		local FriendData = FriendModule.GetManager(nil,self.Data.pid)
 		if not FriendData then
 			ChatView.Center.gameObject:SetActive(false)
 		else
	 		ChatView.Center.gameObject:SetActive(true)
	 		ChatView.Left:SetActive(false)
	 		ChatView.Right:SetActive(false)
	 		local WordFilter = WordFilter.check(desc)--屏蔽字
	 		ChatView.Center.bg.desc[CS.InlineText].text = WordFilter
	 	end
  	end
end

function View:listEvent()
	return {
		"Chat_INFO_CHANGE",
		"Chat_RedDot_CHANGE",
		"Team_members_Request",
		"FriendTipsNew_close",
		"PLAYER_FIGHT_INFO_CHANGE",
		"Friend_INFO_CHANGE",
		"PlayerFinOnlineChange",
		"FriendChatChange",
	}
end

function View:onEvent(event,data)
	if event == "Chat_INFO_CHANGE" then
		if (data.channel == 6 or data.channel == 8) and (data.fromid == self.Data.pid or data.fromid == playerModule.Get().id) then
			--self:ChatPanelRef(data)
			--ERROR_LOG("new message ",sprinttb(data))
			if data.channel == 8 then
				self:ExamineFriend(self.Data.pid)
				if data.status == 1 then--只是更新某消息状态，不增加新的聊天数据
					return
				end
			end
			self.ChatData = {}
			local ChatData = ChatManager.GetManager(6)[self.Data.pid]
			for i = 1,#ChatData do
				self.ChatData[i] = ChatData[i]
			end
			local ChatData = ChatManager.GetManager(8)
			if ChatData and ChatData[self.Data.pid] then
				ChatData = ChatData[self.Data.pid]
				for i = 1,#ChatData do
					if ChatData[i].status == 1 then
						--NetworkService.Send(5005,{nil,{{ChatData[i].id,2}}})--已读取加好友通知
					else
						self.ChatData[#self.ChatData+1] = ChatData[i]
					end
				end
			end
			table.sort(self.ChatData,function(a,b)
				return a.time < b.time
			end)
			self.view.root.ScrollView[CS.ChatContent]:AddItem()
			ChatManager.SetPrivateChatData(self.Data.pid,6)--已读好友消息
		end
	elseif event == "FriendTipsNew_close" then
	 	self.view.root.PlayerObj.yBtn.transform.localEulerAngles = Vector3(0,0,180)
	elseif event == "PLAYER_FIGHT_INFO_CHANGE" then
		if playerModule.GetFightData(data) and self.SNArr[data] then
			self.SNArr[data].combat[UnityEngine.UI.Text].text = tostring(math.ceil(playerModule.GetFightData(data).capacity))
			self.SNArr[data] = nil
		end
	elseif event == "Friend_INFO_CHANGE" or event == "PlayerFinOnlineChange" then
		if FriendModule.FindId(self.Data.pid) then
			self.view.root.PlayerObj.online:SetActive(FriendModule.FindId(self.Data.pid).online == 1)
		else
			self.view.root.PlayerObj.online:SetActive(false)
			FriendModule.PlayerFinOnline(self.Data.pid,function (online)
				self.view.root.PlayerObj.online:SetActive(online)
			end)
		end
		self:ExamineFriend(self.Data.pid)
	elseif event == "FriendChatChange" then
		local Old_Pid = self.Data.pid
		self:init(data)
		local FriendData = FriendModule.GetManager(nil,Old_Pid)
		if Old_Pid ~= self.Data.pid and FriendData and (FriendData.type == 1 or FriendData.type == 3) then
			ChatManager.SetPrivateChatData(Old_Pid,8)--已读取加好友通知
		end
	elseif event == "PrivateChatData_CHANGE" then
		if data.status == 8 and (data.fromid == self.Data.pid or data.fromid == playerModule.Get().id) then
			self:ExamineFriend(self.Data.pid)
		end
	end
end
function View:OnDestroy( ... )
	-- local FriendData = FriendModule.GetManager(nil,self.Data.pid)
	-- if FriendData and (FriendData.type == 1 or FriendData.type == 3) then
		ChatManager.SetPrivateChatData(self.Data.pid,8)--已读取加好友通知
	-- end
end
function View:string_segmentation(str)
	--print(str)
    local len  = #str
    local left = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    local t = {}
    local start = 1
    local wordLen = 0
    while len ~= left do
        local tmp = string.byte(str, start)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                break
            end
            i = i - 1
        end
        wordLen = i + wordLen
        local tmpString = string.sub(str, start, wordLen)
        start = start + i
        left = left + i
        t[#t + 1] = tmpString
    end
    return t
end
return View