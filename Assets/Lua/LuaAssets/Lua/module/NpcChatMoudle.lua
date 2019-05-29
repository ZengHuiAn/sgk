local QuestModule = require "module.QuestModule"
local npcConfig = require "config.npcConfig"

local function CheckNeedQuest(needQuest)
	local index = nil
		for i,v in pairs(needQuest) do
			local k=tonumber(v)
			if k ~= 0 then
				local quest = QuestModule.Get(k)
				print("zoezeo",k,sprinttb(quest))
				if quest==nil or quest.status == 0 then
					index = i-1
					break
				end
			end
		end
	return index
end

local npcFriendCfg = nil
local function GetNpcRelation(npc_id)
	if not npcFriendCfg then
		npcFriendCfg=npcConfig.GetNpcFriendList()
	end
	local needQuest = StringSplit(npcFriendCfg[npc_id].quest_up,"|")
	return CheckNeedQuest(needQuest)
end

local npcRedDot = nil
local function CheckNpcDataRedDot(npc_id,point,stageNum,relation)
	if not npcRedDot then
		npcRedDot = {}
	end
	if not npcRedDot[npc_id] then
		npcRedDot[npc_id] = {}
	end
	--print("查看NPC事件红点表",sprinttb(npcRedDot))
	if npcRedDot[npc_id][stageNum] then
		return false
	end
	if point >= tonumber(relation[#relation]) then
		return false
	end
	if point >= tonumber(relation[stageNum+2]) then
		return true
	end
	return false
end

local function SetNpcRedDotFlag(npc_id,stageNum)
	if not npcRedDot then
		npcRedDot = {}
	end
	if not npcRedDot[npc_id] then
		npcRedDot[npc_id] = {}
	end
	npcRedDot[npc_id][stageNum] = true
end

return{
	GetNpcRelation = GetNpcRelation,
	CheckNpcDataRedDot = CheckNpcDataRedDot,
	SetNpcRedDotFlag = SetNpcRedDotFlag,
}