function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
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

function onEnd(target, buff)
	if buff.cfg_property[2] and RAND(1, 10000) <= buff.cfg_property[2] then
		print("__________________________AddRandomBuff_________________!!!!!!!!", buff.id)
        AddRandomBuff(target, buff.id)
	end
	add_buff_parameter(target, buff, -1)
end