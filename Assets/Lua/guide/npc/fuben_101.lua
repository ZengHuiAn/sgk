local function Npc_showDialog(id, desc, delay, duration, type)
    SGK.Action.DelayTime.Create(delay):OnComplete(function() LoadNpcDesc(id, desc, nil, type, duration) end)
end

local function Npc_move(obj, Vector, delay, is_shunyi)
    local x,y,z = Vector.x,Vector.y,Vector.z
    SGK.Action.DelayTime.Create(delay):OnComplete(function() obj[SGK.MapPlayer]:MoveTo(Vector3(x,y,z),is_shunyi) end)
end


local switch = {
    [1] = function()
        local  obj = module.NPCModule.GetNPCALL(2016800)
        Npc_showDialog(2016800 ,"阿尔快住手！",0.5, 1, 2)
        Npc_move(obj ,Vector3(-0.34, 0, 2.93), 0.5)
    end,
    [2] = function()
        module.NPCModule.LoadNpcOBJ(2016800,Vector3(-0.34, 0, 2.93),true)
        Npc_showDialog(2016800 ,"等等！听我解释！",0.5, 1, 2)
    end,
    [3] = function()
        module.NPCModule.LoadNpcOBJ(2016800,Vector3(-0.34, 0, 2.93),true)
        Npc_showDialog(2016800 ,"喂！你别太过分了啊！",0.5, 1, 2)
    end,
    [4] = function()
        module.NPCModule.LoadNpcOBJ(2016800,Vector3(-0.34, 0, 2.93),true)
        Npc_showDialog(2016800 ,"必须要阻止阿尔释放大招！",0.5, 1, 2)
    end,
    [5] = function()
        module.NPCModule.LoadNpcOBJ(2016800,Vector3(-0.34, 0, 2.93),true)
        Npc_showDialog(2016800 ,"这下可以听我们解释了吧？",0.5, 1, 2)
    end
}

if module.TeamModule.GetTeamInfo().id > 0 then

    local stage = module.CemeteryModule.GetTeam_stage(101)
    stage = stage +1

    local f = switch[stage]
    if(f) then
        f()
    else
    end
end