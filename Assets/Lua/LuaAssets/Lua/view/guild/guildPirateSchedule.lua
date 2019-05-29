local ItemModule = require "module.ItemModule"
local guildTaskModule = require "module.guildTaskModule"
local guildTaskCfg = require "config.guildTaskConfig"
local ItemHelper = require "utils.ItemHelper"
local Time = require "module.Time"
local UnionConfig = require "config/UnionConfig"
local View = {};
local activity_Period = nil
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject).root
	self.view.helpBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guild_haidao_rule"))
	end
	self:RefItem()
	self.m_endTime = nil
	self.activitytime = nil
	self.open = nil
	self:showActivityTime();
	self.view.rankBtn[CS.UGUIClickEventListener].onClick = function ( ... )
        DialogStack.PushPrefStact("guild/UnionActivityRank",{Period = activity_Period, activity_id = 8});
	end
	self.view.leaveBtn[CS.UGUIClickEventListener].onClick = function ()
		SceneStack.EnterMap(1);
	end;

	module.TreasureModule.GetUnionRank(8,nil,function ( _rank_data )
		self:FreshScroe()
	end);
	self.pirate_list = guildTaskCfg.GetguildTask(nil,2003) --海盗列表
end

local function getTimeHMS(time)
    local H = math.floor(time /3600);
    time = math.fmod(time ,3600)
    local M = math.floor(time/60);
    time = math.fmod(time ,60)
    local S = time
    return H,M,S
end

function View:FreshScroe( ... )
	local score = module.TreasureModule.GetActivityScore(8)

	ERROR_LOG("积分============",score);
	self.view.score.point[UI.Text].text = score;
	self.boss_quest = guildTaskCfg.GetguildTask(nil,2007)
	self.boss_list = guildTaskCfg.GetguildTask(nil,2005)--boss列表
	local quest_list = guildTaskModule.GetGuild_task_list()
	if quest_list then
		local _quest_list = quest_list[2][self.boss_list[1].quest_id]

		if _quest_list then
			for k,v in pairs(_quest_list) do
				if v.status == 1 and math.floor(v.pid) == self.pid then
					utils.SGKTools.MapBroadCastEvent(12, v.pid);
					break
				end
			end
		end
	end

	local self_boss = nil
	if quest_list and #quest_list > 0 then
		-- ERROR_LOG("self.boss_quest",sprinttb(quest_list[1][self.boss_quest[1].quest_id]))
		if quest_list[1][self.boss_quest[1].quest_id] then
			if quest_list[1][self.boss_quest[1].quest_id][0].status == 1 then
				for i = 1,#self.pirate_list do
					local npc_obj = module.NPCModule.GetNPCALL(self.pirate_list[i].npcid)
					if utils.SGKTools.GameObject_null(npc_obj) ~=true then
						self_boss = true;
					end
				end
			end
		end
	end
	if self_boss then
		self.view.tips.Text[UI.Text].text = "海盗船长的死亡激怒了其他海盗，消灭他们！"
		return;
	end
	print("tips====",self.tips,score)
	if score < 100 then
		if self.tips ~= 1 then
			self:PlayEffect();
		end
		self.tips = 1;
		self.view.tips.Text[UI.Text].text = "击杀入侵海盗，积分达到100将开启海盗船传送门！"
	elseif score >= 100 and self.tips ~=2 then
		self.tips = 3
		self.view.tips.Text[UI.Text].text = "传送门已开启，请前往海盗船击杀海盗船长！"
	end
	print("tips====",self.tips)
end

function View:PlayEffect( ... )
	self.view.tips.effect.glow[UnityEngine.ParticleSystem]:Stop(true);
	self.view.tips.effect.glow[UnityEngine.ParticleSystem]:Play(true);
end


function View:Update()
	if self.m_endTime and self.open then
		self.activitytime = math.floor(self.m_endTime - Time.now())
		if self.activitytime < 0 then
			self.activitytime = 0
			self:SaveData()
			self.open = nil
			self:ShowEndActivity();
			return
		end
		local H,M,S = getTimeHMS(self.activitytime)
		self.view.activitytime.Text[UI.Text].text = string.format("%02d:%02d",M,S);
	else
		self.view.activitytime.Text[UI.Text].text = "已结束"
	end
end

function View:RefItem()
	self.TASK_list = guildTaskCfg.GetguildTask(nil,2004)
	-- local quest_id = self.TASK_list[1].quest_id
	-- local item_ids = {}
	-- local name = "积分"
	-- local Max = {}
	-- local quest_list = nil
	-- if guildTaskModule.GetGuild_task_list() and #guildTaskModule.GetGuild_task_list() > 0 then
	-- 	quest_list = guildTaskModule.GetGuild_task_list()[1][quest_id]
	-- 	-- ERROR_LOG("计数任务",quest_id,sprinttb(quest_list))
	-- 	if quest_list then
	-- 		if quest_list[0].status == 2 then
	-- 			quest_list[0].record = {0,0,0}
	-- 		end
	-- 	end
	-- end
	-- local guild_quest_stepreward = guildTaskCfg.Getguild_quest_stepreward(quest_id)
	-- -- print("guild_quest_stepreward",sprinttb(guild_quest_stepreward))
	-- for i = 1,#guild_quest_stepreward do
	-- 	if not item_ids[i] then
	-- 		item_ids[i] = {}
	-- 	end
	-- 	if guild_quest_stepreward[i].reward_id1 ~= 0 then
	-- 		item_ids[i][1] = {type = guild_quest_stepreward[i].reward_type1,id = guild_quest_stepreward[i].reward_id1,count = guild_quest_stepreward[i].reward_value1}
	-- 	end
	-- 	if guild_quest_stepreward[i].reward_id2 ~= 0 then
	-- 		item_ids[i][2] = {type = guild_quest_stepreward[i].reward_type2,id = guild_quest_stepreward[i].reward_id2,count = guild_quest_stepreward[i].reward_value2}
	-- 	end
	-- 	if guild_quest_stepreward[i].reward_id3 ~= 0 then
	-- 		item_ids[i][3] = {type = guild_quest_stepreward[i].reward_type3,id = guild_quest_stepreward[i].reward_id3,count = guild_quest_stepreward[i].reward_value3}
	-- 	end
	-- 	Max[i] = guild_quest_stepreward[i].condition1
	-- end
end

function View:SaveData()
	self.data = {}
	local _quest_list = guildTaskModule.GetGuild_task_list()
	if _quest_list[1][self.TASK_list[1].quest_id] then
		local temp = _quest_list[1][self.TASK_list[1].quest_id][0].quest_stage
		print(sprinttb(temp))
		for k,v in pairs(temp) do
			if v.contribituion > 0 then
				self.data[v.pid] = {count = math.floor(v.contribituion / 10)}
			end
		end
	else
		self.data = nil
	end
end

function View:showActivityTime()
	local _cfg = UnionConfig.GetActivity(8)
	if _cfg.loop_duration then
		self.maxtitle = _cfg.loop_duration / 15
	end
	if _cfg.begin_time >= 0 and _cfg.end_time >= 0 and _cfg.period >= 0 then
        local total_pass = Time.now() - _cfg.begin_time
        local count = math.floor(total_pass / _cfg.period) * _cfg.period
        self.m_endTime = count + _cfg.loop_duration + _cfg.begin_time
        self.open = true
        -- print("配置开始时间",_cfg.begin_time,"持续时间",_cfg.loop_duration,"周期",_cfg.period)
        -- print("结束时间",self.m_endTime,"当前时间",Time.now())
        if self.m_endTime < Time.now() then
        	self.open = nil
        	-- self.m_endTime = self.m_endTime - _cfg.loop_duration + _cfg.period
		end
		if self.open then
			activity_Period = module.TreasureModule.GetNowPeriod(8);
		end
    else
    	self.m_endTime = nil
    end
end

function View:onEvent(event, data)
	if event == "Guild_task_change" then
		self:RefItem()
	elseif event == "GUILD_ACTIVITY_ENDNOTIFY" then
		if data == 8 then
			self:ShowEndActivity();
		end
	elseif event == "GUILD_SCORE_INFO_CHANGE" then
		if data == 8 then
			self:FreshScroe();
		end
	elseif event == "GUILD_ACTIVITY_BOSS_DEAD" then
		if self.boss ~=1 then
			self.boss = 1;
			if self.tips ~= 2 then
				self.tips = 2;
				self.view.tips.Text[UI.Text].text = "海盗船长的死亡激怒了其他海盗，消灭他们！"
			end
		end
	end

end
function View:ShowEndActivity(  )
	if not DialogStack.GetPref_list("guild/guildEnd") then
		self.view.tips.Text[UI.Text].text = "活动已结束！"
		self:PlayEffect();
		DialogStack.PushPref("guild/guildEnd",{Period = activity_Period, activity_id = 8});
	end
end

function View:listEvent()
	return{
	"Guild_task_change",
	"GUILD_ACTIVITY_ENDNOTIFY",
	"GUILD_SCORE_INFO_CHANGE",
	"MAP_CLIENT_EVENT_12",
	"GUILD_ACTIVITY_BOSS_DEAD"
	}
end
return View