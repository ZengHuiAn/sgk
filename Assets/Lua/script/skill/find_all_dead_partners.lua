local manual = ...
if not Common_Skill_Check(attacker, _Skill, manual) then return end

local dead_list = GetDeadList()
local list = {}
local t = {}

for _, v in ipairs(dead_list) do
	if v.side == attacker.side and v.Force.pid == attacker.Force.pid then
		table.insert(t, v)
	end
end

if not next(t) then
	Common_ShowErrorInfo(attacker, 6, manual)
	return
end

table.insert(list, {target = "partner",  button = Check_Button_All(_Skill.skill_type), type = "dead_partners", value = t});	

return list
