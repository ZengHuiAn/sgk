local FriendModule = require 'module.FriendModule'
local NetworkService = require "utils.NetworkService";
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local playerModule = require "module.playerModule"
local unionModule = require "module.unionModule"
local TipCfg = require "config.TipConfig"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.blacklist = FriendModule.GetManager(2)
	self.SNArr = {}
	self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
	self.nguiDragIconScript.RefreshIconCallback = (function (go,idx)
		local obj = CS.SGK.UIReference.Setup(go)
		local tempData = self.blacklist[idx + 1]
		obj.yBtn[CS.UGUIClickEventListener].onClick = (function ( ... )
			if tempData.stranger == 0 then--陌生人
				NetworkService.Send(5015,{nil,tempData.pid})
			else
				if #FriendModule.GetManager() < FriendModule.GetFriendConf().friends_limit then
				--你们之前是好友关系，是否需要恢复好友？
					showDlg(nil,TipCfg.GetAssistDescConfig(61013).info,function()
						NetworkService.Send(5013,{nil,1,tempData.pid})--添加好友
					end,function()
						utils.NetworkService.Send(5015,{nil,tempData.pid})--删除好友
					end,TipCfg.GetAssistDescConfig(61014).info,TipCfg.GetAssistDescConfig(61015).info)
				else
					--你们之前是好友关系，由于您当前好友数量已达上限，无法恢复为好友，请选择？
					showDlg(nil,TipCfg.GetAssistDescConfig(61018).info,function()
						NetworkService.Send(5015,{nil,tempData.pid})
					end,function()
					end,TipCfg.GetAssistDescConfig(61015).info)
				end
			end
		end)
		obj.name[UnityEngine.UI.Text].text = tempData.name..""
		obj.type[UnityEngine.UI.Text].text = tempData.stranger == 0 and "<color=#FD2D2B>陌生人</color>" or "<color=#2EFFD7>好友</color>"
		obj.online:SetActive(tempData.online == 1)
		local unionName = unionModule.GetPlayerUnioInfo(tempData.pid).unionName
		if unionName then
			obj.guild[UnityEngine.UI.Text].text =unionName
		else
			unionModule.queryPlayerUnioInfo(tempData.pid,(function ( ... )
				unionName = unionModule.GetPlayerUnioInfo(tempData.pid).unionName or "无"
				obj.guild[UnityEngine.UI.Text].text =unionName
			end))
		end
		if playerModule.GetFightData(tempData.pid) then
			obj.combat[UnityEngine.UI.Text].text =tostring(math.ceil(playerModule.GetFightData(tempData.pid).capacity))
		else
			self.SNArr[tempData.pid] = obj
		end
		-- local PLayerIcon = nil
		-- if obj.hero.transform.childCount == 0 then
		-- 	PLayerIcon = IconFrameHelper.Hero({},obj.hero)
			PLayerIcon = IconFrameHelper.Create(obj.hero,{pid = tempData.pid})
		-- else
		-- 	local objClone = obj.hero.transform:GetChild(0)
		-- 	PLayerIcon = SGK.UIReference.Setup(objClone)
		-- end
 		-- PlayerInfoHelper.GetPlayerAddData(tempData.pid,99,function (addData)
 		-- 	IconFrameHelper.UpdateHero({pid = tempData.pid,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
 		-- end)
		obj.gameObject:SetActive(true)
	end)
	self.nguiDragIconScript.DataCount = #self.blacklist--初始化数量
	self.view.tips:SetActive(#self.blacklist == 0)
	self.view.relieveBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--一键解除
		for i = 1,#self.blacklist do
			if self.blacklist[i].stranger == 0 then--陌生人
				NetworkService.Send(5015,{nil,self.blacklist[i].pid})
			else
				NetworkService.Send(5013,{nil,1,self.blacklist[i].pid})--添加好友
			end
		end
	end
end
function View:listEvent()
	return {
		"Friend_INFO_CHANGE",
		"PLAYER_FIGHT_INFO_CHANGE",
		"Black_Friend_Sort",
	}
end

function View:onEvent(event,data)
	if event == "Friend_INFO_CHANGE" then
		self.blacklist = FriendModule.GetManager(2)--2为黑名单
		self.nguiDragIconScript.DataCount = #self.blacklist--初始化数量
		self.view.tips:SetActive(#self.blacklist == 0)
	elseif event == "PLAYER_FIGHT_INFO_CHANGE" then
		if playerModule.GetFightData(data) and self.SNArr[data] then
			self.SNArr[data].combat[UnityEngine.UI.Text].text =tostring(math.ceil(playerModule.GetFightData(data).capacity))
			self.SNArr[data] = nil
		end
	elseif event == "Black_Friend_Sort" then
		self.blacklist = FriendModule.GetManager(2,nil,data.sortType)--2为黑名单
		self.nguiDragIconScript.DataCount = #self.blacklist--初始化数量
		self.view.tips:SetActive(#self.blacklist == 0)
	end
end
return View