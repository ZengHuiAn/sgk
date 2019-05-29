local a =  {
	[2] = 1,
	[3] = 2,
	[4] = 3,
	[5] = 4,
}

function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
	
	local need_player_count = buff.cfg_property[1] and buff.cfg_property[1] or 5
	if target.game.attacker_player_count and target.game.attacker_player_count > need_player_count then
		local buff_id = buff.cfg_property[2] 
		local value = (buff.cfg_property[3] and buff.cfg_property[3] or 0) * a[target.game.attacker_player_count]
		if not buff_id then return end
		Common_UnitAddBuff(attacker, attacker, buff_id, 1, {
			parameter_99 = {k= buff_id, v = value}
		})   
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
