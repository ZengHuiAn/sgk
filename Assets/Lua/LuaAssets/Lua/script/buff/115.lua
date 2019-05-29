--[受到攻击时x%的概率，反弹x%的伤害]
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
	buff.last_shield = 0
	buff.last_shield = target.shield
end

function targetWillHit(target, buff, bullet)
	local range = buff.cfg_property[1] and buff.cfg_property[1] or 0	

	if Hurt_Effect_judge(bullet) and RAND(1,10000) <= range then	
		local per = buff.cfg_property[2] and buff.cfg_property[2]/10000 or 0
		local value = math.min(per * bullet.hurt_final_value + buff.last_shield - target.shield, target.hp)

		local _target = target.owner ~= 0 and target.owner or target
		Common_Hurt(_target, {bullet.attacker}, 0, value, {Type = 6, name_id = buff.id})
	end
end
