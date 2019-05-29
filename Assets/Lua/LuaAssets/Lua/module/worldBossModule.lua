local Type = {
    World = 1,
    Union = 2,
}

local bossInfo = {}
local bossRankInfo = {}
local bossReplayInfo = {}


local AccumulativeRankings = 0

local boss_end_attack = nil

local function merge_reward(t, a, b)
    if t then
        t.reward = {}
        for i = a, b do
            local _type, _id = t["reward_type" .. i], t["reward_id" .. i]
            if _type and _id then
                if _type ~= 0 and _id ~= 0 then
                    table.insert(t.reward, {type = _type, id = _id})
                end
            end
        end
    end
    return t;
end

local bossCfgList = nil
local function GetBossCfg(id)
    if not bossCfgList then
        bossCfgList = {raw = LoadDatabaseWithKey("world_boss", "id")}
        setmetatable(bossCfgList, {__index = function(t, k)
            local _cfg = t.raw[k]
            if _cfg then
                rawset(t, k, merge_reward(_cfg, 0, 4))
            end
            return _cfg
        end})
    end
    if not id then
        return bossCfgList
    end
    return bossCfgList[id]
end


local bossConfig = nil
local function GetBossConfig(type)
    if not bossConfig then
        bossConfig= bossConfig or {};
        DATABASE.ForEach("world_boss", function(row)
            bossConfig[row.type] = bossConfig[row.type] or {};


            table.insert( bossConfig[row.type], row );
        end)
    end 

    return bossConfig[type];
end


local bossRewardCfgList = nil
local function GetBossRewardCfg(typeId, level)
    if not bossRewardCfgList then
        bossRewardCfgList = {}
        DATABASE.ForEach("phase_reward", function(row)
            if not bossRewardCfgList[row.type_id] then bossRewardCfgList[row.type_id] = {} end
            if not bossRewardCfgList[row.type_id][row.lv_max] then bossRewardCfgList[row.type_id][row.lv_max] = {} end
            local _tab = row
            _tab.reward = {}
            for i = 1, 3 do
                if row["reward_type"..i] ~= 0 and row["reward_id"..i] ~= 0 then
                    table.insert(_tab.reward, {id = row["reward_id"..i], type = row["reward_type"..i], value = row["reward_value"..i]})
                end
            end
            table.insert(bossRewardCfgList[row.type_id][row.lv_max], _tab)
        end)
    end
    if typeId and level then
        for k,v in pairs(bossRewardCfgList[typeId] or {}) do
            if k >= level and v[1].lv_min <= level then
                return v
            end
        end
    end
end

local function queryRankInfo()
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(11117, {nil})
    else
        utils.NetworkService.Send(11117, {nil})
    end
end

local function queryInfo(typeId)
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(11095, {nil, typeId})
    else
        utils.NetworkService.Send(11095, {nil, typeId})
    end
end

local function queryReplay(typeId)
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(11097, {nil, typeId})
    else
        utils.NetworkService.Send(11097, {nil, typeId})
    end
end

local function attackBoss(typeId,gid)
    if coroutine.isyieldable() then
        -- ERROR_LOG("攻击boss"..typeId);
        return utils.NetworkService.SyncRequest(11099, {nil, typeId,gid})
    else
        -- ERROR_LOG("攻击boss"..typeId)
        utils.NetworkService.Send(11099, {nil, typeId,gid})
    end
end

local function queryRank(typeId)
    if coroutine.isyieldable() then
        return utils.NetworkService.SyncRequest(11101, {nil, typeId})
    else
        utils.NetworkService.Send(11101, {nil, typeId})
    end
end

local function QueryWorldInfo()
    return queryInfo(Type.World)
end

local function QueryUnionInfo()
    return queryInfo(Type.Union)
end

local function QueryWorldReplay()
    return queryReplay(Type.World)
end

local function QueryUnionReplay()
    return queryReplay(Type.Union)
end

local function AttackWorldBoss()
    return attackBoss(Type.World)
end

local function AttackUnionBoss()
    return attackBoss(Type.Union)
end

local function QueryWorldRank()
    return queryRank(Type.World)
end

local function QueryUnionRank()
    return queryRank(Type.Union)
end

local function QueryAll()
    queryRankInfo()
    local _world = QueryWorldInfo()
    if _world[2] == 0 and _world[3] then
        QueryWorldReplay()
        QueryWorldRank()
    end
end

--flag1 0-29
--flag2 30-59
--flag3 60-89
--flag4 90-119
local function upReplay(type, data)
    local _tab = {
        bossId    = data[1],
        pid       = data[2],
        harm      = data[3],
        time      = data[4],
        fightData = data[5],
    }
    if not bossReplayInfo[type] then bossReplayInfo[type] = {} end
    if not bossReplayInfo[type].replayInfo then bossReplayInfo[type].replayInfo = {} end
    if not bossReplayInfo[type].replayInfo[_tab.pid] then bossReplayInfo[type].replayInfo[_tab.pid] = {} end

    table.insert(bossReplayInfo[type].replayInfo[_tab.pid], _tab)
end

local function upRank(type, data)
    local _tab = {
        pid  = data[1] or 0,
        rank = data[2],
        harm = data[3],
    }
    bossRankInfo = bossRankInfo or {};
    bossRankInfo[type] = bossRankInfo[type] or {};
    bossRankInfo[type].rankInfo = bossRankInfo[type].rankInfo or {};
    bossRankInfo[type].rankInfo[_tab.pid] = _tab
end

local function GetBossInfo(type)
    if type then
        return bossInfo[type] or {}
    end
    return {}
end

local function GetReplayInfo(type)
    if type then
        return bossReplayInfo[type] or {}
    end
    return {}
end

local function GetRankInfo(type)
    if type then
        return bossRankInfo[type] or {}
    end
    return {}
end

local AtkTween = nil


local function DOATKTween( time,func )
    if AtkTween then
        AtkTween:Kill();
    end
    AtkTween = SGK.Action.DelayTime.Create(time):OnComplete(function()
        if func then
            func();
        end
    end)
end
--停止攻击
local function KILLATK(  )
    if AtkTween then
        AtkTween:Kill();
    end
end

local function dispatchBossOpenEvent(data)
    if data[3] == Type.World then
        local _cfg = data[4]
        local MapConfig = require "config.MapConfig"
        local _cfg = MapConfig.GetMapMonsterConf(data[4])
        if _cfg then
            local _mapCfg = MapConfig.GetMapConf(_cfg.mapid)
            if _mapCfg then
                local _data = {
                    [1] = 18,
                    [2] = _cfg.name,
                    [3] = _mapCfg.map_name
                }
            end
        end
    end
end

-- 11126

utils.EventManager.getInstance():addListener("server_notify_11126", function(event, cmd, data)
    -- ERROR_LOG("boss 开启-------------->>>>>>> server_notify_11126",sprinttb(data));
    boss_end_attack = nil
    bossInfo = bossInfo or {};
    bossInfo[1] = {}
    bossInfo[1].type      = 1
    bossInfo[1].id        = data[1]
    bossInfo[1].beginTime = data[2]
    bossInfo[1].allHp     = data[3]
    bossInfo[1].hp        = data[4]
    bossInfo[1].duration  = data[5]
    bossInfo[1].bossLevel = data[6]
    bossInfo[1].nextTime  = data[7]
    bossInfo[1].watch     = data[8]
    -- ERROR_LOG("bossInfo---------------->>>",sprinttb(bossInfo));
    DispatchEvent("LOCAL_WORLDBOSS_INFO_CHANGE",1);
    module.NPCModule.Ref_NPC_LuaCondition()

end)

utils.EventManager.getInstance():addListener("server_respond_11096", function(event, cmd, data)
    -- ERROR_LOG("世界boss 查询 server_respond_11096",sprinttb(data))
    if data[2] == 0 and data[3] then
        bossInfo = bossInfo or {};
        bossInfo[data[3]] = {}
        bossInfo[data[3]].type      = data[3]
        bossInfo[data[3]].id        = data[4]
        bossInfo[data[3]].beginTime = data[5]
        bossInfo[data[3]].allHp     = data[6]
        if data[3] == 1 then
            
            bossInfo[data[3]].hp        = boss_end_attack and -1 or data[7]
        else
            bossInfo[data[3]].hp = data[7]
        end
        bossInfo[data[3]].duration  = data[8]
        bossInfo[data[3]].bossLevel = data[9]
        bossInfo[data[3]].nextTime  = data[10]
        bossInfo[data[3]].watch     = data[11]
        bossInfo[data[3]].dead     = data[12]

        DispatchEvent("LOCAL_WORLDBOSS_INFO_CHANGE",data[3])
        -- module.NPCModule.Ref_NPC_LuaCondition()
        if data[3] == 1 then
            module.NPCModule.Ref_NPC_LuaCondition()
        end

        coroutine.resume(coroutine.create(function()
            QueryWorldReplay()
            QueryWorldRank()
        end))
    end
end)

utils.EventManager.getInstance():addListener("server_respond_11098", function(event, cmd, data)
    -- ERROR_LOG(" 查询回放 server_respond_11098",sprinttb(data))
    if data[2] == 0 then
        bossReplayInfo[data[3]] = bossReplayInfo[data[3]] or {}
        bossReplayInfo[data[3]].type = data[3]
        bossReplayInfo[data[3]].replayInfo = {}
        for i,v in ipairs(data[4]) do
            upReplay(data[3], v)
        end
    end
end)

utils.EventManager.getInstance():addListener("server_respond_11100", function(event, cmd, data)
    -- ERROR_LOG("server_respond_11100",sprinttb(data))
    if data[2] == 0 then
        bossInfo = bossInfo or {};

        bossInfo[data[3]] = bossInfo[data[3]] or {}; 
        bossInfo[data[3]].nextTime = data[4]
        DispatchEvent("LOCAL_WORLDBOSS_ATTACK_INFO", {type = data[3], pid = module.playerModule.Get().id, oldHarm = 0, harm = data[5]})

        -- ERROR_LOG("--------------->>>攻击boss数值",data[5]);
        module.worldBossModule.PlayeBossAttackAnim(data[3], data[5],module.playerModule.Get().id)
    end
end)

utils.EventManager.getInstance():addListener("server_respond_11102", function(event, cmd, data)
    -- ERROR_LOG("server_respond_11102",sprinttb(data))
    if data[2] == 0 then
        bossRankInfo[data[3]] = bossRankInfo[data[3]] or {}
        bossRankInfo[data[3]].type = data[3]
        bossRankInfo[data[3]].rankInfo = {}
        for i,v in ipairs(data[4] or {}) do
            upRank(bossRankInfo[data[3]].type, v)
        end
        data[5] = data[5] or {}
        local _tab = {
            pid       = data[5][1],
            rank      = data[5][2],
            harm      = data[5][3],
            flag      = data[6],
            todayHarm = data[7] or 0,
        }
        bossRankInfo[data[3]].selfInfo = _tab
        --ERROR_LOG(sprinttb(bossRankInfo[data[3]].selfInfo))
    end
end)

utils.EventManager.getInstance():addListener("server_notify_11103", function(event, cmd, data)

    -- ERROR_LOG("回放通知server_notify_11103",sprinttb(data));
    local _data = {}
    for i = 2, 6 do
        _data[i - 1] = data[i]
    end
    upReplay(data[1], _data)
    queryInfo(data[1])
end)

local function PlayeBossAttackAnim(type, harm, pid)
    local _info = GetBossInfo(type)
    if _info and _info.id then
        local _obj = module.NPCModule.GetNPCALL(_info.id)
        if _obj then
            if pid == module.playerModule.GetSelfID() then
                local _effect = SGK.ResourcesManager.Load("prefabs/effect/boss_word_me.prefab")
                local _effectObj = UnityEngine.GameObject.Instantiate(_effect.gameObject, _obj.gameObject.transform)
                _effectObj.transform.localPosition = Vector3(0, 0, -0.1)
                local _view = CS.SGK.UIReference.Setup(_effectObj.gameObject)
                _view.word_ani["New Text "][UnityEngine.TextMesh].text = tostring(harm)
                UnityEngine.GameObject.Destroy(_effectObj, 1.6)
            else
                local _effect = SGK.ResourcesManager.Load("prefabs/effect/boss_word.prefab")
                local _effectObj = UnityEngine.GameObject.Instantiate(_effect.gameObject, _obj.gameObject.transform)
                _effectObj.transform.localPosition = Vector3(math.random(-100, 100) / 100, math.random(0, 200) / 100, -0.1)
                local _view = CS.SGK.UIReference.Setup(_effectObj.gameObject)
                _view.word_ani["New Text"][UnityEngine.TextMesh].text = tostring(harm)
                UnityEngine.GameObject.Destroy(_effectObj, 1.6)
            end
        end
    end
end

utils.EventManager.getInstance():addListener("server_notify_11104", function(event, cmd, data)

    -- ERROR_LOG("伤害通知server_notify_11104",sprinttb(data))
    local v = data[3]
    bossRankInfo[data[1]] = bossRankInfo[data[1]] or {}

    if v then

        if bossRankInfo[data[1]] then
            if bossRankInfo[data[1]].rankInfo and bossRankInfo[data[1]].rankInfo[v[1]] then
                local _harm = v[3] - bossRankInfo[data[1]].rankInfo[v[1]].harm
                -- ERROR_LOG("伤害============>>>>",v[3],bossRankInfo[data[1]].rankInfo[v[1]].harm,_harm);
                -- PlayeBossAttackAnim(data[1], v[3] - bossRankInfo[data[1]].rankInfo[v[1]].harm, v[1])

                -- bossRankInfo[data[1]].rankInfo.hp = bossRankInfo[data[1]].rankInfo.hp - v[3]
                DispatchEvent("LOCAL_WORLDBOSS_ATTACK_INFO", {type = data[1], pid = v[1], oldHarm = bossRankInfo[data[1]].rankInfo[v[1]].harm, harm = v[3]})

                -- bossRankInfo[data[1]].hp = bossRankInfo[data[1]].hp - v[3]

                -- ERROR_LOG(bossRankInfo[data[1]].hp);
            else
                -- PlayeBossAttackAnim(data[1], v[3], v[1])
                DispatchEvent("LOCAL_WORLDBOSS_ATTACK_INFO", {type = data[1], pid = v[1], oldHarm = 0, harm = v[3]})
            end
        end
        if bossRankInfo[data[1]] then
            upRank(data[1], v)
        end
    end


    data[3] = data[3] or {}
    local _tab = {
        pid       = data[3][1],
        rank      = data[3][2],
        harm      = data[3][3],
        flag      = data[4],
        todayHarm = data[5] or 0,
    }
    coroutine.resume(coroutine.create(function()
        local _union = QueryUnionInfo()
        if _union[2] == 0 and _union[3] ~= 0 then
            QueryUnionReplay()
            QueryUnionRank()
        end
    end))
    bossRankInfo[data[1]] = bossRankInfo[data[1]] or {}
    bossRankInfo[data[1]].selfInfo = _tab
end)


--军团boss伤害通知
utils.EventManager.getInstance():addListener("server_notify_11105", function(event, cmd, data)

    -- ERROR_LOG("server_notify_11105",sprinttb(data));
    if data[1] == 1 then

        ---被击杀

        coroutine.resume(coroutine.create(function()
            local _union = QueryUnionInfo()
            if _union[2] == 0 and _union[3] ~= 0 then
                QueryUnionReplay()
                QueryUnionRank()
            end
        end))
    else
        QueryUnionInfo()
    end
end)

utils.EventManager.getInstance():addListener("server_respond_11118", function(event, cmd, data)
    if data[2] == 0 then
        AccumulativeRankings = data[3]
    end
end)

local function ClearBossInfo()
    bossReplayInfo = {}
    bossRankInfo = {}
    module.NPCModule.Ref_NPC_LuaCondition()
    DispatchEvent("LOCAL_WORLDBOSS_INFO_CHANGE",1);
end

utils.EventManager.getInstance():addListener("server_notify_40", function(event, cmd, data)

    -- ERROR_LOG("跑马灯==============>>>>",sprinttb(data));
    if data[1] == 17 then

        -- ERROR_LOG("清除世界boss");
        module.worldBossModule.worldBossHunting();
        ClearBossInfo()
    elseif data[1] == 16 then
        module.worldBossModule.worldBossHunting();
        --最后一击
        for k,v in pairs(bossInfo) do
            if v.id == data[3] then
                v.hp = -1;
                if data[5] and data[5] == module.playerModule.GetSelfID() then
                    if data[4] then
                        local _itemTab = {}
                        for i,v in ipairs(data[4]) do
                            table.insert(_itemTab, {type = v[1], id = v[2], count = v[3]})
                        end
                        if #_itemTab > 0 then
                            DialogStack.PushPrefStact("mapSceneUI/GiftBoxPre", {itemTab = _itemTab, textName = SGK.Localize:getInstance():getValue("shijieboss_16")})
                        end
                    end
                end
                break
            end
        end

        if math.floor( data[5]  ) == math.floor(module.playerModule.Get().id) then
            SGK.Action.DelayTime.Create(3):OnComplete(function()
                boss_end_attack = true;
                bossInfo[1].hp = -1
                module.NPCModule.Ref_NPC_LuaCondition()
                DispatchEvent("LOCAL_WORLDBOSS_INFO_CHANGE");
           end)
        else
            boss_end_attack = true;

            bossInfo = bossInfo or {};
            bossInfo[1] = bossInfo[1] or {}
            bossInfo[1].hp = -1
            module.NPCModule.Ref_NPC_LuaCondition()
            DispatchEvent("LOCAL_WORLDBOSS_INFO_CHANGE");
        end
        
        
    end
end)

local activityBossIdList = {
    2102, 2103, 2104
}

utils.EventManager.getInstance():addListener("PLAYER_LEVEL_UP", function(event, data)

    if data >=18 then
        coroutine.resume(coroutine.create(function()
            local _world = QueryWorldInfo()
            if _world[2] == 0 and _world[3] then
                if _world[3] == Type.World then
                    -- ERROR_LOG("世界boss开启");
                    dispatchBossOpenEvent(_world)
                end
                QueryWorldReplay()
                QueryWorldRank()
            end
        end))
    end
    -- ERROR_LOG("玩家升级",data);
end)


utils.EventManager.getInstance():addListener("npc_init_succeed", function(event, data)
    local _cfg = module.worldBossModule.GetBossCfg(data)
    if _cfg and next(_cfg) then
       local npc = module.NPCModule.GetNPCALL(data)

        if npc then

            local npcinfo = npc.gameObject.transform:Find("npcInfo(Clone)");

            local _view = CS.SGK.UIReference.Setup(npcinfo.gameObject);


            local slider = UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load(_cfg.type == 1 and "prefabs/effect/HPSlider.prefab" or "prefabs/effect/guildHPSlider.prefab"),_view.Root.Canvas.gameObject.transform)

            slider.gameObject.transform.localScale = UnityEngine.Vector3.one
        end 
    end
end)
-- 


local function GetAccumulativeRankings()
    return AccumulativeRankings
end

-- C_WATCH_WORLD_BOSS_REQUEST = 11127    boss_id
-- C_WATCH_WORLD_BOSS_RESPOND = 11128
local function sendWatch( boss_id )
   utils.NetworkService.Send(11127,{nil,boss_id})
end

utils.EventManager.getInstance():addListener("server_respond_11128", function(event, cmd, data)

    if data[2] == 0 then
        -- showDlgError(nil,"关注成功");
    else
        -- showDlgError(nil,"关注失败");
    end
end)
local later_boss_rank = nil


local function uplaterRank(data )
   
    local temp = {}

    local selfrank = {pid = data[3][1],rank = data[3][2],harm = data[3][3]};

    local allrank = {};


    for i,v in ipairs(data[2]) do
        local item_rank = {pid = v[1],rank = v[2],harm = v[3]};
        table.insert(allrank,item_rank);
    end

    table.sort( allrank, function ( item1,item2 )
        return item1.rank <item2.rank;
    end )
    table.insert( later_boss_rank, {boss = data[1], allrank = allrank,selfrank = selfrank} );
    -- [npcid,rank_list:[pid, rank, score], player_rank:{[pid, rank, score}]
end


local snCallBack = nil
local function queryLaterRankInfo(call)

    snCallBack = snCallBack or {}
    local sn = utils.NetworkService.Send(11129, {nil})

    snCallBack[sn]={callback = call}
end

utils.EventManager.getInstance():addListener("server_respond_11130", function(event, cmd, data)
    -- ERROR_LOG("server_respond_11130",sprinttb(data));
    if data[2] == 0 then
        later_boss_rank = {};

        for k,v in pairs(data[3]) do
            uplaterRank(v);
        end
        -- ERROR_LOG(sprinttb(snCallBack));
        if snCallBack and snCallBack[data[1]] and snCallBack[data[1]].callback then
            snCallBack[data[1]].callback(later_boss_rank);    
            snCallBack[data[1]] = nil
        end
    else

        if snCallBack and snCallBack[data[1]] and snCallBack[data[1]].callback then
            snCallBack[data[1]].callback();   
            snCallBack[data[1]] = nil 
        end
    end
end)


utils.EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, pid)
    coroutine.resume(coroutine.create(function ( ... )
        local world_boss = QueryWorldInfo()
        ERROR_LOG("=============登录查询世界Boss",sprinttb(world_boss));

        if world_boss[7] == 0 then
            boss_end_attack = true;
        end
    end))
end);

local huntingStatus = nil

local huning_id = 0

local function worldBossHunting( status ,bossid)
    if status == huntingStatus then
        return;
    end
    huntingStatus = status;
    local pid = module.playerModule.GetSelfID();
    local mapPlayerStatus = module.TeamModule.GetmapPlayStatus(pid);
    if huntingStatus then
        if mapPlayerStatus and mapPlayerStatus[1] == 1 and mapPlayerStatus[3] ~= status then
            utils.SGKTools.SynchronousPlayStatus({5,{0,module.playerModule.GetSelfID(), mapPlayerStatus[3]}})
            utils.SGKTools.SynchronousPlayStatus({5,{1,module.playerModule.GetSelfID(), "hunting_world"}})
        else
            utils.SGKTools.SynchronousPlayStatus({5,{1,module.playerModule.GetSelfID(), "hunting_world"}})
        end
        if bossid then
            utils.SGKTools.Map_Interact(tonumber(bossid))
        end
        -- ERROR_LOG("============>>>","开启世界boss自动攻击功能");
    else
        if mapPlayerStatus and mapPlayerStatus[1] == 1 then
            utils.SGKTools.SynchronousPlayStatus({5,{0,module.playerModule.GetSelfID(), mapPlayerStatus[3]}})
        end
        KILLATK();
        -- ERROR_LOG("============>>>","关闭世界boss自动攻击功能");
    end
end

local function GetHunting(  )
    return huntingStatus;
end 

return {
    AttackWorldBoss      = AttackWorldBoss,
    AttackUnionBoss      = AttackUnionBoss,
    AttackBoss           = attackBoss,
    GetBossCfg           = GetBossCfg,
    QueryAll             = QueryAll,
    Type                 = Type,
    GetBossInfo          = GetBossInfo,
    GetReplayInfo        = GetReplayInfo,
    GetRankInfo          = GetRankInfo,
    GetBossRewardCfg     = GetBossRewardCfg,
    PlayeBossAttackAnim  = PlayeBossAttackAnim,
    GetAccumulativeRankings = GetAccumulativeRankings,

    QueryUnionInfo       = QueryUnionInfo,
    QueryUnionReplay     = QueryUnionReplay,
    QueryUnionRank       = QueryUnionRank,

    SendWatch            = sendWatch,

    GetBossConfig        = GetBossConfig,


    LaterRankInfo        = queryLaterRankInfo,

    queryRankInfo        = queryRankInfo,

    worldBossHunting     = worldBossHunting,

    GetHunting           = GetHunting,

    DOATKTween           = DOATKTween,
}
