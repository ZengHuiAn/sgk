Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);

Common_ShowCfgStageEffect(_Skill)
OtherEffectInCfg(attacker, target, _Skill)

local function DoSkill(target, all)
    local attacks = 3
    local former_target = target
    
    for i = 1, 20, 1 do
        if attacks == 0 then
            break
        end

        if former_target.hp <= 0 then
            if #All_target_list(all) == 0 then
                break
            end
    
            former_target = SortWithParameter(All_target_list(all), "hp")[1]
            attacks = attacks + 1
        end
    
        Common_FireBullet(0, attacker, {former_target}, _Skill, {
            Attacks_Count = i,
        })
        Common_Sleep(attacker, 0.1)
        attacks = attacks - 1 
    end
end

if attacker.side == 2 and attacker.game.attacker_player_count > 1 then
    local new_list = Common_SplitTargetsByPid(attacker.focus_pid > 0)
    local target_bypid = {}

    for k, v in ipairs(target) do
        target_bypid[v.Force.pid] = v
    end

    for k, v in pairs(new_list) do
        Run(function ()
            DoSkill(target_bypid[k], v)
        end)
    end
else
    DoSkill(target[1], all_targets)
end

Common_Sleep(attacker, 0.3)
