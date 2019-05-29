local ItemHelper = require "utils.ItemHelper"
local MailModule = require 'module.MailModule'
local ChatManager = require 'module.ChatModule'
local NetworkService = require "utils.NetworkService";
local openLevel = require "config.openLevel"
local Time = require "module.Time"
local commonConfig = require "config.commonConfig"

local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject).UGUIResourceBar
	self.isMapScene = false
	MailModule.GetManager()--获取邮件中的玩家信息
	self.IsMain = true--true是主场景
	-- self.MainRoot = UnityEngine.GameObject.FindWithTag("ui_reference_root")
	--self:CurrencyRef()
	self.Function = nil
	self.break_Function = false
	self.ChatData = {}--聊天数据
	self.IsApply = false--是否邀请
	self.ChatRef_time = 0--聊天刷新间隔时间
	--self.IsExit = false--是否正在退出
	if data and data.active ~= nil then
		self.view:SetActive(data.active)
	end

	if self.view.BottomBar then
		self.view.BottomBar.chat[CS.UGUIClickEventListener].onClick = (function ( ... )
			if #DialogStack.GetStack() == 0 or DialogStack.GetStack()[#DialogStack.GetStack()].name ~= "NewChatFrame" then
				local _guide = UnityEngine.GameObject.FindWithTag("GuideRoot")
				if not _guide then
					DialogStack.PushPref('NewChatFrame', nil, self.view)
				end
			end
		end)
		for i = 1 ,2 do
			self.view.BottomBar.chat[i][CS.UGUIClickEventListener].onClick = function ( ... )
			--聊天
				if #DialogStack.GetStack() == 0 or DialogStack.GetStack()[#DialogStack.GetStack()].name ~= "NewChatFrame" then
					local _guide = UnityEngine.GameObject.FindWithTag("GuideRoot")
					if not _guide then
						DialogStack.PushPref('NewChatFrame', nil, self.view)
					end
				end
			end
		end
		CS.UGUIClickEventListener.Get(self.view.BottomBar.back.gameObject).onClick = function()
			self:BackBtn()
		end
	end
	self.itemid = data and data.itemid or self:getItemList()
	self:ChatRef()
	self:CurrencyRef();

	if data and data.Type == 1 then
		if self.view.BottomBar then
			self.view.BottomBar.back:SetActive(false)
		end
		self.view.TopBar:SetActive(false);
	end
end

function View:getItemList()
    local _list = {}
    for i = 500, 503 do
        local _cfg = commonConfig.Get(i)
        if _cfg then
            table.insert(_list, _cfg.para1)
        end
    end
    return _list
end

function View:IsLastView()
	return (SceneStack.Count() <= 1 and  #DialogStack.GetStack() == 0 and #DialogStack.GetPref_stact() == 0);
end

function View:changeMapScene(flag)
	self.isMapScene = flag
end

local last_escape_press_time = -100;
function View:BackBtn()
	--ERROR_LOG("BackBtn")
	-- if self:IsLastView() then
    --     if CS.UnityEngine.Application.isEditor then
    -- 		if UnityEngine.Time.realtimeSinceStartup - last_escape_press_time < 1.0 then
    -- 			GetHelpFrame(function (...)
    -- 				last_escape_press_time = -100;
    -- 			end)
    -- 		else
    -- 			last_escape_press_time = UnityEngine.Time.realtimeSinceStartup;
    -- 		end
    --     end
	-- 	return;
	-- end

	--[[
	self.view.BottomBar[UnityEngine.UI.HorizontalLayoutGroup].enabled = true
	--self.view.BottomBar.back.gameObject:SetActive(true)
	self.view.BottomBar.chat.gameObject:SetActive(true)
	--]]

	if self.Function and not self.break_Function then
		self.Function()
		self.Function = nil
		return
	else
		self.break_Function = false
		if #DialogStack.GetStack() > 0 or #DialogStack.GetPref_stact() > 0 then
			if UnityEngine.SceneManagement.SceneManager.GetActiveScene().name == "newSelectMapUp" then
				local stack = DialogStack.Top()
				if stack and stack.name == "newSelectMap/selectMap" then
					--DialogStack.Pop()
					SceneStack.Pop()
				else
					DialogStack.Pop()
				end
			else
				DialogStack.Pop()
			end
		elseif SceneStack.Count() > 1 then
			if #DialogStack.GetPref_stact() > 0 then--如果弹窗存在先关闭弹窗
				DialogStack.Pop()
			else
				if UnityEngine.SceneManagement.SceneManager.GetActiveScene().name == "newSelectMapUp" then
					DialogStack.Push("newSelectMap/selectMap")
					--SceneStack.savedValues.OpenSelectMap = true
				else
					SceneStack.Pop()
				end
			end
		elseif SceneStack.MapId() >= 501 and SceneStack.MapId() <= 510 then
			SceneStack.EnterMap(1)
		end
	end
	DispatchEvent("Main_bg_IsActive",{active = true})
end

function View:CurrencyRef(idx,id)
	if idx and id then
		self.itemid[idx] = id
	end
	
	if not self.RefTopResources then
		self.RefTopResources = true
		self.view.transform:DOScale(Vector3.one,0.1):OnComplete(function()
			self.RefTopResources = false

			for i = 1 ,#self.itemid do
				local item = ItemHelper.Get(ItemHelper.TYPE.ITEM, self.itemid[i]);
				if self.itemid[i] ==90010 then--体力特殊显示(当前值/可回复最大值)
					self.view.TopBar[i].num[UnityEngine.UI.Text].text = string.format("%s%s</color>/150",item.count>150 and "<color=#FF0000FF>" or "<color=#FFFFFFFF>",tostring(item.count));
				elseif self.itemid[i] ==90118 then--特殊显示(当前值/可回复最大值)
					self.view.TopBar[i].num[UnityEngine.UI.Text].text = string.format("%s%s</color>/100",item.count>100 and "<color=#FF0000FF>" or "<color=#FFFFFFFF>",tostring(item.count));
				else
					self.view.TopBar[i].num[UnityEngine.UI.Text].text = tostring(item.count);
				end
		 		
				self.view.TopBar[i].icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. item.icon.."_small",function ( ... )
					self.view.TopBar[i].icon[UI.Image].enabled = true
				end);
				self.view.TopBar[i].icon[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(40,40)
				self.view.TopBar[i].icon[UI.Image].raycastTarget = true

				--点击显示 Item name
				local off_y = self.view.TopBar[i].icon[UnityEngine.RectTransform].sizeDelta.y
				utils.SGKTools.ShowItemNameTip(self.view.TopBar[i].icon,item.name,0,off_y)

				CS.UGUIClickEventListener.Get(self.view.TopBar[i].gameObject).onClick = function()
					DialogStack.PushPrefStact("ItemDetailFrame", {id = self.itemid[i],type = ItemHelper.TYPE.ITEM,InItemBag=2},UnityEngine.GameObject.FindWithTag("UGUITopRoot").gameObject)
				end
			end
		end)
	end
end

function View:ChatRef( ... )
	if not self.view.BottomBar then
		return
	end
	if self.ChatRef_time < Time.now() then
    	self.ChatRef_time = Time.now()
		local channelName = {[0] = "系统",[1] = "世界",[6] = "私聊",[3] = "公会",[7] = "队伍",[8] = "好友",[10] = "组队",[100] = "地图"}
		self.ChatData = ChatManager.GetNewChat()
		for i = 1,#self.ChatData do
			local label = self.view.BottomBar.chat[i][UnityEngine.UI.Text];
			label.text = ""
			local desc = WordFilter.check(self.ChatData[i].message)
			local applyLen =string.len(desc)
            self.applyType=string.sub(desc,0,1)
            if tonumber(self.applyType)==3  or tonumber(self.applyType)==1 or tonumber(self.applyType)==4 then
                desc = string.sub(desc,2,applyLen)
            else
                desc = desc
            end
			if self.ChatData[i].channel == 0 then
				desc = self.ChatData[i].message
			end
			local desc_list = StringSplit(desc,"\n")
            if #desc_list > 1 then
                desc = ""
                for i =1,#desc_list do
                    desc = desc..desc_list[i]
                end
            end
			local name = self.ChatData[i].fromname..":"
	        if self.ChatData[i].channel == 0 then
	            name = ""
	        end
	        label.text = label.text.."["..(channelName[self.ChatData[i].channel] or "未知").."]"..name..desc.."\n"
			self.view.BottomBar.chat[i][CS.InlineText].onClick = function (name,id)
				if id == 1 then--申请入队
					local teamInfo = module.TeamModule.GetTeamInfo();
	    			if teamInfo.group == 0 then
	    				if openLevel.GetStatus(1601) then
		 					self.IsApply = true
		 					module.TeamModule.GetPlayerTeam(self.ChatData[i].fromid,true)--查询玩家队伍信息
		 				else
			 				showDlgError(nil,"等级不足")
			 			end
		 			else
		 				showDlgError(nil,"已在队伍中")
		 			end
		 		elseif id == 2 then--申请入会
		 			if module.unionModule.Manage:GetUionId() == 0 then
		 				module.unionModule.JoinUnionByPid(self.ChatData[i].fromid)
		 			else
		 				showDlgError(nil,"您已经加入了一个公会")
		 			end
		 		elseif id == 3 then--我来协助
			 		local _pid = self.ChatData[i].fromid
		 			local quest_id = 3000015
		 			local quest = module.QuestModule.GetCfg(quest_id)
		 			if module.playerModule.Get().level >= quest.depend.level then
		 				DialogStack.PushPref("Tips/shareQuestTip",{quest,_pid},UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject)
			 		else
			 			showDlgError(nil,"等级不足")
			 		end
	 			end
			end
		end
	end
end

function View:listEvent()
	return {
	"UIRoot_refresh",
	"ITEM_INFO_CHANGE",
	"KEYDOWN_ESCAPE_BreakFun",
	"Chat_INFO_CHANGE",
	"CurrencyChatBackFunction",
	"KEYDOWN_ESCAPE",
	"CurrencyRef",
	"Team_members_Request",
	"HeroCamera_DOOrthoSize",
	}
end

function View:onEvent(event,data)
	if event == "UIRoot_refresh" then

	elseif event == "ITEM_INFO_CHANGE" then
		self:CurrencyRef()
	elseif event == "KEYDOWN_ESCAPE_BreakFun" then
		self.break_Function = data
	elseif event == "Chat_INFO_CHANGE" then
		--聊天
		self:ChatRef()
	elseif event == "CurrencyChatBackFunction" then
		self.Function = data.Function
	elseif event == "KEYDOWN_ESCAPE" then
		if self.isMapScene then
			self:BackBtn();
		end
	elseif event == "CurrencyRef" then
		--改变显示资源引起的资源变化
		if data and #data == 2 then
			self:CurrencyRef(data[1],data[2])
		else
			self.itemid = self:getItemList()
			self:CurrencyRef()
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
	elseif event == "HeroCamera_DOOrthoSize" then
		self.view.TopBar:SetActive(not data)
	end
end
return View
