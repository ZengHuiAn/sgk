local FriendModule = require 'module.FriendModule'
local playerModule = require "module.playerModule"
local NetworkService = require "utils.NetworkService"
local unionModule = require "module.unionModule"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local openLevel = require "config.openLevel"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.FriendData = FriendModule.GetManager()
	self.callback = data and data.callback;
	self.tips = data and data.tips;
	self.ClickToggleIndx = 1
	self.SNArr = {}
	self.AlreadySend = {};
	self.nguiDragIconScript = self.view.ScrollView.Viewport.Content[CS.ScrollViewContent]
	self.nguiDragIconScript.RefreshIconCallback = function (go,idx)
		print(sprinttb(self.FriendData))
		local obj = CS.SGK.UIReference.Setup(go)
		local tempData = self.now_data[idx + 1]
		if self.ClickToggleIndx == 2 then
			tempData = self.FriendData[idx + 1]
		elseif self.ClickToggleIndx == 3 then
			tempData = self.unionMember[idx + 1]
		end
		obj.name[UnityEngine.UI.Text].text = tempData.name..""
		-- if self.ClickToggleIndx == 1 then
		-- 	obj.status[UnityEngine.UI.Text].text = tempData.online == 1 and "在线" or "离线"
		-- else
		-- 	obj.status[UnityEngine.UI.Text].text = tempData.online and "在线" or "离线"
		-- end
		--obj.lv[UnityEngine.UI.Text].text = ""
		--obj.hero.lv[UnityEngine.UI.Text].text = tostring(tempData.level)
		obj.guild[UnityEngine.UI.Text].text = "公会:无"
		local unionName = unionModule.GetPlayerUnioInfo(tempData.pid).unionName
		if unionName then
			obj.guild[UnityEngine.UI.Text].text = "公会:"..unionName
		else
			unionModule.queryPlayerUnioInfo(tempData.pid,(function ( ... )
				unionName = unionModule.GetPlayerUnioInfo(tempData.pid).unionName or "无"
				obj.guild[UnityEngine.UI.Text].text = "公会:"..unionName
			end))
		end

		if playerModule.GetFightData(tempData.pid) then
			obj.combat[UnityEngine.UI.Text].text = "战力:"..tostring(math.ceil(playerModule.GetFightData(tempData.pid).capacity))
		else
			self.SNArr[tempData.pid] = obj
		end
		if self.AlreadySend[tempData.pid] == 1 then
			obj.InviteBtn.Text[UnityEngine.UI.Text].text = "已邀请"
			obj.InviteBtn[UnityEngine.UI.Button].interactable = false;
		else
			obj.InviteBtn.Text[UnityEngine.UI.Text].text = "邀请"
			obj.InviteBtn[UnityEngine.UI.Button].interactable = true;
		end
		obj.InviteBtn[CS.UGUIClickEventListener].onClick = function ( ... )
			self:Invite(false, idx)
		end

		local PLayerIcon = obj.hero.IconFrame; 
		utils.IconFrameHelper.Create(PLayerIcon, {pid = tempData.pid})	
		obj.gameObject:SetActive(true)
	end
	self:RefData()
	self.nguiDragIconScript.DataCount = #self.now_data--初始化数量
	self.view.none:SetActive(#self.now_data == 0)
	self.view.ToggleGrid[1][CS.UGUIClickEventListener].onClick = (function( ... )
		self.ClickToggleIndx = 1
		self.nguiDragIconScript.DataCount = #self.now_data--初始化数量
		self.view.none:SetActive(#self.now_data == 0)
	end)
	self.view.ToggleGrid[2][CS.UGUIClickEventListener].onClick = (function( ... )
		self.ClickToggleIndx = 2
		self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
		self.view.none:SetActive(#self.FriendData == 0)
	end)
	self.view.ToggleGrid[3][CS.UGUIClickEventListener].onClick = (function( ... )
		self.ClickToggleIndx = 3
		self.nguiDragIconScript.DataCount = #self.unionMember--初始化数量
		self.view.none:SetActive(#self.unionMember == 0)
	end)
	self.view.exitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	self.view.yBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		self:Invite(true)
		self.nguiDragIconScript:ItemRef()
	end
end

function View:Invite(isall, idx)
	if isall then
		for i,tempData in ipairs(self.now_data) do
			if self.AlreadySend[tempData.pid] ~= 1 then
				PlayerInfoHelper.GetPlayerAddData(tempData.pid, 7, function(addData)
					self.callback(tempData, addData, isall, function ()
						local obj = self.nguiDragIconScript:GetItem(i - 1);
						if obj then
							local item = CS.SGK.UIReference.Setup(obj);
							item.InviteBtn.Text[UnityEngine.UI.Text].text = "已邀请"
							item.InviteBtn[UnityEngine.UI.Button].interactable = false
						end
						self.AlreadySend[tempData.pid] = 1;
					end)
				end,true)
			end
		end
		-- if self.tips then
		-- 	showDlgError(nil, self.tips);
		-- end
	else
		local tempData = self.now_data[idx + 1]
		if self.ClickToggleIndx == 2 then
			tempData = self.FriendData[idx + 1]
		elseif self.ClickToggleIndx == 3 then
			tempData = self.unionMember[idx + 1]
		end
		if self.AlreadySend[tempData.pid] ~= 1 then
			PlayerInfoHelper.GetPlayerAddData(tempData.pid, 7, function(addData)
				self.callback(tempData, addData, isall, function ()
					local obj = self.nguiDragIconScript:GetItem(idx);
					if obj then
						local item = CS.SGK.UIReference.Setup(obj);
						item.InviteBtn.Text[UnityEngine.UI.Text].text = "已邀请"
						item.InviteBtn[UnityEngine.UI.Button].interactable = false
					end
					self.AlreadySend[tempData.pid] = 1;
				end)
				-- if self.tips then
				-- 	showDlgError(nil, self.tips);
				-- end
			end,true)
		end
	end
end

function View:RefData()
	self.now_data = {}
	self.unionMember = {}
	for k,v in pairs(module.unionModule.Manage:GetMember())do
		--ERROR_LOG(sprinttb(v))
		if v.pid ~= playerModule.GetSelfID() and v.online then
			self.unionMember[#self.unionMember+1] = v
			self.now_data[#self.now_data+1] = v
		end
	end

	local temp = self.FriendData
	self.FriendData = {}
	for i = 1,#temp do
		if temp[i].online == 1 then
			self.FriendData[#self.FriendData+1] = temp[i]
			local merge = true
			for j = 1,#self.unionMember do
				if self.unionMember[j].pid == temp[i].pid then
					merge = false
					break
				end
			end
			if merge then
				self.now_data[#self.now_data+1] = temp[i]
			end
		end
	end

	
end

function View:listEvent()
	return {
		"Friend_INFO_CHANGE",
		"PLAYER_FIGHT_INFO_CHANGE",
		"CONTAINER_UNION_MEMBER_LIST_CHANGE",
		"CONTAINER_UNION_MEMBER_INFO_CHANGE",
	}
end

function View:onEvent(event,data)
	print("onEvent", event, data)
	if event == "Friend_INFO_CHANGE" then
		self.FriendData = FriendModule.GetManager()
		self:RefData()
		if self.ClickToggleIndx == 2 then
			self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
		elseif self.ClickToggleIndx == 1 then
			self.nguiDragIconScript.DataCount = #self.now_data--初始化数量
		end
	elseif event == "PLAYER_FIGHT_INFO_CHANGE" then
		if playerModule.GetFightData(data) and self.SNArr[data] then
			self.SNArr[data].combat[UnityEngine.UI.Text].text = "战力:"..tostring(math.ceil(playerModule.GetFightData(data).capacity))
			self.SNArr[data] = nil
		end
	elseif event == "CONTAINER_UNION_MEMBER_LIST_CHANGE" or event == "CONTAINER_UNION_MEMBER_INFO_CHANGE" then
		self:RefData()
		if self.ClickToggleIndx == 1 then
			self.nguiDragIconScript.DataCount = #self.now_data--初始化数量
		elseif self.ClickToggleIndx == 3 then
			self.nguiDragIconScript.DataCount = #self.unionMember--初始化数量
		end
	end
end
return View