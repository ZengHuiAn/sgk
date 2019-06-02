local round_local = 0
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onTick(target, buff)
	round_local = round_local + 1
	local interval = buff.cfg_property[1]
	if not interval then return end
	if GetBattleData().round % interval ~= 0 then return end
	
	if buff.cfg_property[2] then
		Common_Heal(target, {target}, 0, (target.hpp - target.hp) * buff.cfg_property[2]/10000 + 1)
	end

	if buff.cfg_property[3] then
		for _, v in ipairs(FindAllEnemy()) do
			Common_UnitAddBuff(target, v, buff.cfg_property[3])
		end
	end

	if buff.cfg_property[4] then
		local enemies = FindAllEnemy()
		Common_UnitAddBuff(target, enemies[RAND(1, #enemies)], buff.cfg_property[4])
	end
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
