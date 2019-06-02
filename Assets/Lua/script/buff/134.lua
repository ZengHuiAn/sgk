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

local function isFit(target, buff)
	return buff.cfg_property[1] and target.id == buff.cfg_property[1] or buff.cfg_property[4] and target.mode == buff.cfg_property[4] or buff.cfg_property[4] == -1
end

function onEnd(target, buff)
	local buff_id = buff.cfg_property[2]
	if buff_id then 
		local have_same
		local targets = {}
		for _,v in ipairs(FindAllPartner()) do 
			if v.id == target.id then 
				have_same = true
			end

			if isFit(v, buff)then
				table.insert(targets, v)
			end
		end
	
		if not have_same then
			for _, v in ipairs(targets) do
				RepeatReomveBuff(v, buff_id, 10)
			end
		end
	end

	add_buff_parameter(target, buff, -1)
end

function afterAllEnter(target, buff)
	local buff_id = buff.cfg_property[2]
	if not buff_id then return end

	local partners = FindAllPartner()
	for _, v in ipairs(partners) do
		if isFit(v, buff) then 
			if v["BuffID_" .. buff_id] == 0 then
				Common_UnitAddBuff(target, v, buff_id, 1, {
					parameter_99 = {k= buff_id, v = buff.cfg_property[3] or 0}
				})   
			end
		end
	end
end
