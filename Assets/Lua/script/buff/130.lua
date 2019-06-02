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

local effect = nil
function onRoundStart(target, buff)
	if not effect then
		local partners = FindAllPartner()
		local range = buff.cfg_property[1] and buff.cfg_property[1]

		for _, v in ipairs(partners) do
			if v.uuid ~= target.uuid then
				v.BuffID_99997.Effect_attackerAfterHit_list[buff.uuid] = function (bullet)			
					if bullet.Type <= 2
					and bullet.Type ~= 0 
					and bullet.Attacks_Total == bullet.Attacks_Count 
					and bullet.target.hp > 0 
					and RAND(1,10000) < range then
						local skill = SkillGetInfo(target, 1)
						local Hurt = (buff.cfg_property[2] and buff.cfg_property[2]/10000 or 0) * target.ad
						UnitPlay(target, "attack1", {speed = 1})
						Common_FireBullet(skill.id, target, {bullet.target}, skill, {
							Hurt = Hurt,
                            Duration = 0,
							Interval = 0,
							Type = 10,
						})
					end
				end
			end
		end
	end
end

