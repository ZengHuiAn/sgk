local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"

local View={}
local StatisticsValue = {}
local initPubReward = 0
function View:Start()
	self.view = SGK.UIReference.Setup(self.gameObject);

	CS.UGUIClickEventListener.Get(self.view.bottom.Exit.gameObject).onClick = function (obj)
		SceneStack.Pop();
	end

	CS.UGUIClickEventListener.Get(self.view.rollTip.Exit.gameObject).onClick = function (obj)
		SceneStack.Pop();
	end

	self.view.Record:SetActive(self.team_fight_id ~= 11701)
	CS.UGUIClickEventListener.Get(self.view.Record.gameObject).onClick = function (obj)
		if next(StatisticsValue) then
			self.view.bottom.Exit.timer:SetActive(false)
			DialogStack.PushPrefStact("fightResult/StatisticsFrame",StatisticsValue)
		end
	end

	-- CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick = function (obj) 
	-- 	SceneStack.Pop();
	-- end

	CS.UGUIClickEventListener.Get(self.view.rollTip.rollBtn.gameObject).onClick = function (obj) 
		initPubReward = initPubReward+1
		DialogStack.Push("fightResult/PubReward",initPubReward,"UGUIRoot")
		self.ShowRollData = nil
		self.exit_turn = 9999
		self.view.rollTip.rollBtn.timer:SetActive(false)
	end

	if module.TeamModule.GetTeamPveFightId() then
		self.team_fight_id = module.TeamModule.GetTeamPveFightId()
		local teamPveFightCfg = SmallTeamDungeonConf.GetTeam_pve_fight_gid(self.team_fight_id)
		if teamPveFightCfg and teamPveFightCfg.fight_type and teamPveFightCfg.fight_type ==4 then
			self.exit_left = 8
		end
	end
end

function View:Init(data)
	local winner = data and data[1]
	local args = data and data[2]

	local win = winner ==1

	self.win = win
	
	if win then
		DispatchEvent("LOCAL_FIGHT_RESULT_WIN")
		SGK.ResourcesManager.LoadAsync("sound/victory 5.mp3",typeof(UnityEngine.AudioClip),function (Audio)
			self.view[UnityEngine.AudioSource].clip = Audio
			self.view[UnityEngine.AudioSource]:Play()
		end)
		
		local replay_fight_info = args and args.replay_fight_info
		local next_fight_info = args and args.next_fight_info

		self:SetFightBtnShow(replay_fight_info,next_fight_info)

		self.gid = args.fight_id
		self.localFightResult = true
	else
		SGK.ResourcesManager.LoadAsync("prefabs/fightResult/failedFrame.prefab", function(o)
			local panel = SGK.UIReference.Instantiate(o)
			panel.transform:SetParent(self.view.node.transform,false)

			local replay_fight_info = args and args.replay_fight_info
			panel[SGK.LuaBehaviour]:Call("SetReplayInfo",replay_fight_info)
			self.result_panel_used = panel
		end)
		self.localFightResult = false
	end

	self.view.transform:DOScale(Vector3.one,3):OnComplete(function ( ... )
		SetItemTipsState(true)
		if 	not self.view.bottom.activeSelf and not self.view.rollTip.activeSelf then
			self:updateBottom()
		end
	end)
end

function View:SetFightBtnShow(replay_fight_info,next_fight_info)
	self.view.bottom.NextFight:SetActive(not not next_fight_info);
	self.view.bottom.TryAgain:SetActive(not not replay_fight_info)

	if next_fight_info and next_fight_info.id then
		local pveCfg = module.fightModule.GetConfig(nil, nil, next_fight_info.id)
		self.view.bottom.NextFight[CS.UGUISpriteSelector].index = pveCfg and pveCfg.cost_item_value > module.ItemModule.GetItemCount(90010) and 1 or 0
		CS.UGUIClickEventListener.Get(self.view.bottom.NextFight.gameObject).onClick = function (obj)
			if pveCfg and pveCfg.cost_item_value <= module.ItemModule.GetItemCount(90010) or not pveCfg then	
				local cfg = module.fightModule.GetPveConfig(next_fight_info.id)
				local before_fight_story = cfg and cfg._data.story_id

				if cfg and before_fight_story and before_fight_story ~= 0 then
					self.view:SetActive(false)
					LoadStory(before_fight_story,nil, nil, function()
						SGK.BackgroundMusicService.PlayMusic()
						module.fightModule.StartFight(next_fight_info.id);
					end)
				else
					SGK.BackgroundMusicService.PlayMusic()
					module.fightModule.StartFight(next_fight_info.id);
				end
			else
				showDlgError(nil, SGK.Localize:getInstance():getValue("fuben_cishubuzu"))
			end
		end
	end

	if replay_fight_info and replay_fight_info.id then
		self.view.bottom.TryAgain.Text[UI.Text].text = SGK.Localize:getInstance():getValue("fube_chongxinzhandou")
		local pveCfg = module.fightModule.GetConfig(nil, nil, replay_fight_info.id)
		local fightInfo = module.fightModule.GetFightInfo(replay_fight_info.id)
		
		self.view.bottom.TryAgain[CS.UGUISpriteSelector].index = 0
		if pveCfg.count_per_day - fightInfo.today_count <= 0  or pveCfg.cost_item_value > module.ItemModule.GetItemCount(90010) then
			self.view.bottom.TryAgain[CS.UGUISpriteSelector].index = 1
		end

		CS.UGUIClickEventListener.Get(self.view.bottom.TryAgain.gameObject).onClick = function()
			if pveCfg.count_per_day <= fightInfo.today_count then
				showDlgError(nil, SGK.Localize:getInstance():getValue("fuben_cishubuzu"))
			else
				SGK.BackgroundMusicService.PlayMusic()

				if pveCfg and pveCfg.cost_item_value <= module.ItemModule.GetItemCount(90010) or not pveCfg then
					module.fightModule.StartFight(replay_fight_info.id);
				else
					showDlgError(nil, SGK.Localize:getInstance():getValue("fuben_tilibuzu"))
				end
			end
		end
	end
end

--设置特殊战斗
function View:SetResultType(data)
	if not self.fightInfo then
		if data[1] and next(data[1]) then
			self.fightInfo = data
		end
		if data[2] then
			self.view[UnityEngine.Animator]:SetInteger("type",data[2]);
			self.view[UnityEngine.Animator].enabled = true
		end
	end
end

function View:SetStatisticsValue(value)
	StatisticsValue = value
end

function View:AddResultObject(resultObject)
	self.resultObject = resultObject
end

function View:UpdateReward(rewards)
	if not rewards or not next(rewards) then
		if self.win then
			self.view.resultInfo.Image:SetActive(false)
		end
		return 
	end
	self.view.resultInfo.Image:SetActive(true)
	DispatchEvent("ADD_FILTER_REWARDS",rewards)--战斗获得奖励
	print("战斗奖励",rewards and sprinttb(rewards))
	self.rewards = {}
	if rewards and next(rewards)~=nil then
		for i=1,#rewards do
			local type,id = rewards[i][1],rewards[i][2]
			if type== utils.ItemHelper.TYPE.EQUIPMENT or type== utils.ItemHelper.TYPE.INSCRIPTION or type== utils.ItemHelper.TYPE.HERO then
				table.insert(self.rewards,rewards[i])
			elseif type == 44 then
				coroutine.resume(coroutine.create(function()
					local data = utils.NetworkService.SyncRequest(428, {nil, id})
					if data and data[3] and next(data[3]) then
						for j=1,#data[3] do
							table.insert(self.rewards,data[3][j])
						end
					end
				end))
			elseif type ~= utils.ItemHelper.TYPE.HERO_ITEM then
				local itemconf = module.ItemModule.GetConfig(id)
				if not itemconf then
				 	print("道具id->"..id.."在item表中不存在。")
				elseif itemconf and itemconf.is_show == 0 then
					print("isShow",is_show)
				else
					table.insert(self.rewards,rewards[i])
				end
			end	
		end	
	end
end
--特殊战斗
function View:UpdateResultFrame(Info)
	if self.view.node.transform.gameObject.activeSelf then
		self.fightInfo = nil

		local resultInfo = Info and Info[1]
		local anima_type = Info and Info[2]
		local IsTeam = Info and Info[3]
		if self.localFightResult then
			if anima_type == 2 then
				SGK.ResourcesManager.LoadAsync("prefabs/fightResult/teamResultFrame.prefab", function(o)
					self.result_panel_used = SGK.UIReference.Instantiate(o)
					self.result_panel_used.transform:SetParent(self.view.node.transform,false)
					self.result_panel_used[SGK.LuaBehaviour]:Call("Init",resultInfo)
				end)
			else
				SGK.ResourcesManager.LoadAsync("prefabs/fightResult/starsResultFrame.prefab", function(o)
					self.result_panel_used = SGK.UIReference.Instantiate(o)
					self.result_panel_used.transform:SetParent(self.view.node.transform,false)
					self.result_panel_used[SGK.LuaBehaviour]:Call("Init",resultInfo)
				end)
			end
		else
			if not IsTeam and resultInfo and next(resultInfo) then
				self.result_panel_used[SGK.LuaBehaviour]:Call("updateResultShow",resultInfo)
			end
		end
	end
end

function View:UpdateRewardShow(rewards)
	if self.view.node.gameObject.activeSelf and self.result_panel_used or self.view.resultInfo.gameObject.activeSelf then
		local rewardPanelNode = self.result_panel_used and self.result_panel_used.mid and self.result_panel_used.mid.RewardContent or self.view.resultInfo.RewardContent
		if rewardPanelNode.gameObject.activeSelf then
			self.rewards = nil
			local rewardsPanel = nil 
			if rewards and next(rewards) then
				if rewardPanelNode.transform.childCount == 0  then
					SGK.ResourcesManager.LoadAsync("prefabs/fightResult/rewardsFrame.prefab", function(o)
						local _obj = SGK.UIReference.Instantiate(o)
						_obj.transform:SetParent(rewardPanelNode.gameObject.transform,false)
						rewardsPanel = SGK.UIReference.Setup(_obj)
						rewardsPanel[SGK.LuaBehaviour]:Call("UpdateReward",rewards)
					end)
				else	
					rewardsPanel = SGK.UIReference.Setup(rewardPanelNode.transform:GetChild(0).gameObject)
					rewardsPanel[SGK.LuaBehaviour]:Call("UpdateReward",rewards)
				end

			end
		end
	end	
end

function View:updateResultObject(resultObject)
	if self.view.resultInfo.activeSelf then
		self.resultObject = nil

		local _parent = self.view.resultInfo
		resultObject.transform:SetParent(_parent.transform, false);
		if resultObject.gameObject:GetComponent("CanvasGroup") then
			resultObject:GetComponent(typeof(UnityEngine.CanvasGroup)).alpha =  0
			resultObject:GetComponent(typeof(UnityEngine.CanvasGroup)):DOFade(1,0.2)--:SetDelay(2)
		end

		local _off_y = -45--self.localFightResult and -145 or -45
		resultObject.transform.localPosition = Vector3(0,_off_y,0)
	    resultObject:SetActive(true);
	end
end

function View:UpdatePubRewardData(ExtraSpoilsAndRollData)
	self.ShowExtraSpoilsData = ExtraSpoilsAndRollData[1]
	self.ShowRollData = ExtraSpoilsAndRollData[2]
	print("幸运币和 公共掉落",ExtraSpoilsAndRollData[1],ExtraSpoilsAndRollData[2])
end

function View:updateBottom()
	if self.ShowRollData or self.ShowExtraSpoilsData then	
		self.view.bottom:SetActive(not self.ShowRollData)
		if self.ShowRollData then
			self.exit_turn = 3;
			self.view.rollTip:SetActive(true)
		end

		if self.ShowExtraSpoilsData then
			local showLuckyCoin = false
			if self.team_fight_id then--有幸运币产出 才会出现幸运币
				local waveConfig = SmallTeamDungeonConf.GetTeamPveMonsterList(self.team_fight_id)
				if waveConfig then
					for k,v in pairs(waveConfig) do
						if v.show_itemid1~=0 then
							showLuckyCoin = true
							break
						end
					end
				else
					ERROR_LOG("waveConfig is nil,id",self.team_fight_id)
				end
			else
				ERROR_LOG(" self.team_fight_id is nil ",self.team_fight_id)
			end
			if showLuckyCoin then
				DialogStack.PushPref("fightResult/luckyCoin",nil,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject)
			end
		end
		-- self.exit_left = 9999;
		self.ShowRollData = nil
		self.ShowExtraSpoilsData = nil
	else	
		if not self.Data then
			self.view.bottom:SetActive(true)
			-- self.exit_left = 5;
		else
			self.view.rollTip.Exit:SetActive(true)
			self.view.rollTip.rollBtn.timer:SetActive(false)
			self.view.bottom.Exit.timer:SetActive(false)
			self.exit_turn = 99999
		end
	end
end

function View:Update()
	if self.rewards then
		self:UpdateRewardShow(self.rewards)
	end
	
	if self.fightInfo then
		self:UpdateResultFrame(self.fightInfo)
	end
		
	if self.resultObject then
		self:updateResultObject(self.resultObject)	
	end


	if self.exit_left and self.exit_left<1000 then
		if not self.view.bottom.Exit.timer.gameObject.activeSelf then
			self.view.bottom.Exit.timer:SetActive(true)
		end
		if self.exit_left>=0 then
			self.exit_left=self.exit_left-UnityEngine.Time.deltaTime
			self.view.bottom.Exit.timer[UI.Text].text=string.format("%s秒后自动退出",math.ceil(self.exit_left))
		else
			self.exit_left = nil
			SceneStack.Pop();
		end
	end


	if self.exit_turn and self.exit_turn< 1000 then
		if self.exit_turn>= 0 then
			self.exit_turn = self.exit_turn-UnityEngine.Time.deltaTime
			self.view.rollTip.rollBtn.timer[UI.Text].text=string.format("%s秒后自动打开",math.ceil(self.exit_turn))
		else
			initPubReward = initPubReward+1
			DialogStack.Push("fightResult/PubReward",initPubReward)
			self.ShowRollData = nil
			self.exit_turn = 9999
			self.view.rollTip.rollBtn.timer:SetActive(false)
		end
	end
end
function View:OnDestroy( ... )
	if self.Data then
		module.TeamModule.SetPubRewardData({})
		DispatchEvent("Roll_Query_Respond")
	end

	if self.team_fight_id == 11701 then
		--移除临时TeamPveFightId
		module.TeamModule.GetTeamPveFightId(0)
	end
end

function View:listEvent()
	return {
		"battle_event_close_result_panel",
		"LOCAL_ROLL_FINISHED",
		"AddResultObject",
		"TEAM_QUERY_NPC_REWARD_REQUEST",
		"Roll_Query_Respond",
	}
end

function View:onEvent(event,data,info)
	if event == "battle_event_close_result_panel" then
		self.view:SetActive(false)
	elseif event == "LOCAL_ROLL_FINISHED" then
		self.Data = data
		self.ShowRollData = false
		self.ShowExtraSpoilsData = false
		self:updateBottom()
	elseif event == "AddResultObject" then
		self:AddResultObject(data)
	elseif event == "TEAM_QUERY_NPC_REWARD_REQUEST" then
		self.ShowExtraSpoilsData = #data.reward_content > 0
	elseif event == "Roll_Query_Respond" then
		self.ShowRollData = true
	end
end

return View;
