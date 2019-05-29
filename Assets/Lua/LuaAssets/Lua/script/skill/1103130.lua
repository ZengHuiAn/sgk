Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);

Common_ShowCfgStageEffect(_Skill)
Common_FireBullet(0, attacker, list, _Skill, {})

Common_ChangeEp(target[1], attacker.ep, true)
Common_ChangeEp(attacker, -attacker.ep, true)

AddConfigBuff(attacker, target, _Skill)
Common_Sleep(attacker, 0.3)
