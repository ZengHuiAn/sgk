--加属性x倍， x为buff。id对应属性
function onStart(target, buff)
	if buff.cfg and buff.cfg ~= 0 then
		for i = 1, 3, 1 do
			local k = buff.cfg["parameter_"..i]
			local v = buff.cfg["value_"..i] * target[buff.id]
			target[k] = target[k] + v
		end
	end
	target["BuffID_"..buff.id] = target["BuffID_"..buff.id] + 1
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
	if buff.cfg and buff.cfg ~= 0 then
		for i = 1, 3, 1 do
			local k = buff.cfg["parameter_"..i]
			local v = buff.cfg["value_"..i] * target[buff.id]
			target[k] = target[k] - v
		end
	end
	target["BuffID_"..buff.id] = target["BuffID_"..buff.id] - 1
end
