local function Npc_showDialog(id, desc, delay, duration, type)
    SGK.Action.DelayTime.Create(delay):OnComplete(function() LoadNpcDesc(id, desc, nil, type, duration) end)
end

local function Npc_move(obj, Vector, delay, is_shunyi)
    local x,y,z = Vector.x,Vector.y,Vector.z
    SGK.Action.DelayTime.Create(delay):OnComplete(function() obj[SGK.MapPlayer]:MoveTo(Vector3(x,y,z),is_shunyi) end)
end

local switch = {
    [1] = function()
        LoadStory(4030101,function() end)
    end,
    [2] = function()
        --冰虾
        module.NPCModule.LoadNpcOBJ(1041802)
    end,
    [3] = function()
        --大猛犸
        module.NPCModule.LoadNpcOBJ(1041800,Vector3(0.3,0,9.5))
        utils.SGKTools.NPCDirectionChange(1041800,4)
        --阿尔
        utils.SGKTools.NPC_Follow_Player(2041800,false)
        local  obj = module.NPCModule.GetNPCALL(2041800)
        Npc_showDialog(2041800 ,"快点跟上来！",0.5, 1, 2)
        Npc_move(obj ,Vector3(0.7, 0, 8.42), 0.5)
    end,
    [4] = function()
        utils.SGKTools.NPC_Follow_Player(2041800,false)
        module.NPCModule.deleteNPC(1041800)
        --阿尔
        module.NPCModule.LoadNpcOBJ(2041800,Vector3(0.7, 0, 8.42),true)
        Npc_showDialog(2041800 ,"快把这头野兽解决了！",0.5, 1, 2)
    end,
    [5] = function()
        --阿尔
        utils.SGKTools.NPC_Follow_Player(2041800,false)
        module.NPCModule.LoadNpcOBJ(2041800,Vector3(0.7, 0, 8.42),true)
        local  obj = module.NPCModule.GetNPCALL(2041800)
        Npc_showDialog(2041800 ,"我们必须阻止他！",0.5, 1, 2)
        Npc_move(obj ,Vector3(-2.7,0,14.7), 0.5)
        Npc_changeDirection(obj, 3, 2)
    end,
    [6] = function()
        --阿尔
        utils.SGKTools.NPC_Follow_Player(2041800,false)
        module.NPCModule.LoadNpcOBJ(2041800,Vector3(-2.7,0,14.7),true)
    end
}

if module.TeamModule.GetTeamInfo().id > 0 then
    utils.SGKTools.NPC_Follow_Player(2041800,true)
    local stage = module.CemeteryModule.GetTeam_stage(103)
    stage = stage +1

    local f = switch[stage]
    if(f) then
        f()
    else
    end
end