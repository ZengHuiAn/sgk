local ItemModule = require "module.ItemModule"
local guildTaskModule = require "module.guildTaskModule"
local guildTaskCfg = require "config.guildTaskConfig"
local ItemHelper = require "utils.ItemHelper"
local IconFrameHelper = require "utils.IconFrameHelper"
local Time = require "module.Time"
local UnionConfig = require "config.UnionConfig"
local View = {};
local activity_Period = nil

local TreasureModule = require "module.TreasureModule"

function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = nil
	self.EndTime = nil
	self.icon_cfg = {}
	self.view.Btn1[CS.UGUIClickEventListener].onClick = function ( ... )
		self:SearchEffect()
	end
	self.view.Btn2[CS.UGUIClickEventListener].onClick = function ( ... )
		self:SearchEffect()
	end
	activity_Period = module.TreasureModule.GetNowPeriod(10);
	if data.type == 2 then
		self.view.Btn1:SetActive(true)
		self.view.Btn2:SetActive(false)
		self.view.tips.Text[UI.Text].text = "请使用探测器寻找隐藏的黑甲胄碎片！";
	elseif data.type == 1 then
		self.view.Btn1:SetActive(false)
		self.view.Btn2:SetActive(true)
		self.view.tips.Text[UI.Text].text = "请使用探测器寻找隐藏的黑甲胄碎片！";
	else
		self:PlayEffect();
		self.view.tips.Text[UI.Text].text = "“请与玛仕达对话，装备探测器！";
	end
	self.view.helpBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guild_activity_treasure"))
		-- module.TreasureModule.GetRankReward();
	end
	--[[self.view.timeBtn.gameObject.transform:DOLocalMoveX(80,0.3):OnComplete(function ( ... )
      	--self.flag  = true;
      	-- print(self.view.timeBtn.gameObject.transform.localPosition.x);
	end);]]
	
	self.view.leaveBtn[CS.UGUIClickEventListener].onClick = function ()
		SceneStack.EnterMap(1);
	end;
	self.pid = module.playerModule.GetSelfID();
	self.view.reward[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.Push("treasureRewardRank");
	end

	self.view.rank[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.PushPrefStact("guild/UnionActivityRank",{Period = activity_Period, activity_id = 10});
	end
	---------------------------------------------
	module.TreasureModule.GetUnionRank(10,nil,function ( _rank_data )
		self:FreshScore()
	end);


	self.view.desc[UI.Text].text = "寻宝活动正在进行中"
	self.Data = data
	------------------------------------------
	self:RefItem()
	DispatchEvent("LOCAL_MAPSCENE_CHAGEGUIDELAYER_STATUS", true)
end

function View:FreshScore(  )
	local score = module.TreasureModule.GetActivityScore(10)
	self.view.unionScore.point[UI.Text].text = score;
end

function View:SearchEffect()
	utils.SGKTools.StopPlayerMove()
	local _item = SGK.ResourcesManager.Load("prefabs/effect/UI/fx_guild_radar.prefab")
    local _obj = CS.UnityEngine.GameObject.Instantiate(_item, UnityEngine.GameObject.FindWithTag("UITopRoot").transform)
    local _view = CS.SGK.UIReference.Setup(_obj)
    _view.text[UI.Text].text = "探索中"
    -- math.randomseed(os.time())
    -- local RandomTime = math.random(0,7)
    SGK.Action.DelayTime.Create(3):OnComplete(function()
    	if self.Data.fun() then
    		self.Data.fun()
    	end
    	UnityEngine.GameObject.Destroy(_obj)
    end)
end

function View:Excavate(idx)
	
end

function View:RefItem()
	local TASK_list = guildTaskCfg.GetguildTask(nil,1001)

	local quest_id = {}
	local item_ids = {}
	for i = 1,#TASK_list do
		--ERROR_LOG(TASK_list[i].begin_time)
		item_ids[i] = {type = TASK_list[i].event_type1,id = TASK_list[i].event_id1,value = TASK_list[i].event_count1}
		--item_ids[2] = {type = TASK_list[i].event_type2,id = TASK_list[i].event_id2,value = TASK_list[i].event_count2}
		--item_ids[3] = {type = TASK_list[i].event_type3,id = TASK_list[i].event_id3,value = TASK_list[i].event_count3}
		quest_id[i] = TASK_list[i].quest_id
	end
	local cfg = UnionConfig.GetActivity(10)
	print("++++++++++++",sprinttb(cfg));

	self.EndTime = cfg.begin_time + cfg.period * ((math.ceil((Time.now() + 1 - cfg.begin_time) / cfg.period)) - 1) + cfg.loop_duration

	-- self.EndTime = cfg.begin_time + math.floor((Time.now() - TASK_list[1].begin_time)/TASK_list[1].period)*TASK_list[1].period + TASK_list[1].duration
	-- ERROR_LOG(self.EndTime);
	local time =  math.floor(self.EndTime - Time.now())

	if time < 0 then
		self.EndTime = nil

		self.view.timeBtn.time[UI.Text].text = "已结束"
		self.view.tips.Text[UI.Text].text = "活动已结束！";
		self:PlayEffect();
	end

	if time < 0 then
		self._status = true;
	else
		self._status = nil;
	end
	-- self.duration = TASK_list[1].duration;
end
function View:ItemList(quest_id)
	local Max = {}
	local item_ids = {}
	local guild_quest_stepreward = guildTaskCfg.Getguild_quest_stepreward(quest_id)

	if not guild_quest_stepreward then return end

	for i = 1,#guild_quest_stepreward do
		if not item_ids[i] then
			item_ids[i] = {}
		end
		if guild_quest_stepreward[i].reward_id1 ~= 0 then
			item_ids[i][1] = {type = guild_quest_stepreward[i].reward_type1,id = guild_quest_stepreward[i].reward_id1,count = guild_quest_stepreward[i].reward_value1}
		end
		if guild_quest_stepreward[i].reward_id2 ~= 0 then
			item_ids[i][2] = {type = guild_quest_stepreward[i].reward_type2,id = guild_quest_stepreward[i].reward_id2,count = guild_quest_stepreward[i].reward_value2}
		end
		if guild_quest_stepreward[i].reward_id3 ~= 0 then
			item_ids[i][3] = {type = guild_quest_stepreward[i].reward_type3,id = guild_quest_stepreward[i].reward_id3,count = guild_quest_stepreward[i].reward_value3}
		end
		Max[i] = guild_quest_stepreward[i].condition1
	end
	return item_ids,Max
end

function View:ShowEndActivity( )
	if not DialogStack.GetPref_list("guild/guildEnd") then
		DialogStack.PushPref("guild/guildEnd",{Period = activity_Period, activity_id = 10});
	end
end

function View:Update()
	if self.EndTime then
		local time =  math.floor(self.EndTime - Time.now())
		if time > 0 then
			self.view.timeBtn.time[UI.Text].text = string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60))
			-- self.view.timeBtn.title_image.slider.Slider[UI.Slider].value = time/self.duration;
		else
			self.view.timeBtn.time[UI.Text].text = "已结束"
			self.view.tips.Text[UI.Text].text = "活动已结束！";
			self:PlayEffect();
			self.EndTime =nil
			
			self:ShowEndActivity();
		end
	end
end

function View:PlayEffect( )
	self.view.tips.effect.glow[UnityEngine.ParticleSystem]:Stop(true);
	self.view.tips.effect.glow[UnityEngine.ParticleSystem]:Play(true);
	 
end

function View:onEvent(event, data)
	-- ERROR_LOG(event);
	if event == "Guild_task_change" then
		self:FreshScore();
		-- print("Guild_task_change");
		self:RefItem()
	elseif event == "Guild_Detect_Change" then
		-- print("Guild_Detect_Change",sprinttb(data));
		if data and data.desc then
			self.view.desc[UI.Text].text = data.desc
		end
	elseif event == "ITEM_INFO_CHANGE" then
		if not data then
			return;
		end
		if ItemModule.GetItemCount(79052) >= 1 then
			print("道具数量2",ItemModule.GetItemCount(79052))
			self.view.Btn1:SetActive(true)
			self.view.Btn2:SetActive(false)

			
			if self.EndTime then
				if self.tip ~= 2 then
					self.tip = 2;
					self:PlayEffect();
					self.view.tips.Text[UI.Text].text = "请使用探测器寻找隐藏的黑甲胄碎片！";
				end
			end
		elseif ItemModule.GetItemCount(79051) >= 1 then
			print("道具数量1",ItemModule.GetItemCount(79051))
			self.view.Btn1:SetActive(false)
			self.view.Btn2:SetActive(true)
			if self.EndTime then
				if self.tip ~= 3 then
					self.tip = 3;
					self:PlayEffect();
					self.view.tips.Text[UI.Text].text = "请使用探测器寻找隐藏的黑甲胄碎片！";
				end
			end
		end
	elseif event == "TREASURE_SUCCESS" then
		-- ERROR_LOG("本公会排行",sprinttb(data));
		local tempObj = SGK.ResourcesManager.Load("prefabs/base/TreasureSuccess.prefab")
		local NGUIRoot = UnityEngine.GameObject.FindWithTag("UGUIRoot")
		local obj = nil;
		if NGUIRoot then
			obj = CS.UnityEngine.GameObject.Instantiate(tempObj, NGUIRoot.gameObject.transform)
		end
		if obj then
			SGK.LuaBehaviour.Append(obj, "view/TreasureSuccess.lua")
		end
		self.open = true;
	elseif event == "GUILD_ACTIVITY_ENDNOTIFY" then
		if data == 10 then
			
			self:ShowEndActivity();
		end
	end
end
function View:listEvent()
	return{
	"Guild_task_change",
	"Guild_Detect_Change",
	"ITEM_INFO_CHANGE",
	"GUILD_ACTIVITY_ENDNOTIFY",
	}
end
return View