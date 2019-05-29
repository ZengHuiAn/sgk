local UserDefault = require "utils.UserDefault"

local xiuluo = {}

function xiuluo:Load_OP()
    local cj = SGK.ResourcesManager.Load("prefabs/effect/op_cj.prefab")
    local _cj = CS.UnityEngine.GameObject.Instantiate(cj)
    UnityEngine.GameObject.Destroy(_cj.gameObject, 7.2)

    utils.SGKTools.Stop()

    local map_xiuluo = UserDefault.Load("map_xiuluo", true)
    map_xiuluo.first = true
    UserDefault.Save()
end

function xiuluo:Start()
    local map_xiuluo = UserDefault.Load("map_xiuluo", true)
    if not map_xiuluo.first then
        self.Load_OP()
    end
end


return xiuluo
