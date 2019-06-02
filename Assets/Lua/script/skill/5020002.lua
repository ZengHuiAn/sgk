--提高所有友方的攻击50%
local all, partners, enemies = FindAllRoles()

if next(partners) then
    for k, v in ipairs(partners) do
        Common_UnitAddBuff(nil, v, 2200015)
    end
end

RemoveRandomBuff();