local manual = ...
if not Common_Skill_Check(attacker, _Skill, manual) then return end

local list = {}
-- 自己
table.insert(list, {target = attacker, button = Check_Button(attacker, attacker, _Skill.skill_type)});

return list