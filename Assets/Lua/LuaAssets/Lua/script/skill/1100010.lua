Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);
Common_ShowCfgStageEffect(_Skill)

----------------------星级对应属性
local value = 11000

local star_list = {
    [1] = 0.15,
    [2] = 0.21,
    [3] = 0.28,
    [4] = 0.36,
}

local star_promote = 0
for i = 1, attacker[40001],1 do
    star_promote = star_promote + star_list[i]
end
value = value * (1 + star_promote)

----------------------------------------
Common_FireBullet(0, attacker, target, _Skill, {
    Hurt = attacker.ad * value/10000,
    parameter = {
        [300080] = 3000
    }
})

Common_Sleep(attacker, 0.3)
