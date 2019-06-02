--[退场时，释放技能x]
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
	local enemies = All_target_list()
	local per =  buff.cfg_property[1] and buff.cfg_property[1]/10000 or 0

	target.hp = 1
	Common_FireBullet(1101420, attacker, enemies, nil, {
		Duration = 0,
		Interval = 0,
		Hurt = target.ad * per,
		Type = 1,
		Attacks_Total = 1,
		Element = 2,
	})

	for i = 1, 1, 1 do
		for k, v in ipairs(enemies) do
			Common_UnitAddBuff(target, v, 7007, 0.3)
		end
	end

	target.hp = 0
end
