local ItemModule = require "module.ItemModule"
local guildTaskModule = require "module.guildTaskModule"
local guildTaskCfg = require "config.guildTaskConfig"
local ItemHelper = require "utils.ItemHelper"
local Time = require "module.Time"
local View = {};
local guildBarbecueModule = require "module.guildBarbecueModule"

local activity_Period = nil
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject).root
	guildTaskModule.Clear_task();


	self.view.helpBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guild_kaorou_rule"))
	end
	self.view.leaveBtn[CS.UGUIClickEventListener].onClick = function ()
		SceneStack.EnterMap(1);
	end;
	-- GetRank
	self.EndTime = nil
	activity_Period = module.TreasureModule.GetNowPeriod(9);
	self:RefItem()
	self:SubmitProp();
	-- local  = GetProp
	self:FreshProp();
	self.view.rankBtn[CS.UGUIClickEventListener].onClick = function ()
		DialogStack.PushPrefStact("guild/UnionActivityRank",{Period = activity_Period, activity_id = 9});
	end

	
	module.TreasureModule.GetUnionRank(9,nil,function ( _rank_data )
		self:FreshScroe();
	end);
end

function View:FreshScroe( ... )
	local score = module.TreasureModule.GetActivityScore(9)
	self.view.score.point[UI.Text].text = score;
end



function View:RefItem()
	
	local TASK_list = guildTaskCfg.GetguildTask(nil,2001)
	if not TASK_list then
		return;
	end
	-- ERROR_LOG(sprinttb(TASK_list));
	local quest_id = 0
	local item_ids = {{},{},{}}
	for i = 1,#TASK_list do
		item_ids[1] = {type = TASK_list[i].event_type1,id = TASK_list[i].event_id1,value = TASK_list[i].event_count1}
		item_ids[2] = {type = TASK_list[i].event_type2,id = TASK_list[i].event_id2,value = TASK_list[i].event_count2}
		item_ids[3] = {type = TASK_list[i].event_type3,id = TASK_list[i].event_id3,value = TASK_list[i].event_count3}
		quest_id = TASK_list[i].quest_id
	end
	-- print("quest_id",quest_id)
	local quest_list = nil
	local lsit = guildTaskModule.GetGuild_task_list();
	
	local data = lsit and lsit[2] or {}

	

	if lsit and #lsit > 0 and lsit[1][quest_id] then
		quest_list = lsit[1][quest_id];
	end

	local cfg = module.TreasureModule.GetActivity(9);
	-- ERROR_LOG(sprinttb(cfg));
	self.activityEndTime = cfg.begin_time + cfg.period * ((math.ceil((Time.now() + 1 - cfg.begin_time) / cfg.period)) - 1) + cfg.loop_duration;
	self.EndTime = quest_list and quest_list[0].next_time_to_accept or 0;


	if self.EndTime == 0 then
		if self.tips ~= 1 then
			self.tips = 1
			self:PlayEffect();
		end
		self.view.tips.Text[UI.Text].text = "当前食材不足,请抓紧时间收集三种食材（鱼，虾和蘑菇）!";
	else
		if self.tips ~= 2 then
			self.tips = 2
			self:PlayEffect();
		end
		-- self:PlayEffect();
		local dur = self.EndTime - Time.now();
		self.view.tips.Text[UI.Text].text = "距离下次烹饪 "..string.format("%02d",math.floor(math.floor(dur/60)%60))..":"..string.format("%02d",math.floor(dur%60));
	end
	
end

local prop_cfg = nil

local nameCfg = {
	[79047] = { name ="已收集海鱼:"},
	[79048] = { name ="已收集龙虾:"},
	[79049] = { name ="已收集蘑菇:"},
}


function View:BuildConfig()
	if not prop_cfg then
		local TASK_list = guildTaskCfg.GetguildTask(nil,2001)
		-- ERROR_LOG(sprinttb(TASK_list));
		prop_cfg = {{},{},{}}
		for i = 1,#TASK_list do
			prop_cfg[1] = ItemModule.GetConfig(TASK_list[i].consume_id1);
			prop_cfg[1].count = TASK_list[i].consume_value1
			prop_cfg[2] = ItemModule.GetConfig(TASK_list[i].consume_id2);
			prop_cfg[2].count = TASK_list[i].consume_value2
			prop_cfg[3] = ItemModule.GetConfig(TASK_list[i].consume_id3);
			prop_cfg[3].count = TASK_list[i].consume_value3
		end
	end

end

function View:FreshProp()
	local list = guildTaskModule.GetGuild_task_list();
	if list and list[1] then
		if list[1][20012001] then
			if list[1][20012001][0].status == 1 or list[1][20012001][0].status == 2 then
				guildTaskModule.Start_GUILD_QUEST(20012001);
			end
		else
			guildTaskModule.Start_GUILD_QUEST(20012001);
		end
	end
	local data = guildBarbecueModule.GetGuildProp();
	if not data then
		return;
	end
	self:BuildConfig();
	local prop_data = {};
	--是否可以提交
	local isSub = true;
	for i = 1,#prop_cfg do
		local cfg = prop_cfg[i];
		local _count = 0;
		for k,v in pairs(data) do

			-- print(k,v)
			if k == cfg.id then
				prop_data[k] = v;
				break;
			end
		end
		prop_data[cfg.id] = prop_data[cfg.id] or 0;
		-- ERROR_LOG(sprinttb(cfg));
		if prop_data[cfg.id]< cfg.count and prop_data[cfg.id] >=0 then
			isSub = false;
		end
		-- ERROR_LOG(sprinttb(cfg));
		local group = self.view.bg;
		group[i].count[UI.Text].text = (prop_data[cfg.id] or 0) .."/"..cfg.count;

		if prop_data[cfg.id] >= cfg.count then
			group[i].check[UI.Image].enabled = true;
		else
			group[i].check[UI.Image].enabled = false;
		end
	end

	if isSub then
		if list and list[1] and list[1][20012001] then
			local currentTime = Time.now()
			-- ERROR_LOG("任务数据",sprinttb(list[1][20012001][0]));
			if list[1][20012001][0].status ~= 1 and list[1][20012001][0].status ~= 2 and (list[1][20012001][0].next_time_to_accept <= currentTime or list[1][20012001][0].next_time_to_accept ==0  )then
				-- ERROR_LOG("提交任务");
				guildTaskModule.End_GUILD_QUEST(20012001);
			end
		end
	end
end

function View:PlayEffect( )
	-- print("刷新特效",self.tips)
	self.view.tips.effect.glow[UnityEngine.ParticleSystem]:Stop(true);
	self.view.tips.effect.glow[UnityEngine.ParticleSystem]:Play(true);
	 
end
function View:Update()
	if self.activityEndTime then
		local time =  math.floor(self.activityEndTime - Time.now());
		if time >=0 then
			self.view.timeBtn.time[UI.Text].text = string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60))
		else
			-- self:PlayEffect();

			if self.tips ~= 3 then
				self.tips = 3
				self:PlayEffect();
			end

			self.view.timeBtn.time[UI.Text].text = "已结束!"
			self.view.tips.Text[UI.Text].text = "活动已结束!";
			self.EndTime = nil
			self.activityEndTime = nil;
		end
	end

	if self.EndTime then
		local time = math.floor(self.EndTime - Time.now());
		if time >=0 then
			self.view.tips.Text[UI.Text].text = "距离下次烹饪 "..string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60));
			if not self.start then
				guildTaskModule.Clear_task();
				self.start = true;
				--开始烹饪
				guildBarbecueModule.ResetGuildProp();

				self:FreshProp();
				DispatchEvent("KAO_ROU_START");
			end
		else
			self.EndTime = nil;
			self:FreshProp();

			if self.tips ~= 1 then
				self.tips = 1
				
				self:PlayEffect();
			end
			self.view.tips.Text[UI.Text].text = "当前食材不足,请抓紧时间收集三种食材（鱼，虾和蘑菇）!";
			if self.start and not self.End then
				self.End = true;
				self.start = nil;
				
				DispatchEvent("KAO_ROU_END");
			end
		end
	end
end

function View:SubmitProp()
	self:BuildConfig();

	for i = 1,#prop_cfg do
		local count = ItemModule.GetItemCount(prop_cfg[i].id)
		-- ERROR_LOG("提交物品".."id"..prop_cfg[i].id,"count"..(count or 0));
		if count > 0 then
			guildBarbecueModule.SubmitGuild(prop_cfg[i].id,count);
		end
	end
end

function View:ShowEndActivity(  )
	if not DialogStack.GetPref_list("guild/guildEnd") then
		DialogStack.PushPref("guild/guildEnd",{Period = activity_Period, activity_id = 9});
	end
end

function View:onEvent(event, data)

	if event == "Guild_task_change" then
		-- ERROR_LOG("数据改变",sprinttb(data));
		self:RefItem()
	elseif event == "GET_GUILD_PROP_SUC" then
		self:FreshProp();
	elseif event =="ITEM_INFO_CHANGE" then

		if data and (data.gid == 79047 or data.gid == 79048 or data.gid == 79049) and data.count >0 then
			self:SubmitProp();
		end
	elseif event =="GUILD_TASK_CHANGEINFO" then
		if data == 20012001 then
			self:FreshProp();
		end
		
	elseif event == "GUILD_ITEM_CHANGE_INFO" then
		self:FreshProp();

	elseif event == "GUILD_ACTIVITY_ENDNOTIFY" then
		if data == 9 then
			self:ShowEndActivity();
		end
	elseif event == "GUILD_TASK_JUMP" then
		showDlgError(nil,"运气爆棚，直接获取素材!"); 
	end
end
function View:listEvent()
	return{
	"Guild_task_change",
	--获取奖励成功
	"GET_GUILD_PROP_SUC",
	"GUILD_TASK_CHANGEINFO",
	"ITEM_INFO_CHANGE",
	"GUILD_ITEM_CHANGE_INFO",
	"GET_RANK_SELF_RESULT",
	"GET_RANK_RESULT",
	"GUILD_ACTIVITY_ENDNOTIFY",
	"GUILD_TASK_JUMP",
	}
end


return View