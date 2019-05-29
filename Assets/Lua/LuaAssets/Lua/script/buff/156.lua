--冻伤类
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onPostTick(target, buff)
	if buff.not_go_round > 0 then
		return
	end

	buff.remaining_round = buff.remaining_round - 1;
	if buff.remaining_round <= 0 then
		if buff.cfg_property[1] then
			Common_FireBullet(buff.id, buff.attacker, {target}, nil, {
				Hurt = buff.attacker.ad * buff.cfg_property[1]/10000,
				Type = 5,
				name_id = buff.id,
			})
			Common_Sleep(0.5)
		end
		UnitRemoveBuff(buff);
	end	
end

function onEnd(target, buff)
	add_buff_parameter(target, buff, -1)
end

function targetAfterHit(target, buff, bullet)
	if buff.cfg_property[2] and buff.cfg_property[2] == 1 and target.hp == target.hpp then
		UnitRemoveBuff(buff);
	end
end
