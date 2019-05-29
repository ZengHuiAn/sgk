local buff_id_list = {
	31036101,
	31036202,
	31036303,
	31036404,
	31036505,
	31036606,
}

local current_buff = nil
function onRoundStart(target, buff)
	if current_buff then
		UnitRemoveBuff(current_buff)
	end
	local buff_id = buff_id_list[RAND(1, #buff_id_list)]
	current_buff = Common_UnitAddBuff(target, target, buff_id, 1, {round = 99})   
end

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
	add_buff_parameter(target, buff, -1)
end