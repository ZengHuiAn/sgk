local QuestModule = require "module.QuestModule"
local ItemModule = require "module.ItemModule"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.now_QuestModule = nil
	self.effectlist = {}--光效组
	self.effectlist_pool = {}
	self.SliderValues = {}
	self.pointList = {}
	local Conflist = QuestModule.GetConfigType(104)
	local maxValue = 0
	for k,v in pairs(Conflist) do
		--ERROR_LOG(v.name)
		--ERROR_LOG(v.event_id1)
		--ERROR_LOG(v.event_count1)
		self.SliderValues[#self.SliderValues+1] = v
	end
	table.sort(self.SliderValues,function (a,b)
		return a.event_count1 < b.event_count1
	end)
	if #self.SliderValues > 0 then
		local count = ItemModule.GetItemCount(self.SliderValues[1].event_id1)
		for i = 1,#self.SliderValues do
			local x = self.SliderValues[i].event_count1/self.SliderValues[#self.SliderValues].event_count1 * 460
			self.view.Slider.point[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(x,0)
			local obj = UnityEngine.GameObject.Instantiate(self.view.Slider.point.gameObject,self.view.Slider.transform)
			obj:SetActive(true)
			self.pointList[i] = CS.SGK.UIReference.Setup(obj)
			self.pointList[i].value[UI.Text].text = self.SliderValues[i].event_count1
		end
		self:Init()
	else
		ERROR_LOG("config_advance_quest中type 104 任务不存在")
	end
	GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_box_get.prefab"),self.view.box[1])
	for i = 1,2 do
		self.view.box[i][CS.UGUIClickEventListener].onClick = function ( ... )
			DialogStack.PushPrefStact("PromptBox/GetRewards",nil,UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject.transform) 
		end
	end
end
function View:Init()
	local count = ItemModule.GetItemCount(self.SliderValues[1].event_id1)
	for i = 1,#self.SliderValues do
		if self.pointList[i] then
			if count >= self.SliderValues[i].event_count1 then
				self.pointList[i][1]:SetActive(true)
				self.pointList[i][2]:SetActive(false)
			else
				self.pointList[i][1]:SetActive(false)
				self.pointList[i][2]:SetActive(true)
			end
		end
	end

	--[[
	--self.view.Slider.FillArea:SetActive(false)
	if count > 0 then
		--self.view.Slider.FillArea:SetActive(true)
		self.view.Scrollbar[UI.Scrollbar].size = count/self.SliderValues[#self.SliderValues].event_count1
	else
		self.view.Scrollbar[UI.Scrollbar].size = 0
	end
	--]]
	self:ShowsBox(count):SetActive(true)
end
function View:ShowsBox(count)
	local QuestList = QuestModule.GetList(104,0)
	local Conflist = QuestModule.GetConfigType(104)
	self.view.box[1]:SetActive(false)
	self.view.box[2]:SetActive(false)
	for k,v in pairs(Conflist) do
		if v.type == 104 then
			--ERROR_LOG(v.id)
			--local interactable = false
			for j,s in pairs(QuestList) do
				-- ERROR_LOG(sprinttb(v))
				-- ERROR_LOG(sprinttb(s))
				if count >= v.event_count1 and v.id == s.id then
					--interactable = true
					return self.view.box[1]
				end
			end
			self.view.box[1][UI.Image]:LoadSprite("icon/" .. v.icon)
			self.view.box[2][UI.Image]:LoadSprite("icon/" .. v.icon)
			--self.now_QuestModule = v
			-- box[CS.UGUIClickEventListener].onClick = function ( ... )
			-- 	local ItemList = {}
			-- 	if v.reward_id1 ~= 0 and v.reward_id1 ~= 90036 then--必得
			-- 		ItemList[#ItemList+1] = {type = v.reward_type1,id = v.reward_id1,count = v.reward_value1,mark =1}
			-- 	end
			-- 	if v.reward_id2 ~= 0 and v.reward_id2 ~= 90036 then--必得
			-- 		ItemList[#ItemList+1] = {type = v.reward_type2,id = v.reward_id2,count = v.reward_value2,mark = 1}
			-- 	end
			-- 	if v.reward_id3 ~= 0 and v.reward_id3 ~= 90036 then--必得
			-- 		ItemList[#ItemList+1] = {type = v.reward_type3,id = v.reward_id3,count = v.reward_value3,mark = 1}
			-- 	end
			-- 	if v.drop_id ~= 0 then
			-- 		local Fight_reward = SmallTeamDungeonConf.GetFight_reward(v.drop_id)
			-- 		if Fight_reward then
			-- 			for i = 1,#Fight_reward do
			-- 				local repetition = false
			-- 				for j = 1,#ItemList do
			-- 					if ItemList[j].id == Fight_reward[i].id then
			-- 						repetition = true
			-- 						break
			-- 					end
			-- 				end
			-- 				if not repetition then
			-- 					ItemList[#ItemList+1] = {type = Fight_reward[i].type,id = Fight_reward[i].id,count = 0,mark = 2}--概率获得
			-- 				end
			-- 			end
			-- 		end
			-- 	end
			-- 	local fun = function ( ... )
			-- 		--ERROR_LOG(v.uuid)
			-- 		if count >= v.event_count1 then
			-- 			QuestModule.Finish(v.uuid)
			-- 			DialogStack.Pop()
			-- 		else
			-- 			showDlgError(nil,"积分不足")
			-- 		end
			-- 	end
			-- 	local desc = SGK.Localize:getInstance():getValue("zhaomu_jifenbaoxiang_02",v.event_count1,count)--"积分达到 "...." 分后可领取 (当前"..count..")"
			-- 	local name = SGK.Localize:getInstance():getValue("zhaomu_jifenbaoxiang_01")
			-- 	DialogStack.PushPrefStact("mapSceneUI/GiftBoxPre", {itemTab = ItemList,interactable = interactable, fun = fun,textName = name,textDesc = desc},UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject.transform)
			-- end
		end
	end
	return self.view.box[2]
end
function View:listEvent()
	return {
	"ITEM_INFO_CHANGE",
	"integral_info_change"
	}
end

function View:onEvent(event,data)
	if event == "ITEM_INFO_CHANGE" then
		self:Init()
	elseif event == "integral_info_change" then
		if #self.effectlist_pool > 0 then
			self.effectlist[#self.effectlist+1] = self.effectlist_pool[1]
			table.remove(self.effectlist_pool,1)
		else
			self.effectlist[#self.effectlist+1] = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_dati_lizi_layer1.prefab"),self.view)
		end
		self.effectlist[#self.effectlist].transform.position = Vector3(data.x,data.y,data.z)
		local idx = #self.effectlist
		self.effectlist[#self.effectlist].transform:DOMove(self.view.box.transform.position,1):OnComplete(function( ... )
			self.effectlist_pool[#self.effectlist_pool+1] = self.effectlist[idx]
			self.effectlist[idx] = nil
		end)
	end
end
return View