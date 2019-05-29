function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
	rate = buff.cfg_property[1] and buff.cfg_property[1] or 0
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

function onSkillCast(target, buff, skill)
	if skill.owner.side ~= target.side and skill.skill_consume_ep > 0 then
		local ep_change = buff.cfg_property[1] and buff.cfg_property[1]/10000 or 0
        Common_ChangeEp(target, ep_change, true)
	end
end