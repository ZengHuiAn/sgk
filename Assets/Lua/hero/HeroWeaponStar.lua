local HeroStar = require "hero.HeroStar"

local function CaclProperty(hero)
    local caclPropertyTab = {}
    local _weaponStarTab = HeroStar.GetWeaponStarTab()
    local _heroCfg = module.HeroModule.GetConfig(hero.id)
    if not _heroCfg then
        return {}
    end
    local weapon_id = _heroCfg.weapon; -- TODO:
    
    if not _weaponStarTab[weapon_id] then
        ERROR_LOG('hero weapon star config not exists', hero.id)
        return {};
    end

    if hero.weapon_star == 0 then
        return {}
    else
        for star = 1, hero.weapon_star do
            for i = 0, 6 do
                local type = _weaponStarTab[weapon_id][star] and _weaponStarTab[weapon_id][star]["type"..i];
                if type and type ~= 0 then
                    local value = _weaponStarTab[weapon_id][star]["value"..i];
                    caclPropertyTab[type] = (caclPropertyTab[type] or 0) + value;
                end
            end
        end
    end
    return caclPropertyTab
end

return {
    CaclProperty = CaclProperty
}
