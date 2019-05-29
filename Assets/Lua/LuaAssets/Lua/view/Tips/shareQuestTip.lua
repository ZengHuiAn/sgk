local CooperationQuestModule = require "module.CooperationQuestModule"
local View={}
function View:Start(data)
	self.root = SGK.UIReference.Setup(self.gameObject);
	self.view = self.root.view

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function()
		UnityEngine.GameObject.Destroy(self.gameObject);
	end

	self:InitView(data)
end

function View:InitView(data)
	local _taskItem = self.view.shareTask
	local _quest_id,_pid,_inviteTime = data[1],data[2],data[3]
	--任务品质
	local _questCfg = module.QuestModule.GetCfg(_quest_id)
	if _questCfg then
		local _quality = _questCfg.quality or 1
		_taskItem[CS.UGUISpriteSelector].index = _quality-1
		for i=1,_taskItem.stars.transform.childCount do
			_taskItem.stars.transform:GetChild(i-1).gameObject:SetActive(i<=_quality)
		end

		_taskItem.questInfo.name.Text[UI.Text].text = _questCfg.name
		--是否为共享任务
		local cooperaQuest = CooperationQuestModule.GetCfg(_quest_id) or false
		_taskItem.questInfo.name.Image:SetActive(cooperaQuest)
		if cooperaQuest then
			local _questCfg2 = module.QuestModule.GetCfg(cooperaQuest.share_id)
			if _questCfg2 then
				--怪物形象
				local mode = string.sub(_questCfg2.condition[1].id,2,6)
				local bossAnim = _taskItem.Image.bossAnim[CS.Spine.Unity.SkeletonGraphic]
				if mode and bossAnim then
					bossAnim.skeletonDataAsset = nil;
					bossAnim:Initialize(true)
					SGK.ResourcesManager.LoadAsync(bossAnim, string.format("roles/%s/%s_SkeletonData.asset", mode, mode), function(o)
						if o ~= nil then
							bossAnim.skeletonDataAsset = o
							local _pos, _scale = DATABASE.GetBattlefieldCharacterTransform(tostring(mode), "taskMonster")
					
							if _pos and _scale then
								bossAnim.transform.localPosition =  _pos+Vector3(0,-10,0)
								bossAnim.transform.localScale = _scale
							end
							bossAnim:Initialize(true)
						else
							SGK.ResourcesManager.LoadAsync(bossAnim, string.format("roles/11000/11000_SkeletonData.asset"), function(o)
								bossAnim.skeletonDataAsset = o
								local _pos, _scale = DATABASE.GetBattlefieldCharacterTransform(tostring(11000), "taskMonster")
								if _pos and _scale then
									bossAnim.transform.localPosition =  _pos+Vector3(0,-10,0)
									bossAnim.transform.localScale = _scale
								end
								bossAnim:Initialize(true);
							end);
						end
					end);
				end
			else
				ERROR_LOG("quest cfg is nil,id",cooperaQuest.share_id)
			end

			--任务奖励
			for i=1,_taskItem.questInfo.rewards.transform.childCount do
				_taskItem.questInfo.rewards.transform:GetChild(i-1).gameObject:SetActive(false)
			end

			for i=1,#cooperaQuest.reward do
				if cooperaQuest.reward[i].type ~= 0 and cooperaQuest.reward[i].id ~= 0 and cooperaQuest.reward[i].value ~= 0 then
					local itemCfg = utils.ItemHelper.Get(cooperaQuest.reward[i].type,cooperaQuest.reward[i].id,nil,cooperaQuest.reward[i].value)
					if itemCfg and _taskItem.questInfo.rewards[i] then
						local rewardItem = _taskItem.questInfo.rewards[i]
						rewardItem:SetActive(true)
						utils.IconFrameHelper.Create(rewardItem, {customCfg = itemCfg})
					end
				end
			end

			if module.playerModule.IsDataExist(_pid) then
				local _cfg = module.playerModule.Get(_pid);
				if _cfg then
					_taskItem.questInfo.friendTip.Text[UI.Text].text = _cfg.name
					utils.IconFrameHelper.Create(_taskItem.questInfo.friendTip.IconFrame, {pid = _pid});
				end
			else            
				module.playerModule.Get(_pid,function ( ... )
					local _cfg=module.playerModule.Get(_pid);
					if _cfg then
						_taskItem.questInfo.friendTip.Text[UI.Text].text = _cfg.name
						utils.IconFrameHelper.Create(_taskItem.questInfo.friendTip.IconFrame, {pid = _pid});
					end
				end)
			end
			--任务条件
			if _taskItem.questInfo.conditions[1] then
				local _targetCount = _questCfg.condition[1].count
				_taskItem.questInfo.conditions[1].Text[UI.Text].text = _questCfg.desc
				_taskItem.questInfo.conditions[1].num[UI.Text].text = string.format("%s/%s",0,_targetCount)
				_taskItem.questInfo.conditions[1].progress[UI.Image].fillAmount = 0

				module.QuestModule.GetOtherQuest(_pid,_quest_id,cooperaQuest.share_id,nil,function ()
					local _questInfo = module.QuestModule.GetOtherQuest(_pid,_quest_id,cooperaQuest.share_id)
					if _questInfo then
						_taskItem.questInfo.conditions[1]:SetActive(true)
						local _finishedCount = _questInfo.records and _questInfo.records[1] or 0

						_taskItem.questInfo.conditions[1].num[UI.Text].text = string.format("%s/%s",_finishedCount,_targetCount)
						_taskItem.questInfo.conditions[1].progress[UI.Image].fillAmount = _finishedCount/_targetCount
					end
				end)
			end
			
			if _questCfg2 and _taskItem.questInfo.conditions[2] then
				local _targetCount = _questCfg2.condition[1].count
				_taskItem.questInfo.conditions[2].Text[UI.Text].text = _questCfg2.desc
				
				_taskItem.questInfo.conditions[2]:SetActive(true)
				_taskItem.questInfo.conditions[2].num[UI.Text].text = string.format("%s/%s",0,_targetCount)
				_taskItem.questInfo.conditions[2].progress[UI.Image].fillAmount = 0
			end

			CS.UGUIClickEventListener.Get(_taskItem.Btns.refuseBtn.gameObject).onClick = function()
				CooperationQuestModule.Refuse(_pid)
				UnityEngine.GameObject.Destroy(self.gameObject);
			end

			CS.UGUIClickEventListener.Get(_taskItem.Btns.acceptBtn.gameObject).onClick = function()
				if _inviteTime and _inviteTime+60*30< module.Time.now() then
					showDlgError(nil,"任务已过期")
					CooperationQuestModule.Refuse(_pid)
				else
					showDlgError(nil,"已申请协助")
					CooperationQuestModule.Accept(_pid,_quest_id)
				end
				UnityEngine.GameObject.Destroy(self.gameObject);
			end
		else
			ERROR_LOG("非共享任务")
		end
	else
		ERROR_LOG("_questCfg is nil id",_quest_id)
	end
end


return View;
