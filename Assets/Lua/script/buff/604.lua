--红岭bff
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
	target.BuffID_99997.special_buffs[buff.uuid] = buff

	if not target.BuffID_99997.Effect_targetAfterHit_list.HL_BuffEvent then
		target.BuffID_99997.Effect_targetAfterHit_list.HL_BuffEvent = function (bullet)
			if Hurt_Effect_judge(bullet) then
				for _, _buff in pairs(target.BuffID_99997.special_buffs) do
					if _buff.id == buff.id then
						UnitRemoveBuff(_buff)
						return
					end	
				end
				target.BuffID_99997.Effect_targetAfterHit_list.HL_BuffEvent = nil
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
	target.BuffID_99997.special_buffs[buff.uuid] = nil
end

function onTick(target, buff)
	FireRandomTarget(buff.id, attacker, FindAllEnemy(), nil, {
		Hurt = target.ad,
		Type = 1,
		Element = 7,
		Attacks_Total = 1,
	})
	Common_Sleep(attacker, 0.3)

	UnitRemoveBuff(buff)
end
