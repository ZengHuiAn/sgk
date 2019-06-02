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
	target.hp = 1

	local T = {}
	local max_count = 0
	for _, v in ipairs(FindAllEnemy()) do
		if v.BuffID_2103210 > 0 then
			local count = RepeatReomveBuff(v, 2103210, 20)
			if count > max_count then
				max_count = count
			end
			table.insert(T, {role = v, count = count})
		end
	end
	
	for i = 1, max_count do
		for _, v in pairs(T) do 
			if i <= v.count then 
				Common_FireBullet(1103230, attacker, {v.role}, nil, {
					Duration = 0,
					Interval = 0,
					Hurt = target.ad,
					Type = 1,
					Element = 4,
				})
			end
		end
	end
	target.hp = 0
end

function targetAfterHit(target, buff, bullet)
	local range =  buff.cfg_property[1] and buff.cfg_property[1] or 0
	if Hurt_Effect_judge(bullet) then
		Common_UnitAddBuff(attacker, bullet.attacker, 2103210, range/10000, {round = 4})
	end
end

function targetBeforeHit(target, buff, bullet)
	local dam_reduce =  buff.cfg_property[2] and buff.cfg_property[2]/10000 or 0
	
	if bullet.attacker.BuffID_2103210 > 0 and Hurt_Effect_judge(bullet) then
		bullet.damageReduce = bullet.damageReduce + dam_reduce
	end
end