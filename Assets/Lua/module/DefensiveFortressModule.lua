local NetworkService = require "utils.NetworkService"
local EventManager = require 'utils.EventManager'
local socket = require "socket";

---[[--mapInfo
local status=false
local randIdxTab = {}
local function GetActivityStatus()
    return status
end

local function EnterActivity()
    SceneStack.EnterMap(551)
end

-- --队长 请求开始元素暴走活动返回
-- EventManager.getInstance():addListener("server_respond_16128", function(event, cmd, data)
--     local sn = data[1];
--     local err = data[2];
--     if err == 0 then
--         DialogStack.Pop()
--     else
--         ERROR_LOG("_16128_err",err)
--     end
-- end)

--通知进入队伍成员进入元素暴走
-- EventManager.getInstance():addListener("server_notify_16120", function(event, cmd, data)
--     print("通知队员进入")
--     status=true
--     --queryMapInfo()
--     CheckEnterMap()
-- end)
local function BackToEntranceNpc()
    SceneStack.EnterMap(13,{pos = {-7.22,-0.02,1.98}})
    -- local npc_id  = 2037000
    -- local npc_confs = utils.MapHelper.GetConfigTable("all_npc","gid")
    -- if npc_confs[npc_id] then
    --     local map_id = npc_confs[npc_id][1].mapid
    --     local x,y,z = npc_confs[npc_id][1].Position_x,npc_confs[npc_id][1].Position_y,npc_confs[npc_id][1].Position_z
    --     SceneStack.EnterMap(map_id,{pos ={x+0.65,y,z-0.5}})
    -- else
    --     ERROR_LOG("npc_confs is nil,npc_id",npc_id)
    -- end
end

local firstInfo=nil 
local function QueryDefensiveFortressStatus()
    if not firstInfo then
        firstInfo=true
        local sn=NetworkService.Send(16129)--查询元素暴走状态-- 16129 16130 // 登录查询
    end 
end

EventManager.getInstance():addListener("server_respond_16130", function(event, cmd, data)
    --ERROR_LOG("server_respond_16130",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        status=true
        EnterActivity()
    elseif err == 3 then
        status=false
        ERROR_LOG("游戏已结束")
        --SceneStack.EnterMap(13)
        BackToEntranceNpc()
    else
        ERROR_LOG("_16130_err",err)
        --SceneStack.EnterMap(13)
        BackToEntranceNpc()
    end
end)

local fortressMapCfg = nil
local function getMapCfg(Site_id)
    if not fortressMapCfg then
        fortressMapCfg = {}
        DATABASE.ForEach("hessboard", function(data)
            local _site_relevance = {}
            local _Monster_site = {}
            local _ObstructPos = {}
            local _ObstructRoa = {}
            local _ObstructScaX = {}
            for i=1,4 do
                if data["Site_relevance"..i] and data["Site_relevance"..i]~=0 then
                    table.insert(_site_relevance,data["Site_relevance"..i])
                end
                if data["Monster_site"..i] and data["Monster_site"..i]~=0 then
                    table.insert(_Monster_site,data["Monster_site"..i])

                    _ObstructPos[data["Monster_site"..i]] = {x = data["obstacle_pos_x"..i] ,y = data["obstacle_pos_y"..i],z = data["obstacle_pos_z"..i]}
                    _ObstructRoa[data["Monster_site"..i]] = {x = data["rotation_x"..i],y = data["rotation_y"..i],z=data["rotation_z"..i]}
                    _ObstructScaX[data["Monster_site"..i]] = data["scale_x"..i]
                end
            end

            fortressMapCfg[data.Site_id]=setmetatable(
                {   
                    pos = {x = data.pos_x, y = data.pos_y,z = data.pos_z},
                    adj = _site_relevance,
                    Monster_site = _Monster_site,
                    ObstructPos = _ObstructPos,
                    ObstructRoa=_ObstructRoa,
                    ObstructScaX=_ObstructScaX,
                },
                {__index = data})
        end)
    end
    if Site_id then
        return fortressMapCfg[Site_id]
    else
        return fortressMapCfg
    end
end
--]]

local collectionPointCfg=nil
local function GetResourceAndBoxPointCfg(type,Site_id)
    if not collectionPointCfg then
        collectionPointCfg={}
        DATABASE.ForEach("collection", function(data)
            collectionPointCfg[data.type]=collectionPointCfg[data.type] or {}
            collectionPointCfg[data.type][data.Site_id]=collectionPointCfg[data.type][data.Site_id] or {}
            collectionPointCfg[data.type][data.Site_id][#collectionPointCfg[data.type][data.Site_id]+1]=setmetatable({pos={x=data.pos_x,y=data.pos_y,z=data.pos_z}},{__index=data})
        end)
    end

    if type and Site_id then
        return collectionPointCfg[type][Site_id]
    elseif type and not Site_id then
        return collectionPointCfg[type]
    else
        return collectionPointCfg
    end
end
---[[--资源
local resourcesCfg = nil;
local function GetResourcesCfg(Resource_id)
    if not resourcesCfg then
        resourcesCfg=LoadDatabaseWithKey("hessboard_resoure","Resource_id")
    end
    if Resource_id then
        return resourcesCfg[Resource_id]
    else
        return resourcesCfg;
    end  
end
--]]

---[[--兑换资源
local exchangeCfg = nil;
local function GetExchangeCfg(Resource_id)
    if not exchangeCfg then
        exchangeCfg=LoadDatabaseWithKey("hessboard_exchange","Resource_id")
    end
    if Resource_id then
        return exchangeCfg[Resource_id]
    else
        return exchangeCfg
    end
end
--]]

---[[--陷阱配置

local pitFallCfgByLevel={}
local pitFallCfgbyId={}
local function loadPitFallCfg()
    local data_list = {};
    DATABASE.ForEach("hessboard_pitfall", function(data)
        table.insert(data_list, data);
        pitFallCfgByLevel[data.Pitfall_type]=pitFallCfgByLevel[data.Pitfall_type] or {}
        pitFallCfgByLevel[data.Pitfall_type][data.Pitfall_level]=data
        pitFallCfgbyId[data.Pitfall_id]=data
    end)
    return data_list;
end

local pitFallCfg = nil;
local function GetPitFallCfgByLevel(type,level)
    if not pitFallCfg then
        pitFallCfg=loadPitFallCfg()
    end
    if type and level then
        return pitFallCfgByLevel[type][level];       
    else
        return pitFallCfgByLevel
    end
end

local function GetPitFallIdCfg(Resource_id)
    if not pitFallCfg then
        pitFallCfg=loadPitFallCfg()
    end
    if Resource_id then
        return pitFallCfgbyId[Resource_id] or {}
    else
        return pitFallCfgbyId
    end 
end
--]]

--诱敌配置
local diversionCfg=nil
local function loadFortressDiversionCfg(id)
    if not diversionCfg then
        diversionCfg=LoadDatabaseWithKey("diversion", "Id")
    end
    if id then
        return diversionCfg[id] or {}
    else
        return diversionCfg
    end 
end

--boss配置
local bossCfg=nil
local function GetBossCfg(id)
    if not bossCfg then
        bossCfg=LoadDatabaseWithKey("hessboard_monster", "Id");
    end
    if id then
        return bossCfg[id] or {}
    else
        return bossCfg
    end 
end
--buff配置
local buffCfg=nil
local function GetBuffCfg(id)
    if not buffCfg then
        buffCfg=LoadDatabaseWithKey("hessboard_buff", "Id");
    end
    if id then
        return buffCfg[id] or {}
    else
        return buffCfg[id]
    end
end

--time配置
local roleTimeCfg=nil
local function GetRoleTimeCfg(id)
    if not roleTimeCfg then
        roleTimeCfg=LoadDatabaseWithKey("hessboard_time", "Monster_id");
    end
    if id then
        return roleTimeCfg[id] or {}
    else
        return roleTimeCfg
    end
end

local boxCfg=nil
local function GetBoxCfg(id)
    if not boxCfg then
        boxCfg=LoadDatabaseWithKey("hessboard_package", "Id");
    end
    if id then
        return boxCfg[id] or {}
    else
        return boxCfg
    end
end

local function GetRandomValue(tab,seed,type) 
    if seed then
        math.randomseed(seed)
    else
        math.randomseed(tostring(socket.gettime()):reverse():sub(1, 6)) 
    end

    randIdxTab[type] = randIdxTab[type] or {}
    randIdxTab[type][seed] = randIdxTab[type][seed] or {}

    local usedTab = {}
    for i=1,#tab do
        usedTab[i] = tab[i]
    end

    if next(randIdxTab[type][seed]) then
        for i=#randIdxTab[type][seed],1,-1 do
            if usedTab[randIdxTab[type][seed][i]] then
                table.remove(usedTab,randIdxTab[type][seed][i])
            end
        end
    end
    usedTab = #usedTab ~= 0 and usedTab or tab
    local index = math.random(1,#usedTab);
    table.insert(randIdxTab[type][seed],index)
    --ERROR_LOG("useTab",sprinttb(usedTab),"random index"..index,"value",usedTab[index])
    return usedTab[index];
end

local function queryMapInfo()
    NetworkService.Send(16101) 
end

local function QueryCollection(siteId)
    NetworkService.Send(16103,{nil,siteId})
end

local function QueryAddPitfall(siteId)
    NetworkService.Send(16105,{nil,siteId})
end

local function QueryExchange(resourceS,resource2)
    NetworkService.Send(16107, {nil,resourceS,resource2})
end

local function QueryDiversion(siteId)
    NetworkService.Send(16109,{nil,siteId})
end

local function QueryMove(PosId)
    NetworkService.Send(16111, {nil,PosId})
end

local function QueryGetRewards()
    NetworkService.Send(16113)
end
local PlayerOpenBoxSn={}
local function QueryOpenBox(pid,siteId)
    local sn=NetworkService.Send(16121,{nil,siteId})
    PlayerOpenBoxSn[sn]=pid
end
local function QueryRepairPoint()
    NetworkService.Send(16123)
end
local function QueryAfterFight()
    NetworkService.Send(16125)
end

local mapInfo={}
local function UpdateMapInfo(data)
    mapInfo.BossData = mapInfo.BossData or {}
    
    mapInfo.BossData.Id = data[3][1]
    mapInfo.BossData.PosId = data[3][2]
    mapInfo.BossData.GameStartTime = data[3][3]
    mapInfo.BossData.Status = data[3][4]
    mapInfo.BossData.ChangeStatusTime = data[3][5]
    mapInfo.BossData.BossHp = data[3][6]
    mapInfo.BossData.LastPosId = data[3][7]
    mapInfo.BossData.HP = 0

    mapInfo.BossData.movedPath = {}
    if mapInfo.BossData.PosId~=0 then
        mapInfo.BossData.movedPath[mapInfo.BossData.PosId] = true
    end
    if mapInfo.BossData.LastPosId~=0 and not mapInfo.BossData.movedPath[mapInfo.BossData.LastPosId] then
    	mapInfo.BossData.movedPath[mapInfo.BossData.LastPosId] = true
    end
    
    mapInfo.PlayerData=mapInfo.PlayerData or {}
    for i,v in ipairs(data[4]) do
        mapInfo.PlayerData[v[1]]=mapInfo.PlayerData[v[1]] or {}
        
        mapInfo.PlayerData[v[1]].Pid=v[1]
        mapInfo.PlayerData[v[1]].PosId=v[2]
        mapInfo.PlayerData[v[1]].LastMoveTime=v[3]
        mapInfo.PlayerData[v[1]].ColNum=v[4]
        mapInfo.PlayerData[v[1]].Status=v[5]
        mapInfo.PlayerData[v[1]].ChangeStatusTime=v[6]
        mapInfo.PlayerData[v[1]].LastPosId=v[7]

        mapInfo.PlayerData[v[1]].OpenTimes=v[8]

        mapInfo.PlayerData[v[1]].LastExchangeTime=0
        mapInfo.PlayerData[v[1]].LastAddTime=0
        mapInfo.PlayerData[v[1]].LastDiversionTime=0
        mapInfo.PlayerData[v[1]].StartActionTime=0
        mapInfo.PlayerData[v[1]].Action=0
        mapInfo.PlayerData[v[1]].Path={}
    end

    mapInfo.TeamResourceData=mapInfo.TeamResourceData or {}
    for i,v in ipairs(data[5]) do
        mapInfo.TeamResourceData[v[1]]=v[2]
    end
    mapInfo.oldResourceNum={}

    mapInfo.MapPointData=mapInfo.MapPointData or {}   
    for i,v in ipairs(data[6]) do
        mapInfo.MapPointData[v[1]]=mapInfo.MapPointData[v[1]] or {}

        mapInfo.MapPointData[v[1]].Pitfall_type=v[2]
        mapInfo.MapPointData[v[1]].Pitfall_level=v[3]
        mapInfo.MapPointData[v[1]].Diversion_value=v[4]
        mapInfo.MapPointData[v[1]].Box_Id=v[5]
        mapInfo.MapPointData[v[1]].Resource_Id=v[6]
        mapInfo.MapPointData[v[1]].Status=v[7]
        mapInfo.MapPointData[v[1]].BuffId=v[8]
        mapInfo.MapPointData[v[1]].LastCollectTime=0
        mapInfo.MapPointData[v[1]].NextResourceId=v[6]
    end
end

EventManager.getInstance():addListener("server_respond_16102", function(event, cmd, data)
    ERROR_LOG("16102@@mapInfo",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        status=true
        UpdateMapInfo(data)
        DispatchEvent("MAP_INFO_CHANGE",mapInfo);   
    else
        ERROR_LOG("16102err",err);
    end
end)

local function GetMapInfo()
    return mapInfo
end

EventManager.getInstance():addListener("server_respond_16104", function(event, cmd, data)
    --print("16104@@收集资源",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        DispatchEvent("START_COLLECT_RESOURCES",data);  
    else
        ERROR_LOG("16104err",err);
    end
end)

-- EventManager.getInstance():addListener("server_respond_16106", function(event, cmd, data)
--     print("16106@@addPitfall",sprinttb(data))
--     local sn = data[1];
--     local err = data[2];
--     if err == 0 then
--         DispatchEvent("ADDPITFALL_SUCCEED",{data[4],data[5]});
--     else
--         print("err",err);
--     end
-- end)

EventManager.getInstance():addListener("server_respond_16108", function(event, cmd, data)
    --print("16108@@exchange",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        DispatchEvent("EXCHANGE_SUCCEED",data);
    else
        print("err",err);
    end
end)

EventManager.getInstance():addListener("server_respond_16110", function(event, cmd, data)
    --print("16110@@diversion",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        DispatchEvent("DIVERSION_SUCCEED",data);
    else
        print("err",err);
    end
end)

-- EventManager.getInstance():addListener("server_respond_16112", function(event, cmd, data)
--     --print("16112@@move",sprinttb(data))
--     local sn = data[1];
--     local err = data[2];
--     if err == 0 then
--         DispatchEvent("PLAYER_MOVE_OVER");
--     else
--         print("err",err);
--     end
-- end)

EventManager.getInstance():addListener("server_respond_16114", function(event, cmd, data)
    -- print("16114@@GetRewards",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        -- DispatchEvent("GET_ACTIVITY_REWARD");
    else
        print("err",err);
    end
end)

EventManager.getInstance():addListener("server_respond_16115", function(event, cmd, data)
    --print("16115@@资源变化",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        if mapInfo.TeamResourceData then
            for k,v in pairs(mapInfo.TeamResourceData) do
                mapInfo.oldResourceNum[k]=v
            end
            for i,v in ipairs(data[3]) do
                mapInfo.TeamResourceData[v[1]]=v[2]
            end
            for i,v in ipairs(data[4]) do
                mapInfo.PlayerData[v[1]].ColNum=v[4]
            end
            --data[5]   1:收集资源2:加强陷阱3:兑换资源4:诱敌消耗资源5:与boss相遇掉资源6:战斗结束之后获得资源
            DispatchEvent("RESOURCES_NUM_CHANGE",{mapInfo.TeamResourceData,mapInfo.oldResourceNum,data[5]});
        end
    else
        print("err",err);
    end
end)

EventManager.getInstance():addListener("server_respond_16116", function(event, cmd, data)
    --print("16116@@Boss状态改变",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
       if mapInfo.MapPointData then
            for i,v in ipairs(data[7]) do
                mapInfo.MapPointData[v[1]].Box_Id=v[2]
            end
        end
        if mapInfo.BossData then
            mapInfo.BossData.movedPath[data[8]] = true   
        end
        DispatchEvent("BOSS_DATA_CHANGE",{0,data[3],data[4],data[5],data[6],data[8],mapInfo.MapPointData,mapInfo.BossData and mapInfo.BossData.movedPath});--boSS移动
    else
        print("err",err);
    end
end)

EventManager.getInstance():addListener("server_respond_16118", function(event, cmd, data)
    -- print("16118@@玩家状态改变",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then 
        DispatchEvent("ROlE_DATA_CHANGE",{data[3],data[4],data[5],data[6],data[7]});--玩家移动
        if mapInfo.PlayerData and mapInfo.PlayerData[data[3]] then
            mapInfo.PlayerData[data[3]].OpenTimes=data[8]
        end
    else
        print("err",err);
    end
end)

EventManager.getInstance():addListener("server_respond_16117", function(event, cmd, data)
    print("16117@@GAMEOVER",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        DispatchEvent("FORTRESS_GAME_OVER",{data[3],data[4]});
        status=false
    else
        print("err",err);
    end
end)

EventManager.getInstance():addListener("server_respond_16119", function(event, cmd, data)
    print("16119@@mapPointInfoChange",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        local _tab={}
        _tab.PosId=data[3]
        _tab.Pid=data[4]
        _tab.LastActionTime=data[5]
        _tab.NextResourceId=data[6]
        _tab.Pitfall_level=data[7]
        _tab.Diversion_value=data[8]
        _tab.Status=data[9]
        _tab.Box_Id=data[10]
        DispatchEvent("POINT_INFO_CHANGE",_tab);
    else
        print("err",err);
    end
end)

EventManager.getInstance():addListener("server_respond_16122", function(event, cmd, data)
    --print("16122@@openBox",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        if PlayerOpenBoxSn[sn] and mapInfo.PlayerData[PlayerOpenBoxSn[sn]] then
            local times=mapInfo.PlayerData[PlayerOpenBoxSn[sn]].OpenTimes+1
            DispatchEvent("OPEN_BOX_INFO_CHANGE",{PlayerOpenBoxSn[sn],times});
            PlayerOpenBoxSn[sn]=nil
        else
            ERROR_LOG( "player data  pid is nil ,pid",PlayerOpenBoxSn[sn])
        end   
    elseif err==7 then
        showDlgError(nil,"今日开启已达上限")
    else
        print("err",err);
    end
end)

EventManager.getInstance():addListener("server_respond_16124", function(event, cmd, data)
    --print("16122@@repairPoint",sprinttb(data))
    local sn = data[1];
    local err = data[2];
    if err == 0 then
        DispatchEvent("REPAIR_POINT_SUCCEED");
    else
        print("err",err);
    end
end)

EventManager.getInstance():addListener("Leave_team_succeed", function(event,data)
    local mapId = SceneStack.MapId();
    if mapId == 551 then
        if data and data.pid == module.playerModule.GetSelfID() then
            BackToEntranceNpc()
        end
        queryMapInfo()
    end
end)

local function GetPlayerColNum()
    return mapInfo.PlayerData
end

---[===[寻路
local function getMinPoint(map)
    local pointList=map.openlist
    local minPoint=pointList[1]
    for i=1,#pointList do
        if minPoint.F>map.tal[pointList[i].name].F then
            minPoint=map.tal[pointList[i].name]
        end
    end
    return minPoint
end

local function GetPoint(list,point)
    for i=1,#list do
        if point==list[i] then
            return point
        end
    end
    return nil
end

local function CalcF(point)
    local F=point.F
    local parentF=0
    if point.parentPoint then
        parentF=point.parentPoint.F
    end
    return F+parentF
end

local function findpath(map,Star,End)
    map.openlist[#map.openlist+1]=Star
    local k=0
    while #map.openlist>0 do
        k=k+1
        local tempStart=getMinPoint(map)
        table.remove(map.openlist, 1)
        for i=1,#tempStart.adj do --相邻点
            local _point=map.tal[tempStart.adj[i]]
            if GetPoint(map.closelist,_point) then
                local F=CalcF(_point)
                if F<_point.F then
                    _point.parentPoint=tempStart
                    point.F=F
                end
            else
                _point.parentPoint=tempStart
                _point.F=CalcF(_point)
                map.openlist[#map.openlist+1]=_point
                map.closelist[#map.closelist+1]=_point
            end
        end
        if k>=50 then
            break
        end
        if GetPoint(map.closelist,End) then
            return GetPoint(map.closelist,End)
        end
    end
    return GetPoint(map.closelist,End)
end

local function GetPath(curr,to)
    local path={}
    local map={}
    map.openlist={}
    map.closelist={}

    map.tal={}
    for k,v in pairs(mapInfo.MapPointData) do
        map.tal[k]={name=k,adj=v.adj,F=1}
    end

    local startPoint=map.tal[curr]
    local endPoint=map.tal[to]
    local point=findpath(map,startPoint,endPoint)
    local k=0
    while point do
        k=k+1
        path[#path+1]=point.name
        point=point.parentPoint
        if point==startPoint or k>=20 then
            break
        end
    end
    return path
end
--]===]
local function CopyUI(UITab,pos,prefab,k)
	local _obj=nil
	if UITab[k]==nil then
		_obj=UnityEngine.Object.Instantiate(prefab.gameObject,pos.gameObject.transform)
		_obj.name=tostring(k)
		UITab[k]=_obj
	else
		_obj=UITab[k]
	end
	_obj.gameObject:SetActive(true)
	local item=CS.SGK.UIReference.Setup(_obj.transform)	
	return item,UITab
end



return {
    GetMapCfg = getMapCfg,
    GetSitePoint=GetResourceAndBoxPointCfg,

    GetPlayerColNum=GetPlayerColNum,

    GetResourceCfg=GetResourcesCfg,
    GetResourceCfgById=GetResourcesCfg,

    GetExchangeCfg=GetExchangeCfg,
    GetExchangeCfgById=GetExchangeCfg,

    GetPitFallCfgById=GetPitFallIdCfg,
    GetPitFallLevelCfg=GetPitFallCfgByLevel,

    GetBoxCfg=GetBoxCfg,

    GetDiversionCfg=loadFortressDiversionCfg,
    GetBossCfg=GetBossCfg,
    GetBuffCfg=GetBuffCfg,
    GetActionTimeCfg=GetRoleTimeCfg,

    QueryMapInfo = queryMapInfo,
    --QueryMove=QueryMove,
    QueryCollection = QueryCollection,
    QueryaAddPitfall = QueryAddPitfall,
    QueryExchange = QueryExchange,
    QueryDiversion = QueryDiversion,
    QueryGetRewards = QueryGetRewards,

    QueryOpenBox = QueryOpenBox,
    --QueryRepairPoint=QueryRepairPoint,
    QueryAfterFight = QueryAfterFight,--通知服务器战斗结束
    GetPath = GetPath,

    CopyUI = CopyUI,
    GetRandom = GetRandomValue,

    QueryStatus=QueryDefensiveFortressStatus,
    GetActivityStatus = GetActivityStatus,

    GetMapInfo = GetMapInfo,

    BackToEntranceNpc = BackToEntranceNpc,

}