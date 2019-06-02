local switch = {
    [1] = function()
    end,
    [2] = function()    
    end,
    [3] = function()
        module.NPCModule.deleteNPC(2040801)
        module.NPCModule.LoadNpcOBJ(1040801)
        module.NPCModule.LoadNpcOBJ(2040802,Vector3(-6,0,-1.2))
        utils.SGKTools.NPCDirectionChange(2040802,6)
        module.NPCModule.LoadNpcOBJ(2040803,Vector3(-6,0,-2.7))
        utils.SGKTools.NPCDirectionChange(2040803,6)
        module.NPCModule.LoadNpcOBJ(2040804,Vector3(-6,0,-4.2))
        utils.SGKTools.NPCDirectionChange(2040804,6)
    end,
    [4] = function()
    end,
    [5] = function()
    end
}

if module.TeamModule.GetTeamInfo().id > 0 then
    local stage = module.CemeteryModule.GetTeam_stage(203)
    stage = stage +1

    local f = switch[stage]
    if(f) then
        f()
    else
    end
end