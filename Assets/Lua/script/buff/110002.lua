local lost_ad = 0
local relevant_buff = nil
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)

	lost_ad = target.ad * 0.1
	target[1014] = target[1014] - 1000
	relevant_buff = Common_UnitAddBuff(buff.attacker, buff.attacker, 110001, 1, {
		adup = lost_ad, 
		relevant_buff = buff,
	})
end

--buff消失的时候触发
function onEnd(target, buff)
	add_buff_parameter(target, buff, -1)
	target[1014] = target[1014] + 1000
	UnitRemoveBuff(relevant_buff)
end

function onPostTick(target, buff, round)
	buff.remaining_round = buff.remaining_round - 1;
	if buff.remaining_round <= 0 then
		UnitRemoveBuff(buff);
	end
end
