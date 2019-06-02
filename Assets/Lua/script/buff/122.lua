
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

function targetAfterHit(target, buff, bullet)
	local function parameter(i)
		return buff.cfg_property[i] and buff.cfg_property[i] or 0
	end

	local range = parameter(1)

	if Hurt_Effect_judge(bullet) and RAND(1,10000) <= range then
		local heal = parameter(2)/10000 * buff.attacker.ad + parameter(3)/10000 * buff.attacker.hpp + parameter(4)/10000 * target.hpp
		Common_Heal(buff.attacker, {target}, 0, heal, {name_id = buff.id})
	end
end

