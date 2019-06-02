--濒死时，献祭队友回血
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
	local count = buff.cfg_property[1]
	local buff_id = buff.cfg_property[2]

	if not count or not buff_id then
		return
	end	

	local partners = FindAllPartner()
	local average =  math.floor(count/#partners)

	Common_Sleep(target, 0.3)
	PlayEffectsInBuff(buff)
	Common_FireBullet(buff.id, target, partners, nil, {Type = 30})

	for _,v in ipairs(partners) do
		for i = 1,average do
			Common_UnitAddBuff(target, v, buff_id)
		end
	end
end