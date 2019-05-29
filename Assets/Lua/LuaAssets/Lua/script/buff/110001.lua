local is_add
function onStart(target, buff)
	if target.ad_steal_count <= 5 then
		target[1003] = target[1003] + buff.adup
		is_add = true
	end
	target.ad_steal_count = target.ad_steal_count + 1
end

--buff消失的时候触发
function onEnd(target, buff)
	if is_add then
		target[1003] = target[1003] - buff.adup
	end
	target.ad_steal_count = target.ad_steal_count - 1
	UnitRemoveBuff(buff.relevant_buff);
end

function onPostTick(target, buff, round)
	buff.remaining_round = buff.remaining_round - 1;
	if buff.remaining_round <= 0 then
		UnitRemoveBuff(buff);
	end
end

