--[受到攻击时，有x%的概率反击]
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

function targetAfterHit(target, buff, bullet)
	local fit_round = buff.cfg_property[6]
	if fit_round then
		local num = GetBattleData().round % 2
		if num == 0 and fit_round ~= 2 or num == 1 and fit_round ~= 1 then
			return
		end
	end

    local range =  buff.cfg_property[1] and buff.cfg_property[1] or 0

	if Hurt_Effect_judge(bullet) and RAND(1,10000) <= range then
		local ad_coe = buff.cfg_property[2] and buff.cfg_property[2]/10000 or 0
		local armor_coe = buff.cfg_property[3] and buff.cfg_property[3]/10000 or 0
		Common_BeatBack(target, {bullet.attacker}, armor_coe * target.armor + ad_coe * target.ad, buff.id)
    end
end
