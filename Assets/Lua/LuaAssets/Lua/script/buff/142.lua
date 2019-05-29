--濒死时，献祭队友回血
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

local function have_fit_partner(target, buff)
	local fit_list = {}
	local partners = FindAllPartner()
	
	local id_1 = buff.cfg_property[1] and buff.cfg_property[1]
	local id_2 = buff.cfg_property[2] and buff.cfg_property[2]
	local id_3 = buff.cfg_property[3] and buff.cfg_property[3]
	
	for _, v in ipairs(partners) do 
		if id_1 and v.id == id_1 then
			table.insert(fit_list, {role = v, order = 1})
		elseif id_2 and v.id == id_2 then
			table.insert(fit_list, {role = v, order = 2})
		elseif id_3 and v.id == id_3 then
			table.insert(fit_list, {role = v, order = 3})
		end
	end

	table.sort(fit_list, function (a, b)
		if a.order ~= b.order then
			return a.order < b.order
		end	
		return a.role.uuid < b.role.uuid
	end)

	return fit_list
end


function targetWillHit(target, buff, bullet)
	if bullet.hurt_final_value > target.hp and target.hp > 1 and #have_fit_partner(target, buff) > 0 then
		bullet.hurt_final_value = math.ceil(target.hp - 1)
    elseif bullet.hurt_final_value > target.hp and target.hp <= 1 and #have_fit_partner(target, buff) > 0 then
		bullet.hurt_final_value = -1
	else
		return
	end

	Run(function ()
		target[7012] = target[7012] + 1000
		PlayEffectsInBuff(buff)		
		if #have_fit_partner(target, buff) == 0 then 
			target.hp = 0
			return
		end

		local kill_partner = have_fit_partner(target, buff)[1].role
		UnitPlay(target, "attack1", {speed = 1});
		Common_Sleep(target, 0.4)
		Common_FireBullet(buff.id, target, {kill_partner}, nil, {TrueHurt = kill_partner.hpp * 10, Duration = 0, Interval = 0, parameter = {
				critPer = -10000,
			}
		})			
		kill_partner.hp = 0
		Common_Sleep(target, 0.4)
		Common_Heal(target, {target}, 0, target.hpp, {name_id = buff.id, Type = 24})
		target[7012] = target[7012] - 1000
	end)
end
