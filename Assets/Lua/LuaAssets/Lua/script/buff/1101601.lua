function onStart(target, buff)
	add_buff_parameter(target, buff, 1)	
end

local effect = nil 

function onRoundStart(target, buff)
	if not effect then
		local enemies = FindAllEnemy()
		for _, v in ipairs(enemies) do
			v.BuffID_99997.Effect_onTick_list[buff.uuid] = function (bullet)
				local range = buff.cfg_property[1] and buff.cfg_property[1] or 0
				local rate = buff.cfg_property[2] and buff.cfg_property[2]/10000 or 0
				if RAND(1,10000) <= 10000 then
					Common_FireBullet(1101610, target, {v}, nil, {
						Type = 5,
						Hurt = target.ad * rate,
						Element = 4,
						name_id = buff.id,
						parameter = {
							critPer = -10000,
						}				
					})
				end
			end
		end
		effect = true
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
	local enemies = FindAllEnemy()
	for _, v in ipairs(enemies) do
		v.BuffID_99997.Effect_onTick_list[buff.uuid] = nil
	end
end
