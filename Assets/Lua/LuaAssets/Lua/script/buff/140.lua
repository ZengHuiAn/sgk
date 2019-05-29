--每存在某周角色 获得属性提升
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

	local partners = FindAllPartner()
	local enemies = FindAllEnemy()

	for _, v in ipairs(partners) do
		if v.uuid ~= target.uuid then
			v.BuffID_99997.Effect_onEnd_list[buff.uuid] = nil
		end
	end

	for _, v in ipairs(enemies) do
		if v.uuid ~= target.uuid then
			v.BuffID_99997.Effect_onEnd_list[buff.uuid] = nil
		end
	end
end

local master_list_2 = {
	airMaster = 4,
	dirtMaster = 3,
	waterMaster = 1,
	fireMaster = 2,
	lightMaster = 5,
	darkMaster = 6
}

function afterAllEnter(target, buff)
	local partners = FindAllPartner()
	local enemies = FindAllEnemy()
	local key = buff.cfg_property[2]
	if not key then return end

	if buff.cfg_property[1] then
		for _, v in ipairs(partners) do
			if master_list_2[GetRoleMaster(v)] == buff.cfg_property[1] then
				if not v.BuffID_99997.Effect_onEnd_list[buff.uuid] and v.uuid ~= target.uuid then
					target[key] = target[key] + buff.cfg_property[3] or 0
					v.BuffID_99997.Effect_onEnd_list[buff.uuid] = function ()
						target[key] = target[key] - buff.cfg_property[3] or 0
					end
				end
			end
		end
	end
end