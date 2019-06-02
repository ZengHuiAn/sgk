local manual = ...
if not Common_Skill_Check(attacker, _Skill, manual) then return end

local list = {}

table.insert(list, {target = "partner",  button = Check_Button_All(_Skill.skill_type), random = 2})

return list;
