local switch = {
    [1] = function()
        module.NPCModule.LoadNpcOBJ(1015805)
        module.NPCModule.LoadNpcOBJ(1015806)
        module.NPCModule.LoadNpcOBJ(1015807)
        module.NPCModule.LoadNpcOBJ(1015808)
        module.NPCModule.LoadNpcOBJ(1015809)
        module.NPCModule.LoadNpcOBJ(1015810)
        module.NPCModule.LoadNpcOBJ(1015811)
        module.NPCModule.LoadNpcOBJ(1015812)
        module.NPCModule.LoadNpcOBJ(1015813)

        LoadStory(4050001,function() end)
    end,
    [2] = function()
        --utils.SGKTools.loadEffect("UI/fx_chuan_ren",2015803)
        module.NPCModule.LoadNpcOBJ(1015808)
        module.NPCModule.LoadNpcOBJ(1015809)
        module.NPCModule.LoadNpcOBJ(1015810)
        module.NPCModule.LoadNpcOBJ(1015811)
        module.NPCModule.LoadNpcOBJ(1015812)
        module.NPCModule.LoadNpcOBJ(1015813)
    end,
    [3] = function()
        module.NPCModule.LoadNpcOBJ(1015811)
        module.NPCModule.LoadNpcOBJ(1015812)
        module.NPCModule.LoadNpcOBJ(1015813)
        --绿菇
        module.NPCModule.LoadNpcOBJ(1015802,Vector3(6.3,0,3.7))
        --紫菇
        module.NPCModule.LoadNpcOBJ(1015803,Vector3(5.3,0,3.3))
    end,
    [4] = function()
        --红菇
        module.NPCModule.LoadNpcOBJ(1015800,Vector3(4.1,0,-1.1))
        --绿菇
        module.NPCModule.LoadNpcOBJ(1015802,Vector3(6.3,0,-1.7))
        --紫菇
        module.NPCModule.LoadNpcOBJ(1015803,Vector3(6.8,0,-0.2))
    end,
    [5] = function()
        --红菇
        module.NPCModule.LoadNpcOBJ(1015802,Vector3(4.6,0,-3.3))
        --金菇
        module.NPCModule.LoadNpcOBJ(1015803,Vector3(5.3,0,-2.6))
        --绿菇
        module.NPCModule.LoadNpcOBJ(1015800,Vector3(3.8,0,-2.7))
        --紫菇
        module.NPCModule.LoadNpcOBJ(1015801,Vector3(3.6,0,-1.7))
    end,
    [6] = function()
        module.NPCModule.deleteNPC(2015801)
        module.NPCModule.deleteNPC(2015802)
        module.NPCModule.deleteNPC(2015803)
        module.NPCModule.deleteNPC(2015804)
        module.NPCModule.deleteNPC(2015805)
        module.NPCModule.deleteNPC(2015806)
    end
}

if module.TeamModule.GetTeamInfo().id > 0 then
    utils.SGKTools.NPC_Follow_Player(2015800,true)
    local stage = module.CemeteryModule.GetTeam_stage(105)
    stage = stage +1
    
    local f = switch[stage]
    if(f) then
        f()
    else
    end
end