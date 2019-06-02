function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

local function isFit(target, buff)
	return buff.cfg_property[1] and target.id == buff.cfg_property[1] or buff.cfg_property[4] and target.mode == buff.cfg_property[4] or buff.cfg_property[4] == -1
end

function afterAllEnter(target, buff)
	local buff_id = buff.cfg_property[2]
	if not buff_id then return end
	if target["BuffID_" .. buff_id] > 0 then return end

	local partners = FindAllPartner()
	local have_fit 
	for _, v in ipairs(partners) do
		if isFit(v, buff) then
			have_fit = true
			break
		end
	end

	if have_fit then
		Common_UnitAddBuff(target, target, buff_id, 1, {
			parameter_99 = {k = buff_id, v = buff.cfg_property[3] or 0}
		})   
	end
end

function onRoleDead(target, buff, role)
	local buff_id = buff.cfg_property[2]
	if not buff_id then return end
	if target["BuffID_" .. buff_id] == 0 then return end

	if isFit(role, buff) then
		local have_fit
		local partners = FindAllPartner()
		for _, v in ipairs(partners) do
			if v.uuid ~= target.uuid and isFit(v, buff) then
				have_fit = true
				break
			end
		end		

		if not have_fit then
			RepeatReomveBuff(target, buff_id, 10)
		end
	end
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
