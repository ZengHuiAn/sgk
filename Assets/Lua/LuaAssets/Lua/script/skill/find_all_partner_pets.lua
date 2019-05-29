local manual = ...
if not Common_Skill_Check(attacker, _Skill, manual) then return end

local list = {}

table.insert(list, {target = "enemy", button= "UI/fx_pet_fz_run", type = "partner_pets"})

return list;
