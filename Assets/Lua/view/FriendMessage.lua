local ChatManager = require 'module.ChatModule'
local MailModule = require 'module.MailModule'
local FriendModule = require 'module.FriendModule'
local NetworkService = require "utils.NetworkService";
local playerModule = require "module.playerModule"
local unionModule = require "module.unionModule"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local IconFrameHelper = require "utils.IconFrameHelper"
local Time = require "module.Time"
local ItemHelper = require "utils.ItemHelper"
local UserDefault = require "utils.UserDefault";
local npcConfig = require "config.npcConfig"
local System_Set_data=UserDefault.Load("System_Set_data");
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data
	self.listData = {}
	self.SNArr = {}
	self.selectIndex = 0
	self.init = true
	if data and data.pid then
		local list = nil
        if ChatManager.GetManager(6) then
            list = ChatManager.GetManager(6)[data.pid]
        end
		DialogStack.PushPref("FriendChat",{data = list,pid = data.pid,is_mask = false},self.view.gameObject)--UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject)
		self.view.ChatScrollView:SetActive(false)
	end
	self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
	self.nguiDragIconScript.RefreshIconCallback = (function (go,idx)
		local obj = CS.SGK.UIReference.Setup(go)
		local tempData = self.listData[idx]
		obj.red:SetActive(false)
		obj.red.num[UnityEngine.UI.Text].text = ""
		if idx > 0 then
			if not tempData or not tempData.fromid then
				return
			end
			local count = ChatManager.GetPrivateChatData(tempData.fromid)
			if count > 0 then
				obj.red.num[UnityEngine.UI.Text].text = count < 100 and count.."" or "99"
			end
			obj.red:SetActive(count>0)
			obj.name[UnityEngine.UI.Text].text = tempData.fromname..""
			-- local PLayerIcon = nil
			-- if obj.hero.transform.childCount == 0 then
			-- 	PLayerIcon = IconFrameHelper.Hero({},obj.hero)
				local PLayerIcon = IconFrameHelper.Create(obj.hero,{pid = tempData.fromid})
			-- else
			-- 	local objClone = obj.hero.transform:GetChild(0).gameObject
			-- 	PLayerIcon = SGK.UIReference.Setup(objClone)
			-- end
			PLayerIcon:SetActive(true)
			if not tempData.source or tempData.source == 0 then
		 		-- PlayerInfoHelper.GetPlayerAddData(tempData.fromid,99,function (addData)
		 		-- 	IconFrameHelper.UpdateHero({pid = tempData.fromid,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
		 		-- end)
		 	else
		 		local cfg = npcConfig.GetnpcList()[tempData.fromid]
		 		--IconFrameHelper.UpdateHero({icon = cfg.icon,sex = cfg.Sex,headFrame = cfg.HeadFrame},PLayerIcon)
		 	end
		 	if count > 0 and self.init then
		 		self.init = false
		 	 	self:FriendChat(obj,idx)
		 	end
	 		obj.hero[CS.UGUIClickEventListener].onClick = function ( ... )
				self:FriendChat(obj,idx)
	 		end
	 	else
	 		if obj.hero.transform.childCount > 0 then
	 			obj.hero.transform:GetChild(0).gameObject:SetActive(false)
	 		end
	 		obj.name[UnityEngine.UI.Text].text = "离线消息"
	 		obj.hero[CS.UGUIClickEventListener].onClick = function ( ... )
	 			if not self.view.ChatScrollView.Viewport.Content[1].activeSelf and not self.view.ChatScrollView.Viewport.Content[2].activeSelf and not self.view.ChatScrollView.Viewport.Content[2].activeSelf then
		 			self:SystemMessage()
		 		end
	 			self.view.ChatScrollView:SetActive(true)
	 			if DialogStack.GetPref_list("FriendChat") then
	 				DialogStack.GetPref_list("FriendChat"):SetActive(false)
	 			end
	 			self.selectIndex = idx
		 		self.view.select.transform:SetParent(obj.selectPos.transform,false)
		 		self.view.select.transform.localPosition = Vector3.zero
		 		self.view.select:SetActive(true)
		 		obj.red:SetActive(false)
		 		DispatchEvent("SystemMessageListRedDotChange")
	 		end
	 		local SystemMessageList = ChatManager.GetSystemMessageList()
			if SystemMessageList then
				for k,v in pairs(SystemMessageList) do
					for i = 1,#v do
						if v[i][6] and v[i][6] == 0 then
							obj.red:SetActive(true)
							break
						end
					end
				end
			end
	 	end
	 	if self.selectIndex == idx then
	 		self.view.select.transform:SetParent(obj.selectPos.transform,false)
	 		self.view.select.transform.localPosition = Vector3.zero
	 		self.view.select:SetActive(true)
	 	elseif obj.selectPos.transform.childCount > 0 then
	 		self.view.select:SetActive(false)
	 	end

	 	obj.gameObject:SetActive(true)
	end)
	self:RefDataCount()
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.mask.transform.childCount == 1 then
			UnityEngine.GameObject.Destroy(self.view.mask.transform:GetChild(0).gameObject)
		end
		self.view.mask:SetActive(false)
	end
	if self.selectIndex == 0 then
		self:SystemMessage()
	end
end

function View:FriendChat(obj,idx)
	local list = {}
	local tempData = self.listData[idx]
	local ChatData = ChatManager.GetManager(6)
	if ChatData and ChatData[tempData.fromid] then
		ChatData = ChatData[tempData.fromid]
		for i = 1,#ChatData do
			list[i] = ChatData[i]
		end
	end
	local ChatData = ChatManager.GetManager(8)
	if ChatData and ChatData[tempData.fromid] then
		ChatData = ChatData[tempData.fromid]
		for i = 1,#ChatData do
			if ChatData[i].status == 1 then
				--NetworkService.Send(5005,{nil,{{ChatData[i].id,2}}})--已读取加好友通知
			else
				list[#list+1] = ChatData[i]
			end
		end
	end
	table.sort(list,function(a,b)
		return a.time < b.time
	end)
	if DialogStack.GetPref_list("FriendChat") then
		DialogStack.GetPref_list("FriendChat"):SetActive(true)
		DispatchEvent("FriendChatChange",{data = list,pid = tempData.fromid,is_mask = false,source = tempData.source})
	else
		DialogStack.PushPref("FriendChat",{data = list,pid = tempData.fromid,is_mask = false,source = tempData.source},self.view.gameObject)--UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject)
	end
	self.view.ChatScrollView:SetActive(false)
	if not tempData.source or tempData.source == 0 then
		-- PlayerInfoHelper.GetPlayerAddData(tempData.fromid,99,function (addData)
 	-- 		IconFrameHelper.UpdateHero({pid = tempData.fromid,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
 	-- 	end,true)
	end
	self.selectIndex = idx
	self.view.select.transform:SetParent(obj.selectPos.transform,false)
	self.view.select.transform.localPosition = Vector3.zero
	self.view.select:SetActive(true)
end

function View:SystemMessage()
	local SystemMessageList = ChatManager.GetSystemMessageList()
	if SystemMessageList then
		for k,v in pairs(SystemMessageList) do
			local idx = k < 4 and k or 4
			if k == 1 then
				self.view.ChatScrollView.Viewport.Content[k].title[UI.Text].text = "试炼活动"
			elseif k == 2 then
				self.view.ChatScrollView.Viewport.Content[k].title[UI.Text].text = "组队副本"
			elseif k == 3 then
				self.view.ChatScrollView.Viewport.Content[k].title[UI.Text].text = "元素暴走"
			else
				self.view.ChatScrollView.Viewport.Content[idx].title[UI.Text].text = "系统奖励"
			end
			for i = 1,#v do
				self.view.ChatScrollView.Viewport.Content[idx]:SetActive(true)
				local old = self.view.ChatScrollView.Viewport.Content[idx].desc[UI.Text].text
				local cfg = ItemHelper.Get(v[i][2], v[i][3]);
				local desc = old.."获得"..cfg.name.."x"..v[i][4]
				if #v > i then
					desc = desc.."\n"
				end
				self.view.ChatScrollView.Viewport.Content[idx].desc[UI.Text].text = desc
				if v[i][5] > System_Set_data.SystemMessageList_Time then
					System_Set_data.SystemMessageList_Time = v[i][5]
				end
				if v[i][6] then
					SystemMessageList[k][i][6] = 1
				end
			end
		end
		DispatchEvent("SystemMessageListRedDotChange")
	end
end
function View:RefDataCount()
	local listDataCount = #self.listData
	local select_pid = self.listData[self.selectIndex] and self.listData[self.selectIndex].fromid or 0
	local Chat_pids = {}
	self.listData = {}
	local ChatData = ChatManager.GetManager(6)--聊天
	if ChatData then
		for k,v in pairs(ChatData)do
			if #v > 0 then
				self.listData[#self.listData + 1] = v[#v]
				Chat_pids[v[#v].fromid] = true
				if self.Data and self.Data.pid == v[#v].fromid then
					self.Data = nil
					select_pid = v[#v].fromid
				end
			end
		end
	end
	ChatData = ChatManager.GetManager(8)--加好友通知
	if ChatData then
		for k,v in pairs(ChatData)do
			if #v > 0 and not Chat_pids[v[#v].fromid] then
				self.listData[#self.listData + 1] = v[#v]
				if self.Data and self.Data.pid == v[#v].fromid then
					self.Data = nil
					select_pid = v[#v].fromid
				end
			end
		end
	end
	table.sort(self.listData,function(a,b)
		local status_a,status_b = self:GetPrivateChatStatus(a.fromid),self:GetPrivateChatStatus(b.fromid)
		if a.channel == 8 then
			status_a = a.status
		end
		if b.channel == 8 then
			status_b = b.status
		end
		if status_a == status_b then
			return a.time > b.time
		else
			return status_a < status_b
		end
	end)
	if self.Data and self.Data.pid then
		self.selectIndex = #self.listData+1
		table.insert(self.listData,{fromid = self.Data.pid,fromname = self.Data.name})
	elseif select_pid > 0 then
		for i = 1,#self.listData do
			if self.listData[i].fromid == select_pid then
				self.selectIndex = i
				break
			end
		end
	end
	if #self.listData == 0 or listDataCount ~= #self.listData then
		self.nguiDragIconScript.DataCount = #self.listData+1--初始化数量
		--self.view.tips:SetActive(#self.listData == 0)
	else
		self.nguiDragIconScript:ItemRef()
	end
	--self.nguiDragIconScript:ScrollMove(self.selectIndex)
end
function View:GetPrivateChatStatus(fromid)
	if ChatManager.GetPrivateChatData(fromid) > 0 then
		return 1
	else
		return 2
	end
end
function View:OnDestroy()
	DialogStack.Destroy("FriendChat")
	-- if DialogStack.GetPref_list("FriendChat") then
	-- 	UnityEngine.GameObject.Destroy(DialogStack.GetPref_list("FriendChat"))
	-- end
-- 	local ChatData = ChatManager.GetManager(8)--加好友通知
-- 	if ChatData then
-- 		for k,v in pairs(ChatData)do
-- 			if #v > 0 then
-- 				for i = 1 ,#v do
-- 					if v[i].status == 1 then
-- 						NetworkService.Send(5005,{nil,{{v[i].id,2}}})--已读取加好友通知
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
end
function View:Update()
    self:RefTime()
end
function View:RefTime( ... )
    if (Time.now() - FriendModule.RefTime()) > 30 then
        if FriendModule.RefTime() == 0 then
            NetworkService.Send(5011)
        else
            NetworkService.Send(5037,{nil,3});
            NetworkService.Send(5037,{nil,1});
        end
    	FriendModule.RefTime(Time.now())
    end
end
function View:listEvent()
	return {
		"PLAYER_FIGHT_INFO_CHANGE",
		"Chat_INFO_CHANGE",
		"Mail_Delete_Succeed",
		"PrivateChatData_CHANGE",
		"Friend_INFO_CHANGE",
		"PlayerFinOnlineChange",
		"SystemMessageList_Change",
	}
end

function View:onEvent(event,data)
	if event == "PLAYER_FIGHT_INFO_CHANGE" then
		if playerModule.GetFightData(data) and self.SNArr[data] then
			self.SNArr[data].combat[UnityEngine.UI.Text].text = "<color=#FEBA00>"..tostring(math.ceil(playerModule.GetFightData(data).capacity)).."</color>"
			self.SNArr[data] = nil
		end
	elseif event == "Chat_INFO_CHANGE" then
		--local ChatData = ChatManager.GetManager(data.channel)
		--ERROR_LOG(sprinttb(ChatData))
		if data.channel == 6 or data.channel == 8 then
			self.init = false
			self:RefDataCount()
		end
		--self.nguiDragIconScript:ItemRef()
		-- for k,v in pairs()do

		-- end
	elseif event == "PrivateChatData_CHANGE" then
		self.nguiDragIconScript:ItemRef()
	elseif event == "Mail_Delete_Succeed" then
		self.init = false
		self:RefDataCount()
	elseif event == "Friend_INFO_CHANGE" or event == "PlayerFinOnlineChange" then
		self.nguiDragIconScript:ItemRef()
	elseif event == "SystemMessageList_Change" then
		self:SystemMessage()
	end
end
return View