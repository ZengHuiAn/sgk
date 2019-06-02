local function Npc_showDialog(id, desc, delay, duration, type)
    SGK.Action.DelayTime.Create(delay):OnComplete(function() LoadNpcDesc(id, desc, nil, type, duration) end)
end

local function Npc_move(obj, Vector, delay, is_shunyi)
    local x,y,z = Vector.x,Vector.y,Vector.z
    SGK.Action.DelayTime.Create(delay):OnComplete(function() obj[SGK.MapPlayer]:MoveTo(Vector3(x,y,z),is_shunyi) end)
end

local switch = {
    [1] = function()
        LoadStory(4040101,function() end)
    end,
    [2] = function()
        local  obj = module.NPCModule.GetNPCALL(2042800)
        Npc_showDialog(2042800 ,"快把这些血蚊解决了！",0.5, 1, 2)
        Npc_move(obj ,Vector3(3.2, 0, 2.71), 0.5)     
    end,
    [3] = function()
        local  obj = module.NPCModule.GetNPCALL(2042800)
        module.NPCModule.LoadNpcOBJ(2042800,Vector3(3.2, 0, 2.71),true)
        Npc_showDialog(2042800 ,"快去把血莲取下来！",0.5, 1, 2)
        Npc_move(obj ,Vector3(3.8, 3.37, 11.43), 0.5)
    end,
    [4] = function()      
        module.NPCModule.LoadNpcOBJ(1042804)       
        module.NPCModule.LoadNpcOBJ(2042800,Vector3(1.43, 0, 2.03),true)
    end,
    [5] = function()
        module.NPCModule.LoadNpcOBJ(2042800,Vector3(2.32, 5.81, 15.54),true)
    end
}

if module.TeamModule.GetTeamInfo().id > 0 then
    local stage = module.CemeteryModule.GetTeam_stage(104)
    stage = stage +1

    local f = switch[stage]
    if(f) then
        f()
    else
    end
end