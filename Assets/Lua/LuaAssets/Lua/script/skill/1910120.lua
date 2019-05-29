Common_UnitConsumeActPoint(attacker, 1);
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
local other_targets = Common_GetOtherTargets(target[1], all_targets)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);

Common_ShowCfgStageEffect(_Skill)
OtherEffectInCfg(attacker, target, _Skill)

Common_FireBullet(0, attacker, target, _Skill, {})

local list = RandomInTargets(other_targets, 2)
Common_FireBullet(0, attacker, list, _Skill, {})

AddConfigBuff(attacker, target, _Skill)
Common_Sleep(attacker, 0.3)
