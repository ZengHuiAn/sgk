function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

local function effect(target, buff)
	local enemies = FindAllEnemy()
	for _, v in ipairs(enemies) do
		PlayEffectsInBuff(buff)
		Common_Hurt(target, {v}, 0, v.hpp * (buff.cfg_property[2] or 1000)/10000, {name_id = buff.id, effect_id = buff.id})
	end
end

function onTick(target, buff)
	local partners = FindAllPartner()
	for _, v in ipairs(partners) do
		if math.abs(v.hp/v.hpp - target.hp/target.hpp) > (buff.cfg_property[1] or 3000)/10000 then
			effect(target, buff)
			break
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
end
