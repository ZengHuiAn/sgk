--[[蓄力通用buff
	sing_type 类型
	1.最差吟唱条：会被打断，会被击退

	2.普通吟唱条：会被打断，不会被击退，打断时技能释放失败

	3.特殊吟唱条：不会被打断，但被攻击时会减少进度

	4.无敌吟唱条：不会被打断，不会被减少进度

]]
local sing_type_list = {
	[1] = {BeatBack = 1 , Break = 1 },
	[2] = {BeatBack = 0 , Break = 1 },
	[3] = {BeatBack = 1 , Break = 0 },
	[4] = {BeatBack = 0 , Break = 0 },
}

local randombuff

function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
	target.Aciton_Sing = 1

	--固定的成长格和可击退格
	buff.BeatBack_count = 2 + target.Sing_Speed_Change
	buff.Certainly_Increase = 0
	
	buff.Sing_Speed = buff.BeatBack_count + buff.Certainly_Increase

	buff.Next_Progress = buff.Sing_Speed
	buff.Total_Progress = buff.cfg_property[2] or 2
	buff.sing_type = buff.cfg_property[1] or 1

	buff.Current_Progress = 0
	buff.Current_BeatBack_count = buff.BeatBack_count
	
	buff.Is_BeatBack = sing_type_list[buff.sing_type].BeatBack
	buff.Is_Break = sing_type_list[buff.sing_type].Break

	CreateSingSkill(buff.SingSkill_id, target, buff.sing_type, buff.Total_Progress, buff.Current_Progress, buff.Current_BeatBack_count, buff.Certainly_Increase)
	UnitPlayLoopAction(target, "skill")
	if buff.cfg_property[3] then
		randombuff = AddRandomBuff(target, buff.cfg_property[3])
	end
end

function onEnd(target, buff)
	RemoveCurrentSingSkill(target)
	UnitPlay(target, "idle")
	target.Aciton_Sing = 0

	if buff.cfg_property[3] then
        RemoveRandomBuff(randombuff.uuid) 
	end
	
	add_buff_parameter(target, buff, -1)
end

function onTick(target, buff)
	if target.hp <= 0 then
		return
	end

	buff.Current_BeatBack_count = buff.BeatBack_count  --可击退计数
	Common_UnitConsumeActPoint(attacker, 1);
	buff.Current_Progress = buff.Current_Progress + buff.Next_Progress

	target.Current_Progress = buff.Current_Progress
	target.Total_Progress = buff.Total_Progress

	if buff.Current_Progress >= buff.Total_Progress then
		SetCurrentSingSkill(target, buff.Current_Progress, buff.Current_BeatBack_count, buff.Certainly_Increase)
		Sleep(0.5)
		CurrentSingSkillCast(target, buff.singskill_index)
		RemoveCurrentSingSkill(target)
		UnitRemoveBuff(buff);
		return
	end
	buff.Next_Progress = buff.Sing_Speed

	SetCurrentSingSkill(target, buff.Current_Progress, buff.Current_BeatBack_count, buff.Certainly_Increase)
end

function targetAfterHit(target, buff, bullet)
	if buff.Is_BeatBack == 1 then
		--[[
		if buff.Current_BeatBack_count > 0 and bullet.skilltype == 4 then
			buff.Next_Progress = buff.Next_Progress - 1
			buff.Current_BeatBack_count = buff.Current_BeatBack_count - 1

			SetCurrentSingSkill(target, buff.Current_Progress, buff.Current_BeatBack_count, buff.Certainly_Increase)
		end
		--]]
	end
end