--[血量低于30%时恢复20%最大生命]
local is_effect
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

function targetAfterHit(target, buff, bullet)
	local hp_line = buff.cfg_property[1] and buff.cfg_property[1]/10000 or 0
	if not is_effect and target.hp/target.hpp < hp_line and target.hp > 0 then
		local function parameter(i)
			return buff.cfg_property[i] and buff.cfg_property[i] or 0
		end
		
		local heal = parameter(2)/10000 * buff.attacker.ad + parameter(3)/10000 * buff.attacker.hpp + parameter(4)/10000 * target.hpp
		Common_Heal(target, {target}, 0, heal, {name_id = buff.id})
		is_effect = true
	end
end

function onEnd(target, buff)
	add_buff_parameter(target, buff, -1)
end
