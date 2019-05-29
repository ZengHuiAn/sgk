--[我方队友受到攻击时，有x%概率恢复10点能量]
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)

	local partners = FindAllPartner()
	for _, v in ipairs(partners) do
		if v.uuid ~= target.uuid then
			v.BuffID_99997.Effect_targetAfterHit_list[buff.uuid] = function (bullet)
				local range =  buff.cfg_property[1] and buff.cfg_property[1] or 0
		
				if Hurt_Effect_judge(bullet) and RAND(1,10000) <= range then
					local ep_change = buff.cfg_property[2] and buff.cfg_property[2] or 0
					Common_ChangeEp(target, ep_change, true)
				end
			end
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
	local partners = FindAllPartner()
	for _, v in ipairs(partners) do
		if v.uuid ~= target.uuid then
			v.BuffID_99997.Effect_targetAfterHit_list[buff.uuid] = nil
		end
	end
end
