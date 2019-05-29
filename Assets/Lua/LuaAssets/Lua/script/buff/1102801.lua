--[如果攻击目标的能量高于自己，则平衡双方的能量，如果低于自己则伤害提升x%]
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

function attackerBeforeHit(target, buff, bullet)
	if Hurt_Effect_judge(bullet) then
		if bullet.target.ep > target.ep then
			local average = (bullet.target.ep + target.ep)/2
			Common_ChangeEp(bullet.target, average - bullet.target.ep, true)
			Common_ChangeEp(target, average - target.ep, true)
		else
			local dam_up =  buff.cfg_property[1] and buff.cfg_property[1]/10000 or 0
			bullet.damagePromote = bullet.damagePromote + dam_up
		end
	end
end
