--[死亡时x%的血量复活]
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
	local range =  buff.cfg_property[2] and buff.cfg_property[2] or 10000
	if target.hp <= 0 and RAND(1,10000) < range then
		local hp_line =  buff.cfg_property[1] and buff.cfg_property[1]/10000 or 0
		Common_Relive(target, target, (hp_line * target.hpp + 1))
		Common_FireWithoutAttacker(1910430, {target}, {})
	end
	add_buff_parameter(target, buff, -1)
end