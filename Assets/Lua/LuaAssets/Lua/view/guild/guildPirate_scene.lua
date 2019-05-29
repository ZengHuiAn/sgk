local guildTaskModule = require "module.guildTaskModule"
local guildTaskCfg = require "config.guildTaskConfig"
local MapConfig = require "config.MapConfig"
local ItemModule = require "module.ItemModule"
local Time = require "module.Time"
local View = {}

function View:Start(data)
	DispatchEvent("MAP_UI_HideGuideLayerObj");
	self.time = 0
	self.boss = 0
	guildTaskModule.Clear_task();
    self.pirate_list = guildTaskCfg.GetguildTask(nil,2003) --海盗列表
    self.weak_pirate_list = guildTaskCfg.GetguildTask(nil,2006)--虚弱海盗列表
    self.boss_list = guildTaskCfg.GetguildTask(nil,2005)--boss列表
    self.boss_quest = guildTaskCfg.GetguildTask(nil,2007)--boss任务
    self.boss_show = guildTaskCfg.GetguildTask(nil,2008)--显示boss任务
    self.point_quest = guildTaskCfg.GetguildTask(nil,2004)--积分任务
    DialogStack.PushPref("guild/guildPirateSchedule",nil, UnityEngine.GameObject.Find("bottomUIRoot"))
    -- self:GuildSubmitItems(2004)
    -- self:GuildSubmitItems(2007)
    -- self:loadPirate()
    self.pid = module.playerModule.Get().id
    self.msg = 0
end

function View:loadPirate()
	local quest_list = guildTaskModule.GetGuild_task_list()
	if quest_list and #quest_list > 0 then
		-- ERROR_LOG("self.boss_maxTab",sprinttb(quest_list))
		-- ERROR_LOG("boss id---->>",self.boss_quest[1].quest_id)
		-- ERROR_LOG("self.boss_tab",sprinttb(quest_list[1][self.boss_quest[1].quest_id]))
		-- ERROR_LOG("self.boss_quest",quest_list[1][self.boss_quest[1].quest_id][0].status)
		if quest_list[1][self.boss_quest[1].quest_id] then
			if quest_list[1][self.boss_quest[1].quest_id][0].status == 1 then
				for i = 1,#self.pirate_list do
					local npc_obj = module.NPCModule.GetNPCALL(self.pirate_list[i].npcid)
					DispatchEvent("GUILD_ACTIVITY_BOSS_DEAD");
					if utils.SGKTools.GameObject_null(npc_obj) ~=true then
						npc_obj.gameObject:SetActive(false)
					end
				end
				self.boss = 1
				--虚弱怪
				self:loadMonster(quest_list,self.weak_pirate_list)
			else
				--强力怪
				self:loadMonster(quest_list,self.pirate_list)
			end
		else
			--强力怪
			self:loadMonster(quest_list,self.pirate_list)
		end
		--boss显示任务
		if quest_list and quest_list[2] and quest_list[2][self.boss_show[1].quest_id] then
			if quest_list[2][self.boss_show[1].quest_id][self.pid] then
				if quest_list[2][self.boss_show[1].quest_id][self.pid].status ~= 2 then
					self.boss = 1
				end
			end
		end	
	end
	--显示传送
    --ERROR_LOG(module.TreasureModule.GetActivityScore(8));
	if module.TreasureModule.GetActivityScore(8) >=100 then
		self:loadPortal(quest_list)
	else
		self:loadPortal(quest_list,true)
	end
end

function View:loadMonster(quest_list,cfg)

--	print(sprinttb(quest_list))
	if cfg and #cfg > 0 then
		for i = 1,#cfg do
			for k,v in pairs(cfg) do
				local MonsterQuest = quest_list and (quest_list[2] and quest_list[2][cfg[i].quest_id] or nil) or nil
				local MonsterQuestStatus = 0
				if MonsterQuest then
					for k1,v1 in pairs(MonsterQuest) do
						if v1.next_time_to_accept > Time.now() then
							module.NPCModule.deleteNPC(cfg[i].npcid)
							MonsterQuestStatus = 1
							break
						end						
					end
				end
				if MonsterQuestStatus == 0 then
					local npc_obj = module.NPCModule.GetNPCALL(cfg[i].npcid)
					if utils.SGKTools.GameObject_null(npc_obj) == true or npc_obj == nil or npc_obj.activeInHierarchy == false then
						module.NPCModule.LoadNpcOBJ(cfg[i].npcid)
					end
				end
			end
		end
	end
end

function View:Update()
	--10秒检查一次是否刷怪
	self.time = self.time + UnityEngine.Time.deltaTime
	if self.time >= 0.5 then
		self.time = 0
		self:loadPirate()
	end
end

function View:loadPortal(quest_list,status)
	local Portal = {1347001,1347002,1347003,1347004}
	for k,v in pairs(Portal) do
		if status then
			module.NPCModule.deleteNPC(v)
		else
			module.NPCModule.LoadNpcOBJ(v)
			utils.SGKTools.loadEffect("effect/UI/fx_chuans_door",v)
			-- utils.SGKTools.loadEffect("UI/fx_chuans_door",v)
		end
	end
--	ERROR_LOG("self.boss----->>>",self.boss)
	if self.boss == 0  and not status then
		guildTaskModule.Start_GUILD_QUEST(self.boss_show[1].quest_id)
		utils.SGKTools.LockMapClick(true)
		utils.SGKTools.MapCameraMoveTo(self.boss_list[1].npcid)
		SGK.Action.DelayTime.Create(3):OnComplete(function()
			utils.SGKTools.LockMapClick(false)
			utils.SGKTools.MapCameraMoveTo()
		end)
		self.boss = 1
	end
	if not status then
		self:loadMonster(quest_list,self.boss_list)
	end	
end

function View:GuildSubmitItems(id)
	self.co = 0
	local TASK_list = guildTaskCfg.GetguildTask(nil,id)
	-- print("TASK_list",sprinttb(TASK_list))
	local Guild_task_list = guildTaskModule.GetGuild_task_list()
	-- print("Guild_task_list",sprinttb(Guild_task_list))
	if Guild_task_list and #Guild_task_list > 0 then
		local quest_list = guildTaskModule.GetGuild_task_list()[1][TASK_list[1].quest_id]
		-- ERROR_LOG("计数任务2007",quest_list,sprinttb(quest_list))
		if quest_list then
			if quest_list[0].status == 0 then
				self.co = 1
			end
		end
		if self.co == 0 then
			quest_list = {}
			quest_list[0] = {record = {0,0,0}}
		end
		-- ERROR_LOG(quest_list[0].record[1],TASK_list[1].event_count1)
		if ItemModule.GetItemCount(TASK_list[1].event_id1) > 0 and quest_list[0].record[1] < TASK_list[1].event_count1 then
			guildTaskModule.GuildSubmitItems(TASK_list[1].quest_id,TASK_list[1].event_id1,ItemModule.GetItemCount(TASK_list[1].event_id1))
		end
		if ItemModule.GetItemCount(TASK_list[1].event_id2) > 0 and quest_list[0].record[2] < TASK_list[1].event_count2 then
			guildTaskModule.GuildSubmitItems(TASK_list[1].quest_id,TASK_list[1].event_id2,ItemModule.GetItemCount(TASK_list[1].event_id2))
		end
		if ItemModule.GetItemCount(TASK_list[1].event_id3) > 0 and quest_list[0].record[3] < TASK_list[1].event_count3 then
			guildTaskModule.GuildSubmitItems(TASK_list[1].quest_id,TASK_list[1].event_id3,ItemModule.GetItemCount(TASK_list[1].event_id3))
		end
	end
end

function View:onEvent(event, data, msg)
	if event == "Guild_task_change" then
		self:GuildSubmitItems(2004)
		self:GuildSubmitItems(2007)
		self:loadPirate()
	elseif event == "GUILD_TASK_CHANGEINFO" then
		if data == self.boss_quest[1].quest_id then
			local quest_list = guildTaskModule.GetGuild_task_list()
			if quest_list[1][self.boss_quest[1].quest_id][0].status == 1 then
				local _quest_list = quest_list[2][self.boss_list[1].quest_id]
				-- print(sprinttb(_quest_list))
				for k,v in pairs(_quest_list) do
					if v.status == 1 and math.floor(v.pid) == self.pid then
						utils.SGKTools.MapBroadCastEvent(12, v.pid);
						DispatchEvent("GUILD_ACTIVITY_BOSS_DEAD");
						break
					end
				end
			end
		end
	elseif event == "MAP_CLIENT_EVENT_12" then
		if self.msg == 0 then
			-- print("pid",msg)
			local player = module.playerModule.Get(data);
			-- print("player",sprinttb(player))
			local str = player.name.."击杀了海盗船长，其他海盗被激怒了！"
			showDlgError(nil,str)
			self.msg = 1
		end
	end
end

function View:listEvent()
	return{
	"Guild_task_change",
	"ITEM_INFO_CHANGE",
	"GUILD_TASK_CHANGEINFO",
	"MAP_CLIENT_EVENT_12",
	}
end
return View
