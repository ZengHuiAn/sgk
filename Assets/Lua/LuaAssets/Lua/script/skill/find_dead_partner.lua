local manual = ...
if not Common_Skill_Check(attacker, _Skill, manual) then return end

local dead_list = GetDeadList()
local list = {}

for _, v in ipairs(dead_list) do
	if v.side == attacker.side and v.Force.pid == attacker.Force.pid then
		table.insert(list, {target = v, button = Check_Button(attacker, v, _Skill.skill_type)})
	end
end

if not next(list) then
	Common_ShowErrorInfo(attacker, 6, manual)
	return
end


return list
