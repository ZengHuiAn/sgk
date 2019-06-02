local effect = nil
local value = 0

function onRoundStart(target, buff)
	local master = GetRoleMaster(target)
	if not effect then
		if buff.cfg and buff.cfg ~= 0 then
			local k = buff.cfg.parameter_1
			local v = (buff.cfg.value_1 == 0 and target[buff.id] or buff.cfg.value_1)
			local partners = FindAllPartner()
			local count = 0
			for _, role in ipairs(partners) do
				if GetRoleMaster(role) == master and role.uuid ~= target.uuid then
					count = count + 1
				end
			end

			value = v * count		
			target[k] = target[k] + value
			-- print("_______________________________",target.name,k,value)
		end
		effect = true
	end
end

function onEnd(target, buff)
	local master = GetRoleMaster(target)
	if effect then
		if buff.cfg and buff.cfg ~= 0 then
			local k = buff.cfg.parameter_1
			local v = (buff.cfg.value_1 == 0 and target[buff.id] or buff.cfg.value_1)
			target[k] = target[k] - value
			effect = nil
		end
	end
end
