Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);

Common_ShowCfgStageEffect(_Skill)

local target_list = SortWithParameter(target, "hp")
local fit_list = {}

for i = 1,2,1 do
	if target_list[i] then
		table.insert(fit_list, target_list[i])
	end
end

Common_FireBullet(0, attacker, fit_list, _Skill, {})

AddConfigBuff(attacker, target, _Skill)
Common_Sleep(attacker, 0.3)
