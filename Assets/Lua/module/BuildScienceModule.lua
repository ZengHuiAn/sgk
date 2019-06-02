local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Time = require "module.Time"
local Sn2Data = {};
local ScienceInfo = {};
local query_time = {};


local function QueryScience(map_id,func,isreset)
    if ScienceInfo[map_id] and not isreset and Time.now() - (query_time[map_id] or 0) < 60 then
        if func then
            func(ScienceInfo[map_id]);
        end
        return ScienceInfo[map_id];
    end
    local sn = NetworkService.Send(3423, {nil, map_id});
    Sn2Data[sn] = {map_id = map_id, callback = func};
    query_time[map_id] = Time.now();
    if coroutine.isyieldable() then
        Sn2Data[sn].co = coroutine.running()
        coroutine.yield();
    end
    return ScienceInfo[map_id]
end

local function updateScienceInfo(map_id, data )
   local title = data[1];
   local temp = {};

   for i=2,9 do
       table.insert( temp, data[i] );
   end
   ScienceInfo[map_id] = ScienceInfo[map_id] or {};

   ScienceInfo[map_id].title = title;

   ScienceInfo[map_id].data = temp;

   ScienceInfo[map_id].time = data[10] or 0;
end

EventManager.getInstance():addListener("server_respond_3424",function ( event,cmd,data )
    local sn = data[1];
    local result = data[2];
    -- print("查询关卡归属返回", sprinttb(data))    
    if result ~= 0 then
        return;
    end
    
    if Sn2Data[sn] and Sn2Data[sn].map_id then
        updateScienceInfo(Sn2Data[sn].map_id,data[3]);

        if Sn2Data[sn].callback then
            Sn2Data[sn].callback(ScienceInfo[Sn2Data[sn].map_id]);
        end
        if Sn2Data[sn].co then
            coroutine.resume(Sn2Data[sn].co);
        end
        DispatchEvent("QUERY_SCIENCE_SUCCESS",Sn2Data[sn].map_id);
    end
end)

EventManager.getInstance():addListener("MAP_OWNER_CHANGE",function ( event,data )
    local mapid = data.map_id;
    QueryScience(mapid, nil, true);
end)


local Sn3Data = nil

local function UpGradeScience( map_id, type,level )
    Sn3Data = Sn3Data or {};
    local sn = NetworkService.Send(3443, {nil, map_id,type,level});
    Sn3Data[sn] = {map_id = map_id,type = type ,level = level};
end


EventManager.getInstance():addListener("server_respond_3444",function ( event,cmd,data )
    local sn = data[1];
    local result = data[2];
    -- ERROR_LOG("升级关卡返回", sprinttb(data))    
    if result ~= 0 then
        QueryScience(Sn3Data[sn].map_id,nil,true);
        return;
    end
    -- print("=========",sprinttb(ScienceInfo[Sn3Data[sn].map_id]))
    
    if ScienceInfo then

        ScienceInfo[Sn3Data[sn].map_id].data[Sn3Data[sn].type] = ScienceInfo[Sn3Data[sn].map_id].data[Sn3Data[sn].type] + 1;

        DispatchEvent("UPGRADE_SUCCESS",Sn3Data[sn].map_id);
        module.NPCModule.Ref_NPC_LuaCondition()
    else

        if Sn3Data[sn].map_id then
            QueryScience(Sn3Data[sn].map_id);
        end
        DispatchEvent("UPGRADE_ERROR",Sn3Data[sn].map_id);
    end
    
end)


local function GetScience(map_id)

    if not ScienceInfo then
        return;
    else

        return ScienceInfo[map_id];
    end
end

return {
    QueryScience = QueryScience,
    GetScience = GetScience,

    UpGradeScience = UpGradeScience,
}
