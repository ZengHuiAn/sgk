Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);
Common_ShowCfgStageEffect(_Skill)

-----------------------星级对应属性
local value = 11000

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
--------------------------
local round = 3
local hp_per = 0.55
local pro_per = value/10000

local pet = Common_SummonPet(attacker, 1100050, 1, round, pro_per, hp_per)
local cfg = GetSkillEffectCfg(_Skill.id)
if cfg.stage_effect_1 == "0" or cfg.stage_effect_1 == 0 or cfg.stage_effect_2 == "0" or cfg.stage_effect_2 == 0 then
    Common_AddStageEffect(30041, 1, 2, attacker, pet.mode)
    Common_Sleep(nil, 1.2)		
end

Common_Sleep(attacker, 0.3)