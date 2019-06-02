Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)

Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);
Common_ShowCfgStageEffect(_Skill)
OtherEffectInCfg(attacker, target, _Skill)

-----------星级对应属性
local value = 17600

local star_list = {
    [1] = 0.15,
    [2] = 0.21,
    [3] = 0.28,
    [4] = 0.36,
}

local star_promote = 0
for i = 1, attacker[40002],1 do
    star_promote = star_promote + star_list[i]
end
value = value * (1 + star_promote)
-----------------------------------
Common_FireBullet(0, attacker, target, _Skill, {})

Common_UnitAddBuff(attacker, target[1], 2100020, 1, {
    parameter_99 = {k= 2100020, v = value}
})     
Common_Sleep(attacker, 1)

AddConfigBuff(attacker, target, _Skill)
Common_Sleep(attacker, 0.3)
