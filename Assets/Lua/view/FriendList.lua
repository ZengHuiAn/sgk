local FriendModule = require 'module.FriendModule'
local NetworkService = require "utils.NetworkService";
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local playerModule = require "module.playerModule"
local unionModule = require "module.unionModule"
local ChatManager = require 'module.ChatModule'
local IconFrameHelper = require "utils.IconFrameHelper"
local TipCfg = require "config.TipConfig"
local Time = require "module.Time"
local npcConfig = require "config.npcConfig"
local ItemModule = require "module.ItemModule"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	NetworkService.Send(5025)--查询赠送记录
	NetworkService.Send(5029)--获赠记录
	NetworkService.Send(5021)--查询一次推荐列表
	self.GetGiftFlag = true
	self.FriendData = FriendModule.GetManager()
	self.friendBlacklist=nil
	self.AnimFlag = true
	self.AnimList = {}
	self.SNArr = {}
	self.attentionBtn_Statue = 1--1好友2特别关注3npc
	--self.view.blackListBtn:SetActive(playerModule.Get().honor == 9999)--暂时隐藏npc按钮
	self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
	self.nguiDragIconScript.RefreshIconCallback = (function (go,idx)
		self:FreshScrollView(go,idx)
	end)
	self:GetAnimCount()
	self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
	self.view.tips:SetActive(#self.FriendData == 0)
	self.view.neglectBtn[UnityEngine.UI.Button].interactable = false
	for i = 1,#self.FriendData do
		if FriendModule.GetgivingCount(self.FriendData[i].pid) < 1 then
			self.view.neglectBtn[UnityEngine.UI.Button].interactable = true
			break
		end
	end
	self.view.FriendBtn.Background.onlineCount[UnityEngine.UI.Text].text = "好友("..#self.FriendData.."/"..module.FriendModule.GetFriendConf().friends_limit..")"
	self.view.attentionBtn.Background.attention[UnityEngine.UI.Text].text = "关注(".. FriendModule.GetcareCount() .."/5)"
	self.view.recordBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--赠送记录
		self.view.giveRecord:SetActive(true)
		NetworkService.Send(5029)--获赠记录
	end
	self.view.giveRecord[CS.UGUIClickEventListener].onClick = function ( ... )
		self.view.giveRecord:SetActive(false)
	end

	self.view.neglectBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if FriendModule.GetgivingCount() < module.FriendModule.GetFriendConf().give_limit then
			local tempArr = {}
			for i =1 ,#self.FriendData do
				if FriendModule.GetgivingCount(self.FriendData[i].pid) < 1 and self.FriendData[i].online == 1 then
					tempArr[#tempArr + 1] = self.FriendData[i].pid
				end
			end
			if #tempArr > 0 then
				self.view.neglectBtn[UnityEngine.UI.Button].interactable = false
				NetworkService.Send(5023,{nil,tempArr})
			else
				showDlgError(nil,"没有可赠送好友或好友不在线")
			end
		else
			--showDlgError(nil,"今日赠送次数已达上限："..module.FriendModule.GetFriendConf().give_limit)
			showDlgError(nil,SGK.Localize:getInstance():getValue("haoyou_01"))
		end
	end
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.mask.transform.childCount == 1 then
			UnityEngine.GameObject.Destroy(self.view.mask.transform:GetChild(0).gameObject)
		end
		self.view.mask:SetActive(false)
	end
	self.sortMask=self.view.sortMask
	self.view.FriendBtn.Background[CS.UGUIClickEventListener].onClick = function ( ... )
		--全部用户
		local FriendBlacklist = DialogStack.GetPref_list("FriendBlacklist")
		if FriendBlacklist then
			UnityEngine.GameObject.Destroy(FriendBlacklist.gameObject)--.transform.localPosition = Vector3(2000,0,0)
		end
		self.sortMask.gameObject:SetActive(false)
		-- if self.friendBlacklist then
		-- 	self.friendBlacklist.gameObject:SetActive(false)
		-- end
		self.view.ScrollView.gameObject:SetActive(true)--.transform.localPosition = Vector3(0,58,0)
		self.view.FriendBtn[UI.Toggle].isOn = true
		self.view.attentionBtn[UI.Toggle].isOn = false
		self.view.blackListBtn[UI.Toggle].isOn = false
		self.attentionBtn_Statue = 1
		self.FriendData = FriendModule.GetManager()
		self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
	end
	self.view.attentionBtn.Background[CS.UGUIClickEventListener].onClick = function ( ... )
		local FriendBlacklist = DialogStack.GetPref_list("FriendBlacklist")
		if FriendBlacklist then
			UnityEngine.GameObject.Destroy(FriendBlacklist.gameObject)--.transform.localPosition = Vector3(2000,0,0)--:SetActive(false)
		end
		self.sortMask.gameObject:SetActive(false)
		-- if self.friendBlacklist then
		-- 	self.friendBlacklist.gameObject:SetActive(false)
		-- end
		self.view.ScrollView.gameObject:SetActive(true)--.transform.localPosition = Vector3(0,58,0)
		self.view.FriendBtn[UI.Toggle].isOn = false
		self.view.attentionBtn[UI.Toggle].isOn = true
		self.view.blackListBtn[UI.Toggle].isOn = false
		self.attentionBtn_Statue = 2
		--特别关注
		local list = FriendModule.GetManager()
		self.FriendData = {}
		for i = 1,#list do
			if list[i].care == 1 then
				self.FriendData[#self.FriendData+1] = list[i]
			end
		end
		self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
	end
	self.view.blackListBtn.Background[CS.UGUIClickEventListener].onClick = function ( ... )
		--npc
		self.view.FriendBtn[UI.Toggle].isOn = false
		self.view.attentionBtn[UI.Toggle].isOn = false
		self.view.blackListBtn[UI.Toggle].isOn = true
		self.attentionBtn_Statue = 3
		self.view.ScrollView.gameObject:SetActive(false)--.transform.localPosition = Vector3(2000,58,0)
		local FriendBlacklist = DialogStack.GetPref_list("FriendBlacklist")
		if FriendBlacklist then
			--FriendBlacklist.gameObject:SetActive(true)
			UnityEngine.GameObject.Destroy(FriendBlacklist.gameObject)--.transform.localPosition = Vector3(2000,0,0)--:SetActive(false)
		end
		FriendBlacklist = DialogStack.PushPref("FriendBlacklist",nil,self.view.childRoot.gameObject)
		--print("zoezoezeo",FriendBlacklist)
		--self.sortMask.gameObject:SetActive(true)
		-- if FriendBlacklist then
		-- 	FriendBlacklist.gameObject.transform.localPosition = Vector3(0,0,0)
		-- 	--FriendBlacklist.gameObject:SetActive(true)
		-- else
		-- 	DialogStack.PushPref("FriendBlacklist",nil,self.view.gameObject)
		-- end
	end
	self.recordTipsData = {}
	self.recordTipsDragIconScript = self.view.giveRecord.RecordScrollView[CS.UIMultiScroller]
	self.recordTipsDragIconScript.RefreshIconCallback = (function (go,idx)
		local obj = CS.SGK.UIReference.Setup(go)
		local tempData = self.recordTipsData.list[idx + 1]
		local pid = tempData[1]
		local time = tempData[3]
		local objClone = nil
		if obj.hero.pos.transform.childCount == 0 then
			local tempObj = SGK.ResourcesManager.Load("prefabs/base/newCharacterIcon.prefab")
			objClone = CS.UnityEngine.GameObject.Instantiate(tempObj,obj.hero.pos.transform)
		else
			objClone = obj.hero.pos.transform:GetChild(0)
		end
		local PLayerIcon = SGK.UIReference.Setup(objClone)
		PLayerIcon.transform.localScale = Vector3(1,1,1)
		PLayerIcon.transform.localPosition = Vector3.zero
		if playerModule.IsDataExist(pid) then
			local Module = playerModule.IsDataExist(pid)
 			PLayerIcon[SGK.CharacterIcon]:SetInfo({head = (Module.head ~= 0 and Module.head or 11000),level = Module.level,name = "",vip=0},true)
 			obj.desc[UnityEngine.UI.Text].text = Module.name.." 送您"..module.FriendModule.GetFriendConf().item_value.."点<color=#D1BA36>体力</color>"
 		else
 			playerModule.Get(pid,(function( ... )
 				local Module = playerModule.IsDataExist(pid)
				PLayerIcon[SGK.CharacterIcon]:SetInfo({head = (Module.head ~= 0 and Module.head or 11000),level = Module.level,name = "",vip=0},true)
				obj.desc[UnityEngine.UI.Text].text = Module.name.." 送您"..module.FriendModule.GetFriendConf().item_value.."点<color=#D1BA36>体力</color>"
			end))
 		end
 		if time > 0 then
	 		local s_time= os.date("*t",time)
	 		local min = (s_time.min or 0)
	 		obj.time[UI.Text].text = s_time.year.."."..s_time.month.."."..s_time.day.."   "..(s_time.hour or 0)..":"..(min > 10 and min or "0"..min)
	 	else
	 		obj.time[UI.Text].text = ""
	 	end
	 	local FrinedData = FriendModule.GetManager(1,pid)
	 	obj.hero.care:SetActive(FrinedData and FrinedData.care == 1)
 		obj:SetActive(true)
	end)
	self.view.sortBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		self.view.sortTips:SetActive(true)
		--self.view.sortBtn[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(179.52,180)
	end
	self.view.sortTips[CS.UGUIClickEventListener].onClick = function ( ... )
		self.view.sortTips:SetActive(false)
		--self.view.sortBtn[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(179.52,44.97)
	end
	self.sort_type = 1--1默认2等级3名称
	local sortTips_type = {2,3}
	for i = 1,2 do
		self.view.sortTips.mask[i][CS.UGUIClickEventListener].onClick = function ( ... )
			self.view.sortBtn.desc[UI.Text].text = self.view.sortTips.mask[i][UI.Text].text
			if self.sort_type == 1 then
				self.sort_type = sortTips_type[i]
				sortTips_type[i] = 1
				self.view.sortTips.mask[i][UI.Text].text = "默认排序"
			elseif self.sort_type == 2 then
				self.sort_type = sortTips_type[i]
				sortTips_type[i] = 2
				self.view.sortTips.mask[i][UI.Text].text = "等级排序"
			elseif self.sort_type == 3 then
				self.sort_type = sortTips_type[i]
				sortTips_type[i] = 3
				self.view.sortTips.mask[i][UI.Text].text = "名称排序"
			end
			utils.EventManager.getInstance():dispatch("Black_Friend_Sort",{sortType = self.sort_type})
			--ERROR_LOG(self.sort_type)
			local list = FriendModule.GetManager(1,nil,self.sort_type)
			if self.attentionBtn_Statue == 2 then--特别关注
				self.FriendData = {}
				for i = 1,#list do
					if list[i].care == 1 then
						self.FriendData[#self.FriendData+1] = list[i]
					end
				end
			else--全部用户
				self.FriendData = list
			end
			self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
			self.view.sortTips:SetActive(false)
			--self.view.sortBtn[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(212,60)
			-- if self.attentionBtn_Statue then
			-- 	--特别关注
			-- 	self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
			-- else
			-- 	self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
			-- end
		end
	end
end

function View:FreshScrollView(go,idx)
	local obj = CS.SGK.UIReference.Setup(go)
	local tempData = self.FriendData[idx + 1]
	obj.yBtn.Text[UnityEngine.UI.Text].text = FriendModule.GetgivingCount(tempData.pid) < 1 and "赠送体力" or "已赠送"
	obj.yBtn[UnityEngine.UI.Button].interactable = FriendModule.GetgivingCount(tempData.pid) < 1 and true or false
	obj.yBtn[CS.UGUIClickEventListener].onClick = (function ( ... )
		if FriendModule.GetgivingCount(tempData.pid) < 1 then
			if FriendModule.GetgivingCount() < module.FriendModule.GetFriendConf().give_limit then
				print("zongsong")
				NetworkService.Send(5023,{nil,{tempData.pid}})--赠送体力
				obj.yBtn[CS.UGUIClickEventListener].interactable = false
			else
				--showDlgError(nil,"今日赠送次数已达上限："..module.FriendModule.GetFriendConf().give_limit)
				showDlgError(nil,SGK.Localize:getInstance():getValue("haoyou_01"))
			end
		else
			showDlgError(nil,"已赠送")
		end
	end)
	obj.yBtn[CS.UGUIClickEventListener].interactable = true
	obj.name[UnityEngine.UI.Text].text = tempData.name or ""
	--obj.type[UI.Text].text = tempData.stranger == 1 and "<color=#2EFFD7>好友</color>" or "<color=#FD2D2B>陌生人</color>"
	----------------------好感度------------------------
	local npc_Friend_cfg = npcConfig.GetNpcFriendList()[0]
	local relation = StringSplit(npc_Friend_cfg.qinmi_max,"|")
	local relation_desc = StringSplit(npc_Friend_cfg.qinmi_name,"|")
	local relation_value = FriendModule.GetManager(nil,tempData.pid).liking
	local relation_index = 0
	for i = 1,#relation do
		if relation_value >= tonumber(relation[i]) then
			relation_index = i
		end
	end
	local relation_Next_value = relation[relation_index+1] or "max"
	if relation_Next_value == "max" then
		obj.value[UI.Text].text = relation_Next_value
		obj.Scrollbar[UI.Scrollbar].size = 1
	else
		obj.value[UI.Text].text = (relation_value - tonumber(relation[relation_index])).."/".. math.floor(relation_Next_value-tonumber(relation[relation_index]))
		obj.Scrollbar[UI.Scrollbar].size = (relation_value - tonumber(relation[relation_index]))/math.floor(relation_Next_value-tonumber(relation[relation_index]))
		obj.Scrollbar.SlidingArea:SetActive(obj.Scrollbar[UI.Scrollbar].size > 0)
	end
	--obj.statusbg[UI.Text].text = relation_desc[relation_index]
	obj.statusbg[CS.UGUISpriteSelector].index = relation_index-1
	--------------------------------------------------------
	obj.type:SetActive(false)
	obj.online:SetActive(tempData.online == 1)
	obj.hero.care:SetActive(tempData.care == 1)
	local unionName = unionModule.GetPlayerUnioInfo(tempData.pid).unionName
	if unionName then
		obj.guild[UnityEngine.UI.Text].text = unionName
	else
		unionModule.queryPlayerUnioInfo(tempData.pid,(function ( ... )
			if obj.guild then
				unionName = unionModule.GetPlayerUnioInfo(tempData.pid).unionName or "无"
				obj.guild[UnityEngine.UI.Text].text = unionName
			end
		end))
	end
	if playerModule.GetFightData(tempData.pid) then
		obj.combat[UnityEngine.UI.Text].text =tostring(math.ceil(playerModule.GetFightData(tempData.pid).capacity))
	else
		self.SNArr[tempData.pid] = obj
	end
	-- local PLayerIcon = nil
	-- if obj.hero.pos.transform.childCount == 0 then
	-- 	--PLayerIcon = IconFrameHelper.Hero({},obj.hero.pos)
	local PLayerIcon = IconFrameHelper.Create(obj.hero.pos,{pid = tempData.pid})
	-- else
	-- 	local objClone = obj.hero.pos.transform:GetChild(0)
	-- 	PLayerIcon = SGK.UIReference.Setup(objClone)
	-- end
	-- PlayerInfoHelper.GetPlayerAddData(tempData.pid,99,function (addData)
	-- IconFrameHelper.UpdateHero({pid = tempData.pid,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
	-- end)
	obj.hero[CS.UGUIClickEventListener].onClick = function ( ... )
		local list = nil
		if ChatManager.GetManager(6) then
			list = ChatManager.GetManager(6)[tempData.pid]
		end
		if tempData.online == 1 then
			utils.SGKTools.FriendTipsNew({self.view,obj.status},tempData.pid,{2,3,4,5,7,8,9},list)
		else
			utils.SGKTools.FriendTipsNew({self.view,obj.status},tempData.pid,{2,4,5,7,8,9},list)
		end
		-- PlayerInfoHelper.GetPlayerAddData(tempData.pid,99,function (addData)
  --       IconFrameHelper.UpdateHero({pid = tempData.pid,sex = addData.Sex,headFrame = addData.HeadFrame},PLayerIcon)
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
	self.AnimCount = math.ceil(height/150)
end

function View:ItemAnim(view,idx)
	--print(idx)
		view.transform:DOLocalMoveX(750,0.05):OnComplete(function ()
			--print(view[UnityEngine.RectTransform].anchoredPosition)
		    view:SetActive(true);
		    view.transform:DOLocalMoveX(20,0.4):OnComplete(function ()
		    	self.AnimList[idx] = false
		    	if idx+1 >= self.AnimCount or idx+1 == self.nguiDragIconScript.DataCount then
					self.AnimFlag = false
					self.view.ScrollViewMask:SetActive(false)
				end
		    end)
		end):SetDelay(idx*0.05)
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
function View:onEvent(event,data)
	if event == "Friend_INFO_CHANGE" then
		if self.attentionBtn_Statue == 2 then
			--特别关注
			local list = FriendModule.GetManager(1,nil,self.sort_type)
			self.FriendData = {}
			for i = 1,#list do
				if list[i].care == 1 then
					self.FriendData[#self.FriendData+1] = list[i]
				end
			end
			self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
		elseif self.attentionBtn_Statue == 1 then
			--全部用户
			self.FriendData = FriendModule.GetManager(1,nil,self.sort_type)
			self.nguiDragIconScript.DataCount = #self.FriendData--初始化数量
		end
		for i = 1,#self.FriendData do
			if FriendModule.GetgivingCount(self.FriendData[i].pid) < 1 then
				self.view.neglectBtn[UnityEngine.UI.Button].interactable = true
				break
			end
		end
		--NetworkService.Send(5029)
		local temp_list = FriendModule.GetManager(1,nil,self.sort_type)
		self.view.tips:SetActive(#temp_list == 0)
		self.view.FriendBtn.Background.onlineCount[UnityEngine.UI.Text].text = "好友("..#temp_list.."/"..module.FriendModule.GetFriendConf().friends_limit..")"
		self.view.attentionBtn.Background.attention[UnityEngine.UI.Text].text = "关注(".. FriendModule.GetcareCount() .."/5)"
	elseif event == "receive_give_record_query" then
		self.view.given[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("haoyou_02")--"每次赠送/获赠:时之力"..module.FriendModule.GetFriendConf().item_value.."点"
		if self.GetGiftFlag then
			self.GetGiftFlag = false
			self.view.recordBtndesc[UnityEngine.UI.Text].text = "今日获赠:"..data.count.."/"..module.FriendModule.GetFriendConf().get_limit
		end
		self.view.neglectBtndesc[UnityEngine.UI.Text].text = "今日已赠:"..FriendModule.GetgivingCount().."/"..module.FriendModule.GetFriendConf().give_limit
		if #data.list > 0 then--刷新获赠记录列表
			--self.recordTipsData = data
			--self.recordTipsDragIconScript.DataCount = #data.list
		elseif self.view.giveRecord.activeSelf then
			showDlgError(nil,"没有好友赠送记录")
		end
	elseif event == "Presented_successful" then
		self.view.neglectBtn[UnityEngine.UI.Button].interactable = false
		for i = 1,#self.FriendData do
			if FriendModule.GetgivingCount(self.FriendData[i].pid) < 1 then
				self.view.neglectBtn[UnityEngine.UI.Button].interactable = true
				break
			end
		end
		self.nguiDragIconScript:ItemRef()
		self.view.neglectBtndesc[UnityEngine.UI.Text].text = "今日已赠:"..FriendModule.GetgivingCount().."/"..module.FriendModule.GetFriendConf().give_limit
	elseif event == "PLAYER_FIGHT_INFO_CHANGE" then
		if playerModule.GetFightData(data) and self.SNArr[data] then
			self.SNArr[data].combat[UnityEngine.UI.Text].text =tostring(math.ceil(playerModule.GetFightData(data).capacity))
			self.SNArr[data] = nil
		end
	elseif event == "Friend_attention_CHANGE" then
		self.FriendData = FriendModule.GetManager(1,nil,self.sort_type)
		self.nguiDragIconScript:ItemRef()
		self.view.FriendBtn.Background.onlineCount[UnityEngine.UI.Text].text = "好友("..#self.FriendData.."/"..module.FriendModule.GetFriendConf().friends_limit..")"
		self.view.attentionBtn.Background.attention[UnityEngine.UI.Text].text = "关注(".. FriendModule.GetcareCount() .."/5)"
	elseif event == "Friend_Giving_Succeed" then
		self.nguiDragIconScript:ItemRef()
	end
end

function View:listEvent()
	return {
		"Friend_INFO_CHANGE",
		"PLAYER_FIGHT_INFO_CHANGE",
		"Presented_successful",
		"receive_give_record_query",
		"Friend_attention_CHANGE",
		"Friend_Giving_Succeed",
	}
end
return View