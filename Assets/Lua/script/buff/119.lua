local value = 0
local effect = nil

function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
	value = buff.cfg_property[1] and buff.cfg_property[1] or 0
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
		v.buff_reflect = v.buff_reflect - value
	end
end

function onRoundStart(target, buff)
	if not effect then
		for _, v in ipairs(FindAllPartner()) do
			if v.uuid ~= target.uuid then
				v.buff_reflect = v.buff_reflect + value
			end
		end
		effect = true
	end
end
