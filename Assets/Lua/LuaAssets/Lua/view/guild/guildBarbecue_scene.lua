local guildTaskModule = require "module.guildTaskModule"
local guildTaskCfg = require "config.guildTaskConfig"
local MapConfig = require "config.MapConfig"
local ItemModule = require "module.ItemModule"
local ItemHelper = require "utils.ItemHelper"
local Time = require "module.Time"
local View = {}
local Vector3 = UnityEngine.Vector3;

local Npcs = {
	{
		{id = 1346401,center ={-3,0,9.5}, target = {-3.2,0,1.54},bubble = 1, desc = "真好吃",time = 2},
	},

	{
		{id = 1346401,center = {-4.5,0,9.5}, target = {-3.2,0,1.54},bubble = 1, desc = "真好吃",time = 3},
		{id = 1346402,center = {-1.5,0,9.5}, target = {-3.2,0,1.54},bubble = 1, desc = "真好吃",time = 4},
	},

	{
		{id = 1346401,center = {-4.5,0,9.5}, target = {-3.2,0,1.54},bubble = 1, desc = "真好吃",time = 3},
		{id = 1346402,center = {-3,0,9.5}, target = {-3.2,0,1.54},bubble = 1, desc = "真好吃",time = 5},
		{id = 1346403,center = {-1.5,0,9.5}, target = {-3.2,0,1.54},bubble = 1, desc = "真好吃",time = 4},
	},

	{
		{id = 1346403,center = {-4.5,0,9.5}, target = {-3.2,0,1.54},bubble = 1, desc = "真好吃",time = 5},
		{id = 1346404,center = {-3,0,9.5}, target = {-3.2,0,1.54},bubble = 1, desc = "真好吃",time = 3},
		{id = 1346405,center = {-1.5,0,9.5}, target = {-3.2,0,1.54},bubble = 1, desc = "真好吃",time = 4},
	},

	{
		{id = 1346404,center ={-4.5,0,9.5}, target = {-3.2,0,1.54},bubble = 1, desc = "真好吃",time = 4},
		{id = 1346405,center ={-1.5,0,9.5}, target = {-3.2,0,1.54},bubble = 1, desc = "真好吃",time = 5},
	},
}


local CoinPos = {
					{-5.5,0,13.5},{-3,0,6},{-0.5,0,13.5},{-3,0,11.5},
					{-0.5,0,7},{-5.5,0,7},{-7,0,4.5},{1,0,4.5},
					{-6,0,9.5},{0,0,9.5}
				};


function View:Start(data)
	guildTaskModule.Clear_task();
	DialogStack.PushPref("guild/guildTaskSchedule",nil, UnityEngine.GameObject.Find("bottomUIRoot"))
    local guildBarBecuePos = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/guild/guildBarBecuePos.prefab"))
    self.time = 0
    self.fish_list = guildTaskCfg.GetguildTask(nil,2002)

    if self:CheckActivity() then
	    self:GuildSubmitItems()
	end
    self:loadNpcEffect()
	-- self:RandomNpc();
	self:loadFish()
	self:SetConfig();
	-- self:FreshFood();
	module.NPCModule.LoadNpcOBJ(1346701);
	-- self:Freshobs();
	self.pid = math.floor(module.playerModule.GetSelfID());
	self.union = module.unionModule.GetPlayerUnioInfo(self.pid);
	-- ERROR_LOG("我的公会",sprinttb(self.union));
	self:FreshCoin();

	-- self:FreshCoinStatus();
end


function View:CheckActivity()
	local cfg = module.TreasureModule.GetActivity(2);
	-- ERROR_LOG(sprinttb(cfg));
	self.activityEndTime = cfg.begin_time + cfg.period * ((math.ceil((Time.now() + 1 - cfg.begin_time) / cfg.period)) - 1) + cfg.loop_duration;

	if self.activityEndTime >= Time.now() then
		return true;
	end
end

function View:Freshobs( ... )
	
	local npc = module.NPCModule.GetNPCALL(6346601);
	if npc then
		local obs = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/guild/scheduleObs.prefab"))
		obs.gameObject.transform.parent = npc.gameObject.transform;
		obs.transform.localPosition = UnityEngine.Vector3.zero;
		if obs then
			local obj_ref = CS.SGK.UIReference.Setup(obs.gameObject);
			local ob = obj_ref[UnityEngine.AI.NavMeshObstacle];
			ob.size = UnityEngine.Vector3(2.72,1,0.25);
		end
		
	end
	
end


local bubbleEffect = {
	[79047] = {"effect/UI/NpcButtle2"},
	[79048] = {"effect/UI/NpcButtle1"},
	[79049] = {"effect/UI/NpcButtle3"},
}


function View:FreshCoinStatus()
	local npc_list = guildTaskCfg.GetguildTask(nil,2011);
	if npc_list then
		local quest_list = guildTaskModule.GetGuild_task_list();
		-- ERROR_LOG("==========",sprinttb(quest_list));
		-- ERROR_LOG("========",sprinttb(npc_list));
		if quest_list and quest_list[2] then
			-- ERROR_LOG(sprinttb(quest_list[2]));
			for k,v in pairs(npc_list) do
				-- quest_id
				if v then
					if quest_list[2] and quest_list[2] and quest_list[2][v.quest_id] then
						if quest_list[2][v.quest_id] then

							for k,_v in pairs(quest_list[2][v.quest_id]) do
							 	if _v.count == 1 then
							 		module.NPCModule.deleteNPC(v.npcid);
							 		break;
							 	end
							 end 
							
						end
					end
				end
			end
		end
	end

end


function View:FreshCoin()
	local npc_list = guildTaskCfg.GetguildTask(nil,2011);

	local pos_list = nil;
	pos_list = {};
	for k,v in pairs(CoinPos) do
		table.insert(pos_list,v);
	end
	if npc_list then
		for k,v in pairs(npc_list) do
			math.randomseed(self.union.unionId);
			local current = math.random(#pos_list);
			local pos = pos_list[current];
			table.remove(pos_list,current);
			module.NPCModule.LoadNpcOBJ(v.npcid,Vector3(pos[1],pos[2],pos[3]),nil,true)
		end
	end
	

end




function View:SetConfig()
	for k,v in pairs(self.fish_list) do
		-- ERROR_LOG("NPCID",v.npcid);
		guildTaskModule.Setnow_guildTask_npc(self.fish_list[k].npcid,self.fish_list[k])
	end
end

function View:RandomNpc()
	math.randomseed(os.time())
	local num = math.random(#Npcs);
	
	self.random_npc = {}
	self:FreshNpc(Npcs[num or 1]);
end


function View:FreshNpc(npc_data)
	
	for k,v in pairs(npc_data) do

		
		self:FreshItemNPC(v);
	end
	
end

function View:FreshItemNPC(item_npc)
	local npcid = item_npc.id;
	local center = item_npc.center;
	local target = item_npc.target;

	local npc_obj = module.NPCModule.GetNPCALL(npcid);
	-- ERROR_LOG(npc_obj,"=======>>>",npcid);
	if not npc_obj then
		module.NPCModule.LoadNpcOBJ(npcid)
		self.random_npc[npcid] = item_npc
		return
	end
	self:NpcMove(npc_obj,Vector3(center[1],center[2],center[3]),function ( ... )

		LoadNpcDesc(npcid,item_npc.desc,function ( ... )
			self:NpcMove(npc_obj,Vector3(target[1],target[2],target[3]),function ( ... )
				module.NPCModule.deleteNPC(npcid);
			end);
		end,item_npc.bubble,item_npc.time);

		-- SGK.Action.DelayTime.Create(1):OnComplete(function()
			
		-- end)
	end);
end

--Npc移动方法
function View:NpcMove(obj,target,func)
	local map = obj[CS.SGK.MapPlayer];
	map.onStop = (function (v3)
		func();
	end);
	map:MoveTo(target);

end

function View:loadFish()
	local quest_list = guildTaskModule.GetGuild_task_list()
	if quest_list and #quest_list > 0 and self.fish_list and #self.fish_list > 0 then
		for i = 1,#self.fish_list do
			local accept = true
			local guildmodule = quest_list[2] and quest_list[2][self.fish_list[i].quest_id] or nil
			if guildmodule then
				for k,v in pairs(guildmodule) do
					if v.next_time_to_accept > Time.now() then
						accept = false
						break
					end
				end
			end

			if self.fish_list[i].npcid ~= 0 then

				if accept then

					local npc_obj = module.NPCModule.GetNPCALL(self.fish_list[i].npcid)
					if npc_obj then
						npc_obj.gameObject:SetActive(true)
					else
						local npc_cfg = MapConfig.GetMapMonsterConf(self.fish_list[i].npcid)
						-- ERROR_LOG(sprinttb(npc_cfg));
						if npc_cfg then
							LoadNpc(npc_cfg)
						end
					end
					
				else
					-- module.NPCModule.deleteNPC(self.fish_list[i].npcid)
				end
			end
		end
	end
end



function View:GuildSubmitItems( ... )
	local Guild_task_list = guildTaskModule.GetGuild_task_list()
	if Guild_task_list == nil then
		return
	end
	local TASK_list = guildTaskCfg.GetguildTask(nil,2001)
	local quest_list = #Guild_task_list > 0 and Guild_task_list[1] or nil

	for i = 1,#TASK_list do
		if quest_list and quest_list[TASK_list[i].quest_id] then
			quest_list = quest_list[TASK_list[i].quest_id][0]
		else
			quest_list = {record = {0,0,0}}
		end
		--ERROR_LOG(quest_list.record[1],TASK_list[i].event_count1)
		if ItemModule.GetItemCount(TASK_list[i].consume_id1) > 0 and quest_list.record[1] < TASK_list[i].consume_value1 then
			guildTaskModule.GuildSubmitItems(TASK_list[i].quest_id,TASK_list[i].consume_id1,ItemModule.GetItemCount(TASK_list[i].consume_id1))
		end
		if ItemModule.GetItemCount(TASK_list[i].consume_id2) > 0 and quest_list.record[2] < TASK_list[i].consume_value2 then
			guildTaskModule.GuildSubmitItems(TASK_list[i].quest_id,TASK_list[i].consume_id2,ItemModule.GetItemCount(TASK_list[i].consume_id2))
		end
		if ItemModule.GetItemCount(TASK_list[i].consume_id3) > 0 and quest_list.record[3] < TASK_list[i].consume_value3 then
			guildTaskModule.GuildSubmitItems(TASK_list[i].quest_id,TASK_list[i].consume_id3,ItemModule.GetItemCount(TASK_list[i].consume_id3))
		end
	end
end
local EffectConfig = {
	
	[79047] = {"UI/fish_big","UI/fish_small"},
	[79048] = {"UI/wind_big","UI/wind_small"},
	[79049] = {"UI/fire_big","UI/fire_small"},
}

function View:loadNpcEffect()
	local TASK_list = guildTaskCfg.GetguildTask(nil,2001)
	local item_ids = {{},{},{}}

	local data = module.guildBarbecueModule.GetProp()
	for i = 1,#TASK_list do 
		item_ids[1] = ItemModule.GetConfig(TASK_list[i].consume_id1);
		item_ids[2] = ItemModule.GetConfig(TASK_list[i].consume_id2)
		item_ids[3] = ItemModule.GetConfig(TASK_list[i].consume_id3)
	end
	-- ERROR_LOG("道具数量",sprinttb(data));
	if data then
		for index = 1,3 do
			local i = 79046 + index;
			if data[i] then
				local record = data[i] or 0;
				-- ERROR_LOG("数量",record);
				if record > 0 then
					if record <= 50 then
						-- utils.SGKTools.DelEffect(EffectConfig[i][1],2346001)
						-- utils.SGKTools.loadEffect(EffectConfig[i][2],2346001)
						-- ERROR_LOG("刷新小鱼");
					else
						-- utils.SGKTools.DelEffect(EffectConfig[i][2],2346001)
						-- utils.SGKTools.loadEffect(EffectConfig[i][1],2346001)
						-- ERROR_LOG("刷新大鱼");
					end
				else
					-- ERROR_LOG("删除特效",i);
					utils.SGKTools.DelEffect(EffectConfig[i][1],2346001)
					utils.SGKTools.DelEffect(EffectConfig[i][2],2346001)
				end

			end
		end
	end


end

local RandomFlag = nil;
function View:onEvent(event, data)
	if event == "Guild_task_change" then
		self:loadFish()
		self:GuildSubmitItems()
		module.NPCModule.Ref_NPC_LuaCondition()
		-- self:FreshFood(true);
	elseif event == "ITEM_INFO_CHANGE" then
		module.NPCModule.Ref_NPC_LuaCondition()
	elseif event == "GUILD_TASK_CHANGEINFO" then
		self:loadNpcEffect();
	elseif event == "GET_GUILD_PROP_SUC" then
		self:loadNpcEffect();
	elseif event == "KAO_ROU_START" then
		self:RandomNpc();
		RandomFlag = true;
		self:FreshCoin(true);
		self.status = true;
	elseif event == "KAO_ROU_END" then
		self:FreshCoin();
		RandomFlag = nil;
		module.NPCModule.Ref_NPC_LuaCondition()
		self.status = nil;
	elseif event == "NPC_OBJ_INFO_CHANGE" then

		if self.random_npc then
			-- ERROR_LOG("随机NPC",sprinttb(self.random_npc),data);
			local npc_data = self.random_npc[data]
			if npc_data then
				self.random_npc[data] = nil
				self:FreshItemNPC(npc_data)
			end
		end
	end
end
function View:listEvent()
	return{
	"KAO_ROU_START",
	"GET_GUILD_PROP_SUC",
	"Guild_task_change",
	"ITEM_INFO_CHANGE",
	"GUILD_TASK_CHANGEINFO",
	"KAO_ROU_END",
	"NOTIFY_TEAM_PLAYER_AFK_CHANGE",
	"GET_RANK_SELF_RESULT",
	"BARbBECUE_SUCCESS",
	"NPC_OBJ_INFO_CHANGE",
	}
end
return View