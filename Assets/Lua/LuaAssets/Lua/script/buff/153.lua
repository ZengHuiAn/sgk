--1.水 2.火 3.土 4.风 5。光 6.暗
local effect_list = {
	[1] = {2, 4, 6},
	[2] = {1, 3, 5},
	--[3] = {1, 2, 3},
	--[4] = {1, 2, 3},
}

local master_list_2 = {
	airMaster   = 4,
	dirtMaster  = 3,
	waterMaster = 1,
	fireMaster  = 2,
	lightMaster = 5,
	darkMaster  = 6,
}

local value
local keys = {}
function onStart(target, buff)
	value = target[buff.id]
	local element = master_list_2[GetRoleMaster(target)] or 0
	for i = 1, 3, 1 do
		local index = buff.cfg["parameter_"..i]		
		if effect_list[index] then
			for _, v in ipairs(effect_list[index]) do
				if element == v then
					keys[i] = buff.cfg["value_"..i]
					target[keys[i]] = target[keys[i]] + value
				end
			end
		end
	end	
end

function onEnd(target, buff)
	for _, key in pairs(keys) do
		target[key] = target[key] - value
	end
end
