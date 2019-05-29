--恢复我方生命值比例最低的x%的生命值
local all, partners, enemies = FindAllRoles()

if next(partners) then
    local list = SortWithHpPer(partners)
    local target = list[1]
    Common_FireWithoutAttacker(1100310, {target}, {
        Hurt = (target.hpp - target.hp) * 0.5,
        Type = 20,
    })
end

RemoveRandomBuff();