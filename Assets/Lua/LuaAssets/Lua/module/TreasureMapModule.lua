local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local mazeConfig = require "config.mazeConfig"
local RoadConfig = nil;
local RoadPosConfig = nil

local function LoadRoadConfig( ... )
    RoadConfig = RoadConfig or {};
    RoadPosConfig = RoadPosConfig or {}
    DATABASE.ForEach("treasure_minigame", function(row)
        RoadPosConfig[row.gid] = row
        RoadConfig[row.type] = RoadConfig[row.type] or {}
        local road = {};
        local point = {};
        for i=7,1,-1 do
            for j=7,1 ,-1 do
                local status = row["row"..i] & (1<<(j-1)) ~= 0 and 0 or 1
                table.insert( road, status)
                if status == 0 then
                    table.insert( point, #road )
                end
            end
        end

        row.road = road;
        row.point = point
        table.insert( RoadConfig[row.type], row )
	end)
end

local function GetRandomRoad(type)
    if not RoadConfig then
        LoadRoadConfig();
    end
    
    if type and RoadConfig[type] then
       math.randomseed(module.Time.now())
        local rand = math.random( 1,#(RoadConfig[type]) )

        return RoadConfig[type][rand];
    else
        ERROR_LOG("TYPE %s IS NIL",type);
    end
end
local answerConfig = nil
local function LoadanswerConfig( ... )
    answerConfig = answerConfig or {};
    DATABASE.ForEach("treasure_24", function(row)

        
        table.insert( answerConfig, row )
	end)
end

local function GetRoadPos( gid )

    if not RoadPosConfig then
        LoadRoadConfig();
    end
    if gid then
        return RoadPosConfig[gid]
    end
end 


local function GetAnswerConfig(gid)

    if not answerConfig then
        LoadanswerConfig()
    end
    if gid then
        return answerConfig[gid]
    end
    return answerConfig
end

local currentTopic = nil

local function RandomCurrentTopic()
    math.randomseed(module.Time.now())
    local all_answer = GetAnswerConfig()
    local index = math.random(1,#all_answer)
    currentTopic = all_answer[index];
    print("获取的题目",sprinttb(currentTopic))
end

local function GetTopic( force )
    if not currentTopic or force then
        RandomCurrentTopic()
    end
    return currentTopic;
end
local NPCModule = nil
local function LoadNPC ( type,cfg,pos )
    NPCModule = NPCModule or {}
    NPCModule[cfg.id] = NPCModule[cfg.id] or {};
    

    local root ;
    if not NPCModule[cfg.id].obj then
        local prefab = SGK.ResourcesManager.Load("prefabs/treasure/treasureNpc2.prefab");
        root = UnityEngine.GameObject.Instantiate(prefab);
    else
        root = NPCModule[cfg.id].obj
    end

    local answer = nil
	local obj = SGK.UIReference.Setup(root);
    if tonumber(cfg.triggle) ~=0 then
        obj[CS.SGK.MapInteractableMenu].enabled = false
        obj.Trigger[CS.SGK.MapColliderMenu].LuaTextName = cfg.script;
        obj.Trigger.gameObject:SetActive(true);
        -- ERROR_LOG(tonumber(cfg.triggle))
        obj.Trigger[CS.SGK.MapColliderMenu].interDeltime = 0.001
        obj.Trigger[UnityEngine.BoxCollider].size = UnityEngine.Vector3(tonumber(cfg.triggle),0,tonumber(cfg.triggle));
    else
        obj[CS.SGK.MapInteractableMenu].enabled = true
        obj[UnityEngine.BoxCollider].size = UnityEngine.Vector3(1,1,1);
        obj[CS.SGK.MapInteractableMenu].LuaTextName = cfg.script;
        obj.Trigger.gameObject:SetActive(false);
    end
    if type == 1 then
    	obj.Trigger[CS.SGK.MapColliderMenu].interDeltime = 0.25	
        if tonumber(cfg.triggle) == 0 then
            obj[CS.SGK.MapInteractableMenu].values[1] = cfg.id;
            obj[CS.SGK.MapInteractableMenu].values[0] = 0;
        else
            obj.Trigger[CS.SGK.MapColliderMenu].values[1] = cfg.id;
            obj.Trigger[CS.SGK.MapColliderMenu].values[0] = 0;
        end
    elseif type ==2 then
        if tonumber(cfg.triggle) == 0 then
            obj[CS.SGK.MapInteractableMenu].values[1] = cfg.id;
            obj[CS.SGK.MapInteractableMenu].values[0] = cfg.type;
        else
            obj.Trigger[CS.SGK.MapColliderMenu].values[1] = cfg.id;
            obj.Trigger[CS.SGK.MapColliderMenu].values[0] = cfg.type;
        end

        -- obj.Trigger[CS.SGK.MapColliderMenu].values[1] = cfg.id;
        -- obj.Trigger[CS.SGK.MapColliderMenu].values[0] = cfg.type;
    elseif type == 4 then
        local topic = GetTopic()
        -- local topic = GetAnswerConfig(index)
        local target = "num"..(tonumber(cfg.type)-20)
        local ret = topic[target]
        if tonumber(cfg.triggle) == 0 then
            obj[CS.SGK.MapInteractableMenu].values[1] = ret;
            obj[CS.SGK.MapInteractableMenu].values[0] = tonumber(cfg.type)-20;
            obj[CS.SGK.MapInteractableMenu].values[2] = cfg.id;
        else
            obj.Trigger[CS.SGK.MapColliderMenu].values[1] = ret
            obj.Trigger[CS.SGK.MapColliderMenu].values[0] = tonumber(cfg.type)-20;
            obj.Trigger[CS.SGK.MapColliderMenu].values[2] = cfg.id;
            obj.Trigger.transform.localRotation = Quaternion.Euler(UnityEngine.Vector3(0,60,0));
        end

        answer = ret
    end
	obj.Root.Canvas.name[UI.Text].text = cfg.name
	-- print("born_script",cfg.id);
    if (cfg.born_script ~= "0") then
        if not NPCModule[cfg.id].born then
            local born = module.mazeModule.LoadEffect(cfg.born_script);

            if born then
                born.transform.parent = obj.gameObject.transform;
                born.transform.localPosition = UnityEngine.Vector3(0,0,0)
                born.transform.localScale = UnityEngine.Vector3.one
                born.transform.localRotation = Quaternion.Euler(UnityEngine.Vector3(45,0,0));
                NPCModule[cfg.id].born = born
            end
        end
        if answer then
            local view = CS.SGK.UIReference.Setup(NPCModule[cfg.id].born.gameObject)
            view.num[UnityEngine.SpriteRenderer].sprite = view.num[CS.UGUISpriteSelector].sprites[tonumber(answer)-1]
        end
	end
    obj.transform.position = UnityEngine.Vector3(pos[1],pos[2],pos[3])
    obj.name = "NPC_"..cfg.id
    obj.gameObject.transform.localScale = UnityEngine.Vector3.one * cfg.scale_rate
    NPCModule[cfg.id].obj = obj
    NPCModule[cfg.id].born_point = obj.born
    obj:SetActive(true);
    return obj
end



local function Load( type,cfg,pos )

    NPCModule = NPCModule or {}

    local obj = LoadNPC(type,cfg,pos);

    return NPCModule[cfg.id];
end

local function GetNPCOBJ( id )
    NPCModule = NPCModule or {}
    if id then
        return NPCModule[id]
    end
end

local function SetNPCStatus( id,status )
    NPCModule = NPCModule or {}

    if id and NPCModule[id] then
        -- print("==============>>>",id)
        NPCModule[id].obj:SetActive(status)
    end
end


local coroutine_func = nil

local function StartCorotinue( id,time,func )

    coroutine_func = coroutine_func or {};
    if coroutine_func[id] then
        coroutine_func[id]:Kill();
    end
    coroutine_func[id] = SGK.Action.DelayTime.Create(time):OnComplete(function()
        if func then
            func();
        end
    end)
end




local function KillCorotinue( id )
    coroutine_func = coroutine_func or {};
    if coroutine_func[id] then
        coroutine_func[id]:Kill();
    end
end


local smallGame1 = nil


local function GetGame1ObsStatus( id )
    smallGame1 = smallGame1 or {}

    return smallGame1[id]
end

local function SetGame1ObsStatus( id,time,obj,status ,effect)
    smallGame1 = smallGame1 or {}

    smallGame1[id] = smallGame1[id] or {}

    smallGame1[id].obj = obj
    StartCorotinue(id,time,function ( ... )
        smallGame1[id].status = status

        if effect then

            -- ERROR_LOG("TYPE 12 ===============>>>",status,effect)

            -- NPCModule[cfg.id]
            smallGame1[id].obj.Trigger.gameObject:SetActive(status == 2);
            GetNPCOBJ(id).born.gameObject:SetActive(status ~= 2);
            effect:SetActive(true);
            effect.gameObject.transform.parent.gameObject:SetActive(status == 2);
        else
            if smallGame1[id].obj then
                smallGame1[id].obj.gameObject:SetActive(status == 2)
            end

        end
        
        SetGame1ObsStatus(id,time,obj,status == 1 and 2 or 1,effect)
    end)

    
end


local function KillGame1ObsStatus( id )
    smallGame1 = smallGame1 or {}
    if smallGame1[id] and smallGame1[id].status~=3 then
        if smallGame1[id].obj then
            smallGame1[id].obj:SetActive(false);
        end
        smallGame1[id].status = 3
        KillCorotinue(id);
        KillCorotinue(id*100);
    end
end


local function ClearGame1ObsStatus(  )
    if smallGame1 then
        for k,v in pairs(smallGame1) do
            if v.status ~=3 then
                KillGame1ObsStatus(k);
            end
        end
    end
    smallGame1 = {}
end


local game2Status = 0
--游戏2状态 0未开始 1已开始 2结束
local function StartGame2()
    if game2Status == 0 then
        game2Status = 1
    end
end

local smallGame2 = nil

local function StartGame2Status( id ,time,func )
    smallGame2 = smallGame2 or {}
    table.insert( smallGame2, id ) 
    StartCorotinue(id,time,func);
end


local function KillGame2Status( id )
    if id then
        KillCorotinue(id);
    else
        if not smallGame2 or #smallGame2 == 0 then
            return
        end
        for k,v in pairs(smallGame2) do
            KillCorotinue(v);
        end
    end
end


local player_current_pos = nil
--对应格子掉落
local function DonePosObject( pos,obj )
    if player_current_pos and pos == player_current_pos then
        KillGame2Status();
        DispatchEvent("PLAYER_DEAD_EFFECT",{pid = module.playerModule.Get().id,time = 4})
        DispatchEvent("PLAYSCREENEFFECT",{2,SGK.Localize:getInstance():getValue("migong_shibai")})
        utils.SGKTools.LockMapClick(true,2)
        StartCorotinue(999,2,function ( ... )
            module.TreasureMapModule.ExitSmallGame();
        end)
    end
    -- print("=====>>>",pos,obj)
    
    -- local effect = UnityEngine.GameObject.Instantiate(effect_cube,obj.gameObject.transform);

    -- effect.transform.localPosition = Vector3.zero
    -- effect.transform.localRotation = Quaternion.Euler(UnityEngine.Vector3(0,60,0));
    -- UnityEngine.GameObject.Destroy(effect,2)
    obj[UnityEngine.AI.NavMeshObstacle].enabled =true
    obj.triggle.gameObject:SetActive(false);
    -- obj.mig_box:SetActive(false);
end


local small_Game2_Roads = nil
local function SavePosRoad( pos,road )
    small_Game2_Roads = small_Game2_Roads or {}

    small_Game2_Roads[pos] = road
end

local function GetPosRoad( pos )
    small_Game2_Roads = small_Game2_Roads or {}
    return small_Game2_Roads[pos]
end

local small_Game_Corotinue = nil

local time = 2
local effect_cube = SGK.ResourcesManager.Load("prefabs/effect/tanta_collaps.prefab");

local function EnterCube(id)
    player_current_pos = id;

    small_Game_Corotinue = small_Game_Corotinue or {}

    if small_Game_Corotinue[id] then
        print(id,"this is exits")
    else
        if id ~= 0 then
            local obj = GetPosRoad(id)
            obj.mig_box:SetActive(false);
            local effect = UnityEngine.GameObject.Instantiate(effect_cube,obj.gameObject.transform);
            effect.transform.localPosition = Vector3.zero
            effect.transform.localRotation = Quaternion.Euler(UnityEngine.Vector3(0,60,0));
            UnityEngine.GameObject.Destroy(effect,2)
            StartCorotinue(id,time,function ( ... )
                DonePosObject(id,obj)
            end);
        end
        
        small_Game_Corotinue[id] = 1
    end
end

local function ExitCube( id )
    player_current_pos = nil
end

local function GetCurrentPos( ... )
    return player_current_pos
end

local npc_effect = nil

utils.EventManager.getInstance():addListener("MAP_SCENE_READY", function(event, data)
    player_current_pos = 0

    NPCModule = nil
    small_Game_Corotinue = nil
    small_Game2_Roads = nil
    npc_effect = nil
end)



local function LoadNpcEffect(id,name,isEffect)

    npc_effect = npc_effect or {}
	if id and name then
        if not npc_effect[id] then
            npc_effect[id] = {}
        end
        if not npc_effect[id].effect_list then
			npc_effect[id].effect_list = {}
        end
        print("特效",npc_effect[id].effect_list[name])
        if npc_effect[id].effect_list[name] then
            npc_effect[id].effect_list[name].gameObject:SetActive(true);
            
            print("加载一个特效",npc_effect[id].effect_list[name].activeInHierarchy)
            return npc_effect[id].effect_list[name]
        end
        
        if name then

            -- ERROR_LOG(sprinttb(GetNPCOBJ(id)),"=================>>>>>");
			local eff = SGK.ResourcesManager.Load("prefabs/effect/"..name..".prefab");
            if eff then

                local effect = UnityEngine.GameObject.Instantiate(eff,GetNPCOBJ(id).born_point.gameObject.transform);

                effect.transform.localPosition = Vector3.zero
                npc_effect[id].effect_list[name] = effect
                print("加载一个特效--->>>>",npc_effect[id].effect_list[name].activeInHierarchy)
                return npc_effect[id].effect_list[name]
            else
                -- ERROR_LOG(effectname.." is not find");
                return
            end
	        
		end
	end
end


local function DestroyNpcEffect( id,name )
    if id and name and npc_effect and npc_effect[id] then
		if not npc_effect[id].effect_list then
            npc_effect[id].effect_list = {}
        end

        if npc_effect[id].effect_list[name] then

            npc_effect[id].effect_list[name]:SetActive(false);
            -- print("销毁一个特效",npc_effect[id].effect_list[name].activeInHierarchy)
        end
    end
end


local smallGame4 = nil


local function GetAnswer(index)
    smallGame4 = smallGame4 or {}
    smallGame4.answer = smallGame4.answer or {}

    if index then
        return smallGame4.answer[index]
    else
        return smallGame4.answer
    end
end

local function GetAnswerByID( id )
    smallGame4 = smallGame4 or {}
    smallGame4.answer = smallGame4.answer or {}

    if id then
        for i=1,4 do
            if smallGame4.answer[i] and smallGame4.answer[i].id == id then
                return smallGame4.answer[i]
            end
        end
    else
        return smallGame4.answer
    end
end

local function SetAnswer( id ,value)
    smallGame4 = smallGame4 or {}
    smallGame4.answer = smallGame4.answer or {}

    -- ERROR_LOG("设置答案",id,value);
    local TYPE = true
    for i=1,4 do
        if smallGame4.answer[i] and smallGame4.answer[i].id == id then
            TYPE = false;
            break;
        end
    end
    -- ERROR_LOG("=====",TYPE);
    
    local function Insert(id,value)
        for i=1,4 do
            if not smallGame4.answer[i] then
                smallGame4.answer[i] = {id = id,value = value}
                DispatchEvent("LOCAL_TREASURE_ANSWER",{index = i,value = value});
                break
            end
        end
    end


    local function RemoveAnswer( id )
        for i=1,4 do
            if smallGame4.answer[i] and smallGame4.answer[i].id == id then
                smallGame4.answer[i] = nil
                DispatchEvent("LOCAL_TREASURE_ANSWER",{index = i});
                break;
            end
        end
    end

    if TYPE then
        Insert(id,value)
    else
        RemoveAnswer(id)
    end


    -- ERROR_LOG("修改过后的答题",sprinttb(smallGame4));
end

local function ClearAnswer( )
    smallGame4 = nil
end


local function ResetSmallGame( ... )
    for k,v in pairs(NPCModule) do
        local info = mazeConfig.GetInfo(k);

        if info.type >10 and v  and info.type ~= 31 and v.obj then
            KillCorotinue(k);
            v.obj:SetActive(false);
        end
    end
end



local function GetPlayerPos( ... )
    local MapSceneController = UnityEngine.GameObject.FindObjectOfType(typeof(SGK.MapSceneController));
    local id = module.playerModule.Get().id;
    local character = MapSceneController:Get(id)

    return {character.transform.position.x,character.transform.position.y,character.transform.position.z}
end
local playerEnterSmallGame_Pos = nil

local SmallGameStatus = nil

local function SaveGamePlayerPos(  )
    playerEnterSmallGame_Pos = GetPlayerPos()
end 

local function EnterSmallGame()
    utils.SGKTools.StopPlayerMove()
    SaveGamePlayerPos();
    -- ERROR_LOG("存储玩家位置",sprinttb(playerEnterSmallGame_Pos));
    math.randomseed(module.Time.now())
    local random = math.random( 1,4 )
    -- print("进入房间",random)
    SmallGameStatus = random;
    DispatchEvent("MOVE_TO_SMALL_GAME",random);
end

local function GetGameStatus( ... )
    return SmallGameStatus;
end


local function FlySmallGame( gid )
    local pos_conf = GetRoadPos(gid)
    if pos_conf then
        -- ERROR_LOG(pos_conf.x,pos_conf.y,pos_conf.z,sprinttb(pos_conf));
        utils.SGKTools.PlayerTransfer(pos_conf.x,pos_conf.y,pos_conf.z)
    end
    -- utils.SGKTools.PlayerTransfer(73.671,0,20.489)
end

local function ExitSmallGame( ... )
    if not playerEnterSmallGame_Pos then
        return
    end
    -- ERROR_LOG("重置小游戏数据");
    game2Status = 0
    
    if small_Game_Corotinue then
        for k,v in pairs(small_Game_Corotinue) do
            KillCorotinue(k);
        end
    end
    small_Game_Corotinue = nil
    small_Game2_Roads = nil

    smallGame4 = nil
    -- ERROR_LOG("解包",sprinttb(playerEnterSmallGame_Pos or {}));
    utils.SGKTools.PlayerTransfer(playerEnterSmallGame_Pos[1],playerEnterSmallGame_Pos[2],playerEnterSmallGame_Pos[3])
    playerEnterSmallGame_Pos = nil
    DispatchEvent("MOVE_TO_SMALL_GAME");
    DispatchEvent("PLAYER_SPEED_OFFEST",0)
    -- DispatchEvent("PLAYER_FILED_CUT",true)
    SmallGameStatus = nil
end



return {
    Kill = KillCorotinue,
    Start = StartCorotinue,
    GetRandomRoad = GetRandomRoad,
    Load = Load,

    --小游戏1

    SetGame1ObsStatus = SetGame1ObsStatus,

    GetGame1ObsStatus = GetGame1ObsStatus,
    --强制停止某个障碍物状态
    KillGame1ObsStatus = KillGame1ObsStatus,

    ClearGame1ObsStatus = ClearGame1ObsStatus,

    GetNPCOBJ = GetNPCOBJ,
    --小游戏2
    StartGame2 = StartGame2,
    StartGame2Status = StartGame2Status,
    EnterCube = EnterCube,

    ExitCube = ExitCube,

    GetCurrentPos = GetCurrentPos,

    DonePosObject = DonePosObject,
    KillGame2Status = KillGame2Status,

    SavePosRoad = SavePosRoad,
    --小游戏4
    LoadNpcEffect = LoadNpcEffect,
    DestroyNpcEffect = DestroyNpcEffect,
    GetAnswer = GetAnswer,
    SetAnswer = SetAnswer,
    ClearAnswer = ClearAnswer,
    ResetSmallGame = ResetSmallGame,
    GetTopic = GetTopic,
    EnterSmallGame = EnterSmallGame,
    ExitSmallGame = ExitSmallGame,
    SetNPCStatus = SetNPCStatus,
    FlySmallGame = FlySmallGame,
    GetAnswerByID = GetAnswerByID,


    GetGameStatus = GetGameStatus,
    SaveGamePlayerPos = SaveGamePlayerPos,
}