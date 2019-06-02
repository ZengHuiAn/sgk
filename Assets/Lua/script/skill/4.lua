Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
local info = ...
-- [[
if attacker[30081] > 0 then
	if not info.SingSkill then
		Common_ChangeEp(attacker, -_Skill.skill_consume_ep)
		Common_UnitConsumeActPoint(attacker, 1);
		Common_Sleep(attacker, 0.3)
		Common_UnitAddBuff(attacker, attacker, attacker[30081], 1, {
			singskill_index = _Skill.sort_index
		})
		Common_Sleep(attacker, 0.4)
		return
	end
end
--]]

if not info.SingSkill then 
	Common_ChangeEp(attacker, -_Skill.skill_consume_ep)
end

local target, all_targets = Common_GetTargets(...)

Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);

Common_ShowCfgStageEffect(_Skill)
OtherEffectInCfg(attacker, target, _Skill)


--[[子弹类型定义！！
	1	普攻
	2	单体攻击
	3	群体攻击
	4	召唤物攻击
	5	dot伤害
	6	反弹伤害
	7	反击伤害
	8	其他伤害来源,溅射,穿刺,链接 
	9	链接伤害 
	20	技能治疗
	21  持续治疗
	22  宠物治疗
	23  其他治疗
	30  其他效果---
]]

--[FindAllEnemy()    FindAllPartner()]

FireRandomTarget(0, attacker, all_targets, _Skill, {Duration = 0.3})

AddConfigBuff(attacker, target, _Skill)
Common_Sleep(attacker, 0.3)
