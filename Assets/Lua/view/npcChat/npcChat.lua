local npcConfig = require "config.npcConfig"
local ItemModule = require "module.ItemModule"
local IconFrameHelper = require "utils.IconFrameHelper"
local playerModule = require "module.playerModule"
local QuestModule = require "module.QuestModule"
local NpcChatMoudle = require "module.NpcChatMoudle"
local UserDefault = require "utils.UserDefault"
local View = {}
function View:Start(data)
	self.view = SGK.UIReference.Setup(self.gameObject);
	local init_obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"), self.view.transform)
	self.rewardQuest_topic_id=nil
	self.friendCfg=data.data
	local relation = StringSplit(self.friendCfg.quest_up,"|")
	self.firstStageQuest = tonumber(relation[2])
	self.npcCfg=data.npcCfg
	self:initData()
	print("zoe npcChat",self.firstStageQuest,sprinttb(relation))
	self:loadChatRecord(true)
	self:reappearChat(self.view.chat.ScrollView.Viewport.Content.ChatObj.gameObject,self.view.chat.ScrollView.Viewport.Content.transform)
	self:init()
	--NpcChatMoudle.GetNpcRelation(self.npcCfg.npc_id)
end

function View:initData()
	self.npcTopicCfg = npcConfig.GetnpcTopic()
	self.npcDialogCfg = npcConfig.GetnpcDialog()
	self.relation_value = ItemModule.GetItemCount(self.friendCfg.arguments_item_id)
end

function View:loadChatRecord(bool)
	local allNPC_Chat_Record = UserDefault.Load("NPC_Chat_Record",true)
	--UserDefault.Clear()
	if not allNPC_Chat_Record[self.npcCfg.npc_id] then
		allNPC_Chat_Record[self.npcCfg.npc_id]={}
		--print("zoe111111111")
		UserDefault.Save()
	end
	self.NPC_Chat_Record = allNPC_Chat_Record[self.npcCfg.npc_id]
	--print("zoe查看记录长度",#self.NPC_Chat_Record)
	if #self.NPC_Chat_Record > 0 then 
		print("zoe查看记录",sprinttb(self.NPC_Chat_Record))
	end
	if bool then
		if #self.NPC_Chat_Record == 0 or self.NPC_Chat_Record[#self.NPC_Chat_Record].isOver then
			self.view.chooseItem.gameObject:SetActive(true)
	    	self.view.chatItem.gameObject:SetActive(false)
	    else
	    	self.view.chooseItem.gameObject:SetActive(false)
	    	self.view.chatItem.gameObject:SetActive(true)
	    end
	end
end

function View:reappearChat(tempObj,trans)
	for i=1,#self.NPC_Chat_Record do
		--print("2222222",i,sprinttb(self.NPC_Chat_Record[i]))
		if self.NPC_Chat_Record[i].right then
			local obj=SGK.UIReference.Setup(CS.UnityEngine.GameObject.Instantiate(tempObj,trans))
			obj.Right.Content.bg.desc[CS.InlineText].text = self.npcDialogCfg[self.NPC_Chat_Record[i].storyId]["reply"..self.NPC_Chat_Record[i].replyId]
			--IconFrameHelper.Hero({pid = playerModule.Get().id},obj.Right.icon)
			--print("PLayer",sprinttb(module.playerModule.Get()))
			obj.Right.icon.transform.localScale=UnityEngine.Vector3(0.8,0.8,1)
			IconFrameHelper.Create(obj.Right.icon,{pid = playerModule.GetSelfID()})
			obj.Right.name[UI.Text].text=playerModule.Get().name
			obj.Right.gameObject:SetActive(true)
			obj.gameObject:SetActive(true)
		end
		if self.NPC_Chat_Record[i].left then
			local obj=SGK.UIReference.Setup(CS.UnityEngine.GameObject.Instantiate(tempObj,trans))
			obj.Left.Content.bg.desc[CS.InlineText].text = self.npcDialogCfg[self.NPC_Chat_Record[i].storyId].text
			local npc_cfg = self.npcCfg
			obj.Left.icon[UI.Image]:LoadSprite("icon/"..npc_cfg.icon)
			obj.Left.icon.transform.localScale=UnityEngine.Vector3(1.05,1.05,1)
			obj.Left.name[UI.Text].text=npc_cfg.name
			obj.Left.gameObject:SetActive(true)
			obj.gameObject:SetActive(true)
		end
		if i == #self.NPC_Chat_Record then
			if self.NPC_Chat_Record[i].left then
				self.rewardQuest_topic_id = self.NPC_Chat_Record[i].rewardId
				self:UpPlayerItem(self.NPC_Chat_Record[i].storyId)
			end
			if self.NPC_Chat_Record[i].right then
				for i=1,3 do
					self.view.chatItem["item"..i].gameObject:SetActive(false)
					self.view.chatItem["item"..i][UnityEngine.CanvasGroup].alpha=0
				end
				local next_story_id = self.npcDialogCfg[self.NPC_Chat_Record[i].storyId]["reply_npc"..self.NPC_Chat_Record[i].replyId]
				self.rewardQuest_topic_id = self.NPC_Chat_Record[i].rewardId
				if next_story_id == 0 then 
					self:finishChat()
				else
					self.view.top.status[UI.Text].text="对方正在输入中..."
					self.view.chatItem["item4"].gameObject:SetActive(true)
	    			self.view.chatItem["item4"][UnityEngine.CanvasGroup]:DOFade(1,0.4):SetDelay(0.1):OnComplete(function ()
	    				self.view.chatItem["item4"][UnityEngine.CanvasGroup]:DOFade(1,0.1):SetDelay(1.7):OnComplete(function ()
	    					self:UpNpcDialog(tempObj,next_story_id)
	    				end)
	    			end)
	    		end
			end	
		end
	end
end

function View:init()
	self.view = SGK.UIReference.Setup(self.gameObject);
	self.view.top.status[UI.Text].text=self.npcCfg.name
	
	for i=1,4 do
		local _npcTopicCfg = self.npcTopicCfg[self.npcCfg.npc_id][i]
		local last_npcTopicCfg = self.npcTopicCfg[self.npcCfg.npc_id][i-1]
		--print(i,sprinttb(_npcTopicCfg))
		local npcTopicCfg = nil
		-- for k,v in pairs(_npcTopicCfg) do
		-- 	if not module.QuestModule.Get(v.reward_quest) or module.QuestModule.Get(v.reward_quest).status == 0 then
		-- 		npcTopicCfg = v
		-- 		break
		-- 	end
		-- end
		-- local checkFlag = true
		-- if not npcTopicCfg or npcTopicCfg.story_begin == 0 then
		-- 	checkFlag = false
		npcTopicCfg = self.npcTopicCfg[self.npcCfg.npc_id][i][1]
		-- end
		--print(i,sprinttb(npcTopicCfg))
		local _view=self.view.chooseItem["item"..i]
		_view.Text[UI.Text].text=npcTopicCfg.topic
		local onClickFlag = true
		if self.relation_value >= npcTopicCfg.condition then
			if last_npcTopicCfg and #last_npcTopicCfg > 0 and QuestModule.Get(last_npcTopicCfg[#last_npcTopicCfg].reward_quest) and QuestModule.Get(last_npcTopicCfg[#last_npcTopicCfg].reward_quest).status == 1 then
				_view.mask.gameObject:SetActive(false)
	    	else
	    		if i ~= 1 then
		    		_view.mask.Text[UI.Text].text="<color=#FFC300FF>上个话题未完成</color>"
					_view.mask.gameObject:SetActive(true)
					onClickFlag =false
				end
	    	end
	    	if onClickFlag then
				CS.UGUIClickEventListener.Get(self.view.chooseItem["item"..i].gameObject).onClick = function ()
					if #_npcTopicCfg > 0 and _npcTopicCfg[1].story_begin ~= 0 then
						-- self.rewardQuest_topic_id = npcTopicCfg.reward_quest
		    --     		self.view.chooseItem.gameObject:SetActive(false)
		    --     		self:UpPlayerDialog(self.view.chat.ScrollView.Viewport.Content.ChatObj.gameObject,npcTopicCfg.story_begin,1)
		    --     		self.view.chatItem.gameObject:SetActive(true)
		    			self.view.chooseItem.gameObject:SetActive(false)
		    			self:UpLittleTopic(_npcTopicCfg)
		    			self.view.littleTopic.gameObject:SetActive(true)
		        	else
		        		showDlgError(nil,"暂未开放")
		        	end
	    		end
	    	end
		else
			--_view.Text.gameObject:SetActive(false)
			_view.mask.Text[UI.Text].text="<color=#FFFFFFFF>好感度"..npcTopicCfg.condition.."解锁</color>"
			_view.mask.gameObject:SetActive(true)
		end
	end
	local stageNum = module.ItemModule.GetItemCount(self.friendCfg.stage_item)
	local relation = StringSplit(self.friendCfg.qinmi_max,"|")
	local relation_desc = StringSplit(self.friendCfg.qinmi_name,"|")
	local relation_value = ItemModule.GetItemCount(self.friendCfg.arguments_item_id)
	self.view.top.friendship[CS.UGUISpriteSelector].index = stageNum
	local relation_Next_value = relation[stageNum+2] or "max"
	if relation_Next_value == "max" then
		self.view.top.value[UI.Text].text = relation_Next_value
		self.view.top.Scrollbar[UI.Scrollbar].size = 1
	else
		self.view.top.value[UI.Text].text = relation_value.."/"..tonumber(relation_Next_value)
		if relation_value > tonumber(relation_Next_value) then
			self.view.top.Scrollbar[UI.Scrollbar].size = 1
		else
			self.view.top.Scrollbar[UI.Scrollbar].size = relation_value/math.floor(relation_Next_value)
		end
	end
end

function View:UpLittleTopic(_npcTopicCfg)
	CS.UGUIClickEventListener.Get(self.view.littleTopic.back.gameObject).onClick = function ()
		self.view.chooseItem.gameObject:SetActive(true)
	    self.view.littleTopic.gameObject:SetActive(false)
	end
	--print("xxxxxxxxx",sprinttb(_npcTopicCfg))
	self.view.littleTopic.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function (go,idx)
		local obj = CS.SGK.UIReference.Setup(go)
		local onClickFlag = true
		local npcTopicCfg = _npcTopicCfg[(idx+1)]
		local LastNpcTopicCfg = _npcTopicCfg[(idx)]
		obj.Text[UI.Text].text = _npcTopicCfg[(idx+1)].topic_small
		--print(sprinttb(QuestModule.Get(npcTopicCfg.reward_quest)))
		if LastNpcTopicCfg and QuestModule.Get(LastNpcTopicCfg.reward_quest) and QuestModule.Get(LastNpcTopicCfg.reward_quest).status == 1 then
			if QuestModule.Get(npcTopicCfg.reward_quest) and QuestModule.Get(npcTopicCfg.reward_quest).status == 1 then
				obj.mask:SetActive(true)
				obj.mask.read:SetActive(true)
				obj.mask.Text:SetActive(false)
			else
				obj.mask:SetActive(false)
			end	
		else
			if idx == 0 then
				if QuestModule.Get(npcTopicCfg.reward_quest) and QuestModule.Get(npcTopicCfg.reward_quest).status == 1 then
					obj.mask:SetActive(true)
					obj.mask.read:SetActive(true)
					obj.mask.Text:SetActive(false)
				else
					obj.mask:SetActive(false)
				end
			else	
				obj.mask:SetActive(true)
				obj.mask.read:SetActive(false)
				obj.mask.Text:SetActive(true)
				onClickFlag = false
			end
		end
		if onClickFlag then	
			CS.UGUIClickEventListener.Get(obj.gameObject).onClick = function ()
				if not QuestModule.Get(npcTopicCfg.reward_quest) or QuestModule.Get(npcTopicCfg.reward_quest).status == 0 then
					self.rewardQuest_topic_id = npcTopicCfg.reward_quest
	        		self.view.littleTopic.gameObject:SetActive(false)
	        		self:UpPlayerDialog(self.view.chat.ScrollView.Viewport.Content.ChatObj.gameObject,npcTopicCfg.story_begin,1)
	        		self.view.chatItem.gameObject:SetActive(true)
	        	else
	        		self:MoveToTopic(npcTopicCfg.story_begin)
	        	end
			end
		end
		obj.gameObject:SetActive(true)
	end
	self.view.littleTopic.ScrollView[CS.UIMultiScroller].DataCount = #_npcTopicCfg
end

function View:MoveToTopic(story_id)
	self:loadChatRecord()
	local index = 0
	for i=1,#self.NPC_Chat_Record do
		if self.NPC_Chat_Record[i].storyId == story_id then
			index = i
			break
		end
	end
	local height = self.view.chat.ScrollView.Viewport.Content[UnityEngine.RectTransform].sizeDelta.y
	local targetHeight = self.view.chat.ScrollView.Viewport.Content.gameObject.transform:GetChild(index):GetComponent(typeof(UnityEngine.RectTransform)).anchoredPosition.y
	local viewHight = self.view.chat.ScrollView.Viewport[UnityEngine.RectTransform].rect.size.y
	self.view.chat.ScrollView.Viewport.Content.transform:DOLocalMoveY(viewHight - height - targetHeight, 0.3)
	--local value = (height - math.abs(targetHeight))/height
	--local _value = self.view.chat.ScrollView.ScrollbarVertical[CS.UnityEngine.UI.Scrollbar].value
	-- for i=1,10 do
	-- 	SGK.Action.DelayTime.Create(0.015*i):OnComplete(function()
	-- 	self.view.chat.ScrollView.ScrollbarVertical[CS.UnityEngine.UI.Scrollbar].value = (value/10)*i
 --        end)
	-- end
end

--IconFrameHelper.UpdateHero({pid = pid,sex = _PlayerData.Sex,headFrame = _PlayerData.HeadFrame},PLayerIcon)
function View:UpPlayerDialog(tempObj,story_id,reply_id,desc,role_id)
	local obj=SGK.UIReference.Setup(CS.UnityEngine.GameObject.Instantiate(tempObj,self.view.chat.ScrollView.Viewport.Content.transform))
	local next_story_id = nil
	if reply_id ~= nil then
		--print("zoe npcChat",sprinttb(self.npcDialogCfg[story_id]))
		obj.Right.Content.bg.desc[CS.InlineText].text = self.npcDialogCfg[story_id]["reply"..reply_id]
		next_story_id = self.npcDialogCfg[story_id]["reply_npc"..reply_id]
	end
	obj.Right.icon.transform.localScale=UnityEngine.Vector3(0.8,0.8,1)
	IconFrameHelper.Create(obj.Right.icon,{pid = playerModule.GetSelfID()})
	obj.Right.name[UI.Text].text=playerModule.Get().name
	obj.Right.gameObject:SetActive(true)
	obj.gameObject:SetActive(true)
	self.view.chat.ScrollView.ScrollbarVertical[CS.UnityEngine.UI.Scrollbar].value = 0
	for i=1,3 do
		self.view.chatItem["item"..i].gameObject:SetActive(false)
		self.view.chatItem["item"..i][UnityEngine.CanvasGroup].alpha=0
	end
	self.NPC_Chat_Record[#self.NPC_Chat_Record+1]={storyId = story_id,left = false,right = true,replyId = reply_id,isOver = false,rewardId = self.rewardQuest_topic_id}
	UserDefault.Save()
	if next_story_id == 0 then
		self:finishChat()
	else
		self.view.top.status[UI.Text].text="对方正在输入中..."
		self.view.chatItem["item4"].gameObject:SetActive(true)
	    self.view.chatItem["item4"][UnityEngine.CanvasGroup]:DOFade(1,0.4):SetDelay(0.1):OnComplete(function ()
	    	self.view.chatItem["item4"][UnityEngine.CanvasGroup]:DOFade(1,0.1):SetDelay(1.7):OnComplete(function ()
	    		self:UpNpcDialog(tempObj,next_story_id)
	    	end)
	    end)
	end
	-- coroutine.resume(coroutine.create(function()
	-- 	Sleep(2.0)
	-- 	self:UpNpcDialog(tempObj,next_story_id)
	-- end))
	
end
function View:UpNpcDialog(tempObj,story_id,role_id)
	self.view.top.status[UI.Text].text=self.npcCfg.name
	self.view.chatItem["item4"].gameObject:SetActive(false)
	self.view.chatItem["item4"][UnityEngine.CanvasGroup].alpha=0
	local obj=SGK.UIReference.Setup(CS.UnityEngine.GameObject.Instantiate(tempObj,self.view.chat.ScrollView.Viewport.Content.transform))
	obj.Left.Content.bg.desc[CS.InlineText].text = self.npcDialogCfg[story_id].text
	local npc_cfg = self.npcCfg
	obj.Left.icon[UI.Image]:LoadSprite("icon/"..npc_cfg.icon)
	obj.Left.icon.transform.localScale=UnityEngine.Vector3(1.05,1.05,1)
	obj.Left.name[UI.Text].text=npc_cfg.name
	obj.Left.gameObject:SetActive(true)
	obj.gameObject:SetActive(true)
	self.view.chat.ScrollView.ScrollbarVertical[CS.UnityEngine.UI.Scrollbar].value = 0
	self.NPC_Chat_Record[#self.NPC_Chat_Record+1]={storyId = story_id,left = true,right = false,replyId = 0,isOver = false,rewardId = self.rewardQuest_topic_id}
	UserDefault.Save()
	self:UpPlayerItem(story_id)
end
function View:UpPlayerItem(story_id)
	--print("zoezoe",self.rewardQuest_topic_id,sprinttb(self.npcDialogCfg[story_id]))
	local CompaleCount = 0
	for i=1,3 do
		if self.npcDialogCfg[story_id]["reply"..i] ~= "" then
			self.view.chatItem["item"..i].Text[UI.Text].text =self.npcDialogCfg[story_id]["reply"..i]
			CS.UGUIClickEventListener.Get(self.view.chatItem["item"..i].gameObject).onClick = function ()
        		self:UpPlayerDialog(self.view.chat.ScrollView.Viewport.Content.ChatObj.gameObject,story_id,i)
    		end
    		self.view.chatItem["item"..i].gameObject:SetActive(true)
		else
			self.view.chatItem["item"..i].gameObject:SetActive(false)
			CompaleCount=CompaleCount+1
		end
	end
	if CompaleCount == 0 then
		for i=1,3 do
    		self.view.chatItem["item"..i][UnityEngine.RectTransform].sizeDelta=UnityEngine.Vector2(687.1,93)
    		self.view.chatItem["item"..i][UnityEngine.CanvasGroup]:DOFade(1,0.5):SetDelay(0.2)
		end
	elseif CompaleCount == 1 then
		for i=1,2 do
    		self.view.chatItem["item"..i][UnityEngine.RectTransform].sizeDelta=UnityEngine.Vector2(687.1,113)
    		self.view.chatItem["item"..i][UnityEngine.CanvasGroup]:DOFade(1,0.5):SetDelay(0.2)
		end
	elseif CompaleCount == 2 then
		self.view.chatItem["item"..1][UnityEngine.RectTransform].sizeDelta=UnityEngine.Vector2(687.1,128)
    	self.view.chatItem["item"..1][UnityEngine.CanvasGroup]:DOFade(1,0.5):SetDelay(0.2)
	elseif CompaleCount == 3 then
		self:finishChat()
	end
end

function View:finishChat()
	if not self.NPC_Chat_Record[#self.NPC_Chat_Record].isOver then
		--print("zoezoe",self.rewardQuest_topic_id)
		QuestModule.Accept(self.rewardQuest_topic_id)
		if QuestModule.Get(self.rewardQuest_topic_id) and QuestModule.Get(self.rewardQuest_topic_id).status == 0 then
			QuestModule.Finish(self.rewardQuest_topic_id)
		end
		self.NPC_Chat_Record[#self.NPC_Chat_Record].isOver = true
		UserDefault.Save()
		--QuestModule.Finish(self.npcTopicCfg[self.npcCfg.npc_id][self.rewardQuest_topic_id].reward_quest)
		--showDlgError(nil, "对话完成")
	end
end

-- function View:Update()
-- 	print(self.view.chat.ScrollView.Viewport.Content.gameObject.transform:GetChild(13).position)
-- end

function View:OnDestory()
	--print("zoe npcChat界面destory")
end

function View:listEvent()
    return {
    "QUEST_INFO_CHANGE",
    }
end

function View:onEvent(event,data)
	if event == "QUEST_INFO_CHANGE" then
		print("zoe npcChat QUEST_INFO_CHANGE",sprinttb(data))
		if data.id == self.rewardQuest_topic_id then
			if data.status == 1 then
				self:initData()
				self:loadChatRecord(true)
				self:init()
			else
				QuestModule.Finish(self.rewardQuest_topic_id)
			end
		end
		if data and data.id == self.firstStageQuest then
			if data.status == 1 then
				self:initData()
				self:init()
			end
		end
	end
end


return View;