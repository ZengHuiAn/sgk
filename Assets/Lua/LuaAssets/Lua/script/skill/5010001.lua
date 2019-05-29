--降低所有敌方的攻击50%
local all, partners, enemies = FindAllRoles()

if next(enemies) then
    for k, v in ipairs(enemies) do
        Common_UnitAddBuff(nil, v, 2200005)
    end
end

RemoveRandomBuff();