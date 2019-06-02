--[我方队友受到攻击时，有X%概率恢复血量]
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
	--[[
	local partners = FindAllPartner()
	for _, v in ipairs(partners) do
		if v.uuid ~= target.uuid then
			v.BuffID_99997.Effect_targetAfterHit_list[buff.uuid] = function (bullet)
				local range =  buff.cfg_property[1] and buff.cfg_property[1] or 0
		
				if Hurt_Effect_judge(bullet) and RAND(1,10000) <= range then
					local ad_coe = buff.cfg_property[2] and buff.cfg_property[2]/10000 or 0
					local hpp_coe_1 = buff.cfg_property[3] and buff.cfg_property[3]/10000 or 0
					local hpp_coe_2 = buff.cfg_property[4] and buff.cfg_property[4]/10000 or 0
					local heal_value = ad_coe * buff.attacker.ad + hpp_coe_1 * buff.attacker.hpp + hpp_coe_2 * target.hpp
                    Common_Heal(target, {target}, 0, heal_value, {name_id = buff.id})
				end
			end
		end
	end
	--]]
end

function targetAfterHit(target, buff, bullet)
	local range =  buff.cfg_property[1] and buff.cfg_property[1] or 0
	if Hurt_Effect_judge(bullet) and RAND(1,10000) <= range then
		local ad_coe = buff.cfg_property[2] and buff.cfg_property[2]/10000 or 0
		local hpp_coe_1 = buff.cfg_property[3] and buff.cfg_property[3]/10000 or 0
		local hpp_coe_2 = buff.cfg_property[4] and buff.cfg_property[4]/10000 or 0
		local heal_value = ad_coe * buff.attacker.ad + hpp_coe_1 * buff.attacker.hpp + hpp_coe_2 * target.hpp
		Common_Heal(target, {target}, 0, heal_value, {name_id = buff.id})
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
