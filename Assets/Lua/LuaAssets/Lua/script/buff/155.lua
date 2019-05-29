function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onRoundStart(target, buff)
	target.order_target = 0
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

function targetAfterHit(target, buff, bullet)
	if not buff.cfg_property[1] or not Hurt_Effect_judge(bullet) then return end
	local type = buff.cfg_property[1]
	
	if type == 1 and target.order_target == 0 then
		target.order_target = bullet.attacker
	end

	if type == 2 then
		target.order_target = bullet.attacker
	end
end
