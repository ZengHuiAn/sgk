local NpcFriendList = nil
local ItemRelyNpcList = nil
local function GetNpcFriendList()
	if not NpcFriendList then
		NpcFriendList = {}
		ItemRelyNpcList = {}
		--NpcFriendList = LoadDatabaseWithKey("arguments_npc","npc_id")
		DATABASE.ForEach("arguments_npc", function(row)
			NpcFriendList[row.npc_id] = row
			ItemRelyNpcList[row.arguments_item_id] = row
		end)
	end
	return NpcFriendList
end
local function GetItemRelyNpc(itemid)
	if not ItemRelyNpcList then
		GetNpcFriendList()
	end
	return ItemRelyNpcList[itemid]
end
local npcList = nil
local function GetnpcList()
	if not npcList then
		npcList = LoadDatabaseWithKey("true_npc","npc_id")
	end
	return npcList
end
local npc_talking = nil
local function Get_npc_talking(id)
	if not npc_talking then
		npc_talking = {}
		DATABASE.ForEach("arguments_npc_talking", function(row)
			if not npc_talking[row.npc_id] then
				npc_talking[row.npc_id] = {}
			end
			npc_talking[row.npc_id][#npc_talking[row.npc_id]+1] = row
		end)
	end
	return npc_talking[id]
end
local npcDialogCfg = nil
local function GetnpcDialog()
	if not npcDialogCfg then
		npcDialogCfg = LoadDatabaseWithKey("favorability_story","story_id")
	end
	return npcDialogCfg
end
local npcTopic = nil
local function GetnpcTopic(id)
	if not npcTopic then
		npcTopic = {}
		local nameNum = {}
		local key = 1
		DATABASE.ForEach("favorability", function(row)
			if not npcTopic[row.npc_id] then
				npcTopic[row.npc_id] = {}
				nameNum[row.npc_id] = {}
				key = 1
			end
			if not nameNum[row.npc_id][row.topic] then
				nameNum[row.npc_id][row.topic] = key
				key = key + 1
			end
			--print(sprinttb(nameNum))
			if not npcTopic[row.npc_id][nameNum[row.npc_id][row.topic]] then
				npcTopic[row.npc_id][nameNum[row.npc_id][row.topic]] = {}
			end
			npcTopic[row.npc_id][nameNum[row.npc_id][row.topic]][#npcTopic[row.npc_id][nameNum[row.npc_id][row.topic]] + 1] = row
		end)
	end
	if id then
		return npcTopic[id]
	else
		return npcTopic
	end
end

local npcBubble = nil
local function GetBubbleByNpcID(id)
    if not npcBubble then 
        npcBubble = {}
        DATABASE.ForEach("npc_bubble", function(row)
            npcBubble[row.npc_id] = npcBubble[row.npc_id] or {}
            npcBubble[row.npc_id][row.type] = npcBubble[row.npc_id][row.type] or {}
            table.insert(npcBubble[row.npc_id][row.type],{id = row.id, duration = row.duration, style = row.style, desc = row.des})
        end)
    end
    if id then
        return npcBubble[id]
    else
        return npcBubble
    end
end

local npcGiftDescList = nil
local function GetGiftDescList(id)
	if not npcGiftDescList then 
        npcGiftDescList = {}
        DATABASE.ForEach("favorability_language", function(row)
			if not npcGiftDescList[row.npc_id] then
				npcGiftDescList[row.npc_id] = {}
			end
			npcGiftDescList[row.npc_id][#npcGiftDescList[row.npc_id]+1] = row
		end)
    end
    if id then
        return npcGiftDescList[id]
    else
        return npcGiftDescList
    end
end

return {
	GetNpcFriendList = GetNpcFriendList,
	GetnpcList = GetnpcList,
	Get_npc_talking = Get_npc_talking,
	GetItemRelyNpc = GetItemRelyNpc,
	GetnpcTopic = GetnpcTopic,
	GetnpcDialog = GetnpcDialog,
	GetBubbleByNpcID = GetBubbleByNpcID,
	GetGiftDescList = GetGiftDescList,
}