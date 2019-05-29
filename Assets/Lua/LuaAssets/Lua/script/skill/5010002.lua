--清空随机一个敌人的蓝
local all, partners, enemies = FindAllRoles()

if next(enemies) then
    local enemy = enemies[RAND(1, #enemies)]
    Common_ChangeEp(enemy, -100, true)
end

RemoveRandomBuff();