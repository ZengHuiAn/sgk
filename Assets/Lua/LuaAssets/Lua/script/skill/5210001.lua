--对一个随机地方造成真实伤害
local info = ...
local target = info.target

Common_FireWithoutAttacker(1103810, {target}, {
    TrueHurt = target.hp * 0.5,
    Type = 1,
})

RemoveRandomBuff();