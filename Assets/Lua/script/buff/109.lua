--[单次伤害超过最大生命值x%时，超出部分伤害减少50%]
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

function targetWillHit(target, buff, bullet)
    local hp_line =  buff.cfg_property[1] and buff.cfg_property[1]/10000 or 0

    if Hurt_Effect_judge(bullet) and (bullet.hurt_final_value > bullet.target.hpp * hp_line) then
		local hurt_reduce = buff.cfg_property[2] and buff.cfg_property[2]/10000 or 0
		bullet.hurt_final_value = bullet.hurt_final_value -  (bullet.hurt_final_value - bullet.target.hpp * hp_line) * hurt_reduce
	end
end
