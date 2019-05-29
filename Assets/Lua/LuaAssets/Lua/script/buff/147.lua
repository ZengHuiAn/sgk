local effect_buff

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


function targetAfterHit(target, buff, bullet)
	if not buff.cfg_property[2] or not buff.cfg_property[1] then return end
	if target.hp > 0 and not effect_buff and target.hp/target.hpp < buff.cfg_property[1]/10000 then
		effect_buff = Common_UnitAddBuff(target, target, buff.cfg_property[2], 1, {
			parameter_99 = {k = buff.cfg_property[2], v = buff.cfg_property[3] or 0 }
		})   
	elseif target.hp > 0 and effect_buff and target.hp/target.hpp >= buff.cfg_property[1]/10000 then
		UnitRemoveBuff(effect_buff)
	end
end
