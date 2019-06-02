function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

local former_target = nil

function onPostTick(target, buff)
	local partners = FindAllPartner()
	local list = SortWithParameter(partners, "hp")
	local buff_id =  buff.cfg_property[1] and buff.cfg_property[1] or 0
	local value = buff.cfg_property[2] and buff.cfg_property[2] or 0	

	if former_target and former_target.hp > 0 then
		RepeatReomveBuff(former_target, buff_id, 1)
	end

	Common_UnitAddBuff(attacker, list[1], buff_id, 1,{
		parameter_99 = {k= buff_id, v = value}
	})   
	former_target = list[1]

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
