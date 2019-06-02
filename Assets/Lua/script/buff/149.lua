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
	local move_type = buff.cfg_property[2]
	if move_type then
		local all, partners, enemies = FindAllRoles()
		if move_type == 1 then
			for i = 1, #all do
				local index = RAND(1, #all)
				if all[index].uuid ~= target.uuid then
					Common_UnitAddBuff(target, all[index], buff.id, 1, {
						parameter_99 = buff.parameter_99
					})   
					break
				else
					table.remove(all, index)
				end
			end
		elseif move_type == 2 then
			if #partners == 1 then
				Common_UnitAddBuff(target, partners[index], buff.id, 1, {
					parameter_99 = buff.parameter_99
				})   
			else
				for i = 1, #partners do
					local index = RAND(1, #partners)
					if partners[index].uuid ~= target.uuid then
						Common_UnitAddBuff(target, partners[index], buff.id, 1, {
							parameter_99 = buff.parameter_99
						})   
						break
					else
						table.remove(partners, index)
					end
				end
			end
		elseif move_type == 3 then
			for i = 1, #enemies do
				local index = RAND(1, #enemies)
				Common_UnitAddBuff(target, enemies[index], buff.id, 1, {
					parameter_99 = buff.parameter_99
				})   
			end
		end
	end

	add_buff_parameter(target, buff, -1)
end

function targetAfterHit(target, buff, bullet)
	if buff.cfg_property[1] and Hurt_Effect_judge(bullet) and RAND(1,10000) <= buff.cfg_property[1] then
		UnitRemoveBuff(buff);
    end
end
