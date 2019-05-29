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

function onTick(target, buff)
	local value = buff.cfg_property[1] and buff.cfg_property[1] or 0

	local partners = FindAllPartner()
	for _, v in ipairs(partners) do
		if v.buff_event_120 ~= GetBattleData().round then
			Common_ChangeEp(v, value, true)
			v.buff_event_120 = GetBattleData().round
		end
	end
end
