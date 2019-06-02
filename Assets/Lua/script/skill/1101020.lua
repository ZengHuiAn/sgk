Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);

Common_ShowCfgStageEffect(_Skill)

local other_targets = Common_GetOtherTargets(target[1], all_targets)
local list = RandomInTargets(other_targets, 2)

Common_FireBullet(0, attacker, target[1], _Skill, {})
Common_FireBullet(0, attacker, list, _Skill, {})

Common_Sleep(attacker, 0.3)
