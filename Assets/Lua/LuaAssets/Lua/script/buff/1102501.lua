--[每损失30%生命召唤一个继承自己30%属性的沙魔城堡，沙魔城堡优先受击]
local lost_hp = 0 
local count = 1
local hp_rate = 0
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
	hp_rate = target.hpp * 0.3
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
	lost_hp = lost_hp + bullet.hurt_final_value
	if lost_hp > count * hp_rate then
		local per_1 = buff.cfg_property[1] and buff.cfg_property[1]/10000 or 0	
		local per_2 = buff.cfg_property[2] and buff.cfg_property[2]/10000 or 0	
		Common_SummonPet(target, 1102501, 1, 5, per_1, per_2)
		count = count + 1
	end
end
