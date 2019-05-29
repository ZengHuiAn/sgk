local switch = {
    [1] = function()
    end,
    [2] = function()   
    end,
    [3] = function()
    end,
    [4] = function()
    end,
    [5] = function()
    end
}

if module.TeamModule.GetTeamInfo().id > 0 then
    local stage = module.CemeteryModule.GetTeam_stage(201)
    stage = stage +1

    local f = switch[stage]
    if(f) then
        f()
    else
    end
end