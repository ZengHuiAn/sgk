local effect = nil

function afterAllEnter(target, buff)	
	if not effect then
		local partners = FindAllPartner()
		for _, v in ipairs(partners) do
			if v.uuid ~= target.uuid then
				v.BuffID_99997.Effect_onEnd_list[buff.uuid] = function ()
					local buff_id = buff.cfg_property[1]
					if not buff_id then return end
					if buff.cfg_property[3] and v.id == buff.cfg_property[3] or buff.cfg_property[4] and v.mode == buff.cfg_property[4] then 
						local value = buff.cfg_property[2] and buff.cfg_property[2]
						Common_UnitAddBuff(target, target, buff_id, 1, {
							parameter_99 = {k= buff_id, v = value}
						})   
					end
				end
			end
		end
		effect = true
	end
end

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
	for _, v in ipairs(partners) do
		if v.uuid ~= target.uuid then
			v.BuffID_99997.Effect_onEnd_list[buff.uuid] = nil
		end
	end
end
