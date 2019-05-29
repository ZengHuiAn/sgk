local manual = ...
if not Common_Skill_Check(attacker, _Skill, manual) then return end

local partners = FindAllPartner()
local list = {}

for _, v in ipairs(partners) do
	table.insert(list, {target = v, button = Check_Button(attacker, v, _Skill.skill_type)})
end

return list
