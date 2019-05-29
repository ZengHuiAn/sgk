local effect = nil

function onRoundStart(target, buff)	
	if not effect then
		if buff.cfg and buff.cfg ~= 0 then
			local partners = FindAllPartner()

			local k = buff.cfg.parameter_1
			local v = (buff.cfg.value_1 == 0 and target[buff.id] or buff.cfg.value_1) * (#partners - 1)
			target[k] = target[k] + v
		end
		effect = true
	end
end
