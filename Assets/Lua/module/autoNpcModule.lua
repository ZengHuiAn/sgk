local MapConfig = require "config.MapConfig"
local npcList = {}

local function createNpc(gid, pos, moveToPos)
    local _cfg = MapConfig.GetMapMonsterConf(gid)
    local _npc = nil
	if _cfg then
		_npc = LoadNpc(_cfg, pos)
    else
        ERROR_LOG(gid, "cfg not find")
        return
	end
    if _npc then
        if _npc[SGK.MapInteractableMenu] then
            _npc[SGK.MapInteractableMenu].LuaTextName = "autoNpcGuide"
            _npc[SGK.MapInteractableMenu].values[0] = gid
            _npc[SGK.MapInteractableMenu].values[1] = _cfg.script
            if moveToPos then
                _npc[SGK.MapPlayer]:MoveTo(moveToPos)
            end
            npcList[gid] = {obj = _npc}
        end
    else
        ERROR_LOG(gid, "create error")
    end
end

local function checkNpc(gid)
    if npcList[gid] and npcList[gid].obj then
        if not utils.SGKTools.GameObject_null(npcList[gid].obj.gameObject) then
            return true
        end
    end
    return false
end

local function moveByGid(gid, pos)
    if not checkNpc(gid) then
        createNpc(gid, nil, pos)
    else
        if npcList[gid] and npcList[gid].obj then
            if pos then
                npcList[gid].obj[SGK.MapPlayer]:MoveTo(pos)
            end
        else
            ERROR_LOG("npc", gid, "not find")
        end
    end
end

return {
    CreateNpc = createNpc,
    MoveByGid = moveByGid,
}
