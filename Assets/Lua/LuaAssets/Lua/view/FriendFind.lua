local FriendModule = require 'module.FriendModule'
local NetworkService = require "utils.NetworkService";
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local playerModule = require "module.playerModule"
local unionModule = require "module.unionModule"
local ChatManager = require 'module.ChatModule'
local Time = require "module.Time"
local TipCfg = require "config.TipConfig"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	NetworkService.Send(5025)--查询赠送记录
	self.AddAllFriend = false
	self.FriendData = {}
	self.FriendDataAll = {}
	self.AnimFlag = true
	self.AnimList = {}
	self:GetAnimCount()
	self.addData = {}
	self.SNArr = {}
	self.init = true
	self.FriendDataAll = FriendModule.GetRecommendFriends()
	self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
	self.nguiDragIconScript.RefreshIconCallback = (function (go,idx)
		self:FreshScrollView(go,idx)
	end)
	if #self.FriendData == 0 then
		self.view.ScrollViewMask:SetActive(false)
		NetworkService.Send(5021)--推荐好友列表
	else
		self:addDataRef()
		self.FriendData = self:filtrate()
		self.view.tips:SetActive(#self.FriendData==0)
		self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
	end
	--self:initClick()
end

function View:addDataRef(bool)
	for i = 1,#self.FriendDataAll do
		PlayerInfoHelper.GetPlayerAddData(self.FriendDataAll[i].pid,99,function (addData)
			self.addData[self.FriendDataAll[i].pid] = addData
			if bool and i == #self.FriendDataAll then
				self:fresh()
				self:initClick()		
			end
		end)
	end
end

function View:initClick()
	self.view.addAllBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if #FriendModule.GetManager() < module.FriendModule.GetFriendConf().friends_limit then
			if #self.FriendData > 0 then
				NetworkService.Send(5013,{nil,1,self.FriendData[1].pid})--添加好友
				self.AddAllFriend = true
			end
		else
			showDlgError(nil,TipCfg.GetAssistDescConfig(61023).info)--"好友数量已达上限，无法继续添加")
		end
	end
	self.RefTime = 0
	self.view.RefBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if Time.now() - self.RefTime > 10 then
			self.RefTime = Time.now()
			NetworkService.Send(5021,{nil})--推荐好友列表
			self.AnimFlag = true
			self.view.ScrollViewMask:SetActive(true)
		else
			showDlgError(nil,10 - math.floor(Time.now() - self.RefTime).."秒后可刷新")
		end
	end
	self.view.addBtn[CS.UGUIClickEventListener].onClick = function( ... )
		--加好友
		local desc = self.view.InputField[UnityEngine.UI.InputField].text
		if desc ~= "" then
			if desc ~= module.playerModule.Get().name then
				if FriendModule.FindName(1,desc) then
					showDlgError(nil,"他已经是您的好友")
				elseif #FriendModule.GetManager() >= module.FriendModule.GetFriendConf().friends_limit then
					showDlgError(nil,TipCfg.GetAssistDescConfig(61023).info)--"好友已达上限")
				else
					NetworkService.Send(5013,{nil,1,0,desc})--添加好友
				end
			else
				showDlgError(nil,"不能添加自己为好友")
			end
		else
			showDlgError(nil,"名称不能空",nil,nil,11)
		end
	end
	for i = 1,3 do
		self.view.Group[i].Background[CS.UGUIClickEventListener].onClick = function ( ... )
			if i == 1 then
				self.view.Group[i][UI.Toggle].isOn = not self.view.Group[i][UI.Toggle].isOn
			elseif i == 2 then --and self.view.Group[3][UI.Toggle].isOn then
				--self.view.Group[i][UI.Toggle].isOn = not self.view.Group[i][UI.Toggle].isOn
				self.view.Group[3][UI.Toggle].isOn = not self.view.Group[3][UI.Toggle].isOn
				self.view.Group[2][UI.Toggle].isOn = not self.view.Group[2][UI.Toggle].isOn
			elseif i == 3 then--and self.view.Group[2][UI.Toggle].isOn then
				--self.view.Group[i][UI.Toggle].isOn = not self.view.Group[i][UI.Toggle].isOn
				self.view.Group[2][UI.Toggle].isOn = not self.view.Group[2][UI.Toggle].isOn
				self.view.Group[3][UI.Toggle].isOn = not self.view.Group[3][UI.Toggle].isOn
			end
			self.FriendData = self:filtrate()
			self.view.tips:SetActive(#self.FriendData==0)
			self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
		end
		self.view.Group[i].Background[CS.UGUIClickEventListener].disableTween = true
	end
end

function View:FreshScrollView(go,idx)
	local obj = CS.SGK.UIReference.Setup(go)
	local tempData = self.FriendData[idx + 1]
	obj.yBtn[CS.UGUIClickEventListener].onClick = (function ( ... )
		NetworkService.Send(5013,{nil,1,tempData.pid})--添加好友
	end)
	obj.name[UnityEngine.UI.Text].text = tempData.name..""
	obj.online:SetActive(tempData.online == 1)
	local unionName = unionModule.GetPlayerUnioInfo(tempData.pid).unionName
	if unionName then
		obj.guild[UnityEngine.UI.Text].text = unionName
	else
		unionModule.queryPlayerUnioInfo(tempData.pid,(function ( ... )
			unionName = unionModule.GetPlayerUnioInfo(tempData.pid).unionName or "无"
			if obj.guild then
				obj.guild[UnityEngine.UI.Text].text = (unionName or "无")
			end
		end))
	end
	if playerModule.GetFightData(tempData.pid) then
		obj.combat[UnityEngine.UI.Text].text =tostring(math.ceil(playerModule.GetFightData(tempData.pid).capacity))
	else
		self.SNArr[tempData.pid] = obj
	end
	local PLayerIcon = nil
	-- if obj.hero.transform.childCount == 0 then
	-- 	PLayerIcon = IconFrameHelper.Hero({},obj.hero)
		PLayerIcon = IconFrameHelper.Create(obj.hero,{pid = tempData.pid,customCfg = {HeadFrame = self.addData[tempData.pid].HeadFrame,sex = self.addData[tempData.pid].Sex}})
	-- else
	-- 	local objClone = obj.hero.transform:GetChild(0)
	-- 	PLayerIcon = SGK.UIReference.Setup(objClone)
	-- end
		-- PlayerInfoHelper.GetPlayerAddData(tempData.pid,99,function (addData)
		-- 	IconFrameHelper.UpdateHero({pid = tempData.pid,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
		-- end,true)
		obj.hero[CS.UGUIClickEventListener].onClick = function ( ... )
			local list = nil
			if ChatManager.GetManager(6) then
				list = ChatManager.GetManager(6)[tempData.pid]
			end
			if tempData.online == 1 then
	 			utils.SGKTools.FriendTipsNew({self.view,obj.status},tempData.pid,{2,3,4,8},list)
	 		else
	 			utils.SGKTools.FriendTipsNew({self.view,obj.status},tempData.pid,{2,4,8},list)
	 		end
		 	-- PlayerInfoHelper.GetPlayerAddData(tempData.pid,99,function (addData)
	 		-- 	IconFrameHelper.UpdateHero({pid = tempData.pid,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
	 		-- end,true)
		end
	--obj.gameObject:SetActive(true)
	if idx < self.AnimCount then
		self.AnimList[idx] = true
	end
	if self.AnimList[idx] and self.AnimFlag then
		self:ItemAnim(obj,idx)
	else
		obj:SetActive(true)
	end
end

function View:GetAnimCount()
	local height = self.view.ScrollView[UnityEngine.RectTransform].rect.size.y
	self.AnimCount = math.ceil(height/145)
end

function View:ItemAnim(view,idx)
	view.transform:DOLocalMoveX(750,0.05):OnComplete(function ()
		--print(view[UnityEngine.RectTransform].anchoredPosition)
	    view:SetActive(true);
	    view.transform:DOLocalMoveX(20,0.4):OnComplete(function ()
	    	self.AnimList[idx] = false
	    	if idx+1 >= self.AnimCount or idx+1 == self.nguiDragIconScript.DataCount then
				self.AnimFlag = false
				--self.nguiDragIconScript:ItemRef()
				self.view.ScrollViewMask:SetActive(false)
			end
	    end)
	end):SetDelay(idx*0.05)
end

function View:fresh(bool)
	self.FriendData = self:filtrate()
	self.view.tips:SetActive(#self.FriendData==0)
	self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
	self.AnimFlag = true
	self.view.ScrollViewMask:SetActive(true)
	if #self.FriendData==0 then
		self.view.ScrollViewMask:SetActive(false)
	end
end

function View:onEvent(event,data,_data)
	if event == "Friend_Recommend_Ref" then
		self.FriendDataAll = data.data
		self:addDataRef(true)
	elseif event == "Friend_ADD_CHANGE" then
		if self.AddAllFriend then
			table.remove(self.FriendData,1)
			if #self.FriendData > 0 then
				if #FriendModule.GetManager() < module.FriendModule.GetFriendConf().friends_limit then
					NetworkService.Send(5013,{nil,1,self.FriendData[1].pid})--添加好友
				else
					self.AddAllFriend = false
					NetworkService.Send(5021,{nil})--推荐好友列表
					showDlgError(nil,TipCfg.GetAssistDescConfig(61023).info)--"好友数量已达上限，无法继续添加")
				end
			else
				self.AddAllFriend = false
				NetworkService.Send(5021,{nil})--推荐好友列表
			end
		else
			self.AddAllFriend = false
			NetworkService.Send(5021,{nil})--推荐好友列表
		end
		--NetworkService.Send(5021)--推荐好友列表
	elseif event == "PLAYER_FIGHT_INFO_CHANGE" then
		if playerModule.GetFightData(data) and self.SNArr[data] then
			self.SNArr[data].combat[UnityEngine.UI.Text].text =tostring(math.ceil(playerModule.GetFightData(data).capacity))
			self.SNArr[data] = nil
		end
	elseif event == "server_respond_17082" then
		-- ERROR_LOG("sprinttb(data)",sprinttb(_data))
		-- if not self.addData then
		-- 	self.addData = {}
		-- 	self.addData = {}
	end
end
function View:filtrate(type)
	local list = {}
	--ERROR_LOG(sprinttb(self.FriendDataAll))
	for i = 1,#self.FriendDataAll do
		local a,b,c = false,false,false
		local sex = 0
		sex = self.addData[self.FriendDataAll[i].pid].Sex
		-- PlayerInfoHelper.GetPlayerAddData(self.FriendDataAll[i].pid,99,function (addData)
		-- 	sex = addData.Sex
		-- end)
		if not self.view.Group[1][UI.Toggle].isOn or (self.FriendDataAll[i].level <= playerModule.Get().level+10 and self.FriendDataAll[i].level >= playerModule.Get().level-10) then
			a = true
		end
		if not self.view.Group[2][UI.Toggle].isOn or sex == 0 then
			b = true
		end
		if not self.view.Group[3][UI.Toggle].isOn or sex == 1 then
			c = true
		end
		if a and b and c then
			list[#list+1] = self.FriendDataAll[i]
		end
	end
	return list
end
function View:listEvent()
	return {
		"Friend_Recommend_Ref",
		"Friend_ADD_CHANGE",
		"PLAYER_FIGHT_INFO_CHANGE",
		"server_respond_17082",
	}
end
return View