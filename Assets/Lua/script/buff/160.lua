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

function targetBeforeHit(target, buff, bullet)
    local range = buff.cfg_property[1] and buff.cfg_property[1] or 10000
    if Heal_Effect_judge(bullet) and RAND(1,10000) <= range and buff.cfg_property[3] then
		local partners = FindAllPartner()
		Common_FireWithoutAttacker(buff.id, partners, {Type = 3, TrueHurt = bullet.hurt, Duration = 0, Interval = 0, name_id = buff.id})
	end
end

function targetAfterHit(target, buff, bullet)
    local range = buff.cfg_property[1] and buff.cfg_property[1] or 10000
    if Heal_Effect_judge(bullet) and RAND(1,10000) <= range then
		if buff.cfg_property[2] then
			Common_UnitAddBuff(target, target, buff.cfg_property[2])
		end
	end
end
