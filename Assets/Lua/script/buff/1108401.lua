local effect = nil
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onRoundStart(target, buff)
	if not effect then
		local up =  buff.cfg_property[1] and buff.cfg_property[1] or 0
		for _, v in ipairs(FindAllPartner()) do
			v[1231] = v[1231] + up
		end
		effect = true
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
	for _, v in ipairs(FindAllPartner()) do
		local up =  buff.cfg_property[1] and buff.cfg_property[1] or 0
		v[1231] = v[1231] - up
	end
end
