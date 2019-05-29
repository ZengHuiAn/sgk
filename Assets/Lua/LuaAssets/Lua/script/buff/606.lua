local lost_ad = 0
local loat_armor = 0
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)

	lost_ad = target.ad * (buff.cfg_property[1] or 0 + buff.cfg_property[5] or 0)/10000
	target[1003] = target[1003] - lost_ad
	buff.attacker[1003] = buff.attacker[1003] + lost_ad

	loat_armor = target.armor * (buff.cfg_property[2] or 0 + buff.cfg_property[5] or 0)/10000
	target[1303] = target[1303] - loat_armor
	buff.attacker[1303] = buff.attacker[1303] + loat_armor

	if buff.cfg_property[4] then
		Common_UnitAddBuff(buff.attacker, buff.attacker, buff.cfg_property[4])
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
	if buff.cfg_property[4] then
		RepeatReomveBuff(buff.attacker, buff.cfg_property[4], 1)
	end

	add_buff_parameter(target, buff, -1)

	target[1003] = target[1003] + lost_ad
	buff.attacker[1003] = buff.attacker[1003] - lost_ad

	target[1303] = target[1303] + loat_armor
	buff.attacker[1303] = buff.attacker[1303] - loat_armor
end

function attackerAfterHit(target, buff, bullet)
	if buff.cfg_property[3] and Hurt_Effect_judge(bullet) and bullet.target.uuid == buff.attacker.uuid then
		UnitRemoveBuff(buff);
	end
end
