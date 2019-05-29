Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);

Common_ShowCfgStageEffect(_Skill)

if attacker.side == 2 and attacker.game.attacker_player_count > 1 then
    local new_list = Common_SplitTargetsByPid(attacker.focus_pid > 0)
    local target_bypid = {}

    for k, v in ipairs(target) do
        target_bypid[v.Force.pid] = v
    end

    for k, v in pairs(new_list) do
        Run(function ()
            BallBulletFire(0, attacker, target_bypid[k], v, 3, _Skill, {})
        end)
    end
else
    BallBulletFire(0, attacker, target, all_targets, 3, _Skill, {})
end

AddConfigBuff(attacker, target, _Skill)
Common_Sleep(attacker, 0.3)
