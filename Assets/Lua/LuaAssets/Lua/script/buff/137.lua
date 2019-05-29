--双数回合退场触发
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
	local num = GetBattleData().round % 2
	if num == 1 then
		return
	end

	--解控制
	if buff.cfg_property[2] then
		local partners = FindAllPartner()
		for _, v in ipairs(partners) do
			Common_RemoveBuffRandom(v, {[3] = true}, 1)
		end
	end

	if buff.cfg_property[3] then
		local partners = FindAllPartner()
		target.hp = 1
		local per = buff.cfg_property[3]/10000
		for _, v in ipairs(partners) do
			if v.uuid ~= target.uuid then
				Common_FireBullet(1101420, target, {v}, nil, {
					Duration = 0,
					Interval = 0,
					Hurt = v.hpp * per,
					name_id = buff.id,
					Type = 1,
					Element = 7,
				})	
			end
		end
		
		target.hp = 0
	end

	if buff.cfg_property[4] then
		local partners = FindAllPartner()
		for _, v in ipairs(partners) do
			if v.uuid ~= target.uuid then
                Common_ChangeEp(v, buff.cfg_property[4], true)
			end
		end
	end

	if buff.cfg_property[5] then
		local enemies = FindAllEnemy()
		local count = 1 + buff.cfg_property[7] or 0
		for i = 1, count,1 do
			if #enemies == 0 then
				break
			end	

			local index = RAND(1, #enemies)
			Common_UnitAddBuff(target, enemies[index], buff.cfg_property[5], 1, {
				parameter_99 = { k= buff.cfg_property[5], v = buff.cfg_property[6] or 0}
			})     
			table.remove(enemies, index)
		end
	end

	if buff.cfg_property[8] then
		local partners = FindAllPartner()
		local count = 1 + buff.cfg_property[10] or 0
		for i = 1, count,1 do
			if #partners == 0 then
				break
			end	

			local index = RAND(1, #partners)
			Common_UnitAddBuff(target, partners[index], buff.cfg_property[8], 1, {
				parameter_99 = { k= buff.cfg_property[8], v = buff.cfg_property[9] or 0}
			})     
			table.remove(partners, index)
		end
	end

	if buff.cfg_property[11] then
		local partners = FindAllPartner()
		for _, v in ipairs(partners) do
			Common_FireBullet(300280, target, {v}, nil,
			{Type = 20, Hurt = v.hpp * buff.cfg_property[11]/10000, Duration = 0, Interval = 0, name_id = buff.id})
		end
	end

	if buff.cfg_property[14] then
		local enemies = FindAllEnemy()
		for _, v in ipairs(enemies) do
			Common_FireBullet(300280, target, {v}, nil,
			{Type = 20, Hurt = v.hpp * buff.cfg_property[14]/10000, Duration = 0, Interval = 0})
		end
	end

	add_buff_parameter(target, buff, -1)
end
