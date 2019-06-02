--[每回合增加一个buff]
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function beforePostTick(target, buff)
	local fit_round = buff.cfg_property[3]
	if fit_round then
		local num = GetBattleData().round % 2
		if num == 0 and fit_round ~= 2 or num == 1 and fit_round ~= 1 then
			return
		end
	end

	local buff_id = buff.cfg_property[1] and buff.cfg_property[1] or 0	
	local value = buff.cfg_property[2] and buff.cfg_property[2] or 0	

	Common_Sleep(target, 0.1)

	for i = 1, (buff.cfg_property[4] or 1) do
		Common_UnitAddBuff(target, target, buff_id, 1, {
			parameter_99 = {k= buff_id, v = value},
		})   
	end
	Common_Sleep(target, 0.5)
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
