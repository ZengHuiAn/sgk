Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
local info = ...

Common_ChangeEp(attacker, -_Skill.skill_consume_ep)
local target, all_targets = Common_GetTargets(...)

Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);
Common_FireBullet(1990311, attacker, {attacker}, nil, {Type = 30})

Common_ShowCfgStageEffect(_Skill)
OtherEffectInCfg(attacker, target, _Skill)
Common_FireBullet(1990320, attacker, target, _Skill, {})

AddConfigBuff(attacker, target, _Skill)
Common_Sleep(attacker, 0.3)
