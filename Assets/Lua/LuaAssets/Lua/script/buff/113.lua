--[退场时解除我方所有友军的控制状态，并回复20点能量]
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
		Common_UnitAddEffect(target, "wuxingshenmu_start")
		local ep_change = buff.cfg_property[1] and buff.cfg_property[1] or 0
		Common_RemoveBuffRandom(v, {[3] = true}, 20)
        Common_ChangeEp(v, ep_change, true)
	end
end
