local manual = ...
if not Common_Skill_Check(attacker, _Skill, manual) then return end

local enemys = FindAllEnemy()
local list = {}

if GetFightData().fight_id == 11010100 then --新手战斗打陆游七
	for _, v in ipairs(enemys) do
		if v.mode == 11088 then
			table.insert(list, {target = v, button = Check_Button(attacker, v, _Skill.skill_type)})
			return list
		end
	end
end

local choose_list = Target_list(attacker, nil, nil, _Skill)

local multiple_choose = false
local focus = false
-- [[
if attacker 
and attacker.game 
and attacker.game.attacker_player_count
and attacker.game.attacker_player_count > 1 
and attacker.side == 2 then
	multiple_choose = true
	if _Skill.skill_consume_ep > 0 and attacker.focus_pid > 0 then
		focus = true
	end
end
--]]

for _, v in ipairs(choose_list) do
	table.insert(list, {target = v, button = Check_Button(attacker, v, _Skill.skill_type), multiple_choose = multiple_choose, focus = focus})
end

return list
