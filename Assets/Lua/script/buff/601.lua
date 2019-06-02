function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onTick(target, buff)
	local fit_id = buff.cfg_property[1]
	if not fit_id then return end

	local partners = FindAllPartner()
	for _, v in ipairs(partners) do
		if v.uuid ~= target.uuid and v.id == fit_id then
			return
		end
	end

	if buff.cfg_property[2] then
		local list_2 = {}
		for _, v in ipairs(partners) do
			list_2[v.Position.pos] = true
			if v.Position.pos == 31 then
				list_2[32] = true
			elseif v.Position.pos == 32 then
				list_2[31] = true
			elseif v.Position.pos == 33 then
				list_2[34] = true
			elseif v.Position.pos == 34 then
				list_2[33] = true
			end
		end

		local pos
		local list = {31, 32, 33, 34, 21, 22, 23}
		for i = 1, #list do
			local index = RAND(1, #list)
			local _pos = list[index]
			if not list_2[_pos] then
				pos = _pos
				break
			end
			table.remove(list, index)
		end

		if pos then
			UnitPlay(target, "attack1", {speed = 1});
			Sleep(0.3)
			AddEnemyInWave(buff.cfg_property[2], pos)
		end
	end

	if buff.cfg_property[3] then
		Common_Heal(target, {target}, 0, (target.hpp - target.hp) * buff.cfg_property[3]/10000, {name_id = buff.id, Type = 24})
		Sleep(0.3)
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
