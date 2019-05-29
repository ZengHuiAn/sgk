--[生命低于40%时，每回合额外回复20能量，每死亡一个敌方或己方目标，获得一次免死的机会]
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onTick(target, buff)
	if target.hp/target.hpp <= 0.4 then
		local ep =  buff.cfg_property[1] and buff.cfg_property[1] or 0
		Common_ChangeEp(target, ep, true)
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

local effect = nil

function onUnitDead(target, buff, role)
	if role.owner == 0 then
		effect = true
	end
end

function targetWillHit(target, buff, bullet)
    --[免死]
    if effect and bullet.hurt_final_value > target.hp then
        bullet.hurt_final_value = target.hp - 1
    end
end
