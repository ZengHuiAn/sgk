--恢复我方生命值比例最低的x%的生命值
local info = ...
local target = info.target

Common_FireWithoutAttacker(1100310, {target}, {
    Hurt = target.hpp * 0.25,
    Type = 20,
})

RemoveRandomBuff();
