local rate = 0
local total = 0
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
	rate = buff.cfg_property[1] and buff.cfg_property[1] or 0
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

function attackerAfterHit(target, buff, bullet)
	if bullet.target.hp <= 0  then
		target[1022] = target[1022] + rate
		total = total + rate
	end
end

function onEnd(target, buff)
	add_buff_parameter(target, buff, -1)
end

function _desc_cfg_add(buff)
	local desc = string.format( "，已提升%s%%的伤害", total/100)
	return 
end