function Guide(quest)
    local npc_id  = quest.npc_id
    local map_id = tonumber(quest.map_id)
    local MapConfig = require "config.MapConfig"
    local npc_conf = MapConfig.GetMapMonsterConf(npc_id)
    if npc_conf then
        map_id = npc_conf.mapid
    end

    if map_id ~= GetCurrentMapID() then
        --SceneStack.EnterMap(map_id)
        module.EncounterFightModule.GUIDE.EnterMap(map_id)
    end
    Interact("NPC_"..npc_id)
end
