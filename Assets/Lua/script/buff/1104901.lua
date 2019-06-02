--[无视目标50%防御，入场时窃取敌方所有目标（入场时攻击）的20%攻击附加给自身，无法驱散]
local effect = nil

function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onRoundStart(target, buff)
	if not effect then
		for _, v in ipairs(FindAllEnemy()) do
			Common_UnitAddBuff(attacker, v, 110002)
		end
		effect = true
	end
	Common_Sleep(target, 0.8)
end

function onPostTick(target, buff)
	if buff.not_go_round > 0 then
		return
	end

	buff.remaining_round = buff.remaining_round - 1;
	if buff.remaining_round <= 0 then
		UnitRemoveBuff(buff);
	end	
end

