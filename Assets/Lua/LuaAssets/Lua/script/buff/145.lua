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
	local fit_element = buff.cfg_property[1]
	if not fit_element or bullet.Element ~= fit_element then
		return
	end

	if buff.cfg_property[2] and Hurt_Effect_judge(bullet) then
		bullet.damageAdd = bullet.damageAdd + target.hpp * buff.cfg_property[2]/10000
	end
end

function targetAfterHit(target, buff, bullet)
	local fit_element = buff.cfg_property[1]
	if not fit_element or bullet.Element ~= fit_element then
		return
	end

	if buff.cfg_property[3] and Hurt_Effect_judge(bullet) then
		local per = buff.cfg_property[3] and buff.cfg_property[3]/10000 or 0
		local value = math.min(bullet.hurt_final_value, target.hp)

		local _target = target.owner ~= 0 and target.owner or target
		Common_Hurt(_target, FindAllEnemy(), 0, value, {Type = 6, name_id = buff.id, effect_id = buff.id})
	end
end