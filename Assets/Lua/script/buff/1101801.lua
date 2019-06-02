--[入场时投掷骰子，提升我方全体【骰子数*5%】的攻击]
local effect = nil
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

function onRoundStart(target, buff)
	if not effect then
		local buffid = buff.cfg_property[1] and buff.cfg_property[1] or 0	
		local value = buff.cfg_property[2] and buff.cfg_property[2] or 0	

		local num = RAND(1,6)
		local partners = FindAllPartner()
		for _, v in ipairs(partners) do
			for i = 1,num do
				Common_UnitAddBuff(attacker, v, buffid , 1,{
					parameter_99 = {k = buffid, v = value}
				})   
			end
		end
		effect = true
		Common_Sleep(target, 0.8)
	end
end
