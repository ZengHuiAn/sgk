function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
	if buff.cfg_property[1] and buff.cfg_property[2] and GetFightData().fight_id == buff.cfg_property[1] then
		Common_UnitAddBuff(target, target, buff.cfg_property[2], 1, {
			parameter_99 = {k= buff.cfg_property[2], v = buff.cfg_property[3] or 0}
		})   
	end
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
	add_buff_parameter(target, buff, -1)
end
