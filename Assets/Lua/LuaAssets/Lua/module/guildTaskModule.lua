local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local guildTaskCfg = require "config.guildTaskConfig"

local guild_task_list = nil
local function SetGuild_task_list(_data,type)
	if not guild_task_list then
		guild_task_list = {}
	end
	if not guild_task_list[type] then
		guild_task_list[type] = {}
	end
	for i =  1,#_data do
		local data = _data[i]
		local list = {}
		local quest_id = data[2]
		local pid = data[1]
		if not guild_task_list[type][quest_id] then
			guild_task_list[type][quest_id] = {}
		end
		guild_task_list[type][quest_id][pid] = {
			pid = pid,
			quest_id = quest_id,
			status = data[3],
			count = data[4],
			record = {data[5],data[6],data[7]},
			consume_item_save1 = data[8],
			consume_item_save2 = data[9],
			accept_time = data[10],
			submit_time = data[11],
			next_time_to_accept = data[12],--下次任务可领取时间
			quest_stage = {},
	 	}
	 	local idx = #guild_task_list[type][quest_id][pid]
	 	for j = 1,#data[13] do
	 		list[#list+ 1] = {pid = data[13][j][1],reward_flag = data[13][j][2],contribituion = data[13][j][3]}
	 	end
	 	guild_task_list[type][quest_id][pid].quest_stage = list
	end
	DispatchEvent("Guild_task_change")
end
local function GetGuild_task_list()
	if not guild_task_list then
		NetworkService.Send(3357)
	end
	return guild_task_list
end


local function Clear_task()
	guild_task_list = nil;
end


EventManager.getInstance():addListener("server_respond_3358", function(event, cmd, data)
	local sn = data[1]
	local err = data[2]
	if err == 0 then
		-- ERROR_LOG("3358",sprinttb(data))
		SetGuild_task_list(data[3],1)--军团共享任务
		SetGuild_task_list(data[4],2)--军团个人任务

		-- ERROR_LOG("任务发生改变",data[2]);
	end
end)

local waiting_co = {}
local function Start_GUILD_QUEST(quest_id)
	-- ERROR_LOG("3360",quest_id)
	local sn = NetworkService.Send(3359,{nil,quest_id})

	local co = coroutine.running();
	if coroutine.isyieldable() then
		waiting_co[sn] = {co = co, scene_index = SceneService.sceneIndex}
		return coroutine.yield();
	end
end
local function End_GUILD_QUEST(quest_id)

	NetworkService.Send(3363,{nil,quest_id})
end

EventManager.getInstance():addListener("server_respond_3360", function(event, cmd, data)
	-- ERROR_LOG("3360",sprinttb(data))
	local sn = data[1]
	local err = data[2]
	if err == 0 then
		-- ERROR_LOG("3360",sprinttb(data))
		if data[3] == 1 then
			DispatchEvent("GUILD_TASK_JUMP");
		end
	end

	if waiting_co[sn] then
		local info = waiting_co[sn];
		waiting_co[sn] = nil

		if info.scene_index == SceneService.sceneIndex then
			coroutine.resume(info.co, err);
		end
	end
end)

local task_stack = nil;

EventManager.getInstance():addListener("server_notify_1128",function ( event,cmd,data)
	if data[1] == 0 then
		SetGuild_task_list({data},1)--军团共享任务
	else

		local pid = math.floor( module.playerModule.Get().id );

		if guild_task_list and guild_task_list[2] then
			-- body
			local _status = guild_task_list[2][data[2]]
			
			-- ERROR_LOG("===========任务发生改变",data[2],sprinttb(_status));
			local flag1 = 0
			if not _status or not _status[pid] then
			
			else
				flag1 = _status and _status[pid].status or 0;
			end
			SetGuild_task_list({data},2)--军团个人任务
	
			local status = guild_task_list[2][data[2]]
			local flag2 = status[pid].status;
			
			task_stack = task_stack or {};
	
			if flag1 == 0 and flag2 == 1 then

				local info = guildTaskCfg.GetguildTask(data[2]);
				local temp = nil;
				for i=1,3 do
					if info["reward_type"..i] == 94 then
						temp = info["reward_id"..i];
					end	
				end

				if temp then

					-- ERROR_LOG("奖励的道具数量", module.ItemModule.GetItemCount(temp));
					if module.ItemModule.GetItemCount(temp)<=0 then
						StartCoroutine(function ( ... )
							WaitForSeconds(2);
							showDlgError(nil,"今日奖励次数已达上限，无法获得奖励");
						end)
					end
				end
				-- ERROR_LOG("有任务完成",data[2]);
				-- -- table.insert( task_stack,1,data[2])
				-- showDlgError(nil,"任务完成"..data[2]);
			end
			-- ERROR_LOG("===========任务发生改变",data[2],sprinttb(status));
		end

	end
	DispatchEvent("GUILD_TASK_CHANGEINFO",data[2]);
end)
local function GuildSubmitItems(quest_id,item_id,cost_value)
	-- ERROR_LOG("->",item_id,cost_value)
	NetworkService.Send(3381,{nil,quest_id,item_id,cost_value})
end
EventManager.getInstance():addListener("server_respond_3382", function(event, cmd, data)
	local sn = data[1]
	local err = data[2]
	if err == 0 then
		-- ERROR_LOG("3382",sprinttb(data))
	end
end)
local function GetReward(quest_id,idx)
	-- ERROR_LOG(quest_id,"_",idx)
	NetworkService.Send(3383,{nil,quest_id,idx})
end
EventManager.getInstance():addListener("server_respond_3384", function(event, cmd, data)
	local sn = data[1]
	local err = data[2]
	if err == 0 then
		-- ERROR_LOG("3384",sprinttb(data))
	end
end)
local now_guildTask_npc = nil



local function Setnow_guildTask_npc(npcid,guild_task_cfg)
	-- if now_guildTask_npc then return end 
	now_guildTask_npc = now_guildTask_npc or {} ;
	if npcid then

		now_guildTask_npc[tonumber(npcid)] = guild_task_cfg
	end
end
local function Getnow_guildTask_npc(npcid)
	return now_guildTask_npc[tonumber(npcid)]
end
return{
	GetGuild_task_list = GetGuild_task_list,
	Start_GUILD_QUEST = Start_GUILD_QUEST,
	End_GUILD_QUEST = End_GUILD_QUEST,
	GuildSubmitItems = GuildSubmitItems,
	GetReward = GetReward,
	Setnow_guildTask_npc = Setnow_guildTask_npc,
	Getnow_guildTask_npc = Getnow_guildTask_npc,
	Clear_task 	= Clear_task,
}