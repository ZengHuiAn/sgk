--晕眩随机一个敌人
local info = ...
local target = info.target

Common_UnitAddBuff(nil, target, 7008, 1)

RemoveRandomBuff();