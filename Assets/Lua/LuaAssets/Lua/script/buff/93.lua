--通用护盾
function targetAfterCalc(target, buff, bullet)
	if buff.cfg_property[4] then
		if Hurt_Effect_judge(bullet) then	
			local per = buff.cfg_property[4] and buff.cfg_property[4]/10000 or 0
			local value = math.min(per * bullet.hurt_final_value + buff.last_shield - target.shield, target.hp)
	
			local _target = target.owner ~= 0 and target.owner or target
			Common_Hurt(_target, {bullet.attacker}, 0, value, {Type = 6, name_id = buff.id})
		end
	end

	if buff.cfg_property[9] then
		if Hurt_Effect_judge(bullet) then	
			local per = buff.cfg_property[9] and buff.cfg_property[9]/10000 or 0
			local value = target.ad * per
	
			local _target = target.owner ~= 0 and target.owner or target
			Common_Hurt(_target, {bullet.attacker}, 0, value, {Type = 6, name_id = buff.id})
		end
	end

	Shield_calc(buff,bullet)
end

function onStart(target, buff)
	CalcAllShield(target)
	add_buff_parameter(target, buff, 1)
	if target.BuffID_1108401 > 0 then
		target[1201] = target[1201] + 4000
		target[1211] = target[1211] + 20
	end
end

local auto_remove
function onTick(target, buff)
	if buff.not_go_round > 0 then
		return
	end

	buff.remaining_round = buff.remaining_round - 1;
	if buff.remaining_round <= 0 then
		auto_remove = true
		UnitRemoveBuff(buff);
	end
end

function onEnd(target, buff)
	if auto_remove then
		if buff.cfg_property[5] then
			Common_UnitAddBuff(target, target, buff.cfg_property[5], 1, {
				parameter_99 = {k= buff.cfg_property[5], v = buff.cfg_property[6] and buff.cfg_property[6] or 0}
			})      
		end
		
		if buff.cfg_property[8] then
			UnitPlay(target, "attack1", {speed = 1});
			Common_Sleep(target, 0.3)
			for _, v in ipairs(FindAllEnemy()) do
				Common_FireBullet(buff.id, target, {v}, nil, {TrueHurt = v.hpp * buff.cfg_property[8]/10000, Type = 3})
			end
		end

		if buff.autoremove_fun and buff.autoremove_fun ~= 0 then
			buff.autoremove_fun()
		end
	elseif buff.break_fun and buff.break_fun ~= 0 then
		buff.break_fun()
	end
	
	add_buff_parameter(target, buff, -1)
	
	if target.BuffID_1108401 > 0 then
		target[1201] = target[1201] - 4000
		target[1211] = target[1211] - 20
	end
	CalcAllShield(target)
end

function targetBeforeHit(target, buff, bullet)
	if buff.cfg_property[4] then
		buff.last_shield = 0
		buff.last_shield = target.shield
	end
end

function targetAfterHit(target, buff, bullet)
	if buff.cfg_property[7] then
		local range =  buff.cfg_property[7] and buff.cfg_property[7] or 0
		if Hurt_Effect_judge(bullet) and RAND(1,10000) <= range then
			Common_BeatBack(target, {bullet.attacker}, target.ad, buff.id)
		end
	end
end
