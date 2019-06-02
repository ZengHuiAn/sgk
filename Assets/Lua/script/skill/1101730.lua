Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);

Common_ShowCfgStageEffect(_Skill)
OtherEffectInCfg(attacker, target, _Skill)

local attacks = 1
if (target[1].hp / target[1].hpp) > (attacker.hp / attacker.hpp) then
    attacks = attacks + 1
end

if #FindAllPartner() < #FindAllEnemy() then
    attacks = attacks + 1
end

Common_FireBullet(0, attacker, target, _Skill, {
	Attacks_Total = attacks,
})

AddConfigBuff(attacker, target, _Skill)
Common_Sleep(attacker, 0.3)
