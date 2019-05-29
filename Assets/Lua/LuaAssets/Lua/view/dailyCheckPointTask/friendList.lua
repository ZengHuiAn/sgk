local FriendModule = require 'module.FriendModule'
local UnionModule = require "module.unionModule"
local PlayerModule = require "module.playerModule"
local ChatManager = require 'module.ChatModule'
local QuestModule = require "module.QuestModule"
local CooperationQuestModule = require "module.CooperationQuestModule"

local UserDefault = require "utils.UserDefault";

local Task_ForHelp_Call = UserDefault.Load("Task_ForHelp_Call",true);
local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view.Content

	self.root.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue("lilianbiji_biaoti3")
	

	CS.UGUIClickEventListener.Get(self.root.view.Close.gameObject).onClick = function (obj) 
		DialogStack.Pop()
	end

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function (obj) 
		DialogStack.Pop()
	end

	self:InitView(data)	
end

local toggleList = {"全部","好友","公会"}
local relationType = {  
	FRIEND =1,
	UNION = 2,}

local chatType = 1
local chatCD = true
local CD = 5*60
function View:InitView(data)
	self:InToggleGroup()

	local uninInfo = UnionModule.Manage:GetSelfUnion()
	if uninInfo and next(uninInfo)~=nil then
		self.unionName = uninInfo.unionName
	end
	self.Pid = module.playerModule.GetSelfID();
	
	self.unionOnlineMembers,self.unionMembers = self:GetUnionMemberList()
	self.friendOnLineList,self.friendList = self:GetFriendList()

	self:updateRelationList()

	self.quest_id = data and data[1]
	self.share_id = data and data[2]

	local shareCfg = QuestModule.GetCfg(self.share_id)
	if shareCfg then
		self.view.top.tip[UI.Text].text = shareCfg and shareCfg.desc or ""
	end
	
	self.view.bottom.btn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("lilianbiji_tip5")

	Task_ForHelp_Call.lastCallTime = Task_ForHelp_Call.lastCallTime or ChatManager.GetChatMessageTime(chatType)
	self.view.bottom.btn[CS.UGUIClickEventListener].interactable = math.floor(module.Time.now() - Task_ForHelp_Call.lastCallTime) > CD

	chatCD = math.floor(module.Time.now() - Task_ForHelp_Call.lastCallTime) <= CD
	self.view.bottom.btn.timer:SetActive(chatCD)
	
	CS.UGUIClickEventListener.Get(self.view.bottom.btn.gameObject).onClick = function (obj) 
		local cd =  math.floor(module.Time.now()  - ChatManager.GetChatMessageTime(chatType))
		if cd < 10 then
			showDlgError(nil,"您说话太快，请在"..10-cd.."秒后发送")
			return
		end

		self:SetCDStatus(true)
		local quest_cfg = QuestModule.GetCfg(self.share_id)
		if quest_cfg then
			CooperationQuestModule.Share(0,self.quest_id)
			ChatManager.ChatMessageRequest(chatType,"3"..quest_cfg.name.."[".. quest_cfg.depend.level.."级以上]".."\n"..SGK.Localize:getInstance():getValue("lilianbiji_tip10").."|"..self.quest_id)
		end
	end
end

function View:SetCDStatus(status)
	if status then
		chatCD = true
		Task_ForHelp_Call.lastCallTime = module.Time.now()
		self.view.bottom.btn[CS.UGUIClickEventListener].interactable = false
		self.view.bottom.btn.timer:SetActive(true)
	else
		chatCD = false
		self.view.bottom.btn[CS.UGUIClickEventListener].interactable = true
		self.view.bottom.btn.timer:SetActive(false)
	end
end

function View:GetSelectList()
	local list = {}
	if self.selectType == 1 then
		local _addedTab = {}
		for i=1,#self.friendOnLineList do
			table.insert(list,self.friendOnLineList[i])
			_addedTab[self.friendOnLineList[i].pid] = true
		end
		for i=1,#self.unionOnlineMembers do
			if not _addedTab[self.unionOnlineMembers[i].pid] then
				table.insert(list,self.unionOnlineMembers[i])
			end
		end
	elseif self.selectType == 2 then
		for i=1,#self.friendOnLineList do
			table.insert(list,self.friendOnLineList[i])
		end
	elseif self.selectType == 3 then
		for i=1,#self.unionOnlineMembers do
			table.insert(list,self.unionOnlineMembers[i])
		end
	end
	return list
end

function View:GetUnionMemberList()
    local memberTab = UnionModule.Manage:GetMember()

    local onlineTab = {}
    local _list = {}
    for k,v in pairs(memberTab) do
        if v.online and v.pid ~= self.Pid then--非自己的在线公话成员
        	local _tab = {pid= v.id,name= v.name,type = relationType.UNION}
            table.insert(onlineTab,_tab)
		end
		table.insert(_list,v)
    end
    return onlineTab,_list
end
function View:GetFriendList()
	local friendList = FriendModule.GetManager() or {}

	local onlineTab = {}
	local allFriends = {}
	for i=1,#friendList do
		--在线的双向好友
		if friendList[i].online == 1 then--and friendList[i].rtype ==1 then
			local _tab = {pid = friendList[i].pid,name = friendList[i].name,type = relationType.FRIEND}
			table.insert(onlineTab,_tab)
		end
		table.insert(allFriends,friendList[i])
	end
	return onlineTab,allFriends
end

function View:InToggleGroup()
	self.selectType = 1
	for i=1,self.view.bottom.fifter.transform.childCount do
		self.view.bottom.fifter[i].Label[UI.Text].text = toggleList[i]
		self.view.bottom.fifter[i][UI.Toggle].isOn = i == self.selectType
		CS.UGUIClickEventListener.Get(self.view.bottom.fifter[i].gameObject).onClick = function (obj) 
			if self.selectType ~= i then
				self.selectType = i
				self:updateRelationList()
			end
		end
	end
end

local friendItem = {}
function View:updateRelationList()
	local list = self:GetSelectList()
	self.SNArr = {}
	self.UIDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
	self.UIDragIconScript.RefreshIconCallback = function (obj, idx)
		local item = CS.SGK.UIReference.Setup(obj.gameObject)

		local cfg = list[idx+1]

		local _pid = cfg.pid

		self.SNArr[_pid] = item

		utils.IconFrameHelper.Create(item.IconFrame, {pid = _pid})

	 	item.name[UI.Text].text = cfg.name
	 	
	 	if cfg.type == relationType.UNION then
	 		item.union.Text[UI.Text].text = self.unionName
	 	else
	 		UnionModule.queryPlayerUnioInfo(_pid,(function ( ... )
				local unionName = UnionModule.GetPlayerUnioInfo(_pid).unionName or "<color=#FEBA00>无</color>"
				item.union.Text[UI.Text].text = unionName
			end))
	 	end

	 	if PlayerModule.GetFightData(_pid) then
			item.capacity.Text[UI.Text].text = tostring(math.ceil(PlayerModule.GetFightData(_pid).capacity))
		end
		
		--QuestModule.GetOtherQuest(_pid,self.quest.id)
		-- CooperationQuestModule.CheckPlayer(_pid)

	 	local questStatus = true
	 	item.mark:SetActive(false)
	 	CooperationQuestModule.Get(_pid,nil,nil,function ()
	 		local cooperaInfo = CooperationQuestModule.Get(_pid)
	 		if cooperaInfo and cooperaInfo[2] and next(cooperaInfo[2]) then
	 			for k,v in pairs(cooperaInfo[2]) do
	 				if v.status == 1 then
	 					item.mark:SetActive(true)
	 				end
	 				questStatus = false
	 			end
	 		end
	 		-- ERROR_LOG(sprinttb(cooperaInfo))
	 	end)

	 	item.btn[CS.UGUIClickEventListener].interactable = questStatus
		CS.UGUIClickEventListener.Get(item.btn.gameObject).onClick = function (obj) 
			-- ERROR_LOG("邀请好友")
			item.btn[CS.UGUIClickEventListener].interactable = false
			CooperationQuestModule.Share(_pid,self.quest_id)
			local _name = module.playerModule.IsDataExist(_pid).name

			local quest_cfg = QuestModule.GetCfg(self.share_id)
			if quest_cfg then
				local desc = SGK.Localize:getInstance():getValue("lilianbiji_tip10")..quest_cfg.desc.."<color=#3aa400>[-3#"..SGK.Localize:getInstance():getValue("lilianbiji_tip11").."]</color>"
				utils.SGKTools.FriendChat(_pid,_name,desc)
			end	
		end

		obj:SetActive(true)
	end

	self.UIDragIconScript.DataCount = #list

	self.view.noFriendTip:SetActive(next(list)==nil)
	if next(list)==nil then
		local tipStr = ""
		if self.selectType == 1 then
			tipStr = SGK.Localize:getInstance():getValue(#self.friendList+#self.unionMembers>0 and "lilianbiji_tip7" or "lilianbiji_tip6") 
		elseif self.selectType ==2 then
			tipStr = SGK.Localize:getInstance():getValue(#self.friendList>0 and "lilianbiji_tip7" or "lilianbiji_tip6") 
		elseif self.selectType == 3 then
			tipStr = SGK.Localize:getInstance():getValue(self.unionName and "lilianbiji_tip9" or "lilianbiji_tip8") 	
		end
		self.view.noFriendTip.btn:SetActive(self.selectType ~= 3 or not self.unionName)
		self.view.noFriendTip.Text[UI.Text].text = tipStr
		self.view.noFriendTip.btn.Text[UI.Text].text = SGK.Localize:getInstance():getValue(self.selectType == 3 and "search_union" or "make_friends") 
	end
	CS.UGUIClickEventListener.Get(self.view.noFriendTip.btn.gameObject).onClick = function (obj) 
		if self.selectType == 3 then
			DialogStack.Push("newUnion/newUnionList")
		else
			DialogStack.Push("FriendSystemList", {idx = 4})
		end
	end
end

function View:Update( ... )
	if chatType and chatCD and Task_ForHelp_Call and Task_ForHelp_Call.lastCallTime then
		local cd = math.floor(module.Time.now()  - Task_ForHelp_Call.lastCallTime)
		if cd <CD then
			self.view.bottom.btn.timer[UI.Text].text = os.date("%M : %S",math.floor(CD -cd))
		else
			self:SetCDStatus()
		end
	end
end

function View:OnDestroy( ... )
    UserDefault.Save();
end

function View:listEvent()
	return {
		"PLAYER_FIGHT_INFO_CHANGE",
		"Friend_INFO_CHANGE",
	}
end


function View:onEvent(event,data)
	if event == "PLAYER_FIGHT_INFO_CHANGE" then--查寻玩家战力返回
		if PlayerModule.GetFightData(data) and self.SNArr[data] then
			self.SNArr[data].capacity.Text[UI.Text].text = tostring(math.ceil(PlayerModule.GetFightData(data).capacity))
		end
	elseif event == "Friend_INFO_CHANGE" then
		self.friendOnLineList,self.friendList = self:GetFriendList()
		self:updateRelationList()
	end
end
return View