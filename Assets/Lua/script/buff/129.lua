function targetBeforeHit(target, buff, bullet)
	if target.hp/target.hpp >= (buff.cfg_property[3] or 6000)/10000 then
		if Hurt_Effect_judge(bullet) then
			--减伤
			if buff.cfg_property[2] then
				local reduce_per = buff.cfg_property[2] and buff.cfg_property[2]/10000 or 0
				bullet.damageReduce = bullet.damageReduce + reduce_per
			end

			--伤害变成治疗
			if buff.cfg_property[4] then
				BulletDisabled(bullet)
				Common_Heal(target, {target}, 0, bullet.hurt * buff.cfg_property[4]/10000, {name_id = buff.id})
			end
		end

		--治疗变成伤害
		if Heal_Effect_judge(bullet) and buff.cfg_property[5] then
			BulletDisabled(bullet)
			Common_Hurt(target, {target}, 0, bullet.healValue * buff.cfg_property[5]/10000, {name_id = buff.id})
		end
	end
end

function attackerBeforeHit(target, buff, bullet)
	if Hurt_Effect_judge(bullet) and target.hp/target.hpp >= (buff.cfg_property[3] or 6000)/10000 then
		local up_per = buff.cfg_property[1] and buff.cfg_property[1]/10000 or 0
		bullet.damagePromote = bullet.damagePromote + up_per
	end
end

function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onTick(target, buff)
	if target.hp/target.hpp >= (buff.cfg_property[3] or 6000)/10000 then
		Common_Hurt(target, {target}, 0, target.hp * 0.05, {})
		local list = SortWithHpPer(FindAllPartner())
		Common_UnitAddBuff(target, list[1], buff.cfg_property[6], 1)
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
