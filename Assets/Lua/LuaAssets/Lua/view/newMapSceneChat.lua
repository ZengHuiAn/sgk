local NetworkService = require "utils.NetworkService";
local EventManager = require 'utils.EventManager';
local ChatManager = require 'module.ChatModule'
local playerModule = require "module.playerModule"
local MailModule = require 'module.MailModule'
local TeamModule = require "module.TeamModule"
local unionModule = require "module.unionModule"
local Time = require "module.Time"
local openLevel = require "config.openLevel"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local ItemModule = require "module.ItemModule"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.ToggleToChatType = {[1] = 0,[2] = 1,[4] = 3,[5] = 7,[3] = 10,[6] = 100}--toggle排序1系统2世界3工会4队伍5组队喊话6地图
 	self.ChatTypeToToggle = {[0] = 1,[1] = 2,[7] = 5,[3] = 4,[10] = 3,[100] = 5}--数据排序0系统1世界6私聊3工会7队伍8加好友消息10组队喊话100地图
 	self.LeftArrows = {[76001] = -170,[76002] = -173,[76003] = -168,[76004] = -172,[76005] = -170}-- -173
 	self.RightArrows = {[76001] = 165,[76002] = 173,[76003] = 172,[76004] = 172,[76005] = 170}-- -173
 	self.ChatType = 1
 	TeamModule.GetTeamInfo()--获取当前自己的队伍
 	self.TempData = {}
 	self.ChatObjArr = {}
	self.ChatObjPool = {}
	self.TempDataCache = {};
 	self.stop_scrollView = false--是否scrollView滑动
 	self.Stop_MapSceneChat = true--是否停止聊天消息接收
 	self.view.SendBtn[CS.UGUIClickEventListener].onClick = (function ()
 		local desc ="1"..self.view.InputField[UnityEngine.UI.InputField].text
 		if self.ChatType == 0 then
 			showDlgError(self.view,"无法发送系统消息")
 			return
 		end
 		if #self:string_segmentation(desc) > 0 then
 			local cd =  math.floor(Time.now()  - ChatManager.GetChatMessageTime(self.ChatType))
			if cd < 10 then
				showDlgError(nil,"您说话太快，请在"..10-cd.."秒后发送")
				return
			end
    		if not openLevel.GetStatus(2801) then
    			showDlgError(nil,openLevel.GetCfg(2801).open_lev.."级开启")
    			return
    		end
 			print(self.ChatType.."发送:"..desc)
 			if self.ChatType == 7 then
 				--队伍聊天
 				local members = TeamModule.GetTeamMembers()
 				local TeamCount = 0
 				for _, v in ipairs(members) do
 					TeamCount = TeamCount + 1
 					break
 				end
 				if TeamCount == 0 then
 					showDlgError(nil,"请先加入一个队伍")
				 else
					module.TeamModule.ChatToTeam(desc, 0); --0普通1警告
					--ChatManager.SetChatMessageTime(self.ChatType,Time.now())
 				end
            elseif self.ChatType == 1 then
                if openLevel.GetStatus(2801) then
                    ChatManager.ChatMessageRequest(self.ChatType,desc)
     				ChatManager.SetChatMessageTime(self.ChatType,Time.now())
                else
                    showDlgError(nil, openLevel.GetCfg(2801).open_lev.."级后开启世界发言")
                end
 			else
 				if self.ChatType == 3 and unionModule.Manage:GetUionId() == 0 then
					showDlgError(self.view,"您需要先加入一个公会")
				else
	 				ChatManager.ChatMessageRequest(self.ChatType,desc)
	 				ChatManager.SetChatMessageTime(self.ChatType,Time.now())
	 			end
		 	end
		else
		 	showDlgError(nil,"消息内容不能为空")
	 	end
	 	self.view.InputField[UnityEngine.UI.InputField].text = ""
 	end)
	for i = 1, #self.view.ToggleGrid do
		--ERROR_LOG("TOggleGrid===========>>>name",self.view.ToggleGrid[i].gameObject.name)
 		self.view.ToggleGrid[i][CS.UGUIClickEventListener].onClick = (function ( ... )
 			self:ToggleTypeRef(i)
 		end)
 		self.view.ToggleGrid[i].RedDot:SetActive(ChatManager.GetPLayerStatus(self.ToggleToChatType[i]) ~= nil)
 	end
 	 self.view.EmojiBtn[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view.mask:SetActive(true)
 	end
 	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view.mask:SetActive(false)
 		self.view.EmojiBtn[UnityEngine.UI.Toggle].isOn = false
 	end
 	for i =1,#self.view.mask.bg do
 		self.view.mask.bg[i][CS.UGUIClickEventListener].onClick = function ( ... )
 			self.view.mask:SetActive(false)
 			self.view.EmojiBtn[UnityEngine.UI.Toggle].isOn = false
 			self.view.InputField[UnityEngine.UI.InputField].text = self.view.InputField[UnityEngine.UI.InputField].text.."[#"..i.."]"
 		end
 	end
 	-- self.view[UnityEngine.RectTransform]:DOScale(Vector3(1,1,1),0.25):OnComplete(function ( ... )
	-- 	self:ChatPanelRes(self.ChatType)
	-- end)
	self.view.black[CS.UGUIClickEventListener].onClick = function ( ... )
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	if SceneStack.GetBattleStatus() then
		self.view.ChatScrollView[CS.ChatContent].referencePixelsPerUnit = 1
	else
		self.view.ChatScrollView[CS.ChatContent].referencePixelsPerUnit = 100
	end
	self.view.ChatScrollView[CS.ChatContent].onRefreshItem = (function (go,idx)
		if #self.TempData > 0 then
			--ERROR_LOG("TempData=========>>>>",sprinttb(self.TempData))
			local objView = CS.SGK.UIReference.Setup(go)
			--objView.Left.gameObject:SetActive(false)
			--objView.Right.Content.bg.desc[CS.InlineText].text = "->"..idx
			--ERROR_LOG(idx,#self.TempData)--,sprinttb(self.TempData))
			self:ChatPanelRef(self.TempData[idx],SGK.UIReference.Setup(go),idx)
			--self:ChatPanelRef({message = "->"..idx,fromid = playerModule.Get().id},SGK.UIReference.Setup(go))
		end
	end)
	self.view.settingBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		DialogStack.PushPref("FiltrationChat",nil,self.view.gameObject)
	end
end
function View:ToggleTypeRef(i)
	-- if i == 4 and unionModule.Manage:GetUionId() == 0 then
	-- 	self.view.ToggleGrid[self.ChatTypeToToggle[self.ChatType]][UnityEngine.UI.Toggle].isOn = true
	-- 	showDlgError(self.view,"您需要先加入一个公会")
	-- else
		if i == 1 then
			--文字模式
			self.view.ChatScrollView.gameObject:SetActive(false)
			self.view.ScrollView.gameObject:SetActive(true)
			self.view.InputField:SetActive(false)
			self.view.SendBtn:SetActive(false)
			self.view.EmojiBtn:SetActive(false)
			--self.view.desc:SetActive(true)
			--self.view.settingBtn:SetActive(true)
			--self.view.characterBtn:SetActive(true)
		else
			--聊天模式
			self.view.ChatScrollView.gameObject:SetActive(true)
			self.view.ScrollView.gameObject:SetActive(false)
			self.view.InputField:SetActive(i ~= 3)
			self.view.SendBtn:SetActive(i ~= 3)
			self.view.EmojiBtn:SetActive(i ~= 3)
			self.view.desc:SetActive(false)
			self.view.settingBtn:SetActive(false)
			self.view.characterBtn:SetActive(false)
		end
		self.view.ToggleGrid[self.ChatTypeToToggle[self.ChatType]].Text[UI.Text].color = {r= 1,g=1,b=1,a=1}
		self.view.ToggleGrid[i].Text[UI.Text].color = {r= 0,g=0,b=0,a=1}
		self.TempData = {}
		self.stop_scrollView = false--切换页签还原可滚动
		self.ChatType = self.ToggleToChatType[i]
		self:ChatPanelRes(self.ChatType)
	--end
end
function View:ChatPanelRes(ChatType)
	--聊天频道重置
	self.ChatHeight = 0
	for i = 1,#self.ChatObjArr do
		self.ChatObjArr[i].gameObject:SetActive(false)
	-- 	self.ChatObjPool[#self.ChatObjPool + 1] = self.ChatObjArr[i].gameObject
	end
	--self.view.
	self.ChatObjArr = {}
	local ChatData = ChatManager.GetManager(ChatType)
	if ChatData and #ChatData > 0 then
		self.view.ScrollView.Viewport.Content.desc[UnityEngine.UI.Text].text = ""
		--for i = #ChatData,1, -1 do
		for i = 1,#ChatData do
			if ChatType ~= 0 then
				self.TempData[#self.TempData+1] = ChatData[i]
			else
				self.view.ScrollView.Viewport.Content.desc[UnityEngine.UI.Text].text = self.view.ScrollView.Viewport.Content.desc[UnityEngine.UI.Text].text..ChatData[i].message.."\n"
			end
		end
		if ChatType == 0 then
			self:ChatSystem()
		end
	else
		--showDlgError(self.view,"本频道无聊天数据")
	end
	self.view.ChatScrollView[CS.ChatContent]:SetChatCount(#self.TempData)
end

function View:Update()
	-- if #self.TempData > 0 then
	-- 	self:ChatPanelRef(self.TempData[1])
	-- 	--self.ChatObjArr[#self.ChatObjArr].name = #self.ChatObjArr..""
	-- 	self.ChatObjArr[#self.ChatObjArr].transform:SetAsFirstSibling()
	-- 	--self.ChatObjArr[#self.ChatObjArr].gameObject:SetActive(true)
	-- 	table.remove(self.TempData,1)
	-- end
	local cd =  math.floor(Time.now()  - ChatManager.GetChatMessageTime(self.ChatType))
	if cd > 10 then
		self.view.InputField.Placeholder[UI.Text].text = "输入..."
	else
		self.view.InputField.Placeholder[UI.Text].text = "请点击输入（"..(10-cd).."秒后可发言）"
	end
	-- if #self.TempDataCache > 5 then
	-- 	print("刷新", #self.TempDataCache)
	-- 	self.TempData = {}
	-- 	self:ChatPanelRes(self.ChatType);
	-- 	self.TempDataCache = {};
	-- elseif #self.TempDataCache > 0 then
	-- 	print("添加", #self.TempDataCache)
	-- 	for i,v in ipairs(self.TempDataCache) do
	-- 		self.TempData[#self.TempData + 1] = v;
	-- 		self.view.ChatScrollView[CS.ChatContent]:AddItem();
	-- 	end
	-- 	self.TempDataCache = {};
	-- end
end

function View:ChatSystem(data)
	SGK.Action.DelayTime.Create(0.1):OnComplete(function()
		if self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].sizeDelta.y > 395 then
 			local height = self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].sizeDelta.y-395
			self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].localPosition = Vector3(0,height,0)
		end
	end)
end

function View:ChatPanelRef(data,ChatView,idx)
	--聊天频道刷新
	--local desc = data.message
	local desc=""
	local applyLen =string.len(data.message)
	self.applyType=string.sub(data.message,0,1)
	if tonumber(self.applyType)==3  or tonumber(self.applyType)==1 or tonumber(self.applyType)==4 then
	    desc = string.sub(data.message,2,applyLen)
	--elseif tonumber(self.applyType)==2 then

	else
		desc = data.message
	end
	--print("消息",data.message)
	--print(desc.."->"..#self:string_segmentation(desc))
 	if data then--and #self:string_segmentation(desc) > 0 then
 	-- 	local obj = nil
 	-- 	if self.view.ChatScrollView.Viewport.Content.transform.childCount-1 > #self.ChatObjArr then
 	-- 		obj = self.view.ChatScrollView.Viewport.Content.transform:GetChild(#self.ChatObjArr + 1).gameObject
 	-- 	else
		--  	obj = CS.UnityEngine.GameObject.Instantiate(self.view.ChatScrollView.Viewport.Content.ChatObj.gameObject,self.view.ChatScrollView.Viewport.Content.gameObject.transform)
		-- end
		-- self.ChatObjArr[#self.ChatObjArr+1] = CS.SGK.UIReference.Setup(obj)
 		ChatView:SetActive(true)
 		--obj.gameObject.transform:DOScale(Vector3(1,1,1),0.25)
 		--print("!!!"..self.ChatType.."\n"..data.fromid..">"..playerModule.Get().id)
 		local head = 11001
 		local ChatObj = nil
 		local ChatView_LR = nil
 		local pid = nil
 		local PLayerIcon = nil;
 		local isleft = true
 		if data.fromid == playerModule.Get().id or (data.ChatIdx and data.ChatIdx == 1) then
			--右边对话
			PLayerIcon = ChatView.Right.icon.IconFrame;
 			pid = playerModule.Get().id
 			ChatObj = ChatView.Right
			ChatObj.name[UnityEngine.UI.Text].text = playerModule.Get().name
 			ChatView.Left.gameObject:SetActive(false)
 			ChatView.Right.gameObject:SetActive(true)
 			head = playerModule.Get().head ~= 0 and playerModule.Get().head or 11001
			PLayerIcon.transform.localScale = Vector3(1,1,1)
			--PLayerIcon[UnityEngine.RectTransform].localPosition = Vector3(0,0,0)
			utils.IconFrameHelper.Create(PLayerIcon, {pid = data.fromid})
			ChatView_LR = ChatView.Right
			isleft = true
 		else
			 --左边对话
			PLayerIcon = ChatView.Left.icon.IconFrame;
 			ChatObj = ChatView.Left
 			pid = data.fromid
 			ChatObj.name[UnityEngine.UI.Text].text = data.fromname
 			ChatView.Right.gameObject:SetActive(false)
			ChatView.Left.gameObject:SetActive(true)

			PLayerIcon.transform.localScale = Vector3(1,1,1)

			utils.IconFrameHelper.Create(PLayerIcon, {pid = data.fromid})

			ChatView_LR = ChatView.Left
			isleft = true
 		end
 		--ERROR_LOG(idx,data.message)
 		PlayerInfoHelper.GetPlayerAddData(pid,99,function (addData)
            --获取头像挂件足迹等
            --ERROR_LOG(pid,">",sprinttb(addData))
			--ERROR_LOG(sprinttb(data.PlayerData))
			--ERROR_LOG("PlayerData====>>>",pid,sprinttb(addData))
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
				-- if pid == playerModule.Get().id then
		  --           ChatObj.arrows.transform.localPosition = Vector3(self.RightArrows[_PlayerData.Bubble],ChatObj.arrows.transform.localPosition.y,0)
		  --       else
		  --       	ChatObj.arrows.transform.localPosition = Vector3(self.LeftArrows[_PlayerData.Bubble],ChatObj.arrows.transform.localPosition.y,0)
		  --       end
		  		local _, _color = UnityEngine.ColorUtility.TryParseHtmlString(ItemModule.GetShowItemCfg(_PlayerData.Bubble).text_color)
    			ChatObj.Content.bg.desc[CS.InlineText].color = _color
    			if ChatObj.Content.bg.TeamText then
    				ChatObj.Content.bg.TeamText[CS.InlineText].color = _color
    			end
		  	--print("_PlayerData",ItemModule.GetShowItemCfg(_PlayerData.Bubble).text_color,SpriteName)
		  	else
		  		local _, _color = UnityEngine.ColorUtility.TryParseHtmlString("#000000FF")
		  		ChatObj.Content.bg.desc[CS.InlineText].color = _color
    			if ChatObj.Content.bg.TeamText then
    				ChatObj.Content.bg.TeamText[CS.InlineText].color = _color
    			end
			end
            ChatObj.Content.bg.bg_prefab[UI.Image]:LoadSprite("icon/"..SpriteName)
            --ChatObj.arrows[UI.Image]:LoadSprite("icon/"..SpriteName.."-1")
            -- PLayerIcon[SGK.newCharacterIcon].sex = _PlayerData.Sex
            --PLayerIcon[SGK.newCharacterIcon].headFrame = _PlayerData.HeadFrame
            ChatManager.ChatUpdate(data.channel,{idx},{Bubble = _PlayerData.Bubble,Sex = _PlayerData.Sex,HeadFrame = _PlayerData.HeadFrame,HeadFrameId = _PlayerData.HeadFrameId})
        end)
 		ChatObj.icon[CS.UGUIClickEventListener].onClick = (function ( ... )
 			if data.ChatIdx and data.ChatIdx == 0 then
 				--PlayerTips({name = data.fromname,level = "nil",pid = data.fromid})
 				DialogStack.PushPrefStact("mapSceneUI/otherPlayerInfo", data.fromid)
 			end
		end)
		
		if ChatObj.Content.bg.TeamText then
			ChatObj.Content.bg.descTeam.gameObject:SetActive(false)
			ChatObj.Content.bg.TeamText.gameObject:SetActive(false)
		end
		ChatObj.Content.bg.desc.gameObject:SetActive(true)
		local specialID = nil
		if tonumber(self.applyType) == 3 or tonumber(self.applyType) == 4 then
			local str = StringSplit(desc,"|")
			specialID = tonumber(str[2])
			desc = str[1]
		end
 		local WordFilter = WordFilter.check(desc)--屏蔽字
 		local t = StringSplit(WordFilter,"\n")
 		--print("assssssssssssssssss",sprinttb(t))
 		if tonumber(self.applyType) ~=1 then
 			ChatObj.Content.bg.desc[CS.InlineText].text = WordFilter
 			if ChatObj.Content.bg.TeamText and ChatObj.Content.bg.descTeam and isleft then
 				ChatObj.Content.bg.descTeam[CS.InlineText].text = t[1].."\n"
 				ChatObj.Content.bg.TeamText[CS.InlineText].text = t[2]
 				ChatObj.Content.bg.descTeam.gameObject:SetActive(true)
 				ChatObj.Content.bg.TeamText.gameObject:SetActive(true)
 				ChatObj.Content.bg.desc.gameObject:SetActive(false)
 			end
 		else
	 		if playerModule.IsDataExist(data.fromid) and playerModule.IsDataExist(data.fromid).honor == 9999 then
		 		ChatObj.Content.bg.desc[CS.InlineText].text = WordFilter
		 	else
		 		ChatObj.Content.bg.desc[CS.InlineText].text = WordFilter
		 	end
		end
	 -- 	ChatObj.Content.bg.bg_prefab[CS.UGUIClickEventListener].onClick = function ( ... )
 	-- 		--玩家装扮
 	-- 		local prefab = self.view.gameObject
 	-- 		if UnityEngine.GameObject.FindWithTag("UITopRoot") then
 	-- 			prefab = UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject
 	-- 		end
 	-- 		DialogStack.PushPref("FriendInfo",{pid=pid,desc=WordFilter,PlayerData=data.PlayerData},prefab)
 	-- 	end
 	-- 	ChatObj.Content.bg.desc[CS.UGUIClickEventListener].onClick = function ( ... )
 	-- 		--玩家装扮
 	-- 		local prefab = self.view.gameObject
 	-- 		if UnityEngine.GameObject.FindWithTag("UITopRoot") then
 	-- 			prefab = UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject
 	-- 		end
 	-- 		DialogStack.PushPref("FriendInfo",{pid=pid,desc=WordFilter,PlayerData=data.PlayerData},prefab)
		-- end

		-- if ChatObj.Content.bg.desc.apply then
		--     CS.UGUIClickEventListener.Get(ChatObj.Content.bg.desc.apply.gameObject).onClick=function()
		-- 		local teamInfo = module.TeamModule.GetTeamInfo();
		-- 		if teamInfo.group == 0 then
		-- 			if openLevel.GetStatus(1601) then
		-- 				self.IsApply = true
		-- 				module.TeamModule.GetPlayerTeam(data.fromid,true)--查询玩家队伍信息
		-- 			else
		-- 				showDlgError(nil,"等级不足")
		-- 			end
		-- 		else
		-- 			showDlgError(nil,"已在队伍中")
		-- 		end
		--     end
		-- end
 		if tonumber(self.applyType) == 1 then
 			if ChatObj.Content.bg.descTeam.apply then
 				--print("不是组队")
 				ChatObj.Content.bg.descTeam.apply.gameObject:SetActive(false)
 				ChatObj.Content.bg[UI.VerticalLayoutGroup].childForceExpandWidth = false
 			end
 		end
		if tonumber(self.applyType) ~=1 and tonumber(self.applyType) ~=3 and tonumber(self.applyType) ~= 4 then
			if ChatObj.Content.bg.descTeam.apply then
				--print("是组队")
				ChatObj.Content.bg.descTeam.apply[CS.UGUISpriteSelector].index = 0
				ChatObj.Content.bg.descTeam.apply.gameObject:SetActive(true)
				ChatObj.Content.bg[UI.VerticalLayoutGroup].childForceExpandWidth = true
				CS.UGUIClickEventListener.Get(ChatObj.Content.bg.descTeam.apply.gameObject).onClick=function()
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
				end
			end
		end
		if tonumber(self.applyType)==3 then
			if ChatObj.Content.bg.descTeam.apply then
				--print("是组队")
				ChatObj.Content.bg.descTeam.apply[CS.UGUISpriteSelector].index = 1
				ChatObj.Content.bg.descTeam.apply.gameObject:SetActive(true)
				ChatObj.Content.bg[UI.VerticalLayoutGroup].childForceExpandWidth = true
				CS.UGUIClickEventListener.Get(ChatObj.Content.bg.descTeam.apply.gameObject).onClick=function()
					ERROR_LOG("协助")
					local _pid = data.fromid
					module.CooperationQuestModule.Check(_pid,specialID)
				end
			end
		end
		if tonumber(self.applyType)==4 then
			if ChatObj.Content.bg.descTeam.apply then
				--print("是组队")
				ChatObj.Content.bg.descTeam.apply[CS.UGUISpriteSelector].index = 2
				ChatObj.Content.bg.descTeam.apply.gameObject:SetActive(true)
				ChatObj.Content.bg[UI.VerticalLayoutGroup].childForceExpandWidth = true
				CS.UGUIClickEventListener.Get(ChatObj.Content.bg.descTeam.apply.gameObject).onClick=function()
					local _pid = data.fromid
					module.equipmentModule.QueryEquipInfoFromServer(_pid, specialID, function (equip)
	  					DialogStack.PushPrefStact("ItemDetailFrame", {type = 43, id = equip.id,uuid = specialID, otherPid =_pid})
	  				end)
				end
			end
		end
		-- if tonumber(self.applyType)==2 then
		-- 	if unionModule.Manage:GetUionId() == 0 then
		-- 		module.unionModule.JoinUnionByPid(data.fromid)
		-- 	else
		-- 		showDlgError(nil,"您已经加入了一个公会")
		-- 	end
		-- end



		--  ChatObj.Content.bg.desc[CS.InlineText].onClick=function (name,id)
		-- 	--local id = 1
 		-- 	ERROR_LOG("id========>>",name,id)
 		-- 	if id == 1 then--申请入队
 		-- 		local teamInfo = module.TeamModule.GetTeamInfo();
    	-- 		if teamInfo.group == 0 then
    	-- 			if openLevel.GetStatus(1601) then
		--  				self.IsApply = true
		--  				module.TeamModule.GetPlayerTeam(data.fromid,true)--查询玩家队伍信息
		--  			else
		--  				showDlgError(nil,"等级不足")
		--  			end
	 	-- 		else
	 	-- 			showDlgError(nil,"已在队伍中")
	 	-- 		end
 		-- 	elseif id == 2 then--申请入会
 		-- 		if unionModule.Manage:GetUionId() == 0 then
	 	-- 			module.unionModule.JoinUnionByPid(data.fromid)
	 	-- 		else
	 	-- 			showDlgError(nil,"您已经加入了一个公会")
	 	-- 		end
 		-- 	end
		 -- end
		 
 		--ChatView[UnityEngine.RectTransform]:DOScale(Vector3(1,1,1),0.1):OnComplete(function ( ... )
 		-- SGK.Action.DelayTime.Create(0.1):OnComplete(function()
 		-- 	--ChatView[UnityEngine.UI.VerticalLayoutGroup].padding.bottom = ChatView_LR[UnityEngine.RectTransform].sizeDelta.y >= 79 and 0 or 30
 		-- 	--ChatView[UnityEngine.UI.VerticalLayoutGroup].enabled = false
 		-- 	--ChatView[UnityEngine.UI.VerticalLayoutGroup].enabled = true
 		-- 	if self.view.ChatScrollView.Viewport.Content[UnityEngine.RectTransform].sizeDelta.y > 585 then
 		-- 		local height = 292+self.view.ChatScrollView.Viewport.Content[UnityEngine.RectTransform].sizeDelta.y-585
 		-- 		--ERROR_LOG(height)
 		-- 		--self.view.ChatScrollView.Viewport.Content[UnityEngine.RectTransform].localPosition = Vector3(0,height,0)
 		-- 	end
 		-- end)
  	end
end
function View:listEvent()
	return {
		"Chat_INFO_CHANGE",
		"Chat_RedDot_CHANGE",
		"Team_members_Request",
		"Stop_MapSceneChat",
	}
end

-- function View:OnApplicationPause(status)
-- 	print("状态", status)
-- 	if not status then
-- 		self.TempData = {}
-- 		self:ChatPanelRes(self.ChatType)
-- 		print("数量", #self.TempData)
-- 	end
-- end

function View:onEvent(event,data)
	if event == "Chat_INFO_CHANGE" then
		if self.Stop_MapSceneChat then
			return
		end
		local ChatData = ChatManager.GetManager(data.channel)
		if data.channel == self.ChatType then
			if self.ChatType ~= 0 then
				if data.idx > #self.TempData then
					self.TempData[#self.TempData + 1] = data;
					self.view.ChatScrollView[CS.ChatContent]:AddItem();
					-- table.insert(self.TempDataCache, data)
				end
			else
				self.view.ScrollView.Viewport.Content.desc[UnityEngine.UI.Text].text = self.view.ScrollView.Viewport.Content.desc[UnityEngine.UI.Text].text..data.message.."\n"
				self:ChatSystem()
			end
		else
			for i = 1, #self.view.ToggleGrid do
				if self.ToggleToChatType[i] ~= self.ChatType then
	 				self.view.ToggleGrid[i].RedDot:SetActive(ChatManager.GetPLayerStatus(self.ToggleToChatType[i]) ~= nil)
	 			end
 			end
		end
	elseif event == "Chat_RedDot_CHANGE" then
		if self.TogglePrivateArr[data.id] then
			self.TogglePrivateArr[data.id].RedDot.gameObject:SetActive(true)
		end
	elseif event == "Team_members_Request" then
		if self.IsApply then
			self.IsApply = false
			if data.upper_limit == 0 or (module.playerModule.Get(module.playerModule.GetSelfID()).level >= data.lower_limit and  module.playerModule.Get(module.playerModule.GetSelfID()).level <= data.upper_limit) then
				module.TeamModule.JoinTeam(data.members[3])
			else
				showDlgError(nil,"你的等级不满足对方的要求")
			end
		end
	elseif event == "Stop_MapSceneChat" then
		self.Stop_MapSceneChat = data.Stop_MapSceneChat
		self.TempData = {}
		self.stop_scrollView = false--切换页签还原可滚动
		if self.Stop_MapSceneChat then
			self.view.ChatScrollView[CS.ChatContent]:SetChatCount(0)
		else
			self:ChatPanelRes(self.ChatType)
		end
	end
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
