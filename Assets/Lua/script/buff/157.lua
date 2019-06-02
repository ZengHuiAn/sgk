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

local former_hp = 0
local effect_times = 0 

local function effect(target, buff)
	if effect_times <= 0 then return end

	effect_times = effect_times - 1
	if buff.cfg_property[2] then
		Common_UnitAddBuff(target, target, buff.cfg_property[2], 1, {
			parameter_99 = {k= buff.cfg_property[2], v = buff.cfg_property[3] or 0}
		})   
	end	
end

function onRoundStart(target, buff)
	former_hp = target.hp
	effect = buff.cfg_property[4] or 1
end

function targetAfterHit(target, buff, bullet)
	if buff.cfg_property[1] and (former_hp - target.hp)/target.hpp > buff.cfg_property[1]/10000 then
		effect(target, buff)
	end
end
