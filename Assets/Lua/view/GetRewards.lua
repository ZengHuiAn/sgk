local QuestModule = require "module.QuestModule"
local ItemModule = require "module.ItemModule"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.TaskCfg = {}
	self.ItemList = {}
	self.QuestList = {}
	self.click_item_list = nil
	self.box_index = 1--当前玩家点击的宝箱
	self.box_open_index = 1--当前可打开宝箱
	self.select_reset = false
	self.shop_ids = {130010001,130010002,130010003}
	self.click_select = nil
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		DialogStack.Pop()
	end
	self.view.close[CS.UGUIClickEventListener].onClick = function ( ... )
		DialogStack.Pop()
	end
	self.view.getBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.getBtn[UI.Button].interactable then
			--ERROR_LOG(sprinttb(self.QuestList))
			for i = 1,#self.QuestList do
				if self.QuestList[i].id == self.TaskCfg[self.box_index].id then
					if ItemModule.GetItemCount(self.QuestList[i].event_id1) >= self.QuestList[i].event_count1 then
						if self.click_item_list then
							QuestModule.Finish(self.QuestList[i].uuid)
						else
							showDlgError(nil,"请选择一个奖励")
						end
					else
						showDlgError(nil,"积分不足")
					end
					break
				end
			end
		end
	end
	self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
	self.nguiDragIconScript.RefreshIconCallback = function (go,idx)
		local ItemView = CS.SGK.UIReference.Setup(go)
		local tempData = self.ItemList[idx + 1]
		local IconView = nil
		if ItemView.pos.transform.childCount == 0 then
			IconView = IconFrameHelper.Item({},nil,{pos=ItemView.pos, scale=0.8})
		else
			IconView = SGK.UIReference.Setup(ItemView.pos.transform:GetChild(0))
		end
		if self.select_reset then
			ItemView.select[CS.UGUISpriteSelector].index = 0
		end
		IconFrameHelper.UpdateItem({id = tempData.id,type = tempData.type,count = tempData.value},IconView,{showDetail = true,func = function()
			if ItemView.select[CS.UGUISpriteSelector].index == 0 then
				if self.click_item_list ~= nil then
					self.click_select[CS.UGUISpriteSelector].index = 0
				end
				self.click_select = ItemView.select
				ItemView.select[CS.UGUISpriteSelector].index = 1
				self.click_item_list = {}
				self.click_item_list[tempData.idx] = tempData
			else
				ItemView.select[CS.UGUISpriteSelector].index = 0
				self.click_item_list = nil
			end
		end})
		ItemView:SetActive(true)
	end

	local Conflist = QuestModule.GetConfigType(104)
	local maxValue = 0
	for k,v in pairs(Conflist) do
		--ERROR_LOG(v.name)
		--ERROR_LOG(v.event_id1)
		--ERROR_LOG(v.event_count1)
		self.TaskCfg[#self.TaskCfg+1] = v
	end
	table.sort(self.TaskCfg,function (a,b)
		return a.event_count1 < b.event_count1
	end)

	self.QuestList = QuestModule.GetList(104,0)--正在进行的任务
	for i = 1,#self.TaskCfg do
		if QuestModule.Get(self.TaskCfg[i].id) and QuestModule.Get(self.TaskCfg[i].id).status and QuestModule.Get(self.TaskCfg[i].id).status == 0 then
			self.box_index = i
			self.box_open_index = i
			break
		end
	end

	self:init()
	self.view.select:SetActive(true)
	self:AcceptTask()
end
function View:init()
	local shop_Data = module.ShopModule.GetManager(3001)
	if #self.TaskCfg > 0 then
		self.view.select.transform.position = self.view.group[self.box_index].transform.position
		if QuestModule.Get(self.TaskCfg[self.box_index].id) and QuestModule.Get(self.TaskCfg[self.box_index].id).status and QuestModule.Get(self.TaskCfg[self.box_index].id).status == 0 then
			self.view.getBtn[CS.UGUIClickEventListener].interactable = true
		else
			self.view.getBtn[CS.UGUIClickEventListener].interactable = false
		end
		for i = 1,#self.TaskCfg do
			local IconView = nil
			if self.view.group[i].transform.childCount == 2 then
				IconView = IconFrameHelper.Item({},nil,{pos=self.view.group[i], scale=0.8})
			else
				IconView = SGK.UIReference.Setup(self.view.group[i].transform:GetChild(2))
			end
			IconFrameHelper.UpdateItem({id = 89000+i},IconView,{showDetail = true,func = function()
				self.select_reset = (self.box_index ~= i)
				if self.select_reset then
					self.click_item_list = nil
				end
				self.box_index = i
				self:init()
			end})
			local count = ItemModule.GetItemCount(self.TaskCfg[i].event_id1)
			self.view.group[i].desc[UI.Text].text = "已领取"
			for j = 1,#self.QuestList do
				if self.QuestList[j].id == self.TaskCfg[i].id then
					self.view.group[i].desc[UI.Text].text = count.."/"..self.TaskCfg[i].event_count1
				end
			end
			if self.box_index == i and shop_Data.shoplist and shop_Data.shoplist[self.shop_ids[self.box_index]].product_item_list then

				------------------------------------------------------------------------------
				-- local v = self.TaskCfg[i]
				-- local ItemList = {}
				-- if v.reward_id1 ~= 0 and v.reward_id1 ~= 90036 then--必得
				-- 	ItemList[#ItemList+1] = {type = v.reward_type1,id = v.reward_id1,count = v.reward_value1,mark =1}
				-- end
				-- if v.reward_id2 ~= 0 and v.reward_id2 ~= 90036 then--必得
				-- 	ItemList[#ItemList+1] = {type = v.reward_type2,id = v.reward_id2,count = v.reward_value2,mark = 1}
				-- end
				-- if v.reward_id3 ~= 0 and v.reward_id3 ~= 90036 then--必得
				-- 	ItemList[#ItemList+1] = {type = v.reward_type3,id = v.reward_id3,count = v.reward_value3,mark = 1}
				-- end
				-- if v.drop_id ~= 0 then
				-- 	local Fight_reward = SmallTeamDungeonConf.GetFight_reward(v.drop_id)
				-- 	if Fight_reward then
				-- 		for i = 1,#Fight_reward do
				-- 			local repetition = false
				-- 			for j = 1,#ItemList do
				-- 				if ItemList[j].id == Fight_reward[i].id then
				-- 					repetition = true
				-- 					break
				-- 				end
				-- 			end
				-- 			if not repetition then
				-- 				ItemList[#ItemList+1] = {type = Fight_reward[i].type,id = Fight_reward[i].id,count = 0,mark = 2}--概率获得
				-- 			end
				-- 		end
				-- 	end
				-- end
				------------------------------------------------------------------------------
				local ItemList = shop_Data.shoplist[self.shop_ids[self.box_index]].product_item_list
				--ERROR_LOG(sprinttb(ItemList))
				self.ItemList = ItemList
				if self.nguiDragIconScript.DataCount == #self.ItemList then
					self.nguiDragIconScript:ItemRef()
				else
					self.nguiDragIconScript.DataCount = #self.ItemList
				end
			end
		end
	else
		ERROR_LOG("config_advance_quest中type 104 任务不存在")
	end
end
function View:AcceptTask()
	if ItemModule.GetItemCount(78901) >= 1 then
		QuestModule.Accept(1041010)
	else
		--ERROR_LOG(ItemModule.GetItemCount(78901))
	end
	if ItemModule.GetItemCount(78902) >= 1 then
		QuestModule.Accept(1041020)
	else
		--ERROR_LOG(ItemModule.GetItemCount(78902))
	end
	if ItemModule.GetItemCount(78903) >= 1 then
		QuestModule.Accept(1041030)
	else
		--ERROR_LOG(ItemModule.GetItemCount(78903))
	end
	if ItemModule.GetItemCount(78951) >= 3 then
		--QuestModule.Accept(1042001)
		QuestModule.Finish(1042001)
	else
		--ERROR_LOG(ItemModule.GetItemCount(78951))
	end
end
function View:listEvent()
	return {
	"ITEM_INFO_CHANGE",
	"integral_info_change",
	"QUEST_INFO_CHANGE",
	"SHOP_INFO_CHANGE",
	"SHOP_BUY_SUCCEED",
	}
end

function View:onEvent(event,data)
	if event == "QUEST_INFO_CHANGE" then
		if self.click_item_list then
			for k,v in pairs(self.click_item_list) do
				module.ShopModule.Buy(3001,self.shop_ids[self.box_index],1,{product_index = v.idx})
			end
			self.click_item_list = nil
		end
		self.QuestList = QuestModule.GetList(104,0)--正在进行的任务
		for i = 1,#self.TaskCfg do
			if QuestModule.Get(self.TaskCfg[i].id).status and QuestModule.Get(self.TaskCfg[i].id).status == 0 then
				self.select_reset = true--(self.box_index ~= i)
				self.box_index = i
				self.box_open_index = i
				if self.select_reset then
					self.click_item_list = nil
				end
				break
			end
		end
		self:init()
	elseif event == "SHOP_INFO_CHANGE" then
		--ERROR_LOG(data.id)
		self:init()
	elseif event == "ITEM_INFO_CHANGE" then
		self:AcceptTask()
	elseif event == "SHOP_BUY_SUCCEED" then
		self:init()
	end
end
return View