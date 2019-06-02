--[受到攻击后，概率减少对手的能量]
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
    local range = buff.cfg_property[1] and buff.cfg_property[1] or 0

    if Hurt_Effect_judge(bullet) and RAND(1,10000) <= range then
		local ep_change = buff.cfg_property[2] and buff.cfg_property[2] or 0
        Common_ChangeEp(bullet.attacker, -(ep_change), true)
    end
end
