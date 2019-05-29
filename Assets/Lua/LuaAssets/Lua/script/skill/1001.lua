Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, _Skill[8001])
local target, all_targets = Common_GetTargets(...)
Add_Cfg_Buff(attacker, _Skill, target, all_targets)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);

--发射子弹
Common_FireBullet(0, attacker, target, _Skill, {
	-- Duration = 0.1,
	-- Interval = 0.1,
	-- Hurt = 10000,
	-- Type = 1,
	-- Attacks_Total = 3,
	-- Element = 6,
	-- parameter = {
	-- 	damagePromote = 10000,
	-- 	damageReduce = 10000,
	-- 	critPer = 10000,
	-- 	critValue = 10000,
	-- 	ignoreArmor = 10000,
	-- 	ignoreArmorPer = 10000,
	-- 	shieldHurt = 10000,
	-- 	shieldHurtPer = 10000,
	-- 	healPromote = 10000,
	-- 	healReduce = 10000,
	-- 	damageAdd = 10000,
	-- }
})

Common_Sleep(attacker, 0.3)
