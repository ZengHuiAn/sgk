local function Npc_showDialog(id, desc, delay, duration, type)
    SGK.Action.DelayTime.Create(delay):OnComplete(function() LoadNpcDesc(id, desc, nil, type, duration) end)
end

local function Npc_move(obj, Vector, delay, is_shunyi)
    local x,y,z = Vector.x,Vector.y,Vector.z
    SGK.Action.DelayTime.Create(delay):OnComplete(function() obj[SGK.MapPlayer]:MoveTo(Vector3(x,y,z),is_shunyi) end)
end

local switch = {
    [1] = function()
        print("999999999999999999999999999999")
        local  obj = module.NPCModule.GetNPCALL(2065801)-------------------金晓明
        local  obj2 = module.NPCModule.GetNPCALL(2065802)--------------------苟赋硅
        module.NPCModule.LoadNpcOBJ(1065804)
        Npc_move(obj ,Vector3(4.16, 0, -4.69), 0.5)
        Npc_move(obj2 ,Vector3(3.38, 0, -4.73), 1)
        Npc_showDialog(2065801 ,"大哥，这和我们之前说好的不一样啊！",1, 2, 2)
        Npc_showDialog(2065802 ,"如果你不去拔狮鹫毛的话我们也不会被发现！",5, 2, 2)
        Npc_showDialog(2065801 ,"大哥不要生气，你看我们的救兵不就来了吗！",9, 2, 2)
    end
}

if module.TeamModule.GetTeamInfo().id > 0 then
    utils.SGKTools.NPC_Follow_Player(2041800,true)
    local stage = module.CemeteryModule.GetTeam_stage(116)
    stage = stage +1

    local f = switch[stage]
    if(f) then
        f()
    else
    end
end