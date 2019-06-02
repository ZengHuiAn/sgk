local all_hide_config = nil
local all_hide_config_type = nil
local all_hide_config_npc = nil

local all_hide_config_map = nil

local function LoadHideConfig()
    if not all_hide_config then
        all_hide_config_map = all_hide_config_map or {}
        all_hide_config = all_hide_config or {}
        all_hide_config_npc = all_hide_config_npc or {}
        all_hide_config_type = all_hide_config_type or {}
        DATABASE.ForEach("hide_reward", function(row)
            all_hide_config[row.id] = row;
            all_hide_config_type[row.type] = all_hide_config_type[row.type] or {}
            all_hide_config_type[row.type][row.map_id] = all_hide_config_type[row.type][row.map_id] or {}
            
            all_hide_config_type[row.type][row.map_id][row.npc_id] = row;
            table.insert( all_hide_config_type[row.type], row )
            all_hide_config_npc[row.npc_id] = all_hide_config_npc[row.npc_id] or {};

            table.insert( all_hide_config_npc[row.npc_id], row )

            all_hide_config_map[row.map_id] = all_hide_config_map[row.map_id] or {}
            table.insert( all_hide_config_map[row.map_id], row )
		end)
    end
end


local function GetConfig(type,mapid,npcid)
    LoadHideConfig();
    if type and mapid and npcid then
        return all_hide_config_type[type][mapid][npcid];
    end
    if type and mapid then
        return all_hide_config_type[type][mapid]
    end
    if type then
        return all_hide_config_type[type]
    end

    if mapid then
        ERROR_LOG(sprinttb(all_hide_config_map));
        return all_hide_config_map[mapid]
    end

    if npcid then
        return all_hide_config_npc[npcid]
    end
    return nil
end

local Manager = {}

function Manager:Init(map_id)
    local cfg = MapNpcModule.GetConfig(nil,map_id,nil);
    local quest = {};
    self.kill = {};
    for k,v in pairs(cfg) do
        local v_quest = sharedQuestModule.GetCfg(v.npc_id);
        quest[v.npc_id] = v_quest;
    end
    self.map_cfg = quest;

end


function Manager:Clear()
    self.map_cfg = nil;
end
--彩蛋NPC信息交互
local inter_npc_info = nil

local function SetNPCCount( id )
    inter_npc_info = inter_npc_info or {}

    inter_npc_info[id] = inter_npc_info[id] or {}

    if inter_npc_info[id].start_time and (math.floor(inter_npc_info[id].start_time/3600/24) ~= math.floor(module.Time.now()/3600/24)) then
        inter_npc_info[id] = {start_time = module.Time.now(), count = 0 }
    else
        if not inter_npc_info[id].start_time then
            inter_npc_info[id] = {start_time = module.Time.now(),count = inter_npc_info[id].count or 0}
        end
    end
    inter_npc_info[id].count = inter_npc_info[id].count + 1
end

local function GetNPCCount( id )

    if inter_npc_info[id] then
        return inter_npc_info[id].count
    end

    return 0
end
--彩蛋NPC特殊对话交互
local randomPool = nil
local index = nil
local function ClearPool()
    randomPool = nil
    index = nil
end

local function GetIndex(id,start,max)
    if GetNPCCount(id) == 0 then
        ClearPool()
    end
    if not index then
        index = start
    else
        index = index + 1
    end
    if index > max then
        index = max
    end
    return index
end

local function GetRandom(id,min,max)
    if GetNPCCount(id) == 0 then
        ClearPool()
    end
    if randomPool == nil then
        randomPool = {}
        for i=min,max do
            randomPool[i]=i
        end
    end
    -- print("23222222222",GetNPCCount(id),sprinttb(randomPool))
    local index = math.random(min,max-GetNPCCount(id))
    local num = randomPool[index]
    -- print("4444444444444444",index)
    table.remove(randomPool,index)
    -- print("随机库",sprinttb(randomPool))
    return num 
end

local function GetRandomPSW()
    math.randomseed(math.floor(module.Time.now()/3600/24))
    local randomPSWPool = {}
    for i=1,4 do
        randomPSWPool[i]=i
    end
    local result = {}
    for i=1,4 do
        local index = math.random(1,5-i)
        result[#result + 1] = randomPSWPool[index]
        table.remove(randomPSWPool,index)
    end
    return result
end

local PSW = nil

local function ClearPSW()
    PSW = nil
end

local function CheckPSW(table)
    local result = GetRandomPSW()
    ClearPSW()
    if #table ~= #result then
        return 0
    end
    for i=1,#table do
        if table[i] ~= result[i] then
            return 0
        end
    end
    return 1
end

local function SetPSW(num)
    if PSW == nil then
        PSW = {}
        PSW[#PSW+1]=num
        return 2
    else
        for i=1,#PSW do
            if PSW[i] == num then
                return 2
            end
        end
        PSW[#PSW+1]=num
        if #PSW == 4 then
            return CheckPSW(PSW)
        else
            return 2
        end
    end

end
-- MAP_SCENE_READY

-- utils.EventManager.getInstance():addListener("LOCAL_SHAREDQUEST_INFO_CHANGE", function(event, data)
--     -- local mapid = SceneStack.MapId() 
--     -- if data == 1 then
--     --     local cfg = GetConfig(nil,mapid,nil);
--     --     ERROR_LOG("进入到地图",mapid);
--     --     if cfg then
--     --         local str = MapNpcManagerModule.Manager:Init(mapid);
--     --         print("========>>>",str)
--     --     end
--     -- end

-- end)

local function RandomRegion( offest, max )
    max = max or 100
    offest = offest > max and max or offest
    math.randomseed(module.Time.now()*100)

    local result = math.random(1,max);
    return result <= offest;
end


--彩蛋锤子

local npc_randomPool = {
    [6014002]= {},
    [6014003]= {},
    [6014004]= {},
    [6014005]= {},
    [6014006]= {},
}

local function Reset_random_pool( ... )
    npc_randomPool = {
    [6014002]= {},
    [6014003]= {},
    [6014004]= {},
    [6014005]= {},
    [6014006]= {},
}
end
local init_flag ;

local function LoadRandomHammer()

    local temp = {1,2,3,4,5}



    for k,v in pairs(npc_randomPool) do
        local ret = module.Time.now() *100
        math.randomseed(ret)
        local index = math.random( 1,#temp )
        v.random = temp[index];
        table.remove( temp, index )
    end
end


local function GetRandomNPC_Hammer(npcid )
    npcid = tonumber(npcid)

    if not init_flag then
        LoadRandomHammer();
        init_flag = 1
    end


    if not npc_randomPool[npcid] or npc_randomPool[npcid].inter then
        return
    end
    
    npc_randomPool[npcid].inter  = init_flag
    init_flag = init_flag +1
    ERROR_LOG("随机池数据",sprinttb(npc_randomPool))
    return npc_randomPool[npcid].random == 5
end

local function checkHammerCount(  )
    return init_flag
end



utils.EventManager.getInstance():addListener("SCENE_LOADED", function(event, data)
    ClearPSW()
end)

utils.EventManager.getInstance():addListener("MAP_SCENE_READY", function(event, data)
    inter_npc_info = {}
    init_flag = nil
    Reset_random_pool()
end)
local fresh_time = 3600*24
local npc_fresh_coro = nil
local function StartCoro( id ,func)
    npc_fresh_coro = npc_fresh_coro or {}
    if npc_fresh_coro[id] then
        npc_fresh_coro[id]:Kill();
    end

    local offest = (math.floor(module.Time.now()/fresh_time)+1)*fresh_time - module.Time.now()
    npc_fresh_coro[id] = SGK.Action.DelayTime.Create(offest):OnComplete(function()
        if func then
            func();
        end
    end)
end


return {
    GetConfig = GetConfig,

    GetNPCCount = GetNPCCount,

    SetNPCCount = SetNPCCount,

    GetIndex = GetIndex,
 
    GetRandom = GetRandom,

    ClearPool = ClearPool,

    GetRandomPSW = GetRandomPSW,

    SetPSW = SetPSW,

    StartCoro = StartCoro,

    RandomRegion = RandomRegion,

    RandomHammer = GetRandomNPC_Hammer,
    GetHammerCount = checkHammerCount
}



