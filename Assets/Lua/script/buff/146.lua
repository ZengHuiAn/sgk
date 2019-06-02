
local add
local key_1
local value_1 
local key_2
local value_2 

function onRoundStart(target, buff)
	local fit_round = buff.cfg.value_1
	if fit_round then
		local num = GetBattleData().round % 2
		if num == 0 and fit_round == 2 and not add or num == 1 and fit_round == 1 and not add then
			if key_1 ~= 0 then
				target[key_1] = target[key_1] + (value_1 == 0 and target[buff.id] or value_1)
			end

			if key_2 ~= 0 then
				target[key_2] = target[key_2] + (value_2 == 0 and target[buff.id] or value_2)
			end
			add = true
		elseif add then
			if key_1 ~= 0 then
				target[key_1] = target[key_1] - (value_1 == 0 and target[buff.id] or value_1)
			end

			if key_2 ~= 0 then
				target[key_2] = target[key_2] - (value_2 == 0 and target[buff.id] or value_2)
			end
			add = nil
		end
	end
end

function onStart(target, buff)
	key_1 = buff.cfg.parameter_2
	value_1 = buff.cfg.value_2
	key_2 = buff.cfg.parameter_3
	value_2 = buff.cfg.value_3
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
	if add then
		if key_1 ~= 0 then
			target[key_1] = target[key_1] - value_1 == 0 and target[buff.id] or value_1
		end

		if key_2 ~= 0 then
			target[key_2] = target[key_2] - value_2 == 0 and target[buff.id] or value_2
		end
		add = nil
	end
end

