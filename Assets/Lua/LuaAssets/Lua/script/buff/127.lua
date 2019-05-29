function onPostTick(target, buff)
	if buff.not_go_round > 0 then
		return
	end

	buff.remaining_round = buff.remaining_round - 1;
	if buff.remaining_round <= 0 then
		UnitRemoveBuff(buff);
	end	
end

local add = 0
local key = nil
function onStart(target, buff)	
	add_buff_parameter(target, buff, 1)
	local per = buff.cfg_property[1] and buff.cfg_property[1]/10000 or 0
	key = buff.cfg_property[2] and buff.cfg_property[2]

	if not key then
		return
	end

	add = target.armor * per
	target[key] = target[key] + add
end

function onEnd(target, buff)	
	add_buff_parameter(target, buff, -1)
	if not key then
		return
	end

	target[key] = target[key] - add
end