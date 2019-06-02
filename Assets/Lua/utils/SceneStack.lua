local DialogStack = require "utils.DialogStack"
local UserDefault = require "utils.UserDefault"
local MapConfig = require "config.MapConfig"
local TipCfg = require "config.TipConfig"
local DialogConfig = require "config.DialogConfig"

local stack = {}
local top = nil;
local battleFlage = false

local homeMapId = {
    [1]   = true,
    [101] = true,
    [102] = true,
    [103] = true,
}
--[[
local function Reset(name, script, arg)
    if #stack > 1 and script == "view/map_scene.lua" then
        --print("SceneCount->"..#stack)
        for i = 1,#stack-1 do
            table.remove(stack,1)
        end
        --print("SceneCount->"..#stack)
    end
end
--]]

local function ClearBattleToggleScene()
    battleFlage = false
end

local function GetBattleStatus()
    local _status = battleFlage
    return _status
end

local function Push(name, script, arg)
    top = {
        name = name,
        script = script,
        arg = arg,
        savedValues = {},
        dialogStack = DialogStack.SetInstance(),
    }

    table.insert(stack, top)
    --Reset(name, script, arg)
    return top.savedValues;
end

local function Replace(name, script, arg)
    table.remove(stack)

    top = {
        name = name,
        script = script,
        arg = arg,
        savedValues = {},
        dialogStack = DialogStack.SetInstance(),
    }

    table.insert(stack, top)
    -- Reset(name, script, arg)
    return top.savedValues;
end

local function Pop()
    table.remove(stack)
    top = stack[#stack];
end

local noFadeScene = {
    HeroShowScene1 = true,
}

local SceneLoadingIndex = {
    battle = 0, 
    login_scene2 = 0,
    main_scene = 0,
}

local isLoading = false;
local nextLoadingInfo = nil;
local nextSceneInfo = {}

local function GetNextSceneInfo()
    return nextSceneInfo;
end

local function LoadSceneAndWait(name, fade, arg, callback,AccountLoginScene)
    ERROR_LOG("======>>>",debug.traceback( ));
    ClearTipsQueue()
    if name ~= "battle" and battleFlage then
        showDlgError(nil, "战斗内无法进行该操作")
        return
    end

    nextSceneInfo.scene_name = name;

    if name == "battle" then
        battleFlage = true
        utils.SGKTools.SynchronousPlayStatus({5,{1,module.playerModule.GetSelfID(),"combat"}})
    end

    if isLoading then
        nextLoadingInfo = {name, fade, arg, callback, AccountLoginScene};
        return
    end
    utils.EventManager.getInstance():dispatch("SCENE_BEFORE_LOAD");

    isLoading = true;

    local useAnimate = false -- (name == "battle");
    local useFade = not (noFadeScene[name] or (top and noFadeScene[top.name]))
    local loadingIndex = SceneLoadingIndex[name] or 1;
    
    local tips="";
    local tipCfgTab=TipCfg.GetTipsConfig();
    if next(tipCfgTab)~=nil then
        local tipsGid=math.random(1, #tipCfgTab)
        tips=TipCfg.GetTipsConfig(tipsGid)
    end
    if AccountLoginScene then
        DialogStack.PushPref("AccountLoginSceneFrame",{name = name,callback = function ()
            collectgarbage();
            -- SGK.ResourcesManager.UnloadUnusedAssets()
            callback();
            if not arg or not arg.guide then
                utils.EventManager.getInstance():dispatch("SCENE_LOADED", name);
            end
            isLoading = false;
            if nextLoadingInfo then LoadSceneAndWait(table.unpack(nextLoadingInfo)); nextLoadingInfo = nil; end
        end},UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject)
    else
        utils.SGKTools.LockMapClick(true)
        SceneService:UnloadOnNextScene();
        local cb = function()
            collectgarbage();
            -- SGK.ResourcesManager.UnloadUnusedAssets()
            if callback then
                callback();
            end
            if not arg or not arg.guide then
                utils.EventManager.getInstance():dispatch("SCENE_LOADED", name);
            end
            isLoading = false;
            utils.SGKTools.LockMapClick(false)

            if nextLoadingInfo then LoadSceneAndWait(table.unpack(nextLoadingInfo)); nextLoadingInfo = nil; end
        end
        if SceneService.SwitchScene2 then
            SceneService:SwitchScene2(name, loadingIndex, tips, cb);
        else
            SceneService:SwitchScene(name, useAnimate, useFade, tips, cb);
        end
    end
end

local scene_switch_with_fade = true;

local function PopScene(...)
    local _data = ...
    if top and top.controller and top.controller.deActive then
        if not top.controller.deActive() then
            return;
        end
    end

    if battleFlage then
        battleFlage = false
    end
    if #stack > 1 then
        local nextTop = stack[#stack - 1];
        if nextTop.arg then
            nextSceneInfo.map_id = nextTop.arg.mapid
            nextTop.arg.isPop = true
        else
            nextSceneInfo.map_id = nil;
        end
        LoadSceneAndWait(nextTop.name, scene_switch_with_fade, nextTop.arg, function()
            UserDefault.Save();
            if top then top.controller = nil end
            local _id = module.MapModule.GetiMapid()
            SGK.BackgroundMusicService.SetMapID(_id)
            SGK.BackgroundMusicService.SwitchMusic()
            --Pop();
            local controller = SGK.LuaLoader.Load(nextTop.script, nextTop.arg)
            if controller then controller.savedValues = nextTop.savedValues;  end
            nextTop.controller = controller;
            nextTop.dialogStack = DialogStack.SetInstance(nextTop.dialogStack);
            if _data and _data.func then
                _data.func()
            end
        end)
        Pop();
    else
        StartScene("main_scene");
    end
end

local MapInfo = {}
local function MapId(mapId, mapType, mapRoom)
    if type(mapId) == "number" then
        MapInfo.mapId = mapId;
        MapInfo.mapType = mapType;
        MapInfo.mapRoom = mapRoom;
    elseif type(mapId) == "string" then
        return MapInfo
    end
    return MapInfo.mapId
end

local function ControllerProfiler(controller, name)
    if UnityEngine.Application.isEditor and controller.Start then
        local Start = controller.Start;
        controller.Start = function(...)
            local profiler = require "perf.profiler"
            profiler.start();
            Start(...)
            print(name .. " Start cost " .. profiler.time() .. "ms\n" .. profiler.report('TOTAL'));
            profiler.stop();
        end
    end
    return controller
end
local function LoadSceneLua(name, arg,parObj)
    local savedValues = {}
    local luaBehaviour = parObj:AddComponent(typeof(SGK.LuaBehaviour));

    local scriptFileName = "view/" .. name .. ".lua";
    local controller = nil
    local func = loadfile(scriptFileName);
    if func then
        controller = ControllerProfiler(func(), scriptFileName);
    end
    if controller then
        luaBehaviour:LoadScript(scriptFileName, controller, arg);
    end
    return parObj
end

local function PushScene(name, script, arg)
    if not DialogConfig.CheckDialog(name) then
        return
    end
    assert(script ~= "view/map_scene.lua")
    nextSceneInfo.map_id = nil;
    LoadSceneAndWait(name, scene_switch_with_fade, arg, function()
        UserDefault.Save();
        if top then top.controller = nil end
        if name == "battle" and top and top.name == "battle" then
            Replace(name, script)
        else
            Push(name, script)
        end
        if script then
            local controller = SGK.LuaLoader.Load(script, arg);
            if controller then  controller.savedValues = top.savedValues;  end
            top.controller = controller;
        end
    end)
end

local function PushScene_coroutine(name, script, arg)
    local co = coroutine.running()
    nextSceneInfo.map_id = nil;
    LoadSceneAndWait(name, scene_switch_with_fade, arg, function()
        UserDefault.Save();
        if top then top.controller = nil end
        if name == "battle" and top.name == "battle" then
            Replace(name, script)
        else
            Push(name, script)
        end
        local controller = SGK.LuaLoader.Load(script, arg);
        if controller then controller.savedValues = top.savedValues;  end
        top.controller = controller;
        coroutine.resume(co)
    end)
    coroutine.yield()
end
local function ReplaceScene(name, script, arg)
    if not DialogConfig.CheckDialog(name) then
        return
    end
    assert(script ~= "view/map_scene.lua")
    nextSceneInfo.map_id = nil;
    LoadSceneAndWait(name, scene_switch_with_fade, arg, function()
        UserDefault.Save();
        if top then top.controller = nil end
        Replace(name, script, arg)
        local controller = SGK.LuaLoader.Load(script, arg);
        if controller then controller.savedValues = top.savedValues;  end
        top.controller = controller;
    end)
end

function StartScene (name, script, arg)
    stack = {}
    top = nil;
    PushScene(name, script, arg)
end

local savedValues = setmetatable({}, {__index=function(t, k)
    return top and top.savedValues[k]
end, __newindex = function(t,k,v)
    if top then
        top.savedValues[k] = v;
    end
end});

local params = setmetatable({}, {__index=function(t, k)
    return top and top.arg[k]
end});

local function Count()
    return #stack
end

local function GetTopStack()
    return stack[#stack]
end
local function GetStack()
    return stack
end

local function GetCurrentSceneName()
    if #stack > 0 then
        return stack[#stack].name;
    else
        return "nil"
    end
end

local function GetCurrentSceneID()
    return MapId()
end

local function checkHomeMap(id)
    if id ~= 1 then
        return id
    end
    return 103

    -- local _hour = tonumber(os.date("%H", module.Time.now()))
    -- if _hour >= 6 and _hour < 19 then
    --     return 1
    -- end
    -- local _rand = math.random(1, 100)
    -- if _rand >= 30 then
    --     return 101
    -- end
    -- return 102
end

local function CheckSelfEnterMap(mapid)
    if SceneStack.GetBattleStatus() then
        return true
    end
    local info = module.TeamModule.GetTeamInfo();
    --具有队伍
    local pid = module.playerModule.Get().id
    if info.id > 0 then
        --队长

        local map_info = MapConfig.GetMapConf(mapid);
        if info.leader.pid == pid then
            if map_info.map_type == 4 then
                -- ERROR_LOG("暂离=======>>>>",sprinttb(info.afk_list));
                local playerInfo = module.unionModule.queryPlayerUnioInfo(pid)
                local un_afk_member = module.TeamModule.GetTeamMembers(1);
                for k,v in pairs(info.afk_list) do
                    
                    if v.pid ~= pid then
                        local memberInfo =module.unionModule.queryPlayerUnioInfo(v.pid)
                        
                        if memberInfo.haveUnion == 0 or memberInfo.unionId ~= playerInfo.unionId then

                            -- ERROR_LOG("暂离玩家------------>>>>",k);
                            -- module.TeamModule.TEAM_AFK_REQUEST(nil,k);
                            module.playerModule.Get(v.pid,function ( _data )
                                showDlgError(nil,_data.name.."无法进地图======>>>>SceneStack");
                            end);
                            utils.NetworkService.SyncRequest(18292, {nil, v.pid});
                        end
                        -- ERROR_LOG("公会信息",sprinttb(memberInfo),sprinttb(playerInfo));
                    end
                end
            end

            return true;
        else
            if info.afk_list[math.floor(module.playerModule.Get().id)] == true then
                return true;
            end
        end
    else
        return true;        
    end

end

local function EnterMap(_id, args,AccountLoginScene)
    print("切换地图", _id, debug.traceback())

    if not GetBattleStatus() then
        local toMap =  _id and MapConfig.GetMapConf(tonumber(_id))
        if toMap then
            local level = module.playerModule.Get().level;
        
            if level < toMap.depend_level  then
                return showDlgError(nil,SGK.Localize:getInstance():getValue("tongyong_02",toMap.depend_level));
            end
        end
    end

    coroutine.resume( coroutine.create( function ( ... )
        local mapId = SceneStack.MapId();
        -- if not SceneStack.GetBattleStatus() then
        --     if mapId ~= 0 and not CheckSelfEnterMap(_id) then
        --         showDlgError(nil,"跟随中无法操作");
        --         return;
        --     end
        -- end
        module.HuntingModule.IsHunting(true);--如果在狩猎，取消狩猎

        local mapCfg, name;
        local id = tonumber(_id)
        id = checkHomeMap(id)
        if id == nil then
            name = _id;
            id = MapConfig.GetMapId(name)
            mapCfg = id and MapConfig.GetMapConf(id)
        else
            mapCfg = MapConfig.GetMapConf(id)
            if not mapCfg then
                ERROR_LOG('map with id', id, 'not eixst');
                return;
            end
            name = mapCfg.map_id;
        end
        if mapCfg and mapCfg.sceneback == 0 then
            stack = {}
            top = nil;
        end

        if name == nil then
            ERROR_LOG("map, no found", _id)
            return
        end
        DispatchEvent("LockMapClickCreate",true)
        -- TODO:
        args = args or {};
        args.mapid = args.mapid or id;
        args.mapType = mapCfg.map_type
        args.map_move_style = mapCfg.map_move_style

        MapInfo = {};
        MapInfo.mapId = args.mapid;
        MapInfo.mapType = args.mapType;
        MapInfo.mapRoom = args.room;
        local script = "";
        if homeMapId[id] then
            script = "view/home_scene.lua";
        else
            script = "view/map_scene.lua";
        end
        nextSceneInfo.map_id = args.mapid;
        LoadSceneAndWait(name, scene_switch_with_fade, args, function()
            UserDefault.Save();
            SGK.BackgroundMusicService.SetMapID(_id)
            SGK.BackgroundMusicService.SwitchMusic()
            Push(name, script)
            local controller = SGK.LuaLoader.Load(script, args)
            if controller then controller.savedValues = top.savedValues;  end
            if args and args.func then
                args.func()
                args.func = nil
            end
        end,AccountLoginScene)
    end ) )
    
end

local function TeamEnterMap(_id, args,AccountLoginScene)
    -- print("队伍切换地图", _id, debug.traceback())
    local mapId = SceneStack.MapId();
    if mapId ~= 0 and not module.TeamModule.CheckEnterMap(_id) then
        showDlgError(nil,"无法传送到队长身边");
        module.TeamModule.TEAM_AFK_REQUEST();
        return;
    end
    
    local mapCfg, name;
    local id = tonumber(_id)
    id = checkHomeMap(id)
    if id == nil then
        name = _id;
        id = MapConfig.GetMapId(name)
        mapCfg = id and MapConfig.GetMapConf(id)
    else
        mapCfg = MapConfig.GetMapConf(id)
        if not mapCfg then
            ERROR_LOG('map with id', id, 'not eixst');
            return;
        end
        name = mapCfg.map_id;
    end
    if mapCfg and mapCfg.sceneback == 0 then
        stack = {}
        top = nil;
    end

    if name == nil then
        ERROR_LOG("map, no found", _id)
        return
    end
    DispatchEvent("LockMapClickCreate",true)
    args = args or {};
    args.mapid = args.mapid or id;
    args.mapType = mapCfg.map_type
    args.map_move_style = mapCfg.map_move_style
    
    MapInfo = {};
    MapInfo.mapId = args.mapid;
    MapInfo.mapType = args.mapType;
    MapInfo.mapRoom = args.room;

    local script = "";
    if homeMapId[id] then
        script = "view/home_scene.lua";
    else
        script = "view/map_scene.lua";
    end
    nextSceneInfo.map_id = args.mapid;
    LoadSceneAndWait(name, scene_switch_with_fade, args, function()
        UserDefault.Save();
        SGK.BackgroundMusicService.SetMapID(_id)
        SGK.BackgroundMusicService.SwitchMusic()
        Push(name, script)
        local controller = SGK.LuaLoader.Load(script, args)
        if controller then controller.savedValues = top.savedValues;  end
        if args and args.func then
            args.func()
            args.func = nil
        end
    end,AccountLoginScene)
end


return {
    Push = PushScene,
    Replace = ReplaceScene,
    Pop = PopScene,
    Start  = StartScene,
    EnterMap = EnterMap,

    StartLoading = StartLoading,
    savedValues = savedValues,
    PushCoroutine = PushScene_coroutine,

    Count = Count,
    GetStack = GetStack,
    GetTopStack = GetTopStack,
    CurrentSceneName  = GetCurrentSceneName,
    CurrentSceneID  = GetCurrentSceneID,
    MapId = MapId,
    LoadSceneLua = LoadSceneLua,
    ClearBattleToggleScene = ClearBattleToggleScene,
    GetBattleStatus = GetBattleStatus,

    GetNextSceneInfo = GetNextSceneInfo,
    HomeMapId = homeMapId,
    TeamEnterMap = TeamEnterMap,
}
