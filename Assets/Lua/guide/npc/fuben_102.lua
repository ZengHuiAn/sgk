local function Npc_showDialog(id, desc, delay, duration, type)
    SGK.Action.DelayTime.Create(delay):OnComplete(function() LoadNpcDesc(id, desc, nil, type, duration) end)
end

local function Npc_move(obj, Vector, delay, is_shunyi)
    local x,y,z = Vector.x,Vector.y,Vector.z
    SGK.Action.DelayTime.Create(delay):OnComplete(function() obj[SGK.MapPlayer]:MoveTo(Vector3(x,y,z),is_shunyi) end)
end

local function Npc_changeDirection(obj, direction, delay)
    SGK.Action.DelayTime.Create(delay):OnComplete(function() obj[SGK.MapPlayer]:SetDirection(direction) end)
end

local switch = {
    [1] = function()
        local  obj = module.NPCModule.GetNPCALL(2039800)
        Npc_showDialog(2039800 ,"梁三郎你会毁了黄金矿脉的！",0.5, 1, 2)
        Npc_move(obj ,Vector3(-2.455467, 0, 12.08308), 0.5)
    end,
    [2] = function()
        module.NPCModule.LoadNpcOBJ(2039800,Vector3(-2.378244, 0, 11.41609),true)
        Npc_showDialog(2039800 ,"我今天就算违抗命令也要阻止你！",0.5, 1, 2)     
    end,
    [3] = function()
        module.NPCModule.LoadNpcOBJ(2039800,Vector3(-2.378244, 0, 11.41609),true)
        Npc_showDialog(2039800 ,"这些矿猿怎么回事？",0.5, 1, 2)     
    end,
    [4] = function()
        module.NPCModule.LoadNpcOBJ(2039800,Vector3(-2.378244, 0, 11.41609),true)
        Npc_showDialog(2039800 ,"这些矿猿怎么回事？",0.5, 1, 2)     
    end,
    [5] = function()
        local  obj = module.NPCModule.GetNPCALL(2039800)
        module.NPCModule.LoadNpcOBJ(2039800,Vector3(-2.378244, 0, 11.41609),true)
        Npc_move(obj ,Vector3(-2.7, 0, 14.06), 0.5)
        Npc_showDialog(2039800 ,"啊，被发现了~",0.5, 1, 2)
        Npc_changeDirection(obj, 7, 2)
    end
}

if module.TeamModule.GetTeamInfo().id > 0 then
    local stage = module.CemeteryModule.GetTeam_stage(102)
    stage = stage +1

    local f = switch[stage]
    if(f) then
        f()
    else
    end
end