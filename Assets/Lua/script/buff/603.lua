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

local armor_down
local current_shield

function onTick(target, buff)
	local buff_id = buff.cfg_property[1]
	
	if not buff_id then return end

	if armor_down then
		target[1314] = target[1314] + 10000
		armor_down = nil
	end

	if not current_shield then
		current_shield = Common_UnitAddBuff(target, target, buff_id, 1, {round = 1})   
		current_shield.break_fun = function ()
			target[1314] = target[1314] - 10000
			armor_down = true
			current_shield = nil
		end
	else
		UnitPlay(target, "attack1", {speed = 1});
		Common_Sleep(target, 0.3)
		Common_FireBullet(buff.id, target, FindAllEnemy(), nil, {TrueHurt = current_shield[7096], Type = 3})
		UnitRemoveBuff(current_shield)

		current_shield = Common_UnitAddBuff(target, target, buff_id, 1, {round = 1})   
		current_shield.break_fun = function ()
			target[1314] = target[1314] - 10000
			armor_down = true
			current_shield = nil
		end
	end
end
