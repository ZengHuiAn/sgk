--印记
local function effect(target, buff)
	if buff.cfg_property[2] then
		local hurt = buff.cfg_property[2] /10000 * buff.attacker.ad
		Common_FireBullet(buff.id, buff.attacker, {target}, nil, {Hurt = hurt, Type = 8, Element = 7})
	end

	if buff.cfg_property[3] then
		Common_UnitAddBuff(target, target, buff.cfg_property[3], 1, {
			parameter_99 = {k = buff.cfg_property[3], v = buff.cfg_property[4] or 0 }
		})   
	end
end

function onStart(target, buff)
	add_buff_parameter(target, buff, 1)

	if buff.cfg_property[3] and target["BuffID_"..buff.cfg_property[3]] > 0 then
		UnitRemoveBuff(buff);
		return
	end

	local count = buff.cfg_property[1] and buff.cfg_property[1] or 3
	if target["BuffID_"..buff.id] == count then
		effect(target, buff)
		RepeatReomveBuff(target, buff.id, count)
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
end
