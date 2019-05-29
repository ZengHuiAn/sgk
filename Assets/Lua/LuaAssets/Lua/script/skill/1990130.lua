Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);

Common_ShowCfgStageEffect(_Skill)
OtherEffectInCfg(attacker, target, _Skill)

for _, v in ipairs(target) do
	local damagePromote = 0.5 * v.BuffID_2990110
	Common_FireBullet(0, attacker, {v}, _Skill, {
		parameter = {
			damagePromote = damagePromote,
		}
	})
end

Common_Sleep(attacker, 0.3)
