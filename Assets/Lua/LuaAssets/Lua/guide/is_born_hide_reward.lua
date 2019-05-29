
local obj,gid = ...
gid = tonumber(gid)

local function UpdateStatus( ... )
    if  not module.QuestModule.Get(350012) or module.QuestModule.Get(350012).status ~= 1 then
        DispatchEvent("UpdateNpcMapEffect6",{gid = gid,flag = false});
    else
        DispatchEvent("UpdateNpcMapEffect6",{gid = gid,flag = true});
    end

    module.MapNPCModule.StartCoro(gid,function ( ... )
        UpdateStatus()
    end)
end

module.MapNPCModule.StartCoro(gid,function ( ... )
    UpdateStatus()
end)

UpdateStatus();

