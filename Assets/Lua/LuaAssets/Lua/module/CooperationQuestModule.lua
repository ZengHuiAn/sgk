local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
--查询任务
local C_COOPERATED_TASK_QUERY_REQUERY = 11131
local C_COOPERATED_TASK_QUERY_RESPOND = 11132

--共享任务
local C_COOPERATED_TASK_TRANSPOND_REQUERY = 11137
local C_COOPERATED_TASK_TRANSPOND_RESPOND = 11138
--接受邀请
local C_COOPERATED_TASK_ANSWER_INVITE_REQUERY = 11133
local C_COOPERATED_TASK_ANSWER_INVITE_RESPOND = 11134

--取消任务
local C_COOPERATED_TASK_CANCEL_REQUERY = 11139
local C_COOPERATED_TASK_CANCEL_RESPOND = 11140
--完成任务
local C_COOPERATED_TASK_REWARD_REQUERY = 11135
local C_COOPERATED_TASK_REWARD_RESPOND = 11136

local NOTIFY_COOPERATED_QUEST_CHANGE = 11141--合作任务改变
local NOTIFY_COOPERATED_QUEST_INVITE_FROM_LIST_ADD = 11145 --被邀请通知

local cooperationQuestTab = nil
local function GetQuestConfig(quest_id)
	if not cooperationQuestTab then
		cooperationQuestTab = {};	
		DATABASE.ForEach("double_quest", function(data)
			local _reward = {}
			for i=1,3 do
				if data["reward_type"..i] ~= 0 and  data["reward_id"..i] ~= 0 and data["reward_value"..i] ~= 0 then
					table.insert(_reward,{type=data["reward_type"..i],id=data["reward_id"..i],value = data["reward_value"..i]})
				end
			end
			if not cooperationQuestTab[data.quest_id] then
				cooperationQuestTab[data.quest_id] = setmetatable({reward =_reward,share =1 },{__index= data})
			end
			if not cooperationQuestTab[data.share_id] then
				cooperationQuestTab[data.share_id] = setmetatable({reward =_reward,share =2 },{__index= data})
			end
		end)
	end

	if quest_id and cooperationQuestTab[quest_id] then
		return cooperationQuestTab[quest_id]
	end
end

local function ON_SERVER_RESPOND(id, callback)
    EventManager.getInstance():addListener("server_respond_" .. id, callback);
end

local function ON_SERVER_NOTIFY(id, callback)
    EventManager.getInstance():addListener("server_notify_" .. id, callback);
end

local Sn2Data = {};
local CooperationQuestTab = {}

local function GetQuestList(pid,func)
	local sn = NetworkService.Send(C_COOPERATED_TASK_QUERY_REQUERY,{nil,pid});
	CooperationQuestTab[pid] = CooperationQuestTab[pid] or {}
	Sn2Data[sn] = {pid = pid,func = func}
end

local function GetQuest(pid,quest_id,share,func)
	pid = pid or module.playerModule.GetSelfID()
	if CooperationQuestTab[pid] then
		if pid and quest_id and share then
			if CooperationQuestTab[pid][share] and CooperationQuestTab[pid][share][quest_id] then
				return CooperationQuestTab[pid][share][quest_id]
			end
		else
			if func then
				func()
			else
				return CooperationQuestTab[pid]
			end
		end
	else
		GetQuestList(pid,func)
	end
end

local function updateQuestData(queryPid,pid,partnerPid,quest_id,share_id,acceptTime,status)
	if pid ~=0 then
		if CooperationQuestTab[queryPid] then
			if pid == queryPid then				
				CooperationQuestTab[queryPid][1] = CooperationQuestTab[queryPid][1] or {}
				CooperationQuestTab[queryPid][1][quest_id] = {pid= pid,partnerPid = partnerPid,quest_id = quest_id,share_id = share_id,status=status,acceptTime = acceptTime}
				DispatchEvent("COOPERAQUEST_INFO_CHANGE",{quest_id,queryPid})
			else
				CooperationQuestTab[queryPid][2] = CooperationQuestTab[queryPid][2] or {}
				CooperationQuestTab[queryPid][2][share_id] = {pid= pid,partnerPid = partnerPid,quest_id = quest_id,share_id = share_id,status=status,acceptTime = acceptTime}
				DispatchEvent("COOPERAQUEST_INFO_CHANGE",{share_id,queryPid})
			end
		else
			ERROR_LOG("CooperationQuestTab is nil")
		end
	end
end

ON_SERVER_RESPOND(C_COOPERATED_TASK_QUERY_RESPOND, function(event, cmd, data)
	-- ERROR_LOG("查询任务",sprinttb(data))
	local sn = data[1];
	local err = data[2];

	if err == 0 then
		if Sn2Data[sn] then
			local _pid = Sn2Data[sn].pid
			if data[3] and next(data[3]) then
				for i=1,#data[3] do
					if data[3][i][1] and data[3][i][3] then
						updateQuestData(_pid,data[3][i][1],data[3][i][2],data[3][i][3],data[3][i][4],data[3][i][5],data[3][i][6])
					end
				end
			end
			if Sn2Data[sn].func then
				Sn2Data[sn].func()
			end
			DispatchEvent("COOPERAQUEST_LIST_CHANGE",_pid)
			Sn2Data[sn] = nil
		end
	else
		ERROR_LOG("查询失败 err,",err)
	end
end)

local function ShareQuest(partnerPid,quest_id)
	-- ERROR_LOG("共享",partnerPid,quest_id)
	NetworkService.Send(C_COOPERATED_TASK_TRANSPOND_REQUERY, {nil,quest_id,partnerPid});
end

ON_SERVER_RESPOND(C_COOPERATED_TASK_TRANSPOND_RESPOND, function(event, cmd, data)
	-- ERROR_LOG("共享任务",sprinttb(data))
	local sn = data[1];
	local result = data[2];
	if result == 0 then
		showDlgError(nil,"任务已共享")
	else
		ERROR_LOG("共享任务 err,err",result)
	end
end)

local function CancelQuest(quest_id,share)
	-- ERROR_LOG("放弃任务",quest_id,share)
	local _questCfg = GetQuestConfig(quest_id)
	if _questCfg then
		local sn = NetworkService.Send(C_COOPERATED_TASK_CANCEL_REQUERY, {nil,quest_id,share});
		Sn2Data[sn] = {quest_id = _questCfg.share_id,share=share, pid = module.playerModule.GetSelfID()}
	else
		ERROR_LOG("cooperaQuest cfg is nil ,id",_quest_id)
	end
end

ON_SERVER_RESPOND(C_COOPERATED_TASK_CANCEL_RESPOND, function(event, cmd, data)
	-- ERROR_LOG("取消任务",sprinttb(data))
	local sn = data[1];
	local result = data[2];
	if result ~= 0 then
		ERROR_LOG("取消任务 err,",result)
	end
	if Sn2Data[sn] then
		local _selfPid = module.playerModule.GetSelfID()
		local _quest_id,_share = Sn2Data[sn].quest_id,Sn2Data[sn].share
		if CooperationQuestTab[_selfPid][_share] then
			for k,v in pairs(CooperationQuestTab[_selfPid][_share]) do
				if k == _quest_id then
					CooperationQuestTab[_selfPid][_share][k] = nil
					break
				end
			end
		end
		DispatchEvent("COOPERAQUEST_INFO_CHANGE",{Sn2Data[sn].quest_id,Sn2Data[sn].pid})
		Sn2Data[sn] = nil
	end
end)

local function FinishQuest(quest_id)
	-- ERROR_LOG("完成任务",quest_id)
	local sn = NetworkService.Send(C_COOPERATED_TASK_REWARD_REQUERY, {nil,quest_id,1});
	Sn2Data[sn] = {quest_id = quest_id}
end

ON_SERVER_RESPOND(C_COOPERATED_TASK_REWARD_RESPOND, function(event, cmd, data)
	-- ERROR_LOG("完成任务",sprinttb(data))
    local sn = data[1];
    local result = data[2];
    if result == 0 and Sn2Data[sn] then
    	DispatchEvent("COOPERAQUEST_INFO_CHANGE",{Sn2Data[sn].quest_id,module.playerModule.GetSelfID()})
		Sn2Data[sn] = nil
    end
end)

ON_SERVER_NOTIFY(NOTIFY_COOPERATED_QUEST_CHANGE,function(event, cmd, data)
	-- ERROR_LOG("合作任务改变",sprinttb(data))
	if data[1] == module.playerModule.GetSelfID() then
		updateQuestData(data[1],data[1],data[2],data[3],data[4],data[5],data[6])
		if data[2]~=0 then
			if module.playerModule.IsDataExist(data[2]) then
				local _playerData = module.playerModule.Get(data[2]);
				if _playerData then
					showDlgError(nil,string.format("%s 已接受您的历练邀请",_playerData.name))
				end
			else
				module.playerModule.Get(data[2],function ( ... )
					local _playerData = module.playerModule.Get(data[2]);
					if _playerData then
						showDlgError(nil,string.format("%s 已接受您的历练邀请",_playerData.name))
					end
				end)
			end
		end
	else
		updateQuestData(data[2],data[1],data[2],data[3],data[4],data[5],data[6])
	end
end)

local InviteList = {}
local function InviteTipDeQueue()
	if utils.SceneStack.CurrentSceneName() == 'battle' then
		return
	end
	if next(InviteList) then
		table.sort(InviteList,function (a,b)
			return a.inviteTime<b.inviteTime
		end)
		if InviteList[1] then
			local _pid,_quest_id,_inviteTime = InviteList[1].pid,InviteList[1].quest_id,InviteList[1].inviteTime
			if _pid and _quest_id then
				DialogStack.PushPref("Tips/shareQuestTip",{_quest_id,_pid,_inviteTime},UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject)
			end
			table.remove(InviteList,1);
		end
	end
end

utils.EventManager.getInstance():addListener("SCENE_LOADED", function(event, name)
    InviteTipDeQueue()
end)

local function InviteTipEnQueue(pid,quest_id)
	local init = false
	for i=1,#InviteList do
		if InviteList[i].pid == pid then
			init = true
			InviteList[i].quest_id = quest_id
			InviteList[i].inviteTime = module.Time.now()
		end
	end
	if not init then
		table.insert(InviteList,{pid = pid,quest_id = quest_id,inviteTime = module.Time.now()})
	end

	if #InviteList == 1 then
		InviteTipDeQueue();
	end
end

ON_SERVER_NOTIFY(NOTIFY_COOPERATED_QUEST_INVITE_FROM_LIST_ADD,function(event, cmd, data)
	-- ERROR_LOG("NOTIFY_COOPERATED_QUEST_INVITE_FROM_LIST_ADD",sprinttb(data))
	if data and data[1] and data[3] then
		local quest = module.QuestModule.GetCfg(data[3])
		if quest then 
			local _quest_id,_pid = data[3],data[1]
			InviteTipEnQueue(_pid,_quest_id)
		else
			ERROR_LOG("questCfg is nil,questId",data[3])
		end
	end
end)

local function AcceptQuest(pid,quest_id)
	-- ERROR_LOG("接受",pid,quest_id)
	local sn = NetworkService.Send(C_COOPERATED_TASK_ANSWER_INVITE_REQUERY, {nil,quest_id,pid});
	Sn2Data[sn] = {pid = pid,quest_id = quest_id}
end

ON_SERVER_RESPOND(C_COOPERATED_TASK_ANSWER_INVITE_RESPOND, function(event, cmd, data)
	-- ERROR_LOG("接受邀请",sprinttb(data))
	local sn = data[1];
	local result = data[2];
	if result == 0 then
		if Sn2Data[sn] then
			local _pid,_quest_id,_selfPid = Sn2Data[sn].pid,Sn2Data[sn].quest_id,module.playerModule.GetSelfID()
			local _questCfg = GetQuestConfig(_quest_id)
			if _questCfg and _questCfg.share and _questCfg.share == 1 then
				InviteList = {}
			else
				ERROR_LOG("cooperaQuest cfg is nil ,id",_quest_id)
			end
			Sn2Data[sn] = nil
		end
	elseif result == 2 then
		showDlgError(nil,SGK.Localize:getInstance():getValue("lilianbiji_tip13"))
	end
end)

local function RefuseInvite()
	InviteTipDeQueue()
	-- ERROR_LOG("拒绝了共享任务")
end


local function CheckQuest(pid,quest_id)
	if pid == module.playerModule.GetSelfID() then return end
	GetQuest(pid,nil,nil,function ()
		local _questList = GetQuest(pid)
		if _questList and _questList[1] and next(_questList[1]) then

			for k,v in pairs(_questList[1]) do
				if v.partnerPid == 0 and k == quest_id then
					-- local quest_id = k
					local quest = module.QuestModule.GetCfg(quest_id)
		 			if module.playerModule.Get().level >= quest.depend.level then
		 				InviteTipEnQueue(pid,quest_id)
			 		else
			 			showDlgError(nil,"等级不足")
			 		end
					break
				elseif v.partnerPid == 1 then
					showDlgError(nil,SGK.Localize:getInstance():getValue("lilianbiji_tip13"))
				end
			end
		else
			ERROR_LOG("_questList is nil")
		end
		-- if _questList and _questList[1] and next(_questList[1]) then
		-- 	for k,v in pairs(_questList[1]) do
		-- 		if v.partnerPid == 0 then
		-- 			local quest_id = k
		-- 			local quest = module.QuestModule.GetCfg(quest_id)
		--  			if module.playerModule.Get().level >= quest.depend.level then
		--  				InviteTipEnQueue(pid,quest_id)
		-- 	 		else
		-- 	 			showDlgError(nil,"等级不足")
		-- 	 		end
		-- 			break
		-- 		elseif v.partnerPid == 1 then
		-- 			showDlgError(nil,SGK.Localize:getInstance():getValue("lilianbiji_tip13"))
		-- 		end
		-- 	end
		-- else
		-- 	ERROR_LOG("_questList is nil")
		-- end
	end)
end


return {
	GetCfg = GetQuestConfig,
	
	Get = GetQuest,
	Share = ShareQuest,
	Accept = AcceptQuest,
	Cancel = CancelQuest,
	Finish = FinishQuest,
	Refuse = RefuseInvite,
	Check = CheckQuest,
}
