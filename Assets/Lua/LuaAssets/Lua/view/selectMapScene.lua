local MapConfig = require "config.MapConfig"

local selectMapScene = {}

function selectMapScene:Start()
    self:initData()
    self:initInfo()
end

function selectMapScene:findBattleId()
    self.battleId = 100101
    local _list = module.fightModule.GetBattleConfig()
    for k,v in pairs(_list) do
        if v.background == SceneStack.MapId() then
            self.battleId = v.battle_id
            return
        end
    end
    ERROR_LOG("selectMapScene not find mapId")
end

function selectMapScene:initData()
    self:findBattleId()
end

function selectMapScene:initInfo()
    DialogStack.PushPref("newSelectMap/selectMapInfo", self.battleId)
end

return selectMapScene
