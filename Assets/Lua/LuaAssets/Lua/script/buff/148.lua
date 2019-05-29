local origial_ids = {}
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
	for i = 1, 3, 1 do
		if buff.cfg_property[i] then
			local skill = SkillGetInfo(target, i)
			origial_ids[i] = skill.id
			SkillChangeId(target, i, buff.cfg_property[i])
		end
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
	for index, id in pairs(origial_ids) do
		SkillChangeId(target, index, id)
	end
end
