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

function onRoundStart(target, buff)
	local dead_partners = GetDeadList()
	for _, v in ipairs(dead_partners) do
		if v.side == target.side and v[buff.id] > 0 then
			v[buff.id] = 0
			Common_Relive(target, v, (buff.cfg_property[1] or 2500)/10000 * v.hpp)
		end
	end
end

function onRoleDead(target, buff, role)
	if role.side == target.side then
		local partners = FindAllPartner()
		local have_same = false
		for _, v in ipairs(partners) do
			if v.uuid ~= target.uuid and v[buff.id] > 0 then
				have_same = true
				break
			end
		end

		if not have_same then 
			UnitRemoveBuff(buff)
		end
	end
end
