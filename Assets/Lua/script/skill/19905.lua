common_enter(attacker)
--Common_UnitAddBuff(attacker, attacker, 99999)
UnitPlay(attacker, "ruchang", 0, {speed=1.0, duration =2.0});

local t = {
    [8000001] = {skills = {0, 0, 0, 0}, buffs = {}, property = { hp = 0 }},
    [8000002] = {skills = {0, 0, 0, 0}, buffs = {}, property = { hp = 0 }},
    [8000003] = {skills = {0, 0, 0, 0}, buffs = {}, property = { hp = 0 }},
    [8000004] = {skills = {0, 0, 0, 0}, buffs = {}, property = { hp = 0 }},
    [8000005] = {skills = {1001, 1001, 1001, 0}, buffs = {},  property = {  }},
}

if t[attacker.id] then
    local skills = t[attacker.id].skills
    for i = 4, 1,-1 do
        local skill = SkillGetInfo(attacker, i)
        if skill and skills[i] ~= 0 then
            SkillChangeId(target, i, skills[i])
        end
    end

    local property = t[attacker.id].property
    for k, v in pairs(property) do
        attacker[k] = v
    end

    local buffs = t[attacker.id].buffs
    for k, v in pairs(buffs) do
        Common_UnitAddBuff(attacker, attacker, v)
    end
end
