function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onPostTick(target, buff)
	if buff.cfg_property[1] and buff.cfg_property[2] then
		if target[BuffID_ .. buff.cfg_property[1]] == 0 then
			Common_UnitAddBuff(target, target, buff.cfg_property[2])
		end
	end

	if buff.not_go_round <= 0 then
		buff.remaining_round = buff.remaining_round - 1;
		if buff.remaining_round <= 0 then
			UnitRemoveBuff(buff);
		end	
	end
end

function onEnd(target, buff)
	add_buff_parameter(target, buff, -1)
end
