--链接buff，分摊伤害
function onStart(target, buff)
    for _, v in ipairs(FindAllPartner()) do
        if v["BuffID_"..buff.id] > 0 
        and v.uuid ~= buff.attacker.uuid 
        and buff.attacker.uuid ~= target.uuid 
        and v.uuid ~= target.uuid
        then
            RepeatReomveBuff(v, buff.id, 10)
        end
    end

    add_buff_parameter(target, buff, 1)
end

function onPostTick(target, buff)
	if buff.not_go_round > 0 then
		return
	end
	buff.remaining_round = buff.remaining_round - 1;
	if buff.remaining_round <= 0 then
        for _, v in ipairs(FindAllPartner()) do
            if v["BuffID_"..buff.id] > 0 then
                RepeatReomveBuff(v, buff.id, 10)
            end
        end
    end
end

function onEnd(target, buff)
    add_buff_parameter(target, buff, -1)
end

function targetWillHit(target, buff, bullet)
    if bullet.hurt_disabled == 0 and bullet.Type ~= 9 then
        local fit_list = {}
        local partners = FindAllPartner()

        for _, v in ipairs(partners) do
            if v["BuffID_"..buff.id] > 0 and v.uuid ~= target.uuid then 
                table.insert(fit_list, v)
            end

            for _, pet in ipairs(UnitPetList(v)) do		
                if pet["BuffID_"..buff.id] > 0 and pet.uuid ~= target.uuid then 
                    table.insert(fit_list, pet)
                end
            end
        end

        if #fit_list > 0 then
            bullet.hurt_final_value = bullet.hurt_final_value / (#fit_list + 1)
            Common_FireBullet(0, bullet.attacker, fit_list, nil, {
                TrueHurt = bullet.hurt_final_value,
                Type = 9,
                Duration = 0,
                Interval = 0,
                name_id = buff.id,
            })
        end
    end
end