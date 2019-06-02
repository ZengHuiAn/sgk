local manual = ...
if not Common_Skill_Check(attacker, _Skill, manual) then return end

local list = {}
local choose_list = All_target_list()

if not next(choose_list) then return end

table.insert(list, {target = "enemy", button = Check_Button_All(_Skill.skill_type)});		

return list;
