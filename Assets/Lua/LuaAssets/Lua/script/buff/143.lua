--濒死时，献祭队友回血
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
	if buff.cfg_property[2] then
		buff.last_shield = 0
		buff.last_shield = target.shield
	end
end

function targetAfterHit(target, buff, bullet)
	local fit_element = buff.cfg_property[1]
	if not fit_element or bullet.Element == fit_element or bullet.Element == 0 then
		return
	end

	if buff.cfg_property[2] and Hurt_Effect_judge(bullet) then	
		local per = buff.cfg_property[2]/10000
		local value = math.min(per * bullet.hurt_final_value + buff.last_shield - target.shield, target.hp)

		local _target = target.owner ~= 0 and target.owner or target
		Common_Hurt(_target, {bullet.attacker}, 0, value, {Type = 6, name_id = buff.id})
	end

	if buff.cfg_property[3] and Hurt_Effect_judge(bullet) and RAND(1,10000) <= buff.cfg_property[3] then
		Common_BeatBack(target, {bullet.attacker}, target.ad, buff.id)
	end

	if buff.cfg_property[4] and Hurt_Effect_judge(bullet) then
		Common_ChangeEp(bullet.attacker, -(buff.cfg_property[4]), true)
	end
end
