local function Npc_showDialog(id, desc, delay, duration, type)
    SGK.Action.DelayTime.Create(delay):OnComplete(function() LoadNpcDesc(id, desc, nil, type, duration) end)
end

local function Npc_move(obj, Vector, delay, is_shunyi)
    local x,y,z = Vector.x,Vector.y,Vector.z
    SGK.Action.DelayTime.Create(delay):OnComplete(function() obj[SGK.MapPlayer]:MoveTo(Vector3(x,y,z),is_shunyi) end)
end

local switch = {
    [1] = function()
        LoadStory(5020101,function() end)
        local  obj = module.NPCModule.GetNPCALL(2018801)
        Npc_move(obj ,Vector3(0, -1.9, 1.4), 0.5)
    end,
    [2] = function()
        local  obj = module.NPCModule.GetNPCALL(2018801)
        module.NPCModule.LoadNpcOBJ(2018801,Vector3(0, -1.9, 1.4),true)
        Npc_showDialog(2018801 ,"呜呜呜，爸爸你没事吧？",0.5, 1, 2)
        Npc_move(obj ,Vector3(-0.08, -1.9, 6.96), 0.5)    
    end,
    [3] = function()
        local  obj1 = module.NPCModule.GetNPCALL(2018801)
        local  obj2 = module.NPCModule.GetNPCALL(2018800)
        module.NPCModule.LoadNpcOBJ(2018801,Vector3(-0.08, -1.9, 6.96),true)
        Npc_showDialog(2018801 ,"这个僵尸有点眼熟……",0.5, 1, 1)
        Npc_showDialog(2018800 ,"一个已死之人也想阻止我吗？",0.5, 1, 2)
        Npc_move(obj1 ,Vector3(0.07, -1.9, 13.97), 0.5)  
        Npc_move(obj2 ,Vector3(1.31, -1.9, 14.5), 0.5)  
    end,
    [4] = function()
        module.NPCModule.LoadNpcOBJ(2018801,Vector3(0.07, -1.9, 13.97),true)
        module.NPCModule.LoadNpcOBJ(2018800,Vector3(1.31, -1.9, 14.5),true)
    end,
    [5] = function()
        module.NPCModule.deleteNPC(2018800)
    end
}

if module.TeamModule.GetTeamInfo().id > 0 then
    local stage = module.CemeteryModule.GetTeam_stage(202)
    stage = stage +1

    local f = switch[stage]
    if(f) then
        f()
    else
    end
end