--加属性，每个回合结束开始结算cd
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
	if buff.cfg_property[1] and Hurt_Effect_judge(bullet) and bullet.remove_buff_count == 0 and RAND(1,10000) <= buff.cfg_property[1] then
		UnitRemoveBuff(buff);
		bullet.remove_buff_count = bullet.remove_buff_count + 1
    end
end
