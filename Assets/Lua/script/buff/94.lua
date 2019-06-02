--回血掉血
-------------------------------------------------
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)

	local function parameter(i)
		-- print("_______________________""__________________________",buff.cfg_property[i] and buff.cfg_property[i] or 0)
		return buff.cfg_property[i] and buff.cfg_property[i] or 0
	end
	
	local heal = parameter(1)/10000 * buff.attacker.ad + parameter(2)/10000 * buff.attacker.hpp + parameter(3)/10000 * target.hpp +  parameter(7)/10000 * buff.attacker.armor
	local hurt = parameter(4)/10000 * buff.attacker.ad + parameter(5)/10000 * buff.attacker.hpp + parameter(6)/10000 * target.hpp

	if hurt > 0 then
		target.BuffID_99997.Effect_onTick_hurt[buff.uuid] = function ()
			hurt = hurt * (1 + target[7016]/10000)
			if buff.cfg_property[8] then
				hurt = hurt + hurt * (buff.cfg_property[8] - 1) * (target.hpp - target.hp)/target.hpp
			end
			Common_Hurt(buff.attacker, {target}, 0, hurt, {name_id = buff.id})
		end
	end

	if heal > 0 then
		target.BuffID_99997.Effect_onTick_heal[buff.uuid] = function ()
			Common_Heal(buff.attacker, {target}, 0, heal, {name_id = buff.id})
		end
	end
end

function onPostTick(target, buff)
	if buff.not_go_round > 0 then
		return
	end

	buff.remaining_round = buff.remaining_round - 1
	if buff.remaining_round <= 0 then
		UnitRemoveBuff(buff)
	end
end

function onEnd(target, buff)
	add_buff_parameter(target, buff, -1)
	target.BuffID_99997.Effect_onTick_hurt[buff.uuid] = nil
	target.BuffID_99997.Effect_onTick_heal[buff.uuid] = nil
end
