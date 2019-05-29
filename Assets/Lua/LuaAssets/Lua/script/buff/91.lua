--受到若干次攻击后移除
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onPostTick(target, buff)
	if buff.not_go_round > 0 then
		return
	end

	buff.remaining_round = buff.remaining_round - 1
	if buff.remaining_round <= 0 then
		UnitRemoveBuff(buff)
	end
end

function onEnd(target, buff)
	add_buff_parameter(target, buff, -1)
end
