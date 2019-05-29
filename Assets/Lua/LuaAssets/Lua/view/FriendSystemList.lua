local ChatManager = require 'module.ChatModule'
local UserDefault = require "utils.UserDefault";
local System_Set_data=UserDefault.Load("System_Set_data");
local View = {};

function View:getData(data)
	if data then
		if type(data) == "function" then
			data = data()
		end
	end
	return data
end

function View:Start(data)
	self.viewRoot = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.viewRoot.root
	data = self:getData(data)
	self.first = true
	self.index = data and data.idx or 2
	self.index = self.savedValues.index or self.index
	self.savedValues.index = self.index
	--self.viewName = {"消  息","好  友","邮  件","添加好友","黑名单","奖  励"}
	self.viewName ={SGK.Localize:getInstance():getValue("biaoti_xiaoxi_01"),
					SGK.Localize:getInstance():getValue("biaoti_haoyou_01"),
					SGK.Localize:getInstance():getValue("biaoti_youjian_01"),
					SGK.Localize:getInstance():getValue("biaoti_tianjiahaoyou_01"),
					SGK.Localize:getInstance():getValue("biaoti_heimingdan_01"),
					SGK.Localize:getInstance():getValue("biaoti_jiangli_01")}
	self.viewFrameArr = {}
	self.viewDatas = data and data.viewDatas or {}
	self.viewDatas = self.savedValues.viewDatas or self.viewDatas
	self.savedValues.viewDatas = self.viewDatas
	self:loadFrameview(self.index)
	self.view.ToggleGroup[self.index][UnityEngine.UI.Toggle].isOn = true
	for i = 1,#self.view.ToggleGroup do
	if self.index == 3 or self.index == 6 then
		if i == 3 or i == 6 then
			self.view.ToggleGroup[i]:SetActive(true)
		else
			self.view.ToggleGroup[i]:SetActive(false)
		end
	else
		if i == 3 or i == 6 then
			self.view.ToggleGroup[i]:SetActive(false)
		else
			self.view.ToggleGroup[i]:SetActive(true)
		end
	end
		self.view.ToggleGroup[i][CS.UGUIClickEventListener].onClick = function ( ... )
			self:loadFrameview(i)
		end
	end
	-- self.view.exitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
	-- 	--DispatchEvent("KEYDOWN_ESCAPE")
	-- 	DialogStack.Pop()
	-- end
	self.viewRoot.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		--DispatchEvent("KEYDOWN_ESCAPE")
		DialogStack.Pop()
	end
	self.view.ToggleGroup[1].Image:SetActive(self:RefDataCount())
	local init_obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform)
end

function View:loadFrameview(idx)
	self.viewFrameArr[self.index] = DialogStack.GetPref_list(self.viewFrameArr[self.index])
	if self.viewFrameArr[self.index] and self.index ~= idx then
		--self.viewFrameArr[self.index]:SetActive(false)
		self.viewDatas[self.index] = nil
		self.savedValues.viewDatas = self.viewDatas
		UnityEngine.GameObject.Destroy(self.viewFrameArr[self.index])
		self.viewFrameArr[self.index] = nil
	end
	self.view.select.transform.position = self.view.ToggleGroup[idx].transform.position
	self.index = idx
	self.savedValues.index = self.index
	--self.view.title[UnityEngine.UI.Text].text = self.viewName[self.index]
	if self.viewFrameArr[self.index] and self.viewFrameArr[self.index].gameObject then
		self.viewFrameArr[self.index]:SetActive(true)
	else
		if self.index == 1 then
			self.viewFrameArr[self.index] = "FriendMessage"
			DialogStack.PushPref("FriendMessage",self.viewDatas[self.index],self.view.childRoot.gameObject)
		elseif self.index == 2 then
			self.viewFrameArr[self.index] = "FriendList"
			DialogStack.PushPref("FriendList",self.viewDatas[self.index],self.view.childRoot.gameObject)
		elseif self.index == 3 then
			self.viewFrameArr[self.index] = "FriendMail"
			DialogStack.PushPref("FriendMail",self.viewDatas[self.index],self.view.childRoot.gameObject)
		elseif self.index == 4 then
			self.viewFrameArr[self.index] = "FriendFind"
			DialogStack.PushPref("FriendFind",self.viewDatas[self.index],self.view.childRoot.gameObject)
		elseif self.index == 5 then
			self.viewFrameArr[self.index] = "NpcListFrame"
			DialogStack.PushPref("NpcListFrame",self.viewDatas[self.index],self.view.childRoot.gameObject)
		elseif self.index == 6 then
			self.viewFrameArr[self.index] = "BoxOpenFrame"
			DialogStack.PushPref("BoxOpenFrame",self.viewDatas[self.index],self.view.childRoot.gameObject)
		else
			ERROR_LOG("索引错误_> ",self.index)
		end
	end
end
function View:RefDataCount()
	self.listData = {}
	-- local ChatData = ChatManager.GetManager(6)--私聊内容
	-- if ChatData then
	-- 	for k,v in pairs(ChatData)do
	-- 		if #v > 0 then
	-- 			local tempData = v[#v]
	-- 			local count = ChatManager.GetPrivateChatData(tempData.fromid)
	-- 			if count and count > 0 then
	-- 				return true
	-- 			end
	-- 		end
	-- 	end
	-- end
	-- --ERROR_LOG(sprinttb(ChatData))
	-- ChatData = ChatManager.GetManager(8)--好友通知
	-- if ChatData then
	-- 	for k,v in pairs(ChatData)do
	-- 		if #v > 0 and v[1].status == 1 then
	-- 			return true
	-- 		end
	-- 	end
	-- end
	-- ChatData = ChatManager.GetSystemMessageList()--系统离线消息
	-- for k,v in pairs(ChatData) do
	-- 	for i = 1,#v do
	-- 		if v[i][6] and v[i][6] == 0 then
	-- 			return true
	-- 		end
	-- 	end
	-- end
	return module.RedDotModule.GetStatus(module.RedDotModule.Type.FriendChat.Chat)
end
function View:onEvent(event,data)
	if event == "Chat_INFO_CHANGE" or event == "PrivateChatData_CHANGE" or event == "Mail_Delete_Succeed" or event == "SystemMessageListRedDotChange" then
		self.view.ToggleGroup[1].Image:SetActive(self:RefDataCount())
		DispatchEvent("Friend_Chat_Change")
	elseif event == "FriendSystemlist_indexChange" then
		if self.index ~= data.i then
			self.viewDatas[data.i] = {pid = data.pid,name = data.name}
			self.savedValues.viewDatas = self.viewDatas
			self:loadFrameview(data.i)
			self.view.ToggleGroup[data.i][UnityEngine.UI.Toggle].isOn = true
		end
	elseif event == "FriendSystemlist_viewDatasChange" then
		if self.index == data.i then
			self.viewDatas[data.i] = {pid = data.pid,name = data.name}
			self.savedValues.viewDatas = self.viewDatas
		end
	end
end
function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end
function View:OnDestroy( ... )
end
function View:listEvent()
	return {
		"PLAYER_FIGHT_INFO_CHANGE",
		"Chat_INFO_CHANGE",
		"Mail_Delete_Succeed",
		"PrivateChatData_CHANGE",
		"FriendSystemlist_indexChange",
		"FriendSystemlist_viewDatasChange",
		"SystemMessageListRedDotChange",
	}
end
return View