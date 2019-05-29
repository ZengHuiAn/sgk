local function Npc_showDialog(id, desc, delay, duration, type)
    SGK.Action.DelayTime.Create(delay):OnComplete(function() LoadNpcDesc(id, desc, nil, type, duration) end)
end

local function Npc_move(obj, Vector, delay, is_shunyi)
    local x,y,z = Vector.x,Vector.y,Vector.z
    SGK.Action.DelayTime.Create(delay):OnComplete(function() obj[SGK.MapPlayer]:MoveTo(Vector3(x,y,z),is_shunyi) end)
end
local switch = {
    [1] = function()
        LoadStory(4120101,function() end)
        module.NPCModule.deleteNPC(2060808)
    end,

    [2] = function()
        module.NPCModule.deleteNPC(2060807)
    end,

    [3] = function()
        module.NPCModule.deleteNPC(2060806)
    end,

    [4] = function()
        module.NPCModule.deleteNPC(2060805)
    end
}


if module.TeamModule.GetTeamInfo().id > 0 then
    local stage = module.CemeteryModule.GetTeam_stage(112)
    stage = stage + 1
    -- ERROR_LOG("STAGE:",stage)
    local f = switch[stage]
    if(f) then
        f()
    else
    end
end