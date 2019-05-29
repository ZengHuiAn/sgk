local roleStarTab = nil

local starSkillCfg = nil
local heroStarSkillConfig = {}

local function GetStarEffect(id)
    if not starSkillCfg then
        heroStarSkillConfig = {}
        starSkillCfg = LoadDatabaseWithKey("star_type", "id")
        for _, v in pairs(starSkillCfg) do
            heroStarSkillConfig[v.role_id] = heroStarSkillConfig[v.role_id] or {need_sort = true}
            table.insert(heroStarSkillConfig[v.role_id], v)
        end
    end

    if id then
        return starSkillCfg[id]
    end
    return starSkillCfg
end

local function GetHeroStarSkillList(hero_id)
    GetStarEffect();
    return heroStarSkillConfig[hero_id] or {}
end

local function getroleStarTab()
    if roleStarTab then
        return {}, roleStarTab
    end

    roleStarTab = {}

    DATABASE.ForEach("role_star", function(v)
        if roleStarTab[v.id] == nil then
            roleStarTab[v.id] = {}
        end
        roleStarTab[v.id][v.level] = v

        -- 升星影响的技能
        local skillCfg = GetStarEffect(v.star_type)
        if skillCfg then
            skillCfg.star_list = skillCfg.star_list or {}

            assert(skillCfg.role_id == 0 or skillCfg.role_id == v.id,
            string.format("star_type id %d, role_id(%d) != role_star(%d, level %d)", 
            skillCfg.id, skillCfg.role_id, v.id, v.level))
            table.insert(skillCfg.star_list, v)
        end
    end)
    return {}, roleStarTab
end

local function CaclProperty(hero)
    local caclPropertyTab = {}
    if roleStarTab == nil then
        getroleStarTab()
    end

    if not roleStarTab[hero.id] then
        ERROR_LOG("hero star config not exists", hero.id)
        return {};
    end

    if hero.star == 0 then
        return {}
    else
        for star = 1, hero.star do
            for i = 0, 6 do
                local type = roleStarTab[hero.id][star] and roleStarTab[hero.id][star]["type"..i];
                if type and type ~= 0 then
                    local value = roleStarTab[hero.id][star]["value"..i];
                    caclPropertyTab[type] = (caclPropertyTab[type] or 0) + value;
                end
            end
        end
    end
    return caclPropertyTab
end

local commonTab = nil
local function getCommonTab()
    if commonTab then
        return commonTab
    end
    commonTab = {}
    local k = 1

    DATABASE.ForEach("common", function(v)
        if v.id >= 151 and v.id <= 180 then
            commonTab[k] = v
            k = k + 1
        end
    end)

    return commonTab
end

local starUpTab = nil
local function getStarUpTab()
    if starUpTab then
        return starUpTab
    end
    starUpTab = LoadDatabaseWithKey("star_up", "star")
    return starUpTab
end

-------------------------盗具--------------------------------
local weaponStarTab = nil
local function getWeaponStarTab()
    if weaponStarTab then
        return weaponStarTab
    end
    weaponStarTab = {}
    local index = 1
    DATABASE.ForEach("weapon_star", function(v)
        if weaponStarTab[v.id] == nil then
            weaponStarTab[v.id] = {}
        end
        weaponStarTab[v.id][v.level] = v
    end)
    return weaponStarTab
end


return {
    CaclProperty = CaclProperty,
    GetroleStarTab = getroleStarTab,
    GetCommonTab = getCommonTab,
    GetStarUpTab = getStarUpTab,
    GetWeaponStarTab = getWeaponStarTab,
    GetHeroStarSkillList = GetHeroStarSkillList,
    GetStarEffect = GetStarEffect,
}
