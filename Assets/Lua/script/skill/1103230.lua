Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);

Common_ShowCfgStageEffect(_Skill)
OtherEffectInCfg(attacker, target, _Skill)

----------------------
local T = {}
local max_count = 0
for _, v in ipairs(FindAllEnemy()) do
    if v.BuffID_2103210 > 0 then
        local count = RepeatReomveBuff(v, 2103210, 20)
        if count > max_count then
            max_count = count
        end
        table.insert(T, {role = v, count = count})
    end
end

for i = 1, max_count do
    for _, v in pairs(T) do 
        if i <= v.count then 
            Common_FireBullet(0, attacker, {v.role}, _Skill, {
                Duration = 0,
                Interval = 0,
            })
        end
    end
    Common_Sleep(attacker, 0.1)
end
----------------------

AddConfigBuff(attacker, target, _Skill)
Common_Sleep(attacker, 0.3)
