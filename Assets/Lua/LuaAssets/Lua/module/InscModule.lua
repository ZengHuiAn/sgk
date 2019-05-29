local EquipModule = require "module.equipmentModule"
local equipCofig = require "config.equipmentConfig"

local function CaclPropertyByInsc(v, pid)
    local propertyTab = {}
    if v.type == 1 then
        ---基础属性
        for i,j in ipairs(EquipModule.GetIncBaseAtt(v.uuid, pid)) do
            local _value = j.allValue
            propertyTab[j.key] = (propertyTab[j.key] or 0) + _value
        end
        ---附加属性
        for i,j in pairs(EquipModule.GetAttribute(v.uuid, pid)) do
            if j.key ~= 0 then
                local _key = j.key
                local _value = j.allValue
                propertyTab[_key] = (propertyTab[_key] or 0) + _value
            end
        end
    end
    return propertyTab
end

local function CaclProperty(hero)
    local propertyTab = {}
    local heroEquip = EquipModule.GetHeroEquip(hero.id)
    for k,v in pairs(heroEquip) do
        if v.type == 1 then
            ---基础属性
            for i,j in ipairs(EquipModule.GetIncBaseAtt(v.uuid)) do
                local _value = j.allValue
                if v.suits ~= 0 then
                    _value = _value * equipCofig.GetOtherSuitsCfg().In
                end
                propertyTab[j.key] = (propertyTab[j.key] or 0) + _value
            end
            ---附加属性
            for i,j in pairs(EquipModule.GetAttribute(v.uuid)) do
                if j.key ~= 0 then
                    local _key = j.key
                    local _value = j.allValue
                    if v.suits ~= 0 then
                        _value = _value * equipCofig.GetOtherSuitsCfg().In
                    end
                    propertyTab[_key] = (propertyTab[_key] or 0) + _value
                end
            end
        end
    end
    return propertyTab
end

return {
    CaclProperty = CaclProperty,
    CaclPropertyByInsc = CaclPropertyByInsc,
}
