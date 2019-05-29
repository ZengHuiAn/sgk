local NetworkService = require "utils.NetworkService";
local EventManager = require 'utils.EventManager';
local ChatManager = require 'module.ChatModule'
local playerModule = require "module.playerModule"
local MailModule = require 'module.MailModule'
local TeamModule = require "module.TeamModule"
local unionModule = require "module.unionModule"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
 	self.Data = data
 	self.NowChatPlayerData = nil--当前正在聊天的数据
 	if data and data.playerData then
 		self.NowChatPlayerData = data.playerData
 	end
 	self.ChatObjArr = {}
 	self.ChatObjPool = {}
 	self.TogglePrivateArr = {}--私聊玩家页签
 	self.ChatHeight = 0
 	self.ToggleToChatType = {[1] = 0,[2] = 1,[3] = 3,[4] = 6,[5] = 7}--toggle排序1系统2世界3工会4私聊5队伍
 	self.ChatTypeToToggle = {[0] = 1,[1] = 2,[6] = 4,[3] = 3,[7] = 5}--数据排序0系统1世界6私聊3工会7队伍8加好友消息
 	self.ChatType = data and self.ToggleToChatType[data.type] or 1 --按数据排序存
 	TeamModule.GetTeamInfo()--获取当前自己的队伍
 	self.IsApply = false--是否开始申请
 	self.stop_scrollView = false--是否scrollView滑动
 	self.view.SendBtn[CS.UGUIClickEventListener].onClick = (function ()
 		local desc = self.view.InputField[UnityEngine.UI.InputField].text
 		--local desc = "111#24ddd#24"
 		--self:ChatPanelRef(desc)
 		if self.ChatType == 0 then
 			showDlgError(self.view,"无法发送系统消息")
 			return
 		end
 		if #self:string_segmentation(desc) > 0 then
 			print(self.ChatType.."发送:"..desc)
 			if self.ChatType == 6 then
 				--用户私聊
 				if self.NowChatPlayerData then
 					NetworkService.Send(5009,{nil,self.NowChatPlayerData.id,3,desc,""})
 					ChatManager.SetManager({fromid = self.NowChatPlayerData.id,fromname = self.NowChatPlayerData.name,title = desc},1,3)--0聊天显示在左1显示在右
 				else
 					showDlgError(nil,"没有私聊对象")
 				end
 			elseif self.ChatType == 7 then
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
 				end
 			else
 				ChatManager.ChatMessageRequest(self.ChatType,desc)
		 		--NetworkService.Send(2005,{nil,self.ChatType,desc});--聊天发送
		 	end
		 else
		 	showDlgError(nil,"消息内容不能为空")
	 	end
	 	self.view.InputField[UnityEngine.UI.InputField].text = ""
 	end)
 	for i = 1, #self.view.ToggleGrid do
 		self.view.ToggleGrid[i][CS.UGUIClickEventListener].onClick = (function ( ... )
 			self:ToggleTypeRef(i)
 		end)
 		if i ~= 4 then--不是私聊
	 		self.view.ToggleGrid[i].RedDot:SetActive(ChatManager.GetPLayerStatus(self.ToggleToChatType[i]) ~= nil)
	 	else
	 		self.view.ToggleGrid[4].RedDot:SetActive(not ChatManager.PrivateShowRed())--重新判断私聊是否有红点
	 	end
 	end
 	self.view.Emoji[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view.mask:SetActive(true)
 	end
 	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
 		self.view.mask:SetActive(false)
 	end
 	for i =1,#self.view.mask.bg do
 		self.view.mask.bg[i][CS.UGUIClickEventListener].onClick = function ( ... )
 			self.view.mask:SetActive(false)
 			self.view.InputField[UnityEngine.UI.InputField].text = self.view.InputField[UnityEngine.UI.InputField].text.."[#"..i.."]"
 		end
 	end
 	if data then
	 	self:ToggleTypeRef(data.type)
	 	self.view.ToggleGrid[data.type][UnityEngine.UI.Toggle].isOn = true
	 end
	MailModule.GetManager()--获取邮件中的玩家信息
	--DispatchEvent("CloseBackChatBtn")
	self.view[UnityEngine.RectTransform]:DOScale(Vector3(1,1,1),0.25):OnComplete(function ( ... )
		self:ChatPanelRes(self.ChatType)
	end)
end

function View:ToggleTypeRef(i)
	if i == 3 and unionModule.Manage:GetUionId() == 0 then
		self.view.ToggleGrid[self.ChatTypeToToggle[self.ChatType]][UnityEngine.UI.Toggle].isOn = true
		showDlgError(self.view,"您需要先加入一个公会")
	else
		if i == 4 then
			--私聊模式
			--self.view.BorderPanel.bgBorder[CS.TweenWidth]:PlayForward()
			self.view.PrivateScrollView.gameObject:SetActive(true)
			--self.view.PrivatePanel[CS.TweenAlpha]:PlayForward()
			
		else
			--正常模式
			--self.view.BorderPanel.bgBorder[CS.TweenWidth]:PlayReverse()
			--self.view.PrivatePanel[CS.TweenAlpha]:PlayReverse()
			--self.view.BorderPanel.bgBorder.gameObject.transform:DOLocalRotate(Vector3.zero,0.25):OnComplete(function( ... )
				self.view.PrivateScrollView.gameObject:SetActive(false)
			--end)
		end
		self.stop_scrollView = false--切换页签还原可滚动
		self.ChatType = self.ToggleToChatType[i]
		self:ChatPanelRes(self.ChatType)
	end
end

function View:ChatPanelRes(ChatType)
	--聊天频道重置

	self.ChatHeight = 0
	for i = 1,#self.ChatObjArr do
		--CS.UnityEngine.GameObject.Destroy(self.ChatObjArr[i].gameObject)

		self.ChatObjArr[i].gameObject:SetActive(false)
		-- if self.ChatObjArr[i].Left.activeSelf then
		-- 	self.ChatObjArr[i].Left.Content.bg[CS.InlineManager]:Reset_TextMeshInfo()
		-- else
		-- 	self.ChatObjArr[i].Right.Content.bg[CS.InlineManager]:Reset_TextMeshInfo()
		-- end
		--self.ChatObjArr[i].gameObject.transform.localScale = Vector3(0.1,0.1,0.1)
		-- for j = 1,self.ChatObjArr[i].desc.gameObject.transform.childCount do
		-- 	self.ChatObjArr[i].desc.gameObject.transform:GetChild(j-1).gameObject:SetActive(false)
		-- end
		self.ChatObjPool[#self.ChatObjPool + 1] = self.ChatObjArr[i].gameObject
	end
	self.ChatObjArr = {}
	--CS.SpringPanel.Begin(self.view.Root.gameObject,Vector3(0,0,0),13)

	local ChatData = ChatManager.GetManager(ChatType)
	if ChatType == 6 then
		if self.NowChatPlayerData then--加载当前正在私聊对象
			if self.TogglePrivateArr[self.NowChatPlayerData.id] then
				self.TogglePrivateArr[self.NowChatPlayerData.id].RedDot.gameObject:SetActive(false)
			end
			ChatManager.SetReadChatid(self.NowChatPlayerData.id,true)--已读私聊
			self:TogglePrivate(self.NowChatPlayerData)
		end
		if ChatData then--加载其他私聊对象
			for k,v in pairs(ChatData) do
				self:TogglePrivate({id = v[1].fromid,name = v[1].fromname})
				if not self.NowChatPlayerData then
					self.NowChatPlayerData = {id = v[1].fromid,name = v[1].fromname}
					self.TogglePrivateArr[self.NowChatPlayerData.id].RedDot.gameObject:SetActive(false)
					ChatManager.SetReadChatid(self.NowChatPlayerData.id,true)--已读私聊
				else
					self.TogglePrivateArr[v[1].fromid][UnityEngine.UI.Toggle].isOn = false
				end
			end
			if ChatData[self.NowChatPlayerData.id] then--加载聊天内容
				for i = 1,#ChatData[self.NowChatPlayerData.id] do
					self:ChatPanelRef(ChatData[self.NowChatPlayerData.id][i])
				end
			end
		end
	else
		if ChatData and #ChatData > 0 then
			for i = 1,#ChatData do
				self:ChatPanelRef(ChatData[i])
			end
		else
			--showDlgError(self.view,"本频道无聊天数据")
		end
	end
end

function View:TogglePrivate(data)
	if self.TogglePrivateArr[data.id] then
		return
	end
	local PrivateToggle = self.view.PrivateScrollView.Viewport.Content.Toggle
	local TogglePrivateObj = CS.UnityEngine.GameObject.Instantiate(PrivateToggle.gameObject, self.view.PrivateScrollView.Viewport.Content.gameObject.transform)
	self.TogglePrivateArr[data.id] = CS.SGK.UIReference.Setup(TogglePrivateObj)
	self.TogglePrivateArr[data.id].Label[UnityEngine.UI.Text].text = data.name
	self.TogglePrivateArr[data.id][CS.UGUIClickEventListener].onClick = (function ( ... )
	--私聊
		if not ChatManager.GetReadChatid(data.id) then
			ChatManager.SetReadChatid(data.id,true)--已读私聊
			self.view.ToggleGrid[4].RedDot:SetActive(not ChatManager.PrivateShowRed())--重新判断私聊是否有红点
		end
		self.TogglePrivateArr[data.id].RedDot.gameObject:SetActive(false)
		self.NowChatPlayerData = data
		self:ChatPanelRes(6)
	 end)
	TogglePrivateObj:SetActive(true)
	--self.TogglePrivateArr[data.id][UnityEngine.UI.Toggle].isOn = true

	if ChatManager.GetReadChatid(data.id) then
		self.TogglePrivateArr[data.id].RedDot.gameObject:SetActive(false)
	else
		self.TogglePrivateArr[data.id].RedDot.gameObject:SetActive(true)
	end
	self.view.ToggleGrid[4].RedDot:SetActive(not ChatManager.PrivateShowRed())--重新判断私聊是否有红点
end

function View:ChatPanelRef(data)
	--聊天频道刷新
	local desc = data.message
	--print(desc)
	--print(desc.."->"..#self:string_segmentation(desc))
 	if data then--and #self:string_segmentation(desc) > 0 then
 		local obj = nil
 		if #self.ChatObjPool > 0 then
 			obj = self.ChatObjPool[1]
 			table.remove(self.ChatObjPool,1)
 		else
	 		obj = CS.UnityEngine.GameObject.Instantiate(self.view.ScrollView.Viewport.Content.ChatObj.gameObject,self.view.ScrollView.Viewport.Content.gameObject.transform)
	 	end
 		obj:SetActive(true)
 		--obj.gameObject.transform:DOScale(Vector3(1,1,1),0.25)
 		self.ChatObjArr[#self.ChatObjArr+1] = CS.SGK.UIReference.Setup(obj)
 		local x = self.ChatType == 6 and -100 or 0--私聊-100其他都是0
 		--print("!!!"..self.ChatType.."\n"..data.fromid..">"..playerModule.Get().id)
 		local head = 11001
 		local ChatObj = nil
 		if data.fromid == playerModule.Get().id or (data.ChatIdx and data.ChatIdx == 1) then
 			--左边对话
 			x = self.ChatType == 6 and -100 or 0
 			ChatObj = self.ChatObjArr[#self.ChatObjArr].Right
 			self.ChatObjArr[#self.ChatObjArr].Left.gameObject:SetActive(false)
 			self.ChatObjArr[#self.ChatObjArr].Right.gameObject:SetActive(true)
 			head = playerModule.Get().head ~= 0 and playerModule.Get().head or 11001
 		else
 			--右边对话
 			x = 0
 			ChatObj = self.ChatObjArr[#self.ChatObjArr].Left
 			self.ChatObjArr[#self.ChatObjArr].Right.gameObject:SetActive(false)
 			self.ChatObjArr[#self.ChatObjArr].Left.gameObject:SetActive(true)
 			if playerModule.IsDataExist(data.fromid) then
 				head = playerModule.IsDataExist(data.fromid).head ~= 0 and playerModule.IsDataExist(data.fromid).head or 11001
 			else
 				playerModule.Get(data.fromid,(function( ... )
 					local head = playerModule.IsDataExist(data.fromid).head ~= 0 and playerModule.IsDataExist(data.fromid).head or 11001
 					ChatObj.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..head)
 				end))
 			end
 		end
 		ChatObj.icon[CS.UGUIClickEventListener].onClick = (function ( ... )
 			if data.ChatIdx and data.ChatIdx == 0 then
	 			PlayerTips({name = data.fromname,level = "nil",pid = data.fromid},{BtnDesc = "添加好友",Function = (function ( ... )
	 				NetworkService.Send(5013,{nil,1,data.fromid})--添加好友
	 			end)})
	 		end
 		end)
 		local WordFilter = WordFilter.check(desc)--屏蔽字
 		--self.ChatObjArr[#self.ChatObjArr].desc[CS.Emoji]:FindEmojiPos(WordFilter)
 		--ChatObj.Content.bg.desc[UnityEngine.UI.Text].text = WordFilter
 		ChatObj.Content.bg.desc[CS.InlineText].text = WordFilter
 		ChatObj.Content.bg.desc[CS.InlineText].onClick = function (name,id)
 			--ERROR_LOG(name..">"..id)
 			if id == 1 then--申请入队
 				local teamInfo = module.TeamModule.GetTeamInfo();
    			if teamInfo.group == 0 then
	 				self.IsApply = true
	 				module.TeamModule.GetPlayerTeam(data.fromid,true)--查询玩家队伍信息
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
 		ChatObj.name[UnityEngine.UI.Text].text = (data.ChatIdx == 0 and data.fromname or playerModule.Get().name)..""
 		ChatObj.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..head)
 		self.ChatObjArr[#self.ChatObjArr][UnityEngine.RectTransform]:DOScale(Vector3(1,1,1),0.1):OnComplete(function ( ... )
 			self.ChatHeight = self.ChatHeight + 120+ChatObj.Content[UnityEngine.RectTransform].sizeDelta.y
 			--ERROR_LOG(">>"..self.ChatHeight)
 			self.ChatObjArr[#self.ChatObjArr][UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(674,120+ChatObj.Content[UnityEngine.RectTransform].sizeDelta.y)
 			if self.ChatHeight >= 960 then
	 			if not self.stop_scrollView then
	 				self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].localPosition = Vector3(0,(self.ChatHeight-960),0)
	 			end
	 			if ChatManager.GetPLayerStatus(data.channel).time == data.time and string.find(data.message, "@"..playerModule.Get().name) then
	 				ChatManager.SetPLayerStatus(data.channel,nil)
	 				self.stop_scrollView = true
	 				self.view.ToggleGrid[self.ChatTypeToToggle[data.channel]].RedDot:SetActive(false)
	 			end
	 		else
	 			if ChatManager.GetPLayerStatus(data.channel) and ChatManager.GetPLayerStatus(data.channel).time == data.time and string.find(data.message, "@"..playerModule.Get().name) then
	 				ChatManager.SetPLayerStatus(data.channel,nil)
	 				self.stop_scrollView = true
	 				self.view.ToggleGrid[self.ChatTypeToToggle[data.channel]].RedDot:SetActive(false)
	 			end
 			end
 		end)
 		--print("x->"..ChatObj.desc[UnityEngine.RectTransform].sizeDelta.x)
 		--print( tostring(data.fromname))
  	end
 --  	if self.ChatHeight >= 960 then
	-- 	--self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform]:DOMove(Vector3(0,(#self.ChatObjArr-6)*170+50,0),0.5):SetDelay(0.5)
	-- 	--self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].localPosition = Vector3(0,(#self.ChatObjArr-6)*170+50,0)
	-- 	self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform]:DOScale(Vector3(1,1,1),0.25):OnComplete(function ( ... )
	-- 		self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].localPosition = Vector3(0,(self.ChatHeight-960),0)
	-- 	end)
	-- end
end

function View:listEvent()
	return {
		"Chat_INFO_CHANGE",
		"Chat_RedDot_CHANGE",
		"Team_members_Request",
	}
end

function View:onEvent(event,data)
	if event == "Chat_INFO_CHANGE" then
		local ChatData = ChatManager.GetManager(data.channel)
		--ERROR_LOG(data.channel.."<type>"..self.ChatType)
		if data.channel == self.ChatType then
			if self.ChatType == 6 then
				if self.NowChatPlayerData and ChatData[self.NowChatPlayerData.id] then
					local i = #ChatData[self.NowChatPlayerData.id]
					self:ChatPanelRef(ChatData[self.NowChatPlayerData.id][i])
					ChatManager.SetReadChatid(self.NowChatPlayerData.id,true)--已读私聊
					self.TogglePrivateArr[self.NowChatPlayerData.id].RedDot.gameObject:SetActive(false)
					self.view.ToggleGrid[4].RedDot:SetActive(not ChatManager.PrivateShowRed())--重新判断私聊是否有红点
				end
			else
				self:ChatPanelRef(ChatData[#ChatData])
			end
		else
			for i = 1, #self.view.ToggleGrid do
				if self.ToggleToChatType[i] ~= self.ChatType and i ~= 4 then
	 				self.view.ToggleGrid[i].RedDot:SetActive(ChatManager.GetPLayerStatus(self.ToggleToChatType[i]) ~= nil)
	 			end
 			end
		end
	elseif event == "Chat_RedDot_CHANGE" then
		self.view.ToggleGrid[4].RedDot:SetActive(true)--私聊页签红点
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
