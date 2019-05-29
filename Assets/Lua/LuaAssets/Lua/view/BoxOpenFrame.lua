local Time = require "module.Time"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.AwardData = {}
	self.offlineAwardData = nil;
	self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]	
	self.nguiDragIconScript.RefreshIconCallback = (function (go,idx)
		--ERROR_LOG(sprinttb(self.AwardData[idx +1]))
		local objView = CS.SGK.UIReference.Setup(go)
		objView.read:SetActive(true)
		objView.name[UnityEngine.UI.Text].text = self.AwardData[idx +1][2]
		local s_time= os.date("*t",Time.now())
		objView.time[UnityEngine.UI.Text].text = s_time.year.."."..s_time.month.."."..s_time.day
		objView.iconGrod[2]:SetActive(false)
		objView[CS.UGUIClickEventListener].enabled = true
		objView[CS.UGUIClickEventListener].onClick = (function ()
			objView[CS.UGUIClickEventListener].enabled = false
			if self.AwardData[idx + 1][1] ~= 1 then
				utils.NetworkService.Send(195,{nil,self.AwardData[idx + 1][1]})
			else
				self:ShowOfflineAward()
			end
		end)
		go:SetActive(true)
	end)
	self.AwardData = module.AwardModule.GetAward()
	self.nguiDragIconScript.DataCount = #self.AwardData
	self.view.getBtn[CS.UGUIClickEventListener].onClick = (function( ... )
		for i = 1,#self.AwardData do
			if self.AwardData[i][1] ~= 1 then
				utils.NetworkService.Send(195,{nil,self.AwardData[i][1]})
			else
				if self.offlineAwardData == nil then
					self:GetOfflineAwardData();
				end
				module.AwardModule.GetOfflineAward(self.offlineAwardData[1].time, true)
			end
		end
	end)
	self:GetOfflineAwardData();
end

function View:GetOfflineAwardData()
	local offlineAward = module.AwardModule.GetOfflineAwardList();
	if offlineAward[3] then
		local list = offlineAward[3];
		local awardList = {};
		for i,v in ipairs(list) do
			if awardList[v[1]] == nil then
				awardList[v[1]] = {};
			end
			local info = {};
			info.drop_id = v[2];
			info.count = v[3];
			table.insert(awardList[v[1]], info)
		end
		local sortList = {}
		for k,v in pairs(awardList) do
			local info = {};
			info.time = k;
			info.list = v;
			table.insert(sortList, info);
		end
		table.sort(sortList, function ( a,b )
			return a.time < b.time;
		end)
		self.offlineAwardData = sortList;
	end
	-- print("奖励列表", sprinttb(self.offlineAwardData))
end

function View:ShowOfflineAward()
	if self.offlineAwardData == nil then
		self:GetOfflineAwardData();
	end
	if #self.offlineAwardData ~= 0 then
		DialogStack.PushPrefStact("OfflineAward", {list = self.offlineAwardData}, self.view.gameObject)
	end
end

function View:listEvent()
	return {
		"NOTIFY_REWARD_CHANGE",
	}
end

function View:onEvent(event,data)
	if event == "NOTIFY_REWARD_CHANGE" then
		self.AwardData = module.AwardModule.GetAward()
		if #self.AwardData > 0 then
			self.nguiDragIconScript.DataCount = #self.AwardData
		else
			DispatchEvent("KEYDOWN_ESCAPE")
		end
		if self.offlineAwardData ~= nil then
			self:GetOfflineAwardData();
		end
	end
end
return View