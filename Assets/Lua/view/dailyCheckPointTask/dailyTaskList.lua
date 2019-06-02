local ItemHelper = require "utils.ItemHelper"
local battle_config = require "config/battle";
local QuestModule = require "module.QuestModule"
local CooperationQuestModule = require "module.CooperationQuestModule"
local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view =  self.root.view;
    self.Pid = module.playerModule.GetSelfID();

	self:InitView();
	self:initGuide()
end

function View:initGuide()
    module.guideModule.PlayByType(114,0.2)
end

local taskType = 22
local _localimer = 0
function View:InitView()
	self.view.Title.Text[UI.Text].text = SGK.Localize:getInstance():getValue("lilianbiji_biaoti1")
	self.view.tip[UI.Text].text = SGK.Localize:getInstance():getValue("lilianbiji_reset_info")
	self.view.tip2[UI.Text].text = SGK.Localize:getInstance():getValue("lilianbiji_tip12")

	CS.UGUIClickEventListener.Get(self.view.helpBtn.gameObject).onClick = function()
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("lilianbiji_help_tip"))
	end

	CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/base/CurrencyChat.prefab"),self.root.transform)
	
	local cooperaQuestList = CooperationQuestModule.Get()
	
	if cooperaQuestList then
		self:InTaskContent()
	end
end

local function GetCopyUIItem(parent,prefab,i)
    local obj = nil
    if i <= parent.transform.childCount then
        obj = parent.transform:GetChild(i-1).gameObject
    else
        obj = CS.UnityEngine.GameObject.Instantiate(prefab.gameObject,parent.gameObject.transform)
        obj.transform.localPosition = Vector3.zero
    end
    obj:SetActive(true)
    local item = CS.SGK.UIReference.Setup(obj)
    return item
end

function View:UpdateRewardInfo(_rewards,item)
	if _rewards then
		self.view.transform:DOScale(Vector3.one,0.5):OnComplete(function( ... )
			for i=1,#_rewards do
				if _rewards[i].type ~= 0 and _rewards[i].id ~= 0 and _rewards[i].value ~= 0 then
					local itemCfg = ItemHelper.Get(_rewards[i].type,_rewards[i].id,nil,_rewards[i].value)
					if itemCfg then
						local rewardItem = item.questItem.questInfo.rewards[i]
						if rewardItem then
							rewardItem:SetActive(true)
							utils.IconFrameHelper.Create(rewardItem, {customCfg = itemCfg,showDetail = true})
						end
					end
				end
			end
		end)
	end
end

local function playAnim(bossAnim,mode)
	bossAnim.initialSkinName = "default"
	-- bossAnim.startingAnimation = "idle"
	local _pos, _scale = DATABASE.GetBattlefieldCharacterTransform(tostring(mode), "taskMonster")
	if _pos and _scale then
		bossAnim.transform.localPosition =  _pos+Vector3(0,-10,0)
		bossAnim.transform.localScale = _scale
	end
end

function View:upAnim(bossAnim,mode)
	if bossAnim.skeletonDataAsset and bossAnim.skeletonDataAsset.name == mode.."_SkeletonData" then
		playAnim(bossAnim,mode)
		return
	else
		SGK.ResourcesManager.LoadAsync(bossAnim, string.format("roles/%s/%s_SkeletonData.asset", mode, mode), function(o)
			if o ~= nil then
				bossAnim.skeletonDataAsset = o
				playAnim(bossAnim,mode)
				bossAnim:Initialize(true)
			else
				SGK.ResourcesManager.LoadAsync(bossAnim, string.format("roles/11000/11000_SkeletonData.asset"), function(o)
					bossAnim.skeletonDataAsset = o
					playAnim(bossAnim,11000)
					bossAnim:Initialize(true);
				end);
			end
		end);
	end
end

function View:UpdateBaseInfo(item,quest)
	--任务品质
	local _quality = quest.quality or 1
	item.questItem[CS.UGUISpriteSelector].index = _quality-1
	for i=1,item.questItem.stars.transform.childCount do
		item.questItem.stars.transform:GetChild(i-1).gameObject:SetActive(i<=_quality)
	end
	--怪物形象
	--历练任务 显示 怪物 取后4位
	local mode = tonumber(string.sub(quest.cfg.condition[1].id,-4,-1))+10000

	local bossAnim = item.questItem.Image.bossAnim[CS.Spine.Unity.SkeletonGraphic]
	if mode and bossAnim then
		self:upAnim(bossAnim,mode)
	end
	item.questItem.questInfo.name.Text[UI.Text].text = quest.name
end

local function InQuestContidition(item,quest,targetCount,_finishedCount,showOwner)
	item:SetActive(true)
	item.Text[UI.Text].text = (showOwner == 1 and "自己:" or showOwner == 2 and "好友：" or "")..quest.desc
	item.num[UI.Text].text = string.format("%s/%s",_finishedCount,targetCount)
	item.progress[UI.Image].fillAmount = _finishedCount/targetCount
end

local changeCD = 60*30
function View:UpdateCondition(item,cooperaQuest,quest,share_id,partnerPid,cooperaInfo)
	item.questItem.questInfo.conditions[1]:SetActive(true)
	item.questItem.questInfo.conditions[1].Text[UI.Text].text = quest.desc

	--任务条件
	local targetCount = quest.condition[1].count
	local finishedCount = quest.records[1]
	local _item = item.questItem.questInfo.conditions[1]
	InQuestContidition(_item,quest,targetCount,finishedCount,cooperaQuest and 1)

	if cooperaQuest then
		--更换好友
		item.questItem.bottom.friendTip.changeBtn:SetActive(partnerPid and cooperaQuest.share ==1)
		--添加好友
		item.questItem.bottom.addTip:SetActive(not partnerPid and cooperaQuest.share ==1)
		item.questItem.bottom.friendTip:SetActive(partnerPid) 
		--前往
		item.Btns.goToBtn:SetActive(quest.status==0)
		item.Btns.ensureBtn:SetActive(false)
		if partnerPid then
			--合作伙伴头像
			if module.playerModule.IsDataExist(partnerPid) then
				local _playerData = module.playerModule.Get(partnerPid);
				item.questItem.bottom.friendTip.Text[UI.Text].text = _playerData.name
				utils.IconFrameHelper.Create(item.questItem.bottom.friendTip.IconFrame, {pid = partnerPid})
				CS.UGUIClickEventListener.Get(item.questItem.bottom.friendTip.IconFrame.gameObject).onClick = function()
					DialogStack.PushPrefStact("FriendSystemList",{idx = 1,viewDatas = {{pid = partnerPid,name = _playerData.name}}})
				end
			else
				module.playerModule.Get(partnerPid,function ( ... )
					local _playerData = module.playerModule.Get(partnerPid);
					item.questItem.bottom.friendTip.Text[UI.Text].text = _playerData.name
					utils.IconFrameHelper.Create(item.questItem.bottom.friendTip.IconFrame, {pid = partnerPid})
					CS.UGUIClickEventListener.Get(item.questItem.bottom.friendTip.IconFrame.gameObject).onClick = function()
						DialogStack.PushPrefStact("FriendSystemList",{idx = 1,viewDatas = {{pid = partnerPid,name = _playerData.name}}})
					end
				end)
			end
			local _partnerQuestId = cooperaQuest.share ==1 and quest.id or share_id
		
			local _quest = QuestModule.GetOtherQuest(partnerPid,share_id,quest.id)
			if _quest then
				local _questCfg = QuestModule.GetCfg(share_id)
				if _questCfg then
					local _targetCount = _questCfg.condition and _questCfg.condition[1].count or 0
					local _finishedCount = _quest.records and _quest.records[1] or 0
					local __item = item.questItem.questInfo.conditions[2]
					__item:SetActive(true)
					InQuestContidition(__item,_questCfg,_targetCount,_finishedCount,2)

					item.Btns.ensureBtn:SetActive(cooperaQuest.share ==1 and cooperaInfo.status==0 and quest.status == 1 and _quest.status == 1)
				else
					ERROR_LOG(" __questCfg is nil",share_id)
				end
				item.questItem.finishTip:SetActive(cooperaInfo and cooperaInfo.status==1)
			else
				-- ERROR_LOG("_questCfg is nil",partnerPid,share_id,_partnerQuestId)
			end
			--放弃
			if cooperaInfo then
				CS.UGUIClickEventListener.Get(item.Btns.giveUpBtn.gameObject).onClick = function()
					item.Btns.giveUpBtn[CS.UGUIClickEventListener].interactable = false
					CooperationQuestModule.Cancel(cooperaInfo.quest_id,cooperaQuest.share)
				end
			end
			
			--更换好友
			CS.UGUIClickEventListener.Get(item.questItem.bottom.friendTip.changeBtn.gameObject).onClick = function()
				if cooperaInfo and cooperaInfo.acceptTime and cooperaInfo.acceptTime+ changeCD>=module.Time.now() then
					local _time = changeCD+cooperaInfo.acceptTime-module.Time.now()
					local _showTime = GetTimeFormat(_time,2,3)
					showDlgError(nil,string.format("%s 后可更换好友",_showTime))
				else
					DialogStack.PushPrefStact("dailyCheckPointTask/friendList",{quest.id,cooperaQuest.share_id})
				end
			end
		else--任务未共享
			local _questCfg = QuestModule.GetCfg(cooperaQuest.share_id)
			if _questCfg then
				local _targetCount = _questCfg.condition[1].count
				local _finishedCount = 0
				--local __item = item.questItem.questInfo.conditions[2]
				local __item = GetCopyUIItem(item.questItem.questInfo.conditions,item.questItem.questInfo.conditions[1],2)
				InQuestContidition(__item,_questCfg,_targetCount,_finishedCount,2)
			else
				ERROR_LOG("quest cfg is nil,id",cooperaQuest.share_id)
			end
			item.Btns.ensureBtn:SetActive(false)
			--非共享任务 完成 或者 共享任务是发起方
			item.questItem.finishTip:SetActive(false)
			--邀请功能
			if cooperaQuest.share ==1 then
				item.questItem.bottom.addTip.Text[UI.Text].text = SGK.Localize:getInstance():getValue("lilianbiji_tip1")
				--邀请好友
				CS.UGUIClickEventListener.Get(item.questItem.bottom.addTip.Add.gameObject).onClick = function()
					DialogStack.PushPrefStact("dailyCheckPointTask/friendList",{quest.id,cooperaQuest.share_id})
				end
			end 
		end
	else
		--非共享任务
		self:UpdateBaseInfo(item,quest)
		--任务奖励
		self:UpdateRewardInfo(quest.reward,item)

		item.Btns.ensureBtn:SetActive(quest.status==0 and finishedCount>=targetCount)
		--非共享任务 完成 或者 共享任务是发起方
		item.questItem.finishTip:SetActive(quest.status==1)
		--前往
		item.Btns.goToBtn:SetActive(quest.status==0 and finishedCount<targetCount)
	end
end

function View:updateQuestItem(item,quest)
	if (quest.status ~= 0 and quest.status ~= 1) then
		item:SetActive(false)
		self.TaskList[quest.id] = nil
		return
	end
	--是否为共享任务
	local cooperaQuest = CooperationQuestModule.GetCfg(quest.id) or false
	--他人共享的任务 才能 放弃
	item.Btns.giveUpBtn:SetActive(cooperaQuest and cooperaQuest.share and cooperaQuest.share==2)
	if item.Btns.giveUpBtn[CS.UGUIClickEventListener] then
		item.Btns.giveUpBtn[CS.UGUIClickEventListener].interactable = true
	end
	ERROR_LOG(quest.id,cooperaQuest)
	if cooperaQuest then
		item.questItem.questInfo.name.Image:SetActive(cooperaQuest)
		if cooperaQuest.share ==2 then
			local cooperaInfo = CooperationQuestModule.Get(nil,quest.id,cooperaQuest.share)
			if cooperaInfo and cooperaInfo.quest_id~=0 and cooperaInfo.pid~= 0 then
				local _quest = QuestModule.Get(cooperaInfo.share_id)
				if _quest then
					self:UpdateBaseInfo(item,_quest)
					self:UpdateCondition(item,cooperaQuest,_quest,cooperaInfo.quest_id,cooperaInfo.pid,cooperaInfo)
				else
					ERROR_LOG("quest cfg is nil,id",cooperaInfo.quest_id)
				end
				--完成状态的任务不能放弃
				item.Btns.giveUpBtn:SetActive(cooperaInfo.status ~=1)
			else
				item.Btns.giveUpBtn:SetActive(false)
				ERROR_LOG("cooperaInfo is nil")
			end
		else
			self:UpdateBaseInfo(item,quest)
			--任务条件
			local cooperaInfo = CooperationQuestModule.Get(nil,quest.id,cooperaQuest.share)
			if cooperaInfo and cooperaInfo.partnerPid~=0  then
				self:UpdateCondition(item,cooperaQuest,quest,cooperaQuest.share_id,cooperaInfo.partnerPid,cooperaInfo)
			else
				self:UpdateCondition(item,cooperaQuest,quest,cooperaQuest.share_id)
			end	
		end
		--任务奖励
		self:UpdateRewardInfo(cooperaQuest.reward,item)
	else
		self:UpdateCondition(item,cooperaQuest,quest)
	end

	item.questItem.questInfo.name.Image:SetActive(cooperaQuest)
	item.questItem.bottom:SetActive(cooperaQuest)
	-- self:UpdateQuestInfo(item,quest.id)
	--前往
	CS.UGUIClickEventListener.Get(item.Btns.goToBtn.gameObject).onClick = function()
		DialogStack.PushPref("dailyCheckPointTask/checkPointList",quest.id)
	end
	--完成任务
	CS.UGUIClickEventListener.Get(item.Btns.ensureBtn.gameObject).onClick = function()
		if cooperaQuest then
			CooperationQuestModule.Finish(quest.id)
		else
			QuestModule.Finish(quest.id)
		end
	end
end

function View:InTaskContent()
	_localimer = 0
	self.TaskList = {}
	local questList = QuestModule.GetList(taskType)--每日副本任务
	local _questList = {}
	local startTime = os.time({day=CS.System.DateTime.Now.Day, month = CS.System.DateTime.Now.Month, year = CS.System.DateTime.Now.Year, hour = 0, minute = 0, second = 0})
	for i,v in ipairs(questList) do
		if v.accept_time >= startTime and (v.status == 0 or v.status == 1) then
			table.insert(_questList,v)
		end
	end
	
	table.sort(_questList,function (a,b)
		return a.id<b.id
	end)

	local taskContent = self.view.ScrollView.Viewport.Content
	for i=1,#_questList do
		local item = GetCopyUIItem(taskContent,taskContent[1],i)
		if item then
			self.TaskList[_questList[i].id] = item
			self:updateQuestItem(item,_questList[i])
		end
	end
end

local _interval = 60
function View:Update()
	_localimer = _localimer + UnityEngine.Time.deltaTime
	if _localimer>= _interval then
		self:InTaskContent()
	end
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end
function View:OnDestroy()
	DispatchEvent("UPDATE_LOCAL_NOTE_REDDOT")
end

function View:listEvent()
	return {
		"QUEST_INFO_CHANGE",
		"LOCAL_GUIDE_CHANE",

		"COOPERAQUEST_LIST_CHANGE",
		"COOPERAQUEST_INFO_CHANGE",
	}
end

function View:onEvent(event,data)
	if event == "QUEST_INFO_CHANGE"  then
		if data and data.id and self.TaskList and self.TaskList[data.id] then
			self.questChangeTip = self.questChangeTip or {}
			if not self.questChangeTip[data.id] then
				local _quest = module.QuestModule.Get(data.id)
				if _quest then
					self:updateQuestItem(self.TaskList[data.id],_quest)
				else
					ERROR_LOG("_quest is nil ",data.id)
				end
				self.questChangeTip[data.id] = 1
				self.view.transform:DOScale(Vector3.one,0.5):OnComplete(function( ... )
					self.questChangeTip[data.id] = nil
				end)
			else
				if self.questChangeTip[data.id]>=2 then
					return
				end
				self.questChangeTip[data.id] = self.questChangeTip[data.id]+1
				self.view.transform:DOScale(Vector3.one,0.5):OnComplete(function( ... )
					local _quest = module.QuestModule.Get(data.id)
					if _quest then
						self:updateQuestItem(self.TaskList[data.id],_quest)
					else
						ERROR_LOG("_quest is nil ",data.id)
					end
					self.questChangeTip[data.id] = nil
				end)
			end
		end

	elseif event == "COOPERAQUEST_LIST_CHANGE" then
		if data and data == self.Pid then
			self:InTaskContent()
		end
	elseif event == "LOCAL_GUIDE_CHANE" then
		self:initGuide()
	elseif event == "COOPERAQUEST_INFO_CHANGE" then
		if data and data[1] and data[2] and data[2] == self.Pid and self.TaskList then
			if self.TaskList[data[1]] then
				local _quest = module.QuestModule.Get(data[1])
				if _quest then
					self:updateQuestItem(self.TaskList[data[1]],_quest)
				else
					ERROR_LOG("_quest is nil ",data[1])
				end
			else
				local _quest = module.QuestModule.Get(data[1])
				if _quest and (_quest.status ==0 or _quest.status ==1) then
					local taskContent = self.view.ScrollView.Viewport.Content
					local _idx = 1
					for k,v in pairs(self.TaskList) do
						_idx = _idx+1
					end
					if taskContent and taskContent[1] then
						local item = GetCopyUIItem(taskContent,taskContent[1],_idx)
						if item then
							self.TaskList[_quest.id] = item
							self:updateQuestItem(item,_quest)
						end
					end
				else
					ERROR_LOG("_quest is nil ",_quest and _quest.status,sprinttb(_quest))
				end
			end
		end
	end
end

return View;