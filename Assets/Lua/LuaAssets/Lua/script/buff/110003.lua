local lost_armor = 0
local relevant_buff = nil
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)

	lost_armor = target.armor * 0.3
	target[1314] = target[1314] - 3000
	local relevant_buff = Common_UnitAddBuff(attacker, buff.attacker, 110004, nil, {
		armorup = lost_armor, 
		relevant_buff = buff,
	})
end

--buff消失的时候触发
function onEnd(target, buff)
	add_buff_parameter(target, buff, -1)
	target[1314] = target[1314] - 3000
	UnitRemoveBuff(relevant_buff)
end

function onPostTick(target, buff, round)
	buff.remaining_round = buff.remaining_round - 1;
	if buff.remaining_round <= 0 then
		UnitRemoveBuff(buff);
	end
end

