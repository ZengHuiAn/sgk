local switch = {
    [1] = function()
        LoadStory(4110101,function() end)
    end
}

if module.TeamModule.GetTeamInfo().id > 0 then
    local stage = module.CemeteryModule.GetTeam_stage(111)
    stage = stage - 1
    --ERROR_LOG("STAGE:",stage)
    local f = switch[stage]
    if(f) then
        f()
    else
    end
end